/**
 * Auth Store
 * 使用者認證與授權管理
 */
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref(null)
  const isAuthenticated = ref(false)
  const token = ref(null)

  // Getters
  const currentUser = computed(() => user.value)
  const isLoggedIn = computed(() => isAuthenticated.value && user.value !== null)
  const userRole = computed(() => user.value?.role || null)

  // Actions
  function login (username, password) {
    // TODO: 實際的登入邏輯
    // 目前使用 localStorage 模擬
    const storedUser = localStorage.getItem('user')
    if (storedUser) {
      const userData = JSON.parse(storedUser)
      if (userData.username === username) {
        user.value = userData
        isAuthenticated.value = true
        token.value = 'mock-token-' + Date.now()
        localStorage.setItem('auth_token', token.value)
        localStorage.setItem('isAuthenticated', 'true')
        return { success: true, user: userData }
      }
    }

    // 預設使用者（開發用）
    if (username === 'admin' || username === 'user') {
      const defaultUser = {
        id: '1',
        username,
        email: `${username}@company.com`,
        role: username === 'admin' ? 'admin' : 'applicant',
        department: 'IT',
      }
      user.value = defaultUser
      isAuthenticated.value = true
      token.value = 'mock-token-' + Date.now()
      localStorage.setItem('user', JSON.stringify(defaultUser))
      localStorage.setItem('auth_token', token.value)
      localStorage.setItem('isAuthenticated', 'true')
      return { success: true, user: defaultUser }
    }

    return { success: false, message: '使用者名稱或密碼錯誤' }
  }

  function logout () {
    user.value = null
    isAuthenticated.value = false
    token.value = null
    localStorage.removeItem('user')
    localStorage.removeItem('auth_token')
    localStorage.removeItem('isAuthenticated')
  }

  function checkAuth () {
    const storedAuth = localStorage.getItem('isAuthenticated')
    const storedUser = localStorage.getItem('user')
    const storedToken = localStorage.getItem('auth_token')

    // 如果缺少任何認證資訊，清除狀態並返回 false
    if (!storedAuth || storedAuth !== 'true' || !storedUser || !storedToken) {
      // 確保狀態已清除
      if (user.value || isAuthenticated.value) {
        logout()
      }
      return false
    }

    try {
      const parsedUser = JSON.parse(storedUser)
      // 驗證用戶資料完整性
      if (!parsedUser || !parsedUser.username) {
        logout()
        return false
      }
      user.value = parsedUser
      isAuthenticated.value = true
      token.value = storedToken
      return true
    } catch (error) {
      console.error('解析使用者資料失敗', error)
      logout()
      return false
    }
  }

  function updateUser (userData) {
    user.value = { ...user.value, ...userData }
    localStorage.setItem('user', JSON.stringify(user.value))
  }

  // 初始化時檢查認證狀態
  checkAuth()

  return {
    // State
    user,
    isAuthenticated,
    token,
    // Getters
    currentUser,
    isLoggedIn,
    userRole,
    // Actions
    login,
    logout,
    checkAuth,
    updateUser,
  }
})
