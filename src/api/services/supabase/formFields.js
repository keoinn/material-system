/**
 * Form Fields API Service - Supabase Implementation
 * 表單欄位定義管理 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得表單的所有欄位定義
   */
  async getFields (formId, filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 form_code
    const isNumeric = /^\d+$/.test(String(formId))
    let query = supabase
      .from('form_fields')
      .select('*')

    if (isNumeric) {
      query = query.eq('form_id', formId)
    } else {
      // 如果是 form_code，先查詢表單 ID
      const { data: form } = await supabase
        .from('forms')
        .select('id')
        .eq('form_code', formId)
        .single()

      if (!form) {
        throw new Error(`找不到表單: ${formId}`)
      }

      query = query.eq('form_id', form.id)
    }

    // 應用篩選條件
    if (filters.field_group) {
      query = query.eq('field_group', filters.field_group)
    }

    if (filters.is_visible !== undefined) {
      query = query.eq('is_visible', filters.is_visible)
    }

    if (filters.field_type) {
      query = query.eq('field_type', filters.field_type)
    }

    // 排序
    query = query.order('display_order', { ascending: true })

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得單一欄位定義
   */
  async getField (formId, fieldIdOrKey) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 form_code
    const isFormNumeric = /^\d+$/.test(String(formId))
    let formIdValue = formId

    if (!isFormNumeric) {
      // 如果是 form_code，先查詢表單 ID
      const { data: form } = await supabase
        .from('forms')
        .select('id')
        .eq('form_code', formId)
        .single()

      if (!form) {
        throw new Error(`找不到表單: ${formId}`)
      }

      formIdValue = form.id
    }

    // 判斷欄位是 ID 還是 field_key
    const isFieldNumeric = /^\d+$/.test(String(fieldIdOrKey))
    const queryField = isFieldNumeric ? 'id' : 'field_key'

    const { data, error } = await supabase
      .from('form_fields')
      .select('*')
      .eq('form_id', formIdValue)
      .eq(queryField, fieldIdOrKey)
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 建立欄位定義
   */
  async createField (formId, fieldData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 form_code
    const isNumeric = /^\d+$/.test(String(formId))
    let formIdValue = formId

    if (!isNumeric) {
      // 如果是 form_code，先查詢表單 ID
      const { data: form } = await supabase
        .from('forms')
        .select('id')
        .eq('form_code', formId)
        .single()

      if (!form) {
        throw new Error(`找不到表單: ${formId}`)
      }

      formIdValue = form.id
    }

    const { data, error } = await supabase
      .from('form_fields')
      .insert({
        ...fieldData,
        form_id: formIdValue,
      })
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 更新欄位定義
   */
  async updateField (formId, fieldId, updates) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 form_code
    const isNumeric = /^\d+$/.test(String(formId))
    let formIdValue = formId

    if (!isNumeric) {
      // 如果是 form_code，先查詢表單 ID
      const { data: form } = await supabase
        .from('forms')
        .select('id')
        .eq('form_code', formId)
        .single()

      if (!form) {
        throw new Error(`找不到表單: ${formId}`)
      }

      formIdValue = form.id
    }

    const { data, error } = await supabase
      .from('form_fields')
      .update(updates)
      .eq('id', fieldId)
      .eq('form_id', formIdValue)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 刪除欄位定義
   */
  async deleteField (formId, fieldId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 form_code
    const isNumeric = /^\d+$/.test(String(formId))
    let formIdValue = formId

    if (!isNumeric) {
      // 如果是 form_code，先查詢表單 ID
      const { data: form } = await supabase
        .from('forms')
        .select('id')
        .eq('form_code', formId)
        .single()

      if (!form) {
        throw new Error(`找不到表單: ${formId}`)
      }

      formIdValue = form.id
    }

    const { error } = await supabase
      .from('form_fields')
      .delete()
      .eq('id', fieldId)
      .eq('form_id', formIdValue)

    if (error) {
      throw error
    }
  },

  /**
   * 批量更新欄位順序
   */
  async updateFieldOrders (formId, fieldOrders) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 form_code
    const isNumeric = /^\d+$/.test(String(formId))
    let formIdValue = formId

    if (!isNumeric) {
      // 如果是 form_code，先查詢表單 ID
      const { data: form } = await supabase
        .from('forms')
        .select('id')
        .eq('form_code', formId)
        .single()

      if (!form) {
        throw new Error(`找不到表單: ${formId}`)
      }

      formIdValue = form.id
    }

    // 使用事務批量更新
    const updates = fieldOrders.map(({ id, display_order }) =>
      supabase
        .from('form_fields')
        .update({ display_order })
        .eq('id', id)
        .eq('form_id', formIdValue)
    )

    const results = await Promise.all(updates)

    // 檢查是否有錯誤
    for (const result of results) {
      if (result.error) {
        throw result.error
      }
    }
  },
}
