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
      query = query.gte('submit_date', filters.dateFrom)
    }

    if (filters.dateTo) {
      query = query.lte('submit_date', filters.dateTo)
    }

    if (filters.mainCategory) {
      query = query.eq('main_category_id', filters.mainCategory)
    }

    // 排序
    query = query.order('submit_date', { ascending: false })

    const { data, error } = await query

    if (error) {
      throw error
    }

    // 處理申請人資訊
    return (data || []).map(app => ({
      ...app,
      applicant_name: app.applicant?.username || 'Unknown',
    }))
  },

  /**
   * 取得單一申請
   */
  async getApplication (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
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

    if (error) {
      throw error
    }

    return {
      ...data,
      applicant_name: data.applicant?.username || 'Unknown',
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

