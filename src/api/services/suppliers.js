/**
 * Suppliers API Service
 * 供應商相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import * as axiosImpl from './axios/suppliers.js'
import * as supabaseImpl from './supabase/suppliers.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 供應商服務
 */
export const suppliersService = {
  /**
   * 取得所有供應商
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getSuppliers (filters = {}) {
    return getImplementation().getSuppliers(filters)
  },

  /**
   * 取得單一供應商
   * @param {number|string} id - 供應商 ID 或 code
   * @returns {Promise<Object>}
   */
  async getSupplier (id) {
    return getImplementation().getSupplier(id)
  },

  /**
   * 建立供應商
   * @param {object} supplierData - 供應商資料
   * @returns {Promise<Object>}
   */
  async createSupplier (supplierData) {
    return getImplementation().createSupplier(supplierData)
  },

  /**
   * 更新供應商
   * @param {number|string} id - 供應商 ID
   * @param {object} updates - 更新資料
   * @returns {Promise<Object>}
   */
  async updateSupplier (id, updates) {
    return getImplementation().updateSupplier(id, updates)
  },

  /**
   * 刪除供應商
   * @param {number|string} id - 供應商 ID
   * @returns {Promise<void>}
   */
  async deleteSupplier (id) {
    return getImplementation().deleteSupplier(id)
  },
}
