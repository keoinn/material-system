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
              <div class="d-flex align-center" style="gap: 8px;">
                <v-btn
                  color="primary"
                  prepend-icon="mdi-code-json"
                  variant="outlined"
                  @click="openStatusesJsonDialog"
                >
                  JSON 配置
                </v-btn>
                <v-btn
                  color="primary"
                  @click="openStatusDialog()"
                >
                  <v-icon start>mdi-plus</v-icon>
                  新增狀態
                </v-btn>
              </div>
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
              <template v-slot:[`item.form_codes`]="{ item }">
                {{ formatWorkflowFormCodes(item.form_codes) }}
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

      <!-- 審核狀態 JSON 配置對話框 -->
      <v-dialog
        v-model="statusesJsonDialog"
        max-width="960"
        persistent
        scrollable
      >
        <v-card>
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-code-json</v-icon>
            審核狀態 JSON 配置
            <v-spacer />
            <v-btn
              icon
              variant="text"
              @click="closeStatusesJsonDialog"
            >
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-card-title>
          <v-card-text>
            <div
              class="statuses-json-editor-pane"
              :class="{ 'statuses-json-editor-pane--error': statusesJsonDraftError }"
            >
              <JsonCodeEditor v-model="statusesJsonDraft" />
            </div>
            <div
              v-if="statusesJsonDraftError"
              class="text-error text-caption mt-2"
            >
              JSON 格式錯誤，請檢查語法
            </div>
            <v-alert
              class="mt-4"
              type="info"
              variant="tonal"
            >
              可編輯審核狀態陣列；套用後會依「狀態代碼」更新或新增，不會自動刪除未列出的狀態。
            </v-alert>
          </v-card-text>
          <v-divider />
          <v-card-actions class="pa-4">
            <v-btn
              prepend-icon="mdi-format-align-left"
              variant="text"
              @click="formatStatusesJsonDraft"
            >
              格式化
            </v-btn>
            <v-btn
              prepend-icon="mdi-content-copy"
              variant="text"
              @click="copyStatusesJson"
            >
              複製
            </v-btn>
            <v-spacer />
            <v-btn
              variant="text"
              @click="revertStatusesJsonDraft"
            >
              回到初始狀態
            </v-btn>
            <v-btn
              variant="text"
              @click="closeStatusesJsonDialog"
            >
              取消
            </v-btn>
            <v-btn
              color="primary"
              :disabled="statusesJsonDraftError"
              :loading="statusesJsonSaving"
              variant="flat"
              @click="applyStatusesJson"
            >
              套用
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

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
            <v-combobox
              v-model="workflowForm.form_codes"
              :items="formCodeOptions"
              item-title="title"
              item-value="value"
              label="套用流程的表單"
              hint="可選多個表單代碼；留空表示通用流程（所有表單）"
              persistent-hint
              multiple
              chips
              closable-chips
              clearable
              variant="outlined"
              class="mb-2"
              @update:model-value="onWorkflowFormCodesChange"
            >
              <template #chip="{ props, item }">
                <v-chip
                  v-bind="props"
                  :text="getFormCodeOptionLabel(typeof item === 'string' ? item : (item.value ?? item.raw?.value ?? item.title))"
                />
              </template>
            </v-combobox>
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
            <v-btn
              prepend-icon="mdi-code-json"
              variant="text"
              :loading="loadingWorkflowFormSteps"
              @click="openWorkflowJsonDialog"
            >
              JSON 配置
            </v-btn>
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

      <!-- 流程 JSON 配置對話框 -->
      <v-dialog
        v-model="workflowJsonDialog"
        max-width="960"
        persistent
        scrollable
      >
        <v-card>
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-code-json</v-icon>
            流程 JSON 配置
            <v-spacer />
            <v-btn
              icon
              variant="text"
              @click="closeWorkflowJsonDialog"
            >
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-card-title>
          <v-card-text>
            <div
              class="statuses-json-editor-pane"
              :class="{ 'statuses-json-editor-pane--error': workflowJsonDraftError }"
            >
              <JsonCodeEditor v-model="workflowJsonDraft" />
            </div>
            <div
              v-if="workflowJsonDraftError"
              class="text-error text-caption mt-2"
            >
              JSON 格式錯誤，請檢查語法
            </div>
            <v-alert
              class="mt-4"
              type="info"
              variant="tonal"
            >
              可編輯流程物件（含 id、steps）；若 workflow_code 或 id 對應既有流程，套用/儲存時會更新而非新增。未列在 steps 的既有步驟不會自動刪除。
            </v-alert>
          </v-card-text>
          <v-divider />
          <v-card-actions class="pa-4">
            <v-btn
              prepend-icon="mdi-format-align-left"
              variant="text"
              @click="formatWorkflowJsonDraft"
            >
              格式化
            </v-btn>
            <v-btn
              prepend-icon="mdi-content-copy"
              variant="text"
              @click="copyWorkflowJson"
            >
              複製
            </v-btn>
            <v-spacer />
            <v-btn
              variant="text"
              @click="revertWorkflowJsonDraft"
            >
              回到初始狀態
            </v-btn>
            <v-btn
              variant="text"
              @click="closeWorkflowJsonDialog"
            >
              取消
            </v-btn>
            <v-btn
              color="primary"
              :disabled="workflowJsonDraftError"
              variant="flat"
              @click="applyWorkflowJson"
            >
              套用
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

            <div class="d-flex justify-end mb-4" style="gap: 8px;">
              <v-btn
                color="primary"
                prepend-icon="mdi-code-json"
                variant="outlined"
                @click="openStepsJsonDialog"
              >
                JSON 配置
              </v-btn>
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

      <!-- 流程步驟 JSON 配置對話框 -->
      <v-dialog
        v-model="stepsJsonDialog"
        max-width="960"
        persistent
        scrollable
      >
        <v-card v-if="currentWorkflow">
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-code-json</v-icon>
            流程步驟 JSON 配置：{{ currentWorkflow.workflow_name }}
            <v-spacer />
            <v-btn
              icon
              variant="text"
              @click="closeStepsJsonDialog"
            >
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-card-title>
          <v-card-text>
            <div
              class="statuses-json-editor-pane"
              :class="{ 'statuses-json-editor-pane--error': stepsJsonDraftError }"
            >
              <JsonCodeEditor v-model="stepsJsonDraft" />
            </div>
            <div
              v-if="stepsJsonDraftError"
              class="text-error text-caption mt-2"
            >
              JSON 格式錯誤，請檢查語法
            </div>
            <v-alert
              class="mt-4"
              type="info"
              variant="tonal"
            >
              可編輯流程步驟陣列；套用後會依「id」更新既有步驟，無 id 則新增，不會自動刪除未列出的步驟。條件型步驟請填寫 trigger_insert_order 等欄位，step_order 會自動計算。
            </v-alert>
          </v-card-text>
          <v-divider />
          <v-card-actions class="pa-4">
            <v-btn
              prepend-icon="mdi-format-align-left"
              variant="text"
              @click="formatStepsJsonDraft"
            >
              格式化
            </v-btn>
            <v-btn
              prepend-icon="mdi-content-copy"
              variant="text"
              @click="copyStepsJson"
            >
              複製
            </v-btn>
            <v-spacer />
            <v-btn
              variant="text"
              @click="revertStepsJsonDraft"
            >
              回到初始狀態
            </v-btn>
            <v-btn
              variant="text"
              @click="closeStepsJsonDialog"
            >
              取消
            </v-btn>
            <v-btn
              color="primary"
              :disabled="stepsJsonDraftError"
              :loading="stepsJsonSaving"
              variant="flat"
              @click="applyStepsJson"
            >
              套用
            </v-btn>
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
                v-model="stepForm.approver_user_ids"
                :items="userOptions"
                item-title="title"
                item-value="value"
                label="指定審核人 *"
                multiple
                chips
                closable-chips
                clearable
                variant="outlined"
                class="mb-2"
                hint="選擇可審核此步驟的使用者"
                persistent-hint
                hide-details="auto"
                @update:model-value="onStepApproverUserIdsChange"
              >
                <template #chip="{ props, item }">
                  <v-chip
                    v-bind="props"
                    :text="getUserOptionLabel(typeof item === 'string' ? item : (item.value ?? item.raw?.value ?? item.title))"
                  />
                </template>
              </v-combobox>
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
                  v-if="stepForm.approver_type !== 'USER'"
                  v-model="stepForm.approver_user_ids"
                  :items="userOptions"
                  item-title="title"
                  item-value="value"
                  label="指定審核人（可選）"
                  multiple
                  chips
                  closable-chips
                  clearable
                  variant="outlined"
                  :hint="'直接指定可審核的使用者'"
                  hide-details="auto"
                  @update:model-value="onStepApproverUserIdsChange"
                >
                  <template #chip="{ props, item }">
                    <v-chip
                      v-bind="props"
                      :text="getUserOptionLabel(typeof item === 'string' ? item : (item.value ?? item.raw?.value ?? item.title))"
                    />
                  </template>
                </v-combobox>
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
import { computed, onMounted, ref, watch } from 'vue'
import { approvalWorkflowsService } from '@/api/services/approvalWorkflows'
import { formsService } from '@/api/services/forms'
import { systemOptionsService } from '@/api/services/systemOptions'
import { usersService } from '@/api/services/users'
import { useSwal } from '@/composables/useSwal'
import JsonCodeEditor from '@/components/JsonCodeEditor.vue'
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

