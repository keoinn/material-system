/**
 * Settings API Service
 * 系統設定相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import axiosImpl from './axios/settings.js'
import supabaseImpl from './supabase/settings.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 設定服務
 */
export const settingsService = {
  /**
   * 取得所有系統設定
   * @returns {Promise<Object>}
   */
  async getSettings () {
    return getImplementation().getSettings()
  },

  /**
   * 取得單一設定值
   * @param {string} key - 設定鍵值
   * @returns {Promise<any>}
   */
  async getSetting (key) {
    return getImplementation().getSetting(key)
  },

  /**
   * 更新設定值
   * @param {string} key - 設定鍵值
   * @param {any} value - 設定值
   * @param {string} type - 設定類型（可選）
   * @returns {Promise<Object>}
   */
  async updateSetting (key, value, type = null) {
    return getImplementation().updateSetting(key, value, type)
  },

  /**
   * 批量更新設定
   * @param {Object} settings - 設定物件
   * @returns {Promise<Array>}
   */
  async updateSettings (settings) {
    return getImplementation().updateSettings(settings)
  },
}
