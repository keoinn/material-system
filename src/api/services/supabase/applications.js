/**
 * Applications API Service - Supabase Implementation
 * 申請相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得申請列表（使用 approval_records 和 form_data_values）
   */
  async getApplications (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 動態導入審核流程服務（避免循環依賴）
    const { approvalWorkflowsService } = await import('../approvalWorkflows.js')

    // 構建審核記錄的篩選條件
    const approvalFilters = {
      is_completed: filters.is_completed !== undefined ? filters.is_completed : undefined,
    }

    if (filters.status) {
      approvalFilters.status_code = filters.status
    }

    if (filters.dateFrom) {
      approvalFilters.dateFrom = filters.dateFrom
    }

    if (filters.dateTo) {
      approvalFilters.dateTo = filters.dateTo
    }

    // 如果 applicant 是字符串（姓名），先查找匹配的用戶 ID
    if (filters.applicant && typeof filters.applicant === 'string') {
      const { data: matchingUsers } = await supabase
        .from('user_profiles')
        .select('id')
        .ilike('username', `%${filters.applicant}%`)

      if (matchingUsers && matchingUsers.length > 0) {
        approvalFilters.applicant_id = matchingUsers[0].id // 使用第一個匹配的用戶
      } else {
        // 如果沒有找到匹配的用戶，返回空結果
        return []
      }
    } else if (filters.applicant) {
      approvalFilters.applicant_id = filters.applicant
    }

    // 獲取所有審核記錄（包含已完成和待審核的）
    const approvalRecords = await approvalWorkflowsService.getAllApprovalApplications(approvalFilters)

    // 為每個審核記錄獲取表單資料
    const applications = await Promise.all(
      approvalRecords.map(async (record) => {
        try {
          // 從 form_data_values 獲取表單資料
          const { formDataService } = await import('../formData.js')
          const formData = await formDataService.getFormData(record.form_id, record.record_id, {
            includeFieldDefinitions: true,
          })

          // 提取關鍵欄位值
          const values = formData?.values || {}
          const fields = formData?.fields || []

          // 查找欄位定義以確定正確的 field_key
          // 料號可能對應到 system_code 或 item_code
          const systemCodeField = fields.find(f => f.field_key === 'system_code' || f.field_key === 'systemCode')
          const itemCodeField = systemCodeField || fields.find(f => f.field_key === 'item_code' || f.field_key === 'itemCode')

          let itemCode = values.system_code || values.systemCode || values.item_code || values.itemCode
          // 如果是聚合欄位，嘗試重新計算
          if (itemCodeField && itemCodeField.field_type === 'aggregated' && itemCodeField.field_config?.template) {
            try {
              const { formDataService: formDataSvc } = await import('../formData.js')
              itemCode = await formDataSvc._calculateAggregatedValue(
                itemCodeField.field_config.template,
                values,
                itemCodeField.field_config.counterKey || itemCodeField.field_key,
              )
            } catch (error) {
              console.warn('重新計算聚合料號失敗，使用原始值', error)
            }
          }
          if (!itemCode || itemCode === '') {
            itemCode = 'N/A'
          }

          // 料件說明可能對應到 materials_desc_cn 或 item_name_cn
          const itemNameCN = values.materials_desc_cn || values.materialsDescCN || values.item_name_cn || values.itemNameCN || 'N/A'
          const itemNameEN = values.item_name_en || values.itemNameEN || 'N/A'

          // 如果篩選條件包含 itemCode，進行過濾
          if (filters.itemCode && !itemCode.toLowerCase().includes(filters.itemCode.toLowerCase())) {
            return null
          }

          return {
            id: record.record_id,
            record_id: record.record_id,
            item_code: itemCode,
            item_name_cn: itemNameCN,
            item_name_en: itemNameEN,
            material: values.material || null,
            surface_finish: values.surface_finish || values.surfaceFinish || null,
            dimensions: values.dimensions || null,
            customer_ref: values.customer_ref || values.customerRef || null,
            applicant_id: record.applicant_id,
            applicant_name: record.applicant_username || 'Unknown',
            status: record.current_status_code,
            approval_status: record.current_status_code,
            submit_date: record.submit_date,
            approval_date: record.approval_date,
            reject_date: record.reject_date,
            reject_reason: record.reject_reason,
            is_dynamic_form: true,
            form_id: record.form_id,
            // 審核流程相關資訊
            current_status_code: record.current_status_code,
            current_status_name: record.current_status_name,
            status_color: record.status_color,
            status_icon: record.status_icon,
            current_step_name: record.current_step_name,
            workflow_name: record.workflow_name,
            workflow_id: record.workflow_id,
            current_step_id: record.current_step_id,
            current_step_order: record.current_step_order,
          }
        } catch (error) {
          console.error(`載入申請 ${record.record_id} 的表單資料失敗`, error)
          // 即使載入表單資料失敗，也返回基本資訊
          return {
            id: record.record_id,
            record_id: record.record_id,
            item_code: 'N/A',
            item_name_cn: 'N/A',
            item_name_en: 'N/A',
            applicant_id: record.applicant_id,
            applicant_name: record.applicant_username || 'Unknown',
            status: record.current_status_code,
            approval_status: record.current_status_code,
            submit_date: record.submit_date,
            is_dynamic_form: true,
            form_id: record.form_id,
            current_status_code: record.current_status_code,
            current_status_name: record.current_status_name,
            status_color: record.status_color,
            status_icon: record.status_icon,
            current_step_name: record.current_step_name,
            workflow_name: record.workflow_name,
            workflow_id: record.workflow_id,
            current_step_id: record.current_step_id,
            current_step_order: record.current_step_order,
          }
        }
      })
    )

    // 過濾掉 null 值（不符合 itemCode 篩選條件的）
    return applications.filter(app => app !== null)
  },

  /**
   * 取得單一申請（使用 approval_records 和 form_data_values）
   */
  async getApplication (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 動態導入服務
    const { approvalWorkflowsService } = await import('../approvalWorkflows.js')
    const { formDataService } = await import('../formData.js')

    // 查找所有審核記錄，找到對應的 record_id
    const allRecords = await approvalWorkflowsService.getAllApprovalApplications({})
    const record = allRecords.find(r => r.record_id === id || r.approval_record_id === id)

    if (!record) {
      throw new Error('找不到申請記錄')
    }

    // 從 form_data_values 獲取表單資料（包含欄位定義以便查找正確的 field_key）
    const formData = await formDataService.getFormData(record.form_id, record.record_id, {
      includeFieldDefinitions: true,
    })

    // 提取關鍵欄位值
    const values = formData?.values || {}
    const fields = formData?.fields || []

    // 查找欄位定義以確定正確的 field_key
    // 料號可能對應到 system_code 或 item_code
    const systemCodeField = fields.find(f => f.field_key === 'system_code' || f.field_key === 'systemCode')
    const itemCodeField = systemCodeField || fields.find(f => f.field_key === 'item_code' || f.field_key === 'itemCode')
    
    let itemCode = values.system_code || values.systemCode || values.item_code || values.itemCode
    // 如果是聚合欄位，嘗試重新計算
    if (itemCodeField && itemCodeField.field_type === 'aggregated' && itemCodeField.field_config?.template) {
      try {
        const { formDataService: formDataSvc } = await import('../formData.js')
        itemCode = await formDataSvc._calculateAggregatedValue(
          itemCodeField.field_config.template,
          values,
          itemCodeField.field_config.counterKey || itemCodeField.field_key,
        )
      } catch (error) {
        console.warn('重新計算聚合料號失敗，使用原始值', error)
      }
    }
    if (!itemCode || itemCode === '') {
      itemCode = 'N/A'
    }

    // 料件說明可能對應到 materials_desc_cn 或 item_name_cn
    const itemNameCN = values.materials_desc_cn || values.materialsDescCN || values.item_name_cn || values.itemNameCN || 'N/A'
    const itemNameEN = values.item_name_en || values.itemNameEN || 'N/A'

    return {
      id: record.record_id,
      record_id: record.record_id,
      item_code: itemCode,
      item_name_cn: itemNameCN,
      item_name_en: itemNameEN,
      material: values.material || null,
      surface_finish: values.surface_finish || values.surfaceFinish || null,
      dimensions: values.dimensions || null,
      customer_ref: values.customer_ref || values.customerRef || null,
      applicant_id: record.applicant_id,
      applicant_name: record.applicant_username || 'Unknown',
      status: record.current_status_code,
      approval_status: record.current_status_code,
      submit_date: record.submit_date,
      approval_date: record.approval_date,
      reject_date: record.reject_date,
      reject_reason: record.reject_reason,
      is_dynamic_form: true,
      form_id: record.form_id,
      // 審核流程相關資訊
      current_status_code: record.current_status_code,
      current_status_name: record.current_status_name,
      status_color: record.status_color,
      status_icon: record.status_icon,
      current_step_name: record.current_step_name,
      workflow_name: record.workflow_name,
      workflow_id: record.workflow_id,
      current_step_id: record.current_step_id,
      current_step_order: record.current_step_order,
    }
  },

  /**
   * 建立申請
   * @param {Object} formData - 表單資料（包含 code 而非 ID）
   * @returns {Promise<Object>}
   */
  async createApplication (formData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 1. 獲取當前用戶 ID
    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser) {
      throw new Error('用戶未登入')
    }

    // 獲取或創建 user_profile
    let applicantId = authUser.id
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('id', authUser.id)
      .single()

    if (!profile) {
      // 如果沒有 profile，創建一個
      const { error: profileError } = await supabase
        .from('user_profiles')
        .insert({
          id: authUser.id,
          username: authUser.email?.split('@')[0] || authUser.id,
          role: 'applicant',
        })

      if (profileError) {
        console.warn('創建 user_profile 失敗', profileError)
      }
    }

    // 2. 查找分類 ID
    let mainCategoryId = null
    let subCategoryId = null
    let specCategoryId = null

    if (formData.mainCategory) {
      const { data: mainCat } = await supabase
        .from('product_categories')
        .select('id')
        .eq('code', formData.mainCategory)
        .eq('level', 1)
        .single()
      mainCategoryId = mainCat?.id || null
    }

    if (formData.subCategory && formData.mainCategory) {
      const { data: subCat } = await supabase
        .from('product_categories')
        .select('id')
        .eq('code', formData.subCategory)
        .eq('level', 2)
        .eq('main_category_code', formData.mainCategory)
        .single()
      subCategoryId = subCat?.id || null
    }

    if (formData.specCategory && formData.mainCategory) {
      const { data: specCat } = await supabase
        .from('product_categories')
        .select('id')
        .eq('code', formData.specCategory)
        .eq('level', 3)
        .eq('main_category_code', formData.mainCategory)
        .single()
      specCategoryId = specCat?.id || null
    }

    // 3. 查找供應商 ID
    let supplierId = null
    if (formData.supplier) {
      // 如果 supplier 是 code，查找 ID
      if (typeof formData.supplier === 'string' && !/^\d+$/.test(formData.supplier)) {
        const { data: supplier } = await supabase
          .from('suppliers')
          .select('id')
          .eq('code', formData.supplier)
          .single()
        supplierId = supplier?.id || null
      } else {
        supplierId = parseInt(formData.supplier)
      }
    }

    // 4. 準備 applications 表資料
    const applicationRecord = {
      item_code: formData.itemCode,
      main_category_id: mainCategoryId,
      sub_category_id: subCategoryId,
      spec_category_id: specCategoryId,
      item_name_cn: formData.itemNameCN,
      item_name_en: formData.itemNameEN,
      material: formData.material || null,
      surface_finish: formData.surfaceFinish || null,
      dimensions: formData.dimensions || null,
      customer_ref: formData.customerRef || null,
      supplier_id: supplierId,
      applicant_id: applicantId,
      status: 'PENDING',
      approval_status: 'PENDING',
      priority: 'MEDIUM',
    }

    // 5. 插入申請記錄
    const { data: application, error: appError } = await supabase
      .from('applications')
      .insert(applicationRecord)
      .select()
      .single()

    if (appError) {
      throw appError
    }

    // 6. 保存包裝數據到 application_packaging 表
    if (formData.packaging && application.id) {
      const packagingRecords = []

      for (const [categoryCode, section] of Object.entries(formData.packaging)) {
        if (!section.options || section.options.length === 0) {
          continue
        }

        // 獲取包裝類別 ID
        const { data: packagingCategory } = await supabase
          .from('packaging_categories')
          .select('id')
          .eq('code', categoryCode)
          .single()

        if (!packagingCategory) {
          continue
        }

        // 為每個選項創建記錄
        for (const [index, optionCode] of section.options.entries()) {
          // 獲取包裝選項 ID
          const { data: packagingOption } = await supabase
            .from('packaging_options')
            .select('id')
            .eq('code', optionCode)
            .eq('category_id', packagingCategory.id)
            .single()

          if (packagingOption) {
            packagingRecords.push({
              application_id: application.id,
              packaging_category_id: packagingCategory.id,
              packaging_option_id: packagingOption.id,
              description: section.description || null,
              display_order: index,
            })
          }
        }
      }

      // 批量插入包裝記錄
      if (packagingRecords.length > 0) {
        const { error: packagingError } = await supabase
          .from('application_packaging')
          .insert(packagingRecords)

        if (packagingError) {
          console.error('保存包裝數據失敗', packagingError)
          // 不拋出錯誤，因為申請已經創建成功
        }
      }
    }

    return application
  },

  /**
   * 更新申請
   */
  async updateApplication (id, updates) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('applications')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 核准申請（包含審核日誌）
   */
  async approveApplication (id, approvalData = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 獲取當前用戶
    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser) {
      throw new Error('用戶未登入')
    }

    // 獲取審核人資訊
    const { data: approverProfile } = await supabase
      .from('user_profiles')
      .select('id, username, role')
      .eq('id', authUser.id)
      .single()

    // 更新申請狀態
    const updates = {
      status: 'APPROVED',
      approval_status: 'APPROVED',
      approval_date: new Date().toISOString(),
      approver_id: approvalData.approver_id || authUser.id,
      ...approvalData,
    }

    const { data: application, error: updateError } = await supabase
      .from('applications')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (updateError) {
      throw updateError
    }

    // 記錄審核日誌
    if (approverProfile) {
      await supabase
        .from('approval_logs')
        .insert({
          application_id: id,
          action: 'APPROVE',
          approver_id: approverProfile.id,
          approver_name: approverProfile.username || authUser.email,
          approver_role: approverProfile.role,
          comment: approvalData.comment || null,
        })
    }

    return application
  },

  /**
   * 退回申請（包含審核日誌）
   */
  async rejectApplication (id, rejectData = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 獲取當前用戶
    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser) {
      throw new Error('用戶未登入')
    }

    // 獲取審核人資訊
    const { data: approverProfile } = await supabase
      .from('user_profiles')
      .select('id, username, role')
      .eq('id', authUser.id)
      .single()

    // 更新申請狀態
    const updates = {
      status: 'REJECTED',
      approval_status: 'REJECTED',
      reject_date: new Date().toISOString(),
      reject_reason: rejectData.reject_reason || rejectData.reason || '',
      approver_id: rejectData.approver_id || authUser.id,
      ...rejectData,
    }

    const { data: application, error: updateError } = await supabase
      .from('applications')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (updateError) {
      throw updateError
    }

    // 記錄審核日誌
    if (approverProfile) {
      await supabase
        .from('approval_logs')
        .insert({
          application_id: id,
          action: 'REJECT',
          approver_id: approverProfile.id,
          approver_name: approverProfile.username || authUser.email,
          approver_role: approverProfile.role,
          reason: rejectData.reject_reason || rejectData.reason || '',
          comment: rejectData.comment || null,
        })
    }

    return application
  },

  /**
   * 刪除申請
   */
  async deleteApplication (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('applications')
      .delete()
      .eq('id', id)

    if (error) {
      throw error
    }
  },
}

