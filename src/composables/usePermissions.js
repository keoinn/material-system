/**
 * usePermissions Composable
 * 權限檢查工具（從資料庫查詢）
 */
import { computed, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { rolesService } from '@/api/services'

/**
 * 頁面代碼映射
 */
const PAGE_CODES = {
  APPLY: 'apply',
  PACKAGING: 'packaging',
  REVIEW: 'review',
  EXPORT: 'export',
  QUERY: 'query',
  SETTINGS: 'settings',
  USERS: 'users',
  APPROVAL_WORKFLOW: 'approval-workflow',
  FORMS: 'forms',
}

/**
 * 權限檢查 Composable
 */
export function usePermissions () {
  const authStore = useAuthStore()
  const accessiblePages = ref(new Set()) // 可訪問的頁面代碼集合
  const loading = ref(false)

  /**
   * 載入當前使用者的頁面權限
   */
  async function loadUserPagePermissions () {
    const userRole = authStore.userRole
    if (!userRole) {
      accessiblePages.value = new Set()
      return
    }

    loading.value = true
    try {
      // 根據 role_code 查詢角色
      const role = await rolesService.getRole(userRole)
      if (!role || !role.is_active) {
        accessiblePages.value = new Set()
        return
      }

      // 查詢該角色的頁面權限
      const pageAccess = await rolesService.getRolePageAccess(role.id)
      
      // 如果沒有設定頁面權限，預設所有頁面都可以訪問（向後兼容）
      if (!pageAccess || pageAccess.length === 0) {
        accessiblePages.value = new Set(Object.values(PAGE_CODES))
      } else {
        // 只保留 is_accessible = true 的頁面
        accessiblePages.value = new Set(
          pageAccess
            .filter(pa => pa.is_accessible)
            .map(pa => pa.page_code)
        )
      }
    } catch (error) {
      console.error('載入使用者頁面權限失敗', error)
      // 如果查詢失敗，預設所有頁面都可以訪問（向後兼容）
      accessiblePages.value = new Set(Object.values(PAGE_CODES))
    } finally {
      loading.value = false
    }
  }

  /**
   * 檢查用戶是否可以訪問指定頁面
   * @param {string} pageCode - 頁面代碼
   * @returns {boolean}
   */
  const canAccessPage = (pageCode) => {
    if (!authStore.isLoggedIn || !authStore.userRole) return false
    return accessiblePages.value.has(pageCode)
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
  const canApply = computed(() => canAccessPage(PAGE_CODES.APPLY))

  /**
   * 檢查是否可以訪問包裝說明設定
   */
  const canPackaging = computed(() => canAccessPage(PAGE_CODES.PACKAGING))

  /**
   * 檢查是否可以訪問審核管理
   */
  const canReview = computed(() => canAccessPage(PAGE_CODES.REVIEW))

  /**
   * 檢查是否可以訪問EXCEL匯出
   */
  const canExport = computed(() => canAccessPage(PAGE_CODES.EXPORT))

  /**
   * 檢查是否可以訪問申請查詢
   */
  const canQuery = computed(() => canAccessPage(PAGE_CODES.QUERY))

  /**
   * 檢查是否可以訪問系統設定
   */
  const canSettings = computed(() => canAccessPage(PAGE_CODES.SETTINGS))

  /**
   * 檢查是否可以訪問使用者管理
   */
  const canUsers = computed(() => canAccessPage(PAGE_CODES.USERS))

  /**
   * 檢查是否可以訪問審核流程設定
   */
  const canApprovalWorkflow = computed(() => canAccessPage(PAGE_CODES.APPROVAL_WORKFLOW))

  /**
   * 檢查是否可以訪問表單管理
   */
  const canForms = computed(() => canAccessPage(PAGE_CODES.FORMS))

  return {
    loadUserPagePermissions,
    canAccessPage,
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
    canApprovalWorkflow,
    canForms,
    loading: computed(() => loading.value),
  }
}

