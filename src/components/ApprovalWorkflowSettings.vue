<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>審核流程設定</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-tabs v-model="activeTab" bg-color="grey-lighten-4">
        <v-tab value="statuses">
          <v-icon start>mdi-flag</v-icon>
          審核狀態
        </v-tab>
        <v-tab value="workflows">
          <v-icon start>mdi-sitemap</v-icon>
          審核流程
        </v-tab>
      </v-tabs>

      <v-window v-model="activeTab">
        <!-- 審核狀態管理 -->
        <v-window-item value="statuses">
          <div class="mt-4">
            <div class="d-flex justify-space-between align-center mb-4">
              <h3>審核狀態定義</h3>
              <v-btn
                color="primary"
                @click="openStatusDialog()"
              >
                <v-icon start>mdi-plus</v-icon>
                新增狀態
              </v-btn>
            </div>

            <v-data-table
              :headers="statusHeaders"
              :items="statuses"
              :loading="loading"
              class="elevation-1"
            >
              <template v-slot:[`item.status_type`]="{ item }">
                <v-chip
                  :color="getStatusTypeColor(item.status_type)"
                  size="small"
                  variant="flat"
                >
                  {{ getStatusTypeText(item.status_type) }}
                </v-chip>
              </template>

              <template v-slot:[`item.color`]="{ item }">
                <v-chip
                  :color="item.color"
                  size="small"
                  variant="flat"
                >
                  {{ item.color }}
                </v-chip>
              </template>

              <template v-slot:[`item.is_active`]="{ item }">
                <v-chip
                  :color="item.is_active ? 'success' : 'grey'"
                  size="small"
                  variant="flat"
                >
                  {{ item.is_active ? '啟用' : '停用' }}
                </v-chip>
              </template>

              <template v-slot:[`item.actions`]="{ item }">
                <v-btn
                  icon
                  size="small"
                  variant="text"
                  @click="openStatusDialog(item)"
                >
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
                <v-btn
                  icon
                  size="small"
                  variant="text"
                  color="error"
                  @click="deleteStatus(item)"
                >
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </template>
            </v-data-table>
          </div>
        </v-window-item>

        <!-- 審核流程管理 -->
        <v-window-item value="workflows">
          <div class="mt-4">
            <div class="d-flex justify-space-between align-center mb-4">
              <h3>審核流程配置</h3>
              <v-btn
                color="primary"
                @click="openWorkflowDialog()"
              >
                <v-icon start>mdi-plus</v-icon>
                新增流程
              </v-btn>
            </div>

            <v-data-table
              :headers="workflowHeaders"
              :items="workflows"
              :loading="loading"
              class="elevation-1"
            >
              <template v-slot:[`item.form_code`]="{ item }">
                {{ item.form_code || '通用流程' }}
              </template>

              <template v-slot:[`item.is_default`]="{ item }">
                <v-chip
                  v-if="item.is_default"
                  color="primary"
                  size="small"
                  variant="flat"
                >
                  預設
                </v-chip>
              </template>

              <template v-slot:[`item.is_active`]="{ item }">
                <v-chip
                  :color="item.is_active ? 'success' : 'grey'"
                  size="small"
                  variant="flat"
                >
                  {{ item.is_active ? '啟用' : '停用' }}
                </v-chip>
              </template>

              <template v-slot:[`item.actions`]="{ item }">
                <v-btn
                  icon
                  size="small"
                  variant="text"
                  @click="openWorkflowDialog(item)"
                >
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
                <v-btn
                  icon
                  size="small"
                  variant="text"
                  color="info"
                  @click="viewWorkflowSteps(item)"
                >
                  <v-icon>mdi-eye</v-icon>
                </v-btn>
                <v-btn
                  icon
                  size="small"
                  variant="text"
                  color="error"
                  @click="deleteWorkflow(item)"
                >
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </template>
            </v-data-table>
          </div>
        </v-window-item>
      </v-window>

      <!-- 狀態編輯對話框 -->
      <v-dialog
        v-model="statusDialog"
        max-width="600"
        persistent
      >
        <v-card>
          <v-card-title>
            {{ editingStatus?.id ? '編輯狀態' : '新增狀態' }}
          </v-card-title>
          <v-card-text>
            <v-text-field
              v-model="statusForm.status_code"
              label="狀態代碼 *"
              :disabled="!!editingStatus?.id"
              variant="outlined"
              class="mb-2"
            />
            <v-text-field
              v-model="statusForm.status_name"
              label="狀態名稱（中文） *"
              variant="outlined"
              class="mb-2"
            />
            <v-text-field
              v-model="statusForm.status_name_en"
              label="狀態名稱（英文）"
              variant="outlined"
              class="mb-2"
            />
            <v-textarea
              v-model="statusForm.description"
              label="說明"
              variant="outlined"
              class="mb-2"
            />
            <v-select
              v-model="statusForm.status_type"
              :items="statusTypeOptions"
              label="狀態類型 *"
              variant="outlined"
              class="mb-2"
            />
            <v-text-field
              v-model="statusForm.color"
              label="顏色（用於 UI 顯示）"
              variant="outlined"
              class="mb-2"
            />
            <v-text-field
              v-model="statusForm.icon"
              label="圖示名稱"
              variant="outlined"
              class="mb-2"
            />
            <v-text-field
              v-model.number="statusForm.display_order"
              label="顯示順序"
              type="number"
              variant="outlined"
              class="mb-2"
            />
            <v-checkbox
              v-model="statusForm.is_active"
              label="啟用"
            />
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn @click="statusDialog = false">取消</v-btn>
            <v-btn
              color="primary"
              @click="saveStatus"
            >
              儲存
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <!-- 流程編輯對話框 -->
      <v-dialog
        v-model="workflowDialog"
        max-width="800"
        persistent
        scrollable
      >
        <v-card>
          <v-card-title>
            {{ editingWorkflow?.id ? '編輯流程' : '新增流程' }}
          </v-card-title>
          <v-card-text>
            <v-text-field
              v-model="workflowForm.workflow_code"
              label="流程代碼 *"
              :disabled="!!editingWorkflow?.id"
              variant="outlined"
              class="mb-2"
            />
            <v-text-field
              v-model="workflowForm.workflow_name"
              label="流程名稱（中文） *"
              variant="outlined"
              class="mb-2"
            />
            <v-text-field
              v-model="workflowForm.workflow_name_en"
              label="流程名稱（英文）"
              variant="outlined"
              class="mb-2"
            />
            <v-textarea
              v-model="workflowForm.description"
              label="說明"
              variant="outlined"
              class="mb-2"
            />
            <v-select
              v-model="workflowForm.initial_status_code"
              :items="statusOptions"
              label="初始狀態 *"
              variant="outlined"
              class="mb-2"
            />
            <v-select
              v-model="workflowForm.final_status_code"
              :items="finalStatusOptions"
              label="最終狀態（核准） *"
              variant="outlined"
              class="mb-2"
            />
            <v-select
              v-model="workflowForm.reject_status_code"
              :items="rejectStatusOptions"
              label="退回狀態 *"
              variant="outlined"
              class="mb-2"
            />
            <v-checkbox
              v-model="workflowForm.is_default"
              label="設為預設流程"
            />
            <v-checkbox
              v-model="workflowForm.is_active"
              label="啟用"
            />
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn @click="workflowDialog = false">取消</v-btn>
            <v-btn
              color="primary"
              @click="saveWorkflow"
            >
              儲存
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <!-- 流程步驟管理對話框 -->
      <v-dialog
        v-model="stepsDialog"
        max-width="1200"
        persistent
        scrollable
      >
        <v-card v-if="currentWorkflow">
          <v-card-title>
            流程步驟配置：{{ currentWorkflow.workflow_name }}
          </v-card-title>
          <v-card-text>
            <WorkflowFlowPreview
              :loading="loadingSteps"
              :statuses="statuses"
              :steps="workflowSteps"
              :workflow="currentWorkflow"
            />

            <div class="d-flex justify-end mb-4">
              <v-btn
                color="primary"
                @click="openStepDialog()"
              >
                <v-icon start>mdi-plus</v-icon>
                新增步驟
              </v-btn>
            </div>

            <v-data-table
              :headers="stepHeaders"
              :items="workflowSteps"
              :loading="loadingSteps"
            >
              <template v-slot:[`item.step_order`]="{ item }">
                <v-chip
                  v-if="item.is_conditional"
                  color="warning"
                  size="small"
                  variant="tonal"
                >
                  {{ formatConditionalInsertLabel(item) }}
                </v-chip>
                <span v-else>{{ item.step_order }}</span>
              </template>

              <template v-slot:[`item.is_conditional`]="{ item }">
                <v-chip
                  :color="item.is_conditional ? 'warning' : 'grey'"
                  size="small"
                  variant="flat"
                >
                  {{ item.is_conditional ? '條件型' : '一般' }}
                </v-chip>
              </template>

              <template v-slot:[`item.trigger_condition`]="{ item }">
                <span v-if="item.is_conditional">
                  {{ item.trigger_field || '-' }}
                  {{ getTriggerOperatorText(item.trigger_operator) }}
                  {{ item.trigger_value || '-' }}
                </span>
                <span v-else class="text-grey">-</span>
              </template>

              <template v-slot:[`item.approver_type`]="{ item }">
                {{ getApproverTypeText(item.approver_type) }}
              </template>

              <template v-slot:[`item.approval_departments`]="{ item }">
                <div v-if="item.approval_departments && item.approval_departments.length > 0">
                  <v-chip
                    v-for="(dept, index) in item.approval_departments"
                    :key="index"
                    size="small"
                    class="ma-1"
                    color="primary"
                    variant="outlined"
                  >
                    {{ getDepartmentLabel(dept) }}
                  </v-chip>
                </div>
                <span v-else class="text-grey">無</span>
              </template>

              <template v-slot:[`item.approver_user_ids`]="{ item }">
                <div v-if="item.approver_user_ids && item.approver_user_ids.length > 0">
                  <v-chip
                    v-for="(userId, index) in item.approver_user_ids"
                    :key="index"
                    size="small"
                    class="ma-1"
                    color="info"
                    variant="outlined"
                  >
                    {{ getUserName(userId) }}
                  </v-chip>
                </div>
                <span v-else class="text-grey">無</span>
              </template>

              <template v-slot:[`item.actions`]="{ item }">
                <v-btn
                  icon
                  size="small"
                  variant="text"
                  @click="openStepDialog(item)"
                >
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
                <v-btn
                  icon
                  size="small"
                  variant="text"
                  color="error"
                  @click="deleteStep(item)"
                >
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </template>
            </v-data-table>
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn @click="stepsDialog = false">關閉</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <!-- 步驟編輯對話框 -->
      <v-dialog
        v-model="stepDialog"
        max-width="900"
        persistent
        scrollable
      >
        <v-card>
          <v-card-title>
            {{ editingStep?.id ? '編輯步驟' : '新增步驟' }}
          </v-card-title>
          <v-card-text>
            <v-row align="center" class="mb-2">
              <v-col>
                <v-text-field
                  v-if="!stepForm.is_conditional"
                  v-model.number="stepForm.step_order"
                  label="步驟順序 *"
                  type="number"
                  variant="outlined"
                  hide-details="auto"
                />
                <v-select
                  v-else
                  v-model="stepForm.trigger_insert_order"
                  :items="conditionalInsertOptions"
                  label="插入位置 *"
                  variant="outlined"
                  hint="表示介於流程步驟之間的觸發程序，例如 1 → 2"
                  hide-details="auto"
                />
              </v-col>
              <v-col cols="auto">
                <v-switch
                  v-model="stepForm.is_conditional"
                  color="primary"
                  hide-details
                  label="條件型流程"
                  @update:model-value="onConditionalToggle"
                />
              </v-col>
            </v-row>

            <template v-if="stepForm.is_conditional">
              <v-select
                v-model="stepForm.trigger_field"
                :items="triggerFieldOptions"
                label="觸發欄位 *"
                variant="outlined"
                class="mb-2"
                hint="當表單欄位符合條件時，插入此審核步驟"
                hide-details="auto"
              />
              <v-row class="mb-2">
                <v-col cols="12" sm="4">
                  <v-select
                    v-model="stepForm.trigger_operator"
                    :items="triggerOperatorOptions"
                    label="觸發運算 *"
                    variant="outlined"
                    hide-details="auto"
                  />
                </v-col>
                <v-col cols="12" sm="8">
                  <v-text-field
                    v-model="stepForm.trigger_value"
                    label="觸發值 *"
                    variant="outlined"
                    hint="例如：更新資料庫"
                    hide-details="auto"
                  />
                </v-col>
              </v-row>
            </template>

            <v-text-field
              v-model="stepForm.step_name"
              label="步驟名稱 *"
              variant="outlined"
              class="mb-2"
              hide-details="auto"
            />
            <v-text-field
              v-model="stepForm.step_name_en"
              label="步驟名稱（英文）"
              variant="outlined"
              class="mb-2"
              hide-details="auto"
            />
            <v-textarea
              v-model="stepForm.description"
              label="說明"
              variant="outlined"
              class="mb-2"
              hide-details="auto"
            />
            <v-select
              v-model="stepForm.status_code"
              :items="statusOptions"
              label="當前單據狀態 *"
              variant="outlined"
              class="mb-2"
              hint="此步驟執行時單據的狀態"
              hide-details="auto"
            />
            <v-select
              v-model="stepForm.approver_type"
              :items="approverTypeOptions"
              label="審核人類型 *"
              variant="outlined"
              class="mb-2"
              hide-details="auto"
              @update:model-value="onApproverTypeChange"
            />
            <div v-if="stepForm.approver_type === 'USER'">
              <v-combobox
                v-model="stepForm.user_ids"
                :items="userOptions"
                label="選擇審核人 *"
                multiple
                chips
                variant="outlined"
                class="mb-2"
                hide-details="auto"
              />
            </div>
            <div v-if="stepForm.approver_type === 'ROLE'">
              <v-select
                v-model="stepForm.role"
                :items="roleOptions"
                label="選擇角色 *"
                variant="outlined"
                class="mb-2"
                hide-details="auto"
              />
            </div>
            <div v-if="stepForm.approver_type === 'DEPARTMENT'">
              <v-select
                v-model="stepForm.department"
                :items="departmentOptions"
                label="選擇部門 *"
                variant="outlined"
                class="mb-2"
                hide-details="auto"
              />
            </div>
            
            <!-- 審核權限部門 + 指定審核人（同一行） -->
            <v-row class="mb-2">
              <v-col cols="12" sm="6">
                <v-select
                  v-model="stepForm.approval_departments"
                  :items="departmentOptions"
                  label="審核權限部門（可選）"
                  multiple
                  chips
                  variant="outlined"
                  :hint="stepForm.approver_type === 'USER' ? '部門與指定審核人可一起篩選可審核的使用者' : '可指定審核權限部門，會與審核人類型一起生效'"
                  hide-details="auto"
                />
              </v-col>
              <v-col cols="12" sm="6">
                <v-combobox
                  v-model="stepForm.approver_user_ids"
                  :items="userOptions"
                  label="指定審核人（可選）"
                  multiple
                  chips
                  variant="outlined"
                  :hint="stepForm.approver_type === 'USER' ? '進一步篩選可審核的使用者' : '直接指定可審核的使用者'"
                  hide-details="auto"
                />
              </v-col>
            </v-row>
            <v-row class="mb-2">
              <v-col cols="12" sm="6">
                <v-select
                  v-model="stepForm.approve_status_code"
                  :items="statusOptions"
                  label="審核通過狀態 *"
                  variant="outlined"
                  hint="審核通過時，單據要設定的狀態"
                  hide-details="auto"
                />
              </v-col>
              <v-col cols="12" sm="6">
                <v-select
                  v-model="stepForm.reject_status_code"
                  :items="statusOptions"
                  label="退回狀態 *"
                  variant="outlined"
                  hint="退回時，單據要設定的狀態"
                  hide-details="auto"
                />
              </v-col>
            </v-row>
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn @click="stepDialog = false">取消</v-btn>
            <v-btn
              color="primary"
              @click="saveStep"
            >
              儲存
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-card-text>
  </v-card>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { approvalWorkflowsService } from '@/api/services/approvalWorkflows'
