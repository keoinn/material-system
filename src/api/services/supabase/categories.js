/**
 * Categories API Service - Supabase Implementation
 * 產品分類相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有大類
   */
  async getMainCategories () {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('product_categories')
      .select('*')
      .eq('level', 1)
      .eq('is_active', true)
      .order('display_order', { ascending: true })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得中類（根據大類）
   */
  async getSubCategories (mainCategoryCode) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('product_categories')
      .select('*')
      .eq('main_category_code', mainCategoryCode)
      .eq('level', 2)
      .eq('is_active', true)
      .order('display_order', { ascending: true })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得小類（根據大類）
   */
  async getSpecCategories (mainCategoryCode) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('product_categories')
      .select('*')
      .eq('main_category_code', mainCategoryCode)
      .eq('level', 3)
      .eq('is_active', true)
      .order('display_order', { ascending: true })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得完整分類樹（大類、中類、小類）
   */
  async getCategoryTree () {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('product_categories')
      .select('*')
      .eq('is_active', true)
      .order('level', { ascending: true })
      .order('display_order', { ascending: true })

    if (error) {
      throw error
    }

    // 組織成樹狀結構
    const tree = {}
    const mainCategories = data.filter(cat => cat.level === 1)
    const subCategories = data.filter(cat => cat.level === 2)
    const specCategories = data.filter(cat => cat.level === 3)

    for (const main of mainCategories) {
      tree[main.code] = {
        ...main,
        subCategories: subCategories
          .filter(sub => sub.parent_id === main.id)
          .reduce((acc, sub) => {
            acc[sub.code] = {
              ...sub,
              specCategories: specCategories
                .filter(spec => spec.main_category_code === main.code)
                .reduce((specAcc, spec) => {
                  specAcc[spec.code] = spec
                  return specAcc
                }, {}),
            }
            return acc
          }, {}),
      }
    }

    return tree
  },
}

