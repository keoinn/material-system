/**
 * usePermissions Composable
 * 權限檢查工具
 */
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

/**
 * 權限定義
 */
const PERMISSIONS = {
  // 功能權限映射
  APPLY: ['admin', 'approver', 'applicant'], // 物料申請
  PACKAGING: ['admin', 'approver'], // 包裝說明設定
  REVIEW: ['admin', 'approver'], // 審核管理
  EXPORT: ['admin', 'approver', 'applicant'], // EXCEL匯出
  QUERY: ['admin', 'approver', 'applicant'], // 申請查詢
  SETTINGS: ['admin'], // 系統設定
  USERS: ['admin'], // 使用者管理
}

/**
 * 權限檢查 Composable
 */
export function usePermissions () {
  const authStore = useAuthStore()

  /**
   * 檢查用戶是否有指定權限
   * @param {string} permission - 權限名稱
   * @returns {boolean}
   */
  const hasPermission = (permission) => {
    const userRole = authStore.userRole
    if (!userRole) return false

    const allowedRoles = PERMISSIONS[permission] || []
    return allowedRoles.includes(userRole)
  }

  /**
   * 檢查是否為管理員
   */
  const isAdmin = computed(() => authStore.userRole === 'admin')

  /**
   * 檢查是否為審核人員
   */
  const isApprover = computed(() => authStore.userRole === 'approver')

  /**
   * 檢查是否為申請人員
   */
  const isApplicant = computed(() => authStore.userRole === 'applicant')

  /**
   * 檢查是否可以訪問物料申請
   */
  const canApply = computed(() => hasPermission('APPLY'))

  /**
   * 檢查是否可以訪問包裝說明設定
   */
  const canPackaging = computed(() => hasPermission('PACKAGING'))

  /**
   * 檢查是否可以訪問審核管理
   */
  const canReview = computed(() => hasPermission('REVIEW'))

  /**
   * 檢查是否可以訪問EXCEL匯出
   */
  const canExport = computed(() => hasPermission('EXPORT'))

  /**
   * 檢查是否可以訪問申請查詢
   */
  const canQuery = computed(() => hasPermission('QUERY'))

  /**
   * 檢查是否可以訪問系統設定
   */
  const canSettings = computed(() => hasPermission('SETTINGS'))

  /**
   * 檢查是否可以訪問使用者管理
   */
  const canUsers = computed(() => hasPermission('USERS'))

  return {
    hasPermission,
    isAdmin,
    isApprover,
    isApplicant,
    canApply,
    canPackaging,
    canReview,
    canExport,
    canQuery,
    canSettings,
    canUsers,
  }
}

