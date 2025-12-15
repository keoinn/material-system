/**
 * API Client Configuration
 * 根據環境變數選擇使用 Supabase 或 Axios
 */
import axios from 'axios'

const API_BACKEND = import.meta.env.VITE_API_BACKEND || 'supabase'
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'
const API_TIMEOUT = import.meta.env.VITE_API_TIMEOUT || 10000

/**
 * Axios 客戶端實例
 * 當 VITE_API_BACKEND=axios 時使用
 */
export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: parseInt(API_TIMEOUT, 10),
  headers: {
    'Content-Type': 'application/json',
  },
})

// 請求攔截器
apiClient.interceptors.request.use(
  (config) => {
    // 從 localStorage 或 Supabase session 取得 token
    const token = localStorage.getItem('auth_token') || 
                  localStorage.getItem('supabase.auth.token')
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    
    return config
  },
  (error) => {
    console.error('API Request Error:', error)
    return Promise.reject(error)
  }
)

// 響應攔截器
apiClient.interceptors.response.use(
  (response) => {
    // 統一處理響應格式
    return response.data || response
  },
  (error) => {
    // 統一錯誤處理
    const errorMessage = error.response?.data?.message || 
                        error.message || 
                        '請求失敗，請稍後再試'
    
    console.error('API Response Error:', error)
    
    // 處理常見錯誤狀態碼
    if (error.response) {
      switch (error.response.status) {
        case 401:
          // 未授權，清除認證資訊
          localStorage.removeItem('auth_token')
          localStorage.removeItem('supabase.auth.token')
          // 可以觸發登出事件
          window.dispatchEvent(new CustomEvent('auth:logout'))
          break
        case 403:
          console.error('無權限存取此資源')
          break
        case 404:
          console.error('資源不存在')
          break
        case 500:
          console.error('伺服器錯誤')
          break
      }
    }
    
    return Promise.reject({
      message: errorMessage,
      status: error.response?.status,
      data: error.response?.data,
    })
  }
)

/**
 * 取得當前使用的後端類型
 */
export function getBackendType() {
  return API_BACKEND
}

/**
 * 檢查是否使用 Supabase
 */
export function isSupabaseBackend() {
  return API_BACKEND === 'supabase'
}

/**
 * 檢查是否使用 Axios
 */
export function isAxiosBackend() {
  return API_BACKEND === 'axios'
}

export default apiClient
