/**
 * Departments API Service - Supabase Implementation
 * 部門管理相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有部門列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getDepartments (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 先查詢基本資料
    let query = supabase
      .from('departments')
      .select('*')
      .order('display_order', { ascending: true })
      .order('id', { ascending: true })

    if (filters.is_active !== undefined && filters.is_active !== null) {
      query = query.eq('is_active', filters.is_active)
    }

    if (filters.parent_id !== undefined && filters.parent_id !== null) {
      if (filters.parent_id === 'null' || filters.parent_id === null) {
        query = query.is('parent_id', null)
      } else {
        query = query.eq('parent_id', filters.parent_id)
      }
    }

    const { data, error } = await query

    if (error) {
      throw error
    }

    if (!data || data.length === 0) {
      return []
    }

    // 手動關聯 parent 和 manager 資料
    const departmentIds = data.map(d => d.id)
    const parentIds = data.map(d => d.parent_id).filter(Boolean)
    const managerIds = data.map(d => d.manager_id).filter(Boolean)

    // 查詢所有相關的 parent 部門
    const parentMap = new Map()
    if (parentIds.length > 0) {
      const { data: parents } = await supabase
        .from('departments')
        .select('id, department_code, department_name')
        .in('id', parentIds)

      if (parents) {
        parents.forEach(p => parentMap.set(p.id, p))
      }
    }

    // 查詢所有相關的 manager
    const managerMap = new Map()
    if (managerIds.length > 0) {
      const { data: managers } = await supabase
        .from('user_profiles')
        .select('id, username')
        .in('id', managerIds)

      if (managers) {
        managers.forEach(m => managerMap.set(m.id, m))
      }
    }

    // 組合資料
    return data.map(dept => ({
      ...dept,
      parent: dept.parent_id ? parentMap.get(dept.parent_id) || null : null,
      manager: dept.manager_id ? managerMap.get(dept.manager_id) || null : null,
    }))
  },

  /**
   * 取得單一部門
   * @param {string|number} id - 部門 ID 或 department_code
   * @returns {Promise<Object>}
   */
  async getDepartment (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 department_code
    const isNumeric = /^\d+$/.test(String(id))
    const query = isNumeric
      ? supabase.from('departments').select('*').eq('id', id).single()
      : supabase.from('departments').select('*').eq('department_code', id).single()

    const { data, error } = await query

    if (error) {
      throw error
    }

    if (!data) {
      return null
    }

    // 手動關聯 parent 和 manager 資料
    const result = { ...data }

    if (data.parent_id) {
      const { data: parent } = await supabase
        .from('departments')
        .select('id, department_code, department_name')
        .eq('id', data.parent_id)
        .single()

      result.parent = parent || null
    } else {
      result.parent = null
    }

    if (data.manager_id) {
      const { data: manager } = await supabase
        .from('user_profiles')
        .select('id, username')
        .eq('id', data.manager_id)
        .single()

      result.manager = manager || null
    } else {
      result.manager = null
    }

    return result
  },

  /**
   * 建立部門
   * @param {object} departmentData - 部門資料
   * @returns {Promise<Object>}
   */
  async createDepartment (departmentData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id || null

    const { data, error } = await supabase
      .from('departments')
      .insert({
        ...departmentData,
        created_by_id: userId,
        updated_by_id: userId,
      })
      .select('*')
      .single()

    if (error) {
      throw error
    }

    // 手動關聯 parent 和 manager 資料
    return await this.getDepartment(data.id)
  },

  /**
   * 更新部門
   * @param {string|number} id - 部門 ID
   * @param {object} departmentData - 部門資料
   * @returns {Promise<Object>}
   */
  async updateDepartment (id, departmentData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id || null

    // 檢查是否會造成循環引用（自己成為自己的父部門）
    if (departmentData.parent_id && Number(departmentData.parent_id) === Number(id)) {
      throw new Error('無法將部門設為自己的上級部門')
    }

    const { error } = await supabase
      .from('departments')
      .update({
        ...departmentData,
        updated_by_id: userId,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)

    if (error) {
      throw error
    }

    // 手動關聯 parent 和 manager 資料
    return await this.getDepartment(id)
  },

  /**
   * 刪除部門
   * @param {string|number} id - 部門 ID
   * @returns {Promise<void>}
   */
  async deleteDepartment (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 檢查是否有子部門
    const { data: children } = await supabase
      .from('departments')
      .select('id')
      .eq('parent_id', id)
      .limit(1)

    if (children && children.length > 0) {
      throw new Error('無法刪除包含子部門的部門，請先刪除或移動子部門')
    }

    // 檢查是否有使用者使用此部門
    const { data: users } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('department', (await this.getDepartment(id)).department_code)
      .limit(1)

    if (users && users.length > 0) {
      throw new Error('無法刪除仍有使用者使用的部門，請先變更使用者的部門')
    }

    const { error } = await supabase
      .from('departments')
      .delete()
      .eq('id', id)

    if (error) {
      throw error
    }
  },
}
