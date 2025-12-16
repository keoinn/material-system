/**
 * Testing Platform Store
 * 測試平台認證管理
 */
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

export const useTestingStore = defineStore('testing', () => {
  // State
  const isAuthenticated = ref(false)
  const showSuccessAlert = ref(true) // 控制成功提示的顯示

  // Getters
  const isTestingPlatformAuthenticated = computed(() => isAuthenticated.value)

  // Actions
  function login (password) {
    // 測試平台密碼（未來可以從環境變數或後端取得）
    const TEST_PASSWORD = 'admin'

    if (password === TEST_PASSWORD) {
      isAuthenticated.value = true
      showSuccessAlert.value = true
      // 將驗證狀態存入 localStorage（持久化）
      localStorage.setItem('testing_platform_verified', 'true')
      return { success: true }
    }

    return { success: false, message: '密碼錯誤，請重新輸入' }
  }

  function logout () {
    isAuthenticated.value = false
    showSuccessAlert.value = true
    localStorage.removeItem('testing_platform_verified')
  }

  function checkAuth () {
    const verified = localStorage.getItem('testing_platform_verified')
    if (verified === 'true') {
      isAuthenticated.value = true
      return true
    }
    return false
  }

  function hideSuccessAlert () {
    showSuccessAlert.value = false
  }

  function showSuccessAlertAgain () {
    showSuccessAlert.value = true
  }

  // 初始化時檢查認證狀態
  checkAuth()

  return {
    // State
    isAuthenticated,
    showSuccessAlert,
    // Getters
    isTestingPlatformAuthenticated,
    // Actions
    login,
    logout,
    checkAuth,
    hideSuccessAlert,
    showSuccessAlertAgain,
  }
})

