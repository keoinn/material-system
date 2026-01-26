<template>
  <v-app>
    <!-- 只有在已登入且不是 Guest 時才顯示 toolbar -->
    <v-app-bar
      v-if="authStore.isLoggedIn && authStore.currentUser && authStore.currentUser.username !== 'Guest'"
      color="primary"
      elevation="2"
      prominent
    >
      <!-- 選單按鈕 -->
      <v-btn
        class="mr-2"
        icon
        @click="drawer = !drawer"
      >
        <v-icon>mdi-menu</v-icon>
      </v-btn>

      <v-app-bar-title>
        <div
          class="d-flex align-center cursor-pointer"
          @click="navigateToHome"
        >
          <v-icon class="mr-2">mdi-package-variant</v-icon>
          <span>物料編碼申請管理系統</span>
          <v-chip
            class="ml-2"
            color="white"
            size="small"
            text-color="primary"
          >
            V3.6
          </v-chip>
        </div>
      </v-app-bar-title>

      <v-spacer />

      <v-menu>
        <template #activator="{ props }">
          <v-btn
            icon
            v-bind="props"
          >
            <v-icon>mdi-account-circle</v-icon>
          </v-btn>
        </template>
        <v-list>
          <v-list-item>
            <v-list-item-title>
              {{ authStore.currentUser?.username }}
            </v-list-item-title>
            <v-list-item-subtitle>
              {{ getRoleText(authStore.currentUser?.role) }}
            </v-list-item-subtitle>
          </v-list-item>
          <v-divider />
          <v-list-item @click="handleLogout">
            <v-list-item-title>登出</v-list-item-title>
            <template #prepend>
              <v-icon>mdi-logout</v-icon>
            </template>
          </v-list-item>
        </v-list>
      </v-menu>
    </v-app-bar>

    <!-- 側邊欄導航抽屜 -->
    <v-navigation-drawer
      v-if="authStore.isLoggedIn && authStore.currentUser && authStore.currentUser.username !== 'Guest'"
      v-model="drawer"
      temporary
    >
      <v-list>
        <v-list-item>
          <v-list-item-title class="text-h6">
            功能選單
          </v-list-item-title>
        </v-list-item>
        <v-divider />

        <!-- 1. 物料申請 -->
        <v-list-item
          v-if="canApply"
          @click="navigateToTab('apply')"
        >
          <template #prepend>
            <v-icon>mdi-file-document-plus</v-icon>
          </template>
          <v-list-item-title>物料申請</v-list-item-title>
        </v-list-item>

        <!-- 2. 申請查詢 -->
        <v-list-item
          v-if="canQuery"
          @click="navigateToTab('query')"
        >
          <template #prepend>
            <v-icon>mdi-magnify</v-icon>
          </template>
          <v-list-item-title>申請查詢</v-list-item-title>
        </v-list-item>

        <!-- 3. EXCEL匯出 -->
        <v-list-item
          v-if="canExport"
          @click="navigateToTab('export')"
        >
          <template #prepend>
            <v-icon>mdi-file-excel</v-icon>
          </template>
          <v-list-item-title>EXCEL匯出</v-list-item-title>
        </v-list-item>

        <!-- 4. 選項活頁簿 -->
        <v-list-item
          v-if="canOptionWorkbooks"
          @click="navigateToTab('option-workbooks')"
        >
          <template #prepend>
            <v-icon>mdi-book-open-variant</v-icon>
          </template>
          <v-list-item-title>選項活頁簿</v-list-item-title>
        </v-list-item>

        <!-- 5. 包裝說明設定 -->
        <v-list-item
          v-if="canPackaging"
          @click="navigateToTab('packaging')"
        >
          <template #prepend>
            <v-icon>mdi-package-variant</v-icon>
          </template>
          <v-list-item-title>包裝說明設定</v-list-item-title>
        </v-list-item>

        <!-- 6. 審核管理 -->
        <v-list-item
          v-if="canReview"
          @click="navigateToTab('review')"
        >
          <template #prepend>
            <v-icon>mdi-check-circle</v-icon>
          </template>
          <v-list-item-title>
            <div class="d-flex align-center">
              <span>審核管理</span>
              <v-badge
                v-if="pendingCount > 0"
                class="ml-2"
                color="error"
                :content="pendingCount"
                inline
              />
            </div>
          </v-list-item-title>
        </v-list-item>

        <!-- 7. 表單管理 -->
        <v-list-item
          v-if="canForms"
          @click="navigateToTab('forms')"
        >
          <template #prepend>
            <v-icon>mdi-form-select</v-icon>
          </template>
          <v-list-item-title>表單管理</v-list-item-title>
        </v-list-item>

        <!-- 8. 審核流程設定 -->
        <v-list-item
          v-if="canApprovalWorkflow"
          @click="navigateToTab('approval-workflow')"
        >
          <template #prepend>
            <v-icon>mdi-sitemap</v-icon>
          </template>
          <v-list-item-title>審核流程設定</v-list-item-title>
        </v-list-item>

        <!-- 9. 使用者管理 -->
        <v-list-item
          v-if="canUsers"
          @click="navigateToTab('users')"
        >
          <template #prepend>
            <v-icon>mdi-account-group</v-icon>
          </template>
          <v-list-item-title>使用者管理</v-list-item-title>
        </v-list-item>

        <!-- 10. 系統設定 -->
        <v-list-item
          v-if="canSettings"
          @click="navigateToTab('settings')"
        >
          <template #prepend>
            <v-icon>mdi-cog</v-icon>
          </template>
          <v-list-item-title>系統設定</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>

    <v-main>
      <router-view />
    </v-main>

    <!-- 只有在已登入時才顯示 footer -->
    <AppFooter v-if="authStore.isLoggedIn && authStore.currentUser && authStore.currentUser.username !== 'Guest'" />
  </v-app>
