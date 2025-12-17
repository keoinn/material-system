/**
 * Code Counters API Service - Supabase Implementation
 * 編碼計數器相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 獲取並增加計數器
   * @param {string} key - 計數器鍵值（格式: {大類}{中類}.{小類}）
   * @returns {Promise<number>} 新的計數器值
   */
  async getAndIncrementCounter (key) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 獲取當前用戶
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id

    // 嘗試獲取現有計數器
    const { data: existing } = await supabase
      .from('code_counters')
      .select('counter')
      .eq('key', key)
      .single()

    let newCounter
    if (existing) {
      // 如果存在，增加計數器
      newCounter = existing.counter + 1
      const { error } = await supabase
        .from('code_counters')
        .update({
          counter: newCounter,
          last_used_date: new Date().toISOString(),
          last_used_by_id: userId,
        })
        .eq('key', key)

      if (error) {
        throw error
      }
    } else {
      // 如果不存在，創建新的計數器（從 1 開始）
      newCounter = 1
      const { error } = await supabase
        .from('code_counters')
        .insert({
          key,
          counter: newCounter,
          last_used_date: new Date().toISOString(),
          last_used_by_id: userId,
        })

      if (error) {
        throw error
      }
    }

    return newCounter
  },

  /**
   * 獲取計數器當前值（不增加）
   * @param {string} key - 計數器鍵值
   * @returns {Promise<number>} 當前計數器值
   */
  async getCounter (key) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('code_counters')
      .select('counter')
      .eq('key', key)
      .single()

    if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
      throw error
    }

    return data?.counter || 0
  },

  /**
   * 重置計數器
   * @param {string} key - 計數器鍵值
   * @param {number} value - 新的計數器值（可選，預設為 0）
   * @returns {Promise<void>}
   */
  async resetCounter (key, value = 0) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('code_counters')
      .upsert({
        key,
        counter: value,
        last_used_date: new Date().toISOString(),
      }, {
        onConflict: 'key',
      })

    if (error) {
      throw error
    }
  },
}

