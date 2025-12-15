<template>
  <div class="material-system">
    <v-container fluid>
      <v-tabs v-model="tab" bg-color="grey-lighten-4" class="mb-4">
        <v-tab value="apply">
          <v-icon start>mdi-file-document-plus</v-icon>
          物料申請
        </v-tab>
        <v-tab value="packaging">
          <v-icon start>mdi-package-variant</v-icon>
          包裝說明設定
        </v-tab>
        <v-tab value="review">
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
        <v-tab value="export">
          <v-icon start>mdi-file-excel</v-icon>
          EXCEL匯出
        </v-tab>
        <v-tab value="query">
          <v-icon start>mdi-magnify</v-icon>
          申請查詢
        </v-tab>
        <v-tab value="settings">
          <v-icon start>mdi-cog</v-icon>
          系統設定
        </v-tab>
      </v-tabs>

      <!-- 物料申請 -->
      <v-window v-model="tab">
        <v-window-item value="apply">
          <MaterialApplicationForm />
        </v-window-item>

        <!-- 包裝說明設定 -->
        <v-window-item value="packaging">
          <PackagingTemplateSettings />
        </v-window-item>

        <!-- 審核管理 -->
        <v-window-item value="review">
          <ReviewManagement />
        </v-window-item>

        <!-- EXCEL匯出 -->
        <v-window-item value="export">
          <ExcelExport />
        </v-window-item>

        <!-- 申請查詢 -->
        <v-window-item value="query">
          <ApplicationQuery />
        </v-window-item>

        <!-- 系統設定 -->
        <v-window-item value="settings">
          <SystemSettings />
        </v-window-item>
      </v-window>
    </v-container>
  </div>
</template>

<script setup>
  import { computed, onMounted, ref } from 'vue'
  import ApplicationQuery from '@/components/ApplicationQuery.vue'
  import ExcelExport from '@/components/ExcelExport.vue'
  import MaterialApplicationForm from '@/components/MaterialApplicationForm.vue'
  import PackagingTemplateSettings from '@/components/PackagingTemplateSettings.vue'
  import ReviewManagement from '@/components/ReviewManagement.vue'
  import SystemSettings from '@/components/SystemSettings.vue'
  import { useApplicationsStore } from '@/stores/applications'

  const tab = ref('apply')
  const applicationsStore = useApplicationsStore()

  const pendingCount = computed(() => applicationsStore.pendingCount)

  // 快捷鍵支援
  onMounted(() => {
    const handleKeyDown = e => {
      if (e.altKey) {
        switch (e.key.toLowerCase()) {
          case 'n': {
            e.preventDefault()
            tab.value = 'apply'
            break
          }
          case 'r': {
            e.preventDefault()
            tab.value = 'review'
            break
          }
          case 'e': {
            e.preventDefault()
            tab.value = 'export'
            break
          }
          case 'q': {
            e.preventDefault()
            tab.value = 'query'
            break
          }
          case 's': {
            e.preventDefault()
            tab.value = 'settings'
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