</template>

<script setup>
  import { computed, onMounted, ref, watch } from 'vue'
  import { useRouter } from 'vue-router'
  import AppFooter from '@/components/AppFooter.vue'
  import { usePermissions } from '@/composables/usePermissions'
  import { useApplicationsStore } from '@/stores/applications'
  import { useAuthStore } from '@/stores/auth'

  const router = useRouter()
  const authStore = useAuthStore()
  const applicationsStore = useApplicationsStore()
  const {
    loadUserPagePermissions,
    canApply,
    canPackaging,
    canReview,
    canExport,
    canQuery,
    canSettings,
    canUsers,
    canApprovalWorkflow,
    canForms,
    canOptionWorkbooks,
  } = usePermissions()

  const drawer = ref(false)
  const pendingCount = computed(() => applicationsStore.pendingCount)

  // 監聽使用者登入狀態和角色變化，重新載入權限
  watch(
    () => [authStore.isLoggedIn, authStore.userRole],
    ([isLoggedIn, userRole]) => {
      if (isLoggedIn && userRole) {
        loadUserPagePermissions()
      }
    },
    { immediate: true },
  )

  // 組件掛載時載入權限
  onMounted(() => {
    if (authStore.isLoggedIn && authStore.userRole) {
      loadUserPagePermissions()
    }
  })

  /**
   * 將角色代碼轉換為中文顯示
   */
  function getRoleText (role) {
    const roleMap = {
      admin: '系統管理員',
      approver: '審核人員',
      applicant: '申請人員',
    }
    return roleMap[role] || role || '未知'
  }

  function handleLogout () {
    authStore.logout()
    router.push('/login')
  }

  /**
   * 導航到指定的 tab
   */
  function navigateToTab (tab) {
    router.push({ path: '/', query: { tab } })
  }

  /**
   * 導航到首頁
   */
  function navigateToHome () {
    router.push({ path: '/', query: {} })
  }
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.cursor-pointer {
  cursor: pointer;
  transition: opacity 0.2s ease;
  
  &:hover {
    opacity: 0.8;
  }
}
</style>
