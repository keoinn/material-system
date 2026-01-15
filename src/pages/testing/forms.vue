<template>
  <v-container>
    <v-card>
      <v-card-title class="system-header">
        <h2>動態表單系統測試頁面</h2>
      </v-card-title>

      <v-card-text class="pt-6">
        <v-tabs v-model="activeTab" class="mb-4">
          <v-tab value="api">API 測試</v-tab>
          <v-tab value="renderer">表單渲染器</v-tab>
          <v-tab value="designer">表單設計器</v-tab>
        </v-tabs>

        <v-window v-model="activeTab">
          <!-- API 測試 -->
          <v-window-item value="api">
            <v-card variant="outlined" class="pa-4 mb-4">
              <v-card-title>API 服務測試</v-card-title>
              <v-card-text>
                <v-btn
                  color="primary"
                  class="mr-2 mb-2"
                  @click="testGetForms"
                >
                  測試：取得所有表單
                </v-btn>
                <v-btn
                  color="primary"
                  class="mr-2 mb-2"
                  @click="testGetForm"
                >
                  測試：取得單一表單
                </v-btn>
                <v-btn
                  color="primary"
                  class="mr-2 mb-2"
                  @click="testGetFields"
                >
                  測試：取得欄位列表
                </v-btn>
                <v-btn
                  color="success"
                  class="mr-2 mb-2"
                  @click="testCreateFormData"
                >
                  測試：建立表單資料
                </v-btn>
                <v-btn
                  color="success"
                  class="mr-2 mb-2"
                  @click="testGetFormData"
                >
                  測試：取得表單資料
                </v-btn>
              </v-card-text>
            </v-card>

            <v-card variant="outlined" class="pa-4">
              <v-card-title>測試結果</v-card-title>
              <v-card-text>
                <pre class="test-result">{{ testResult }}</pre>
              </v-card-text>
            </v-card>
          </v-window-item>

          <!-- 表單渲染器測試 -->
          <v-window-item value="renderer">
            <v-card variant="outlined" class="pa-4 mb-4">
              <v-card-title>表單渲染器測試</v-card-title>
              <v-card-text>
                <v-text-field
                  v-model="testFormId"
                  label="表單 ID 或 form_code"
                  placeholder="例如：material_application"
                  variant="outlined"
                  class="mb-4"
                />
                <v-text-field
                  v-model="testRecordId"
                  label="記錄 ID（可選，用於編輯模式）"
                  variant="outlined"
                  class="mb-4"
                />
                <v-btn
                  color="primary"
                  @click="loadFormRenderer"
                >
                  載入表單
                </v-btn>
              </v-card-text>
            </v-card>

            <DynamicFormRenderer
              v-if="showRenderer"
              ref="rendererRef"
              :form-id="testFormId"
              :record-id="testRecordId || null"
              :auto-load="false"
              @submit="handleFormSubmit"
            />
          </v-window-item>

          <!-- 表單設計器測試 -->
          <v-window-item value="designer">
            <v-card variant="outlined" class="pa-4 mb-4">
              <v-card-title>表單設計器測試</v-card-title>
              <v-card-text>
                <v-text-field
                  v-model="editFormId"
                  label="表單 ID（留空則建立新表單）"
                  variant="outlined"
                  class="mb-4"
                />
                <v-btn
                  color="primary"
                  @click="openDesigner"
                >
                  開啟表單設計器
                </v-btn>
              </v-card-text>
            </v-card>
          </v-window-item>
        </v-window>
      </v-card-text>
    </v-card>

    <!-- 表單設計器對話框 -->
    <v-dialog
      v-model="designerDialog"
      max-width="1200"
      fullscreen
      scrollable
      persistent
    >
      <FormDesigner
        v-if="designerDialog"
        :form-id="editFormId || null"
        @saved="handleDesignerSaved"
        @cancel="designerDialog = false"
      />
    </v-dialog>
  </v-container>
