<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>待審核申請</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-data-table
        class="elevation-1"
        :headers="headers"
        :items="pendingApplications"
        :loading="loading"
      >
        <template v-slot:[`item.submit_date`]="{ item }">
          {{ formatDate(item.submit_date || item.submitDate) }}
        </template>

        <template v-slot:[`item.item_code`]="{ item }">
          {{ item.item_code || item.itemCode }}
        </template>

        <template v-slot:[`item.item_name_cn`]="{ item }">
          {{ item.item_name_cn || item.itemNameCN }}
        </template>

        <template v-slot:[`item.status`]="{ item }">
          <v-chip
            :color="getStatusColor(item.status)"
            size="small"
            variant="flat"
          >
            {{ getStatusText(item.status) }}
          </v-chip>
        </template>

        <template v-slot:[`item.actions`]="{ item }">
          <v-btn
            class="mr-2"
            color="success"
            size="small"
            @click="approveApplication(item.id)"
          >
            核准
          </v-btn>
          <v-btn
            class="mr-2"
            color="error"
            size="small"
            @click="rejectApplication(item.id)"
          >
            退回
          </v-btn>
          <v-btn
            color="info"
            size="small"
            @click="viewDetails(item.id)"
          >
            詳情
          </v-btn>
        </template>

        <template #no-data>
          <div class="text-center py-4">
            目前沒有待審核的申請
          </div>
        </template>
      </v-data-table>

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
                          {{ selectedApplication.itemCode || selectedApplication.item_code || 'N/A' }}
                        </span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">中文名稱：</span>
                        <span class="detail-value">{{ selectedApplication.itemNameCN || selectedApplication.item_name_cn || 'N/A' }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">英文名稱：</span>
                        <span class="detail-value">{{ selectedApplication.itemNameEN || selectedApplication.item_name_en || 'N/A' }}</span>
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
                        <span class="detail-value">{{ selectedApplication.surfaceFinish || selectedApplication.surface_finish || 'N/A' }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請人：</span>
                        <span class="detail-value">{{ selectedApplication.applicant || 'Unknown' }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請日期：</span>
                        <span class="detail-value">{{ formatDate(selectedApplication.submit_date || selectedApplication.submitDate) }}</span>
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

              <!-- 動態表單資料區塊 -->
              <v-card
                v-if="selectedApplication.isDynamicForm && selectedFormData"
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
                    :record-id="selectedApplication.id"
                    :show-actions="false"
                    :show-title="false"
                    :readonly="true"
                  />
                </v-card-text>
              </v-card>

              <!-- 包裝說明區塊（僅非動態表單顯示） -->
              <v-card
                v-if="!selectedApplication.isDynamicForm && selectedApplication.packaging"
                variant="outlined"
              >
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

      <!-- 退回原因對話框 -->
      <v-dialog v-model="rejectDialog" max-width="500">
        <v-card>
          <v-card-title>輸入退回原因</v-card-title>
          <v-card-text>
            <v-textarea
              v-model="rejectReason"
              label="退回原因"
              rows="3"
              variant="outlined"
            />
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn @click="rejectDialog = false">取消</v-btn>
            <v-btn color="error" @click="confirmReject">確認退回</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { computed, onMounted, ref } from 'vue'
  import { applicationsService } from '@/api/services/applications'
  import { formDataService } from '@/api/services/formData'
  import { formsService } from '@/api/services/forms'
  import { packagingService } from '@/api/services/packaging'
  import { categoriesService } from '@/api/services/categories'
  import { useSwal } from '@/composables/useSwal'
  import { useAuthStore } from '@/stores/auth'
  import DynamicFormRenderer from './DynamicFormRenderer.vue'

  const swal = useSwal()
  const authStore = useAuthStore()

  const loading = ref(false)
  const detailDialog = ref(false)
  const rejectDialog = ref(false)
  const selectedApplication = ref(null)
  const rejectReason = ref('')
  const rejectApplicationId = ref(null)
  const applications = ref([])
  const selectedFormData = ref(null) // 動態表單資料
  const selectedFormId = ref(null) // 動態表單 ID

  const pendingApplications = computed(() => applications.value)

  const headers = [
    { title: '申請日期', key: 'submit_date', sortable: true },
    { title: '申請單號', key: 'id', sortable: true },
    { title: '料號', key: 'item_code', sortable: true },
    { title: '料件說明', key: 'item_name_cn', sortable: true },
    { title: '申請人', key: 'applicant', sortable: true },
    { title: '狀態', key: 'status', sortable: true },
    { title: '操作', key: 'actions', sortable: false },
  ]

  // 載入待審核申請列表（從 form_data_values 讀取）
  async function loadPendingApplications () {
    loading.value = true
    try {
      // 嘗試獲取 material_application 表單，如果不存在則查詢所有表單的資料
      let formData = null
      let formId = null

      try {
        formData = await formsService.getForm('material_application', false)
        if (formData) {
          formId = formData.id
        }
      } catch (error) {
        // 如果找不到表單，嘗試查詢所有 active 的表單
        console.warn('找不到 material_application 表單，嘗試查詢所有表單', error)
        try {
          const allForms = await formsService.getForms({ is_active: true })
          if (allForms && allForms.length > 0) {
            // 優先使用預設表單，否則使用第一個
            formData = allForms.find(f => f.is_default) || allForms[0]
            if (formData) {
              formId = formData.id
            }
          }
        } catch (formsError) {
          console.warn('無法查詢表單列表，將查詢所有 form_data_values', formsError)
          // 如果無法查詢表單，formId 保持為 null，會查詢所有表單的資料
        }
      }

      // 從 form_data_values 讀取待審核申請（如果 formId 為 null，會查詢所有表單的資料）
      const data = await formDataService.getPendingFormDataList(formId, { status: 'PENDING' })

      // 轉換數據格式以符合組件需求
      applications.value = data.map((app) => ({
        ...app,
        submitDate: app.submit_date,
        itemCode: app.item_code,
        itemNameCN: app.item_name_cn,
        itemNameEN: app.item_name_en,
        applicant: app.applicant_name || app.applicant?.username || 'Unknown',
        isDynamicForm: true, // 所有從 form_data_values 讀取的都標記為動態表單
        formId: app.form_id || formData?.id || null,
      }))
    } catch (error) {
      console.error('載入待審核申請失敗', error)
      await swal.error('載入待審核申請失敗，請重新整理頁面')
    } finally {
      loading.value = false
    }
  }

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

  async function approveApplication (id) {
    const result = await swal.confirm('確定要核准此申請嗎？', '確認核准')
    if (result.isConfirmed) {
      loading.value = true
      try {
        const approverId = authStore.currentUser?.id
        // 從 form_data_values 更新狀態
        const application = applications.value.find(app => app.id === id || app.record_id === id)
        if (!application || !application.formId) {
          throw new Error('找不到申請記錄或表單 ID')
        }

        // 更新 form_data_values 中的 status 和 approval_status
        await formDataService.updateFormData(application.formId, id, {
          status: 'APPROVED',
          approval_status: 'APPROVED',
          approver_id: approverId,
          approval_date: new Date().toISOString(),
        })

        await swal.success('申請已核准！')
        // 重新載入列表
        await loadPendingApplications()
      } catch (error) {
        console.error('核准申請失敗', error)
        await swal.error('核准申請失敗，請稍後再試')
      } finally {
        loading.value = false
      }
    }
  }

  function rejectApplication (id) {
    rejectApplicationId.value = id
    rejectReason.value = ''
    rejectDialog.value = true
  }

  async function confirmReject () {
    if (!rejectReason.value.trim()) {
      await swal.warning('請輸入退回原因', '驗證失敗')
      return
    }

    loading.value = true
    try {
      const approverId = authStore.currentUser?.id
      // 從 form_data_values 更新狀態
      const application = applications.value.find(app => app.id === rejectApplicationId.value || app.record_id === rejectApplicationId.value)
      if (!application || !application.formId) {
        throw new Error('找不到申請記錄或表單 ID')
      }

      // 更新 form_data_values 中的 status 和 approval_status
      await formDataService.updateFormData(application.formId, rejectApplicationId.value, {
        status: 'REJECTED',
        approval_status: 'REJECTED',
        reject_reason: rejectReason.value,
        approver_id: approverId,
        reject_date: new Date().toISOString(),
      })

      rejectDialog.value = false
      rejectReason.value = ''
      await swal.success('申請已退回！')
      // 重新載入列表
      await loadPendingApplications()
    } catch (error) {
      console.error('退回申請失敗', error)
      await swal.error('退回申請失敗，請稍後再試')
    } finally {
      loading.value = false
    }
  }

  async function viewDetails (id) {
    loading.value = true
    try {
      // 從列表中查找申請資訊
      const application = applications.value.find(app => app.id === id || app.record_id === id)
      if (!application || !application.formId) {
        throw new Error('找不到申請記錄')
      }

      // 載入動態表單資料
      try {
        const formData = await formDataService.getFormData(application.formId, id, {
          includeFieldDefinitions: true,
        })
        selectedFormData.value = formData
        selectedFormId.value = application.formId
      } catch (error) {
        console.error('載入動態表單資料失敗', error)
        selectedFormData.value = null
        selectedFormId.value = null
      }

      // 從表單資料中讀取對應欄位值
      const formValues = selectedFormData.value?.values || {}
      const formFields = selectedFormData.value?.fields || []

      // 查找對應的欄位 field_key
      const findFieldKeyByLabel = (label) => {
        const field = formFields.find(f => 
          f.field_label === label || 
          f.field_label_en === label ||
          f.field_label?.includes(label) ||
          f.field_label_en?.includes(label)
        )
        return field?.field_key
      }

      // 對應關係：
      // 料號 → 系統編碼 (item_code)
      // 中文名稱 → 料件說明 (中文)
      // 英文名稱 → 料件說明 (英文)
      // 材質 → 基本材質
      // 表面處理 → 基本材質 表面處理

      const itemCodeKey = findFieldKeyByLabel('系統編碼') || 'item_code'
      const itemNameCNKey = findFieldKeyByLabel('料件說明') || findFieldKeyByLabel('料件說明 (中文)') || 'item_name_cn'
      const itemNameENKey = findFieldKeyByLabel('料件說明 (英文)') || 'item_name_en'
      const materialKey = findFieldKeyByLabel('基本材質') || 'material'
      const surfaceFinishKey = findFieldKeyByLabel('表面處理') || findFieldKeyByLabel('基本材質 表面處理') || 'surface_finish'

      // 查找欄位定義並獲取選項的 label
      const getFieldLabelByValue = (fieldKey, value) => {
        if (!value) {
          return null
        }
        const field = formFields.find(f => f.field_key === fieldKey)
        if (!field || !field.field_config?.options) {
          return value
        }
        const options = field.field_config.options
        const option = options.find(opt => {
          if (typeof opt === 'string') {
            return opt === value
          }
          return (opt.value || opt) === value
        })
        if (option) {
          if (typeof option === 'string') {
            return option
          }
          return option.title || option.label || option.value || value
        }
        return value
      }

      // 獲取材質欄位的值
      const materialValue = formValues[materialKey] || application.material
      // 獲取材質欄位的 label
      const materialLabel = getFieldLabelByValue(materialKey, materialValue)

      // 使用從 form_data_values 讀取的資料
      selectedApplication.value = {
        ...application,
        submitDate: application.submit_date,
        itemCode: formValues[itemCodeKey] || application.item_code,
        itemNameCN: formValues[itemNameCNKey] || application.item_name_cn,
        itemNameEN: formValues[itemNameENKey] || application.item_name_en,
        material: materialLabel || materialValue || 'N/A',
        surfaceFinish: formValues[surfaceFinishKey] || application.surface_finish,
        applicant: application.applicant_name || 
                  application.applicant?.username || 
                  'Unknown',
        isDynamicForm: true,
      }

      detailDialog.value = true
    } catch (error) {
      console.error('載入申請詳情失敗', error)
      await swal.error('載入申請詳情失敗，請稍後再試')
    } finally {
      loading.value = false
    }
  }

  // 組件掛載時載入數據
  onMounted(() => {
    loadPendingApplications()
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

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
