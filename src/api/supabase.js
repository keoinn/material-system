/**
 * Supabase Client Configuration
 * Supabase 客戶端初始化和 Storage 配置
 */
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY
const storageBucket = import.meta.env.VITE_SUPABASE_STORAGE_BUCKET || 'attachments'

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase 環境變數未設定，請檢查 .env 檔案')
}

/**
 * Supabase 客戶端實例
 */
export const supabase = supabaseUrl && supabaseAnonKey
  ? createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    })
  : null

/**
 * Storage Bucket 名稱
 */
export const STORAGE_BUCKET = storageBucket

/**
 * Storage 操作輔助函數
 */
export const storageService = {
  /**
   * 上傳檔案到 Storage
   * @param {File} file - 要上傳的檔案
   * @param {string} path - 檔案路徑（例如：'applications/123/image.jpg'）
   * @param {object} options - 上傳選項
   * @returns {Promise<{data: object, error: object}>}
   */
  async uploadFile(file, path, options = {}) {
    if (!supabase) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const {
      cacheControl = '3600',
      upsert = false,
      contentType,
    } = options

    const { data, error } = await supabase.storage
      .from(STORAGE_BUCKET)
      .upload(path, file, {
        cacheControl,
        upsert,
        contentType: contentType || file.type,
      })

    if (error) {
      console.error('檔案上傳失敗:', error)
      return { data: null, error }
    }

    // 取得公開 URL
    const { data: urlData } = supabase.storage
      .from(STORAGE_BUCKET)
      .getPublicUrl(path)

    return {
      data: {
        ...data,
        publicUrl: urlData.publicUrl,
      },
      error: null,
    }
  },

  /**
   * 刪除檔案
   * @param {string} path - 檔案路徑
   * @returns {Promise<{data: object, error: object}>}
   */
  async deleteFile(path) {
    if (!supabase) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase.storage
      .from(STORAGE_BUCKET)
      .remove([path])

    return { data, error }
  },

  /**
   * 取得檔案公開 URL
   * @param {string} path - 檔案路徑
   * @returns {string} 公開 URL
   */
  getPublicUrl(path) {
    if (!supabase) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data } = supabase.storage
      .from(STORAGE_BUCKET)
      .getPublicUrl(path)

    return data.publicUrl
  },

  /**
   * 取得檔案簽名 URL（私有檔案用）
   * @param {string} path - 檔案路徑
   * @param {number} expiresIn - 過期時間（秒）
   * @returns {Promise<string>} 簽名 URL
   */
  async getSignedUrl(path, expiresIn = 3600) {
    if (!supabase) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase.storage
      .from(STORAGE_BUCKET)
      .createSignedUrl(path, expiresIn)

    if (error) {
      throw error
    }

    return data.signedUrl
  },

  /**
   * 列出目錄下的檔案
   * @param {string} folder - 資料夾路徑
   * @param {object} options - 選項
   * @returns {Promise<{data: array, error: object}>}
   */
  async listFiles(folder = '', options = {}) {
    if (!supabase) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const {
      limit = 100,
      offset = 0,
      sortBy = { column: 'name', order: 'asc' },
    } = options

    const { data, error } = await supabase.storage
      .from(STORAGE_BUCKET)
      .list(folder, {
        limit,
        offset,
        sortBy,
      })

    return { data, error }
  },
}

/**
 * 檢查 Supabase 是否可用
 */
export function isSupabaseAvailable() {
  return supabase !== null
}

export default supabase
