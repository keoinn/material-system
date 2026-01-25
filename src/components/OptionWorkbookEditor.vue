<template>
  <v-card class="d-flex flex-column" style="height: 100%;">
    <v-card-title class="d-flex align-center bg-primary text-white flex-shrink-0">
      <v-icon class="mr-2">mdi-table-edit</v-icon>
      <span>編輯活頁簿：{{ workbookData.workbook_name || '載入中...' }}</span>
      <v-spacer />
      <v-btn
        icon
        variant="text"
        @click="handleCancel"
      >
        <v-icon>mdi-close</v-icon>
      </v-btn>
    </v-card-title>

    <v-card-text class="pa-0 d-flex flex-column flex-grow-1" style="overflow: hidden;">
      <v-window
        v-model="activeTab"
        class="flex-grow-1"
        style="overflow-y: auto;"
      >
          <!-- 定義儲存格 Tab -->
          <v-window-item value="columns">
            <v-card variant="flat" class="d-flex flex-column" style="height: 100%;">
              <v-card-title class="d-flex align-center justify-space-between bg-grey-lighten-4 flex-shrink-0">
                <div class="d-flex align-center">
                  <v-icon class="mr-2">mdi-table-column</v-icon>
                  <span>定義儲存格</span>
                </div>
                <v-btn
                  color="primary"
                  size="small"
                  prepend-icon="mdi-plus"
                  @click="addColumn"
                >
                  新增欄位
                </v-btn>
              </v-card-title>
              <v-card-text class="flex-grow-1" style="overflow-y: auto;">
                <v-data-table
                  :headers="columnHeaders"
                  :items="workbookData.columns"
                  class="elevation-0"
                >
                  <template #header.column_key="{ column }">
                    <div class="d-flex align-center">
                      <span>{{ column.title }}</span>
                      <span class="required-asterisk">*</span>
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
                        <span>{{ fieldTooltips.column_key }}</span>
                      </v-tooltip>
                    </div>
                  </template>

                  <template #header.column_label="{ column }">
                    <div class="d-flex align-center">
                      <span>{{ column.title }}</span>
                      <span class="required-asterisk">*</span>
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
                        <span>{{ fieldTooltips.column_label }}</span>
                      </v-tooltip>
                    </div>
                  </template>

                  <template #header.column_type="{ column }">
                    <div class="d-flex align-center">
                      <span>{{ column.title }}</span>
                      <span class="required-asterisk">*</span>
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
                        <span>{{ fieldTooltips.column_type }}</span>
                      </v-tooltip>
                    </div>
                  </template>

                  <template #header.is_key="{ column }">
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
                        <span>{{ fieldTooltips.is_key }}</span>
                      </v-tooltip>
                    </div>
                  </template>

                  <template #header.is_label="{ column }">
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
                        <span>{{ fieldTooltips.is_label }}</span>
                      </v-tooltip>
                    </div>
                  </template>

                  <template #item.column_key="{ item, index }">
                    <v-text-field
                      v-model="item.column_key"
                      density="compact"
                      variant="outlined"
                      hide-details
                      :rules="[rules.required]"
                      :placeholder="generateColumnKey(index)"
                      :class="{ 'error-field': columnErrors[index]?.column_key }"
                      @input="clearColumnError(index, 'column_key')"
                    />
                  </template>

                  <template #item.column_label="{ item, index }">
                    <v-text-field
                      v-model="item.column_label"
                      density="compact"
                      variant="outlined"
                      hide-details
                      :rules="[rules.required]"
                      :class="{ 'error-field': columnErrors[index]?.column_label }"
                      @input="clearColumnError(index, 'column_label')"
                    />
                  </template>

                  <template #item.column_type="{ item, index }">
                    <v-text-field
                      v-model="item.column_type"
                      density="compact"
                      variant="outlined"
                      hide-details
                      :rules="[rules.required]"
                      placeholder="例如：text, number, boolean, date, select"
                      :class="{ 'error-field': columnErrors[index]?.column_type }"
                      @input="clearColumnError(index, 'column_type')"
                    />
                  </template>

                  <template #item.is_key="{ item }">
                    <v-checkbox
                      v-model="item.is_key"
                      density="compact"
                      hide-details
                      @update:model-value="onKeyColumnChange(item)"
                    />
                  </template>

                  <template #item.is_label="{ item }">
                    <v-checkbox
                      v-model="item.is_label"
                      density="compact"
                      hide-details
                      @update:model-value="onLabelColumnChange(item)"
                    />
                  </template>

                  <template #item.actions="{ index }">
                    <v-btn
                      icon
                      size="x-small"
                      color="error"
                      @click="removeColumn(index)"
                    >
                      <v-icon>mdi-delete</v-icon>
                    </v-btn>
                  </template>
                </v-data-table>
              </v-card-text>
            </v-card>
          </v-window-item>

          <!-- 資料編輯 Tab -->
          <v-window-item value="rows">
            <v-card variant="flat" class="d-flex flex-column" style="height: 100%;">
              <v-card-title class="d-flex align-center justify-space-between bg-grey-lighten-4 flex-shrink-0">
                <div class="d-flex align-center">
                  <v-icon class="mr-2">mdi-table-edit</v-icon>
                  <span>資料編輯</span>
                </div>
                <div
                  v-if="workbookData.columns.length > 0"
                  class="d-flex align-center"
                  style="gap: 8px;"
                >
                  <v-btn
                    color="success"
                    size="small"
                    prepend-icon="mdi-plus"
                    @click="addRow"
                  >
                    新增資料行
                  </v-btn>
                </div>
              </v-card-title>
              <v-card-text class="flex-grow-1" style="overflow-y: auto;">
                <v-alert
                  v-if="workbookData.columns.length === 0"
                  type="info"
                  variant="tonal"
                  class="mb-4"
                >
                  <strong>提示：</strong>
                  請先定義欄位後再編輯資料。欄位定義中必須包含一個外部鍵值和一個外部標籤欄位。
                </v-alert>
                <div
                  v-else
                  class="excel-editor-container"
                >
                  <vue-excel-editor
                    ref="excelEditorRef"
                    v-model="excelData"
                    filter-row
                    :height="excelEditorHeight"
                  >
                    <!-- Key欄位 -->
                    <vue-excel-column
                      v-if="keyColumn"
                      type="string"
                      field="row_key"
                      :width="keyColumn.column_config?.width || '150px'"
                      :label="keyColumn.column_label || 'Key'"
                    />
                    <!-- Label欄位 -->
                    <vue-excel-column
                      v-if="labelColumn"
                      type="string"
                      field="row_label"
                      :width="labelColumn.column_config?.width || '200px'"
                      :label="labelColumn.column_label || 'Label'"
                    />
                    <!-- 動態欄位（排除key和label欄位） -->
                    <vue-excel-column
                      v-for="column in otherColumns"
                      :key="column.column_key"
                      :type="getExcelColumnType(column.column_type)"
                      :field="column.column_key"
                      :width="column.column_config?.width || '150px'"
                      :label="column.column_label"
                      :options="column.column_config?.options"
                      :readonly="column.is_readonly"
                    />
                  </vue-excel-editor>
                </div>
              </v-card-text>
            </v-card>
          </v-window-item>
        </v-window>

        <!-- Tabs 放在底部 -->
        <v-tabs
          v-model="activeTab"
          bg-color="grey-lighten-4"
          slider-color="primary"
          class="mt-auto"
        >
           <v-tab value="columns">
             <v-icon class="mr-2">mdi-table-column</v-icon>
             定義儲存格
           </v-tab>
          <v-tab value="rows">
            <v-icon class="mr-2">mdi-table-edit</v-icon>
            資料編輯
          </v-tab>
        </v-tabs>
      </v-card-text>

      <v-divider class="flex-shrink-0" />

      <v-card-actions class="pa-4 flex-shrink-0">
      <v-spacer />
      <v-btn
        color="grey"
        variant="text"
        @click="handleCancel"
      >
        取消
      </v-btn>
      <v-btn
        color="primary"
        variant="flat"
        :loading="saving"
        @click="handleSave"
      >
        儲存
      </v-btn>
    </v-card-actions>
  </v-card>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { optionWorkbooksService } from '@/api/services/optionWorkbooks'
