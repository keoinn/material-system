/**
 * Approval Workflows API Service
 * 審核流程管理 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import supabaseImpl from './supabase/approvalWorkflows.js'
// import axiosImpl from './axios/approvalWorkflows.js' // 未來可實作

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? null : supabaseImpl // 目前只支援 Supabase
}

/**
 * 審核流程服務
 */
export const approvalWorkflowsService = {
  /**
   * 取得所有審核狀態定義
   * @returns {Promise<Array>}
   */
  async getApprovalStatuses (options = {}) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getApprovalStatuses(options)
  },

  /**
   * 取得單一審核狀態定義
   * @param {string} statusCode - 狀態代碼
   * @returns {Promise<Object>}
   */
  async getApprovalStatus (statusCode) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getApprovalStatus(statusCode)
  },

  /**
   * 建立審核狀態定義
   * @param {Object} statusData - 狀態資料
   * @returns {Promise<Object>}
   */
  async createApprovalStatus (statusData) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.createApprovalStatus(statusData)
  },

  /**
   * 更新審核狀態定義
   * @param {string} statusCode - 狀態代碼
   * @param {Object} statusData - 狀態資料
   * @returns {Promise<Object>}
   */
  async updateApprovalStatus (statusCode, statusData) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.updateApprovalStatus(statusCode, statusData)
  },

  /**
   * 刪除審核狀態定義
   * @param {string} statusCode - 狀態代碼
   * @returns {Promise<void>}
   */
  async deleteApprovalStatus (statusCode) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.deleteApprovalStatus(statusCode)
  },

  /**
   * 取得所有審核流程配置
   * @param {Object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getWorkflows (filters = {}) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getWorkflows(filters)
  },

  /**
   * 取得單一審核流程配置（包含步驟）
   * @param {number|string} workflowIdOrCode - 流程 ID 或代碼
   * @returns {Promise<Object>}
   */
  async getWorkflow (workflowIdOrCode) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getWorkflow(workflowIdOrCode)
  },

  /**
   * 建立審核流程配置
   * @param {Object} workflowData - 流程資料
   * @returns {Promise<Object>}
   */
  async createWorkflow (workflowData) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.createWorkflow(workflowData)
  },

  /**
   * 更新審核流程配置
   * @param {number} workflowId - 流程 ID
   * @param {Object} workflowData - 流程資料
   * @returns {Promise<Object>}
   */
  async updateWorkflow (workflowId, workflowData) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.updateWorkflow(workflowId, workflowData)
  },

  /**
   * 刪除審核流程配置
   * @param {number} workflowId - 流程 ID
   * @returns {Promise<void>}
   */
  async deleteWorkflow (workflowId) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.deleteWorkflow(workflowId)
  },

  /**
   * 取得審核流程的步驟列表
   * @param {number} workflowId - 流程 ID
   * @returns {Promise<Array>}
   */
  async getWorkflowSteps (workflowId) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getWorkflowSteps(workflowId)
  },

  /**
   * 建立審核流程步驟
   * @param {Object} stepData - 步驟資料
   * @returns {Promise<Object>}
   */
  async createWorkflowStep (stepData) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.createWorkflowStep(stepData)
  },

  /**
   * 更新審核流程步驟
   * @param {number} stepId - 步驟 ID
   * @param {Object} stepData - 步驟資料
   * @returns {Promise<Object>}
   */
  async updateWorkflowStep (stepId, stepData) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.updateWorkflowStep(stepId, stepData)
  },

  /**
   * 刪除審核流程步驟
   * @param {number} stepId - 步驟 ID
   * @returns {Promise<void>}
   */
  async deleteWorkflowStep (stepId) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.deleteWorkflowStep(stepId)
  },

  /**
   * 取得申請的審核記錄
   * @param {number} formId - 表單 ID
   * @param {number} recordId - 記錄 ID
   * @returns {Promise<Object>}
   */
  async getApprovalRecord (formId, recordId) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getApprovalRecord(formId, recordId)
  },

  /**
   * 建立申請的審核記錄（提交申請時調用）
   * @param {Object} recordData - 記錄資料
   * @returns {Promise<Object>}
   */
  async createApprovalRecord (recordData) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.createApprovalRecord(recordData)
  },

  /**
   * 依表單 ID 解析審核流程（form_codes 匹配 > 預設流程）
   * @param {number} formId - 表單 ID
   * @returns {Promise<number|null>}
   */
  async resolveWorkflowIdForForm (formId) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.resolveWorkflowIdForForm(formId)
  },

  /**
   * 依表單代碼解析審核流程（form_codes 匹配 > 預設流程）
   * @param {string} formCode - 表單代碼
   * @returns {Promise<number|null>}
   */
  async resolveWorkflowIdByFormCode (formCode) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.resolveWorkflowIdByFormCode(formCode)
  },

  /**
   * 執行審核操作（核准、退回等）
   * @param {Object} actionData - 操作資料
   * @returns {Promise<Object>}
   */
  async executeApprovalAction (actionData) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.executeApprovalAction(actionData)
  },

  /**
   * 取得申請的審核操作記錄
   * @param {number} approvalRecordId - 審核記錄 ID
   * @returns {Promise<Array>}
   */
  async getApprovalActionLogs (approvalRecordId) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getApprovalActionLogs(approvalRecordId)
  },

  /**
   * 取得當前審核人列表
   * @param {number} approvalRecordId - 審核記錄 ID
   * @returns {Promise<Array>}
   */
  async getCurrentApprovers (approvalRecordId) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getCurrentApprovers(approvalRecordId)
  },

  /**
   * 取得待審核申請列表（使用視圖）
   * @param {Object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getPendingApprovalApplications (filters = {}) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getPendingApprovalApplications(filters)
  },

  /**
   * 取得所有申請列表（包含已完成和待審核的）
   * @param {Object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getAllApprovalApplications (filters = {}) {
    const impl = getImplementation()
    if (!impl) throw new Error('審核流程服務目前僅支援 Supabase')
    return impl.getAllApprovalApplications(filters)
  },
}

export default approvalWorkflowsService