import { formsService } from '@/api/services/forms'
import { systemOptionsService } from '@/api/services/systemOptions'
import { usersService } from '@/api/services/users'
import { useSwal } from '@/composables/useSwal'
import WorkflowFlowPreview from '@/components/WorkflowFlowPreview.vue'

const swal = useSwal()

const activeTab = ref('statuses')
const loading = ref(false)
const loadingSteps = ref(false)

// 狀態管理
const statuses = ref([])
const statusDialog = ref(false)
const editingStatus = ref(null)
const statusForm = ref({
  status_code: '',
  status_name: '',
  status_name_en: '',
  description: '',
  status_type: 'INTERMEDIATE',
  color: 'grey',
  icon: '',
  display_order: 0,
  is_active: true,
})

const statusHeaders = [
  { title: '狀態代碼', key: 'status_code' },
  { title: '狀態名稱', key: 'status_name' },
  { title: '類型', key: 'status_type' },
  { title: '顏色', key: 'color' },
  { title: '順序', key: 'display_order' },
  { title: '狀態', key: 'is_active' },
  { title: '操作', key: 'actions', sortable: false },
]

const statusTypeOptions = [
  { title: '初始狀態', value: 'INITIAL' },
  { title: '中間狀態', value: 'INTERMEDIATE' },
  { title: '最終狀態', value: 'FINAL' },
]

