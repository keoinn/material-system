/**
 * Form Data API Service - Supabase Implementation
 * 表單資料管理 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
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
        valuesMap[field.field_key] = this._convertValueFromDb(value, field)
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

    // 如果選項中指定了要建立記錄，先建立記錄
    let newRecordId = options.recordId
    if (options.createRecord && !newRecordId) {
      // 這裡可以建立一個關聯記錄，例如在 applications 表中建立新記錄
      // 目前先使用時間戳作為臨時 ID
      newRecordId = Date.now()
    }

    if (!newRecordId) {
      throw new Error('建立表單資料需要提供 recordId 或設定 createRecord 選項')
    }

    // 取得欄位定義
    const { data: fields } = await supabase
      .from('form_fields')
      .select('*')
      .eq('form_id', formIdValue)

    if (!fields || fields.length === 0) {
      throw new Error('表單沒有定義欄位')
    }

    // 準備要插入的資料
    const valuesToInsert = []
    for (const [fieldKey, value] of Object.entries(formValues)) {
      const field = fields.find(f => f.field_key === fieldKey)
      if (!field) {
        continue // 跳過不存在的欄位
      }

      const dbValue = this._convertValueToDb(value, field)
      valuesToInsert.push({
        form_id: formIdValue,
        field_id: field.id,
        record_id: newRecordId,
        field_key: fieldKey,
        ...dbValue,
      })
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
    for (const [fieldKey, value] of Object.entries(formValues)) {
      const field = fields.find(f => f.field_key === fieldKey)
      if (!field) {
        continue // 跳過不存在的欄位
      }

      const dbValue = this._convertValueToDb(value, field)
      valuesToUpsert.push({
        form_id: formIdValue,
        field_id: field.id,
        record_id: recordId,
        field_key: fieldKey,
        ...dbValue,
      })
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
}
