/**
 * Forms API Service - Supabase Implementation
 * 表單定義管理 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有表單列表
   */
  async getForms (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('forms')
      .select('*')

    // 應用篩選條件
    if (filters.is_active !== undefined) {
      query = query.eq('is_active', filters.is_active)
    }

    if (filters.is_default !== undefined) {
      query = query.eq('is_default', filters.is_default)
    }

    if (filters.form_code) {
      query = query.eq('form_code', filters.form_code)
    }

    // 排序
    query = query.order('created_at', { ascending: false })

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得單一表單定義（含所有欄位）
   */
  async getForm (idOrCode, includeFields = true) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 form_code
    const isNumeric = /^\d+$/.test(String(idOrCode))
    const queryField = isNumeric ? 'id' : 'form_code'

    let query = supabase
      .from('forms')
      .select(includeFields ? '*, form_fields(*)' : '*')
      .eq(queryField, idOrCode)
      .maybeSingle()

    const { data, error } = await query

    // 如果查詢出錯（非 PGRST116），拋出錯誤
    if (error && error.code !== 'PGRST116') {
      throw error
    }

    if (!data) {
      return null
    }

    // 如果有欄位，按 display_order 排序
    if (includeFields && data.form_fields) {
      data.fields = data.form_fields.sort((a, b) => {
        const orderA = a.display_order || 0
        const orderB = b.display_order || 0
        return orderA - orderB
      })
      delete data.form_fields
    }

    return data
  },

  /**
   * 建立表單定義
   */
  async createForm (formData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 如果設置為預設表單，先取消其他表單的預設狀態
    if (formData.is_default === true) {
      await supabase
        .from('forms')
        .update({ is_default: false })
        .eq('is_default', true) // 只更新當前是預設的表單
    }

    const { data, error } = await supabase
      .from('forms')
      .insert(formData)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 更新表單定義
   */
  async updateForm (id, updates) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 如果設置為預設表單，先取消其他表單的預設狀態
    if (updates.is_default === true) {
      await supabase
        .from('forms')
        .update({ is_default: false })
        .neq('id', id) // 排除當前表單
    }

    const { data, error } = await supabase
      .from('forms')
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
   * 刪除表單定義
   */
  async deleteForm (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('forms')
      .delete()
      .eq('id', id)

    if (error) {
      throw error
    }
  },

  /**
   * 複製表單定義
   */
  async duplicateForm (id, newFormData = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得原始表單
    const originalForm = await this.getForm(id, true)

    if (!originalForm) {
      throw new Error('找不到要複製的表單')
    }

    // 建立新表單
    const newForm = {
      form_code: newFormData.form_code || `${originalForm.form_code}_copy_${Date.now()}`,
      form_name: newFormData.form_name || `${originalForm.form_name} (複製)`,
      form_name_en: newFormData.form_name_en || `${originalForm.form_name_en} (Copy)`,
      description: newFormData.description || originalForm.description,
      form_config: newFormData.form_config || originalForm.form_config,
      is_active: newFormData.is_active !== undefined ? newFormData.is_active : originalForm.is_active,
      is_default: false, // 複製的表單預設不是預設表單
    }

    const createdForm = await this.createForm(newForm)

    // 複製欄位定義
    if (originalForm.fields && originalForm.fields.length > 0) {
      const formFieldsService = (await import('../supabase/formFields.js')).default
      for (const field of originalForm.fields) {
        const { id: fieldId, form_id, created_at, updated_at, ...fieldData } = field
        await formFieldsService.createField(createdForm.id, fieldData)
      }
    }

    return createdForm
  },
}
