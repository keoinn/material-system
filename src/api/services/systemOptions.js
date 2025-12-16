/**
 * System Options API Service
 * 系統選項相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import axiosImpl from './axios/systemOptions.js'
import supabaseImpl from './supabase/systemOptions.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 系統選項服務
 */
export const systemOptionsService = {
  /**
   * 取得系統選項（根據模組和類別）
   * @param {string} module - 模組名稱
   * @param {string} cate - 類別名稱
   * @param {string} parentKey - 父層鍵值（可選）
   * @returns {Promise<Array>}
   */
  async getOptions (module, cate, parentKey = null) {
    return getImplementation().getOptions(module, cate, parentKey)
  },

  /**
   * 取得所有模組的選項
   * @param {string} module - 模組名稱
   * @returns {Promise<Object>}
   */
  async getModuleOptions (module) {
    return getImplementation().getModuleOptions(module)
  },
}
