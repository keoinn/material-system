/**
 * Settings Store
 * 系統設定管理
 */
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useSettingsStore = defineStore('settings', () => {
  // State
  const settings = ref({
    serialDigits: 5,
    serialStart: '1',
    autoApprove: false,
    emailNotify: true,
    approvalLevel: 1,
  })

  // Actions
  function loadSettings () {
    try {
      const stored = localStorage.getItem('settings_v35')
      if (stored) {
        settings.value = { ...settings.value, ...JSON.parse(stored) }
      }
    } catch (error) {
      console.error('載入設定失敗', error)
    }
  }

  function saveSettings (newSettings) {
    try {
      settings.value = { ...settings.value, ...newSettings }
      localStorage.setItem('settings_v35', JSON.stringify(settings.value))
      return true
    } catch (error) {
      console.error('儲存設定失敗', error)
      return false
    }
  }

  function resetSettings () {
    settings.value = {
      serialDigits: 5,
      serialStart: '1',
      autoApprove: false,
      emailNotify: true,
      approvalLevel: 1,
    }
    saveSettings(settings.value)
  }

  // 初始化
  loadSettings()

  return {
    // State
    settings,
    // Actions
    loadSettings,
    saveSettings,
    resetSettings,
  }
})
