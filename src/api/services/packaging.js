/**
 * Packaging API Service
 * 包裝相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import * as axiosImpl from './axios/packaging.js'
import * as supabaseImpl from './supabase/packaging.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation() {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 包裝服務
 */
export const packagingService = {
  /**
   * 取得所有包裝類別
   * @returns {Promise<Array>}
   */
  async getPackagingCategories() {
    return getImplementation().getPackagingCategories()
  },

  /**
   * 取得包裝選項（根據類別）
   * @param {string|number} categoryId - 類別 ID 或 code
   * @returns {Promise<Array>}
   */
  async getPackagingOptions(categoryId) {
    return getImplementation().getPackagingOptions(categoryId)
  },

  /**
   * 取得所有包裝選項（依類別分組）
   * @returns {Promise<Object>}
   */
  async getAllPackagingOptions() {
    return getImplementation().getAllPackagingOptions()
  },

  /**
   * 取得類別預設包裝選項
   * @param {string} mainCategoryCode - 產品大類代碼
   * @returns {Promise<Object>}
   */
  async getCategoryDefaults(mainCategoryCode) {
    return getImplementation().getCategoryDefaults(mainCategoryCode)
  },

  /**
   * 取得申請的包裝選項
   * @param {number|string} applicationId - 申請 ID
   * @returns {Promise<Array>}
   */
  async getApplicationPackaging(applicationId) {
    return getImplementation().getApplicationPackaging(applicationId)
  },

  /**
   * 儲存申請的包裝選項
   * @param {number|string} applicationId - 申請 ID
   * @param {Array} packagingData - 包裝資料陣列
   * @returns {Promise<Array>}
   */
  async saveApplicationPackaging(applicationId, packagingData) {
    return getImplementation().saveApplicationPackaging(applicationId, packagingData)
  },
}
