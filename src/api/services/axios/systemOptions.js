/**
 * System Options API Service - Axios Implementation
 * 系統選項相關 API 服務（Axios 實作）
 */
import { apiClient } from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 取得系統選項（根據模組和類別）
   */
  async getOptions (module, cate, parentKey = null) {
    const params = { module, cate }
    if (parentKey !== null) {
      params.parentKey = parentKey
    }

    const response = await apiClient.get('/system-options', { params })
    return response.data || response
  },

  /**
   * 取得所有模組的選項
   */
  async getModuleOptions (module) {
    const response = await apiClient.get(`/system-options/module/${module}`)
    return response.data || response
  },
}

