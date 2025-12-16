/**
 * Categories API Service
 * 產品分類相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import * as axiosImpl from './axios/categories.js'
import * as supabaseImpl from './supabase/categories.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 分類服務
 */
export const categoriesService = {
  /**
   * 取得所有大類
   * @returns {Promise<Array>}
   */
  async getMainCategories () {
    return getImplementation().getMainCategories()
  },

  /**
   * 取得中類（根據大類）
   * @param {string} mainCategoryCode - 大類代碼
   * @returns {Promise<Array>}
   */
  async getSubCategories (mainCategoryCode) {
    return getImplementation().getSubCategories(mainCategoryCode)
  },

  /**
   * 取得小類（根據大類）
   * @param {string} mainCategoryCode - 大類代碼
   * @returns {Promise<Array>}
   */
  async getSpecCategories (mainCategoryCode) {
    return getImplementation().getSpecCategories(mainCategoryCode)
  },

  /**
   * 取得完整分類樹（大類、中類、小類）
   * @returns {Promise<Object>}
   */
  async getCategoryTree () {
    return getImplementation().getCategoryTree()
  },
}
