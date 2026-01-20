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
   * 取得申請列表
   */
  async getApplications (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 如果 applicant 是字符串（姓名），先查找匹配的用戶 ID
    let applicantIds = null
    if (filters.applicant && typeof filters.applicant === 'string') {
      const { data: matchingUsers } = await supabase
        .from('user_profiles')
        .select('id')
        .ilike('username', `%${filters.applicant}%`)

      if (matchingUsers && matchingUsers.length > 0) {
        applicantIds = matchingUsers.map(u => u.id)
      } else {
        // 如果沒有找到匹配的用戶，返回空結果
        return []
      }
    }

    // 獲取表單 ID（用於查詢動態表單資料）
    const { data: formData } = await supabase
      .from('forms')
      .select('id, form_code')
      .eq('form_code', 'material_application')
      .single()

    const formId = formData?.id || null

    // 查詢 applications 表中的申請
    let query = supabase
      .from('applications')
      .select(`
        *,
        applicant:user_profiles!applications_applicant_id_fkey (
          id,
          username
        )
      `)

    // 應用篩選條件
    if (filters.status && filters.status !== 'ALL') {
      query = query.eq('status', filters.status)
    }

    if (filters.itemCode) {
      query = query.ilike('item_code', `%${filters.itemCode}%`)
    }

    if (filters.applicant) {
      if (applicantIds) {
        // 使用查詢到的用戶 ID 列表
        query = query.in('applicant_id', applicantIds)
      } else if (typeof filters.applicant !== 'string') {
        // 如果 applicant 是 ID，直接查詢
        query = query.eq('applicant_id', filters.applicant)
      }
    }

    if (filters.dateFrom) {
      // 確保日期格式正確，設置為當天開始時間
      const dateFrom = new Date(filters.dateFrom)
      dateFrom.setHours(0, 0, 0, 0)
      query = query.gte('submit_date', dateFrom.toISOString())
    }

    if (filters.dateTo) {
      // 確保日期格式正確，設置為當天結束時間
      const dateTo = new Date(filters.dateTo)
      dateTo.setHours(23, 59, 59, 999)
      query = query.lte('submit_date', dateTo.toISOString())
    }

    if (filters.mainCategory) {
      query = query.eq('main_category_id', filters.mainCategory)
    }

    // 排序
    query = query.order('submit_date', { ascending: false })

    const { data: applicationsData, error } = await query

    if (error) {
      throw error
    }

    // 查詢動態表單申請（form_data_values 中有資料但 applications 表中可能沒有記錄的）
    let dynamicFormApplications = []
    if (formId) {
      // 查詢所有待審核的動態表單資料
      const { data: formValuesData } = await supabase
        .from('form_data_values')
        .select('record_id, created_by_id, created_at')
        .eq('form_id', formId)
        .order('created_at', { ascending: false })

      if (formValuesData && formValuesData.length > 0) {
        // 獲取所有唯一的 record_id
        const recordIds = [...new Set(formValuesData.map(fv => fv.record_id))]

        // 檢查哪些 record_id 在 applications 表中不存在
        const existingRecordIds = new Set((applicationsData || []).map(app => app.id))
        const missingRecordIds = recordIds.filter(rid => !existingRecordIds.has(rid))

        // 對於缺失的記錄，嘗試從 form_data_values 提取資料創建臨時申請記錄
        for (const recordId of missingRecordIds) {
          // 檢查是否為臨時 ID（時間戳格式）
          const isTempId = typeof recordId === 'number' && recordId > 1000000000000

          if (isTempId) {
            // 這是臨時 ID，需要創建 applications 記錄
            // 提取關鍵欄位值
            const { data: itemCodeData } = await supabase
              .from('form_data_values')
              .select('field_value')
              .eq('form_id', formId)
              .eq('record_id', recordId)
              .eq('field_key', 'item_code')
              .single()

            const { data: itemNameCNData } = await supabase
              .from('form_data_values')
              .select('field_value')
              .eq('form_id', formId)
              .eq('record_id', recordId)
              .eq('field_key', 'item_name_cn')
              .single()

            const { data: itemNameENData } = await supabase
              .from('form_data_values')
              .select('field_value')
              .eq('form_id', formId)
              .eq('record_id', recordId)
              .eq('field_key', 'item_name_en')
              .single()

            const itemCode = itemCodeData?.field_value || `TEMP-${recordId}`
            const itemNameCN = itemNameCNData?.field_value || '未命名物料'
            const itemNameEN = itemNameENData?.field_value || 'Unnamed Material'

            // 獲取申請人 ID
            const formValueRecord = formValuesData.find(fv => fv.record_id === recordId)
            const applicantId = formValueRecord?.created_by_id

            // 創建 applications 記錄
            const { data: newApplication, error: createError } = await supabase
              .from('applications')
              .insert({
                item_code: itemCode,
                item_name_cn: itemNameCN,
                item_name_en: itemNameEN,
                applicant_id: applicantId,
                status: 'PENDING',
                approval_status: 'PENDING',
                submit_date: formValueRecord?.created_at || new Date().toISOString(),
              })
              .select(`
                *,
                applicant:user_profiles!applications_applicant_id_fkey (
                  id,
                  username
                )
              `)
              .single()

            if (!createError && newApplication) {
              // 更新 form_data_values 中的 record_id
              await supabase
                .from('form_data_values')
                .update({ record_id: newApplication.id })
                .eq('form_id', formId)
                .eq('record_id', recordId)

              // 添加到結果中
              dynamicFormApplications.push(newApplication)
            }
          }
        }
      }

      // 批量查詢動態表單標記（一次性查詢所有申請的 form_data_values）
      const allApplicationIds = [
        ...(applicationsData || []).map(app => app.id),
        ...dynamicFormApplications.map(app => app.id),
      ]

      let dynamicFormRecordIds = new Set()
      if (allApplicationIds.length > 0) {
        const { data: formValues } = await supabase
          .from('form_data_values')
          .select('record_id')
          .eq('form_id', formId)
          .in('record_id', allApplicationIds)

        if (formValues) {
          dynamicFormRecordIds = new Set(formValues.map(fv => fv.record_id))
        }
      }
    }

    // 合併 applications 表中的申請和動態表單申請
    const allApplications = [...(applicationsData || []), ...dynamicFormApplications]

    // 處理申請人資訊和動態表單標記
    return allApplications.map(app => ({
      ...app,
      applicant_name: app.applicant?.username || 'Unknown',
      is_dynamic_form: formId ? (dynamicFormRecordIds?.has(app.id) || false) : false,
      form_id: formId,
    }))
  },

  /**
   * 取得單一申請
   */
  async getApplication (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 先從 applications 表查詢
    const { data: appData, error: appError } = await supabase
      .from('applications')
      .select(`
        *,
        applicant:user_profiles!applications_applicant_id_fkey (
          id,
          username
        )
      `)
      .eq('id', id)
      .single()

    if (appError) {
      throw appError
    }

    // 檢查是否為動態表單申請
    const { data: formData } = await supabase
      .from('forms')
      .select('id, form_code')
      .eq('form_code', 'material_application')
      .single()

    let isDynamicForm = false
    let formId = null

    if (formData) {
      formId = formData.id
      // 檢查是否有對應的 form_data_values
      const { data: formValues } = await supabase
        .from('form_data_values')
        .select('id')
        .eq('form_id', formId)
        .eq('record_id', id)
        .limit(1)

      isDynamicForm = formValues && formValues.length > 0
    }

    return {
      ...appData,
      applicant_name: appData.applicant?.username || 'Unknown',
      is_dynamic_form: isDynamicForm,
      form_id: formId,
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

