/**
 * Form Fields API Service
 * 表單欄位定義管理 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import axiosImpl from './axios/formFields.js'
import supabaseImpl from './supabase/formFields.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 表單欄位定義服務
 */
export const formFieldsService = {
  /**
   * 取得表單的所有欄位定義
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {object} filters - 篩選條件（field_group, is_visible 等）
   * @returns {Promise<Array>}
   */
  async getFields (formId, filters = {}) {
    return getImplementation().getFields(formId, filters)
  },

  /**
   * 取得單一欄位定義
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {number|string} fieldIdOrKey - 欄位 ID 或 field_key
   * @returns {Promise<Object>}
   */
  async getField (formId, fieldIdOrKey) {
    return getImplementation().getField(formId, fieldIdOrKey)
  },

  /**
   * 建立欄位定義
   * @param {number|string} formId - 表單 ID
   * @param {object} fieldData - 欄位資料
   * @returns {Promise<Object>}
   */
  async createField (formId, fieldData) {
    return getImplementation().createField(formId, fieldData)
  },

  /**
   * 更新欄位定義
   * @param {number|string} formId - 表單 ID
   * @param {number|string} fieldId - 欄位 ID
   * @param {object} updates - 更新資料
   * @returns {Promise<Object>}
   */
  async updateField (formId, fieldId, updates) {
    return getImplementation().updateField(formId, fieldId, updates)
  },

  /**
   * 刪除欄位定義
   * @param {number|string} formId - 表單 ID
   * @param {number|string} fieldId - 欄位 ID
   * @returns {Promise<void>}
   */
  async deleteField (formId, fieldId) {
    return getImplementation().deleteField(formId, fieldId)
  },

  /**
   * 批量更新欄位順序
   * @param {number|string} formId - 表單 ID
   * @param {Array<{id: number, display_order: number}>} fieldOrders - 欄位順序陣列
   * @returns {Promise<void>}
   */
  async updateFieldOrders (formId, fieldOrders) {
    const impl = getImplementation()
    if (impl.updateFieldOrders) {
      return impl.updateFieldOrders(formId, fieldOrders)
    }
    // 如果實作沒有 updateFieldOrders 方法，逐個更新
    for (const { id, display_order } of fieldOrders) {
      await this.updateField(formId, id, { display_order })
    }
  },
}

export default formFieldsService