// 流程管理
const workflows = ref([])
const workflowDialog = ref(false)
const editingWorkflow = ref(null)
const workflowForm = ref({
  workflow_code: '',
  workflow_name: '',
  workflow_name_en: '',
  description: '',
  initial_status_code: 'PENDING',
  final_status_code: 'APPROVED',
  reject_status_code: 'REJECTED',
  is_default: false,
  is_active: true,
})

const workflowHeaders = [
  { title: '流程代碼', key: 'workflow_code' },
  { title: '流程名稱', key: 'workflow_name' },
  { title: '預設', key: 'is_default' },
  { title: '狀態', key: 'is_active' },
  { title: '操作', key: 'actions', sortable: false },
]

// 步驟管理
const stepsDialog = ref(false)
const stepDialog = ref(false)
const currentWorkflow = ref(null)
const workflowSteps = ref([])
const editingStep = ref(null)
const stepForm = ref({
  step_order: 1,
  is_conditional: false,
  trigger_insert_order: 0,
  trigger_field: '',
  trigger_operator: 'equals',
  trigger_value: '',
  step_name: '',
  step_name_en: '',
  description: '',
  status_code: 'PENDING',
  approver_type: 'USER',
  approver_config: {},
  approval_departments: [], // 審核權限部門列表
  approver_user_ids: [], // 審核人 ID 列表
  approve_status_code: 'APPROVED', // 審核通過狀態
  reject_status_code: 'REJECTED', // 退回狀態
  user_ids: [],
  role: null,
  department: null,
})