const VALID_STATUS_TYPES = new Set(['INITIAL', 'INTERMEDIATE', 'FINAL'])

const statusesJsonDialog = ref(false)
const statusesJsonDraft = ref('')
const statusesJsonDraftError = ref(false)
const statusesJsonSaving = ref(false)

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
  form_codes: [],
  is_default: false,
  is_active: true,
})

const formCodeOptions = ref([])

const workflowJsonDialog = ref(false)
const workflowJsonDraft = ref('')
const workflowJsonDraftError = ref(false)
const workflowFormSteps = ref([])
const loadingWorkflowFormSteps = ref(false)

const workflowHeaders = [
  { title: '流程代碼', key: 'workflow_code' },
  { title: '流程名稱', key: 'workflow_name' },
  { title: '套用表單', key: 'form_codes' },
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

const VALID_APPROVER_TYPES = new Set(['USER', 'ROLE', 'DEPARTMENT', 'AUTO'])
const VALID_TRIGGER_OPERATORS = new Set(triggerOperatorOptions.map(option => option.value))
const DEFAULT_TRIGGER_OPERATOR = 'equals'

function normalizeStepForPersist (data) {
  const normalized = { ...data }
  if (normalized.is_conditional) {
    normalized.trigger_operator = normalized.trigger_operator || DEFAULT_TRIGGER_OPERATOR
  } else {
    normalized.trigger_insert_order = null
    normalized.trigger_field = null
    normalized.trigger_value = null
    normalized.trigger_operator = DEFAULT_TRIGGER_OPERATOR
  }
  return normalized
}

const stepsJsonDialog = ref(false)
const stepsJsonDraft = ref('')
const stepsJsonDraftError = ref(false)
const stepsJsonSaving = ref(false)

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

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function extractUserId (value) {
  if (value == null) return ''
  if (typeof value === 'string') {
    const trimmed = value.trim()
    if (!trimmed) return ''
    if (UUID_PATTERN.test(trimmed)) return trimmed
    const byTitle = userOptions.value.find(option => option.title === trimmed)
    if (byTitle) return byTitle.value
    const byValue = userOptions.value.find(option => option.value === trimmed)
    return byValue?.value || ''
  }
  if (typeof value === 'object') {
    if (value.value) return String(value.value)
    if (value.id) return String(value.id)
    if (value.title) {
      const byTitle = userOptions.value.find(option => option.title === value.title)
      return byTitle?.value || ''
    }
  }
  return ''
}

function normalizeUserIds (userIds) {
  if (!Array.isArray(userIds)) return []
  return [...new Set(userIds.map(extractUserId).filter(Boolean))]
}

function getUserOptionLabel (userId) {
  const option = userOptions.value.find(item => item.value === userId)
  return option?.title || userId
}

function mergeStepApproverUserIds (step) {
  return normalizeUserIds([
    ...(step?.approver_user_ids || []),
    ...(step?.approver_config?.user_ids || []),
  ])
}

function onStepApproverUserIdsChange (value) {
  stepForm.value.approver_user_ids = normalizeUserIds(value)
  stepForm.value.user_ids = [...stepForm.value.approver_user_ids]
}

async function loadTriggerFieldOptions () {
  try {
    const forms = await formsService.getForms({ is_active: true })
    const defaultForm = forms.toSorted((a, b) =>
      (a.form_name || '').localeCompare(b.form_name || '', 'zh-Hant'),
    )[0]
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

function buildStatusPayload (raw) {
  return {
    status_code: String(raw.status_code || '').trim(),
    status_name: String(raw.status_name || '').trim(),
    status_name_en: raw.status_name_en ? String(raw.status_name_en).trim() : '',
    description: raw.description ? String(raw.description).trim() : '',
    status_type: raw.status_type || 'INTERMEDIATE',
    color: raw.color || 'grey',
    icon: raw.icon ? String(raw.icon).trim() : '',
    display_order: Number(raw.display_order) || 0,
    is_active: raw.is_active !== false,
  }
}

function buildStatusesSnapshot () {
  return statuses.value.map(status => buildStatusPayload(status))
}

function syncStatusesJsonDraft () {
  statusesJsonDraft.value = JSON.stringify(buildStatusesSnapshot(), null, 2)
  statusesJsonDraftError.value = false
}

function openStatusesJsonDialog () {
  syncStatusesJsonDraft()
  statusesJsonDialog.value = true
}

function closeStatusesJsonDialog () {
  statusesJsonDialog.value = false
}

function revertStatusesJsonDraft () {
  syncStatusesJsonDraft()
}

function validateStatusesJsonDraft () {
  if (!statusesJsonDraft.value || !statusesJsonDraft.value.trim()) {
    statusesJsonDraftError.value = false
    return true
  }

  try {
    JSON.parse(statusesJsonDraft.value)
    statusesJsonDraftError.value = false
    return true
  } catch {
    statusesJsonDraftError.value = true
    return false
  }
}

function formatStatusesJsonDraft () {
  if (!validateStatusesJsonDraft()) {
    return
  }

  try {
    statusesJsonDraft.value = JSON.stringify(JSON.parse(statusesJsonDraft.value || '[]'), null, 2)
  } catch {
    statusesJsonDraftError.value = true
  }
}

async function copyStatusesJson () {
  try {
    await navigator.clipboard.writeText(statusesJsonDraft.value || '[]')
    await swal.success('已複製到剪貼簿')
  } catch (error) {
    console.error('複製 JSON 失敗', error)
    await swal.error('複製失敗')
  }
}

function parseStatusesJsonPayload () {
  const parsed = JSON.parse(statusesJsonDraft.value || '[]')
  if (!Array.isArray(parsed)) {
    throw new Error('JSON 必須為陣列格式')
  }
  return parsed.map((item, index) => {
    const payload = buildStatusPayload(item)
    if (!payload.status_code) {
      throw new Error(`第 ${index + 1} 筆缺少狀態代碼`)
    }
    if (!payload.status_name) {
      throw new Error(`第 ${index + 1} 筆（${payload.status_code}）缺少狀態名稱`)
    }
    if (!VALID_STATUS_TYPES.has(payload.status_type)) {
      throw new Error(`第 ${index + 1} 筆（${payload.status_code}）狀態類型無效`)
    }
    return payload
  })
}

async function applyStatusesJson () {
  if (!validateStatusesJsonDraft()) {
    return
  }

  let payloads
  try {
    payloads = parseStatusesJsonPayload()
  } catch (error) {
    await swal.warning(error.message || 'JSON 內容格式不正確')
    return
  }

  const codes = payloads.map(item => item.status_code)
  if (new Set(codes).size !== codes.length) {
    await swal.warning('狀態代碼不可重複')
    return
  }

  statusesJsonSaving.value = true
  try {
    const existingByCode = new Map(
      statuses.value.map(status => [status.status_code, status]),
    )

    for (const payload of payloads) {
      const { status_code, ...updates } = payload
      if (existingByCode.has(status_code)) {
        await approvalWorkflowsService.updateApprovalStatus(status_code, updates)
      } else {
        await approvalWorkflowsService.createApprovalStatus(payload)
      }
    }

    await loadStatuses()
    syncStatusesJsonDraft()
    statusesJsonDialog.value = false
    await swal.success('審核狀態 JSON 已套用')
  } catch (error) {
    console.error('套用審核狀態 JSON 失敗', error)
    await swal.error('套用失敗', error.message)
  } finally {
    statusesJsonSaving.value = false
  }
}

watch(() => statusesJsonDraft.value, () => {
  if (statusesJsonDialog.value) {
    validateStatusesJsonDraft()
  }
})

function buildStepSnapshotItem (step) {
  return {
    id: step.id,
    step_order: step.step_order,
    step_name: step.step_name,
    step_name_en: step.step_name_en || '',
    description: step.description || '',
    status_code: step.status_code,
    approver_type: step.approver_type,
    approver_config: step.approver_config || {},
    approval_departments: step.approval_departments || [],
    approver_user_ids: normalizeUserIds([
      ...(step.approver_user_ids || []),
      ...(step.approver_config?.user_ids || []),
    ]),
    approve_status_code: step.approve_status_code || 'APPROVED',
    reject_status_code: step.reject_status_code || 'REJECTED',
    is_conditional: !!step.is_conditional,
    trigger_insert_order: step.is_conditional ? (step.trigger_insert_order ?? 0) : null,
    trigger_field: step.is_conditional ? (step.trigger_field || '') : null,
    trigger_value: step.is_conditional ? (step.trigger_value ?? '') : null,
    trigger_operator: step.is_conditional ? (step.trigger_operator || DEFAULT_TRIGGER_OPERATOR) : DEFAULT_TRIGGER_OPERATOR,
  }
}

function buildStepsSnapshotFromList (steps) {
  return (steps || []).map(step => buildStepSnapshotItem(step))
}

function buildStepsSnapshot () {
  return buildStepsSnapshotFromList(workflowSteps.value)
}

function syncStepsJsonDraft () {
  stepsJsonDraft.value = JSON.stringify(buildStepsSnapshot(), null, 2)
  stepsJsonDraftError.value = false
}

function openStepsJsonDialog () {
  syncStepsJsonDraft()
  stepsJsonDialog.value = true
}

function closeStepsJsonDialog () {
  stepsJsonDialog.value = false
}

function revertStepsJsonDraft () {
  syncStepsJsonDraft()
}

function validateStepsJsonDraft () {
  if (!stepsJsonDraft.value || !stepsJsonDraft.value.trim()) {
    stepsJsonDraftError.value = false
    return true
  }

  try {
    JSON.parse(stepsJsonDraft.value)
    stepsJsonDraftError.value = false
    return true
  } catch {
    stepsJsonDraftError.value = true
    return false
  }
}

function formatStepsJsonDraft () {
  if (!validateStepsJsonDraft()) {
    return
  }

  try {
    stepsJsonDraft.value = JSON.stringify(JSON.parse(stepsJsonDraft.value || '[]'), null, 2)
  } catch {
    stepsJsonDraftError.value = true
  }
}

async function copyStepsJson () {
  try {
    await navigator.clipboard.writeText(stepsJsonDraft.value || '[]')
    await swal.success('已複製到剪貼簿')
  } catch (error) {
    console.error('複製 JSON 失敗', error)
    await swal.error('複製失敗')
  }
}

function buildStepPayloadFromJson (raw) {
  const isConditional = !!raw.is_conditional
  const approverType = raw.approver_type || 'USER'
  let approverConfig = raw.approver_config && typeof raw.approver_config === 'object'
    ? { ...raw.approver_config }
    : {}

  if (Array.isArray(raw.user_ids)) {
    approverConfig.user_ids = normalizeUserIds(raw.user_ids)
  } else if (approverType === 'USER' && !approverConfig.user_ids) {
    approverConfig.user_ids = []
  }
  if (raw.role !== undefined) {
    approverConfig.role = raw.role
  }
  if (raw.department !== undefined) {
    approverConfig.department = raw.department
  }

  const approverUserIds = normalizeUserIds([
    ...(Array.isArray(raw.approver_user_ids) ? raw.approver_user_ids : []),
    ...(approverConfig.user_ids || []),
  ])
  if (approverType === 'USER') {
    approverConfig.user_ids = approverUserIds
  }

  return {
    step_name: String(raw.step_name || '').trim(),
    step_name_en: raw.step_name_en ? String(raw.step_name_en).trim() : '',
    description: raw.description ? String(raw.description).trim() : '',
    status_code: raw.status_code || 'PENDING',
    approver_type: approverType,
    approver_config: approverConfig,
    approval_departments: Array.isArray(raw.approval_departments) ? raw.approval_departments : [],
    approver_user_ids: approverUserIds,
    approve_status_code: raw.approve_status_code || 'APPROVED',
    reject_status_code: raw.reject_status_code || 'REJECTED',
    is_conditional: isConditional,
    trigger_insert_order: isConditional ? Number(raw.trigger_insert_order ?? 0) : null,
    trigger_field: isConditional ? String(raw.trigger_field || '').trim() : null,
    trigger_value: isConditional ? String(raw.trigger_value ?? '') : null,
    trigger_operator: isConditional ? (raw.trigger_operator || DEFAULT_TRIGGER_OPERATOR) : DEFAULT_TRIGGER_OPERATOR,
    step_order: !isConditional ? Number(raw.step_order) || 1 : null,
    id: raw.id ?? null,
  }
}

function parseStepsPayloadFromArray (parsed) {
  if (!Array.isArray(parsed)) {
    throw new Error('steps 必須為陣列格式')
  }

  return parsed.map((item, index) => {
    const payload = buildStepPayloadFromJson(item)
    const label = payload.step_name || `第 ${index + 1} 筆`

    if (!payload.step_name) {
      throw new Error(`第 ${index + 1} 筆缺少步驟名稱`)
    }
    if (!VALID_APPROVER_TYPES.has(payload.approver_type)) {
      throw new Error(`「${label}」審核人類型無效`)
    }
    if (payload.is_conditional) {
      if (!payload.trigger_field) {
        throw new Error(`「${label}」為條件型步驟，缺少觸發欄位`)
      }
      if (!payload.trigger_operator || !VALID_TRIGGER_OPERATORS.has(payload.trigger_operator)) {
        throw new Error(`「${label}」觸發運算無效`)
      }
      if (payload.trigger_value === null || payload.trigger_value === '') {
        throw new Error(`「${label}」為條件型步驟，缺少觸發值`)
      }
    } else if (!payload.step_order || payload.step_order < 1) {
      throw new Error(`「${label}」一般步驟的 step_order 必須大於 0`)
    }

    return payload
  })
}

function parseStepsJsonPayload () {
  return parseStepsPayloadFromArray(JSON.parse(stepsJsonDraft.value || '[]'))
}

function validateStepsBeforePersist (payloads, existingSteps) {
  const regularOrders = payloads
    .filter(item => !item.is_conditional)
    .map(item => item.step_order)
  if (new Set(regularOrders).size !== regularOrders.length) {
    throw new Error('一般步驟的 step_order 不可重複')
  }

  const updatedIds = new Set(payloads.filter(item => item.id).map(item => item.id))
  const retainedRegularOrders = (existingSteps || [])
    .filter(step => !step.is_conditional && !updatedIds.has(step.id))
    .map(step => step.step_order)
  const allRegularOrders = [...retainedRegularOrders, ...regularOrders]
  if (new Set(allRegularOrders).size !== allRegularOrders.length) {
    throw new Error('一般步驟的 step_order 與現有步驟衝突')
  }
}

function stepPayloadToFormStep (payload) {
  return {
    id: payload.id,
    step_order: payload.step_order,
    step_name: payload.step_name,
    step_name_en: payload.step_name_en,
    description: payload.description,
    status_code: payload.status_code,
    approver_type: payload.approver_type,
    approver_config: payload.approver_config,
    approval_departments: payload.approval_departments,
    approver_user_ids: payload.approver_user_ids,
    approve_status_code: payload.approve_status_code,
    reject_status_code: payload.reject_status_code,
    is_conditional: payload.is_conditional,
    trigger_insert_order: payload.trigger_insert_order,
    trigger_field: payload.trigger_field,
    trigger_value: payload.trigger_value,
    trigger_operator: payload.trigger_operator,
  }
}

function resolveConditionalStepOrderForApply (triggerInsertOrder, stepId, conditionalCounts, existingSteps) {
  if (stepId) {
    return computeConditionalStepOrder(triggerInsertOrder, stepId, existingSteps)
  }

  const count = conditionalCounts.get(triggerInsertOrder) || 0
  conditionalCounts.set(triggerInsertOrder, count + 1)
  const sequence = count + 1
  return 10000 + (triggerInsertOrder * 100) + sequence
}

async function persistWorkflowSteps (workflowId, payloads, existingStepsForValidation) {
  validateStepsBeforePersist(payloads, existingStepsForValidation)

  const dbSteps = await approvalWorkflowsService.getWorkflowSteps(workflowId)
  const existingById = new Map(dbSteps.map(step => [step.id, step]))
  const conditionalCounts = new Map()
  dbSteps
    .filter(step => step.is_conditional)
    .forEach(step => {
      const key = step.trigger_insert_order ?? 0
      conditionalCounts.set(key, (conditionalCounts.get(key) || 0) + 1)
    })

  for (const payload of payloads) {
    let { id, step_order: regularStepOrder, ...rest } = payload
    if (id && !existingById.has(id)) {
      id = null
    }

    const data = normalizeStepForPersist({
      workflow_id: workflowId,
      ...rest,
    })

    if (data.is_conditional) {
      data.step_order = resolveConditionalStepOrderForApply(
        data.trigger_insert_order ?? 0,
        id && existingById.has(id) ? id : null,
        conditionalCounts,
        dbSteps,
      )
    } else {
      data.step_order = regularStepOrder
    }

    if (id && existingById.has(id)) {
      await approvalWorkflowsService.updateWorkflowStep(id, data)
    } else {
      await approvalWorkflowsService.createWorkflowStep(data)
    }
  }
}

async function applyStepsJson () {
  if (!currentWorkflow.value?.id) {
    return
  }
  if (!validateStepsJsonDraft()) {
    return
  }

  let payloads
  try {
    payloads = parseStepsJsonPayload()
  } catch (error) {
    await swal.warning(error.message || 'JSON 內容格式不正確')
    return
  }

  stepsJsonSaving.value = true
  try {
    await persistWorkflowSteps(currentWorkflow.value.id, payloads, workflowSteps.value)

    await loadWorkflowSteps(currentWorkflow.value.id)
    syncStepsJsonDraft()
    stepsJsonDialog.value = false
    await swal.success('流程步驟 JSON 已套用')
  } catch (error) {
    console.error('套用流程步驟 JSON 失敗', error)
    await swal.error('套用失敗', error.message)
  } finally {
    stepsJsonSaving.value = false
  }
}

watch(() => stepsJsonDraft.value, () => {
  if (stepsJsonDialog.value) {
    validateStepsJsonDraft()
  }
})

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

function extractFormCode (value) {
  if (value == null) return ''
  if (typeof value === 'string') {
    const trimmed = value.trim()
    return trimmed === '[object Object]' ? '' : trimmed
  }
  if (typeof value === 'object') {
    if (typeof value.value === 'string') return value.value.trim()
    if (typeof value.form_code === 'string') return value.form_code.trim()
    if (typeof value.title === 'string') {
      const match = value.title.match(/\(([^)]+)\)\s*$/)
      if (match) return match[1].trim()
    }
  }
  return ''
}

function normalizeFormCodes (formCodes) {
  if (formCodes == null) return []
  if (typeof formCodes === 'string') {
    const trimmed = formCodes.trim()
    if (!trimmed) return []
    try {
      const parsed = JSON.parse(trimmed)
      if (Array.isArray(parsed)) {
        return [...new Set(parsed.map(extractFormCode).filter(Boolean))]
      }
    } catch {
      return trimmed === '[object Object]' ? [] : [trimmed]
    }
    return trimmed === '[object Object]' ? [] : [trimmed]
  }
  if (Array.isArray(formCodes)) {
    return [...new Set(formCodes.map(extractFormCode).filter(Boolean))]
  }
  return []
}

function getFormCodeOptionLabel (code) {
  const option = formCodeOptions.value.find(item => item.value === code)
  return option?.title || code
}

function onWorkflowFormCodesChange (value) {
  workflowForm.value.form_codes = normalizeFormCodes(value)
}

function formatWorkflowFormCodes (formCodes) {
  const codes = normalizeFormCodes(formCodes)
  if (codes.length === 0) return '通用流程'
  return codes.join('、')
}

async function loadFormCodeOptions () {
  try {
    const forms = await formsService.getForms({ is_active: true })
    formCodeOptions.value = (forms || [])
      .filter(f => f.form_code)
      .map(f => ({
        title: `${f.form_name} (${f.form_code})`,
        value: f.form_code,
      }))
  } catch (error) {
    console.error('載入表單代碼選項失敗', error)
    formCodeOptions.value = []
  }
}

function buildWorkflowFormSnapshot () {
  const snapshot = {
    workflow_code: workflowForm.value.workflow_code || '',
    workflow_name: workflowForm.value.workflow_name || '',
    workflow_name_en: workflowForm.value.workflow_name_en || '',
    description: workflowForm.value.description || '',
    initial_status_code: workflowForm.value.initial_status_code || 'PENDING',
    final_status_code: workflowForm.value.final_status_code || 'APPROVED',
    reject_status_code: workflowForm.value.reject_status_code || 'REJECTED',
    form_codes: normalizeFormCodes(workflowForm.value.form_codes),
    is_default: workflowForm.value.is_default === true,
    is_active: workflowForm.value.is_active !== false,
    steps: buildStepsSnapshotFromList(workflowFormSteps.value),
  }

  if (editingWorkflow.value?.id) {
    snapshot.id = editingWorkflow.value.id
  }

  return snapshot
}

function findWorkflowByCode (workflowCode) {
  if (!workflowCode) return null
  return workflows.value.find(workflow => workflow.workflow_code === workflowCode) || null
}

function findWorkflowById (workflowId) {
  if (workflowId == null) return null
  return workflows.value.find(workflow => Number(workflow.id) === Number(workflowId)) || null
}

function resolveWorkflowTargetFromImport (jsonWorkflowId, workflowCode) {
  return findWorkflowById(jsonWorkflowId) || findWorkflowByCode(workflowCode)
}

function sanitizeWorkflowSaveData (raw) {
  const data = { ...raw }
  delete data.id
  delete data.created_at
  delete data.updated_at
  delete data.created_by_id
  delete data.steps
  delete data.form_code
  delete data.form_id
  return data
}

function getWorkflowSaveErrorMessage (error) {
  const message = error?.message || ''
  if (message.includes('approval_workflows_workflow_code_key')) {
    return '流程代碼已存在，請改用其他 workflow_code，或編輯既有流程後再匯入 JSON'
  }
  if (message.includes('approval_workflow_steps_trigger_operator')) {
    return '步驟 trigger_operator 不可為空，一般步驟請使用 equals'
  }
  return message || '儲存失敗'
}

function resolveWorkflowIdForSave (data) {
  let workflowId = editingWorkflow.value?.id ?? workflowForm.value.id
  if (workflowId) {
    return workflowId
  }

  const existing = findWorkflowByCode(data.workflow_code)
  if (existing) {
    editingWorkflow.value = existing
    return existing.id
  }

  return null
}

async function loadWorkflowFormSteps (workflowId) {
  if (!workflowId) {
    workflowFormSteps.value = []
    return
  }

  loadingWorkflowFormSteps.value = true
  try {
    workflowFormSteps.value = await approvalWorkflowsService.getWorkflowSteps(workflowId)
  } catch (error) {
    console.error('載入流程步驟失敗', error)
    workflowFormSteps.value = []
    throw error
  } finally {
    loadingWorkflowFormSteps.value = false
  }
}

function syncWorkflowJsonDraft () {
  workflowJsonDraft.value = JSON.stringify(buildWorkflowFormSnapshot(), null, 2)
  workflowJsonDraftError.value = false
}

function openWorkflowJsonDialog () {
  void openWorkflowJsonDialogAsync()
}

async function openWorkflowJsonDialogAsync () {
  try {
    if (editingWorkflow.value?.id) {
      await loadWorkflowFormSteps(editingWorkflow.value.id)
    }
    syncWorkflowJsonDraft()
    workflowJsonDialog.value = true
  } catch (error) {
    await swal.error('載入流程步驟失敗', error.message)
  }
}

function closeWorkflowJsonDialog () {
  workflowJsonDialog.value = false
}

function revertWorkflowJsonDraft () {
  syncWorkflowJsonDraft()
}

function validateWorkflowJsonDraft () {
  if (!workflowJsonDraft.value || !workflowJsonDraft.value.trim()) {
    workflowJsonDraftError.value = false
    return true
  }

  try {
    JSON.parse(workflowJsonDraft.value)
    workflowJsonDraftError.value = false
    return true
  } catch {
    workflowJsonDraftError.value = true
    return false
  }
}

function formatWorkflowJsonDraft () {
  if (!validateWorkflowJsonDraft()) {
    return
  }

  try {
    workflowJsonDraft.value = JSON.stringify(JSON.parse(workflowJsonDraft.value || '{}'), null, 2)
  } catch {
    workflowJsonDraftError.value = true
  }
}

async function copyWorkflowJson () {
  try {
    await navigator.clipboard.writeText(workflowJsonDraft.value || '{}')
    await swal.success('已複製到剪貼簿')
  } catch (error) {
    console.error('複製 JSON 失敗', error)
    await swal.error('複製失敗')
  }
}

function parseWorkflowJsonPayload () {
  const parsed = JSON.parse(workflowJsonDraft.value || '{}')
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('JSON 必須為物件格式')
  }

  const payload = {
    workflow_code: String(parsed.workflow_code || '').trim(),
    workflow_name: String(parsed.workflow_name || '').trim(),
    workflow_name_en: parsed.workflow_name_en ? String(parsed.workflow_name_en).trim() : '',
    description: parsed.description ? String(parsed.description).trim() : '',
    initial_status_code: parsed.initial_status_code || 'PENDING',
    final_status_code: parsed.final_status_code || 'APPROVED',
    reject_status_code: parsed.reject_status_code || 'REJECTED',
    form_codes: normalizeFormCodes(parsed.form_codes),
    is_default: parsed.is_default === true,
    is_active: parsed.is_active !== false,
  }

  if (!payload.workflow_code) {
    throw new Error('缺少流程代碼 workflow_code')
  }
  if (!payload.workflow_name) {
    throw new Error('缺少流程名稱 workflow_name')
  }
  if (!payload.initial_status_code) {
    throw new Error('缺少初始狀態 initial_status_code')
  }
  if (!payload.final_status_code) {
    throw new Error('缺少最終狀態 final_status_code')
  }
  if (!payload.reject_status_code) {
    throw new Error('缺少退回狀態 reject_status_code')
  }

  let steps
  if (parsed.steps !== undefined) {
    steps = parseStepsPayloadFromArray(parsed.steps)
    validateStepsBeforePersist(steps, workflowFormSteps.value)
  }

  return {
    id: parsed.id ?? null,
    ...payload,
    steps,
  }
}

function applyWorkflowJson () {
  if (!validateWorkflowJsonDraft()) {
    return
  }

  let parsed
  try {
    parsed = parseWorkflowJsonPayload()
  } catch (error) {
    swal.warning(error.message || 'JSON 內容格式不正確')
    return
  }

  const { steps, id: jsonWorkflowId, ...workflowPayload } = parsed
  const existingWorkflow = resolveWorkflowTargetFromImport(jsonWorkflowId, workflowPayload.workflow_code)

  if (existingWorkflow) {
    editingWorkflow.value = existingWorkflow
    workflowPayload.workflow_code = existingWorkflow.workflow_code
  } else if (editingWorkflow.value?.id) {
    workflowPayload.workflow_code = workflowForm.value.workflow_code
  }

  workflowForm.value = {
    ...workflowForm.value,
    ...workflowPayload,
  }

  if (steps !== undefined) {
    workflowFormSteps.value = steps.map(step => stepPayloadToFormStep(step))
  }

  syncWorkflowJsonDraft()
  workflowJsonDialog.value = false

  const modeHint = existingWorkflow && !jsonWorkflowId
    ? '（已識別為更新既有流程）'
    : ''
  void swal.success(`流程 JSON 已套用至表單，請按「儲存」寫入${modeHint}`)
}

watch(() => workflowJsonDraft.value, () => {
  if (workflowJsonDialog.value) {
    validateWorkflowJsonDraft()
  }
})

// 流程操作
async function openWorkflowDialog (workflow = null) {
  editingWorkflow.value = workflow
  if (workflow) {
    const { form_code, form_id, ...rest } = workflow
    const legacyCodes = form_code ? [form_code] : []
    workflowForm.value = {
      ...rest,
      form_codes: normalizeFormCodes(workflow.form_codes ?? legacyCodes),
    }
    workflowDialog.value = true
    try {
      await loadWorkflowFormSteps(workflow.id)
    } catch (error) {
      await swal.error('載入流程步驟失敗', error.message)
    }
  } else {
    workflowForm.value = {
      workflow_code: '',
      workflow_name: '',
      workflow_name_en: '',
      description: '',
      initial_status_code: 'PENDING',
      final_status_code: 'APPROVED',
      reject_status_code: 'REJECTED',
      form_codes: [],
      is_default: false,
      is_active: true,
    }
    workflowFormSteps.value = []
    workflowDialog.value = true
  }
}

async function saveWorkflow () {
  try {
    const data = sanitizeWorkflowSaveData(workflowForm.value)
    data.form_codes = normalizeFormCodes(data.form_codes)

    const stepsToPersist = workflowFormSteps.value.map(step => buildStepPayloadFromJson(step))
    if (stepsToPersist.length > 0) {
      validateStepsBeforePersist(stepsToPersist, workflowFormSteps.value)
    }

    let workflowId = resolveWorkflowIdForSave(data)
    if (workflowId) {
      await approvalWorkflowsService.updateWorkflow(workflowId, data)
    } else {
      if (findWorkflowByCode(data.workflow_code)) {
        await swal.warning(`流程代碼「${data.workflow_code}」已存在，請編輯既有流程後再匯入 JSON`)
        return
      }
      const created = await approvalWorkflowsService.createWorkflow(data)
      workflowId = created.id
      editingWorkflow.value = created
    }

    if (stepsToPersist.length > 0) {
      await persistWorkflowSteps(workflowId, stepsToPersist, workflowFormSteps.value)
      await loadWorkflowFormSteps(workflowId)
    }

    await swal.success('流程已儲存！')
    workflowDialog.value = false
    await loadWorkflows()
  } catch (error) {
    console.error('儲存流程失敗', error)
    await swal.error('儲存流程失敗', getWorkflowSaveErrorMessage(error))
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

function computeConditionalStepOrder (triggerInsertOrder, excludeStepId = null, stepsList = workflowSteps.value) {
  const samePointSteps = stepsList.filter(step =>
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
      role: step.approver_config?.role || null,
      department: step.approver_config?.department || null,
      approval_departments: step.approval_departments || [],
      approver_user_ids: mergeStepApproverUserIds(step),
      user_ids: mergeStepApproverUserIds(step),
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
  if (stepForm.value.approver_type !== 'USER') {
    stepForm.value.approver_user_ids = normalizeUserIds(stepForm.value.approver_user_ids)
  }
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

    const data = normalizeStepForPersist({
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
    })

    if (stepForm.value.is_conditional) {
      data.step_order = computeConditionalStepOrder(
        stepForm.value.trigger_insert_order,
        editingStep.value?.id || null
      )
    } else {
      data.step_order = stepForm.value.step_order
    }

    if (stepForm.value.approver_type === 'USER') {
      const approverUserIds = normalizeUserIds(stepForm.value.approver_user_ids)
      if (approverUserIds.length === 0) {
        await swal.error('請至少指定一位審核人')
        return
      }
      data.approver_user_ids = approverUserIds
      data.approver_config = { user_ids: approverUserIds }
    } else if (stepForm.value.approver_type === 'ROLE') {
      data.approver_config = { role: stepForm.value.role }
    } else if (stepForm.value.approver_type === 'DEPARTMENT') {
      data.approver_config = { department: stepForm.value.department }
    } else {
      data.approver_config = {}
    }

    if (stepForm.value.approver_type !== 'USER') {
      data.approver_user_ids = normalizeUserIds(stepForm.value.approver_user_ids)
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
    loadFormCodeOptions(),
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

.statuses-json-editor-pane {
  min-height: 360px;
  height: 50vh;
  max-height: 520px;
  overflow: hidden;
  border: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
  border-radius: 4px;
  background: #fafafa;
}

.statuses-json-editor-pane--error {
  border-color: rgb(var(--v-theme-error));
}

.statuses-json-editor-pane :deep(.cm-editor) {
  height: 100%;
}
</style>
