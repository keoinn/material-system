/**
 * Attachments API Service - Axios Implementation
 * 附件相關 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得申請的附件列表
   */
  async getAttachments (applicationId) {
    const response = await apiClient.get(`/applications/${applicationId}/attachments`)
    return response.data || response
  },

  /**
   * 上傳附件
   */
  async uploadAttachment (applicationId, file, metadata = {}) {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('applicationId', applicationId)
    if (metadata.description) {
      formData.append('description', metadata.description)
    }

    const response = await apiClient.post(`/applications/${applicationId}/attachments`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    return response.data || response
  },

  /**
   * 刪除附件
   */
  async deleteAttachment (attachmentId) {
    await apiClient.delete(`/attachments/${attachmentId}`)
  },

  /**
   * 取得附件下載 URL
   */
  async getAttachmentUrl (attachmentId, expiresIn = 3600) {
    const response = await apiClient.get(`/attachments/${attachmentId}/url`, {
      params: { expiresIn },
    })
    return response.url || response
  },
}

