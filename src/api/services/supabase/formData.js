/**
 * Form Data API Service - Supabase Implementation
 * 表單資料管理 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
import { codeCountersService } from '../codeCounters.js'

export default {
  /**
   * 取得表單資料（單一記錄的所有欄位值）
   */
  async getFormData (formId, recordId, options = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得表單 ID
    const formIdValue = await this._getFormId(formId)

    // 取得欄位定義
    const { data: fields } = await supabase
      .from('form_fields')
      .select('*')
      .eq('form_id', formIdValue)
      .order('display_order', { ascending: true })

    if (!fields || fields.length === 0) {
      return {
        form_id: formIdValue,
        record_id: recordId,
        values: {},
        fields: options.includeFieldDefinitions ? fields : undefined,
      }
    }

    // 取得所有欄位值
    const fieldIds = fields.map(f => f.id)
    const { data: values, error } = await supabase
      .from('form_data_values')
      .select('*')
      .eq('form_id', formIdValue)
      .eq('record_id', recordId)
      .in('field_id', fieldIds)

    if (error) {
      throw error
    }

    // 將值轉換為 key-value 格式
    const valuesMap = {}
    for (const value of values || []) {
      const field = fields.find(f => f.id === value.field_id)
      if (field) {
        // 優先使用資料庫中的 field_key（對於 cascading select 的層級值）
        // 如果資料庫中沒有 field_key，則使用欄位定義的 field_key
        const key = value.field_key || field.field_key
        valuesMap[key] = this._convertValueFromDb(value, field)
      }
    }

    return {
      form_id: formIdValue,
      record_id: recordId,
      values: valuesMap,
      fields: options.includeFieldDefinitions ? fields : undefined,
    }
  },

  /**
   * 取得表單資料列表（多筆記錄）
   */
  async getFormDataList (formId, filters = {}, options = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得表單 ID
    const formIdValue = await this._getFormId(formId)

    // 取得所有記錄 ID
    let query = supabase
      .from('form_data_values')
      .select('record_id')
      .eq('form_id', formIdValue)

    // 應用篩選條件
    if (filters.record_id) {
      query = query.eq('record_id', filters.record_id)
    }

    if (filters.field_key && filters.field_value) {
      // 根據特定欄位值篩選
      const { data: field } = await supabase
        .from('form_fields')
        .select('id')
        .eq('form_id', formIdValue)
        .eq('field_key', filters.field_key)
        .single()

      if (field) {
        query = query.eq('field_id', field.id)
        // 根據欄位類型查詢對應的值欄位
        // 這裡簡化處理，實際可能需要更複雜的查詢邏輯
      }
    }

    const { data: records, error } = await query

    if (error) {
      throw error
    }

    // 取得唯一的記錄 ID
    const recordIds = [...new Set((records || []).map(r => r.record_id))]

    // 取得每筆記錄的完整資料
    const results = []
    for (const recordId of recordIds) {
      const formData = await this.getFormData(formId, recordId, options)
      results.push(formData)
    }

    return results
  },

  /**
   * 取得待審核的表單資料列表（從 form_data_values 讀取）
   * @param {number|string} formId - 表單 ID 或 form_code
   * @param {object} filters - 篩選條件（status 等）
   * @returns {Promise<Array>} 返回格式化的申請列表
   */
  async getPendingFormDataList (formId, filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得表單 ID（如果 formId 是 null 或 undefined，查詢所有表單的資料）
    let formIdValue = null
    if (formId) {
      try {
        formIdValue = await this._getFormId(formId)
      } catch (error) {
        // 如果無法取得表單 ID，查詢所有表單的資料
        console.warn('無法取得表單 ID，查詢所有表單的資料', error)
        formIdValue = null
      }
    }

    // 取得所有唯一的 record_id（包含 form_id 以便後續處理）
    let query = supabase
      .from('form_data_values')
      .select('record_id, created_by_id, created_at, form_id')
      .order('created_at', { ascending: false })

    // 如果指定了表單 ID，則過濾
    if (formIdValue) {
      query = query.eq('form_id', formIdValue)
    }

    const { data: recordData, error: recordError } = await query

    if (recordError) {
      throw recordError
    }

    if (!recordData || recordData.length === 0) {
      return []
    }

    // 取得唯一的 record_id 和 form_id 組合
    const recordFormMap = new Map()
    for (const record of recordData || []) {
      const key = `${record.form_id}_${record.record_id}`
      if (!recordFormMap.has(key)) {
        recordFormMap.set(key, {
          record_id: record.record_id,
          form_id: record.form_id,
          created_by_id: record.created_by_id,
          created_at: record.created_at,
        })
      }
    }

    // 取得所有相關的表單 ID
    const formIds = [...new Set(Array.from(recordFormMap.values()).map(r => r.form_id).filter(Boolean))]

    if (formIds.length === 0) {
      return []
    }

    // 取得所有相關表單的欄位定義
    const { data: allFields } = await supabase
      .from('form_fields')
      .select('*')
      .in('form_id', formIds)

    if (!allFields || allFields.length === 0) {
      return []
    }

    // 按 form_id 分組欄位
    const fieldsByFormId = new Map()
    for (const field of allFields) {
      if (!fieldsByFormId.has(field.form_id)) {
        fieldsByFormId.set(field.form_id, [])
      }
      fieldsByFormId.get(field.form_id).push(field)
    }

    // 取得所有記錄 ID
    const recordIds = [...new Set(Array.from(recordFormMap.values()).map(r => r.record_id))]

    // 批量查詢所有記錄的欄位值
    let valuesQuery = supabase
      .from('form_data_values')
      .select('*')
      .in('form_id', formIds)
      .in('record_id', recordIds)

    const { data: allValues, error: valuesError } = await valuesQuery

    if (valuesError) {
      throw valuesError
    }

    // 按 form_id + record_id 分組資料
    const recordsMap = new Map()
    for (const value of allValues || []) {
      const key = `${value.form_id}_${value.record_id}`
      if (!recordsMap.has(key)) {
        const recordInfo = recordFormMap.get(key) || {
          record_id: value.record_id,
          form_id: value.form_id,
          created_by_id: value.created_by_id,
          created_at: value.created_at,
        }
        recordsMap.set(key, {
          record_id: value.record_id,
          form_id: value.form_id,
          created_by_id: recordInfo.created_by_id,
          created_at: recordInfo.created_at,
          values: {},
        })
      }

      const fields = fieldsByFormId.get(value.form_id) || []
      const field = fields.find(f => f.id === value.field_id)
      if (field) {
        // 優先使用資料庫中的 field_key（對於 cascading select 的層級值）
        // 如果資料庫中沒有 field_key，則使用欄位定義的 field_key
        const fieldKey = value.field_key || field.field_key
        const record = recordsMap.get(key)
        if (record) {
          record.values[fieldKey] = this._convertValueFromDb(value, field)
        }
      }
    }

    // 批量獲取申請人資訊（提升效能）
    const applicantIds = [...new Set(Array.from(recordsMap.values()).map(r => r.created_by_id).filter(Boolean))]
    const applicantMap = new Map()

    if (applicantIds.length > 0) {
      const { data: applicants } = await supabase
        .from('user_profiles')
        .select('id, username')
        .in('id', applicantIds)

      if (applicants) {
        for (const applicant of applicants) {
          applicantMap.set(applicant.id, applicant.username)
        }
      }
    }

    // 轉換為申請列表格式
    const results = []
    for (const [key, record] of recordsMap.entries()) {
      const values = record.values
      const recordId = record.record_id
      const recordFormId = record.form_id

      // 獲取該記錄的表單欄位定義
      const fields = fieldsByFormId.get(recordFormId) || []
      
      // 查找 system_code 欄位（料號對應到 system_code）
      let itemCode = values.system_code || values.systemCode
      
      // 如果沒有找到 system_code，嘗試查找 item_code（向後兼容）
      if (!itemCode || itemCode === '') {
        itemCode = values.item_code || values.itemCode
      }
      
      // 查找 system_code 欄位定義（優先）或 item_code 欄位定義（向後兼容）
      const systemCodeField = fields.find(f => f.field_key === 'system_code' || f.field_key === 'systemCode')
      const itemCodeField = systemCodeField || fields.find(f => f.field_key === 'item_code' || f.field_key === 'itemCode')
      
      // 如果欄位是聚合資料類型，重新計算
      if (itemCodeField && itemCodeField.field_type === 'aggregated' && itemCodeField.field_config?.template) {
        try {
          // 重新計算聚合值
          itemCode = await this._calculateAggregatedValue(
            itemCodeField.field_config.template,
            values,
            itemCodeField.field_config.counterKey || itemCodeField.field_key
          )
        } catch (error) {
          console.warn('重新計算聚合料號失敗，使用原始值', error)
          // 如果計算失敗，使用原始值
        }
      }
      
      // 如果還是沒有值，使用預設值
      if (!itemCode || itemCode === '') {
        itemCode = `TEMP-${recordId}`
      }

      // 料件說明對應到 materials_desc_cn
      const itemNameCN = values.materials_desc_cn || values.materialsDescCN || values.item_name_cn || values.itemNameCN || '未命名物料'
      const itemNameEN = values.item_name_en || values.itemNameEN || 'Unnamed Material'
      const status = values.status || 'PENDING'
      const approvalStatus = values.approval_status || values.approvalStatus || 'PENDING'

      // 如果篩選狀態，檢查是否符合
      if (filters.status && filters.status !== 'ALL' && status !== filters.status) {
        continue
      }

      // 獲取申請人資訊（從批量查詢的結果中獲取）
      const applicantName = record.created_by_id && applicantMap.has(record.created_by_id)
        ? applicantMap.get(record.created_by_id)
        : 'Unknown'

      // 構建申請記錄
      const application = {
        id: recordId,
        record_id: recordId,
        item_code: itemCode,
        item_name_cn: itemNameCN,
        item_name_en: itemNameEN,
        material: values.material || null,
        surface_finish: values.surface_finish || values.surfaceFinish || null,
        dimensions: values.dimensions || null,
        customer_ref: values.customer_ref || values.customerRef || null,
        status: status,
        approval_status: approvalStatus,
        submit_date: record.created_at || new Date().toISOString(),
        applicant_id: record.created_by_id,
        applicant_name: applicantName,
        applicant: {
          id: record.created_by_id,
          username: applicantName,
        },
        is_dynamic_form: true,
        form_id: recordFormId,
        // 保存完整的表單值以便後續使用
        _form_values: values,
      }

      results.push(application)
    }

    // 按提交日期排序
    results.sort((a, b) => {
      const dateA = new Date(a.submit_date || a.created_at || 0)
      const dateB = new Date(b.submit_date || b.created_at || 0)
      return dateB - dateA
    })

    return results
  },

  /**
   * 儲存表單資料（建立或更新）
   */
  async saveFormData (formId, recordId, formValues, options = {}) {
    if (recordId) {
      return this.updateFormData(formId, recordId, formValues, options)
    } else {
      return this.createFormData(formId, formValues, options)
    }
  },

  /**
   * 建立表單資料
   */
  async createFormData (formId, formValues, options = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得表單 ID
    const formIdValue = await this._getFormId(formId)

    // 取得當前用戶
    const { data: { user } } = await supabase.auth.getUser()
    const userId = user?.id

    // 取得欄位定義（無論是否為 material_application，都需要處理聚合資料欄位）
    const { data: fields } = await supabase
      .from('form_fields')
      .select('*')
      .eq('form_id', formIdValue)

    if (!fields || fields.length === 0) {
      throw new Error('表單沒有定義欄位')
    }

    // 如果選項中指定了要建立記錄，先建立記錄
    let newRecordId = options.recordId
    if (options.createRecord && !newRecordId) {
      // 檢查表單是否為 material_application 類型
      const { data: form, error: formError } = await supabase
        .from('forms')
        .select('form_code')
        .eq('id', formIdValue)
        .maybeSingle()

      if (formError && formError.code !== 'PGRST116') {
        console.error('查詢表單失敗:', formError)
        throw formError
      }

      // 如果是 material_application 表單，在 applications 表中創建記錄
      if (form && form.form_code === 'material_application') {
        // 先創建一個臨時的 record_id（使用時間戳）
        const tempRecordId = Date.now()

        // 先保存表單資料到 form_data_values（使用臨時 record_id）
        const valuesToInsert = []
        const processedFieldKeys = new Set() // 追蹤已處理的欄位鍵值

        // 首先處理聚合資料欄位（需要先遞增計數器）
        // 這樣可以確保計數器在保存其他資料之前就被更新
        for (const field of fields) {
          if (field.field_type === 'aggregated' && field.field_config?.template) {
            const fieldKey = field.field_key
            if (processedFieldKeys.has(fieldKey)) {
              continue
            }

            try {
              
              // 生成計數器 key（與 AggregatedField.vue 中的邏輯相同）
              let counterKey = field.field_config.counterKey
              if (!counterKey) {
                // 如果沒有配置 counterKey，嘗試從模板中的其他欄位值構建
                const templateStr = field.field_config.template
                const fieldKeyMatches = Array.from(templateStr.matchAll(/\{#(\w+)\}/g))
                const fieldKeys = fieldKeyMatches.map(m => m[1])
                
                if (fieldKeys.length > 0) {
                  const keyParts = []
                  for (const fKey of fieldKeys) {
                    const fValue = formValues[fKey]
                    // 提取值（與 _calculateAggregatedValue 中的 extractValue 相同邏輯）
                    const extractedValue = this._extractValueForCounter(fValue)
                    if (extractedValue) {
                      keyParts.push(extractedValue)
                    }
                  }
                  
                  if (keyParts.length === fieldKeys.length && keyParts.length >= 2) {
                    const prefix = keyParts.slice(0, 2).join('')
                    const suffix = keyParts.slice(2).join('.')
                    counterKey = suffix ? `${prefix}.${suffix}` : prefix
                  } else if (keyParts.length === 1) {
                    counterKey = `${keyParts[0]}.${field.field_key}`
                  }
                }
                
                if (!counterKey) {
                  counterKey = field.field_key || 'default'
                }
              }
              
              // 遞增計數器（這會返回新的計數器值）
              const newCounterValue = await codeCountersService.getAndIncrementCounter(counterKey)
              
              // 重新計算聚合值（使用新的計數器值）
              const aggregatedValue = await this._calculateAggregatedValueWithCounter(
                field.field_config.template,
                formValues,
                counterKey,
                newCounterValue
              )
              
              // 保存計算後的聚合值
              const dbValue = this._convertValueToDb(aggregatedValue, field)
              valuesToInsert.push({
                form_id: formIdValue,
                field_id: field.id,
                record_id: tempRecordId,
                field_key: fieldKey,
                created_by_id: userId,
                ...dbValue,
              })
              processedFieldKeys.add(fieldKey)
            } catch (error) {
              console.error('處理聚合資料欄位失敗', {
                fieldKey,
                fieldType: field.field_type,
                hasTemplate: !!field.field_config?.template,
                template: field.field_config?.template,
                error: error.message,
                stack: error.stack,
              })
              // 如果處理失敗，拋出錯誤而不是靜默失敗
              throw new Error(`處理聚合資料欄位失敗 (${fieldKey}): ${error.message}`)
            }
          }
        }

        // 然後處理其他欄位（包括 cascading_select）
        for (const [fieldKey, value] of Object.entries(formValues)) {
          // 跳過已經處理過的欄位（可能是聚合資料欄位或 cascading select 的層級欄位）
          if (processedFieldKeys.has(fieldKey)) {
            continue
          }

          const field = fields.find(f => f.field_key === fieldKey)
          if (!field) {
            continue // 跳過不存在的欄位
          }

          // 如果是 cascading_select 欄位，只為每個層級分別保存值（不保存主欄位的陣列值）
          if (field.field_type === 'cascading_select' && field.field_config?.levels) {
            // 為每個層級分別保存值
            const levels = field.field_config.levels
            if (Array.isArray(value)) {
              for (let levelIndex = 0; levelIndex < levels.length; levelIndex++) {
                const level = levels[levelIndex]
                if (!level || !level.field_key) {
                  continue
                }

                const levelValue = value[levelIndex]
                if (levelValue === null || levelValue === undefined || levelValue === '') {
                  continue // 跳過空值
                }

                // 查找層級對應的欄位定義
                const levelField = fields.find(f => f.field_key === level.field_key)
                if (levelField) {
                  // 如果存在對應的欄位定義，使用該欄位的配置保存
                  const levelDbValue = this._convertValueToDb(levelValue, levelField)
                  valuesToInsert.push({
                    form_id: formIdValue,
                    field_id: levelField.id,
                    record_id: tempRecordId,
                    field_key: level.field_key,
                    created_by_id: userId,
                    ...levelDbValue,
                  })
                  processedFieldKeys.add(level.field_key)
                } else {
                  // 如果層級欄位不存在，使用主欄位的 field_id，但使用層級的 field_key
                  // 注意：這會導致同一個 field_id 有多個記錄，但 field_key 不同
                  const levelDbValue = this._convertValueToDb(levelValue, field)
                  valuesToInsert.push({
                    form_id: formIdValue,
                    field_id: field.id, // 使用主欄位的 field_id
                    record_id: tempRecordId,
                    field_key: level.field_key, // 使用層級的 field_key
                    created_by_id: userId,
                    ...levelDbValue,
                  })
                  processedFieldKeys.add(level.field_key)
                }
              }
            } else {
              // 如果值不是陣列，嘗試從 formValues 中讀取層級的值
              for (const level of levels) {
                if (!level || !level.field_key) {
                  continue
                }

                const levelValue = formValues[level.field_key]
                if (levelValue === null || levelValue === undefined || levelValue === '') {
                  continue // 跳過空值
                }

                // 查找層級對應的欄位定義
                const levelField = fields.find(f => f.field_key === level.field_key)
                if (levelField) {
                  const levelDbValue = this._convertValueToDb(levelValue, levelField)
                  valuesToInsert.push({
                    form_id: formIdValue,
                    field_id: levelField.id,
                    record_id: tempRecordId,
                    field_key: level.field_key,
                    created_by_id: userId,
                    ...levelDbValue,
                  })
                  processedFieldKeys.add(level.field_key)
                } else {
                  // 如果層級欄位不存在，使用主欄位的 field_id，但使用層級的 field_key
                  const levelDbValue = this._convertValueToDb(levelValue, field)
                  valuesToInsert.push({
                    form_id: formIdValue,
                    field_id: field.id, // 使用主欄位的 field_id
                    record_id: tempRecordId,
                    field_key: level.field_key, // 使用層級的 field_key
                    created_by_id: userId,
                    ...levelDbValue,
                  })
                  processedFieldKeys.add(level.field_key)
                }
              }
            }
            // 標記主欄位已處理（不保存主欄位的陣列值，避免重複）
            processedFieldKeys.add(fieldKey)
          } else {
            // 對於非 cascading_select 和非 aggregated 欄位，正常保存
            const dbValue = this._convertValueToDb(value, field)
            valuesToInsert.push({
              form_id: formIdValue,
              field_id: field.id,
              record_id: tempRecordId,
              field_key: fieldKey,
              created_by_id: userId,
              ...dbValue,
            })
            processedFieldKeys.add(fieldKey)
          }
        }

        // 批量插入（使用 upsert 以避免重複）
        if (valuesToInsert.length > 0) {
          const { error } = await supabase
            .from('form_data_values')
            .upsert(valuesToInsert)

          if (error) {
            throw error
          }
        }

        // 調用 SQL 函數創建 applications 記錄
        // 這會從 form_data_values 提取資料並創建 applications 記錄
        // 同時會更新 form_data_values 中的 record_id 為新的 application id
        const { data: applicationId, error: funcError } = await supabase
          .rpc('create_application_from_form_data', {
            p_form_id: formIdValue,
            p_record_id: tempRecordId,
            p_applicant_id: userId,
          })

        if (funcError) {
          // 如果函數不存在或執行失敗，嘗試手動創建 applications 記錄
          console.warn('無法調用 create_application_from_form_data 函數，嘗試手動創建', funcError)

          // 提取關鍵欄位值
          const itemCode = formValues.item_code || formValues.itemCode || `TEMP-${tempRecordId}`
          const itemNameCN = formValues.item_name_cn || formValues.itemNameCN || '未命名物料'
          const itemNameEN = formValues.item_name_en || formValues.itemNameEN || 'Unnamed Material'
          const material = formValues.material || null
          const surfaceFinish = formValues.surface_finish || formValues.surfaceFinish || null
          const dimensions = formValues.dimensions || null
          const customerRef = formValues.customer_ref || formValues.customerRef || null

          // 創建 applications 記錄
          const { data: application, error: appError } = await supabase
            .from('applications')
            .insert({
              item_code: itemCode,
              item_name_cn: itemNameCN,
              item_name_en: itemNameEN,
              material: material,
              surface_finish: surfaceFinish,
              dimensions: dimensions,
              customer_ref: customerRef,
              applicant_id: userId,
              status: 'PENDING',
              approval_status: 'PENDING',
              submit_date: new Date().toISOString(),
            })
            .select()
            .single()

          if (appError) {
            throw new Error(`創建 applications 記錄失敗: ${appError.message}`)
          }

          newRecordId = application.id

          // 更新 form_data_values 中的 record_id
          const { error: updateError } = await supabase
            .from('form_data_values')
            .update({ record_id: newRecordId })
            .eq('form_id', formIdValue)
            .eq('record_id', tempRecordId)

          if (updateError) {
            console.error('更新 form_data_values record_id 失敗', updateError)
          }
        } else {
          newRecordId = applicationId
        }
      } else {
        // 如果不是 material_application 表單，使用時間戳作為臨時 ID
        newRecordId = Date.now()
      }
    }

    if (!newRecordId) {
      throw new Error('建立表單資料需要提供 recordId 或設定 createRecord 選項')
    }

    // 如果已經在上面的邏輯中保存了資料，直接返回
    if (options.createRecord) {
      const { data: form } = await supabase
        .from('forms')
        .select('form_code')
        .eq('id', formIdValue)
        .single()

      if (form && form.form_code === 'material_application') {
        // 已經在上面的邏輯中保存了資料，直接返回
        return this.getFormData(formId, newRecordId, options)
      }
    }

    // 準備要插入的資料
    const valuesToInsert = []
    const processedFieldKeys = new Set() // 追蹤已處理的欄位鍵值

    // 首先處理聚合資料欄位（需要先遞增計數器）
    // 這樣可以確保計數器在保存其他資料之前就被更新
    for (const field of fields) {
      if (field.field_type === 'aggregated' && field.field_config?.template) {
        const fieldKey = field.field_key
        if (processedFieldKeys.has(fieldKey)) {
          continue
        }

        try {
          
          // 生成計數器 key（與 AggregatedField.vue 中的邏輯相同）
          let counterKey = field.field_config.counterKey
          if (!counterKey) {
            // 如果沒有配置 counterKey，嘗試從模板中的其他欄位值構建
            const templateStr = field.field_config.template
            const fieldKeyMatches = Array.from(templateStr.matchAll(/\{#(\w+)\}/g))
            const fieldKeys = fieldKeyMatches.map(m => m[1])
            
            if (fieldKeys.length > 0) {
              const keyParts = []
              for (const fKey of fieldKeys) {
                const fValue = formValues[fKey]
                // 提取值（與 _calculateAggregatedValue 中的 extractValue 相同邏輯）
                const extractedValue = this._extractValueForCounter(fValue)
                if (extractedValue) {
                  keyParts.push(extractedValue)
                }
              }
              
              if (keyParts.length === fieldKeys.length && keyParts.length >= 2) {
                const prefix = keyParts.slice(0, 2).join('')
                const suffix = keyParts.slice(2).join('.')
                counterKey = suffix ? `${prefix}.${suffix}` : prefix
              } else if (keyParts.length === 1) {
                counterKey = `${keyParts[0]}.${field.field_key}`
              }
            }
            
            if (!counterKey) {
              counterKey = field.field_key || 'default'
            }
          }
          
          // 遞增計數器（這會返回新的計數器值）
          const newCounterValue = await codeCountersService.getAndIncrementCounter(counterKey)
          
          // 重新計算聚合值（使用新的計數器值）
          const aggregatedValue = await this._calculateAggregatedValueWithCounter(
            field.field_config.template,
            formValues,
            counterKey,
            newCounterValue
          )
          
          // 保存計算後的聚合值
          const dbValue = this._convertValueToDb(aggregatedValue, field)
          valuesToInsert.push({
            form_id: formIdValue,
            field_id: field.id,
            record_id: newRecordId,
            field_key: fieldKey,
            created_by_id: userId,
            ...dbValue,
          })
          processedFieldKeys.add(fieldKey)
        } catch (error) {
          console.error('處理聚合資料欄位失敗', {
            fieldKey,
            fieldType: field.field_type,
            hasTemplate: !!field.field_config?.template,
            template: field.field_config?.template,
            error: error.message,
            stack: error.stack,
          })
          // 如果處理失敗，拋出錯誤而不是靜默失敗
          throw new Error(`處理聚合資料欄位失敗 (${fieldKey}): ${error.message}`)
        }
      }
    }

    // 然後處理其他欄位（包括 cascading_select）
    for (const [fieldKey, value] of Object.entries(formValues)) {
      // 跳過已經處理過的欄位（可能是 cascading select 的層級欄位）
      if (processedFieldKeys.has(fieldKey)) {
        continue
      }

      const field = fields.find(f => f.field_key === fieldKey)
      if (!field) {
        continue // 跳過不存在的欄位
      }

      // 如果是 cascading_select 欄位，只為每個層級分別保存值（不保存主欄位的陣列值）
      if (field.field_type === 'cascading_select' && field.field_config?.levels) {
        // 為每個層級分別保存值
        const levels = field.field_config.levels
        if (Array.isArray(value)) {
          for (let levelIndex = 0; levelIndex < levels.length; levelIndex++) {
            const level = levels[levelIndex]
            if (!level || !level.field_key) {
              continue
            }

            const levelValue = value[levelIndex]
            if (levelValue === null || levelValue === undefined || levelValue === '') {
              continue // 跳過空值
            }

            // 查找層級對應的欄位定義（必須存在，否則跳過）
            const levelField = fields.find(f => f.field_key === level.field_key)
            if (levelField) {
              const levelDbValue = this._convertValueToDb(levelValue, levelField)
              valuesToInsert.push({
                form_id: formIdValue,
                field_id: levelField.id,
                record_id: newRecordId,
                field_key: level.field_key,
                created_by_id: userId,
                ...levelDbValue,
              })
              processedFieldKeys.add(level.field_key)
            } else {
              // 如果層級欄位不存在，使用主欄位的 field_id，但使用層級的 field_key
              // 注意：這需要資料庫的唯一約束包含 field_key
              const levelDbValue = this._convertValueToDb(levelValue, field)
              valuesToInsert.push({
                form_id: formIdValue,
                field_id: field.id, // 使用主欄位的 field_id
                record_id: newRecordId,
                field_key: level.field_key, // 使用層級的 field_key
                created_by_id: userId,
                ...levelDbValue,
              })
              processedFieldKeys.add(level.field_key)
            }
          }
        } else {
          // 如果值不是陣列，嘗試從 formValues 中讀取層級的值
          for (const level of levels) {
            if (!level || !level.field_key) {
              continue
            }

            const levelValue = formValues[level.field_key]
            if (levelValue === null || levelValue === undefined || levelValue === '') {
              continue // 跳過空值
            }

            // 查找層級對應的欄位定義（必須存在，否則跳過）
            const levelField = fields.find(f => f.field_key === level.field_key)
            if (levelField) {
              const levelDbValue = this._convertValueToDb(levelValue, levelField)
              valuesToInsert.push({
                form_id: formIdValue,
                field_id: levelField.id,
                record_id: newRecordId,
                field_key: level.field_key,
                created_by_id: userId,
                ...levelDbValue,
              })
              processedFieldKeys.add(level.field_key)
            } else {
              // 如果層級欄位不存在，使用主欄位的 field_id，但使用層級的 field_key
              // 注意：這需要資料庫的唯一約束包含 field_key
              const levelDbValue = this._convertValueToDb(levelValue, field)
              valuesToInsert.push({
                form_id: formIdValue,
                field_id: field.id, // 使用主欄位的 field_id
                record_id: newRecordId,
                field_key: level.field_key, // 使用層級的 field_key
                created_by_id: userId,
                ...levelDbValue,
              })
              processedFieldKeys.add(level.field_key)
            }
          }
        }
        // 標記主欄位已處理（雖然不保存，但避免重複處理）
        processedFieldKeys.add(fieldKey)
      } else {
        // 對於非 cascading_select 欄位，正常保存
        const dbValue = this._convertValueToDb(value, field)
        valuesToInsert.push({
          form_id: formIdValue,
          field_id: field.id,
          record_id: newRecordId,
          field_key: fieldKey,
          created_by_id: userId,
          ...dbValue,
        })
        processedFieldKeys.add(fieldKey)
      }
    }

    // 批量插入（使用 upsert 以避免重複）
    if (valuesToInsert.length > 0) {
      const { error } = await supabase
        .from('form_data_values')
        .upsert(valuesToInsert)

      if (error) {
        throw error
      }
    }

    // 嘗試創建審核記錄（如果審核流程系統可用）
    if (options.createRecord && userId && newRecordId) {
      try {
        // 動態導入審核流程服務（避免循環依賴）
        const { approvalWorkflowsService } = await import('../approvalWorkflows.js')
        
        // 檢查是否已存在審核記錄
        const existingRecord = await approvalWorkflowsService.getApprovalRecord(formIdValue, newRecordId)
        
        if (!existingRecord) {
          // 創建審核記錄
          await approvalWorkflowsService.createApprovalRecord({
            form_id: formIdValue,
            record_id: newRecordId,
            applicant_id: userId,
          })
        }
      } catch (approvalError) {
        // 如果創建審核記錄失敗，記錄錯誤但不影響表單資料的創建
        console.warn('創建審核記錄失敗（不影響表單資料創建）', approvalError)
      }
    }

    // 返回建立的資料
    return this.getFormData(formId, newRecordId, options)
  },

  /**
   * 更新表單資料
   */
  async updateFormData (formId, recordId, formValues, options = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得表單 ID
    const formIdValue = await this._getFormId(formId)

    // 取得欄位定義
    const { data: fields } = await supabase
      .from('form_fields')
      .select('*')
      .eq('form_id', formIdValue)

    if (!fields || fields.length === 0) {
      throw new Error('表單沒有定義欄位')
    }

    // 準備要更新的資料
    const valuesToUpsert = []
    const processedFieldKeys = new Set() // 追蹤已處理的欄位鍵值

    for (const [fieldKey, value] of Object.entries(formValues)) {
      // 跳過已經處理過的欄位（可能是 cascading select 的層級欄位）
      if (processedFieldKeys.has(fieldKey)) {
        continue
      }

      const field = fields.find(f => f.field_key === fieldKey)
      if (!field) {
        continue // 跳過不存在的欄位
      }

      // 如果是 cascading_select 欄位，只為每個層級分別保存值（不保存主欄位的陣列值）
      if (field.field_type === 'cascading_select' && field.field_config?.levels) {
        // 為每個層級分別保存值
        const levels = field.field_config.levels
        if (Array.isArray(value)) {
          for (let levelIndex = 0; levelIndex < levels.length; levelIndex++) {
            const level = levels[levelIndex]
            if (!level || !level.field_key) {
              continue
            }

            const levelValue = value[levelIndex]
            if (levelValue === null || levelValue === undefined || levelValue === '') {
              continue // 跳過空值
            }

            // 查找層級對應的欄位定義（必須存在，否則跳過）
            const levelField = fields.find(f => f.field_key === level.field_key)
            if (levelField) {
              const levelDbValue = this._convertValueToDb(levelValue, levelField)
              valuesToUpsert.push({
                form_id: formIdValue,
                field_id: levelField.id,
                record_id: recordId,
                field_key: level.field_key,
                ...levelDbValue,
              })
              processedFieldKeys.add(level.field_key)
            } else {
              // 如果層級欄位不存在，使用主欄位的 field_id，但使用層級的 field_key
              // 注意：這需要資料庫的唯一約束包含 field_key
              const levelDbValue = this._convertValueToDb(levelValue, field)
              valuesToUpsert.push({
                form_id: formIdValue,
                field_id: field.id, // 使用主欄位的 field_id
                record_id: recordId,
                field_key: level.field_key, // 使用層級的 field_key
                ...levelDbValue,
              })
              processedFieldKeys.add(level.field_key)
            }
          }
        } else {
          // 如果值不是陣列，嘗試從 formValues 中讀取層級的值
          for (const level of levels) {
            if (!level || !level.field_key) {
              continue
            }

            const levelValue = formValues[level.field_key]
            if (levelValue === null || levelValue === undefined || levelValue === '') {
              continue // 跳過空值
            }

            // 查找層級對應的欄位定義
            const levelField = fields.find(f => f.field_key === level.field_key)
            if (levelField) {
              const levelDbValue = this._convertValueToDb(levelValue, levelField)
              valuesToUpsert.push({
                form_id: formIdValue,
                field_id: levelField.id,
                record_id: recordId,
                field_key: level.field_key,
                ...levelDbValue,
              })
              processedFieldKeys.add(level.field_key)
            } else {
              // 如果層級欄位不存在，使用主欄位的 field_id，但使用層級的 field_key
              // 注意：這需要資料庫的唯一約束包含 field_key
              const levelDbValue = this._convertValueToDb(levelValue, field)
              valuesToUpsert.push({
                form_id: formIdValue,
                field_id: field.id, // 使用主欄位的 field_id
                record_id: recordId,
                field_key: level.field_key, // 使用層級的 field_key
                ...levelDbValue,
              })
              processedFieldKeys.add(level.field_key)
            }
          }
        }
        // 標記主欄位已處理（不保存主欄位的陣列值，避免重複）
        processedFieldKeys.add(fieldKey)
      } else {
        // 對於非 cascading_select 欄位，正常保存
        const dbValue = this._convertValueToDb(value, field)
        valuesToUpsert.push({
          form_id: formIdValue,
          field_id: field.id,
          record_id: recordId,
          field_key: fieldKey,
          ...dbValue,
        })
        processedFieldKeys.add(fieldKey)
      }
    }

    // 批量更新（使用 upsert）
    if (valuesToUpsert.length > 0) {
      const { error } = await supabase
        .from('form_data_values')
        .upsert(valuesToUpsert)

      if (error) {
        throw error
      }
    }

    // 返回更新的資料
    return this.getFormData(formId, recordId, options)
  },

  /**
   * 刪除表單資料
   */
  async deleteFormData (formId, recordId) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得表單 ID
    const formIdValue = await this._getFormId(formId)

    const { error } = await supabase
      .from('form_data_values')
      .delete()
      .eq('form_id', formIdValue)
      .eq('record_id', recordId)

    if (error) {
      throw error
    }
  },

  /**
   * 取得欄位值（單一欄位）
   */
  async getFieldValue (formId, recordId, fieldKey) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得表單 ID
    const formIdValue = await this._getFormId(formId)

    // 取得欄位定義
    const { data: field } = await supabase
      .from('form_fields')
      .select('*')
      .eq('form_id', formIdValue)
      .eq('field_key', fieldKey)
      .single()

    if (!field) {
      return null
    }

    // 取得欄位值
    const { data: value, error } = await supabase
      .from('form_data_values')
      .select('*')
      .eq('form_id', formIdValue)
      .eq('field_id', field.id)
      .eq('record_id', recordId)
      .single()

    if (error && error.code !== 'PGRST116') { // PGRST116 是「找不到記錄」的錯誤碼
      throw error
    }

    if (!value) {
      return null
    }

    return this._convertValueFromDb(value, field)
  },

  /**
   * 設定欄位值（單一欄位）
   */
  async setFieldValue (formId, recordId, fieldKey, value) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得表單 ID
    const formIdValue = await this._getFormId(formId)

    // 取得欄位定義
    const { data: field } = await supabase
      .from('form_fields')
      .select('*')
      .eq('form_id', formIdValue)
      .eq('field_key', fieldKey)
      .single()

    if (!field) {
      throw new Error(`找不到欄位: ${fieldKey}`)
    }

    const dbValue = this._convertValueToDb(value, field)

    const { data, error } = await supabase
      .from('form_data_values')
      .upsert({
        form_id: formIdValue,
        field_id: field.id,
        record_id: recordId,
        field_key: fieldKey,
        ...dbValue,
      })
      .select()
      .single()

    if (error) {
      throw error
    }

    return this._convertValueFromDb(data, field)
  },

  /**
   * 輔助方法：取得表單 ID
   */
  async _getFormId (formId) {
    const isNumeric = /^\d+$/.test(String(formId))
    if (isNumeric) {
      return parseInt(formId)
    }

    // 如果是 form_code，查詢表單 ID
    const { data: form } = await supabase
      .from('forms')
      .select('id')
      .eq('form_code', formId)
      .single()

    if (!form) {
      throw new Error(`找不到表單: ${formId}`)
    }

    return form.id
  },

  /**
   * 輔助方法：將值轉換為資料庫格式
   */
  _convertValueToDb (value, field) {
    if (value === null || value === undefined) {
      return {
        field_value: null,
        field_value_json: null,
        field_value_number: null,
        field_value_date: null,
        field_value_datetime: null,
        file_url: null,
      }
    }

    const result = {
      field_value: null,
      field_value_json: null,
      field_value_number: null,
      field_value_date: null,
      field_value_datetime: null,
      file_url: null,
    }

    switch (field.field_type) {
      case 'text':
      case 'textarea':
      case 'select':
      case 'radio':
        result.field_value = String(value)
        break

      case 'number':
        result.field_value_number = typeof value === 'number' ? value : parseFloat(value)
        break

      case 'date':
        result.field_value_date = value instanceof Date ? value.toISOString().split('T')[0] : value
        break

      case 'datetime':
        result.field_value_datetime = value instanceof Date ? value.toISOString() : value
        break

      case 'multiselect':
      case 'checkbox':
      case 'json':
        result.field_value_json = typeof value === 'string' ? JSON.parse(value) : value
        break

      case 'file':
        result.file_url = String(value)
        break

      default:
        result.field_value = String(value)
    }

    return result
  },

  /**
   * 輔助方法：從資料庫格式轉換值
   */
  _convertValueFromDb (dbValue, field) {
    // 根據欄位類型返回對應的值
    switch (field.field_type) {
      case 'text':
      case 'textarea':
      case 'select':
      case 'radio':
        return dbValue.field_value

      case 'number':
        return dbValue.field_value_number

      case 'date':
        return dbValue.field_value_date

      case 'datetime':
        return dbValue.field_value_datetime

      case 'multiselect':
      case 'checkbox':
      case 'json':
        return dbValue.field_value_json

      case 'file':
        return dbValue.file_url

      default:
        return dbValue.field_value
    }
  },

  /**
   * 輔助方法：計算聚合資料欄位的值
   * @param {string} template - 模板字符串（例如："{#type}.{#subtype}.{#detail}.{@sn#5}"）
   * @param {object} formValues - 表單值對象
   * @param {string} counterKey - 計數器鍵值（可選）
   * @returns {Promise<string>} 計算後的聚合值
   */
  async _calculateAggregatedValue (template, formValues, counterKey = null) {
    if (!template) {
      return ''
    }

    let result = template

    // 從值中提取實際的字符串值（與 AggregatedField.vue 中的 extractValue 相同邏輯）
    const extractValue = (value) => {
      if (value === null || value === undefined || value === '') {
        return ''
      }

      // 如果是陣列
      if (Array.isArray(value)) {
        const validValues = value.filter(v => v !== null && v !== undefined && v !== '')
        if (validValues.length === 0) {
          return ''
        }
        return extractValue(validValues[0])
      }

      // 如果是物件
      if (typeof value === 'object') {
        const valueKeys = ['value', 'id', 'key', 'code']
        for (const key of valueKeys) {
          if (value[key] !== undefined && value[key] !== null && value[key] !== '') {
            return String(value[key])
          }
        }
        const keys = Object.keys(value)
        if (keys.length > 0) {
          const firstValue = value[keys[0]]
          if (firstValue !== null && firstValue !== undefined && firstValue !== '') {
            return String(firstValue)
          }
        }
        return ''
      }

      // 其他情況直接轉為字串
      return String(value)
    }

    // 處理欄位值替換 {#field_key}
    result = result.replace(/\{#(\w+)\}/g, (match, fieldKey) => {
      const value = formValues[fieldKey]
      return extractValue(value)
    })

    // 處理系統計數序號 {@sn#n}
    const snMatches = Array.from(result.matchAll(/\{@sn#(\d+)\}/g))
    for (const match of snMatches) {
      const digits = parseInt(match[1], 10)
      
      // 生成計數器 key
      let finalCounterKey = counterKey
      if (!finalCounterKey) {
        // 如果沒有提供 counterKey，嘗試從模板中的其他欄位值構建
        const templateStr = template
        const fieldKeyMatches = Array.from(templateStr.matchAll(/\{#(\w+)\}/g))
        const fieldKeys = fieldKeyMatches.map(m => m[1])
        
        if (fieldKeys.length > 0) {
          const keyParts = []
          for (const fieldKey of fieldKeys) {
            const value = extractValue(formValues[fieldKey] || '')
            if (value) {
              keyParts.push(value)
            }
          }
          
          if (keyParts.length === fieldKeys.length && keyParts.length >= 2) {
            const prefix = keyParts.slice(0, 2).join('')
            const suffix = keyParts.slice(2).join('.')
            finalCounterKey = suffix ? `${prefix}.${suffix}` : prefix
          } else if (keyParts.length === 1) {
            finalCounterKey = `${keyParts[0]}.item_code`
          }
        }
        
        if (!finalCounterKey) {
          finalCounterKey = 'item_code'
        }
      }

      // 獲取計數器值
      // counter 表存儲的是"下一個要使用的計數值"，所以直接使用即可（不需要 +1）
      // 如果查詢不到，使用 1（表示下一個要使用的序號是 1，即當前要使用的序號）
      let counterValue = 1
      try {
        const value = await codeCountersService.getCounter(finalCounterKey)
        // 如果查詢不到或值無效，使用 1
        counterValue = value && value >= 1 ? value : 1
      } catch (error) {
        console.warn(`獲取計數器值失敗 (key: ${finalCounterKey})`, error)
        counterValue = 1
      }

      // 替換計數器佔位符（直接使用 counter 值，因為它已經表示"下一個要使用的序號"，即當前要使用的序號）
      result = result.replace(match[0], String(counterValue).padStart(digits, '0'))
    }

    return result
  },

  /**
   * 輔助方法：從值中提取字符串（用於構建計數器 key）
   * @param {any} value - 要提取的值
   * @returns {string} 提取的字符串值
   */
  _extractValueForCounter (value) {
    if (value === null || value === undefined || value === '') {
      return ''
    }

    // 如果是陣列
    if (Array.isArray(value)) {
      const validValues = value.filter(v => v !== null && v !== undefined && v !== '')
      if (validValues.length === 0) {
        return ''
      }
      return this._extractValueForCounter(validValues[0])
    }

    // 如果是物件
    if (typeof value === 'object') {
      const valueKeys = ['value', 'id', 'key', 'code']
      for (const key of valueKeys) {
        if (value[key] !== undefined && value[key] !== null && value[key] !== '') {
          return String(value[key])
        }
      }
      const keys = Object.keys(value)
      if (keys.length > 0) {
        const firstValue = value[keys[0]]
        if (firstValue !== null && firstValue !== undefined && firstValue !== '') {
          return String(firstValue)
        }
      }
      return ''
    }

    // 其他情況直接轉為字串
    return String(value)
  },

  /**
   * 輔助方法：計算聚合資料欄位的值（使用指定的計數器值）
   * @param {string} template - 模板字符串（例如："{#type}.{#subtype}.{#detail}.{@sn#5}"）
   * @param {object} formValues - 表單值對象
   * @param {string} counterKey - 計數器鍵值（可選，用於日誌）
   * @param {number} counterValue - 計數器值（已遞增後的值）
   * @returns {Promise<string>} 計算後的聚合值
   */
  async _calculateAggregatedValueWithCounter (template, formValues, counterKey = null, counterValue) {
    if (!template) {
      return ''
    }

    let result = template

    // 從值中提取實際的字符串值（與 AggregatedField.vue 中的 extractValue 相同邏輯）
    const extractValue = (value) => {
      return this._extractValueForCounter(value)
    }

    // 處理欄位值替換 {#field_key}
    result = result.replace(/\{#(\w+)\}/g, (match, fieldKey) => {
      const value = formValues[fieldKey]
      return extractValue(value)
    })

    // 處理系統計數序號 {@sn#n} - 使用傳入的計數器值
    // counterValue 是"當前要使用的計數值"（從 getAndIncrementCounter 返回），直接使用即可
    const snMatches = Array.from(result.matchAll(/\{@sn#(\d+)\}/g))
    for (const match of snMatches) {
      const digits = parseInt(match[1], 10)
      // 如果 counterValue 無效，使用 1（表示當前要使用的序號是 1）
      const finalCounterValue = counterValue && counterValue >= 1 ? counterValue : 1
      // 替換計數器佔位符（直接使用 counterValue，因為它已經表示"當前要使用的序號"）
      result = result.replace(match[0], String(finalCounterValue).padStart(digits, '0'))
    }

    return result
  },
}
