/**
 * Permissions API Service
 * 權限管理相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import supabaseImpl from './supabase/permissions.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? {} : supabaseImpl
}

/**
 * 權限服務
 */
export const permissionsService = {
  /**
   * 取得所有權限列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getPermissions (filters = {}) {
    return getImplementation().getPermissions(filters)
  },

  /**
   * 取得單一權限
   * @param {string|number} id - 權限 ID 或 permission_code
   * @returns {Promise<Object>}
   */
  async getPermission (id) {
    return getImplementation().getPermission(id)
  },

  /**
   * 建立權限
   * @param {object} permissionData - 權限資料
   * @returns {Promise<Object>}
   */
  async createPermission (permissionData) {
    return getImplementation().createPermission(permissionData)
  },

  /**
   * 更新權限
   * @param {string|number} id - 權限 ID
   * @param {object} permissionData - 權限資料
   * @returns {Promise<Object>}
   */
  async updatePermission (id, permissionData) {
    return getImplementation().updatePermission(id, permissionData)
  },

  /**
   * 刪除權限
   * @param {string|number} id - 權限 ID
   * @returns {Promise<void>}
   */
  async deletePermission (id) {
    return getImplementation().deletePermission(id)
  },
}
