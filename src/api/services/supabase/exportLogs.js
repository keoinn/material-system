/**
 * Export Logs API Service - Supabase Implementation
 * 匯出記錄相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 記錄匯出操作
   */
  async createExportLog (logData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 獲取當前用戶
    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser) {
      throw new Error('用戶未登入')
    }

    const { data, error } = await supabase
      .from('export_logs')
      .insert({
        category: logData.category || null,
        status: logData.status || null,
        start_date: logData.startDate || null,
        end_date: logData.endDate || null,
        record_count: logData.recordCount || 0,
        file_name: logData.fileName || '',
        file_path: logData.filePath || null,
        file_size: logData.fileSize || null,
        format: logData.format || 'CSV',
        exported_by_id: authUser.id,
      })
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 取得匯出記錄列表
   */
  async getExportLogs (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('export_logs')
      .select(`
        *,
        exported_by:user_profiles!export_logs_exported_by_id_fkey (
          id,
          username,
          email
        )
      `)
      .order('exported_at', { ascending: false })

    if (filters.exportedById) {
      query = query.eq('exported_by_id', filters.exportedById)
    }

    if (filters.startDate) {
      query = query.gte('exported_at', filters.startDate)
    }

    if (filters.endDate) {
      query = query.lte('exported_at', filters.endDate)
    }

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 更新下載次數
   */
  async incrementDownloadCount (logId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 先獲取當前記錄
    const { data: currentLog } = await supabase
      .from('export_logs')
      .select('download_count')
      .eq('id', logId)
      .single()

    if (!currentLog) {
      throw new Error('匯出記錄不存在')
    }

    const { data, error } = await supabase
      .from('export_logs')
      .update({
        download_count: (currentLog.download_count || 0) + 1,
      })
      .eq('id', logId)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },
}

