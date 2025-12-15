/**
 * Applications API Service - Axios Implementation
 * 申請相關 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得申請列表
   */
  async getApplications(filters = {}) {
    const response = await apiClient.get('/applications', { params: filters })
    return response.data || response
  },

  /**
   * 取得單一申請
   */
  async getApplication(id) {
    const response = await apiClient.get(`/applications/${id}`)
    return response.data || response
  },

  /**
   * 建立申請
   */
  async createApplication(applicationData) {
    const response = await apiClient.post('/applications', applicationData)
    return response.data || response
  },

  /**
   * 更新申請
   */
  async updateApplication(id, updates) {
    const response = await apiClient.put(`/applications/${id}`, updates)
    return response.data || response
  },

  /**
   * 刪除申請
   */
  async deleteApplication(id) {
    await apiClient.delete(`/applications/${id}`)
  },
}

