<template>
  <div class="material-system">
    <v-container fluid>
      <v-tabs v-model="tab" bg-color="grey-lighten-4" class="mb-4">
        <v-tab
          v-if="canApply"
          value="apply"
        >
          <v-icon start>mdi-file-document-plus</v-icon>
          物料申請
        </v-tab>
        <v-tab
          v-if="canPackaging"
          value="packaging"
        >
          <v-icon start>mdi-package-variant</v-icon>
          包裝說明設定
        </v-tab>
        <v-tab
          v-if="canReview"
          value="review"
        >
          <v-icon start>mdi-check-circle</v-icon>
          審核管理
          <v-badge
            v-if="pendingCount > 0"
            class="ml-2"
            color="error"
            :content="pendingCount"
            inline
          />
        </v-tab>
        <v-tab
          v-if="canExport"
          value="export"
        >
          <v-icon start>mdi-file-excel</v-icon>
          EXCEL匯出
        </v-tab>
        <v-tab
          v-if="canQuery"
          value="query"
        >
          <v-icon start>mdi-magnify</v-icon>
          申請查詢
        </v-tab>
        <v-tab
          v-if="canSettings"
          value="settings"
        >
          <v-icon start>mdi-cog</v-icon>
          系統設定
        </v-tab>
        <v-tab
          v-if="canUsers"
          value="users"
        >
          <v-icon start>mdi-account-group</v-icon>
          使用者管理
        </v-tab>
      </v-tabs>

      <!-- 物料申請 -->
      <v-window v-model="tab">
        <v-window-item
          v-if="canApply"
          value="apply"
        >
          <MaterialApplicationForm />
        </v-window-item>

        <!-- 包裝說明設定 -->
        <v-window-item
          v-if="canPackaging"
          value="packaging"
        >
          <PackagingTemplateSettings />
        </v-window-item>

        <!-- 審核管理 -->
        <v-window-item
          v-if="canReview"
          value="review"
        >
          <ReviewManagement />
        </v-window-item>

        <!-- EXCEL匯出 -->
        <v-window-item
          v-if="canExport"
          value="export"
        >
          <ExcelExport />
        </v-window-item>

        <!-- 申請查詢 -->
        <v-window-item
          v-if="canQuery"
          value="query"
        >
          <ApplicationQuery />
        </v-window-item>

        <!-- 系統設定 -->
        <v-window-item
          v-if="canSettings"
          value="settings"
        >
          <SystemSettings />
        </v-window-item>

        <!-- 使用者管理 -->
        <v-window-item
          v-if="canUsers"
          value="users"
        >
          <UsersManagement />
        </v-window-item>
      </v-window>
    </v-container>
  </div>
</template>

<script setup>
  import { computed, onMounted, ref, watch } from 'vue'
  import { useRoute } from 'vue-router'
  import ApplicationQuery from '@/components/ApplicationQuery.vue'
  import ExcelExport from '@/components/ExcelExport.vue'
  import MaterialApplicationForm from '@/components/MaterialApplicationForm.vue'
  import PackagingTemplateSettings from '@/components/PackagingTemplateSettings.vue'
  import ReviewManagement from '@/components/ReviewManagement.vue'
  import SystemSettings from '@/components/SystemSettings.vue'
  import UsersManagement from '@/pages/users.vue'
  import { useApplicationsStore } from '@/stores/applications'
  import { usePermissions } from '@/composables/usePermissions'

  const route = useRoute()
  const tab = ref('apply')
  const applicationsStore = useApplicationsStore()
  
  // 權限檢查
  const {
    canApply,
    canPackaging,
    canReview,
    canExport,
    canQuery,
    canSettings,
    canUsers,
  } = usePermissions()

  const pendingCount = computed(() => applicationsStore.pendingCount)

  // 根據權限設定預設 tab 和快捷鍵支援
  onMounted(() => {
    // 監聽路由查詢參數，切換 tab
    watch(() => route.query.tab, (newTab) => {
      if (newTab) {
        // 檢查是否有權限訪問該 tab
        const tabPermissions = {
          apply: canApply.value,
          packaging: canPackaging.value,
          review: canReview.value,
          export: canExport.value,
          query: canQuery.value,
          settings: canSettings.value,
          users: canUsers.value,
        }
        
        if (tabPermissions[newTab]) {
          tab.value = newTab
        }
      }
    }, { immediate: true })

    // 如果當前 tab 沒有權限，切換到第一個有權限的 tab
    const tabOrder = ['apply', 'packaging', 'review', 'export', 'query', 'settings', 'users']
    const tabPermissions = {
      apply: canApply.value,
      packaging: canPackaging.value,
      review: canReview.value,
      export: canExport.value,
      query: canQuery.value,
      settings: canSettings.value,
      users: canUsers.value,
    }

    // 如果當前 tab 沒有權限，找到第一個有權限的 tab
    if (!tabPermissions[tab.value]) {
      const firstAllowedTab = tabOrder.find(t => tabPermissions[t])
      if (firstAllowedTab) {
        tab.value = firstAllowedTab
      }
    }

    // 快捷鍵支援（僅在有權限時生效）
    const handleKeyDown = e => {
      if (e.altKey) {
        switch (e.key.toLowerCase()) {
          case 'n': {
            if (canApply.value) {
              e.preventDefault()
              tab.value = 'apply'
            }
            break
          }
          case 'r': {
            if (canReview.value) {
              e.preventDefault()
              tab.value = 'review'
            }
            break
          }
          case 'e': {
            if (canExport.value) {
              e.preventDefault()
              tab.value = 'export'
            }
            break
          }
          case 'q': {
            if (canQuery.value) {
              e.preventDefault()
              tab.value = 'query'
            }
            break
          }
          case 's': {
            if (canSettings.value) {
              e.preventDefault()
              tab.value = 'settings'
            }
            break
          }
        }
      }
    }

    window.addEventListener('keydown', handleKeyDown)

    return () => {
      window.removeEventListener('keydown', handleKeyDown)
    }
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';
</style>
