/**
 * Auth Store
 * 使用者認證與授權管理（Supabase Auth 整合）
 */
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { authService } from '@/api/services/auth'
import { isSupabaseAvailable, supabase } from '@/api/supabase.js'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref(null)
  const userProfile = ref(null)
  const isAuthenticated = ref(false)
  const token = ref(null)
  const loading = ref(false)
  const checkingAuth = ref(false) // 用於追蹤是否正在檢查認證

  function normalizeIdentifier (identifier) {
    return (identifier || '').trim()
  }

  async function resolveLoginEmail (identifier) {
    const normalized = normalizeIdentifier(identifier)
    if (!normalized) return ''
    if (normalized.includes('@')) return normalized
    if (!isSupabaseAvailable()) return normalized

    const { data, error } = await supabase
      .from('user_profiles')
      .select('email')
      .ilike('username', normalized)
      .limit(1)
      .maybeSingle()

    if (error) throw error
    return data?.email?.trim?.() || ''
  }

  // Getters
  const currentUser = computed(() => {
    if (userProfile.value) {
      return {
        ...userProfile.value,
        email: user.value?.email,
        id: user.value?.id,
      }
    }
    return user.value ? {
      id: user.value.id,
      username: user.value.email?.split('@')[0] || user.value.id,
      email: user.value.email,
      role: 'applicant',
    } : null
  })
  const isLoggedIn = computed(() => isAuthenticated.value && user.value !== null)
  // 僅在 user_profile 載入後回傳角色，避免重整時以預設 applicant 誤觸權限查詢
  const userRole = computed(() => userProfile.value?.role ?? null)

  /** 合併並發的 checkAuth 請求，避免路由守衛與初始化重複檢查 */
  let authCheckInFlight = null

  /** Supabase 完成 INITIAL_SESSION 後才為 true（避免與 onAuthStateChange 死鎖） */
  let authReadyResolved = !isSupabaseAvailable()
  let resolveAuthReady = null
  const authReadyPromise = new Promise(resolve => {
    resolveAuthReady = resolve
  })

  function markAuthReady () {
    if (authReadyResolved) return
    authReadyResolved = true
    resolveAuthReady?.()
  }

  /**
   * 等待 Supabase 完成 session 還原（路由守衛應先 await 此函式）
   */
  async function waitForAuthReady (maxMs = 10000) {
    if (authReadyResolved) return
    await Promise.race([
      authReadyPromise,
      new Promise(resolve => setTimeout(resolve, maxMs)),
    ])
  }

  // Actions
  /**
   * 登入（支援 email 或 username）
   */
  async function login (identifier, password) {
    loading.value = true
    try {
      const normalized = normalizeIdentifier(identifier)
      if (!normalized) {
        return { success: false, message: '請輸入 Email/使用者名稱' }
      }

      const email = await resolveLoginEmail(normalized)
      if (!email || !email.includes('@')) {
        return { success: false, message: '找不到此使用者名稱對應的 Email，請改用 Email 登入或聯繫管理員' }
      }

      // 使用 Supabase Auth 登入
      const result = await authService.login(email, password)

      if (result.user) {
        user.value = result.user
        isAuthenticated.value = true
        token.value = result.session?.access_token || null

        // 載入 user_profile
        await loadUserProfile(result.user.id)

        // 檢查用戶是否已啟用
        if (userProfile.value && !userProfile.value.is_active) {
          await logout()
          return {
            success: false,
            message: '您的帳號尚未啟用，請等待管理員審核後再登入',
          }
        }

        // 更新最後登入時間和 IP
        await updateLastLogin(result.user.id)

        return { success: true, user: currentUser.value }
      }

      return { success: false, message: '登入失敗' }
    } catch (error) {
      console.error('登入錯誤', error)
      return {
        success: false,
        message: error.message || '登入失敗，請檢查帳號密碼',
      }
    } finally {
      loading.value = false
    }
  }

  /**
   * 登出
   */
  async function logout () {
    loading.value = true
    try {
      await authService.logout()
    } catch (error) {
      console.error('登出錯誤', error)
    } finally {
      user.value = null
      userProfile.value = null
      isAuthenticated.value = false
      token.value = null
      loading.value = false
    }
  }

  /**
   * 更新最後登入時間和 IP
   */
  async function updateLastLogin (userId) {
    if (!isSupabaseAvailable() || !userId) {
      return
    }

    try {
      // 獲取 IP 地址（使用第三方 API）
      let ipAddress = null
      try {
        // 使用 ipify.org API 獲取 IP 地址（免費且無需認證）
        const response = await fetch('https://api.ipify.org?format=json')
        if (response.ok) {
          const data = await response.json()
          ipAddress = data.ip || null
        }
      } catch (error) {
        console.warn('獲取 IP 地址失敗', error)
        // IP 獲取失敗不影響登入流程，設為 null
        ipAddress = null
      }

      // 更新 user_profiles
      const { error } = await supabase
        .from('user_profiles')
        .update({
          last_login: new Date().toISOString(),
          last_login_ip: ipAddress,
        })
        .eq('id', userId)

      if (error) {
        console.warn('更新最後登入時間失敗', error)
        // 不拋出錯誤，避免影響登入流程
      }
    } catch (error) {
      console.error('更新最後登入時間錯誤', error)
      // 不拋出錯誤，避免影響登入流程
    }
  }

  /**
   * 載入用戶資料（從 user_profiles）
   */
  async function loadUserProfile (userId) {
    if (!isSupabaseAvailable() || !userId) {
      return
    }

    try {
      const { data: profile, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single()

      if (error) {
        // PGRST116 表示找不到記錄，這是正常的（可能還沒創建 profile）
        if (error.code === 'PGRST116') {
          // 如果沒有 profile，嘗試創建一個基本的
          try {
            const { data: newProfile } = await supabase
              .from('user_profiles')
              .insert({
                id: userId,
                username: user.value?.email?.split('@')[0] || userId,
                role: 'applicant',
              })
              .select()
              .single()

            if (newProfile) {
              userProfile.value = newProfile
            }
          } catch (insertError) {
            // 創建失敗可能是因為已經存在（race condition），忽略錯誤
            console.warn('創建 user_profile 失敗', insertError)
          }
        } else {
          console.warn('載入 user_profile 失敗', error)
        }
        return
      }

      if (profile) {
        userProfile.value = profile
      }
    } catch (error) {
      console.error('載入 user_profile 錯誤', error)
      // 不拋出錯誤，避免阻塞認證流程
    }
  }

  /**
   * 檢查認證狀態
   */
  async function checkAuth () {
    if (authCheckInFlight) {
      return authCheckInFlight
    }

    authCheckInFlight = (async () => {
      checkingAuth.value = true
      loading.value = true
      try {
        if (!isSupabaseAvailable()) {
          const storedAuth = localStorage.getItem('isAuthenticated')
          if (storedAuth === 'true') {
            const storedUser = localStorage.getItem('user')
            if (storedUser) {
              try {
                const parsedUser = JSON.parse(storedUser)
                user.value = parsedUser
                isAuthenticated.value = true
                return true
              } catch {
                // 忽略解析錯誤
              }
            }
          }
          return false
        }

        // 先等 INITIAL_SESSION，避免在 onAuthStateChange 內呼叫 getSession 造成死鎖
        await waitForAuthReady()

        if (isAuthenticated.value && user.value) {
          if (!userProfile.value) {
            try {
              await loadUserProfile(user.value.id)
              if (userProfile.value && !userProfile.value.is_active) {
                await logout()
                return false
              }
            } catch (error) {
              console.error('載入 user_profile 失敗', error)
            }
          }
          return true
        }

        let session
        try {
          session = await authService.getSession()
        } catch (error) {
          console.error('獲取 session 失敗', error)
          session = null
        }

        if (!session?.user) {
          user.value = null
          userProfile.value = null
          isAuthenticated.value = false
          token.value = null
          return false
        }

        user.value = session.user
        token.value = session.access_token
        isAuthenticated.value = true

        try {
          await loadUserProfile(session.user.id)
          if (userProfile.value && !userProfile.value.is_active) {
            await logout()
            return false
          }
        } catch (error) {
          console.error('載入 user_profile 失敗', error)
        }

        return true
      } catch (error) {
        console.error('檢查認證狀態錯誤', error)
        user.value = null
        userProfile.value = null
        isAuthenticated.value = false
        token.value = null
        return false
      } finally {
        loading.value = false
        checkingAuth.value = false
      }
    })()

    try {
      return await authCheckInFlight
    } finally {
      authCheckInFlight = null
    }
  }

  /**
   * 更新用戶資料
   */
  async function updateUser (userData) {
    if (!isSupabaseAvailable() || !user.value?.id) {
      return
    }

    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .update(userData)
        .eq('id', user.value.id)
        .select()
        .single()

      if (error) {
        throw error
      }

      if (data) {
        userProfile.value = data
      }
    } catch (error) {
      console.error('更新用戶資料失敗', error)
      throw error
    }
  }

  /**
   * 監聽 Supabase Auth 狀態變化
   */
  function setupAuthListener () {
    if (!isSupabaseAvailable()) {
      return
    }

    // 回呼內不可同步呼叫其他 Supabase Auth API，否則會與 getSession 死鎖
    supabase.auth.onAuthStateChange((event, session) => {
      setTimeout(async () => {
        console.log('Auth state changed:', event, session?.user?.id)

        try {
          if (event === 'INITIAL_SESSION') {
            if (session?.user) {
              user.value = session.user
              token.value = session.access_token
              isAuthenticated.value = true
              try {
                await loadUserProfile(session.user.id)
                if (userProfile.value && !userProfile.value.is_active) {
                  await logout()
                }
              } catch (error) {
                console.error('載入 user_profile 失敗', error)
              }
            } else {
              user.value = null
              userProfile.value = null
              isAuthenticated.value = false
              token.value = null
            }
            markAuthReady()
            return
          }

          if (event === 'SIGNED_IN' && session?.user) {
            user.value = session.user
            token.value = session.access_token
            isAuthenticated.value = true
            try {
              await loadUserProfile(session.user.id)
              if (userProfile.value && !userProfile.value.is_active) {
                await logout()
              }
            } catch (error) {
              console.error('載入 user_profile 失敗', error)
            }
          } else if (event === 'SIGNED_OUT') {
            user.value = null
            userProfile.value = null
            isAuthenticated.value = false
            token.value = null
            loading.value = false
            checkingAuth.value = false
          } else if (event === 'TOKEN_REFRESHED' && session) {
            token.value = session.access_token
          }
        } catch (error) {
          console.error('Auth state change 處理錯誤', error)
          if (event === 'SIGNED_OUT' || !session) {
            user.value = null
            userProfile.value = null
            isAuthenticated.value = false
            token.value = null
            loading.value = false
            checkingAuth.value = false
          }
        }
      }, 0)
    })
  }

  /**
   * 註冊新用戶
   */
  async function register (userData) {
    loading.value = true
    try {
      // 使用 Supabase Auth 註冊
      const result = await authService.signUp({
        email: userData.email,
        password: userData.password,
        username: userData.username,
        role: 'applicant',
      })

      if (result.user) {
        // 註冊成功後，更新 user_profiles，設置 is_active = false
        if (isSupabaseAvailable()) {
          const { error: updateError } = await supabase
            .from('user_profiles')
            .update({
              username: userData.username,
              department: userData.department || null,
              phone: userData.phone || null,
              is_active: false, // 新註冊用戶預設未啟用
            })
            .eq('id', result.user.id)

          if (updateError) {
            console.error('更新 user_profile 失敗', updateError)
            // 即使更新失敗，註冊也算成功（因為 trigger 會自動創建 profile）
          }
        }

        return {
          success: true,
          message: '註冊成功！請等待管理員審核啟用後即可登入。',
        }
      }

      return { success: false, message: '註冊失敗' }
    } catch (error) {
      console.error('註冊錯誤', error)
      // 處理常見的 Supabase Auth 錯誤
      let errorMessage = '註冊失敗，請稍後再試'
      if (error.message) {
        if (error.message.includes('User already registered') || error.message.includes('already registered')) {
          errorMessage = '此 Email 已被註冊'
        } else if (error.message.includes('Password')) {
          errorMessage = '密碼不符合要求'
        } else if (error.message.includes('Email')) {
          errorMessage = 'Email 格式不正確'
        } else {
          errorMessage = error.message
        }
      }
      return {
        success: false,
        message: errorMessage,
      }
    } finally {
      loading.value = false
    }
  }

  // 初始化：由 onAuthStateChange 的 INITIAL_SESSION 還原登入狀態
  if (isSupabaseAvailable()) {
    setupAuthListener()
  } else {
    markAuthReady()
  }

  return {
    // State
    user,
    userProfile,
    isAuthenticated,
    token,
    loading,
    checkingAuth,
    // Getters
    currentUser,
    isLoggedIn,
    userRole,
    // Actions
    login,
    logout,
    register,
    checkAuth,
    waitForAuthReady,
    updateUser,
    loadUserProfile,
  }
})
