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

      <!-- 申請詳情對話框 -->
      <v-dialog
        v-model="detailDialog"
        max-width="900"
        scrollable
        persistent
      >
        <v-card v-if="selectedApplication">
          <v-card-title class="d-flex align-center bg-primary text-white">
            <v-icon class="mr-2">mdi-file-document-outline</v-icon>
            <span>申請詳情</span>
            <v-spacer />
            <v-btn
              icon
              variant="text"
              @click="detailDialog = false"
            >
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-card-title>

          <v-card-text class="pa-0">
            <v-container>
              <!-- 基本資訊區塊 -->
              <v-card
                class="mb-4"
                variant="outlined"
              >
                <v-card-title class="text-subtitle-1 bg-grey-lighten-4">
                  <v-icon class="mr-2">mdi-information</v-icon>
                  基本資訊
                </v-card-title>
                <v-card-text>
                  <v-row>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請單號：</span>
                        <span class="detail-value">{{ selectedApplication.id }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">料號：</span>
                        <span class="detail-value font-weight-bold text-primary">
                          {{ selectedApplication.itemCode }}
                        </span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">中文名稱：</span>
                        <span class="detail-value">{{ selectedApplication.itemNameCN }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">英文名稱：</span>
                        <span class="detail-value">{{ selectedApplication.itemNameEN }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">材質：</span>
                        <span class="detail-value">{{ selectedApplication.material }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">表面處理：</span>
                        <span class="detail-value">{{ selectedApplication.surfaceFinish || 'N/A' }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請人：</span>
                        <span class="detail-value">{{ selectedApplication.applicant }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請日期：</span>
                        <span class="detail-value">{{ formatDate(selectedApplication.submitDate) }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">狀態：</span>
                        <v-chip
                          :color="getStatusColor(selectedApplication.status)"
                          size="small"
                          variant="flat"
                        >
                          {{ getStatusText(selectedApplication.status) }}
                        </v-chip>
                      </div>
                    </v-col>
                  </v-row>
                </v-card-text>
              </v-card>

              <!-- 包裝說明區塊 -->
              <v-card variant="outlined">
                <v-card-title class="text-subtitle-1 bg-grey-lighten-4">
                  <v-icon class="mr-2">mdi-package-variant</v-icon>
                  包裝說明
                </v-card-title>
                <v-card-text>
                  <div
                    v-for="(section, key) in selectedApplication.packaging"
                    :key="key"
                    class="packaging-section"
                  >
                    <div class="packaging-section-title">
                      {{ getPackagingSectionName(key) }}
                    </div>
                    <div class="packaging-section-content">
                      <div v-if="section.options?.length" class="mb-2">
                        <span class="text-grey-darken-1">選項：</span>
                        <v-chip
                          v-for="(option, index) in section.options"
                          :key="index"
                          class="ma-1"
                          color="primary"
                          size="small"
                          variant="outlined"
                        >
                          {{ option }}
                        </v-chip>
                      </div>
                      <div v-if="section.description">
                        <span class="text-grey-darken-1">說明：</span>
                        <span>{{ section.description }}</span>
                      </div>
                      <div
                        v-if="!section.options?.length && !section.description"
                        class="text-grey"
                      >
                        無資料
                      </div>
                    </div>
                  </div>
                </v-card-text>
              </v-card>
            </v-container>
          </v-card-text>

          <v-divider />

          <v-card-actions class="pa-4">
            <v-spacer />
            <v-btn
              color="primary"
              variant="flat"
              @click="detailDialog = false"
            >
              關閉
            </v-btn>
          </v-card-actions>
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

.detail-item {
  padding: 8px 0;
  min-height: 40px;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
}

.detail-label {
  font-weight: 600;
  color: rgba(0, 0, 0, 0.6);
  margin-right: 8px;
  min-width: 100px;
}

.detail-value {
  color: rgba(0, 0, 0, 0.87);
  flex: 1;
}

.packaging-section {
  margin-bottom: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.12);

  &:last-child {
    border-bottom: none;
    margin-bottom: 0;
    padding-bottom: 0;
  }
}

.packaging-section-title {
  font-weight: 600;
  color: rgba(0, 0, 0, 0.87);
  margin-bottom: 8px;
  font-size: 0.95rem;
}

.packaging-section-content {
  padding-left: 16px;
  color: rgba(0, 0, 0, 0.7);
}
</style>
