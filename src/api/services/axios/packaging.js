/**
 * Packaging API Service - Axios Implementation
 * 包裝相關 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得所有包裝類別
   */
  async getPackagingCategories() {
    const response = await apiClient.get('/packaging/categories')
    return response.data || response
  },

  /**
   * 取得包裝選項（根據類別）
   */
  async getPackagingOptions(categoryId) {
    const response = await apiClient.get(`/packaging/options/${categoryId}`)
    return response.data || response
  },

  /**
   * 取得所有包裝選項（依類別分組）
   */
  async getAllPackagingOptions() {
    const response = await apiClient.get('/packaging/options')
    return response.data || response
  },

  /**
   * 取得類別預設包裝選項
   */
  async getCategoryDefaults(mainCategoryCode) {
    const response = await apiClient.get(`/packaging/defaults/${mainCategoryCode}`)
    return response.data || response
  },

  /**
   * 取得申請的包裝選項
   */
  async getApplicationPackaging(applicationId) {
    const response = await apiClient.get(`/applications/${applicationId}/packaging`)
    return response.data || response
  },

  /**
   * 儲存申請的包裝選項
   */
  async saveApplicationPackaging(applicationId, packagingData) {
    const response = await apiClient.post(`/applications/${applicationId}/packaging`, {
      packaging: packagingData,
    })
    return response.data || response
  },
}

