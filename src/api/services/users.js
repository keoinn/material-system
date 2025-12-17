/**
 * Users API Service
 * 使用者管理相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import axiosImpl from './axios/users.js'
import supabaseImpl from './supabase/users.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 使用者服務
 */
export const usersService = {
  /**
   * 取得所有使用者列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getUsers (filters = {}) {
    return getImplementation().getUsers(filters)
  },

  /**
   * 取得單一使用者
   * @param {string} id - 使用者 ID
   * @returns {Promise<Object>}
   */
  async getUser (id) {
    return getImplementation().getUser(id)
  },

  /**
   * 建立使用者
   * @param {object} userData - 使用者資料
   * @returns {Promise<Object>}
   */
  async createUser (userData) {
    return getImplementation().createUser(userData)
  },

  /**
   * 更新使用者資料
   * @param {string} id - 使用者 ID
   * @param {object} updates - 更新資料
   * @returns {Promise<Object>}
   */
  async updateUser (id, updates) {
    return getImplementation().updateUser(id, updates)
  },

  /**
   * 刪除使用者
   * @param {string} id - 使用者 ID
   * @returns {Promise<void>}
   */
  async deleteUser (id) {
    return getImplementation().deleteUser(id)
  },

  /**
   * 啟用/停用使用者
   * @param {string} id - 使用者 ID
   * @param {boolean} isActive - 是否啟用
   * @returns {Promise<Object>}
   */
  async toggleUserActive (id, isActive) {
    return getImplementation().toggleUserActive(id, isActive)
  },
}

