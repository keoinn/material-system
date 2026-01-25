<template>
  <v-card>
    <v-card-title class="system-header d-flex align-center justify-space-between">
      <h2>選項活頁簿</h2>
      <v-btn
        color="primary"
        prepend-icon="mdi-plus"
        @click="openCreateDialog"
      >
        新增活頁簿
      </v-btn>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-progress-linear
        v-if="loading"
        indeterminate
        color="primary"
        class="mb-4"
      />

      <v-data-table
        v-if="!loading"
        :headers="headers"
        :items="workbooks"
        :items-per-page="10"
        class="elevation-1"
      >
        <template #header.workbook_key="{ column }">
          <div class="d-flex align-center">
            <span>{{ column.title }}</span>
            <v-tooltip location="top">
              <template #activator="{ props }">
                <v-icon
                  v-bind="props"
                  size="small"
                  color="grey"
                  class="ml-1"
                >
                  mdi-help-circle-outline
                </v-icon>
              </template>
              <span>{{ fieldTooltips.workbook_key }}</span>
            </v-tooltip>
          </div>
        </template>

        <template #header.workbook_name="{ column }">
          <div class="d-flex align-center">
            <span>{{ column.title }}</span>
            <v-tooltip location="top">
              <template #activator="{ props }">
                <v-icon
                  v-bind="props"
                  size="small"
                  color="grey"
                  class="ml-1"
                >
                  mdi-help-circle-outline
                </v-icon>
              </template>
              <span>{{ fieldTooltips.workbook_name }}</span>
            </v-tooltip>
          </div>
        </template>

        <template #header.description="{ column }">
          <div class="d-flex align-center">
            <span>{{ column.title }}</span>
            <v-tooltip location="top">
              <template #activator="{ props }">
                <v-icon
                  v-bind="props"
                  size="small"
                  color="grey"
                  class="ml-1"
                >
                  mdi-help-circle-outline
                </v-icon>
              </template>
              <span>{{ fieldTooltips.description }}</span>
            </v-tooltip>
          </div>
        </template>

        <template #header.is_active="{ column }">
          <div class="d-flex align-center">
            <span>{{ column.title }}</span>
            <v-tooltip location="top">
              <template #activator="{ props }">
                <v-icon
                  v-bind="props"
                  size="small"
                  color="grey"
                  class="ml-1"
                >
                  mdi-help-circle-outline
                </v-icon>
              </template>
              <span>{{ fieldTooltips.is_active }}</span>
            </v-tooltip>
          </div>
        </template>

        <template #header.created_at="{ column }">
          <div class="d-flex align-center">
            <span>{{ column.title }}</span>
            <v-tooltip location="top">
              <template #activator="{ props }">
                <v-icon
                  v-bind="props"
                  size="small"
                  color="grey"
                  class="ml-1"
                >
                  mdi-help-circle-outline
                </v-icon>
              </template>
              <span>{{ fieldTooltips.created_at }}</span>
            </v-tooltip>
          </div>
        </template>

        <template #header.actions="{ column }">
          <div class="d-flex align-center">
            <span>{{ column.title }}</span>
            <v-tooltip location="top">
              <template #activator="{ props }">
                <v-icon
                  v-bind="props"
                  size="small"
                  color="grey"
                  class="ml-1"
                >
                  mdi-help-circle-outline
                </v-icon>
              </template>
              <span>{{ fieldTooltips.actions }}</span>
            </v-tooltip>
          </div>
        </template>

        <template #item.created_at="{ item }">
          {{ formatDateTime(item.created_at) }}
        </template>

        <template #item.is_active="{ item }">
          <v-chip
            :color="item.is_active ? 'success' : 'grey'"
            size="small"
            variant="flat"
          >
            {{ item.is_active ? '啟用' : '停用' }}
          </v-chip>
        </template>

        <template #item.actions="{ item }">
          <div class="d-flex align-center" style="gap: 8px;">
            <v-btn
              icon
              size="x-small"
              color="primary"
              @click="openEditor(item.id)"
            >
              <v-icon>mdi-pencil</v-icon>
            </v-btn>
            <v-btn
              icon
              size="x-small"
              color="info"
              @click="openEditBasicInfo(item)"
            >
              <v-icon>mdi-information-outline</v-icon>
            </v-btn>
            <v-btn
              icon
              size="x-small"
              color="error"
              @click="deleteWorkbook(item.id)"
            >
              <v-icon>mdi-delete</v-icon>
            </v-btn>
          </div>
        </template>

        <template #no-data>
          <div class="text-center py-4">
            目前沒有活頁簿
          </div>
        </template>
      </v-data-table>
    </v-card-text>

    <!-- 新增活頁簿對話框（僅基本資訊） -->
    <v-dialog
      v-model="createDialog"
      max-width="600"
      persistent
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-primary text-white">
          <v-icon class="mr-2">mdi-table-plus</v-icon>
          <span>新增活頁簿</span>
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="createDialog = false"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>

        <v-card-text class="pt-6">
          <v-form
            v-if="newWorkbook"
            ref="createFormRef"
          >
            <v-text-field
              v-model="newWorkbook.workbook_key"
              hint="唯一識別碼，用於系統內部引用"
              persistent-hint
              variant="outlined"
              :rules="[rules.required]"
              class="mb-4"
              @blur="checkWorkbookKeyDuplicate"
            >
              <template #label>
                <span>活頁簿鍵值 <span class="required-asterisk">*</span></span>
              </template>
            </v-text-field>
            <v-text-field
              v-model="newWorkbook.workbook_name"
              hint="顯示給使用者看的分頁名稱"
              persistent-hint
              variant="outlined"
              :rules="[rules.required]"
              class="mb-4"
            >
              <template #label>
                <span>活頁簿名稱 <span class="required-asterisk">*</span></span>
              </template>
            </v-text-field>
            <v-textarea
              v-model="newWorkbook.description"
              label="說明"
              variant="outlined"
              rows="2"
              class="mb-4"
            />
            <v-switch
              v-model="newWorkbook.is_active"
              label="啟用"
              color="success"
            />
          </v-form>
        </v-card-text>

        <v-divider />

        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn
            color="grey"
            variant="text"
            @click="createDialog = false"
          >
            取消
          </v-btn>
          <v-btn
            color="primary"
            variant="flat"
            :loading="creating"
            @click="handleCreate"
          >
            建立
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- 編輯活頁簿對話框 -->
    <v-dialog
      v-model="editorDialog"
      max-width="1400"
      fullscreen
      scrollable
      persistent
    >
      <OptionWorkbookEditor
        v-if="editorDialog"
        :workbook-id="editingWorkbookId"
        @saved="handleSaved"
        @cancel="editorDialog = false"
      />
    </v-dialog>

    <!-- 編輯基本資訊對話框 -->
    <v-dialog
      v-model="editBasicInfoDialog"
      max-width="600"
      persistent
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-info text-white">
          <v-icon class="mr-2">mdi-information-outline</v-icon>
          <span>編輯基本資訊</span>
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="editBasicInfoDialog = false"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>

        <v-card-text class="pt-6">
          <v-form
            v-if="editingBasicInfo"
            ref="editBasicInfoFormRef"
          >
            <v-text-field
              v-model="editingBasicInfo.workbook_name"
              hint="顯示給使用者看的分頁名稱"
              persistent-hint
              variant="outlined"
              :rules="[rules.required]"
              class="mb-4"
            >
              <template #label>
                <span>活頁簿名稱 <span class="required-asterisk">*</span></span>
              </template>
            </v-text-field>
            <v-textarea
              v-model="editingBasicInfo.description"
              label="說明"
              variant="outlined"
              rows="2"
              class="mb-4"
            />
          </v-form>
        </v-card-text>

        <v-divider />

        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn
            color="grey"
            variant="text"
            @click="editBasicInfoDialog = false"
          >
            取消
          </v-btn>
          <v-btn
            color="info"
            variant="flat"
            :loading="updating"
            @click="handleUpdateBasicInfo"
          >
            儲存
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { optionWorkbooksService } from '@/api/services/optionWorkbooks'
import { useSwal } from '@/composables/useSwal'
import OptionWorkbookEditor from './OptionWorkbookEditor.vue'