import { useSwal } from '@/composables/useSwal'

const props = defineProps({
  workbookId: {
    type: Number,
    default: null,
  },
})

const emit = defineEmits(['saved', 'cancel'])

const swal = useSwal()

const saving = ref(false)
const loading = ref(false)
const editingCell = ref(null)
const activeTab = ref('columns')
// 追蹤欄位錯誤狀態（用於顯示紅色背景）
const columnErrors = ref({}) // { columnIndex: { column_key: boolean, column_label: boolean, column_type: boolean } }

const isEditMode = computed(() => !!props.workbookId)

const workbookData = reactive({
  workbook_key: '',
  workbook_name: '',
  description: '',
  is_active: true,
  columns: [],
  rows: [],
})

// 獲取 key 和 label 欄位
const keyColumn = computed(() => workbookData.columns.find(col => col.is_key))
const labelColumn = computed(() => workbookData.columns.find(col => col.is_label))
const otherColumns = computed(() => workbookData.columns.filter(col => !col.is_key && !col.is_label))

// 將 rows 轉換為 excel-editor 需要的格式（扁平化）
function convertRowsToExcelData () {
  return workbookData.rows.map(row => {
    const flatRow = {
      _id: row.id, // 保留原始ID用於追蹤
      row_key: row.row_key || '',
      row_label: row.row_label || '',
    }
    // 將 row_data 中的欄位扁平化
    if (row.row_data) {
      Object.keys(row.row_data).forEach(key => {
        flatRow[key] = row.row_data[key] ?? ''
      })
    }
    return flatRow
  })
}