const stepHeaders = [
  { title: '順序 / 插入點', key: 'step_order' },
  { title: '類型', key: 'is_conditional' },
  { title: '步驟名稱', key: 'step_name' },
  { title: '觸發條件', key: 'trigger_condition' },
  { title: '狀態', key: 'status_code' },
  { title: '審核人類型', key: 'approver_type' },
  { title: '審核權限部門', key: 'approval_departments' },
  { title: '審核人', key: 'approver_user_ids' },
  { title: '操作', key: 'actions', sortable: false },
]

const approverTypeOptions = [
  { title: '指定使用者', value: 'USER' },
  { title: '指定角色', value: 'ROLE' },
  { title: '指定部門', value: 'DEPARTMENT' },
  { title: '自動通過', value: 'AUTO' },
]

const triggerOperatorOptions = [
  { title: '等於', value: 'equals' },
  { title: '不等於', value: 'not_equals' },
  { title: '包含', value: 'contains' },
  { title: '不包含', value: 'not_contains' },
  { title: '開頭為', value: 'starts_with' },
  { title: '結尾為', value: 'ends_with' },
]

const userOptions = ref([])
const triggerFieldOptions = ref([])
const departmentOptions = ref([])
const roleOptions = [
  { title: '系統管理員', value: 'admin' },
  { title: '審核人員', value: 'approver' },
  { title: '申請人員', value: 'applicant' },
]

