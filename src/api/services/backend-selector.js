/**
 * Backend Selector
 * 根據環境變數選擇使用哪個後端實作
 */
import { getBackendType } from '../client.js'

/**
 * 動態載入並返回對應的後端實作
 * @param {string} serviceName - 服務名稱（例如：'applications', 'auth'）
 * @returns {Promise<Object>} 後端實作物件
 */
export async function getBackendImplementation (serviceName) {
  const backendType = getBackendType()

  if (backendType === 'axios') {
    const axiosImpl = await import(`./axios/${serviceName}.js`)
    return axiosImpl.default || axiosImpl
  } else {
    const supabaseImpl = await import(`./supabase/${serviceName}.js`)
    return supabaseImpl.default || supabaseImpl
  }
}

/**
 * 同步載入後端實作（用於不需要動態載入的情況）
 * @param {string} serviceName - 服務名稱
 * @returns {Object} 後端實作物件
 */
export function getBackendImplementationSync (serviceName) {
  const backendType = getBackendType()

  if (backendType === 'axios') {
    // 使用動態 import 的同步版本
    return require(`./axios/${serviceName}.js`)
  } else {
    return require(`./supabase/${serviceName}.js`)
  }
}

