/**
 * Users API Service - Axios Implementation
 * 使用者管理相關 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得所有使用者列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getUsers (filters = {}) {
    const response = await apiClient.get('/users', { params: filters })
    return response.data || response
  },

  /**
   * 取得單一使用者
   * @param {string} id - 使用者 ID
   * @returns {Promise<Object>}
   */
  async getUser (id) {
    const response = await apiClient.get(`/users/${id}`)
    return response.data || response
  },

  /**
   * 建立使用者
   * @param {object} userData - 使用者資料
   * @returns {Promise<Object>}
   */
  async createUser (userData) {
    const response = await apiClient.post('/users', userData)
    return response.data || response
  },

  /**
   * 更新使用者資料
   * @param {string} id - 使用者 ID
   * @param {object} updates - 更新資料
   * @returns {Promise<Object>}
   */
  async updateUser (id, updates) {
    const response = await apiClient.put(`/users/${id}`, updates)
    return response.data || response
  },

  /**
   * 刪除使用者
   * @param {string} id - 使用者 ID
   * @returns {Promise<void>}
   */
  async deleteUser (id) {
    await apiClient.delete(`/users/${id}`)
  },

  /**
   * 啟用/停用使用者
   * @param {string} id - 使用者 ID
   * @param {boolean} isActive - 是否啟用
   * @returns {Promise<Object>}
   */
  async toggleUserActive (id, isActive) {
    return this.updateUser(id, { is_active: isActive })
  },
}