// 將 excel-editor 的資料轉換回 rows 格式
function convertExcelDataToRows (excelDataArray) {
  return excelDataArray.map((flatRow, index) => {
    const rowData = {}
    // 提取 row_data 中的欄位
    otherColumns.value.forEach(col => {
      if (flatRow[col.column_key] !== undefined) {
        rowData[col.column_key] = flatRow[col.column_key]
      }
    })
    return {
      id: flatRow._id || Date.now() + index,
      row_key: flatRow.row_key || '',
      row_label: flatRow.row_label || '',
      row_data: rowData,
      display_order: index,
      is_active: true,
    }
  })
}

const excelData = ref([])
const isSyncing = ref(false) // 防止循環更新
const excelEditorRef = ref(null)
const excelEditorHeight = ref('600px') // vue-excel-editor 的 height prop 需要像素值字符串

// 計算 excel editor 的高度
function calculateExcelEditorHeight () {
  nextTick(() => {
    const cardText = document.querySelector('.excel-editor-container')?.closest('.v-card-text')
    if (cardText) {
      const rect = cardText.getBoundingClientRect()
      // 減去一些邊距和標題高度，確保不會溢出
      const calculatedHeight = Math.max(400, rect.height - 100)
      excelEditorHeight.value = `${calculatedHeight}px`
    }
  })
}

// 監聽 excelData 的變更，同步回 workbookData.rows（單向同步）
watch(excelData, (newValue) => {
  if (isSyncing.value) return
  isSyncing.value = true
  try {
    workbookData.rows = convertExcelDataToRows(newValue || [])
  } catch (error) {
    console.error('轉換 excelData 失敗', error)
  } finally {
    isSyncing.value = false
  }
}, { deep: true })

