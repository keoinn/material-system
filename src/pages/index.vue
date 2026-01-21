<template>
  <div class="material-system">
    <v-container fluid>
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

        <!-- 審核流程設定 -->
        <v-window-item
          v-if="canApprovalWorkflow"
          value="approval-workflow"
        >
          <ApprovalWorkflowSettings />
        </v-window-item>

        <!-- 表單管理 -->
        <v-window-item
          v-if="canForms"
          value="forms"
        >
          <FormsManagement />
        </v-window-item>
      </v-window>
    </v-container>
  </div>
</template>

<script setup>
  import { onMounted, ref, watch } from 'vue'
  import { useRoute } from 'vue-router'
  import ApplicationQuery from '@/components/ApplicationQuery.vue'
  import ApprovalWorkflowSettings from '@/components/ApprovalWorkflowSettings.vue'
  import ExcelExport from '@/components/ExcelExport.vue'
  import MaterialApplicationForm from '@/components/MaterialApplicationForm.vue'
  import PackagingTemplateSettings from '@/components/PackagingTemplateSettings.vue'
  import ReviewManagement from '@/components/ReviewManagement.vue'
  import SystemSettings from '@/components/SystemSettings.vue'
  import { usePermissions } from '@/composables/usePermissions'
  import FormsManagement from '@/pages/forms.vue'
  import UsersManagement from '@/pages/users.vue'

  const route = useRoute()
  const tab = ref('apply')

  // 權限檢查
  const {
    canApply,
    canPackaging,
    canReview,
    canExport,
    canQuery,
    canSettings,
    canUsers,
    canApprovalWorkflow,
    canForms,
  } = usePermissions()

  // 根據權限設定預設 tab 和快捷鍵支援
  onMounted(() => {
    // 監聽路由查詢參數，切換 tab
    watch(() => route.query.tab, newTab => {
      if (newTab) {
        // 檢查是否有權限訪問該 tab
        const tabPermissions = {
          'apply': canApply.value,
          'packaging': canPackaging.value,
          'review': canReview.value,
          'export': canExport.value,
          'query': canQuery.value,
          'settings': canSettings.value,
          'users': canUsers.value,
          'approval-workflow': canApprovalWorkflow.value,
          'forms': canForms.value,
        }

        if (tabPermissions[newTab]) {
          tab.value = newTab
        }
      }
    }, { immediate: true })

    // 如果當前 tab 沒有權限，切換到第一個有權限的 tab
    const tabOrder = ['apply', 'packaging', 'review', 'export', 'query', 'settings', 'users', 'approval-workflow', 'forms']
    const tabPermissions = {
      'apply': canApply.value,
      'packaging': canPackaging.value,
      'review': canReview.value,
      'export': canExport.value,
      'query': canQuery.value,
      'settings': canSettings.value,
      'users': canUsers.value,
      'approval-workflow': canApprovalWorkflow.value,
      'forms': canForms.value,
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
