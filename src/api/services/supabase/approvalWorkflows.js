/**
 * Approval Workflows API Service - Supabase Implementation
 * 審核流程管理 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

function extractFormCode (value) {
  if (value == null) return ''
  if (typeof value === 'string') {
    const trimmed = value.trim()
    return trimmed === '[object Object]' ? '' : trimmed
  }
  if (typeof value === 'object') {
    if (typeof value.value === 'string') return value.value.trim()
    if (typeof value.form_code === 'string') return value.form_code.trim()
    if (typeof value.title === 'string') {
      const match = value.title.match(/\(([^)]+)\)\s*$/)
      if (match) return match[1].trim()
    }
  }
  return ''
}

function normalizeFormCodes (formCodes) {
  if (formCodes == null) return []
  if (typeof formCodes === 'string') {
    const trimmed = formCodes.trim()
    if (!trimmed) return []
    try {
      const parsed = JSON.parse(trimmed)
      if (Array.isArray(parsed)) {
        return [...new Set(parsed.map(extractFormCode).filter(Boolean))]
      }
    } catch {
      return trimmed === '[object Object]' ? [] : [trimmed]
    }
    return trimmed === '[object Object]' ? [] : [trimmed]
  }
  if (Array.isArray(formCodes)) {
    return [...new Set(formCodes.map(extractFormCode).filter(Boolean))]
  }
  return []
}

export default {
  /**
   * 取得所有審核狀態定義
   */
  async getApprovalStatuses (options = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('approval_statuses')
      .select('*')

    if (options.is_active !== undefined) {
      query = query.eq('is_active', options.is_active)
    }

    if (options.status_type) {
      query = query.eq('status_type', options.status_type)
    }

    query = query.order('display_order', { ascending: true })

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得單一審核狀態定義
   */
  async getApprovalStatus (statusCode) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_statuses')
      .select('*')
      .eq('status_code', statusCode)
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 建立審核狀態定義
   */
  async createApprovalStatus (statusData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_statuses')
      .insert(statusData)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 更新審核狀態定義
   */
  async updateApprovalStatus (statusCode, statusData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_statuses')
      .update(statusData)
      .eq('status_code', statusCode)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 刪除審核狀態定義
   */
  async deleteApprovalStatus (statusCode) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('approval_statuses')
      .delete()
      .eq('status_code', statusCode)

    if (error) {
      throw error
    }
  },

  /**
   * 取得所有審核流程配置
   */
  async getWorkflows (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('approval_workflows')
      .select('*')

    if (filters.is_active !== undefined) {
      query = query.eq('is_active', filters.is_active)
    }

    if (filters.is_default !== undefined) {
      query = query.eq('is_default', filters.is_default)
    }

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得單一審核流程配置（包含步驟）
   */
  async getWorkflow (workflowIdOrCode) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是代碼
    const isId = typeof workflowIdOrCode === 'number' || /^\d+$/.test(workflowIdOrCode)

    let query = supabase
      .from('approval_workflows')
      .select('*')

    if (isId) {
      query = query.eq('id', workflowIdOrCode)
    } else {
      query = query.eq('workflow_code', workflowIdOrCode)
    }

    const { data: workflow, error } = await query.single()

    if (error) {
      throw error
    }

    // 取得流程步驟
    const { data: steps, error: stepsError } = await supabase
      .from('approval_workflow_steps')
      .select('*')
      .eq('workflow_id', workflow.id)
      .order('step_order', { ascending: true })

    if (stepsError) {
      throw stepsError
    }

    return {
      ...workflow,
      steps: steps || [],
    }
  },

  /**
   * 建立審核流程配置
   */
  async createWorkflow (workflowData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_workflows')
      .insert(workflowData)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 更新審核流程配置
   */
  async updateWorkflow (workflowId, workflowData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_workflows')
      .update(workflowData)
      .eq('id', workflowId)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 刪除審核流程配置
   */
  async deleteWorkflow (workflowId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('approval_workflows')
      .delete()
      .eq('id', workflowId)

    if (error) {
      throw error
    }
  },

  /**
   * 取得審核流程的步驟列表
   */
  async getWorkflowSteps (workflowId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_workflow_steps')
      .select('*')
      .eq('workflow_id', workflowId)
      .order('step_order', { ascending: true })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 建立審核流程步驟
   */
  async createWorkflowStep (stepData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_workflow_steps')
      .insert(stepData)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 更新審核流程步驟
   */
  async updateWorkflowStep (stepId, stepData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_workflow_steps')
      .update(stepData)
      .eq('id', stepId)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 刪除審核流程步驟
   */
  async deleteWorkflowStep (stepId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('approval_workflow_steps')
      .delete()
      .eq('id', stepId)

    if (error) {
      throw error
    }
  },

  /**
   * 取得申請的審核記錄
   */
  async getApprovalRecord (formId, recordId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_records')
      .select('*')
      .eq('form_id', formId)
      .eq('record_id', recordId)
      .maybeSingle()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 取得啟用中的審核流程列表
   */
  async _getActiveWorkflows () {
    if (!isSupabaseAvailable()) {
      return []
    }

    const { data, error } = await supabase
      .from('approval_workflows')
      .select('*')
      .eq('is_active', true)

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得預設審核流程 ID
   */
  async _getDefaultWorkflowId (workflows = null) {
    const list = workflows || await this._getActiveWorkflows()
    const defaultWorkflow = list.find(workflow => workflow.is_default)
    return defaultWorkflow?.id ?? null
  },

  /**
   * 依表單代碼解析審核流程（form_codes 匹配 > 預設流程）
   */
  async resolveWorkflowIdByFormCode (formCode) {
    if (!isSupabaseAvailable()) {
      return null
    }

    const normalizedCode = String(formCode || '').trim()
    const workflows = await this._getActiveWorkflows()

    if (!normalizedCode) {
      return this._getDefaultWorkflowId(workflows)
    }

    const matched = workflows.filter(workflow => {
      const codes = normalizeFormCodes(workflow.form_codes)
      return codes.length > 0 && codes.includes(normalizedCode)
    })

    if (matched.length > 0) {
      const preferred = matched.find(workflow => !workflow.is_default) || matched[0]
      return preferred.id
    }

    return this._getDefaultWorkflowId(workflows)
  },

  /**
   * 依表單 ID 解析審核流程（form_codes 匹配 > 預設流程）
   */
  async resolveWorkflowIdForForm (formId) {
    if (!isSupabaseAvailable() || !formId) {
      return this._getDefaultWorkflowId()
    }

    const { data: form, error } = await supabase
      .from('forms')
      .select('form_code')
      .eq('id', formId)
      .maybeSingle()

    if (error) {
      throw error
    }

    return this.resolveWorkflowIdByFormCode(form?.form_code)
  },

  /**
   * @deprecated 請改用 resolveWorkflowIdForForm
   */
  async _resolveWorkflowIdForForm (formId) {
    return this.resolveWorkflowIdForForm(formId)
  },

  /**
   * 建立申請的審核記錄（提交申請時調用）
   */
  async createApprovalRecord (recordData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 如果沒有指定 workflow_id，依表單 form_code 匹配流程，否則使用預設流程
    if (!recordData.workflow_id) {
      recordData.workflow_id = recordData.form_id
        ? await this.resolveWorkflowIdForForm(recordData.form_id)
        : await this._getDefaultWorkflowId()
    }

    // 如果找到 workflow_id，取得第一個步驟（含條件型分支判斷）
    let firstStep = null
    if (recordData.workflow_id) {
      firstStep = await this._resolveInitialStep(
        recordData.workflow_id,
        recordData.form_id,
        recordData.record_id
      )

      if (firstStep) {
        recordData.current_step_id = firstStep.id
        recordData.current_status_code = firstStep.status_code || 'DRAFT'
      } else {
        const { data: workflow } = await supabase
          .from('approval_workflows')
          .select('initial_status_code')
          .eq('id', recordData.workflow_id)
          .maybeSingle()
        recordData.current_status_code = workflow?.initial_status_code || 'DRAFT'
      }
    } else {
      recordData.current_status_code = 'DRAFT'
    }

    const { data, error } = await supabase
      .from('approval_records')
      .insert(recordData)
      .select()
      .single()

    if (error) {
      throw error
    }

    // 建立提交記錄
    await this._createActionLog({
      approval_record_id: data.id,
      step_id: data.current_step_id,
      action: 'SUBMIT',
      approver_id: recordData.applicant_id,
      from_status_code: null,
      to_status_code: data.current_status_code,
    })

    // 同步表單資料狀態
    if (data.current_status_code) {
      await this._updateFormDataStatus(
        recordData.form_id,
        recordData.record_id,
        data.current_status_code,
      )
    }

    // 如果找到第一個步驟，檢查是否需要自動處理
    if (firstStep && recordData.workflow_id) {
      // 遞迴處理自動通過的步驟
      await this._processAutoApprovalSteps(data.id, recordData.workflow_id, firstStep.id)
    }

    // 重新取得更新後的記錄
    const { data: updatedRecord } = await supabase
      .from('approval_records')
      .select('*')
      .eq('id', data.id)
      .single()

    return updatedRecord || data
  },

  /**
   * 內部方法：取得下一個一般流程步驟（依 step_order）
   */
  async _getNextRegularStepAfter (workflowId, currentStepOrder) {
    if (!workflowId || currentStepOrder == null) {
      return null
    }

    const { data } = await supabase
      .from('approval_workflow_steps')
      .select('id, status_code, approver_type, step_order')
      .eq('workflow_id', workflowId)
      .eq('is_conditional', false)
      .gt('step_order', currentStepOrder)
      .order('step_order', { ascending: true })
      .limit(1)
      .maybeSingle()

    return data
  },

  /**
   * 內部方法：解析核准後的下一個步驟
   */
  async _resolveNextStepOnApprove (currentStep, workflowId) {
    if (!currentStep || !workflowId) {
      return { nextStepId: null, toStatus: null, isCompleted: false }
    }

    let nextStepId = currentStep.next_step_on_approve
    let toStatus = null
    let isCompleted = false

    if (nextStepId) {
      const { data: nextStep } = await supabase
        .from('approval_workflow_steps')
        .select('id, status_code')
        .eq('id', nextStepId)
        .maybeSingle()

      if (nextStep) {
        toStatus = nextStep.status_code
        nextStepId = nextStep.id
      } else {
        toStatus = currentStep.approve_status_code || currentStep.status_code
        nextStepId = null
      }
    }

    if (!nextStepId) {
      const nextRegularStep = await this._getNextRegularStepAfter(workflowId, currentStep.step_order)
      if (nextRegularStep) {
        return {
          nextStepId: nextRegularStep.id,
          toStatus: nextRegularStep.status_code,
          isCompleted: false,
        }
      }
    }

    if (!nextStepId) {
      const { data: workflow } = await supabase
        .from('approval_workflows')
        .select('final_status_code')
        .eq('id', workflowId)
        .maybeSingle()

      toStatus = currentStep.approve_status_code || workflow?.final_status_code || 'APPROVED'
      isCompleted = toStatus === 'APPROVED'

      if (!isCompleted && toStatus) {
        const { data: stepByStatus } = await supabase
          .from('approval_workflow_steps')
          .select('id, status_code')
          .eq('workflow_id', workflowId)
          .eq('status_code', toStatus)
          .order('step_order', { ascending: true })
          .limit(1)
          .maybeSingle()

        if (stepByStatus) {
          nextStepId = stepByStatus.id
          toStatus = stepByStatus.status_code
        }
      }
    }

    return { nextStepId, toStatus, isCompleted }
  },

  /**
   * 處理自動通過的步驟（內部方法）
   */
  async _processAutoApprovalSteps (approvalRecordId, workflowId, stepId) {
    if (!stepId) {
      return
    }

    // 取得當前步驟
    const { data: currentStep, error: stepError } = await supabase
      .from('approval_workflow_steps')
      .select('*')
      .eq('id', stepId)
      .single()

    if (stepError || !currentStep) {
      return
    }

    // 如果審核人類型不是 AUTO，停止處理
    if (currentStep.approver_type !== 'AUTO') {
      return
    }

    // 取得當前審核記錄
    const { data: record } = await supabase
      .from('approval_records')
      .select('*')
      .eq('id', approvalRecordId)
      .single()

    if (!record || record.is_completed) {
      return
    }

    // 自動核准當前步驟
    const { nextStepId, toStatus, isCompleted } = await this._resolveNextStepOnApprove(
      currentStep,
      workflowId,
    )

    // 更新審核記錄
    const updateData = {
      current_status_code: toStatus,
      current_step_id: nextStepId,
      is_completed: isCompleted,
      updated_at: new Date().toISOString(),
    }

    if (isCompleted) {
      updateData.approval_date = new Date().toISOString()
    }

    const { error: updateError } = await supabase
      .from('approval_records')
      .update(updateData)
      .eq('id', approvalRecordId)

    if (updateError) {
      console.error('更新審核記錄失敗', updateError)
      return
    }

    // 建立自動核准記錄
    await this._createActionLog({
      approval_record_id: approvalRecordId,
      step_id: stepId,
      action: 'APPROVE',
      approver_id: null, // 系統自動操作
      approver_name: '系統自動',
      approver_role: 'SYSTEM',
      from_status_code: record.current_status_code,
      to_status_code: toStatus,
      comment: '自動通過（審核人類型為自動通過）',
    })

    // 更新 form_data_values 中的狀態
    await this._updateFormDataStatus(record.form_id, record.record_id, toStatus)

    // 如果還有下一步驟，且下一步驟也是 AUTO，繼續處理
    if (nextStepId && !isCompleted) {
      const { data: nextStep } = await supabase
        .from('approval_workflow_steps')
        .select('approver_type')
        .eq('id', nextStepId)
        .maybeSingle()

      if (nextStep && nextStep.approver_type === 'AUTO') {
        await this._processAutoApprovalSteps(approvalRecordId, workflowId, nextStepId)
      }
    }
  },

  /**
   * 執行審核操作（核准、退回等）
   */
  async executeApprovalAction (actionData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const {
      approval_record_id,
      action, // APPROVE, REJECT, RETURN
      approver_id,
      comment,
      reason,
    } = actionData

    // 取得審核記錄
    const { data: record, error: recordError } = await supabase
      .from('approval_records')
      .select('*')
      .eq('id', approval_record_id)
      .single()

    if (recordError) {
      throw recordError
    }

    if (record.is_completed) {
      throw new Error('此申請已完成審核，無法再進行操作')
    }

    // 取得當前步驟
    const { data: currentStep, error: stepError } = await supabase
      .from('approval_workflow_steps')
      .select('*')
      .eq('id', record.current_step_id)
      .single()

    if (stepError) {
      throw stepError
    }

    const fromStatus = record.current_status_code
    let toStatus = null
    let nextStepId = null
    let isCompleted = false

    // 根據操作類型決定下一步
    if (action === 'APPROVE') {
      const conditionalNext = await this._resolveConditionalNextStep(record, currentStep)

      if (conditionalNext) {
        nextStepId = conditionalNext.id
        toStatus = conditionalNext.status_code
        isCompleted = false
      } else if (currentStep.is_conditional) {
        const nextRegularStep = await this._getRegularStepByOrder(
          record.workflow_id,
          currentStep.trigger_insert_order + 1
        )

        if (nextRegularStep) {
          nextStepId = nextRegularStep.id
          toStatus = nextRegularStep.status_code
          isCompleted = false
        } else {
          const { data: workflow } = await supabase
            .from('approval_workflows')
            .select('final_status_code')
            .eq('id', record.workflow_id)
            .single()

          toStatus = currentStep.approve_status_code || workflow?.final_status_code || 'APPROVED'
          isCompleted = toStatus === 'APPROVED'
          nextStepId = null
        }
      } else {
      // 核准：移到下一步驟
      nextStepId = currentStep.next_step_on_approve

      if (nextStepId) {
        // 取得下一步驟的狀態
        const { data: nextStep } = await supabase
          .from('approval_workflow_steps')
          .select('id, status_code')
          .eq('id', nextStepId)
          .single()

        if (nextStep) {
          // 使用下一步驟的 status_code 作為當前狀態
          toStatus = nextStep.status_code
        } else {
          // 如果找不到下一步驟，使用當前步驟的 approve_status_code
          toStatus = currentStep.approve_status_code || currentStep.status_code
          // 嘗試根據狀態代碼找到對應的步驟
          if (toStatus && record.workflow_id) {
            const { data: stepByStatus } = await supabase
              .from('approval_workflow_steps')
              .select('id')
              .eq('workflow_id', record.workflow_id)
              .eq('status_code', toStatus)
              .order('step_order', { ascending: true })
              .limit(1)
              .maybeSingle()

            if (stepByStatus) {
              nextStepId = stepByStatus.id
            }
          }
        }
      } else {
        // 沒有下一步，表示流程完成，使用當前步驟的 approve_status_code 或流程的 final_status_code
        const { data: workflow } = await supabase
          .from('approval_workflows')
          .select('final_status_code')
          .eq('id', record.workflow_id)
          .single()

        toStatus = currentStep.approve_status_code || workflow?.final_status_code || 'APPROVED'
        // 只有當狀態為 APPROVED 時，才設定 is_completed = true
        isCompleted = toStatus === 'APPROVED'
        // 如果狀態不是 APPROVED，嘗試找到對應的步驟
        if (!isCompleted && toStatus && record.workflow_id) {
          const { data: stepByStatus } = await supabase
            .from('approval_workflow_steps')
            .select('id')
            .eq('workflow_id', record.workflow_id)
            .eq('status_code', toStatus)
            .order('step_order', { ascending: true })
            .limit(1)
            .maybeSingle()

          if (stepByStatus) {
            nextStepId = stepByStatus.id
          }
        }
      }
      }
    } else if (action === 'REJECT' || action === 'RETURN') {
      // 退回：使用當前步驟的 reject_status_code
      toStatus = currentStep.reject_status_code || (action === 'REJECT' ? 'REJECTED' : 'RETURNED')
      // 只有當狀態為 APPROVED 時，才設定 is_completed = true（退回時不應該設定為完成）
      isCompleted = false
      nextStepId = currentStep.next_step_on_reject || null
      // 如果沒有指定 next_step_on_reject，嘗試根據狀態代碼找到對應的步驟
      if (!nextStepId && toStatus && record.workflow_id) {
        const { data: stepByStatus } = await supabase
          .from('approval_workflow_steps')
          .select('id')
          .eq('workflow_id', record.workflow_id)
          .eq('status_code', toStatus)
          .order('step_order', { ascending: true })
          .limit(1)
          .maybeSingle()

        if (stepByStatus) {
          nextStepId = stepByStatus.id
        }
      }
    }

    // 更新審核記錄
    const updateData = {
      current_status_code: toStatus,
      current_step_id: nextStepId,
      is_completed: isCompleted,
      updated_at: new Date().toISOString(),
    }

    if (action === 'APPROVE' && isCompleted) {
      updateData.approval_date = new Date().toISOString()
    }

    if (action === 'REJECT' || action === 'RETURN') {
      updateData.reject_date = new Date().toISOString()
      updateData.reject_reason = reason
    }

    const { data: updatedRecord, error: updateError } = await supabase
      .from('approval_records')
      .update(updateData)
      .eq('id', approval_record_id)
      .select()
      .single()

    if (updateError) {
      throw updateError
    }

    // 取得審核人資訊
    const { data: approver } = await supabase
      .from('user_profiles')
      .select('username, role')
      .eq('id', approver_id)
      .single()

    // 建立操作記錄
    await this._createActionLog({
      approval_record_id,
      step_id: record.current_step_id,
      action,
      approver_id,
      approver_name: approver?.username,
      approver_role: approver?.role,
      from_status_code: fromStatus,
      to_status_code: toStatus,
      comment,
      reason,
    })

    // 更新 form_data_values 中的狀態
    await this._updateFormDataStatus(record.form_id, record.record_id, toStatus)

    return updatedRecord
  },

  /**
   * 取得申請的審核操作記錄
   */
  async getApprovalActionLogs (approvalRecordId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('approval_action_logs')
      .select('*')
      .eq('approval_record_id', approvalRecordId)
      .order('action_date', { ascending: false })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得待審核申請列表
   * 邏輯：
   * 1. 找出狀態類型為 INTERMEDIATE 的申請單（非 INITIAL 和 FINAL）
   * 2. 透過審核流程的步驟找到對應的狀態，檢查當前用戶是否符合審核條件
   */
  async getPendingApprovalApplications (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 獲取當前用戶資訊
    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser) {
      return []
    }

    // 獲取當前用戶的 profile 資訊
    const { data: currentUserProfile } = await supabase
      .from('user_profiles')
      .select('id, username, role, department')
      .eq('id', authUser.id)
      .single()

    if (!currentUserProfile) {
      return []
    }

    const currentUserId = currentUserProfile.id
    const currentUserRole = currentUserProfile.role
    const currentUserDepartment = currentUserProfile.department

    const { data: allUserProfiles } = await supabase
      .from('user_profiles')
      .select('id, username')

    const usernameToUserId = new Map(
      (allUserProfiles || [])
        .filter(profile => profile.username)
        .map(profile => [profile.username, profile.id]),
    )

    const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

    const resolveStoredUserId = (value) => {
      if (value == null) return null
      const str = String(value).trim()
      if (!str) return null
      if (UUID_PATTERN.test(str)) return str
      return usernameToUserId.get(str) || null
    }

    const resolveStoredUserIds = (values) => {
      return [...new Set((values || []).map(resolveStoredUserId).filter(Boolean))]
    }

    const isCurrentUserInApproverList = (values) => {
      return resolveStoredUserIds(values).includes(currentUserId)
    }

    // 1. 查詢待審核的審核記錄
    // 2. 關聯當前步驟和狀態資訊
    // 3. 檢查當前用戶是否符合審核條件

    let sqlQuery = `
      SELECT DISTINCT
        ar.id AS approval_record_id,
        ar.form_id,
        ar.record_id,
        ar.workflow_id,
        ar.current_step_id,
        ar.current_status_code,
        ar.applicant_id,
        ar.submit_date,
        ar.approval_date,
        ar.reject_date,
        ar.reject_reason,
        ar.is_completed,
        -- 申請人資訊
        up.username AS applicant_username,
        -- 當前步驟資訊
        aws.step_name AS current_step_name,
        aws.step_order AS current_step_order,
        aws.approver_type,
        aws.approver_config,
        aws.approval_departments,
        aws.approver_user_ids,
        -- 狀態資訊
        ast.status_name AS current_status_name,
        ast.color AS status_color,
        ast.icon AS status_icon,
        ast.status_type,
        -- 流程資訊
        aw.workflow_name,
        aw.workflow_code
      FROM approval_records ar
      LEFT JOIN user_profiles up ON ar.applicant_id = up.id
      LEFT JOIN approval_workflow_steps aws ON ar.current_step_id = aws.id
      LEFT JOIN approval_statuses ast ON ar.current_status_code = ast.status_code
      LEFT JOIN approval_workflows aw ON ar.workflow_id = aw.id
      WHERE ar.is_completed = FALSE
        AND (ast.status_type IS NULL OR ast.status_type <> 'FINAL')
    `

    const sqlParams = []

    // 應用篩選條件
    if (filters.status_code) {
      sqlQuery += ` AND ar.current_status_code = $${sqlParams.length + 1}`
      sqlParams.push(filters.status_code)
    }

    if (filters.applicant_id) {
      sqlQuery += ` AND ar.applicant_id = $${sqlParams.length + 1}`
      sqlParams.push(filters.applicant_id)
    }

    if (filters.form_id) {
      sqlQuery += ` AND ar.form_id = $${sqlParams.length + 1}`
      sqlParams.push(filters.form_id)
    }

    if (filters.dateFrom) {
      const dateFrom = new Date(filters.dateFrom)
      dateFrom.setHours(0, 0, 0, 0)
      sqlQuery += ` AND ar.submit_date >= $${sqlParams.length + 1}`
      sqlParams.push(dateFrom.toISOString())
    }

    if (filters.dateTo) {
      const dateTo = new Date(filters.dateTo)
      dateTo.setHours(23, 59, 59, 999)
      sqlQuery += ` AND ar.submit_date <= $${sqlParams.length + 1}`
      sqlParams.push(dateTo.toISOString())
    }

    sqlQuery += ` ORDER BY ar.submit_date DESC`

    // 輸出 SQL 查詢語句到 console（供 Supabase 調試使用）
    console.log('=== 待審核申請查詢 SQL ===')
    console.log('SQL Query:', sqlQuery)
    console.log('SQL Parameters:', sqlParams)
    console.log('Current User ID:', currentUserId)
    console.log('Current User Role:', currentUserRole)
    console.log('Current User Department:', currentUserDepartment)
    console.log('==========================')

    // 使用標準 Supabase 查詢
    // 注意：如果關聯查詢失敗，我們會手動查詢步驟資料
    let query = supabase
      .from('approval_records')
      .select(`
        *,
        applicant:user_profiles!approval_records_applicant_id_fkey (
          id,
          username
        ),
        current_status:approval_statuses!approval_records_current_status_code_fkey (
          status_code,
          status_name,
          color,
          icon,
          status_type
        ),
        workflow:approval_workflows!approval_records_workflow_id_fkey (
          id,
          workflow_name,
          workflow_code
        )
      `)
      .eq('is_completed', false)

    // 應用篩選條件
    if (filters.status_code) {
      query = query.eq('current_status_code', filters.status_code)
    }

    if (filters.applicant_id) {
      query = query.eq('applicant_id', filters.applicant_id)
    }

    if (filters.form_id) {
      query = query.eq('form_id', filters.form_id)
    }

    if (filters.dateFrom) {
      const dateFrom = new Date(filters.dateFrom)
      dateFrom.setHours(0, 0, 0, 0)
      query = query.gte('submit_date', dateFrom.toISOString())
    }

    if (filters.dateTo) {
      const dateTo = new Date(filters.dateTo)
      dateTo.setHours(23, 59, 59, 999)
      query = query.lte('submit_date', dateTo.toISOString())
    }

    query = query.order('submit_date', { ascending: false })

    const { data, error } = await query

    if (error) {
      throw error
    }

    const records = data || []

    console.log('=== 過濾前記錄數 ===')
    console.log('總記錄數:', records.length)
    console.log('當前用戶 ID:', currentUserId)
    console.log('當前用戶角色:', currentUserRole)
    console.log('當前用戶部門:', currentUserDepartment)
    console.log('==================')

    // 修復 current_step_id 為 null 的記錄
    // 如果 current_step_id 為 null，嘗試根據 current_status_code 找到對應的步驟
    const recordsToFix = records.filter(r => !r.current_step_id && r.current_status_code && r.workflow_id)
    if (recordsToFix.length > 0) {
      console.log(`發現 ${recordsToFix.length} 筆記錄需要修復 current_step_id`)
      for (const record of recordsToFix) {
        try {
          // 根據狀態代碼找到對應的步驟
          const { data: stepByStatus } = await supabase
            .from('approval_workflow_steps')
            .select('id')
            .eq('workflow_id', record.workflow_id)
            .eq('status_code', record.current_status_code)
            .order('step_order', { ascending: true })
            .limit(1)
            .maybeSingle()

          if (stepByStatus) {
            // 更新記錄的 current_step_id
            await supabase
              .from('approval_records')
              .update({ current_step_id: stepByStatus.id })
              .eq('id', record.id)

            // 更新記憶體中的記錄
            record.current_step_id = stepByStatus.id
            console.log(`修復記錄 ${record.id}: current_step_id = ${stepByStatus.id}`)
          } else {
            console.warn(`無法找到狀態 ${record.current_status_code} 對應的步驟 (workflow_id: ${record.workflow_id})`)
          }
        } catch (error) {
          console.error(`修復記錄 ${record.id} 失敗:`, error)
        }
      }
    }

    // 獲取所有需要的步驟 ID（包括修復後的）
    const stepIds = records
      .map(r => r.current_step_id)
      .filter(Boolean)
      .filter((id, index, self) => self.indexOf(id) === index) // 去重

    // 批量查詢步驟資料
    const stepsMap = new Map()
    if (stepIds.length > 0) {
      const { data: stepsData } = await supabase
        .from('approval_workflow_steps')
        .select('id, step_name, step_order, approver_type, approver_config, approval_departments, approver_user_ids')
        .in('id', stepIds)

      if (stepsData) {
        for (const step of stepsData) {
          stepsMap.set(step.id, step)
        }
      }
    }

    console.log('步驟資料:', Array.from(stepsMap.entries()))

    // 過濾符合審核條件的記錄
    const filteredRecords = records.filter((record, index) => {
      // 手動關聯步驟資料
      const step = record.current_step_id ? stepsMap.get(record.current_step_id) : null
      const status = record.current_status

      console.log(`\n--- 檢查記錄 ${index + 1} (record_id: ${record.record_id}) ---`)
      console.log('current_step_id:', record.current_step_id)
      console.log('狀態:', status?.status_code, '狀態類型:', status?.status_type)
      console.log('步驟:', step?.step_name, '審核人類型:', step?.approver_type)

      // 排除已完成；允許 INTERMEDIATE 與等待人工審核的 INITIAL 狀態
      if (!status || status.status_type === 'FINAL') {
        console.log('❌ 過濾原因: 狀態為最終狀態或缺少狀態')
        return false
      }

      if (!step) {
        console.log('❌ 過濾原因: 沒有當前步驟')
        return false
      }

      const approverType = step.approver_type
      const approverConfig = step.approver_config || {}
      const approvalDepartments = step.approval_departments || []
      const approverUserIds = step.approver_user_ids || []

      console.log('審核人配置:', {
        approverType,
        approverConfig,
        approvalDepartments,
        approverUserIds,
      })

      // 檢查審核條件
      if (approverType === 'AUTO') {
        // 自動通過，不需要審核
        console.log('❌ 過濾原因: 審核人類型為 AUTO（自動通過）')
        return false
      }

      // 系統管理員可檢視所有待審核項目
      if (currentUserRole === 'admin') {
        console.log('✓ 管理員可審核此項目')
        return true
      }

      // 檢查審核條件
      if (approverType === 'USER') {
        const userIds = resolveStoredUserIds([
          ...approverUserIds,
          ...(approverConfig.user_ids || []),
        ])

        console.log('USER 類型檢查 - 審核人 ID 列表:', userIds)

        if (userIds.length > 0) {
          if (!isCurrentUserInApproverList(userIds)) {
            console.log('❌ 過濾原因: 當前用戶不在審核人列表中')
            return false
          }
          console.log('✓ 當前用戶在審核人列表中')
        } else {
          console.log('⚠ 警告: USER 類型但沒有指定審核人列表，允許通過')
        }

        // 如果有指定審核權限部門，進一步檢查
        if (approvalDepartments.length > 0) {
          console.log('檢查部門:', approvalDepartments, 'vs', currentUserDepartment)
          if (!currentUserDepartment || !approvalDepartments.includes(currentUserDepartment)) {
            console.log('❌ 過濾原因: 當前用戶部門不符合要求')
            return false
          }
          console.log('✓ 部門檢查通過')
        }
      } else if (approverType === 'ROLE') {
        // 指定角色：檢查角色是否匹配
        const requiredRole = approverConfig.role
        console.log('ROLE 類型檢查 - 需要角色:', requiredRole, '當前角色:', currentUserRole)

        if (requiredRole && currentUserRole !== requiredRole) {
          console.log('❌ 過濾原因: 角色不匹配')
          return false
        }
        console.log('✓ 角色檢查通過')

        // 如果有指定審核權限部門，進一步檢查
        if (approvalDepartments.length > 0) {
          console.log('檢查部門:', approvalDepartments, 'vs', currentUserDepartment)
          if (!currentUserDepartment || !approvalDepartments.includes(currentUserDepartment)) {
            console.log('❌ 過濾原因: 當前用戶部門不符合要求')
            return false
          }
          console.log('✓ 部門檢查通過')
        }

        // 如果有指定審核人列表，進一步檢查
        if (approverUserIds.length > 0) {
          console.log('檢查審核人列表:', resolveStoredUserIds(approverUserIds))
          if (!isCurrentUserInApproverList(approverUserIds)) {
            console.log('❌ 過濾原因: 當前用戶不在審核人列表中')
            return false
          }
          console.log('✓ 審核人列表檢查通過')
        }
      } else if (approverType === 'DEPARTMENT') {
        // 指定部門：檢查部門是否匹配
        const requiredDepartments = approvalDepartments.length > 0
          ? approvalDepartments
          : (approverConfig.departments || [approverConfig.department].filter(Boolean))

        console.log('DEPARTMENT 類型檢查 - 需要部門:', requiredDepartments, '當前部門:', currentUserDepartment)

        if (requiredDepartments.length > 0) {
          if (!currentUserDepartment || !requiredDepartments.includes(currentUserDepartment)) {
            console.log('❌ 過濾原因: 部門不匹配')
            return false
          }
          console.log('✓ 部門檢查通過')
        } else {
          console.log('⚠ 警告: DEPARTMENT 類型但沒有指定部門，允許通過')
        }

        // 如果有指定審核人列表，進一步檢查
        if (approverUserIds.length > 0) {
          console.log('檢查審核人列表:', resolveStoredUserIds(approverUserIds))
          if (!isCurrentUserInApproverList(approverUserIds)) {
            console.log('❌ 過濾原因: 當前用戶不在審核人列表中')
            return false
          }
          console.log('✓ 審核人列表檢查通過')
        }
      } else {
        console.log(`⚠ 警告: 未知的審核人類型 ${approverType}，允許通過`)
      }

      console.log('✅ 記錄通過所有檢查')
      return true
    })

    console.log('\n=== 過濾後記錄數 ===')
    console.log('過濾後記錄數:', filteredRecords.length)
    console.log('==================\n')

    // 轉換資料格式
    return filteredRecords.map(record => ({
      approval_record_id: record.id,
      form_id: record.form_id,
      record_id: record.record_id,
      workflow_id: record.workflow_id,
      current_step_id: record.current_step_id,
      current_status_code: record.current_status_code,
      applicant_id: record.applicant_id,
      submit_date: record.submit_date,
      approval_date: record.approval_date,
      reject_date: record.reject_date,
      reject_reason: record.reject_reason,
      is_completed: record.is_completed,
      applicant_username: record.applicant?.username || 'Unknown',
      current_step_name: record.current_step?.step_name || null,
      current_step_order: record.current_step?.step_order || null,
      current_status_name: record.current_status?.status_name || record.current_status_code,
      status_color: record.current_status?.color || 'grey',
      status_icon: record.current_status?.icon || null,
      workflow_name: record.workflow?.workflow_name || null,
      workflow_code: record.workflow?.workflow_code || null,
    }))
  },

  /**
   * 取得所有申請列表（包含已完成和待審核的）
   */
  async getAllApprovalApplications (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 查詢所有審核記錄（不限制 is_completed）
    let query = supabase
      .from('approval_records')
      .select(`
        *,
        applicant:user_profiles!approval_records_applicant_id_fkey (
          id,
          username
        ),
        current_step:approval_workflow_steps!approval_records_current_step_id_fkey (
          id,
          step_name,
          step_order
        ),
        current_status:approval_statuses!approval_records_current_status_code_fkey (
          status_code,
          status_name,
          color,
          icon
        ),
        workflow:approval_workflows!approval_records_workflow_id_fkey (
          id,
          workflow_name,
          workflow_code
        )
      `)

    // 應用篩選條件
    if (filters.status_code) {
      query = query.eq('current_status_code', filters.status_code)
    }

    if (filters.applicant_id) {
      query = query.eq('applicant_id', filters.applicant_id)
    }

    if (filters.form_id) {
      query = query.eq('form_id', filters.form_id)
    }

    if (filters.is_completed !== undefined) {
      query = query.eq('is_completed', filters.is_completed)
    }

    if (filters.dateFrom) {
      const dateFrom = new Date(filters.dateFrom)
      dateFrom.setHours(0, 0, 0, 0)
      query = query.gte('submit_date', dateFrom.toISOString())
    }

    if (filters.dateTo) {
      const dateTo = new Date(filters.dateTo)
      dateTo.setHours(23, 59, 59, 999)
      query = query.lte('submit_date', dateTo.toISOString())
    }

    // 排序
    query = query.order('submit_date', { ascending: false })

    const { data, error } = await query

    if (error) {
      throw error
    }

    // 轉換資料格式
    return (data || []).map(record => ({
      approval_record_id: record.id,
      form_id: record.form_id,
      record_id: record.record_id,
      workflow_id: record.workflow_id,
      current_step_id: record.current_step_id,
      current_status_code: record.current_status_code,
      applicant_id: record.applicant_id,
      submit_date: record.submit_date,
      approval_date: record.approval_date,
      reject_date: record.reject_date,
      reject_reason: record.reject_reason,
      is_completed: record.is_completed,
      applicant_username: record.applicant?.username || 'Unknown',
      current_step_name: record.current_step?.step_name || null,
      current_step_order: record.current_step?.step_order || null,
      current_status_name: record.current_status?.status_name || record.current_status_code,
      status_color: record.current_status?.color || 'grey',
      status_icon: record.current_status?.icon || null,
      workflow_name: record.workflow?.workflow_name || null,
      workflow_code: record.workflow?.workflow_code || null,
    }))
  },

  /**
   * 取得當前審核人列表
   */
  async getCurrentApprovers (approvalRecordId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 使用資料庫函數
    const { data, error } = await supabase.rpc('get_current_approvers', {
      p_approval_record_id: approvalRecordId,
    })

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 內部方法：建立操作記錄
   */
  async _createActionLog (logData) {
    const { error } = await supabase
      .from('approval_action_logs')
      .insert({
        ...logData,
        action_date: new Date().toISOString(),
      })

    if (error) {
      console.error('建立操作記錄失敗', error)
      // 不拋出錯誤，因為這不應該影響主要操作
    }
  },

  /**
   * 內部方法：讀取表單欄位值
   */
  async _getFormFieldValue (formId, recordId, fieldKey) {
    if (!formId || !recordId || !fieldKey) {
      return null
    }

    const { data } = await supabase
      .from('form_data_values')
      .select('field_value')
      .eq('form_id', formId)
      .eq('record_id', recordId)
      .eq('field_key', fieldKey)
      .maybeSingle()

    return data?.field_value ?? null
  },

  /**
   * 內部方法：比對觸發值
   */
  _compareTriggerValue (actualValue, expectedValue, operator = 'equals') {
    const actual = actualValue == null ? '' : String(actualValue).trim()
    const expected = expectedValue == null ? '' : String(expectedValue).trim()

    switch (operator) {
      case 'not_equals':
        return actual !== expected
      case 'contains':
        return expected !== '' && actual.includes(expected)
      case 'not_contains':
        return expected === '' || !actual.includes(expected)
      case 'starts_with':
        return expected !== '' && actual.startsWith(expected)
      case 'ends_with':
        return expected !== '' && actual.endsWith(expected)
      case 'equals':
      default:
        return actual === expected
    }
  },

  /**
   * 內部方法：依插入點尋找符合條件的步驟
   */
  async _findMatchingConditionalStep (workflowId, insertOrder, formId, recordId) {
    if (!workflowId || insertOrder === null || insertOrder === undefined) {
      return null
    }

    const { data: steps, error } = await supabase
      .from('approval_workflow_steps')
      .select('*')
      .eq('workflow_id', workflowId)
      .eq('is_conditional', true)
      .eq('trigger_insert_order', insertOrder)
      .order('step_order', { ascending: true })

    if (error || !steps?.length) {
      return null
    }

    for (const step of steps) {
      const fieldValue = await this._getFormFieldValue(formId, recordId, step.trigger_field)
      if (this._compareTriggerValue(fieldValue, step.trigger_value, step.trigger_operator)) {
        return step
      }
    }

    return null
  },

  /**
   * 內部方法：取得一般流程步驟
   */
  async _getRegularStepByOrder (workflowId, stepOrder) {
    if (!workflowId || !stepOrder) {
      return null
    }

    const { data } = await supabase
      .from('approval_workflow_steps')
      .select('*')
      .eq('workflow_id', workflowId)
      .eq('is_conditional', false)
      .eq('step_order', stepOrder)
      .maybeSingle()

    return data
  },

  /**
   * 內部方法：決定流程起始步驟
   */
  async _resolveInitialStep (workflowId, formId, recordId) {
    const conditionalStep = await this._findMatchingConditionalStep(workflowId, 0, formId, recordId)
    if (conditionalStep) {
      return conditionalStep
    }

    const { data: firstStep } = await supabase
      .from('approval_workflow_steps')
      .select('id, status_code, approver_type')
      .eq('workflow_id', workflowId)
      .eq('is_conditional', false)
      .eq('step_order', 1)
      .maybeSingle()

    return firstStep
  },

  /**
   * 內部方法：一般步驟核准後，判斷是否進入條件型分支
   */
  async _resolveConditionalNextStep (record, currentStep) {
    if (currentStep.is_conditional) {
      return null
    }

    return this._findMatchingConditionalStep(
      record.workflow_id,
      currentStep.step_order,
      record.form_id,
      record.record_id
    )
  },

  /**
   * 內部方法：更新表單資料狀態
   */
  async _updateFormDataStatus (formId, recordId, statusCode) {
    // 查找 status 欄位
    const { data: statusField } = await supabase
      .from('form_fields')
      .select('id, field_key')
      .eq('form_id', formId)
      .eq('field_key', 'status')
      .single()

    if (statusField) {
      // 更新或插入狀態值
      const { error } = await supabase
        .from('form_data_values')
        .upsert({
          form_id: formId,
          field_id: statusField.id,
          record_id: recordId,
          field_key: 'status',
          field_value: statusCode,
          updated_at: new Date().toISOString(),
        }, {
          onConflict: 'form_id,field_id,record_id,field_key',
        })

      if (error) {
        console.error('更新表單狀態失敗', error)
      }
    }

    // 同樣更新 approval_status
    const { data: approvalStatusField } = await supabase
      .from('form_fields')
      .select('id, field_key')
      .eq('form_id', formId)
      .eq('field_key', 'approval_status')
      .single()

    if (approvalStatusField) {
      const { error } = await supabase
        .from('form_data_values')
        .upsert({
          form_id: formId,
          field_id: approvalStatusField.id,
          record_id: recordId,
          field_key: 'approval_status',
          field_value: statusCode,
          updated_at: new Date().toISOString(),
        }, {
          onConflict: 'form_id,field_id,record_id,field_key',
        })

      if (error) {
        console.error('更新審核狀態失敗', error)
      }
    }
  },
}
