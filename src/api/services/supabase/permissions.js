/**
 * Permissions API Service - Supabase Implementation
 * 權限管理相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有權限列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getPermissions (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('permissions')
      .select('*')
      .order('display_order', { ascending: true })
      .order('id', { ascending: true })

    if (filters.module) {
      query = query.eq('module', filters.module)
    }

    if (filters.is_active !== undefined && filters.is_active !== null) {
      query = query.eq('is_active', filters.is_active)
    }

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得單一權限
   * @param {string|number} id - 權限 ID 或 permission_code
   * @returns {Promise<Object>}
   */
  async getPermission (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 permission_code
    const isNumeric = /^\d+$/.test(String(id))
    const query = isNumeric
      ? supabase.from('permissions').select('*').eq('id', id).single()
      : supabase.from('permissions').select('*').eq('permission_code', id).single()

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 建立權限
   * @param {object} permissionData - 權限資料
   * @returns {Promise<Object>}
   */
  async createPermission (permissionData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id || null

    const { data, error } = await supabase
      .from('permissions')
      .insert({
        ...permissionData,
        created_by_id: userId,
        updated_by_id: userId,
      })
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 更新權限
   * @param {string|number} id - 權限 ID
   * @param {object} permissionData - 權限資料
   * @returns {Promise<Object>}
   */
  async updatePermission (id, permissionData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id || null

    const { data, error } = await supabase
      .from('permissions')
      .update({
        ...permissionData,
        updated_by_id: userId,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 刪除權限
   * @param {string|number} id - 權限 ID
   * @returns {Promise<void>}
   */
  async deletePermission (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 檢查是否為系統內建權限
    const permission = await this.getPermission(id)
    if (permission.is_system_permission) {
      throw new Error('無法刪除系統內建權限')
    }

    const { error } = await supabase
      .from('permissions')
      .delete()
      .eq('id', id)

    if (error) {
      throw error
    }
  },
}
