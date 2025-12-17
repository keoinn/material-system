/**
 * Export Logs API Service
 * 匯出記錄相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import supabaseImpl from './supabase/exportLogs.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  // 目前只實作 Supabase 版本
  return supabaseImpl
}

/**
 * 匯出記錄服務
 */
export const exportLogsService = {
  /**
   * 記錄匯出操作
   * @param {object} logData - 匯出記錄資料
   * @returns {Promise<Object>}
   */
  async createExportLog (logData) {
    return getImplementation().createExportLog(logData)
  },

  /**
   * 取得匯出記錄列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getExportLogs (filters = {}) {
    return getImplementation().getExportLogs(filters)
  },

  /**
   * 更新下載次數
   * @param {number|string} logId - 記錄 ID
   * @returns {Promise<Object>}
   */
  async incrementDownloadCount (logId) {
    return getImplementation().incrementDownloadCount(logId)
  },
}

