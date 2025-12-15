/**
 * Attachments API Service
 * 附件相關 API 服務（包含檔案上傳）
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import * as axiosImpl from './axios/attachments.js'
import * as supabaseImpl from './supabase/attachments.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation() {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 附件服務
 */
export const attachmentsService = {
  /**
   * 取得申請的附件列表
   * @param {number|string} applicationId - 申請 ID
   * @returns {Promise<Array>}
   */
  async getAttachments(applicationId) {
    return getImplementation().getAttachments(applicationId)
  },

  /**
   * 上傳附件
   * @param {number|string} applicationId - 申請 ID
   * @param {File} file - 檔案物件
   * @param {object} metadata - 檔案元資料
   * @returns {Promise<Object>}
   */
  async uploadAttachment(applicationId, file, metadata = {}) {
    return getImplementation().uploadAttachment(applicationId, file, metadata)
  },

  /**
   * 刪除附件
   * @param {number|string} attachmentId - 附件 ID
   * @returns {Promise<void>}
   */
  async deleteAttachment(attachmentId) {
    return getImplementation().deleteAttachment(attachmentId)
  },

  /**
   * 取得附件下載 URL
   * @param {number|string} attachmentId - 附件 ID
   * @param {number} expiresIn - 過期時間（秒，預設 3600）
   * @returns {Promise<string>}
   */
  async getAttachmentUrl(attachmentId, expiresIn = 3600) {
    return getImplementation().getAttachmentUrl(attachmentId, expiresIn)
  },
}
