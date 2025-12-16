/**
 * Auth API Service - Axios Implementation
 * 認證相關 API 服務（Axios 實作）
 */
import apiClient from '../../client.js'

/**
 * Axios 實作
 */
export default {
  /**
   * 登入
   */
  async login (email, password) {
    const response = await apiClient.post('/auth/login', { email, password })
    // 儲存 token
    if (response.token) {
      localStorage.setItem('auth_token', response.token)
    }
    return response
  },

  /**
   * 登出
   */
  async logout () {
    await apiClient.post('/auth/logout')
    localStorage.removeItem('auth_token')
  },

  /**
   * 取得當前使用者
   */
  async getCurrentUser () {
    try {
      const response = await apiClient.get('/auth/me')
      return response.user || response
    } catch {
      return null
    }
  },

  /**
   * 取得當前 Session
   */
  async getSession () {
    const token = localStorage.getItem('auth_token')
    return token ? { access_token: token } : null
  },

  /**
   * 註冊新使用者
   */
  async signUp (userData) {
    const response = await apiClient.post('/auth/signup', userData)
    return response
  },

  /**
   * 重設密碼
   */
  async resetPassword (email) {
    await apiClient.post('/auth/reset-password', { email })
  },
}