</template>

<script setup>
import { ref } from 'vue'
import { formsService } from '@/api/services/forms'
import { formFieldsService } from '@/api/services/formFields'
import { formDataService } from '@/api/services/formData'
import { useSwal } from '@/composables/useSwal'
import DynamicFormRenderer from '@/components/DynamicFormRenderer.vue'
import FormDesigner from '@/components/FormDesigner.vue'

const swal = useSwal()

const activeTab = ref('api')
const testResult = ref('點擊上方按鈕開始測試...')
const testFormId = ref('material_application')
const testRecordId = ref('')
const showRenderer = ref(false)
const rendererRef = ref(null)
const editFormId = ref('')
const designerDialog = ref(false)

// API 測試
async function testGetForms () {
  try {
    testResult.value = '測試中...'
    const forms = await formsService.getForms()
    testResult.value = JSON.stringify(forms, null, 2)
    await swal.success(`成功取得 ${forms.length} 個表單`)
  } catch (error) {
    testResult.value = `錯誤：${error.message}\n${error.stack}`
    await swal.error('測試失敗：' + error.message)
  }
}

async function testGetForm () {
  try {
    testResult.value = '測試中...'
    const form = await formsService.getForm('material_application', true)
    testResult.value = JSON.stringify(form, null, 2)
    await swal.success('成功取得表單定義')
  } catch (error) {
    testResult.value = `錯誤：${error.message}\n${error.stack}`
    await swal.error('測試失敗：' + error.message)
  }
}

async function testGetFields () {
  try {
    testResult.value = '測試中...'
    const fields = await formFieldsService.getFields('material_application')
    testResult.value = JSON.stringify(fields, null, 2)
    await swal.success(`成功取得 ${fields.length} 個欄位`)
  } catch (error) {
    testResult.value = `錯誤：${error.message}\n${error.stack}`
    await swal.error('測試失敗：' + error.message)
  }
}

async function testCreateFormData () {
  try {
    testResult.value = '測試中...'
    const recordId = Date.now()
    const formData = await formDataService.createFormData('material_application', {
      item_name_cn: '測試物料',
      item_name_en: 'Test Material',
      material: 'Steel',
    }, {
      createRecord: true,
      recordId,
    })
    testResult.value = JSON.stringify(formData, null, 2)
    await swal.success(`成功建立表單資料，記錄 ID：${recordId}`)
  } catch (error) {
    testResult.value = `錯誤：${error.message}\n${error.stack}`
    await swal.error('測試失敗：' + error.message)
  }
}

async function testGetFormData () {
  try {
    testResult.value = '測試中...'
    if (!testRecordId.value) {
      await swal.warning('請先輸入記錄 ID')
      return
    }
    const data = await formDataService.getFormData('material_application', testRecordId.value)
    testResult.value = JSON.stringify(data, null, 2)
    await swal.success('成功取得表單資料')
  } catch (error) {
    testResult.value = `錯誤：${error.message}\n${error.stack}`
    await swal.error('測試失敗：' + error.message)
  }
}

// 表單渲染器測試
function loadFormRenderer () {
  if (!testFormId.value) {
    swal.warning('請輸入表單 ID 或 form_code')
    return
  }
  showRenderer.value = true
}

async function handleFormSubmit (formValues) {
  console.log('表單提交:', formValues)
  await swal.success('表單提交成功！\n值：' + JSON.stringify(formValues, null, 2))
}

// 表單設計器測試
function openDesigner () {
  designerDialog.value = true
}

async function handleDesignerSaved (formId) {
  designerDialog.value = false
  await swal.success(`表單已儲存，ID：${formId}`)
  editFormId.value = formId.toString()
}
</script>

<style scoped>
.test-result {
  background: #f5f5f5;
  padding: 16px;
  border-radius: 4px;
  max-height: 500px;
  overflow: auto;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  white-space: pre-wrap;
  word-wrap: break-word;
}
</style>
