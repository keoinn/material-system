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
      :key="activeFormKey"
      ref="formRendererRef"
      :cancel-text="cancelText"
      :form-id="defaultFormId"
      :initial-values="activeInitialValues"
      :show-actions="true"
      :show-cancel="true"
      :show-title="true"
      :submit-text="submitText"
      @cancel="handleClear"
      @submit="handleSubmit"
      @field-update="handleFieldUpdate"
    />
  </div>
</template>

<script setup>
  import { computed, nextTick, onMounted, ref, watch } from 'vue'
  import { useRoute, useRouter } from 'vue-router'
  import { formDataService } from '@/api/services/formData'
  import { formFieldsService } from '@/api/services/formFields'
  import { formsService } from '@/api/services/forms'
  import { packagingService } from '@/api/services/packaging'
  import { useSwal } from '@/composables/useSwal'
  import { useBatchMaterialApplicationsStore } from '@/stores/batchMaterialApplications'
  import DynamicFormRenderer from './DynamicFormRenderer.vue'

  const route = useRoute()
  const router = useRouter()
  const swal = useSwal()
  const batchStore = useBatchMaterialApplicationsStore()

  const formRendererRef = ref(null)
  const loading = ref(false)
  const defaultFormId = ref(null)
  const loadingTemplate = ref(false)

  const selectedDraft = computed(() => batchStore.selectedDraft)
  const activeInitialValues = computed(() => selectedDraft.value?.values || {})
  const activeFormKey = computed(() => selectedDraft.value?.id || 'single-form')
  const submitText = computed(() => selectedDraft.value ? '儲存草稿' : '提交申請')
  const cancelText = computed(() => selectedDraft.value ? '清除目前草稿' : '清除表單')

  async function syncDraftValuesToForm () {
    if (!selectedDraft.value || !formRendererRef.value?.setValues) {
      return
    }
    await nextTick()
    formRendererRef.value.setValues({ ...(selectedDraft.value.values || {}) })
  }

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
    try {
      if (!defaultFormId.value) {
        await swal.warning('表單尚未載入完成')
        return
      }

      if (selectedDraft.value) {
        batchStore.updateDraftValues(selectedDraft.value.id, formValues)
        await swal.success('草稿已儲存')
        router.push({ path: '/', query: { tab: 'batch-apply' } })
        return
      }

      const result = await formDataService.createFormData(defaultFormId.value, formValues, { createRecord: true })
      const recordId = result?.record_id || result?.id || 'N/A'

      await swal.success(`申請單號：${recordId}`, '申請已提交！')

      handleClear()
    } catch (error) {
      console.error('提交申請失敗', error)
      await swal.error(error.message || '提交申請時發生錯誤')
    }
  }

  // 處理清除表單
  function handleClear () {
    if (selectedDraft.value) {
      batchStore.updateDraftValues(selectedDraft.value.id, {})
    }
    if (formRendererRef.value) {
      formRendererRef.value.reset()
    }
  }

  // 僅在「基本資料」內會影響產品大類／模板選擇的欄位變更時載入包裝模板。
  // 若在任何欄位更新時都從 formValues 推斷大類並載入，使用者編輯其他區塊時也會觸發，導致 setValues 覆寫手動輸入。
  const PACKAGING_TEMPLATE_TRIGGER_FIELD_KEYS = new Set([
    'main_type',
    'type',
    'main_category',
  ])

  // 處理欄位更新事件
  async function handleFieldUpdate (event) {
    const { fieldKey, value } = event

    if (selectedDraft.value && event.formValues) {
      batchStore.updateDraftValues(selectedDraft.value.id, event.formValues)
    }

    if (!PACKAGING_TEMPLATE_TRIGGER_FIELD_KEYS.has(fieldKey)) {
      return
    }

    // 產品大類可能是：
    // 1. main_type - 單獨的欄位，值直接是產品大類代碼（如 'H', 'S', 'M'）
    // 2. type - cascading_select，值是一個數組，第一層是產品大類代碼
    // 3. main_category - 舊版欄位名稱（向後兼容）
    let mainCategoryCode = null

    if (fieldKey === 'main_type') {
      if (typeof value === 'string' && value) {
        mainCategoryCode = value
      }
    } else if (fieldKey === 'type') {
      if (Array.isArray(value) && value.length > 0 && value[0]) {
        mainCategoryCode = value[0]
      }
    } else if (fieldKey === 'main_category') {
      if (Array.isArray(value) && value.length > 0 && value[0]) {
        mainCategoryCode = value[0]
      } else if (typeof value === 'string' && value) {
        mainCategoryCode = value
      }
    }

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

  watch(() => route.query.batchDraftId, draftId => {
    if (typeof draftId === 'string' && batchStore.hasDraft(draftId)) {
      batchStore.selectDraft(draftId)
      return
    }
    batchStore.selectDraft(null)
  }, { immediate: true })

  watch(
    () => selectedDraft.value?.id,
    async () => {
      await syncDraftValuesToForm()
    },
    { immediate: true },
  )
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
