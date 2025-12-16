/**
 * Auth API Service
 * 認證相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import * as axiosImpl from './axios/auth.js'
import * as supabaseImpl from './supabase/auth.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 認證服務
 */
export const authService = {
  /**
   * 登入
   * @param {string} email - Email
   * @param {string} password - 密碼
   * @returns {Promise<Object>}
   */
  async login (email, password) {
    return getImplementation().login(email, password)
  },

  /**
   * 登出
   * @returns {Promise<void>}
   */
  async logout () {
    return getImplementation().logout()
  },

  /**
   * 取得當前使用者
   * @returns {Promise<Object|null>}
   */
  async getCurrentUser () {
    return getImplementation().getCurrentUser()
  },

  /**
   * 取得當前 Session
   * @returns {Promise<Object|null>}
   */
  async getSession () {
    return getImplementation().getSession()
  },

  /**
   * 註冊新使用者
   * @param {object} userData - 使用者資料
   * @returns {Promise<Object>}
   */
  async signUp (userData) {
    return getImplementation().signUp(userData)
  },

  /**
   * 重設密碼
   * @param {string} email - Email
   * @returns {Promise<void>}
   */
  async resetPassword (email) {
    return getImplementation().resetPassword(email)
  },
}
