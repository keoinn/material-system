/**
 * Form Data API Service
 * 表單資料管理 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import axiosImpl from './axios/formData.js'
import supabaseImpl from './supabase/formData.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 表單資料服務
 */
export const formDataService = {
  /**
   * 取得表單資料（單一記錄的所有欄位值）
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {number|string} recordId - 記錄 ID
   * @param {object} options - 選項（includeFieldDefinitions 等）
   * @returns {Promise<Object>}
   */
  async getFormData (formId, recordId, options = {}) {
    return getImplementation().getFormData(formId, recordId, options)
  },

  /**
   * 取得表單資料列表（多筆記錄）
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {object} filters - 篩選條件
   * @param {object} options - 選項（includeFieldDefinitions 等）
   * @returns {Promise<Array>}
   */
  async getFormDataList (formId, filters = {}, options = {}) {
    return getImplementation().getFormDataList(formId, filters, options)
  },

  /**
   * 儲存表單資料（建立或更新）
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {number|string} recordId - 記錄 ID（可選，用於更新）
   * @param {object} formValues - 表單欄位值（key-value 格式）
   * @param {object} options - 選項（createRecord 等）
   * @returns {Promise<Object>}
   */
  async saveFormData (formId, recordId, formValues, options = {}) {
    return getImplementation().saveFormData(formId, recordId, formValues, options)
  },

  /**
   * 建立表單資料
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {object} formValues - 表單欄位值（key-value 格式）
   * @param {object} options - 選項
   * @returns {Promise<Object>}
   */
  async createFormData (formId, formValues, options = {}) {
    return getImplementation().createFormData(formId, formValues, options)
  },

  /**
   * 更新表單資料
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {number|string} recordId - 記錄 ID
   * @param {object} formValues - 表單欄位值（key-value 格式）
   * @param {object} options - 選項
   * @returns {Promise<Object>}
   */
  async updateFormData (formId, recordId, formValues, options = {}) {
    return getImplementation().updateFormData(formId, recordId, formValues, options)
  },

  /**
   * 刪除表單資料
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {number|string} recordId - 記錄 ID
   * @returns {Promise<void>}
   */
  async deleteFormData (formId, recordId) {
    return getImplementation().deleteFormData(formId, recordId)
  },

  /**
   * 取得待審核的表單資料列表（從 form_data_values 讀取）
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {object} filters - 篩選條件（status 等）
   * @returns {Promise<Array>} 返回格式化的申請列表
   */
  async getPendingFormDataList (formId, filters = {}) {
    const impl = getImplementation()
    if (impl.getPendingFormDataList) {
      return impl.getPendingFormDataList(formId, filters)
    }
    // 如果實作沒有此方法，使用 getFormDataList 作為後備
    return this.getFormDataList(formId, filters)
  },

  /**
   * 取得欄位值（單一欄位）
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {number|string} recordId - 記錄 ID
   * @param {string} fieldKey - 欄位鍵值
   * @returns {Promise<any>}
   */
  async getFieldValue (formId, recordId, fieldKey) {
    return getImplementation().getFieldValue(formId, recordId, fieldKey)
  },

  /**
   * 設定欄位值（單一欄位）
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {number|string} recordId - 記錄 ID
   * @param {string} fieldKey - 欄位鍵值
   * @param {any} value - 欄位值
   * @returns {Promise<Object>}
   */
  async setFieldValue (formId, recordId, fieldKey, value) {
    return getImplementation().setFieldValue(formId, recordId, fieldKey, value)
  },
}

export default formDataService
