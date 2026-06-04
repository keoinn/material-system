<template>
  <v-card>
    <v-card-title class="d-flex align-center flex-wrap ga-2">
      <div>
        <div class="text-h6">項目主檔申請表</div>
        <div
          v-if="currentStep === 2 && selectedForm"
          class="text-caption text-medium-emphasis"
        >
          {{ selectedForm.form_name }}
        </div>
      </div>
      <v-spacer />
      <v-btn
        v-if="currentStep === 2"
        class="mr-2"
        prepend-icon="mdi-arrow-left"
        variant="outlined"
        @click="goToFormSelection"
      >
        選擇表單
      </v-btn>
      <template v-if="currentStep === 2">
        <v-btn
          class="mr-2"
          color="primary"
          prepend-icon="mdi-plus"
          @click="createDraft"
        >
          新增草稿
        </v-btn>
        <v-btn
          color="success"
          prepend-icon="mdi-send"
          :disabled="batchSubmitting || selectedDraftIds.length === 0"
          :loading="batchSubmitting"
          @click="submitAllDrafts"
        >
          送出已選取草稿
        </v-btn>
      </template>
    </v-card-title>

    <v-card-text>
      <v-progress-linear
        v-if="loadingForms"
        class="mb-4"
        color="primary"
        indeterminate
      />

      <v-window v-model="currentStep">
        <!-- 第一頁：選擇啟用中的表單 -->
        <v-window-item :value="1">
          <p class="text-body-2 text-medium-emphasis mb-4">
            請選擇要申請的表單（僅顯示啟用中的表單）
          </p>

          <v-alert
            v-if="!loadingForms && activeForms.length === 0"
            type="warning"
            variant="tonal"
          >
            目前沒有啟用中的表單，請先到「表單管理」建立或啟用表單。
          </v-alert>

          <v-row v-else>
            <v-col
              v-for="form in activeForms"
              :key="form.id"
              cols="12"
              sm="6"
              md="4"
              lg="3"
            >
              <v-btn
                block
                class="form-select-btn"
                color="primary"
                height="auto"
                :loading="loadingForms"
                variant="outlined"
                @click="selectForm(form)"
              >
                <div class="form-select-btn__content py-4">
                  <v-icon class="mb-2" size="32">mdi-file-document-outline</v-icon>
                  <div class="text-subtitle-1 font-weight-medium">
                    {{ form.form_name }}
                  </div>
                  <div class="text-caption text-medium-emphasis form-select-btn__en">
                    {{ form.form_name_en || '\u00a0' }}
                  </div>
                  <div class="text-caption mt-1">
                    {{ form.form_code }}
                  </div>
                </div>
              </v-btn>
            </v-col>
          </v-row>
        </v-window-item>

        <!-- 第二頁：草稿搜尋與管理 -->
        <v-window-item :value="2">
          <v-row class="mb-4">
            <v-col cols="12" md="4">
              <v-text-field
                v-model="searchKeyword"
                clearable
                label="搜尋草稿名稱"
                prepend-inner-icon="mdi-magnify"
                variant="outlined"
                density="comfortable"
                @click:clear="searchKeyword = ''"
              />
            </v-col>
          </v-row>

          <v-data-table
            v-model="selectedDraftIds"
            :headers="headers"
            :items="visibleDrafts"
            item-value="id"
            :items-per-page="5"
            class="elevation-1"
            show-select
          >
            <template v-slot:[`item.name`]="{ item }">
              <div class="d-flex align-center" style="gap: 6px;">
                <span>{{ item.name }}</span>
                <v-btn
                  icon
                  size="x-small"
                  color="primary"
                  variant="text"
                  :title="`修改名稱 ${item.name}`"
                  @click="openRenameDialog(item)"
                >
                  <v-icon>mdi-pencil-outline</v-icon>
                </v-btn>
              </div>
            </template>

            <template v-slot:[`item.status`]="{ item }">
              <v-chip
                :color="item.status === 'submitted' ? 'success' : 'warning'"
                size="small"
                variant="flat"
              >
                {{ item.status === 'submitted' ? '已送出' : '草稿' }}
              </v-chip>
            </template>

            <template v-slot:[`item.recordId`]="{ item }">
              {{ item.recordId || '-' }}
            </template>

            <template v-slot:[`item.updatedAt`]="{ item }">
              {{ formatDate(item.updatedAt) }}
            </template>

            <template v-slot:[`item.actions`]="{ item }">
              <div class="d-flex align-center" style="gap: 8px;">
                <v-btn
                  icon
                  size="x-small"
                  color="info"
                  variant="elevated"
                  :title="`預覽 ${item.name}`"
                  @click="openPreview(item)"
                >
                  <v-icon>mdi-eye</v-icon>
                </v-btn>
                <v-btn
                  icon
                  size="x-small"
                  color="primary"
                  variant="elevated"
                  :title="`編輯 ${item.name}`"
                  @click="openForm(item)"
                >
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
                <v-btn
                  icon
                  size="x-small"
                  color="info"
                  variant="elevated"
                  :title="`複製 ${item.name}`"
                  @click="duplicateDraft(item)"
                >
                  <v-icon>mdi-content-copy</v-icon>
                </v-btn>
                <v-btn
                  v-if="item.status !== 'submitted'"
                  icon
                  size="x-small"
                  color="error"
                  variant="elevated"
                  @click="removeDraft(item)"
                >
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </div>
            </template>

            <template #no-data>
              <div class="text-center py-4">
                {{ hasSearchKeyword ? '找不到符合的草稿' : '尚未建立草稿，請先點擊「新增草稿」。' }}
              </div>
            </template>
          </v-data-table>
        </v-window-item>
      </v-window>
    </v-card-text>
  </v-card>

  <v-dialog
    v-model="renameDialog"
    max-width="480"
  >
    <v-card>
      <v-card-title>修改草稿名稱</v-card-title>
      <v-card-text>
        <v-text-field
          v-model="renameDraftName"
          label="草稿名稱"
          variant="outlined"
          density="comfortable"
          maxlength="60"
          autofocus
        />
      </v-card-text>
      <v-card-actions>
        <v-spacer />
        <v-btn
          variant="text"
          @click="closeRenameDialog"
        >
          取消
        </v-btn>
        <v-btn
          color="primary"
          variant="flat"
          @click="confirmRename"
        >
          儲存
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>

  <v-dialog
    v-model="previewDialog"
    max-width="900"
    persistent
    scrollable
  >
    <v-card v-if="previewDraft">
      <v-card-title class="d-flex align-center bg-primary text-white">
        <v-icon class="mr-2">mdi-file-document-outline</v-icon>
        <span>申請預覽</span>
        <v-spacer />
        <v-btn
          icon
          variant="text"
          @click="closePreview"
        >
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </v-card-title>
      <v-card-text class="pa-0">
        <v-container>
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
                    <span class="detail-label">草稿名稱：</span>
                    <span class="detail-value">{{ previewDraft.name }}</span>
                  </div>
                </v-col>
                <v-col cols="12" md="6">
                  <div class="detail-item">
                    <span class="detail-label">狀態：</span>
                    <v-chip
                      :color="previewDraft.status === 'submitted' ? 'success' : 'warning'"
                      size="small"
                      variant="flat"
                    >
                      {{ previewDraft.status === 'submitted' ? '已送出' : '草稿' }}
                    </v-chip>
                  </div>
                </v-col>
                <v-col cols="12" md="6">
                  <div class="detail-item">
                    <span class="detail-label">申請單號：</span>
                    <span class="detail-value">{{ previewDraft.recordId || '-' }}</span>
                  </div>
                </v-col>
                <v-col cols="12" md="6">
                  <div class="detail-item">
                    <span class="detail-label">最後更新：</span>
                    <span class="detail-value">{{ formatDate(previewDraft.updatedAt) }}</span>
                  </div>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>
          <v-card
            v-if="previewFormId"
            variant="outlined"
          >
            <v-card-title class="text-subtitle-1 bg-grey-lighten-4">
              <v-icon class="mr-2">mdi-form-select</v-icon>
              表單資料
            </v-card-title>
            <v-card-text>
              <v-alert
                v-if="!hasAnyValue(previewDraft.values)"
                type="info"
                variant="tonal"
              >
                尚未填寫內容
              </v-alert>
              <DynamicFormRenderer
                v-else
                :key="previewDraft.id"
                :form-id="previewFormId"
                :initial-values="previewDraft.values || {}"
                :readonly="true"
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
          @click="closePreview"
        >
          關閉
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { formDataService } from '@/api/services/formData'
import { formsService } from '@/api/services/forms'
import { useSwal } from '@/composables/useSwal'
import { FORMS_UPDATED_EVENT } from '@/utils/formsUpdatedEvent'
import { useBatchMaterialApplicationsStore } from '@/stores/batchMaterialApplications'
import DynamicFormRenderer from './DynamicFormRenderer.vue'

