/**
 * Categories API Service - Axios Implementation
 * 產品分類相關 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得所有大類
   */
  async getMainCategories() {
    const response = await apiClient.get('/categories/main')
    return response.data || response
  },

  /**
   * 取得中類（根據大類）
   */
  async getSubCategories(mainCategoryCode) {
    const response = await apiClient.get(`/categories/sub/${mainCategoryCode}`)
    return response.data || response
  },

  /**
   * 取得小類（根據大類）
   */
  async getSpecCategories(mainCategoryCode) {
    const response = await apiClient.get(`/categories/spec/${mainCategoryCode}`)
    return response.data || response
  },

  /**
   * 取得完整分類樹（大類、中類、小類）
   */
  async getCategoryTree() {
    const response = await apiClient.get('/categories/tree')
    return response.data || response
  },
}