const statusOptions = computed(() => {
  return statuses.value
    .filter(s => s.is_active)
    .map(s => ({
      title: `${s.status_name} (${s.status_code})`,
      value: s.status_code,
    }))
})

const finalStatusOptions = computed(() => {
  return statuses.value
    .filter(s => s.is_active && s.status_type === 'FINAL')
    .map(s => ({
      title: `${s.status_name} (${s.status_code})`,
      value: s.status_code,
    }))
})

const rejectStatusOptions = computed(() => {
  return statuses.value
    .filter(s => s.is_active && (s.status_type === 'FINAL' || s.status_code === 'REJECTED' || s.status_code === 'RETURNED'))
    .map(s => ({
      title: `${s.status_name} (${s.status_code})`,
      value: s.status_code,
    }))
})

const regularWorkflowSteps = computed(() => {
  return workflowSteps.value
    .filter(step => !step.is_conditional)
    .sort((a, b) => a.step_order - b.step_order)
})

const conditionalInsertOptions = computed(() => {
  const options = [{ title: '0 → 1', value: 0 }]

  regularWorkflowSteps.value.forEach(step => {
    options.push({
      title: `${step.step_order} → ${step.step_order + 1}`,
      value: step.step_order,
    })
  })

  return options
})

// 載入資料
async function loadStatuses () {
  loading.value = true
  try {
    statuses.value = await approvalWorkflowsService.getApprovalStatuses()
  } catch (error) {
    console.error('載入狀態失敗', error)
    await swal.error('載入狀態失敗', error.message)
  } finally {
    loading.value = false
  }
}

