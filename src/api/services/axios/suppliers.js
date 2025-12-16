/**
 * Suppliers API Service - Axios Implementation
 * 供應商相關 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得所有供應商
   */
  async getSuppliers (filters = {}) {
    const response = await apiClient.get('/suppliers', { params: filters })
    return response.data || response
  },

  /**
   * 取得單一供應商
   */
  async getSupplier (id) {
    const response = await apiClient.get(`/suppliers/${id}`)
    return response.data || response
  },

  /**
   * 建立供應商
   */
  async createSupplier (supplierData) {
    const response = await apiClient.post('/suppliers', supplierData)
    return response.data || response
  },

  /**
   * 更新供應商
   */
  async updateSupplier (id, updates) {
    const response = await apiClient.put(`/suppliers/${id}`, updates)
    return response.data || response
  },

  /**
   * 刪除供應商
   */
  async deleteSupplier (id) {
    await apiClient.delete(`/suppliers/${id}`)
  },
}

