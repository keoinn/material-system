/**
 * Form Fields API Service - Axios Implementation
 * 表單欄位定義管理 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得表單的所有欄位定義
   */
  async getFields (formId, filters = {}) {
    const response = await apiClient.get(`/forms/${formId}/fields`, {
      params: filters,
    })
    return response.data || response
  },

  /**
   * 取得單一欄位定義
   */
  async getField (formId, fieldIdOrKey) {
    const response = await apiClient.get(`/forms/${formId}/fields/${fieldIdOrKey}`)
    return response.data || response
  },

  /**
   * 建立欄位定義
   */
  async createField (formId, fieldData) {
    const response = await apiClient.post(`/forms/${formId}/fields`, fieldData)
    return response.data || response
  },

  /**
   * 更新欄位定義
   */
  async updateField (formId, fieldId, updates) {
    const response = await apiClient.put(`/forms/${formId}/fields/${fieldId}`, updates)
    return response.data || response
  },

  /**
   * 刪除欄位定義
   */
  async deleteField (formId, fieldId) {
    await apiClient.delete(`/forms/${formId}/fields/${fieldId}`)
  },

  /**
   * 批量更新欄位順序
   */
  async updateFieldOrders (formId, fieldOrders) {
    const response = await apiClient.put(`/forms/${formId}/fields/orders`, {
      fieldOrders,
    })
    return response.data || response
  },
}
