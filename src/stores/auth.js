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
  const userRole = computed(() => userProfile.value?.role || currentUser.value?.role || null)

  // Actions
  /**
   * 登入（支援 email 或 username）
   */
  async function login (identifier, password) {
    loading.value = true
    try {
      // 如果 identifier 不是 email 格式，嘗試使用 username@company.com 格式
      // 注意：Supabase Auth 只支援 email/password 登入
      // 如果輸入的是 username，會嘗試使用 username@company.com 格式
      let email = identifier
      if (!identifier.includes('@')) {
        // 可能是 username，嘗試使用 username@company.com 格式
        // 這適用於開發環境或特定配置的用戶
        email = `${identifier}@company.com`
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
    // 避免重複檢查
    if (checkingAuth.value) {
      // 如果正在檢查，直接返回當前認證狀態，不等待
      // 這樣可以避免 router guard 超時
      return isAuthenticated.value && user.value !== null
    }

    checkingAuth.value = true
    loading.value = true
    try {
      if (!isSupabaseAvailable()) {
        // 如果 Supabase 不可用，回退到開發模式
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
        // 確保重置 loading 狀態
        loading.value = false
        checkingAuth.value = false
        return false
      }

      // 檢查 Supabase session
      let session
      try {
        session = await authService.getSession()
      } catch (error) {
        console.error('獲取 session 失敗', error)
        session = null
      }

      if (!session) {
        user.value = null
        userProfile.value = null
        isAuthenticated.value = false
        token.value = null
        // 確保重置 loading 狀態
        loading.value = false
        checkingAuth.value = false
        return false
      }

      // 獲取當前用戶
      let authUser
      try {
        authUser = await authService.getCurrentUser()
      } catch (error) {
        console.error('獲取當前用戶失敗', error)
        authUser = null
      }

      if (!authUser) {
        user.value = null
        userProfile.value = null
        isAuthenticated.value = false
        token.value = null
        // 確保重置 loading 狀態
        loading.value = false
        checkingAuth.value = false
        return false
      }

      user.value = authUser
      token.value = session.access_token
      isAuthenticated.value = true

      // 先重置狀態，允許其他檢查繼續
      loading.value = false
      checkingAuth.value = false

      // 載入 user_profile（異步執行，不阻塞認證流程）
      Promise.resolve().then(async () => {
        try {
          await loadUserProfile(authUser.id)
          // 檢查用戶是否已啟用（在 profile 載入後）
          if (userProfile.value && !userProfile.value.is_active) {
            try {
              await logout()
            } catch (error) {
              console.error('登出失敗', error)
            }
          }
        } catch (error) {
          console.error('載入 user_profile 失敗', error)
          // 即使載入失敗，也允許認證繼續
        }
      })

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

    supabase.auth.onAuthStateChange(async (event, session) => {
      console.log('Auth state changed:', event, session?.user?.id)

      try {
        if (event === 'SIGNED_IN' && session?.user) {
          user.value = session.user
          token.value = session.access_token
          isAuthenticated.value = true
          // 異步載入 user_profile，不阻塞
          loadUserProfile(session.user.id).then(() => {
            // 檢查用戶是否已啟用
            if (userProfile.value && !userProfile.value.is_active) {
              logout().catch(error => {
                console.error('登出失敗', error)
              })
            }
          }).catch(error => {
            console.error('載入 user_profile 失敗', error)
          })
        } else if (event === 'SIGNED_OUT') {
          user.value = null
          userProfile.value = null
          isAuthenticated.value = false
          token.value = null
          loading.value = false
          checkingAuth.value = false
        } else if (event === 'TOKEN_REFRESHED' && session) {
          token.value = session.access_token
        } else if (event === 'INITIAL_SESSION' && session) {
          // 初始化 session，不設置 loading
          if (session.user) {
            user.value = session.user
            token.value = session.access_token
            isAuthenticated.value = true
            // 異步載入 user_profile
            loadUserProfile(session.user.id).catch(error => {
              console.error('載入 user_profile 失敗', error)
            })
          }
        }
      } catch (error) {
        console.error('Auth state change 處理錯誤', error)
        // 確保狀態正確
        if (event === 'SIGNED_OUT' || !session) {
          user.value = null
          userProfile.value = null
          isAuthenticated.value = false
          token.value = null
          loading.value = false
          checkingAuth.value = false
        }
      }
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

  // 初始化
  setupAuthListener()
  // 異步初始化認證檢查，不阻塞 store 創建
  // 使用 setTimeout 確保 store 完全初始化後再檢查
  // 不設置 loading，避免影響 UI 顯示
  setTimeout(() => {
    // 只在有 session 時才檢查（避免不必要的檢查）
    if (isSupabaseAvailable()) {
      supabase.auth.getSession().then(({ data: { session } }) => {
        if (session) {
          checkAuth().catch(error => {
            console.error('初始化認證檢查失敗', error)
            // 確保重置狀態
            loading.value = false
            checkingAuth.value = false
          })
        } else {
          // 沒有 session，確保狀態已清除
          user.value = null
          userProfile.value = null
          isAuthenticated.value = false
          token.value = null
          loading.value = false
          checkingAuth.value = false
        }
      }).catch(error => {
        console.error('獲取初始 session 失敗', error)
        // 確保重置狀態
        loading.value = false
        checkingAuth.value = false
      })
    }
  }, 100) // 稍微延遲，確保所有組件都已初始化

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
    updateUser,
    loadUserProfile,
  }
})
