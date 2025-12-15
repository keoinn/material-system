<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>申請記錄查詢</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-form ref="formRef">
        <v-row>
          <v-col cols="12" md="3">
            <v-text-field
              v-model="filters.itemCode"
              clearable
              label="料號"
              variant="outlined"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-text-field
              v-model="filters.applicant"
              clearable
              label="申請人"
              variant="outlined"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-select
              v-model="filters.status"
              clearable
              :items="statusOptions"
              label="狀態"
              variant="outlined"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-text-field
              v-model="filters.dateFrom"
              label="日期範圍（開始）"
              type="date"
              variant="outlined"
            />
          </v-col>
        </v-row>

        <div class="d-flex justify-center gap-4 mt-4">
          <v-btn
            color="primary"
            size="large"
            @click="searchApplications"
          >
            查詢
          </v-btn>
          <v-btn
            color="grey"
            size="large"
            @click="clearQueryForm"
          >
            清除條件
          </v-btn>
        </div>
      </v-form>

      <!-- 查詢結果 -->
      <v-card v-if="queryResults.length > 0" class="mt-4">
        <v-card-title>查詢結果（共 {{ queryResults.length }} 筆）</v-card-title>
        <v-card-text>
          <v-data-table
            class="elevation-1"
            :headers="headers"
            :items="queryResults"
            :items-per-page="10"
          >
            <template #item.submitDate="{ item }">
              {{ formatDate(item.submitDate) }}
            </template>

            <template #item.status="{ item }">
              <v-chip
                :color="getStatusColor(item.status)"
                size="small"
                variant="flat"
              >
                {{ getStatusText(item.status) }}
              </v-chip>
            </template>

            <template #item.actions="{ item }">
              <v-btn
                color="info"
                size="small"
                @click="viewDetails(item.id)"
              >
                詳情
              </v-btn>
            </template>
          </v-data-table>
        </v-card-text>
      </v-card>

      <!-- 詳情對話框 -->
      <v-dialog v-model="detailDialog" max-width="800">
        <v-card v-if="selectedApplication">
          <v-card-title>
            申請詳情
            <v-spacer />
            <v-btn icon @click="detailDialog = false">
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-card-title>

          <v-card-text>
            <v-row>
              <v-col cols="12" md="6">
                <strong>申請單號：</strong>{{ selectedApplication.id }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>料號：</strong>{{ selectedApplication.itemCode }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>中文名稱：</strong>{{ selectedApplication.itemNameCN }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>英文名稱：</strong>{{ selectedApplication.itemNameEN }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>材質：</strong>{{ selectedApplication.material }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>表面處理：</strong>{{ selectedApplication.surfaceFinish || 'N/A' }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>申請人：</strong>{{ selectedApplication.applicant }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>申請日期：</strong>{{ formatDate(selectedApplication.submitDate) }}
              </v-col>
            </v-row>

            <v-divider class="my-4" />

            <h3 class="mb-2">包裝說明</h3>
            <div
              v-for="(section, key) in selectedApplication.packaging"
              :key="key"
              class="mb-2"
            >
              <strong>{{ getPackagingSectionName(key) }}：</strong>
              <span v-if="section.options?.length">
                {{ section.options.join(', ') }}
              </span>
              <span v-if="section.description">{{ section.description }}</span>
            </div>
          </v-card-text>
        </v-card>
      </v-dialog>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { reactive, ref } from 'vue'
  import { useApplicationsStore } from '@/stores/applications'

  const applicationsStore = useApplicationsStore()

  const formRef = ref(null)
  const queryResults = ref([])
  const detailDialog = ref(false)
  const selectedApplication = ref(null)

  const filters = reactive({
    itemCode: '',
    applicant: '',
    status: '',
    dateFrom: '',
  })

  const statusOptions = [
    { title: '全部', value: '' },
    { title: '待審核', value: 'PENDING' },
    { title: '已核准', value: 'APPROVED' },
    { title: '已退回', value: 'REJECTED' },
  ]

  const headers = [
    { title: '申請日期', key: 'submitDate', sortable: true },
    { title: '申請單號', key: 'id', sortable: true },
    { title: '料號', key: 'itemCode', sortable: true },
    { title: '料件說明', key: 'itemNameCN', sortable: true },
    { title: '申請人', key: 'applicant', sortable: true },
    { title: '狀態', key: 'status', sortable: true },
    { title: '操作', key: 'actions', sortable: false },
  ]

  function formatDate (dateString) {
    if (!dateString) return ''
    return new Date(dateString).toLocaleDateString('zh-TW')
  }

  function getStatusColor (status) {
    const colors = {
      PENDING: 'warning',
      APPROVED: 'success',
      REJECTED: 'error',
    }
    return colors[status] || 'grey'
  }

  function getStatusText (status) {
    const texts = {
      PENDING: '待審核',
      APPROVED: '已核准',
      REJECTED: '已退回',
    }
    return texts[status] || status
  }

  function getPackagingSectionName (key) {
    const names = {
      productPackaging: '1. 個別產品包裝',
      accessoriesContent: '2. 配件內容',
      accessories: '3. 配件',
      innerBox: '4. 內盒',
      outerBox: '5. 外箱',
      transport: '6. 運輸與托盤要求',
      container: '7. 裝櫃要求',
      other: '8. 其他說明',
    }
    return names[key] || key
  }

  function searchApplications () {
    queryResults.value = applicationsStore.searchApplications(filters)
  }

  function clearQueryForm () {
    Object.assign(filters, {
      itemCode: '',
      applicant: '',
      status: '',
      dateFrom: '',
    })
    queryResults.value = []
    formRef.value?.reset()
  }

  function viewDetails (id) {
    selectedApplication.value = applicationsStore.getApplication(id)
    detailDialog.value = true
  }
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.gap-4 {
  gap: 16px;
}
</style>
