/**
 * Settings Store
 * 系統設定管理
 */
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { settingsService } from '@/api/services/settings'

export const useSettingsStore = defineStore('settings', () => {
  // State
  const settings = ref({
    serialDigits: 5,
    serialStart: '1',
    autoApprove: false,
    emailNotify: true,
    approvalLevel: 1,
  })

  const loading = ref(false)

  // Actions
  async function loadSettings () {
    loading.value = true
    try {
      const data = await settingsService.getSettings()
      if (data) {
        settings.value = {
          serialDigits: data.serialDigits ?? 5,
          serialStart: data.serialStart ?? '1',
          autoApprove: data.autoApprove ?? false,
          emailNotify: data.emailNotify ?? true,
          approvalLevel: data.approvalLevel ?? 1,
        }
      }
    } catch (error) {
      console.error('載入設定失敗', error)
      // 如果載入失敗，使用預設值
      settings.value = {
        serialDigits: 5,
        serialStart: '1',
        autoApprove: false,
        emailNotify: true,
        approvalLevel: 1,
      }
    } finally {
      loading.value = false
    }
  }

  async function saveSettings (newSettings) {
    loading.value = true
    try {
      settings.value = { ...settings.value, ...newSettings }
      await settingsService.updateSettings(newSettings)
      return true
    } catch (error) {
      console.error('儲存設定失敗', error)
      return false
    } finally {
      loading.value = false
    }
  }

  async function resetSettings () {
    loading.value = true
    try {
      const defaultSettings = {
        serialDigits: 5,
        serialStart: '1',
        autoApprove: false,
        emailNotify: true,
        approvalLevel: 1,
      }
      settings.value = defaultSettings
      await settingsService.updateSettings(defaultSettings)
    } catch (error) {
      console.error('恢復預設設定失敗', error)
    } finally {
      loading.value = false
    }
  }

  // 初始化（異步載入）
  loadSettings()

  return {
    // State
    settings,
    loading,
    // Actions
    loadSettings,
    saveSettings,
    resetSettings,
  }
})
