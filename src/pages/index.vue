<template>
  <div class="material-system">
    <v-container fluid>
      <!-- 載入中提示 -->
      <v-progress-linear
        v-if="permissionsLoading"
        indeterminate
        color="primary"
        class="mb-4"
      />

      <!-- 首頁：功能模組按鈕 -->
      <v-window v-model="tab">
        <v-window-item value="home">
          <v-card class="pa-6">
            <v-card-title class="text-h4 mb-6 d-flex align-center">
              <v-icon class="mr-3" size="40">mdi-view-dashboard</v-icon>
              功能模組
            </v-card-title>
            <v-card-text>
              <v-row>
                <!-- 1. 項目主檔申請表 -->
                <v-col
                  v-if="canApply"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('batch-apply')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-table-plus
                      </v-icon>
                      <div class="text-h6">項目主檔申請表</div>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 2. 申請查詢 -->
                <v-col
                  v-if="canQuery"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('query')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-magnify
                      </v-icon>
                      <div class="text-h6">申請查詢</div>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 3. EXCEL匯出 -->
                <v-col
                  v-if="canExport"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('export')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-file-excel
                      </v-icon>
                      <div class="text-h6">EXCEL匯出</div>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 4. 選項活頁簿 -->
                <v-col
                  v-if="canOptionWorkbooks"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('option-workbooks')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-book-open-variant
                      </v-icon>
                      <div class="text-h6">選項活頁簿</div>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 5. 包裝說明設定 -->
                <v-col
                  v-if="canPackaging"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('packaging')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-package-variant
                      </v-icon>
                      <div class="text-h6">包裝說明設定</div>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 6. 審核管理 -->
                <v-col
                  v-if="canReview"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('review')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-check-circle
                      </v-icon>
                      <div class="text-h6">審核管理</div>
                      <v-badge
                        v-if="pendingCount > 0"
                        class="mt-2"
                        color="error"
                        :content="pendingCount"
                        inline
                      />
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 7. 表單管理 -->
                <v-col
                  v-if="canForms"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('forms')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-form-select
                      </v-icon>
                      <div class="text-h6">表單管理</div>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 8. 審核流程設定 -->
                <v-col
                  v-if="canApprovalWorkflow"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('approval-workflow')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-sitemap
                      </v-icon>
                      <div class="text-h6">審核流程設定</div>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 9. 使用者管理 -->
                <v-col
                  v-if="canUsers"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('users')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-account-group
                      </v-icon>
                      <div class="text-h6">使用者管理</div>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 10. 系統設定 -->
                <v-col
                  v-if="canSettings"
                  cols="12"
                  sm="6"
                  md="4"
                  lg="3"
                >
                  <v-card
                    class="module-card"
                    hover
                    @click="navigateToModule('settings')"
                  >
                    <v-card-text class="text-center pa-6">
                      <v-icon
                        size="64"
                        color="primary"
                        class="mb-4"
                      >
                        mdi-cog
                      </v-icon>
                      <div class="text-h6">系統設定</div>
                    </v-card-text>
                  </v-card>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>
        </v-window-item>

        <!-- 物料申請 -->
        <v-window-item
          v-if="canApply"
          value="apply"
        >
          <MaterialApplicationForm />
        </v-window-item>

        <!-- 單據申請 -->
        <v-window-item
          v-if="canApply"
          value="batch-apply"
        >
          <BatchMaterialApplications />
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

        <!-- 選項活頁簿 -->
        <v-window-item
          v-if="canOptionWorkbooks"
          value="option-workbooks"
        >
          <OptionWorkbooks />
        </v-window-item>
      </v-window>
    </v-container>
  </div>
</template>

<script setup>
  import { computed, onMounted, ref, watch } from 'vue'
  import { useRoute, useRouter } from 'vue-router'
  import ApplicationQuery from '@/components/ApplicationQuery.vue'
  import ApprovalWorkflowSettings from '@/components/ApprovalWorkflowSettings.vue'
  import BatchMaterialApplications from '@/components/BatchMaterialApplications.vue'
  import ExcelExport from '@/components/ExcelExport.vue'
  import MaterialApplicationForm from '@/components/MaterialApplicationForm.vue'
  import OptionWorkbooks from '@/components/OptionWorkbooks.vue'
  import PackagingTemplateSettings from '@/components/PackagingTemplateSettings.vue'
  import ReviewManagement from '@/components/ReviewManagement.vue'
  import SystemSettings from '@/components/SystemSettings.vue'
  import { usePermissions } from '@/composables/usePermissions'
  import { useApplicationsStore } from '@/stores/applications'
  import FormsManagement from '@/pages/forms.vue'
  import UsersManagement from '@/pages/users.vue'

  const route = useRoute()
  const router = useRouter()
  const tab = ref('home')
  const applicationsStore = useApplicationsStore()
  
  // 待審核數量
  const pendingCount = computed(() => applicationsStore.pendingCount)

  // 權限檢查
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
    loading: permissionsLoading,
  } = usePermissions()

  /**
   * 導航到指定的功能模組
   */
  function navigateToModule (moduleTab) {
    tab.value = moduleTab
    router.push({ path: '/', query: { tab: moduleTab } })
  }

  // 根據權限設定預設 tab 和快捷鍵支援
  onMounted(async () => {
    // 先載入權限
    await loadUserPagePermissions()
    
    // 監聽路由查詢參數，切換 tab
    watch(() => route.query.tab, newTab => {
      if (newTab) {
        // 檢查是否有權限訪問該 tab
        const tabPermissions = {
          'apply': canApply.value,
          'batch-apply': canApply.value,
          'packaging': canPackaging.value,
          'review': canReview.value,
          'export': canExport.value,
          'query': canQuery.value,
          'settings': canSettings.value,
          'users': canUsers.value,
          'approval-workflow': canApprovalWorkflow.value,
          'forms': canForms.value,
          'option-workbooks': canOptionWorkbooks.value,
        }

        if (tabPermissions[newTab]) {
          tab.value = newTab
        } else {
          // 如果沒有權限訪問該 tab，回到首頁
          tab.value = 'home'
        }
      } else {
        // 如果沒有指定 tab，顯示首頁
        tab.value = 'home'
      }
    }, { immediate: true })

    // 快捷鍵支援（僅在有權限時生效）
    const handleKeyDown = e => {
      if (e.altKey) {
        switch (e.key.toLowerCase()) {
          case 'n': {
            if (canApply.value) {
              e.preventDefault()
              tab.value = 'batch-apply'
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

.module-card {
  cursor: pointer;
  transition: all 0.3s ease;
  height: 100%;
  
  &:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15) !important;
  }
  
  .v-card-text {
    min-height: 180px;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }
}
</style>