const columnHeaders = [
  { title: '系統編號', key: 'column_key', sortable: false },
  { title: '儲存格名稱', key: 'column_label', sortable: false },
  { title: '儲存格型態', key: 'column_type', sortable: false },
  { title: '外部鍵值', key: 'is_key', sortable: false },
  { title: '外部標籤', key: 'is_label', sortable: false },
  { title: '操作', key: 'actions', sortable: false },
]

// 欄位說明文字
const fieldTooltips = {
  column_key: '系統內部使用的欄位識別碼，用於資料儲存和讀取。建議格式：活頁簿Key + 序號（例如：suppliers_001），也可自訂',
  column_label: '顯示給使用者看的欄位名稱，用於表格標題和表單標籤',
  column_type: '欄位的資料型態，例如：text（文字）、number（數字）、boolean（布林值）、date（日期）、select（選單）',
  is_key: '標記此欄位為外部鍵值，用於識別記錄的唯一值。每個活頁簿必須有一個外部鍵值欄位',
  is_label: '標記此欄位為外部標籤，用於顯示記錄的名稱。每個活頁簿必須有一個外部標籤欄位'
}

// 產生系統編號（活頁簿key + 序號）
function generateColumnKey (index) {
  const workbookKey = workbookData.workbook_key || 'workbook'
  // 序號從 001 開始，使用三位數格式
  const sequence = String(index + 1).padStart(3, '0')
  return `${workbookKey}_${sequence}`
}

// 將欄位類型映射到 vue-excel-editor 的類型
function getExcelColumnType (columnType) {
  const typeMap = {
    'text': 'string',
    'number': 'number',
    'boolean': 'boolean',
    'date': 'date',
    'select': 'map',
  }
  return typeMap[columnType] || 'string'
}

const rules = {
  required: value => !!value || '此欄位為必填',
  uniqueKey: value => {
    if (!value) return true
    // 檢查key是否唯一（排除當前編輯的）
    const duplicates = workbookData.columns.filter(
      col => col.column_key === value && col !== editingCell.value
    )
    return duplicates.length === 0 || '欄位Key必須唯一'
  },
}

// 載入活頁簿資料
async function loadWorkbook () {
  if (!props.workbookId) {
    // 新增模式，不預設欄位（空欄位和空資料）
    workbookData.columns = []
    workbookData.rows = []
    return
  }

  loading.value = true
  try {
    const data = await optionWorkbooksService.getWorkbook(props.workbookId, true, true)
    if (data) {
      Object.assign(workbookData, {
        workbook_key: data.workbook_key,
        workbook_name: data.workbook_name,
        description: data.description || '',
        is_active: data.is_active !== undefined ? data.is_active : true,
        columns: (data.columns || []).map((col, index) => ({
          ...col,
          // 如果沒有 column_key 或不符合格式，自動生成
          column_key: col.column_key || generateColumnKey(index),
          column_config: col.column_config || {},
        })),
        rows: (data.rows || []).map(row => {
          const rowData = row.row_data || {}
          // 確保所有欄位都有對應的值（如果欄位定義存在但資料中沒有）
          const processedRowData = { ...rowData }
          if (data.columns) {
            data.columns.forEach(col => {
              if (!col.is_key && !col.is_label && processedRowData[col.column_key] === undefined) {
                processedRowData[col.column_key] = ''
              }
            })
          }
          return {
            id: row.id,
            row_key: row.row_key,
            row_label: row.row_label,
            row_data: processedRowData,
            display_order: row.display_order || 0,
            is_active: row.is_active !== undefined ? row.is_active : true,
          }
        }),
      })
      // 初始化 excelData（暫時禁用同步以避免觸發 watch）
      isSyncing.value = true
      excelData.value = convertRowsToExcelData()
      isSyncing.value = false
    }
  } catch (error) {
    console.error('載入活頁簿失敗', error)
    await swal.error('載入失敗', error.message || '無法取得活頁簿資料')
  } finally {
    loading.value = false
  }
}

