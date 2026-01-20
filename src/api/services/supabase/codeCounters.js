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
   * @returns {Promise<number>} 當前使用的計數器值（counter 表存儲的是下一個要使用的值）
   * 
   * 邏輯說明：
   * - counter 表存儲的是"下一個要使用的計數值"
   * - 如果不存在，則使用 1（表示下一個要使用的序號是 1，即當前還沒有使用過）
   * - 使用完後，將 counter 更新為 counter + 1（表示下一個要使用的序號）
   * - 返回的是"當前使用的序號"（即查詢到的 counter 值）
   */
  async getAndIncrementCounter (key) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 獲取當前用戶
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id

    // 嘗試獲取現有計數器
    const { data: existing, error: fetchError } = await supabase
      .from('code_counters')
      .select('counter')
      .eq('key', key)
      .maybeSingle()

    // 如果查詢出錯（非 PGRST116），拋出錯誤
    if (fetchError && fetchError.code !== 'PGRST116') {
      throw fetchError
    }

    let currentCounter // 當前要使用的計數值
    let nextCounter // 下一個要使用的計數值（存儲到資料庫）

    if (existing && existing.counter !== null && existing.counter !== undefined) {
      // 如果存在，使用當前的 counter 值（表示下一個要使用的序號）
      // 如果 counter 為 0 或小於 1，則使用 1
      currentCounter = existing.counter >= 1 ? existing.counter : 1
      // 使用完後，下一個要使用的序號是 currentCounter + 1
      nextCounter = currentCounter + 1
      
      const { error } = await supabase
        .from('code_counters')
        .update({
          counter: nextCounter, // 存儲下一個要使用的序號
          last_used_date: new Date().toISOString(),
          last_used_by_id: userId,
        })
        .eq('key', key)

      if (error) {
        throw error
      }
    } else {
      // 如果不存在，使用 1（表示下一個要使用的序號是 1，即當前還沒有使用過）
      currentCounter = 1
      // 使用完後，下一個要使用的序號是 2
      nextCounter = 2
      
      const { error } = await supabase
        .from('code_counters')
        .insert({
          key,
          counter: nextCounter, // 存儲下一個要使用的序號
          last_used_date: new Date().toISOString(),
          last_used_by_id: userId,
        })

      if (error) {
        throw error
      }
    }

    return currentCounter
  },

  /**
   * 獲取計數器當前值（不增加）
   * @param {string} key - 計數器鍵值
   * @returns {Promise<number>} 下一個要使用的計數器值（如果不存在則返回 1，表示下一個要使用的序號是 1）
   * 
   * 邏輯說明：
   * - counter 表存儲的是"下一個要使用的計數值"
   * - 如果不存在，返回 1（表示下一個要使用的序號是 1，即當前還沒有使用過）
   * - 如果存在，返回 counter 值（表示下一個要使用的序號）
   */
  async getCounter (key) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('code_counters')
      .select('counter')
      .eq('key', key)
      .maybeSingle()

    // 如果查詢出錯（非 PGRST116），拋出錯誤
    if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
      throw error
    }

    // 如果計數器不存在，返回 1（表示下一個要使用的序號是 1）
    // 如果計數器存在但值為 0 或小於 1，也返回 1（確保從 1 開始）
    const counterValue = data?.counter
    if (counterValue === null || counterValue === undefined || counterValue < 1) {
      return 1
    }

    return counterValue
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

