/**
 * Packaging API Service - Supabase Implementation
 * 包裝相關 API 服務（Supabase 實作）
 */
import { supabase, isSupabaseAvailable } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有包裝類別
   */
  async getPackagingCategories() {
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
  async getPackagingOptions(categoryId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 如果傳入的是 code，先查詢 ID
    let categoryIdValue = categoryId
    if (typeof categoryId === 'string' && !categoryId.match(/^\d+$/)) {
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
  async getAllPackagingOptions() {
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
    data.forEach(option => {
      const categoryCode = option.packaging_categories?.code || 'unknown'
      if (!grouped[categoryCode]) {
        grouped[categoryCode] = {
          category: option.packaging_categories,
          options: [],
        }
      }
      grouped[categoryCode].options.push(option)
    })

    return grouped
  },

  /**
   * 取得類別預設包裝選項
   */
  async getCategoryDefaults(mainCategoryCode) {
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
    data.forEach(item => {
      const categoryCode = item.packaging_categories?.code
      if (!defaults[categoryCode]) {
        defaults[categoryCode] = []
      }
      defaults[categoryCode].push(item.packaging_options?.code)
    })

    return defaults
  },

  /**
   * 取得申請的包裝選項
   */
  async getApplicationPackaging(applicationId) {
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
  async saveApplicationPackaging(applicationId, packagingData) {
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
}

