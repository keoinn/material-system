/**
 * Code Counters API Service - Axios Implementation
 * 編碼計數器相關 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 獲取並增加計數器
   * @param {string} key - 計數器鍵值
   * @returns {Promise<number>} 新的計數器值
   */
  async getAndIncrementCounter (key) {
    const response = await apiClient.post(`/code-counters/${key}/increment`)
    return response.data?.counter || response.counter || 0
  },

  /**
   * 獲取計數器當前值（不增加）
   * @param {string} key - 計數器鍵值
   * @returns {Promise<number>} 當前計數器值
   */
  async getCounter (key) {
    const response = await apiClient.get(`/code-counters/${key}`)
    return response.data?.counter || response.counter || 0
  },

  /**
   * 重置計數器
   * @param {string} key - 計數器鍵值
   * @param {number} value - 新的計數器值（可選，預設為 0）
   * @returns {Promise<void>}
   */
  async resetCounter (key, value = 0) {
    await apiClient.put(`/code-counters/${key}`, { counter: value })
  },
}