const route = useRoute()
const router = useRouter()
const swal = useSwal()
const batchStore = useBatchMaterialApplicationsStore()

const currentStep = ref(1)
const loadingForms = ref(false)
const activeForms = ref([])
const selectedForm = ref(null)
const batchSubmitting = ref(false)
const selectedDraftIds = ref([])
const renameDialog = ref(false)
const renamingDraftId = ref(null)
const renameDraftName = ref('')
const previewDialog = ref(false)
const previewDraft = ref(null)
const searchKeyword = ref('')

const headers = [
  { title: '草稿名稱', key: 'name', sortable: false },
  { title: '狀態', key: 'status', sortable: false },
  { title: '申請單號', key: 'recordId', sortable: false },
  { title: '最後更新', key: 'updatedAt', sortable: true },
  { title: '操作', key: 'actions', sortable: false },
]

const drafts = computed(() => batchStore.drafts)
const selectedFormId = computed(() => selectedForm.value?.id ?? null)
const hasSearchKeyword = computed(() => (searchKeyword.value || '').trim().length > 0)

const visibleDrafts = computed(() => {
  const keyword = (searchKeyword.value || '').trim().toLowerCase()
  return drafts.value
    .filter(item => item.status === 'draft')
    .filter(item => {
      if (!selectedFormId.value) {
        return true
      }
      return !item.formId || item.formId === selectedFormId.value
    })
    .filter(item => !keyword || (item.name || '').toLowerCase().includes(keyword))
})

