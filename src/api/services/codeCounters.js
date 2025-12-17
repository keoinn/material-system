/**
 * Code Counters API Service
 * 編碼計數器相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import axiosImpl from './axios/codeCounters.js'
import supabaseImpl from './supabase/codeCounters.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 編碼計數器服務
 */
export const codeCountersService = {
  /**
   * 獲取並增加計數器
   * @param {string} key - 計數器鍵值（格式: {大類}{中類}.{小類}）
   * @returns {Promise<number>} 新的計數器值
   */
  async getAndIncrementCounter (key) {
    return getImplementation().getAndIncrementCounter(key)
  },

  /**
   * 獲取計數器當前值（不增加）
   * @param {string} key - 計數器鍵值
   * @returns {Promise<number>} 當前計數器值
   */
  async getCounter (key) {
    return getImplementation().getCounter(key)
  },

  /**
   * 重置計數器
   * @param {string} key - 計數器鍵值
   * @param {number} value - 新的計數器值（可選，預設為 0）
   * @returns {Promise<void>}
   */
  async resetCounter (key, value = 0) {
    return getImplementation().resetCounter(key, value)
  },
}