const swal = useSwal()

const loading = ref(false)
const workbooks = ref([])
const editorDialog = ref(false)
const createDialog = ref(false)
const editBasicInfoDialog = ref(false)
const editingWorkbookId = ref(null)
const editingBasicInfoId = ref(null)
const creating = ref(false)
const updating = ref(false)
const createFormRef = ref(null)
const editBasicInfoFormRef = ref(null)

const newWorkbook = ref({
  workbook_key: '',
  workbook_name: '',
  description: '',
  is_active: true,
})

const editingBasicInfo = ref({
  workbook_name: '',
  description: '',
})

const rules = {
  required: value => !!value || '此欄位為必填',
}

const headers = [
  { title: '活頁簿鍵值', key: 'workbook_key', sortable: true },
  { title: '活頁簿名稱', key: 'workbook_name', sortable: true },
  { title: '說明', key: 'description', sortable: false },
  { title: '狀態', key: 'is_active', sortable: true },
  { title: '建立時間', key: 'created_at', sortable: true },
  { title: '操作', key: 'actions', sortable: false },
]

// 欄位說明文字
const fieldTooltips = {
  workbook_name: '活頁簿的顯示名稱，用於識別和顯示給使用者',
  workbook_key: '活頁簿的唯一識別碼，用於系統內部引用，格式建議：小寫字母、數字、底線',
  description: '活頁簿的詳細說明，描述其用途和內容',
  is_active: '活頁簿的啟用狀態，停用的活頁簿將無法在表單中使用',
  created_at: '活頁簿建立的時間',
  actions: '可執行的操作：編輯活頁簿內容、編輯基本資訊、刪除活頁簿'
}

