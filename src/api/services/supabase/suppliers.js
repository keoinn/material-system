/**
 * Suppliers API Service - Supabase Implementation
 * 供應商相關 API 服務（Supabase 實作）
 */
import { supabase, isSupabaseAvailable } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有供應商
   */
  async getSuppliers(filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('suppliers')
      .select('*')

    if (filters.isActive !== undefined) {
      query = query.eq('is_active', filters.isActive)
    } else {
      query = query.eq('is_active', true)
    }

    if (filters.code) {
      query = query.ilike('code', `%${filters.code}%`)
    }

    if (filters.name) {
      query = query.ilike('name', `%${filters.name}%`)
    }

    query = query.order('code', { ascending: true })

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得單一供應商
   */
  async getSupplier(id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 code
    const isCode = typeof id === 'string' && !id.match(/^\d+$/)
    const field = isCode ? 'code' : 'id'

    const { data, error } = await supabase
      .from('suppliers')
      .select('*')
      .eq(field, id)
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 建立供應商
   */
  async createSupplier(supplierData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('suppliers')
      .insert(supplierData)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 更新供應商
   */
  async updateSupplier(id, updates) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('suppliers')
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
   * 刪除供應商
   */
  async deleteSupplier(id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('suppliers')
      .delete()
      .eq('id', id)

    if (error) {
      throw error
    }
  },
}

