/**
 * Packaging API Service
 * 包裝相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import axiosImpl from './axios/packaging.js'
import supabaseImpl from './supabase/packaging.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
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
  async getPackagingCategories () {
    return getImplementation().getPackagingCategories()
  },

  /**
   * 取得包裝選項（根據類別）
   * @param {string|number} categoryId - 類別 ID 或 code
   * @returns {Promise<Array>}
   */
  async getPackagingOptions (categoryId) {
    return getImplementation().getPackagingOptions(categoryId)
  },

  /**
   * 取得所有包裝選項（依類別分組）
   * @returns {Promise<Object>}
   */
  async getAllPackagingOptions () {
    return getImplementation().getAllPackagingOptions()
  },

  /**
   * 取得類別預設包裝選項
   * @param {string} mainCategoryCode - 產品大類代碼
   * @returns {Promise<Object>}
   */
  async getCategoryDefaults (mainCategoryCode) {
    return getImplementation().getCategoryDefaults(mainCategoryCode)
  },

  /**
   * 取得申請的包裝選項
   * @param {number|string} applicationId - 申請 ID
   * @returns {Promise<Array>}
   */
  async getApplicationPackaging (applicationId) {
    return getImplementation().getApplicationPackaging(applicationId)
  },

  /**
   * 儲存申請的包裝選項
   * @param {number|string} applicationId - 申請 ID
   * @param {Array} packagingData - 包裝資料陣列
   * @returns {Promise<Array>}
   */
  async saveApplicationPackaging (applicationId, packagingData) {
    return getImplementation().saveApplicationPackaging(applicationId, packagingData)
  },

  /**
   * 儲存類別預設包裝模板
   * @param {string} mainCategoryCode - 產品大類代碼
   * @param {Object} templateData - 模板資料 { categoryCode: [optionCode, ...] }
   * @returns {Promise<Array>}
   */
  async saveCategoryDefaults (mainCategoryCode, templateData) {
    return getImplementation().saveCategoryDefaults(mainCategoryCode, templateData)
  },

  /**
   * 刪除類別預設包裝模板
   * @param {string} mainCategoryCode - 產品大類代碼
   * @returns {Promise<void>}
   */
  async deleteCategoryDefaults (mainCategoryCode) {
    return getImplementation().deleteCategoryDefaults(mainCategoryCode)
  },

  /**
   * 取得包裝說明模板
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {string} templateType - 模板類型（H, S, M, D, F, B, I, O）
   * @returns {Promise<Object|null>}
   */
  async getPackagingTemplate (formId, templateType) {
    return getImplementation().getPackagingTemplate(formId, templateType)
  },

  /**
   * 儲存包裝說明模板
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {string} templateType - 模板類型（H, S, M, D, F, B, I, O）
   * @param {Object} templateValues - 模板值（JSON 格式）
   * @returns {Promise<Object>}
   */
  async savePackagingTemplate (formId, templateType, templateValues) {
    return getImplementation().savePackagingTemplate(formId, templateType, templateValues)
  },

  /**
   * 刪除指定表單的所有包裝說明模板
   * @param {number|string} formId - 表單 ID 或 form_code
   * @returns {Promise<void>}
   */
  async deleteAllPackagingTemplatesForForm (formId) {
    const impl = getImplementation()
    if (impl.deleteAllPackagingTemplatesForForm) {
      return impl.deleteAllPackagingTemplatesForForm(formId)
    }
    throw new Error('目前後端不支援刪除表單包裝模板')
  },
}
