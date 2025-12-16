/**
 * System Options API Service - Supabase Implementation
 * 系統選項相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得系統選項（根據模組和類別）
   */
  async getOptions (module, cate, parentKey = null) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('system_options')
      .select('*')
      .eq('module', module)
      .eq('cate', cate)

    if (parentKey !== null) {
      query = query.eq('parent_key', parentKey)
    } else {
      query = query.is('parent_key', null)
    }

    query = query.order('key', { ascending: true })

    const { data, error } = await query

    if (error) {
      throw error
    }

    // 轉換為選項格式
    return (data || []).map(item => ({
      value: item.value,
      label: item.label || item.value,
      description: item.desc || '',
      key: item.key,
    }))
  },

  /**
   * 取得所有模組的選項
   */
  async getModuleOptions (module) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('system_options')
      .select('*')
      .eq('module', module)
      .order('cate', { ascending: true })
      .order('key', { ascending: true })

    if (error) {
      throw error
    }

    // 依類別分組
    const grouped = {}
    for (const item of data || []) {
      if (!grouped[item.cate]) {
        grouped[item.cate] = []
      }
      grouped[item.cate].push({
        value: item.value,
        label: item.label || item.value,
        description: item.desc || '',
        key: item.key,
      })
    }

    return grouped
  },
}