// 清除欄位錯誤狀態
function clearColumnError (index, field) {
  if (columnErrors.value[index]) {
    delete columnErrors.value[index][field]
    // 如果該欄位沒有其他錯誤，移除整個索引
    if (Object.keys(columnErrors.value[index]).length === 0) {
      delete columnErrors.value[index]
    }
  }
}

// 新增欄位
function addColumn () {
  const newIndex = workbookData.columns.length
  const newColumnKey = generateColumnKey(newIndex)
  
  workbookData.columns.push({
    column_key: newColumnKey,
    column_label: '',
    column_type: 'text',
    is_key: false,
    is_label: false,
    display_order: newIndex,
    column_config: {},
  })
}

// 移除欄位
function removeColumn (index) {
  const column = workbookData.columns[index]
  if (column.is_key || column.is_label) {
    swal.warning('無法刪除', '外部鍵值和外部標籤欄位無法刪除')
    return
  }
  workbookData.columns.splice(index, 1)
  // 從所有資料行中移除該欄位的資料
  workbookData.rows.forEach(row => {
    if (row.row_data[column.column_key] !== undefined) {
      delete row.row_data[column.column_key]
    }
  })
}

// Key欄位變更處理
function onKeyColumnChange (column) {
  if (column.is_key) {
    // 確保只有一個key欄位
    workbookData.columns.forEach(col => {
      if (col !== column && col.is_key) {
        col.is_key = false
      }
    })
    // 如果沒有 column_key，自動生成
    if (!column.column_key) {
      const index = workbookData.columns.indexOf(column)
      column.column_key = generateColumnKey(index)
    }
    // 設定預設標籤
    if (!column.column_label) {
      column.column_label = 'Key'
    }
  }
}

// Label欄位變更處理
function onLabelColumnChange (column) {
  if (column.is_label) {
    // 確保只有一個label欄位
    workbookData.columns.forEach(col => {
      if (col !== column && col.is_label) {
        col.is_label = false
      }
    })
    // 如果沒有 column_key，自動生成
    if (!column.column_key) {
      const index = workbookData.columns.indexOf(column)
      column.column_key = generateColumnKey(index)
    }
    // 設定預設標籤
    if (!column.column_label) {
      column.column_label = 'Label'
    }
  }
}

// 新增資料行
async function addRow () {
  // 確保 excelData 是數組
  if (!Array.isArray(excelData.value)) {
    excelData.value = []
  }
  
  const newRow = {
    _id: Date.now() + Math.random(), // 臨時ID
    row_key: '',
    row_label: '',
  }
  
  // 初始化所有欄位的預設值
  workbookData.columns.forEach(column => {
    if (!column.is_key && !column.is_label) {
      newRow[column.column_key] = ''
    }
  })
  
  // 暫時禁用同步
  isSyncing.value = true
  try {
    // 直接添加到 excelData（vue-excel-editor 的數據源）
    // 使用展開運算符創建新數組以觸發響應式更新
    excelData.value = [...excelData.value, newRow]
    
    // 等待 DOM 更新
    await nextTick()
  } finally {
    isSyncing.value = false
  }
}

// 移除資料行
function removeRow (index) {
  workbookData.rows.splice(index, 1)
}


// 處理儲存格焦點
function handleCellFocus (item, columnKey) {
  editingCell.value = { item, columnKey }
}

// 處理儲存格失焦
function handleCellBlur (item, columnKey) {
  editingCell.value = null
}

