/**
 * Applications API Service
 * 申請相關 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import axiosImpl from './axios/applications.js'
import supabaseImpl from './supabase/applications.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 申請服務
 */
export const applicationsService = {
  /**
   * 取得申請列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getApplications (filters = {}) {
    return getImplementation().getApplications(filters)
  },

  /**
   * 取得單一申請
   * @param {number|string} id - 申請 ID
   * @returns {Promise<Object>}
   */
  async getApplication (id) {
    return getImplementation().getApplication(id)
  },

  /**
   * 建立申請
   * @param {object} applicationData - 申請資料
   * @returns {Promise<Object>}
   */
  async createApplication (applicationData) {
    return getImplementation().createApplication(applicationData)
  },

  /**
   * 更新申請
   * @param {number|string} id - 申請 ID
   * @param {object} updates - 更新資料
   * @returns {Promise<Object>}
   */
  async updateApplication (id, updates) {
    return getImplementation().updateApplication(id, updates)
  },

  /**
   * 刪除申請
   * @param {number|string} id - 申請 ID
   * @returns {Promise<void>}
   */
  async deleteApplication (id) {
    return getImplementation().deleteApplication(id)
  },

  /**
   * 核准申請
   * @param {number|string} id - 申請 ID
   * @param {object} approvalData - 核准資料
   * @returns {Promise<Object>}
   */
  async approveApplication (id, approvalData = {}) {
    const impl = getImplementation()
    // 如果實作有 approveApplication 方法，使用它（Supabase）
    if (impl.approveApplication) {
      return impl.approveApplication(id, approvalData)
    }
    // 否則使用通用的 updateApplication（Axios）
    const updates = {
      status: 'APPROVED',
      approval_status: 'APPROVED',
      approval_date: new Date().toISOString(),
      ...approvalData,
    }
    return this.updateApplication(id, updates)
  },

  /**
   * 退回申請
   * @param {number|string} id - 申請 ID
   * @param {object} rejectData - 退回資料
   * @returns {Promise<Object>}
   */
  async rejectApplication (id, rejectData = {}) {
    const impl = getImplementation()
    // 如果實作有 rejectApplication 方法，使用它（Supabase）
    if (impl.rejectApplication) {
      return impl.rejectApplication(id, rejectData)
    }
    // 否則使用通用的 updateApplication（Axios）
    const updates = {
      status: 'REJECTED',
      approval_status: 'REJECTED',
      reject_date: new Date().toISOString(),
      ...rejectData,
    }
    return this.updateApplication(id, updates)
  },
}