async function loadWorkflows () {
  loading.value = true
  try {
    workflows.value = await approvalWorkflowsService.getWorkflows({ is_active: undefined })
  } catch (error) {
    console.error('載入流程失敗', error)
    await swal.error('載入流程失敗', error.message)
  } finally {
    loading.value = false
  }
}

async function loadDepartments () {
  try {
    const departments = await systemOptionsService.getOptions('approval_workflow', 'department')
    departmentOptions.value = departments.map(d => ({
      title: d.label || d.value,
      value: d.key || d.value,
    }))
  } catch (error) {
    console.error('載入部門選項失敗', error)
  }
}

async function loadUsers () {
  try {
    const users = await usersService.getUsers({ is_active: true })
    userOptions.value = users.map(u => ({
      title: u.username || u.id,
      value: u.id,
    }))
  } catch (error) {
    console.error('載入使用者失敗', error)
  }
}

async function loadTriggerFieldOptions () {
  try {
    const forms = await formsService.getForms({ is_active: true })
    const defaultForm = forms.find(form => form.is_default) || forms[0]
    if (!defaultForm) {
      triggerFieldOptions.value = []
      return
    }

    const form = await formsService.getForm(defaultForm.id, true)
    triggerFieldOptions.value = (form.fields || [])
      .filter(field => field.field_key && !['status', 'approval_status'].includes(field.field_key))
      .map(field => ({
        title: `${field.field_label || field.field_key} (${field.field_key})`,
        value: field.field_key,
      }))
  } catch (error) {
    console.error('載入觸發欄位選項失敗', error)
    triggerFieldOptions.value = []
  }
}

async function loadWorkflowSteps (workflowId) {
  loadingSteps.value = true
  try {
    workflowSteps.value = await approvalWorkflowsService.getWorkflowSteps(workflowId)
  } catch (error) {
    console.error('載入步驟失敗', error)
    await swal.error('載入步驟失敗', error.message)
  } finally {
    loadingSteps.value = false
  }
}

// 狀態操作
function openStatusDialog (status = null) {
  editingStatus.value = status
  if (status) {
    statusForm.value = { ...status }
  } else {
    statusForm.value = {
      status_code: '',
      status_name: '',
      status_name_en: '',
      description: '',
      status_type: 'INTERMEDIATE',
      color: 'grey',
      icon: '',
      display_order: 0,
      is_active: true,
    }
  }
  statusDialog.value = true
}

async function saveStatus () {
  try {
    if (editingStatus.value?.id) {
      await approvalWorkflowsService.updateApprovalStatus(
        editingStatus.value.status_code,
        statusForm.value
      )
    } else {
      await approvalWorkflowsService.createApprovalStatus(statusForm.value)
    }
    await swal.success('狀態已儲存！')
    statusDialog.value = false
    await loadStatuses()
  } catch (error) {
    console.error('儲存狀態失敗', error)
    await swal.error('儲存狀態失敗', error.message)
  }
}

async function deleteStatus (status) {
  const result = await swal.confirm(`確定要刪除狀態「${status.status_name}」嗎？`, '確認刪除')
  if (result.isConfirmed) {
    try {
      await approvalWorkflowsService.deleteApprovalStatus(status.status_code)
      await swal.success('狀態已刪除！')
      await loadStatuses()
    } catch (error) {
      console.error('刪除狀態失敗', error)
      await swal.error('刪除狀態失敗', error.message)
    }
  }
}

// 流程操作
function openWorkflowDialog (workflow = null) {
  editingWorkflow.value = workflow
  if (workflow) {
    // 移除 form_code 和 form_id（如果存在）
    const { form_code, form_id, ...rest } = workflow
    workflowForm.value = { ...rest }
  } else {
    workflowForm.value = {
      workflow_code: '',
      workflow_name: '',
      workflow_name_en: '',
      description: '',
      initial_status_code: 'PENDING',
      final_status_code: 'APPROVED',
      reject_status_code: 'REJECTED',
      is_default: false,
      is_active: true,
    }
  }
  workflowDialog.value = true
}

