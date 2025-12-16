/**
 * API 入口檔案
 * 統一匯出所有 API 相關功能
 */
export { default as apiClient, getBackendType, isAxiosBackend, isSupabaseBackend } from './client.js'
// 匯出所有服務
export * from './services/index.js'

export { isSupabaseAvailable, STORAGE_BUCKET, storageService, default as supabase } from './supabase.js'