// 儲存活頁簿
async function handleSave () {
  // 過濾掉空的資料行（row_key 和 row_label 都為空）
  const validExcelData = (excelData.value || []).filter(
    row => row.row_key && row.row_key.trim() !== '' && row.row_label && row.row_label.trim() !== ''
  )
  
  // 如果有欄位定義，則驗證欄位結構
  if (workbookData.columns.length > 0) {
    const keyColumn = workbookData.columns.find(col => col.is_key)
    const labelColumn = workbookData.columns.find(col => col.is_label)

    if (!keyColumn || !labelColumn) {
      await swal.warning('欄位定義錯誤', '必須定義一個外部鍵值和一個外部標籤欄位')
      return
    }

    // 驗證欄位Key唯一性
    const columnKeys = workbookData.columns.map(col => col.column_key).filter(Boolean)
    if (new Set(columnKeys).size !== columnKeys.length) {
      await swal.warning('欄位Key重複', '欄位Key必須唯一')
      return
    }

    // 驗證資料行的key和label（如果有資料行）
    if (excelData.value && excelData.value.length > 0 && validExcelData.length !== excelData.value.length) {
      await swal.warning('資料不完整', '部分資料行的Key或Label為空，這些資料行將不會被儲存')
    }
  }

  // 驗證必填欄位
  const errors = {}
  let hasErrors = false
  
  workbookData.columns.forEach((col, index) => {
    const colErrors = {}
    if (!col.column_key || col.column_key.trim() === '') {
      colErrors.column_key = true
      hasErrors = true
    }
    if (!col.column_label || col.column_label.trim() === '') {
      colErrors.column_label = true
      hasErrors = true
    }
    if (!col.column_type || col.column_type.trim() === '') {
      colErrors.column_type = true
      hasErrors = true
    }
    if (Object.keys(colErrors).length > 0) {
      errors[index] = colErrors
    }
  })
  
  // 如果有錯誤，顯示錯誤狀態並停止儲存
  if (hasErrors) {
    columnErrors.value = errors
    await swal.warning('請填寫必填欄位', '系統編號、儲存格名稱與儲存格類型為必填欄位，請檢查後再試')
    return
  }
  
  // 清除錯誤狀態
  columnErrors.value = {}

  saving.value = true
  try {
    const dataToSave = {
      workbook_key: workbookData.workbook_key,
      workbook_name: workbookData.workbook_name,
      description: workbookData.description || '',
      is_active: workbookData.is_active,
      columns: workbookData.columns.map((col, index) => ({
        column_key: col.column_key,
        column_label: col.column_label,
        column_type: col.column_type,
        is_key: col.is_key,
        is_label: col.is_label,
        display_order: col.display_order !== undefined ? col.display_order : index,
        column_config: col.column_config || {},
        is_visible: col.is_visible !== undefined ? col.is_visible : true,
        is_required: col.is_required || false,
      })),
      rows: convertExcelDataToRows(validExcelData), // 從 excelData 轉換，只包含有效的資料行
    }

    if (isEditMode.value) {
      await optionWorkbooksService.updateWorkbook(props.workbookId, dataToSave)
    } else {
      await optionWorkbooksService.createWorkbook(dataToSave)
    }

    await swal.success('儲存成功！')
    
    // 重新載入活頁簿資料以確保資料同步
    await loadWorkbook()
    
    emit('saved')
  } catch (error) {
    console.error('儲存活頁簿失敗', error)
    await swal.error('儲存失敗', error.message || '無法儲存活頁簿')
  } finally {
    saving.value = false
  }
}

// 取消編輯
function handleCancel () {
  emit('cancel')
}

onMounted(async () => {
  await loadWorkbook()
  // 計算 excel editor 高度
  calculateExcelEditorHeight()
  
  // 監聽窗口大小變化
  window.addEventListener('resize', calculateExcelEditorHeight)
})

onUnmounted(() => {
  window.removeEventListener('resize', calculateExcelEditorHeight)
})
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.excel-editor-container {
  width: 100%;
  height: 100%;
  overflow: auto;
}

// 必填欄位標題的紅色星號
.required-asterisk {
  color: #d32f2f; // 紅色
  font-weight: bold;
  margin-left: 2px;
}

// 錯誤欄位的淺紅色背景
:deep(.error-field) {
  .v-field__input {
    background-color: #ffebee !important; // 淺紅色
  }
  
  &:focus-within .v-field__input {
    background-color: transparent !important; // 輸入時恢復預設
  }
}
</style>