// 格式化日期時間
function formatDateTime (dateString) {
  if (!dateString) return ''
  const date = new Date(dateString)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
}

// 載入活頁簿列表
async function loadWorkbooks () {
  loading.value = true
  try {
    workbooks.value = await optionWorkbooksService.getWorkbooks({ is_active: true })
  } catch (error) {
    console.error('載入活頁簿列表失敗', error)
    await swal.error('載入失敗', error.message || '無法取得活頁簿列表')
  } finally {
    loading.value = false
  }
}

// 開啟建立對話框
function openCreateDialog () {
  newWorkbook.value = {
    workbook_key: '',
    workbook_name: '',
    description: '',
    is_active: true,
  }
  createDialog.value = true
}

// 檢查活頁簿鍵值是否重複
async function checkWorkbookKeyDuplicate () {
  const workbookKey = newWorkbook.value.workbook_key?.trim()
  
  // 如果為空，不檢查
  if (!workbookKey) {
    return
  }

  try {
    // 查詢後台是否有相同的鍵值
    const existingWorkbooks = await optionWorkbooksService.getWorkbooks({
      workbook_key: workbookKey,
    })

    // 如果找到重複的鍵值
    if (existingWorkbooks && existingWorkbooks.length > 0) {
      await swal.warning('鍵值重複', `活頁簿鍵值「${workbookKey}」已存在，請使用其他鍵值。`)
      // 清空輸入框，讓使用者重新輸入
      newWorkbook.value.workbook_key = ''
    }
  } catch (error) {
    console.error('檢查鍵值重複失敗', error)
    // 檢查失敗時不阻止使用者繼續，只記錄錯誤
  }
}