const previewFormId = computed(() => {
  if (!previewDraft.value) {
    return null
  }
  return previewDraft.value.formId || selectedFormId.value
})

async function loadActiveForms () {
  loadingForms.value = true
  try {
    activeForms.value = await formsService.getForms({ is_active: true })
  } catch (error) {
    console.error('載入表單列表失敗', error)
    activeForms.value = []
    await swal.error('載入表單列表失敗，請稍後再試')
  } finally {
    loadingForms.value = false
  }
}

function syncBatchRouteView (view) {
  router.replace({
    path: '/',
    query: {
      tab: 'batch-apply',
      batchView: view,
    },
  })
}

function applyBatchViewFromRoute () {
  const view = route.query.batchView
  if (view === 'drafts' && selectedForm.value) {
    currentStep.value = 2
    return
  }
  currentStep.value = 1
  selectedDraftIds.value = []
  searchKeyword.value = ''
  if (view === 'select') {
    selectedForm.value = null
  }
}

function selectForm (form) {
  selectedForm.value = form
  selectedDraftIds.value = []
  searchKeyword.value = ''
  currentStep.value = 2
  syncBatchRouteView('drafts')
}

function goToFormSelection () {
  currentStep.value = 1
  selectedDraftIds.value = []
  searchKeyword.value = ''
  syncBatchRouteView('select')
}

function createDraft () {
  if (!selectedForm.value) {
    return
  }
  batchStore.createDraft({
    formId: selectedForm.value.id,
    formName: selectedForm.value.form_name,
    formCode: selectedForm.value.form_code,
  })
}

function getDraftRow (item) {
  if (!item) return null
  return item.raw || item
}

function openRenameDialog (item) {
  const draft = getDraftRow(item)
  if (!draft?.id) {
    return
  }
  renamingDraftId.value = draft.id
  renameDraftName.value = draft.name || ''
  renameDialog.value = true
}

function closeRenameDialog () {
  renameDialog.value = false
  renamingDraftId.value = null
  renameDraftName.value = ''
}

async function confirmRename () {
  const nextName = renameDraftName.value.trim()
  if (!nextName) {
    await swal.warning('草稿名稱不可為空')
    return
  }

  if (!renamingDraftId.value) {
    await swal.warning('找不到可更新的草稿')
    closeRenameDialog()
    return
  }

  batchStore.updateDraftName(renamingDraftId.value, nextName)
  await swal.success('草稿名稱已更新')
  closeRenameDialog()
}