async function saveWorkflow () {
  try {
    const data = { ...workflowForm.value }
    
    // 移除 form_code 和 form_id（不再使用）
    delete data.form_code
    delete data.form_id

    if (editingWorkflow.value?.id) {
      await approvalWorkflowsService.updateWorkflow(editingWorkflow.value.id, data)
    } else {
      await approvalWorkflowsService.createWorkflow(data)
    }
    await swal.success('流程已儲存！')
    workflowDialog.value = false
    await loadWorkflows()
  } catch (error) {
    console.error('儲存流程失敗', error)
    await swal.error('儲存流程失敗', error.message)
  }
}

async function deleteWorkflow (workflow) {
  const result = await swal.confirm(`確定要刪除流程「${workflow.workflow_name}」嗎？`, '確認刪除')
  if (result.isConfirmed) {
    try {
      await approvalWorkflowsService.deleteWorkflow(workflow.id)
      await swal.success('流程已刪除！')
      await loadWorkflows()
    } catch (error) {
      console.error('刪除流程失敗', error)
      await swal.error('刪除流程失敗', error.message)
    }
  }
}

async function viewWorkflowSteps (workflow) {
  currentWorkflow.value = workflow
  await Promise.all([
    loadWorkflowSteps(workflow.id),
    loadTriggerFieldOptions(),
  ])
  stepsDialog.value = true
}

function formatConditionalInsertLabel (step) {
  const insertOrder = step.trigger_insert_order ?? 0
  return `${insertOrder} → ${insertOrder + 1}`
}

function computeConditionalStepOrder (triggerInsertOrder, excludeStepId = null) {
  const samePointSteps = workflowSteps.value.filter(step =>
    step.is_conditional
    && step.trigger_insert_order === triggerInsertOrder
    && step.id !== excludeStepId
  )
  const sequence = samePointSteps.length + 1
  return 10000 + (triggerInsertOrder * 100) + sequence
}

function getNextRegularStepOrder () {
  const regularSteps = workflowSteps.value.filter(step => !step.is_conditional)
  if (regularSteps.length === 0) {
    return 1
  }
  return Math.max(...regularSteps.map(step => step.step_order)) + 1
}

// 步驟操作
async function openStepDialog (step = null) {
  editingStep.value = step
  if (step) {
    stepForm.value = {
      ...step,
      is_conditional: !!step.is_conditional,
      trigger_insert_order: step.trigger_insert_order ?? 0,
      trigger_field: step.trigger_field || '',
      trigger_operator: step.trigger_operator || 'equals',
      trigger_value: step.trigger_value || '',
      user_ids: step.approver_config?.user_ids || [],
      role: step.approver_config?.role || null,
      department: step.approver_config?.department || null,
      approval_departments: step.approval_departments || [],
      approver_user_ids: step.approver_user_ids || [],
      approve_status_code: step.approve_status_code || 'APPROVED',
      reject_status_code: step.reject_status_code || 'REJECTED',
    }
  } else {
    stepForm.value = {
      step_order: getNextRegularStepOrder(),
      is_conditional: false,
      trigger_insert_order: 0,
      trigger_field: '',
      trigger_operator: 'equals',
      trigger_value: '',
      step_name: '',
      step_name_en: '',
      description: '',
      status_code: 'PENDING',
      approver_type: 'USER',
      approver_config: {},
      approval_departments: [],
      approver_user_ids: [],
      approve_status_code: 'APPROVED',
      reject_status_code: 'REJECTED',
      user_ids: [],
      role: null,
      department: null,
    }
  }
  stepDialog.value = true
  if (triggerFieldOptions.value.length === 0) {
    await loadTriggerFieldOptions()
  }
}

function onConditionalToggle (enabled) {
  if (enabled) {
    stepForm.value.trigger_insert_order = stepForm.value.trigger_insert_order ?? 0
    return
  }

  if (!stepForm.value.step_order) {
    stepForm.value.step_order = getNextRegularStepOrder()
  }
}

function onApproverTypeChange () {
  // 清空配置
  stepForm.value.user_ids = []
  stepForm.value.role = null
  stepForm.value.department = null
}

