/**
 * Settings API Service - Axios Implementation
 * 系統設定相關 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得所有系統設定
   */
  async getSettings() {
    const response = await apiClient.get('/settings')
    return response.data || response
  },

  /**
   * 取得單一設定值
   */
  async getSetting(key) {
    const response = await apiClient.get(`/settings/${key}`)
    return response.value || response
  },

  /**
   * 更新設定值
   */
  async updateSetting(key, value, type = null) {
    const response = await apiClient.put(`/settings/${key}`, { value, type })
    return response.data || response
  },

  /**
   * 批量更新設定
   */
  async updateSettings(settings) {
    const response = await apiClient.put('/settings', settings)
    return response.data || response
  },
}