async function duplicateDraft (item) {
  const draft = getDraftRow(item)
  const draftId = draft?.id
  const target = drafts.value.find(row => row.id === draftId)
  if (!target) return
  batchStore.duplicateDraft(draftId)
  await swal.success('草稿已複製')
}

async function removeDraft (item) {
  const draft = getDraftRow(item)
  const draftId = draft?.id
  const target = drafts.value.find(row => row.id === draftId)
  if (!target) return
  const result = await swal.confirm(`確定刪除「${target.name}」嗎？`)
  if (!result.isConfirmed) return
  batchStore.removeDraft(draftId)
}

function openForm (item) {
  const draft = getDraftRow(item)
  const draftId = draft?.id
  if (!draftId) return
  batchStore.selectDraft(draftId)
  router.push({ path: '/', query: { tab: 'apply', batchDraftId: draftId } })
}

async function openPreview (item) {
  const draft = getDraftRow(item)
  if (!draft?.id) return
  const formId = draft.formId || selectedFormId.value
  if (!formId) {
    await swal.warning('找不到對應的表單')
    return
  }
  previewDraft.value = draft
  previewDialog.value = true
}

function closePreview () {
  previewDialog.value = false
  previewDraft.value = null
}

function hasAnyValue (values) {
  return Object.values(values || {}).some(value => {
    if (Array.isArray(value)) return value.length > 0
    return value !== null && value !== undefined && value !== ''
  })
}

async function submitAllDrafts () {
  if (selectedDraftIds.value.length === 0) {
    await swal.warning('請先勾選要送出的草稿')
    return
  }

  const pendingDrafts = drafts.value.filter(item =>
    item.status === 'draft' && selectedDraftIds.value.includes(item.id),
  )
  if (pendingDrafts.length === 0) {
    await swal.warning('勾選的草稿目前不可送出')
    return
  }

  batchSubmitting.value = true
  const failedItems = []
  const failedDraftIds = []
  let successCount = 0

  for (const draft of pendingDrafts) {
    const formId = draft.formId || selectedFormId.value
    if (!formId) {
      failedItems.push(`${draft.name}：找不到對應的表單`)
      failedDraftIds.push(draft.id)
      continue
    }

    try {
      if (!hasAnyValue(draft.values)) {
        throw new Error('尚未填寫內容')
      }
      const result = await formDataService.createFormData(formId, draft.values, { createRecord: true })
      const recordId = result?.record_id || result?.id || 'N/A'
      batchStore.markSubmitted(draft.id, recordId)
      successCount += 1
    } catch (error) {
      failedItems.push(`${draft.name}：${error.message || '送出失敗'}`)
      failedDraftIds.push(draft.id)
    }
  }

  batchSubmitting.value = false

  if (failedItems.length === 0) {
    selectedDraftIds.value = selectedDraftIds.value.filter(id =>
      !pendingDrafts.some(draft => draft.id === id),
    )
    await swal.success(`共送出 ${successCount} 筆申請`, '批次送出完成')
    return
  }

  selectedDraftIds.value = selectedDraftIds.value.filter(id => failedDraftIds.includes(id))

  await swal.warning(
    `成功 ${successCount} 筆，失敗 ${failedItems.length} 筆`,
    failedItems.join('\n'),
  )
}

function formatDate (date) {
  if (!date) return '-'
  return new Date(date).toLocaleString('zh-TW')
}

function handleFormsUpdated () {
  loadActiveForms()
}

onMounted(async () => {
  await loadActiveForms()
  window.addEventListener(FORMS_UPDATED_EVENT, handleFormsUpdated)
})

onUnmounted(() => {
  window.removeEventListener(FORMS_UPDATED_EVENT, handleFormsUpdated)
})

watch(
  () => [route.query.tab, route.query.batchView],
  ([tab]) => {
    if (tab !== 'batch-apply') {
      return
    }
    loadActiveForms()
    applyBatchViewFromRoute()
  },
  { immediate: true },
)
</script>

<style scoped lang="scss">
.form-select-btn {
  text-transform: none;
  letter-spacing: normal;
}

.form-select-btn__content {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
  white-space: normal;
  text-align: center;
}

.form-select-btn__en {
  min-height: 20px;
  line-height: 20px;
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
</style>
