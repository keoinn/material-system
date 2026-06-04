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
            :color="getStatusColor(item.current_status_code || item.status)"
            size="small"
            variant="flat"
          >
            {{ item.current_status_name || getStatusText(item.current_status_code || item.status) }}
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
            預覽
          </v-btn>
        </template>

        <template #no-data>
          <div class="text-center py-4">
            目前沒有待審核的申請
          </div>
        </template>
      </v-data-table>

      <!-- 申請預覽對話框 -->
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
                    :readonly="true"
                    :record-id="selectedApplication.id"
                    :show-actions="false"
                    :show-title="false"
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
  import { approvalWorkflowsService } from '@/api/services/approvalWorkflows'
  import { formDataService } from '@/api/services/formData'
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

  // 載入待審核申請列表（從 approval_records 讀取）
  async function loadPendingApplications () {
    loading.value = true
    try {
      // 使用審核流程系統獲取待審核申請
      const approvalRecords = await approvalWorkflowsService.getPendingApprovalApplications()

      // 為每個審核記錄獲取表單資料
      const applicationsWithData = await Promise.all(
        approvalRecords.map(async record => {
          try {
            // 從 form_data_values 獲取表單資料（包含欄位定義以便查找正確的 field_key）
            const formData = await formDataService.getFormData(record.form_id, record.record_id, {
              includeFieldDefinitions: true,
            })

            // 提取關鍵欄位值
            const values = formData?.values || {}
            const fields = formData?.fields || []

            // 查找欄位定義以確定正確的 field_key
            // 料號對應到「系統編碼」欄位（system_code）
            const systemCodeField = fields.find(f => f.field_key === 'system_code' || f.field_key === 'systemCode')
            const itemCodeField = systemCodeField || fields.find(f => f.field_key === 'item_code' || f.field_key === 'itemCode')

            let itemCode = values.system_code || values.systemCode || values.item_code || values.itemCode
            // 如果是聚合欄位，嘗試重新計算
            if (itemCodeField && itemCodeField.field_type === 'aggregated' && itemCodeField.field_config?.template) {
              try {
                itemCode = await formDataService._calculateAggregatedValue(
                  itemCodeField.field_config.template,
                  values,
                  itemCodeField.field_config.counterKey || itemCodeField.field_key,
                )
              } catch (error) {
                console.warn('重新計算聚合料號失敗，使用原始值', error)
              }
            }
            if (!itemCode || itemCode === '') {
              itemCode = 'N/A'
            }

            // 料件說明對應到「料件說明 (中文)」欄位（materials_desc_cn）
            const itemNameCN = values.materials_desc_cn || values.materialsDescCN || values.item_name_cn || values.itemNameCN || 'N/A'
            const itemNameEN = values.item_name_en || values.itemNameEN || 'N/A'

            return {
              id: record.record_id,
              record_id: record.record_id,
              approval_record_id: record.approval_record_id,
              form_id: record.form_id,
              submit_date: record.submit_date,
              submitDate: record.submit_date,
              item_code: itemCode,
              itemCode: itemCode,
              item_name_cn: itemNameCN,
              itemNameCN: itemNameCN,
              item_name_en: itemNameEN,
              itemNameEN: itemNameEN,
              applicant: record.applicant_username || 'Unknown',
              applicant_name: record.applicant_username || 'Unknown',
              // 審核流程相關資訊
              current_status_code: record.current_status_code,
              current_status_name: record.current_status_name,
              status_color: record.status_color,
              status_icon: record.status_icon,
              current_step_name: record.current_step_name,
              current_step_order: record.current_step_order,
              workflow_name: record.workflow_name,
              workflow_code: record.workflow_code,
              // 兼容舊的狀態欄位
              status: record.current_status_code,
              isDynamicForm: true,
              formId: record.form_id,
            }
          } catch (error) {
            console.error(`載入申請 ${record.record_id} 的表單資料失敗`, error)
            // 即使載入表單資料失敗，也返回基本資訊
            return {
              id: record.record_id,
              record_id: record.record_id,
              approval_record_id: record.approval_record_id,
              form_id: record.form_id,
              submit_date: record.submit_date,
              submitDate: record.submit_date,
              item_code: 'N/A',
              itemCode: 'N/A',
              item_name_cn: 'N/A',
              itemNameCN: 'N/A',
              item_name_en: 'N/A',
              itemNameEN: 'N/A',
              applicant: record.applicant_username || 'Unknown',
              applicant_name: record.applicant_username || 'Unknown',
              current_status_code: record.current_status_code,
              current_status_name: record.current_status_name,
              status_color: record.status_color,
              status_icon: record.status_icon,
              current_step_name: record.current_step_name,
              current_step_order: record.current_step_order,
              workflow_name: record.workflow_name,
              workflow_code: record.workflow_code,
              status: record.current_status_code,
              isDynamicForm: true,
              formId: record.form_id,
            }
          }
        }),
      )

      applications.value = applicationsWithData
    } catch (error) {
      console.error('載入待審核申請失敗', error)
      await swal.error('載入待審核申請失敗', error.message || '請重新整理頁面')
    } finally {
      loading.value = false
    }
  }

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

  function getStatusColor (status) {
    // 如果狀態有對應的顏色，使用它；否則使用預設顏色
    const statusMap = {
      DRAFT: 'grey',
      PENDING: 'warning',
      IN_REVIEW: 'info',
      APPROVED: 'success',
      REJECTED: 'error',
      RETURNED: 'warning',
    }
    return statusMap[status] || 'grey'
  }

  function getStatusText (status) {
    // 如果狀態有對應的文本，使用它；否則直接顯示狀態代碼
    const statusMap = {
      DRAFT: '草稿',
      PENDING: '待審核',
      IN_REVIEW: '審核中',
      APPROVED: '已核准',
      REJECTED: '已退回',
      RETURNED: '退回修改',
    }
    return statusMap[status] || status
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
        if (!approverId) {
          throw new Error('無法取得審核人資訊，請重新登入')
        }

        // 從列表中查找申請資訊
        const application = applications.value.find(app =>
          app.id === id
          || app.record_id === id
          || app.approval_record_id === id,
        )

        if (!application) {
          throw new Error('找不到申請記錄')
        }

        // 使用審核流程系統執行核准操作
        if (application.approval_record_id) {
          await approvalWorkflowsService.executeApprovalAction({
            approval_record_id: application.approval_record_id,
            action: 'APPROVE',
            approver_id: approverId,
            comment: '審核通過',
          })
          await swal.success('申請已核准！')
        } else {
          // 如果沒有審核記錄，嘗試取得
          const approvalRecord = await approvalWorkflowsService.getApprovalRecord(
            application.form_id || application.formId,
            application.record_id || application.id,
          )

          if (approvalRecord) {
            await approvalWorkflowsService.executeApprovalAction({
              approval_record_id: approvalRecord.id,
              action: 'APPROVE',
              approver_id: approverId,
              comment: '審核通過',
            })
            await swal.success('申請已核准！')
          } else {
            throw new Error('找不到審核記錄，無法執行核准操作')
          }
        }

        // 重新載入列表
        await loadPendingApplications()
      } catch (error) {
        console.error('核准申請失敗', error)
        await swal.error('核准申請失敗', error.message || '請稍後再試')
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
      if (!approverId) {
        throw new Error('無法取得審核人資訊，請重新登入')
      }

      // 從列表中查找申請資訊
      const application = applications.value.find(app =>
        app.id === rejectApplicationId.value
        || app.record_id === rejectApplicationId.value
        || app.approval_record_id === rejectApplicationId.value,
      )

      if (!application) {
        throw new Error('找不到申請記錄')
      }

      // 使用審核流程系統執行退回操作
      if (application.approval_record_id) {
        await approvalWorkflowsService.executeApprovalAction({
          approval_record_id: application.approval_record_id,
          action: 'REJECT',
          approver_id: approverId,
          reason: rejectReason.value,
          comment: rejectReason.value,
        })
        await swal.success('申請已退回！')
      } else {
        // 如果沒有審核記錄，嘗試取得
        const approvalRecord = await approvalWorkflowsService.getApprovalRecord(
          application.form_id || application.formId,
          application.record_id || application.id,
        )

        if (approvalRecord) {
          await approvalWorkflowsService.executeApprovalAction({
            approval_record_id: approvalRecord.id,
            action: 'REJECT',
            approver_id: approverId,
            reason: rejectReason.value,
            comment: rejectReason.value,
          })
          await swal.success('申請已退回！')
        } else {
          throw new Error('找不到審核記錄，無法執行退回操作')
        }
      }

      rejectDialog.value = false
      rejectReason.value = ''
      // 重新載入列表
      await loadPendingApplications()
    } catch (error) {
      console.error('退回申請失敗', error)
      await swal.error('退回申請失敗', error.message || '請稍後再試')
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
      const findFieldKeyByLabel = label => {
        const field = formFields.find(f =>
          f.field_label === label
          || f.field_label_en === label
          || f.field_label?.includes(label)
          || f.field_label_en?.includes(label),
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
      let workflowName = application.workflow_name
      let workflowCode = application.workflow_code
      let currentStepName = application.current_step_name

      if ((!workflowName && !workflowCode) && application.form_id) {
        try {
          const approvalRecord = await approvalWorkflowsService.getApprovalRecord(
            application.form_id,
            application.record_id || application.id,
          )
          if (approvalRecord?.workflow_id) {
            const workflow = await approvalWorkflowsService.getWorkflow(approvalRecord.workflow_id)
            workflowName = workflow?.workflow_name || workflowName
            workflowCode = workflow?.workflow_code || workflowCode
          }
          if (approvalRecord?.current_step_id && !currentStepName) {
            const steps = await approvalWorkflowsService.getWorkflowSteps(approvalRecord.workflow_id)
            currentStepName = steps.find(step => step.id === approvalRecord.current_step_id)?.step_name || currentStepName
          }
        } catch (error) {
          console.warn('載入審核流程資訊失敗', error)
        }
      }

      selectedApplication.value = {
        ...application,
        submitDate: application.submit_date,
        itemCode: formValues[itemCodeKey] || application.item_code,
        itemNameCN: formValues[itemNameCNKey] || application.item_name_cn,
        itemNameEN: formValues[itemNameENKey] || application.item_name_en,
        material: materialLabel || materialValue || 'N/A',
        surfaceFinish: formValues[surfaceFinishKey] || application.surface_finish,
        applicant: application.applicant_name
          || application.applicant?.username
          || 'Unknown',
        workflow_name: workflowName,
        workflow_code: workflowCode,
        current_step_name: currentStepName,
        isDynamicForm: true,
      }

      detailDialog.value = true
    } catch (error) {
      console.error('載入申請預覽失敗', error)
      await swal.error('載入申請預覽失敗，請稍後再試')
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
