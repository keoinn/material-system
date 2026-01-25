/**
 * Option Workbooks API Service
 * 選項活頁簿 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import supabaseImpl from './supabase/optionWorkbooks.js'
// import axiosImpl from './axios/optionWorkbooks.js' // 未來可實作

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? null : supabaseImpl // 目前只支援 Supabase
}

/**
 * 選項活頁簿服務
 */
export const optionWorkbooksService = {
  /**
   * 取得所有活頁簿列表
   * @param {Object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getWorkbooks (filters = {}) {
    const impl = getImplementation()
    if (!impl) throw new Error('選項活頁簿服務目前僅支援 Supabase')
    return impl.getWorkbooks(filters)
  },

  /**
   * 取得單一活頁簿（含欄位定義和資料）
   * @param {number|string} idOrKey - 活頁簿 ID 或 workbook_key
   * @param {boolean} includeColumns - 是否包含欄位定義
   * @param {boolean} includeRows - 是否包含資料行
   * @returns {Promise<Object>}
   */
  async getWorkbook (idOrKey, includeColumns = true, includeRows = true) {
    const impl = getImplementation()
    if (!impl) throw new Error('選項活頁簿服務目前僅支援 Supabase')
    return impl.getWorkbook(idOrKey, includeColumns, includeRows)
  },

  /**
   * 建立活頁簿
   * @param {Object} workbookData - 活頁簿資料
   * @returns {Promise<Object>}
   */
  async createWorkbook (workbookData) {
    const impl = getImplementation()
    if (!impl) throw new Error('選項活頁簿服務目前僅支援 Supabase')
    return impl.createWorkbook(workbookData)
  },

  /**
   * 更新活頁簿
   * @param {number} id - 活頁簿 ID
   * @param {Object} updates - 更新資料
   * @returns {Promise<Object>}
   */
  async updateWorkbook (id, updates) {
    const impl = getImplementation()
    if (!impl) throw new Error('選項活頁簿服務目前僅支援 Supabase')
    return impl.updateWorkbook(id, updates)
  },

  /**
   * 刪除活頁簿
   * @param {number} id - 活頁簿 ID
   * @returns {Promise<void>}
   */
  async deleteWorkbook (id) {
    const impl = getImplementation()
    if (!impl) throw new Error('選項活頁簿服務目前僅支援 Supabase')
    return impl.deleteWorkbook(id)
  },

  /**
   * 取得活頁簿的選項列表（用於表單選項）
   * @param {string} workbookKey - 活頁簿 key
   * @param {string} optionColumnKey - 選項欄位 key（可選）
   * @returns {Promise<Array>}
   */
  async getWorkbookOptions (workbookKey, optionColumnKey = null) {
    const impl = getImplementation()
    if (!impl) throw new Error('選項活頁簿服務目前僅支援 Supabase')
    return impl.getWorkbookOptions(workbookKey, optionColumnKey)
  },
}

export default optionWorkbooksService
