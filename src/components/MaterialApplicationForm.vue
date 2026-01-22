<template>
  <div>
    <v-alert
      v-if="!defaultFormId && !loading"
      class="mb-4"
      type="warning"
      variant="tonal"
    >
      尚未設定預設表單，請先到「表單管理」設定預設表單。
    </v-alert>

    <DynamicFormRenderer
      v-if="defaultFormId"
      ref="formRendererRef"
      cancel-text="清除表單"
      :form-id="defaultFormId"
      :show-actions="true"
      :show-cancel="true"
      :show-title="true"
      submit-text="提交申請"
      @cancel="handleClear"
      @submit="handleSubmit"
      @field-update="handleFieldUpdate"
    />
  </div>
</template>

<script setup>
  import { onMounted, ref } from 'vue'
  import { useRouter } from 'vue-router'
  import { formDataService } from '@/api/services/formData'
  import { formFieldsService } from '@/api/services/formFields'
  import { formsService } from '@/api/services/forms'
  import { packagingService } from '@/api/services/packaging'
  import { useSwal } from '@/composables/useSwal'
  import DynamicFormRenderer from './DynamicFormRenderer.vue'

  const swal = useSwal()
  const router = useRouter()

  const formRendererRef = ref(null)
  const loading = ref(false)
  const defaultFormId = ref(null)
  const loadingTemplate = ref(false)

  // 載入預設表單
  async function loadDefaultForm () {
    loading.value = true
    try {
      const defaultForms = await formsService.getForms({ is_default: true, is_active: true })
      if (defaultForms && defaultForms.length > 0) {
        defaultFormId.value = defaultForms[0].id
      } else {
        // 如果沒有預設表單，嘗試使用 form_code 為 'material_application' 的表單
        try {
          const materialForm = await formsService.getForm('material_application', false)
          if (materialForm && materialForm.is_active) {
            defaultFormId.value = materialForm.id
          }
        } catch (error) {
          console.error('載入 material_application 表單失敗', error)
        }
      }
    } catch (error) {
      console.error('載入預設表單失敗', error)
      await swal.error('載入表單定義失敗，請稍後再試')
    } finally {
      loading.value = false
    }
  }

  // 處理表單提交
  async function handleSubmit (formValues) {
    if (!defaultFormId.value) {
      await swal.warning('表單尚未載入完成')
      return
    }

    try {
      // 使用 formDataService 建立表單資料（新建記錄）
      // 使用 createRecord 選項自動建立記錄 ID
      const result = await formDataService.createFormData(defaultFormId.value, formValues, { createRecord: true })

      const recordId = result?.record_id || result?.id || 'N/A'
      await swal.success(`申請單號：${recordId}`, '申請已提交！')

      // 清除表單
      handleClear()

      // 跳轉到審核管理頁面
      router.push({ path: '/', query: { tab: 'review' } })
    } catch (error) {
      console.error('提交申請失敗', error)
      const errorMessage = error.message || '提交申請時發生錯誤'
      await swal.error(errorMessage)
    }
  }

  // 處理清除表單
  function handleClear () {
    if (formRendererRef.value) {
      formRendererRef.value.reset()
    }
  }

  // 處理欄位更新事件
  async function handleFieldUpdate (event) {
    const { fieldKey, value, formValues } = event

    // 檢查是否是產品大類欄位的更新
    // 產品大類可能是：
    // 1. main_type - 單獨的欄位，值直接是產品大類代碼（如 'H', 'S', 'M'）
    // 2. type - cascading_select，值是一個數組，第一層是產品大類代碼
    // 3. main_category - 舊版欄位名稱（向後兼容）
    let mainCategoryCode = null

    // 優先檢查 main_type 欄位
    if (fieldKey === 'main_type') {
      if (typeof value === 'string' && value) {
        mainCategoryCode = value
      }
    }
    // 檢查 type 欄位（cascading_select）
    else if (fieldKey === 'type') {
      if (Array.isArray(value) && value.length > 0 && value[0]) {
        mainCategoryCode = value[0]
      }
    }
    // 向後兼容：檢查 main_category 欄位
    else if (fieldKey === 'main_category') {
      if (Array.isArray(value) && value.length > 0 && value[0]) {
        mainCategoryCode = value[0]
      } else if (typeof value === 'string' && value) {
        mainCategoryCode = value
      }
    }
    // 檢查 formValues 中是否有產品大類相關欄位
    else {
      // 優先檢查 main_type
      if (formValues && formValues.main_type) {
        const mainTypeValue = formValues.main_type
        if (typeof mainTypeValue === 'string' && mainTypeValue) {
          mainCategoryCode = mainTypeValue
        }
      }
      // 檢查 type（cascading_select）
      else if (formValues && formValues.type) {
        const typeValue = formValues.type
        if (Array.isArray(typeValue) && typeValue.length > 0 && typeValue[0]) {
          mainCategoryCode = typeValue[0]
        }
      }
      // 檢查 main_category（向後兼容）
      else if (formValues && formValues.main_category) {
        const mainCategoryValue = formValues.main_category
        if (Array.isArray(mainCategoryValue) && mainCategoryValue.length > 0 && mainCategoryValue[0]) {
          mainCategoryCode = mainCategoryValue[0]
        } else if (typeof mainCategoryValue === 'string' && mainCategoryValue) {
          mainCategoryCode = mainCategoryValue
        }
      }
    }

    // 如果找到產品大類代碼，載入對應的模板
    if (mainCategoryCode) {
      await loadTemplateForCategory(mainCategoryCode)
    }
  }

  // 載入指定產品大類的模板
  async function loadTemplateForCategory (mainCategoryCode) {
    if (!defaultFormId.value || !mainCategoryCode || loadingTemplate.value) {
      return
    }

    loadingTemplate.value = true
    try {
      // 載入模板值
      const template = await packagingService.getPackagingTemplate(defaultFormId.value, mainCategoryCode)

      if (template && template.template_values && formRendererRef.value) {
        // 取得表單中所有標記為 is_in_template 的欄位
        const fields = await formFieldsService.getFields(defaultFormId.value, { is_in_template: true })

        // 只更新標記為 is_in_template 的欄位
        const templateValues = {}
        for (const field of fields) {
          if (template.template_values[field.field_key] !== undefined) {
            templateValues[field.field_key] = template.template_values[field.field_key]
          }
        }

        // 將模板值填入表單（使用 setValues 方法）
        if (Object.keys(templateValues).length > 0 && formRendererRef.value && formRendererRef.value.setValues) {
          // 取得當前表單值
          const currentValues = formRendererRef.value.getValues ? formRendererRef.value.getValues() : {}
          // 合併模板值（模板值優先，但不覆蓋已填寫的值）
          const mergedValues = { ...currentValues, ...templateValues }
          formRendererRef.value.setValues(mergedValues)
        }
      }
    } catch (error) {
      console.warn('載入包裝模板失敗', error)
      // 不顯示錯誤訊息，因為模板可能不存在
    } finally {
      loadingTemplate.value = false
    }
  }

  onMounted(() => {
    loadDefaultForm()
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

// 必填欄位的紅色星號
:deep(.v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label--floating .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field .v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-input .v-label__asterisk) {
  color: #f44336 !important;
}
</style>
