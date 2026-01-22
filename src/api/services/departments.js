/**
 * Departments API Service
 * 部門管理相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import supabaseImpl from './supabase/departments.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? {} : supabaseImpl
}

/**
 * 部門服務
 */
export const departmentsService = {
  /**
   * 取得所有部門列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getDepartments (filters = {}) {
    return getImplementation().getDepartments(filters)
  },

  /**
   * 取得單一部門
   * @param {string|number} id - 部門 ID 或 department_code
   * @returns {Promise<Object>}
   */
  async getDepartment (id) {
    return getImplementation().getDepartment(id)
  },

  /**
   * 建立部門
   * @param {object} departmentData - 部門資料
   * @returns {Promise<Object>}
   */
  async createDepartment (departmentData) {
    return getImplementation().createDepartment(departmentData)
  },

  /**
   * 更新部門
   * @param {string|number} id - 部門 ID
   * @param {object} departmentData - 部門資料
   * @returns {Promise<Object>}
   */
  async updateDepartment (id, departmentData) {
    return getImplementation().updateDepartment(id, departmentData)
  },

  /**
   * 刪除部門
   * @param {string|number} id - 部門 ID
   * @returns {Promise<void>}
   */
  async deleteDepartment (id) {
    return getImplementation().deleteDepartment(id)
  },
}