async function saveStep () {
  try {
    if (stepForm.value.is_conditional) {
      if (stepForm.value.trigger_insert_order === null || stepForm.value.trigger_insert_order === undefined) {
        await swal.error('請選擇插入位置')
        return
      }
      if (!stepForm.value.trigger_field) {
        await swal.error('請選擇觸發欄位')
        return
      }
      if (!stepForm.value.trigger_operator) {
        await swal.error('請選擇觸發運算')
        return
      }
      if (!stepForm.value.trigger_value) {
        await swal.error('請輸入觸發值')
        return
      }
    }

    const data = {
      workflow_id: currentWorkflow.value.id,
      step_name: stepForm.value.step_name,
      step_name_en: stepForm.value.step_name_en,
      description: stepForm.value.description,
      status_code: stepForm.value.status_code,
      approver_type: stepForm.value.approver_type,
      approval_departments: stepForm.value.approval_departments || [],
      approver_user_ids: stepForm.value.approver_user_ids || [],
      approve_status_code: stepForm.value.approve_status_code,
      reject_status_code: stepForm.value.reject_status_code,
      is_conditional: !!stepForm.value.is_conditional,
      trigger_insert_order: stepForm.value.is_conditional ? stepForm.value.trigger_insert_order : null,
      trigger_field: stepForm.value.is_conditional ? stepForm.value.trigger_field : null,
      trigger_value: stepForm.value.is_conditional ? stepForm.value.trigger_value : null,
      trigger_operator: stepForm.value.is_conditional ? stepForm.value.trigger_operator : null,
    }

    if (stepForm.value.is_conditional) {
      data.step_order = computeConditionalStepOrder(
        stepForm.value.trigger_insert_order,
        editingStep.value?.id || null
      )
    } else {
      data.step_order = stepForm.value.step_order
    }

    // 根據審核人類型設定配置
    if (stepForm.value.approver_type === 'USER') {
      data.approver_config = { user_ids: stepForm.value.user_ids }
    } else if (stepForm.value.approver_type === 'ROLE') {
      data.approver_config = { role: stepForm.value.role }
    } else if (stepForm.value.approver_type === 'DEPARTMENT') {
      data.approver_config = { department: stepForm.value.department }
    } else {
      data.approver_config = {}
    }

    if (editingStep.value?.id) {
      await approvalWorkflowsService.updateWorkflowStep(editingStep.value.id, data)
    } else {
      await approvalWorkflowsService.createWorkflowStep(data)
    }
    await swal.success('步驟已儲存！')
    stepDialog.value = false
    await loadWorkflowSteps(currentWorkflow.value.id)
  } catch (error) {
    console.error('儲存步驟失敗', error)
    await swal.error('儲存步驟失敗', error.message)
  }
}

async function deleteStep (step) {
  const result = await swal.confirm(`確定要刪除步驟「${step.step_name}」嗎？`, '確認刪除')
  if (result.isConfirmed) {
    try {
      await approvalWorkflowsService.deleteWorkflowStep(step.id)
      await swal.success('步驟已刪除！')
      await loadWorkflowSteps(currentWorkflow.value.id)
    } catch (error) {
      console.error('刪除步驟失敗', error)
      await swal.error('刪除步驟失敗', error.message)
    }
  }
}

function getStatusTypeColor (type) {
  const colors = {
    INITIAL: 'grey',
    INTERMEDIATE: 'info',
    FINAL: 'success',
  }
  return colors[type] || 'grey'
}

function getStatusTypeText (type) {
  const texts = {
    INITIAL: '初始狀態',
    INTERMEDIATE: '中間狀態',
    FINAL: '最終狀態',
  }
  return texts[type] || type
}

function getApproverTypeText (type) {
  const texts = {
    USER: '指定使用者',
    ROLE: '指定角色',
    DEPARTMENT: '指定部門',
    AUTO: '自動通過',
  }
  return texts[type] || type
}

function getTriggerOperatorText (operator) {
  const option = triggerOperatorOptions.find(item => item.value === operator)
  return option?.title || operator || '等於'
}

function getDepartmentLabel (deptKey) {
  const dept = departmentOptions.value.find(d => d.value === deptKey)
  return dept ? dept.title : deptKey
}

function getUserName (userId) {
  const user = userOptions.value.find(u => u.value === userId)
  return user ? user.title : userId
}

onMounted(async () => {
  await Promise.all([
    loadStatuses(),
    loadWorkflows(),
    loadDepartments(),
    loadUsers(),
    loadTriggerFieldOptions(),
  ])
})
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

h3 {
  color: #667eea;
  margin-bottom: 16px;
  font-size: 1.2em;
}
</style>
