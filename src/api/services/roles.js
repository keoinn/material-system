/**
 * Roles API Service
 * 角色管理相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import supabaseImpl from './supabase/roles.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? {} : supabaseImpl
}

/**
 * 角色服務
 */
export const rolesService = {
  /**
   * 取得所有角色列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getRoles (filters = {}) {
    return getImplementation().getRoles(filters)
  },

  /**
   * 取得單一角色
   * @param {string|number} id - 角色 ID 或 role_code
   * @returns {Promise<Object>}
   */
  async getRole (id) {
    return getImplementation().getRole(id)
  },

  /**
   * 建立角色
   * @param {object} roleData - 角色資料
   * @returns {Promise<Object>}
   */
  async createRole (roleData) {
    return getImplementation().createRole(roleData)
  },

  /**
   * 更新角色
   * @param {string|number} id - 角色 ID
   * @param {object} roleData - 角色資料
   * @returns {Promise<Object>}
   */
  async updateRole (id, roleData) {
    return getImplementation().updateRole(id, roleData)
  },

  /**
   * 刪除角色
   * @param {string|number} id - 角色 ID
   * @returns {Promise<void>}
   */
  async deleteRole (id) {
    return getImplementation().deleteRole(id)
  },

  /**
   * 取得角色的權限列表
   * @param {string|number} roleId - 角色 ID
   * @returns {Promise<Array>}
   */
  async getRolePermissions (roleId) {
    return getImplementation().getRolePermissions(roleId)
  },

  /**
   * 設定角色的權限
   * @param {string|number} roleId - 角色 ID
   * @param {Array<number>} permissionIds - 權限 ID 陣列
   * @returns {Promise<void>}
   */
  async setRolePermissions (roleId, permissionIds) {
    return getImplementation().setRolePermissions(roleId, permissionIds)
  },

  /**
   * 取得角色的頁面權限列表
   * @param {string|number} roleId - 角色 ID
   * @returns {Promise<Array>}
   */
  async getRolePageAccess (roleId) {
    return getImplementation().getRolePageAccess(roleId)
  },

  /**
   * 設定角色的頁面權限
   * @param {string|number} roleId - 角色 ID
   * @param {Array<{page_code: string, page_name: string, is_accessible: boolean}>} pageAccess - 頁面權限陣列
   * @returns {Promise<void>}
   */
  async setRolePageAccess (roleId, pageAccess) {
    return getImplementation().setRolePageAccess(roleId, pageAccess)
  },
}
