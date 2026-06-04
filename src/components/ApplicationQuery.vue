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
            <template v-slot:[`item.submit_date`]="{ item }">
              {{ formatDate(item.submit_date) }}
            </template>
            <template v-slot:[`item.status`]="{ item }">
              <v-chip
                :color="getStatusColor(item.current_status_code || item.status)"
                size="small"
                variant="flat"
              >
                {{ item.current_status_name || getStatusText(item.current_status_code || item.status) }}
              </v-chip>
            </template>
            <template v-slot:[`item.actions`]="{ item }">
              <v-btn
                color="info"
                size="small"
                :loading="loadingDetails && selectedApplicationId === item.id"
                @click="viewDetails(item.id)"
              >
                預覽
              </v-btn>
            </template>
          </v-data-table>
        </v-card-text>
      </v-card>
      <v-dialog
        v-model="detailDialog"
        max-width="900"
        persistent
        scrollable
      >
        <v-card v-if="selectedApplication">
          <v-card-title class="d-flex align-center bg-primary text-white">
            <v-icon class="mr-2">mdi-file-document-outline</v-icon>
            <span>申請預覽</span>
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
              <v-card
                class="mb-4 basic-info-card"
                density="compact"
                variant="outlined"
              >
                <v-card-title class="text-subtitle-1 bg-grey-lighten-4 basic-info-card__title">
                  <v-icon class="mr-2">mdi-information</v-icon>
                  基本資訊
                </v-card-title>
                <v-card-text class="basic-info-card__content">
                  <v-row class="basic-info-grid" dense>
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
                    <v-col
                      v-if="selectedApplication.workflow_name || selectedApplication.workflow_code"
                      cols="12"
                      md="6"
                    >
                      <div class="detail-item">
                        <span class="detail-label">審核流程：</span>
                        <span class="detail-value">{{ formatWorkflowName(selectedApplication) }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">狀態：</span>
                        <v-chip
                          :color="getStatusColor(selectedApplication.current_status_code || selectedApplication.status)"
                          size="small"
                          variant="flat"
                        >
                          {{ selectedApplication.current_status_name || getStatusText(selectedApplication.current_status_code || selectedApplication.status) }}
                        </v-chip>
                      </div>
                    </v-col>
                    <v-col
                      v-if="isReturnedStatus(selectedApplication)"
                      cols="12"
                    >
                      <div class="detail-item detail-item--reject-reason">
                        <span class="detail-label">退回原因：</span>
                        <span class="detail-value text-error">{{ selectedApplication.reject_reason || '無' }}</span>
                      </div>
                    </v-col>
                    <v-col
                      v-if="selectedApplication.current_step_name"
                      cols="12"
                      md="6"
                    >
                      <div class="detail-item">
                        <span class="detail-label">當前步驟：</span>
                        <span class="detail-value">{{ selectedApplication.current_step_name }}</span>
                      </div>
                    </v-col>
                  </v-row>
                </v-card-text>
              </v-card>
              <v-card
                v-if="selectedApplication.is_dynamic_form && selectedFormData"
                class="mb-4"
                variant="outlined"
              >
                <v-card-title class="text-subtitle-1 bg-grey-lighten-4">
                  <v-icon class="mr-2">mdi-form-select</v-icon>
                  表單資料
                </v-card-title>
                <v-card-text>
                  <DynamicFormRenderer
                    :form-id="selectedFormId"
                    :readonly="true"
                    :record-id="selectedApplication.id"
                    :show-actions="false"
                    :show-title="false"
                  />
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
import { computed, onMounted, reactive, ref } from 'vue'
import { applicationsService } from '@/api/services/applications'
import { approvalWorkflowsService } from '@/api/services/approvalWorkflows'
import { formDataService } from '@/api/services/formData'
import { useSwal } from '@/composables/useSwal'
import DynamicFormRenderer from './DynamicFormRenderer.vue'

const swal = useSwal()
const formRef = ref(null)
const queryResults = ref([])
const detailDialog = ref(false)
const selectedApplication = ref(null)
const loading = ref(false)
const loadingDetails = ref(false)
const selectedApplicationId = ref(null)
const selectedFormData = ref(null)
const selectedFormId = ref(null)
const approvalStatuses = ref([])

const filters = reactive({
  itemCode: '',
  applicant: '',
  status: '',
  dateFrom: '',
})

// 從審核流程讀取狀態選項
const statusOptions = computed(() => {
  const options = [{ title: '全部', value: '' }]
  const statuses = approvalStatuses.value
    .filter(s => s.is_active)
    .sort((a, b) => a.display_order - b.display_order)
    .map(s => ({
      title: s.status_name,
      value: s.status_code,
    }))
  return [...options, ...statuses]
})

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

function formatWorkflowName (application) {
  if (!application) return 'N/A'
  if (application.workflow_name && application.workflow_code) {
    return `${application.workflow_name} (${application.workflow_code})`
  }
  return application.workflow_name || application.workflow_code || 'N/A'
}

function isReturnedStatus (application) {
  if (!application) return false
  const statusCode = application.current_status_code || application.status
  if (statusCode === 'REJECTED' || statusCode === 'RETURNED') {
    return true
  }
  const statusName = application.current_status_name || getStatusText(statusCode)
  return typeof statusName === 'string' && statusName.includes('退回')
}

// 從審核流程狀態定義獲取顏色
function getStatusColor (status) {
  if (!status) return 'grey'
  const statusDef = approvalStatuses.value.find(s => s.status_code === status)
  return statusDef?.color || 'grey'
}

// 從審核流程狀態定義獲取文字
function getStatusText (status) {
  if (!status) return '未知狀態'
  const statusDef = approvalStatuses.value.find(s => s.status_code === status)
  return statusDef?.status_name || status
}

// 載入審核狀態定義
async function loadApprovalStatuses () {
  try {
    approvalStatuses.value = await approvalWorkflowsService.getApprovalStatuses({ is_active: true })
  } catch (error) {
    console.error('載入審核狀態失敗', error)
    // 如果載入失敗，使用預設狀態（向後兼容）
    approvalStatuses.value = [
      { status_code: 'DRAFT', status_name: '草稿', color: 'grey', is_active: true, display_order: 1 },
      { status_code: 'PENDING', status_name: '待審核', color: 'warning', is_active: true, display_order: 2 },
      { status_code: 'IN_REVIEW', status_name: '審核中', color: 'info', is_active: true, display_order: 3 },
      { status_code: 'APPROVED', status_name: '已核准', color: 'success', is_active: true, display_order: 4 },
      { status_code: 'REJECTED', status_name: '已退回', color: 'error', is_active: true, display_order: 5 },
      { status_code: 'RETURNED', status_name: '退回修改', color: 'warning', is_active: true, display_order: 6 },
    ]
  }
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
    const application = await applicationsService.getApplication(id)
    if (application.is_dynamic_form && application.form_id) {
      try {
        const formData = await formDataService.getFormData(application.form_id, id, {
          includeFieldDefinitions: true,
        })
        selectedFormData.value = formData
        selectedFormId.value = application.form_id
      } catch (error) {
        console.error('載入動態表單資料失敗', error)
        selectedFormData.value = null
        selectedFormId.value = null
      }
    }
    selectedApplication.value = {
      ...application,
    }
    detailDialog.value = true
  } catch (error) {
    console.error('獲取申請預覽失敗', error)
    await swal.error('載入失敗', error.message || '無法取得申請預覽')
  } finally {
    loadingDetails.value = false
    selectedApplicationId.value = null
  }
}

// 組件掛載時載入審核狀態
onMounted(() => {
  loadApprovalStatuses()
})
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

.basic-info-card {
  &__title {
    padding-top: 8px;
    padding-bottom: 8px;
    min-height: unset;
  }

  &__content {
    padding-top: 8px !important;
    padding-bottom: 8px !important;
  }

  .detail-item {
    padding: 2px 0;
    min-height: 28px;
    line-height: 1.35;
  }

  .detail-label {
    min-width: 88px;
    margin-right: 6px;
    font-size: 0.875rem;
  }

  .detail-value {
    font-size: 0.875rem;
  }
}

.basic-info-grid {
  > .v-col {
    padding-top: 2px;
    padding-bottom: 2px;
  }
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

.detail-item--reject-reason {
  align-items: flex-start;

  .detail-value {
    white-space: pre-wrap;
    word-break: break-word;
  }
}
</style>
