/**
 * Roles API Service - Supabase Implementation
 * 角色管理相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有角色列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getRoles (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('roles')
      .select('*')
      .order('display_order', { ascending: true })
      .order('id', { ascending: true })

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
   * 取得單一角色
   * @param {string|number} id - 角色 ID 或 role_code
   * @returns {Promise<Object>}
   */
  async getRole (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 role_code
    const isNumeric = /^\d+$/.test(String(id))
    const query = isNumeric
      ? supabase.from('roles').select('*').eq('id', id).maybeSingle()
      : supabase.from('roles').select('*').eq('role_code', id).maybeSingle()

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 建立角色
   * @param {object} roleData - 角色資料
   * @returns {Promise<Object>}
   */
  async createRole (roleData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id || null

    const { data, error } = await supabase
      .from('roles')
      .insert({
        ...roleData,
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
   * 更新角色
   * @param {string|number} id - 角色 ID
   * @param {object} roleData - 角色資料
   * @returns {Promise<Object>}
   */
  async updateRole (id, roleData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id || null

    const { data, error } = await supabase
      .from('roles')
      .update({
        ...roleData,
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
   * 刪除角色
   * @param {string|number} id - 角色 ID
   * @returns {Promise<void>}
   */
  async deleteRole (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 檢查是否為系統內建角色
    const role = await this.getRole(id)
    if (role.is_system_role) {
      throw new Error('無法刪除系統內建角色')
    }

    const { error } = await supabase
      .from('roles')
      .delete()
      .eq('id', id)

    if (error) {
      throw error
    }
  },

  /**
   * 取得角色的權限列表
   * @param {string|number} roleId - 角色 ID
   * @returns {Promise<Array>}
   */
  async getRolePermissions (roleId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('role_permissions')
      .select(`
        permission_id,
        permissions (
          id,
          permission_code,
          permission_name,
          permission_name_en,
          module,
          description
        )
      `)
      .eq('role_id', roleId)

    if (error) {
      throw error
    }

    return (data || []).map(item => item.permissions).filter(Boolean)
  },

  /**
   * 設定角色的權限
   * @param {string|number} roleId - 角色 ID
   * @param {Array<number>} permissionIds - 權限 ID 陣列
   * @returns {Promise<void>}
   */
  async setRolePermissions (roleId, permissionIds) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id || null

    // 先刪除現有權限
    const { error: deleteError } = await supabase
      .from('role_permissions')
      .delete()
      .eq('role_id', roleId)

    if (deleteError) {
      throw deleteError
    }

    // 插入新權限
    if (permissionIds && permissionIds.length > 0) {
      const rolePermissions = permissionIds.map(permissionId => ({
        role_id: roleId,
        permission_id: permissionId,
        created_by_id: userId,
      }))

      const { error: insertError } = await supabase
        .from('role_permissions')
        .insert(rolePermissions)

      if (insertError) {
        throw insertError
      }
    }
  },

  /**
   * 取得角色的頁面權限列表
   * @param {string|number} roleId - 角色 ID
   * @returns {Promise<Array>}
   */
  async getRolePageAccess (roleId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('role_page_access')
      .select('*')
      .eq('role_id', roleId)
      .order('page_code', { ascending: true })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 設定角色的頁面權限
   * @param {string|number} roleId - 角色 ID
   * @param {Array<{page_code: string, page_name: string, is_accessible: boolean}>} pageAccess - 頁面權限陣列
   * @returns {Promise<void>}
   */
  async setRolePageAccess (roleId, pageAccess) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id || null

    // 先刪除現有頁面權限
    const { error: deleteError } = await supabase
      .from('role_page_access')
      .delete()
      .eq('role_id', roleId)

    if (deleteError) {
      throw deleteError
    }

    // 插入新頁面權限
    if (pageAccess && pageAccess.length > 0) {
      const rolePageAccess = pageAccess.map(page => ({
        role_id: roleId,
        page_code: page.page_code,
        page_name: page.page_name,
        is_accessible: page.is_accessible !== undefined ? page.is_accessible : true,
        created_by_id: userId,
      }))

      const { error: insertError } = await supabase
        .from('role_page_access')
        .insert(rolePageAccess)

      if (insertError) {
        throw insertError
      }
    }
  },
}
