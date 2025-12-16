/**
 * Attachments API Service - Supabase Implementation
 * 附件相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, STORAGE_BUCKET, storageService, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得申請的附件列表
   */
  async getAttachments (applicationId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('attachments')
      .select('*')
      .eq('application_id', applicationId)
      .order('uploaded_at', { ascending: false })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 上傳附件
   */
  async uploadAttachment (applicationId, file, metadata = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 產生檔案路徑：applications/{applicationId}/{timestamp}-{filename}
    const timestamp = Date.now()
    const sanitizedFileName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_')
    const filePath = `applications/${applicationId}/${timestamp}-${sanitizedFileName}`

    // 上傳檔案到 Storage
    const { data: uploadData, error: uploadError } = await storageService.uploadFile(
      file,
      filePath,
      {
        contentType: file.type,
      },
    )

    if (uploadError) {
      throw uploadError
    }

    // 判斷檔案類型
    let fileType = 'other'
    if (file.type.startsWith('image/')) {
      fileType = 'image'
    } else if (file.type.includes('pdf') || file.type.includes('document') || file.type.includes('word')) {
      fileType = 'document'
    } else if (file.type.includes('dwg') || file.type.includes('dxf') || /\.(dwg|dxf)$/i.test(file.name)) {
      fileType = 'drawing'
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const uploadedById = user?.id

    // 建立附件記錄
    const attachmentData = {
      application_id: applicationId,
      file_name: uploadData.name,
      original_file_name: file.name,
      file_type: fileType,
      file_size: file.size,
      mime_type: file.type,
      file_url: uploadData.publicUrl,
      uploaded_by_id: uploadedById,
      description: metadata.description || null,
    }

    // 如果是圖片，產生縮圖 URL（可以後續實作）
    if (fileType === 'image') {
      attachmentData.thumbnail_url = uploadData.publicUrl // 暫時使用原圖
    }

    const { data, error } = await supabase
      .from('attachments')
      .insert(attachmentData)
      .select()
      .single()

    if (error) {
      // 如果插入失敗，刪除已上傳的檔案
      await storageService.deleteFile(filePath)
      throw error
    }

    return data
  },

  /**
   * 刪除附件
   */
  async deleteAttachment (attachmentId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 先取得附件資料（包含檔案路徑）
    const { data: attachment, error: fetchError } = await supabase
      .from('attachments')
      .select('file_url')
      .eq('id', attachmentId)
      .single()

    if (fetchError) {
      throw fetchError
    }

    // 從 Storage 刪除檔案
    if (attachment.file_url) {
      // 從 URL 中提取路徑
      const urlParts = attachment.file_url.split(`${STORAGE_BUCKET}/`)
      if (urlParts.length > 1) {
        const filePath = urlParts[1]
        await storageService.deleteFile(filePath)
      }
    }

    // 刪除資料庫記錄
    const { error } = await supabase
      .from('attachments')
      .delete()
      .eq('id', attachmentId)

    if (error) {
      throw error
    }
  },

  /**
   * 取得附件下載 URL
   */
  async getAttachmentUrl (attachmentId, expiresIn = 3600) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data: attachment, error } = await supabase
      .from('attachments')
      .select('file_url')
      .eq('id', attachmentId)
      .single()

    if (error) {
      throw error
    }

    // 如果是公開檔案，直接返回 URL
    if (attachment.file_url && attachment.file_url.includes('public')) {
      return attachment.file_url
    }

    // 如果是私有檔案，產生簽名 URL
    const urlParts = attachment.file_url.split(`${STORAGE_BUCKET}/`)
    if (urlParts.length > 1) {
      const filePath = urlParts[1]
      return await storageService.getSignedUrl(filePath, expiresIn)
    }

    return attachment.file_url
  },
}