// 建立活頁簿（僅基本資訊）
async function handleCreate () {
  // 驗證表單
  if (!createFormRef.value) {
    return
  }
  const { valid } = await createFormRef.value.validate()
  if (!valid) {
    return
  }

  // 再次檢查鍵值是否重複（防止在驗證後又被修改）
  const workbookKey = newWorkbook.value.workbook_key?.trim()
  if (workbookKey) {
    try {
      const existingWorkbooks = await optionWorkbooksService.getWorkbooks({
        workbook_key: workbookKey,
      })

      if (existingWorkbooks && existingWorkbooks.length > 0) {
        await swal.warning('鍵值重複', `活頁簿鍵值「${workbookKey}」已存在，請使用其他鍵值。`)
        return
      }
    } catch (error) {
      console.error('檢查鍵值重複失敗', error)
      await swal.error('驗證失敗', '無法驗證鍵值是否重複，請稍後再試')
      return
    }
  }

  creating.value = true
  try {
    await optionWorkbooksService.createWorkbook({
      workbook_key: newWorkbook.value.workbook_key,
      workbook_name: newWorkbook.value.workbook_name,
      description: newWorkbook.value.description || '',
      is_active: newWorkbook.value.is_active,
      columns: [], // 空欄位，後續編輯時再添加
      rows: [], // 空資料，後續編輯時再添加
    })
    await swal.success('活頁簿已建立！')
    createDialog.value = false
    await loadWorkbooks()
  } catch (error) {
    console.error('建立活頁簿失敗', error)
    // 檢查是否為唯一性約束錯誤
    if (error.message && (error.message.includes('unique') || error.message.includes('重複'))) {
      await swal.warning('鍵值重複', `活頁簿鍵值「${newWorkbook.value.workbook_key}」已存在，請使用其他鍵值。`)
    } else {
      await swal.error('建立失敗', error.message || '無法建立活頁簿')
    }
  } finally {
    creating.value = false
  }
}

// 開啟編輯對話框
function openEditor (id) {
  editingWorkbookId.value = id
  editorDialog.value = true
}

// 處理儲存成功
async function handleSaved () {
  // 不關閉 dialog，只重新載入活頁簿列表
  await loadWorkbooks()
}

// 開啟編輯基本資訊對話框
async function openEditBasicInfo (item) {
  editingBasicInfoId.value = item.id
  editingBasicInfo.value = {
    workbook_name: item.workbook_name || '',
    description: item.description || '',
  }
  editBasicInfoDialog.value = true
}

// 儲存基本資訊
async function handleUpdateBasicInfo () {
  // 驗證表單
  if (!editBasicInfoFormRef.value) {
    return
  }
  const { valid } = await editBasicInfoFormRef.value.validate()
  if (!valid) {
    return
  }

  updating.value = true
  try {
    // 先取得現有的活頁簿資料
    const existingData = await optionWorkbooksService.getWorkbook(editingBasicInfoId.value, true, true)
    
    // 更新基本資訊
    await optionWorkbooksService.updateWorkbook(editingBasicInfoId.value, {
      ...existingData,
      workbook_name: editingBasicInfo.value.workbook_name,
      description: editingBasicInfo.value.description || '',
    })
    
    await swal.success('基本資訊已更新！')
    editBasicInfoDialog.value = false
    editingBasicInfoId.value = null
    await loadWorkbooks()
  } catch (error) {
    console.error('更新基本資訊失敗', error)
    await swal.error('更新失敗', error.message || '無法更新基本資訊')
  } finally {
    updating.value = false
  }
}

// 刪除活頁簿
async function deleteWorkbook (id) {
  try {
    const result = await swal.confirm('確定要刪除這個活頁簿嗎？此操作無法復原。')
    if (!result.isConfirmed) return

    await optionWorkbooksService.deleteWorkbook(id)
    await swal.success('活頁簿已刪除')
    await loadWorkbooks()
  } catch (error) {
    console.error('刪除活頁簿失敗', error)
    await swal.error('刪除失敗', error.message || '無法刪除活頁簿')
  }
}

onMounted(() => {
  loadWorkbooks()
})
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

// 必填欄位標題的紅色星號
.required-asterisk {
  color: #d32f2f; // 紅色
  font-weight: bold;
}
</style>
