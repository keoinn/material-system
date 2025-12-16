/**
 * Applications API Service - Supabase Implementation
 * 申請相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得申請列表
   */
  async getApplications (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('applications')
      .select('*')

    // 應用篩選條件
    if (filters.status && filters.status !== 'ALL') {
      query = query.eq('status', filters.status)
    }

    if (filters.itemCode) {
      query = query.ilike('item_code', `%${filters.itemCode}%`)
    }

    if (filters.applicant) {
      query = query.eq('applicant_id', filters.applicant)
    }

    if (filters.dateFrom) {
      query = query.gte('submit_date', filters.dateFrom)
    }

    if (filters.dateTo) {
      query = query.lte('submit_date', filters.dateTo)
    }

    if (filters.mainCategory) {
      query = query.eq('main_category_id', filters.mainCategory)
    }

    // 排序
    query = query.order('submit_date', { ascending: false })

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得單一申請
   */
  async getApplication (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('applications')
      .select('*')
      .eq('id', id)
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 建立申請
   */
  async createApplication (applicationData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('applications')
      .insert(applicationData)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 更新申請
   */
  async updateApplication (id, updates) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('applications')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 刪除申請
   */
  async deleteApplication (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('applications')
      .delete()
      .eq('id', id)

    if (error) {
      throw error
    }
  },
}

