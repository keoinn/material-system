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
            :loading="loading"
            :disabled="loading"
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
      <v-card v-if="queryResults.length > 0 || loading" class="mt-4">
        <v-card-title>查詢結果（共 {{ queryResults.length }} 筆）</v-card-title>
        <v-card-text>
          <v-progress-linear
            v-if="loading"
            indeterminate
            color="primary"
            class="mb-4"
          />
          <v-data-table
            v-if="!loading"
            class="elevation-1"
            :headers="headers"
            :items="queryResults"
            :items-per-page="10"
          >
            <template #item.submit_date="{ item }">
              {{ formatDate(item.submit_date) }}
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
                :loading="loadingDetails && selectedApplicationId === item.id"
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
                          {{ selectedApplication.item_code }}
                        </span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">中文名稱：</span>
                        <span class="detail-value">{{ selectedApplication.item_name_cn }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">英文名稱：</span>
                        <span class="detail-value">{{ selectedApplication.item_name_en || 'N/A' }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">材質：</span>
                        <span class="detail-value">{{ selectedApplication.material || 'N/A' }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">表面處理：</span>
                        <span class="detail-value">{{ selectedApplication.surface_finish || 'N/A' }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請人：</span>
                        <span class="detail-value">{{ selectedApplication.applicant_name || 'N/A' }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請日期：</span>
                        <span class="detail-value">{{ formatDate(selectedApplication.submit_date) }}</span>
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
  import { applicationsService } from '@/api/services/applications'
  import { packagingService } from '@/api/services/packaging'
  import { useSwal } from '@/composables/useSwal'

  const swal = useSwal()

  const formRef = ref(null)
  const queryResults = ref([])
  const detailDialog = ref(false)
  const selectedApplication = ref(null)
  const loading = ref(false)
  const loadingDetails = ref(false)
  const selectedApplicationId = ref(null)

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
    { title: '申請日期', key: 'submit_date', sortable: true },
    { title: '申請單號', key: 'id', sortable: true },
    { title: '料號', key: 'item_code', sortable: true },
    { title: '料件說明', key: 'item_name_cn', sortable: true },
    { title: '申請人', key: 'applicant_name', sortable: true },
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

  async function searchApplications () {
    loading.value = true
    try {
      const queryFilters = {}
      if (filters.itemCode) {
        queryFilters.itemCode = filters.itemCode
      }
      if (filters.applicant) {
        queryFilters.applicant = filters.applicant
      }
      if (filters.status) {
        queryFilters.status = filters.status
      }
      if (filters.dateFrom) {
        queryFilters.dateFrom = filters.dateFrom
      }

      const results = await applicationsService.getApplications(queryFilters)
      queryResults.value = results || []
    } catch (error) {
      console.error('查詢申請記錄失敗', error)
      await swal.error('查詢失敗', error.message || '無法取得申請記錄')
      queryResults.value = []
    } finally {
      loading.value = false
    }
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

  async function viewDetails (id) {
    loadingDetails.value = true
    selectedApplicationId.value = id
    try {
      // 獲取申請詳情
      const application = await applicationsService.getApplication(id)
      
      // 獲取包裝數據
      const packagingData = await packagingService.getApplicationPackaging(id)
      
      // 轉換包裝數據格式
      const packaging = transformPackagingData(packagingData)
      
      selectedApplication.value = {
        ...application,
        packaging,
      }
      detailDialog.value = true
    } catch (error) {
      console.error('獲取申請詳情失敗', error)
      await swal.error('載入失敗', error.message || '無法取得申請詳情')
    } finally {
      loadingDetails.value = false
      selectedApplicationId.value = null
    }
  }

  // 轉換包裝數據格式：從 Supabase 格式轉換為組件期望的格式
  function transformPackagingData (packagingData) {
    const result = {
      productPackaging: { options: [], description: '' },
      accessoriesContent: { options: [], description: '' },
      accessories: { options: [], description: '' },
      innerBox: { options: [], description: '' },
      outerBox: { options: [], description: '' },
      transport: { options: [], description: '' },
      container: { options: [], description: '' },
      other: { options: [], description: '' },
    }

    if (!packagingData || !Array.isArray(packagingData)) {
      return result
    }

    // 按包裝類別分組（category code 直接對應 result 的 key）
    for (const item of packagingData) {
      const categoryCode = item.packaging_categories?.code
      if (!categoryCode || !result[categoryCode]) {
        continue
      }

      // 獲取選項名稱
      const optionName = item.packaging_options?.name || item.packaging_options?.code
      if (optionName && !result[categoryCode].options.includes(optionName)) {
        result[categoryCode].options.push(optionName)
      }

      // 設置描述（如果有多個描述，使用第一個非空的）
      if (item.description && !result[categoryCode].description) {
        result[categoryCode].description = item.description
      }
    }

    return result
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
