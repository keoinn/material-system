/**
 * Forms API Service
 * 表單定義管理 API 服務
 * 根據環境變數自動選擇使用 Supabase 或 Axios 實作
 */
import { getBackendType } from '../client.js'
import axiosImpl from './axios/forms.js'
import supabaseImpl from './supabase/forms.js'

/**
 * 取得當前使用的後端實作
 */
function getImplementation () {
  return getBackendType() === 'axios' ? axiosImpl : supabaseImpl
}

/**
 * 表單定義服務
 */
export const formsService = {
  /**
   * 取得所有表單列表
   * @param {object} filters - 篩選條件（is_active, is_default 等）
   * @returns {Promise<Array>}
   */
  async getForms (filters = {}) {
    return getImplementation().getForms(filters)
  },

  /**
   * 取得單一表單定義（含所有欄位）
   * @param {number|string} idOrCode - 表單 ID 或 form_code
   * @param {boolean} includeFields - 是否包含欄位定義
   * @returns {Promise<Object>}
   */
  async getForm (idOrCode, includeFields = true) {
    return getImplementation().getForm(idOrCode, includeFields)
  },

  /**
   * 建立表單定義
   * @param {object} formData - 表單資料
   * @returns {Promise<Object>}
   */
  async createForm (formData) {
    return getImplementation().createForm(formData)
  },

  /**
   * 更新表單定義
   * @param {number|string} id - 表單 ID
   * @param {object} updates - 更新資料
   * @returns {Promise<Object>}
   */
  async updateForm (id, updates) {
    return getImplementation().updateForm(id, updates)
  },

  /**
   * 刪除表單定義
   * @param {number|string} id - 表單 ID
   * @returns {Promise<void>}
   */
  async deleteForm (id) {
    return getImplementation().deleteForm(id)
  },

  /**
   * 複製表單定義
   * @param {number|string} id - 表單 ID
   * @param {object} newFormData - 新表單資料（可選）
   * @returns {Promise<Object>}
   */
  async duplicateForm (id, newFormData = {}) {
    const impl = getImplementation()
    if (impl.duplicateForm) {
      return impl.duplicateForm(id, newFormData)
    }
    // 如果實作沒有 duplicateForm 方法，手動實作
    const form = await this.getForm(id, true)
    const newForm = {
      form_code: newFormData.form_code || `${form.form_code}_copy_${Date.now()}`,
      form_name: newFormData.form_name || `${form.form_name} (複製)`,
      form_name_en: newFormData.form_name_en || `${form.form_name_en} (Copy)`,
      description: newFormData.description || form.description,
      form_config: newFormData.form_config || form.form_config,
      is_active: newFormData.is_active !== undefined ? newFormData.is_active : form.is_active,
      is_default: false, // 複製的表單預設不是預設表單
    }
    const createdForm = await this.createForm(newForm)
    
    // 複製欄位定義
    if (form.fields && form.fields.length > 0) {
      const formFieldsService = (await import('./formFields.js')).formFieldsService
      for (const field of form.fields) {
        const { id: fieldId, form_id, created_at, updated_at, ...fieldData } = field
        await formFieldsService.createField(createdForm.id, fieldData)
      }
    }
    
    return createdForm
  },
}

export default formsService
