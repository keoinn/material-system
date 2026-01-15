/**
 * Form Data API Service - Axios Implementation
 * 表單資料管理 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得表單資料（單一記錄的所有欄位值）
   */
  async getFormData (formId, recordId, options = {}) {
    const response = await apiClient.get(`/forms/${formId}/data/${recordId}`, {
      params: options,
    })
    return response.data || response
  },

  /**
   * 取得表單資料列表（多筆記錄）
   */
  async getFormDataList (formId, filters = {}, options = {}) {
    const response = await apiClient.get(`/forms/${formId}/data`, {
      params: { ...filters, ...options },
    })
    return response.data || response
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
    const response = await apiClient.post(`/forms/${formId}/data`, {
      formValues,
      ...options,
    })
    return response.data || response
  },

  /**
   * 更新表單資料
   */
  async updateFormData (formId, recordId, formValues, options = {}) {
    const response = await apiClient.put(`/forms/${formId}/data/${recordId}`, {
      formValues,
      ...options,
    })
    return response.data || response
  },

  /**
   * 刪除表單資料
   */
  async deleteFormData (formId, recordId) {
    await apiClient.delete(`/forms/${formId}/data/${recordId}`)
  },

  /**
   * 取得欄位值（單一欄位）
   */
  async getFieldValue (formId, recordId, fieldKey) {
    const response = await apiClient.get(`/forms/${formId}/data/${recordId}/fields/${fieldKey}`)
    return response.data || response
  },

  /**
   * 設定欄位值（單一欄位）
   */
  async setFieldValue (formId, recordId, fieldKey, value) {
    const response = await apiClient.put(`/forms/${formId}/data/${recordId}/fields/${fieldKey}`, {
      value,
    })
    return response.data || response
  },
}
