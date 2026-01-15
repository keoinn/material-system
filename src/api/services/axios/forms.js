/**
 * Forms API Service - Axios Implementation
 * 表單定義管理 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得所有表單列表
   */
  async getForms (filters = {}) {
    const response = await apiClient.get('/forms', { params: filters })
    return response.data || response
  },

  /**
   * 取得單一表單定義（含所有欄位）
   */
  async getForm (idOrCode, includeFields = true) {
    const response = await apiClient.get(`/forms/${idOrCode}`, {
      params: { includeFields },
    })
    return response.data || response
  },

  /**
   * 建立表單定義
   */
  async createForm (formData) {
    const response = await apiClient.post('/forms', formData)
    return response.data || response
  },

  /**
   * 更新表單定義
   */
  async updateForm (id, updates) {
    const response = await apiClient.put(`/forms/${id}`, updates)
    return response.data || response
  },

  /**
   * 刪除表單定義
   */
  async deleteForm (id) {
    await apiClient.delete(`/forms/${id}`)
  },

  /**
   * 複製表單定義
   */
  async duplicateForm (id, newFormData = {}) {
    const response = await apiClient.post(`/forms/${id}/duplicate`, newFormData)
    return response.data || response
  },
}
