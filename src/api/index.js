/**
 * API 入口檔案
 * 統一匯出所有 API 相關功能
 */
export { default as apiClient, getBackendType, isSupabaseBackend, isAxiosBackend } from './client.js'
export { default as supabase, storageService, isSupabaseAvailable, STORAGE_BUCKET } from './supabase.js'

// 匯出所有服務
export * from './services/index.js'

