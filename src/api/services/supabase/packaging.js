/**
 * Packaging API Service - Supabase Implementation
 * 包裝相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有包裝類別
   */
  async getPackagingCategories () {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('packaging_categories')
      .select('*')
      .eq('is_active', true)
      .order('display_order', { ascending: true })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得包裝選項（根據類別）
   */
  async getPackagingOptions (categoryId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 如果傳入的是 code，先查詢 ID
    let categoryIdValue = categoryId
    if (typeof categoryId === 'string' && !/^\d+$/.test(categoryId)) {
      const { data: category } = await supabase
        .from('packaging_categories')
        .select('id')
        .eq('code', categoryId)
        .single()

      if (!category) {
        return []
      }
      categoryIdValue = category.id
    }

    const { data, error } = await supabase
      .from('packaging_options')
      .select('*')
      .eq('category_id', categoryIdValue)
      .eq('is_active', true)
      .order('display_order', { ascending: true })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得所有包裝選項（依類別分組）
   */
  async getAllPackagingOptions () {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('packaging_options')
      .select(`
        *,
        packaging_categories (
          code,
          name,
          name_cn
        )
      `)
      .eq('is_active', true)
      .order('category_id', { ascending: true })
      .order('display_order', { ascending: true })

    if (error) {
      throw error
    }

    // 依類別分組
    const grouped = {}
    for (const option of data) {
      const categoryCode = option.packaging_categories?.code || 'unknown'
      if (!grouped[categoryCode]) {
        grouped[categoryCode] = {
          category: option.packaging_categories,
          options: [],
        }
      }
      grouped[categoryCode].options.push(option)
    }

    return grouped
  },

  /**
   * 取得類別預設包裝選項
   */
  async getCategoryDefaults (mainCategoryCode) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('category_packaging_defaults')
      .select(`
        *,
        packaging_categories (
          code,
          name,
          name_cn
        ),
        packaging_options (
          code,
          name,
          description
        )
      `)
      .eq('main_category_code', mainCategoryCode)
      .order('packaging_category_id', { ascending: true })
      .order('display_order', { ascending: true })

    if (error) {
      throw error
    }

    // 組織成物件格式
    const defaults = {}
    for (const item of data) {
      const categoryCode = item.packaging_categories?.code
      if (!defaults[categoryCode]) {
        defaults[categoryCode] = []
      }
      defaults[categoryCode].push(item.packaging_options?.code)
    }

    return defaults
  },

  /**
   * 取得申請的包裝選項
   */
  async getApplicationPackaging (applicationId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('application_packaging')
      .select(`
        *,
        packaging_categories (
          code,
          name,
          name_cn
        ),
        packaging_options (
          code,
          name,
          description
        )
      `)
      .eq('application_id', applicationId)
      .order('packaging_category_id', { ascending: true })
      .order('display_order', { ascending: true })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 儲存申請的包裝選項
   */
  async saveApplicationPackaging (applicationId, packagingData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 先刪除舊的包裝資料
    await supabase
      .from('application_packaging')
      .delete()
      .eq('application_id', applicationId)

    // 插入新的包裝資料
    const insertData = packagingData.map((item, index) => ({
      application_id: applicationId,
      packaging_category_id: item.categoryId,
      packaging_option_id: item.optionId,
      description: item.description || null,
      display_order: index,
    }))

    const { data, error } = await supabase
      .from('application_packaging')
      .insert(insertData)
      .select()

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 儲存類別預設包裝模板
   * @param {string} mainCategoryCode - 產品大類代碼
   * @param {Object} templateData - 模板資料 { categoryCode: [optionCode, ...] }
   * @returns {Promise<Array>}
   */
  async saveCategoryDefaults (mainCategoryCode, templateData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 先刪除該類別的所有預設值
    const { error: deleteError } = await supabase
      .from('category_packaging_defaults')
      .delete()
      .eq('main_category_code', mainCategoryCode)

    if (deleteError) {
      throw deleteError
    }

    // 準備插入資料
    const insertData = []
    for (const [categoryCode, optionCodes] of Object.entries(templateData)) {
      if (!Array.isArray(optionCodes) || optionCodes.length === 0) {
        continue
      }

      // 取得包裝類別 ID
      const { data: category } = await supabase
        .from('packaging_categories')
        .select('id')
        .eq('code', categoryCode)
        .single()

      if (!category) {
        console.warn(`找不到包裝類別: ${categoryCode}`)
        continue
      }

      // 為每個選項建立記錄
      for (const [index, optionCode] of optionCodes.entries()) {
        // 取得包裝選項 ID
        const { data: option } = await supabase
          .from('packaging_options')
          .select('id')
          .eq('code', optionCode)
          .eq('category_id', category.id)
          .single()

        if (!option) {
          console.warn(`找不到包裝選項: ${optionCode} (類別: ${categoryCode})`)
          continue
        }

        insertData.push({
          main_category_code: mainCategoryCode,
          packaging_category_id: category.id,
          packaging_option_id: option.id,
          display_order: index + 1,
        })
      }
    }

    // 批量插入
    if (insertData.length > 0) {
      const { data, error } = await supabase
        .from('category_packaging_defaults')
        .insert(insertData)
        .select()

      if (error) {
        throw error
      }

      return data || []
    }

    return []
  },

  /**
   * 取得包裝說明模板
   * @param {number|string} formId - 表單 ID
   * @param {string} templateType - 模板類型（H, S, M, D, F, B, I, O）
   * @returns {Promise<Object|null>}
   */
  async getPackagingTemplate (formId, templateType) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 form_code
    const isNumeric = /^\d+$/.test(String(formId))
    let actualFormId = formId

    if (!isNumeric) {
      // 如果是 form_code，先查詢表單 ID
      const { data: form, error: formError } = await supabase
        .from('forms')
        .select('id')
        .eq('form_code', formId)
        .maybeSingle()

      if (formError) {
        throw formError
      }

      if (!form) {
        throw new Error(`找不到表單: ${formId}`)
      }

      actualFormId = form.id
    }

    const { data, error } = await supabase
      .from('packaging_templates')
      .select('*')
      .eq('form_id', actualFormId)
      .eq('template_type', templateType)
      .maybeSingle()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 儲存包裝說明模板
   * @param {number|string} formId - 表單 ID
   * @param {string} templateType - 模板類型（H, S, M, D, F, B, I, O）
   * @param {Object} templateValues - 模板值（JSON 格式）
   * @returns {Promise<Object>}
   */
  async savePackagingTemplate (formId, templateType, templateValues) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id || null

    // 判斷是 ID 還是 form_code
    const isNumeric = /^\d+$/.test(String(formId))
    let actualFormId = formId

    if (!isNumeric) {
      // 如果是 form_code，先查詢表單 ID
      const { data: form, error: formError } = await supabase
        .from('forms')
        .select('id')
        .eq('form_code', formId)
        .maybeSingle()

      if (formError) {
        throw formError
      }

      if (!form) {
        throw new Error(`找不到表單: ${formId}`)
      }

      actualFormId = form.id
    }

    // 檢查是否已存在
    const { data: existing } = await supabase
      .from('packaging_templates')
      .select('id')
      .eq('form_id', actualFormId)
      .eq('template_type', templateType)
      .maybeSingle()

    const templateData = {
      form_id: actualFormId,
      template_type: templateType,
      template_values: templateValues,
      updated_by_id: userId,
      updated_at: new Date().toISOString(),
    }

    let data, error

    if (existing) {
      // 更新現有記錄
      const { data: updated, error: updateError } = await supabase
        .from('packaging_templates')
        .update(templateData)
        .eq('id', existing.id)
        .select()
        .maybeSingle()

      data = updated
      error = updateError
      if (!error && !data) {
        error = new Error(`找不到包裝模板或無法更新（id: ${existing.id}）`)
      }
    } else {
      // 建立新記錄
      templateData.created_by_id = userId
      const { data: created, error: createError } = await supabase
        .from('packaging_templates')
        .insert(templateData)
        .select()
        .maybeSingle()

      data = created
      error = createError
      if (!error && !data) {
        error = new Error('建立包裝模板失敗：無法取得新建資料')
      }
    }

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 刪除類別預設包裝模板
   * @param {string} mainCategoryCode - 產品大類代碼
   * @returns {Promise<void>}
   */
  async deleteCategoryDefaults (mainCategoryCode) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('category_packaging_defaults')
      .delete()
      .eq('main_category_code', mainCategoryCode)

    if (error) {
      throw error
    }
  },
}
