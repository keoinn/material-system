<template>
  <div>
    <v-alert
      v-if="!activeFormId && !loading"
      class="mb-4"
      type="info"
      variant="tonal"
    >
      <div class="d-flex align-center flex-wrap ga-2">
        <span v-if="selectedDraft && !selectedDraft.formId">
          此草稿尚未關聯表單，請回到「項目主檔申請表」重新選擇表單並建立草稿。
        </span>
        <span v-else>
          請先到「項目主檔申請表」選擇啟用中的表單並建立草稿，再於此編輯申請內容。
        </span>
        <v-btn
          color="primary"
          size="small"
          variant="outlined"
          @click="goToBatchApply"
        >
          前往項目主檔申請表
        </v-btn>
      </div>
    </v-alert>

    <DynamicFormRenderer
      v-if="activeFormId"
      :key="activeFormKey"
      ref="formRendererRef"
      :cancel-text="cancelText"
      :form-id="activeFormId"
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
  import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
  import { useRoute, useRouter } from 'vue-router'
  import { formFieldsService } from '@/api/services/formFields'
  import { formsService } from '@/api/services/forms'
  import { packagingService } from '@/api/services/packaging'
  import { useSwal } from '@/composables/useSwal'
  import { useBatchMaterialApplicationsStore } from '@/stores/batchMaterialApplications'
  import { FORMS_UPDATED_EVENT } from '@/utils/formsUpdatedEvent'
  import {
    getPackagingCategoryFieldKey,
    PACKAGING_TEMPLATE_DEFAULT_TYPE,
    resolveTemplateTypeFromFieldValue,
  } from '@/utils/packagingTemplateConfig'
  import DynamicFormRenderer from './DynamicFormRenderer.vue'

  const route = useRoute()
  const router = useRouter()
  const swal = useSwal()
  const batchStore = useBatchMaterialApplicationsStore()

  const formRendererRef = ref(null)
  const loading = ref(false)
  const loadingTemplate = ref(false)
  const packagingCategoryFieldKey = ref(null)

  const selectedDraft = computed(() => batchStore.selectedDraft)
  const activeFormId = computed(() => selectedDraft.value?.formId ?? null)
  const activeInitialValues = computed(() => selectedDraft.value?.values || {})
  const activeFormKey = computed(() => {
    const draftId = selectedDraft.value?.id || 'none'
    return `${draftId}-${activeFormId.value || 'none'}`
  })
  const submitText = computed(() => '儲存草稿')
  const cancelText = computed(() => '清除目前草稿')

  function goToBatchApply () {
    router.push({ path: '/', query: { tab: 'batch-apply', batchView: 'select' } })
  }

  async function syncDraftValuesToForm () {
    if (!selectedDraft.value || !formRendererRef.value?.setValues) {
      return
    }
    await nextTick()
    formRendererRef.value.setValues({ ...(selectedDraft.value.values || {}) })
  }

  async function loadPackagingTemplateConfig () {
    if (!activeFormId.value) {
      packagingCategoryFieldKey.value = null
      return
    }
    try {
      const form = await formsService.getForm(activeFormId.value, false)
      packagingCategoryFieldKey.value = getPackagingCategoryFieldKey(form?.form_config)
    } catch (error) {
      console.warn('載入包裝模板設定失敗', error)
      packagingCategoryFieldKey.value = null
    }
  }

  async function refreshFormContext () {
    loading.value = true
    try {
      await loadPackagingTemplateConfig()
      if (!packagingCategoryFieldKey.value && activeFormId.value) {
        await loadTemplateForCategory(PACKAGING_TEMPLATE_DEFAULT_TYPE)
      }
    } finally {
      loading.value = false
    }
  }

  async function handleSubmit (formValues) {
    if (!activeFormId.value || !selectedDraft.value) {
      await swal.warning('請先到「項目主檔申請表」選擇表單並建立草稿')
      return
    }

    batchStore.updateDraftValues(selectedDraft.value.id, formValues)
    await swal.success('草稿已儲存')
    router.push({ path: '/', query: { tab: 'batch-apply', batchView: 'drafts' } })
  }

  function handleClear () {
    if (selectedDraft.value) {
      batchStore.updateDraftValues(selectedDraft.value.id, {})
    }
    if (formRendererRef.value) {
      formRendererRef.value.reset()
    }
  }

  const LEGACY_PACKAGING_TEMPLATE_TRIGGER_FIELD_KEYS = new Set([
    'main_type',
    'type',
    'main_category',
  ])

  function resolveLegacyTemplateType (fieldKey, value) {
    if (fieldKey === 'main_type' && typeof value === 'string' && value) {
      return value
    }
    if (fieldKey === 'type' && Array.isArray(value) && value.length > 0 && value[0]) {
      return String(value[0])
    }
    if (fieldKey === 'main_category') {
      if (Array.isArray(value) && value.length > 0 && value[0]) {
        return String(value[0])
      }
      if (typeof value === 'string' && value) {
        return value
      }
    }
    return null
  }

  async function handleFieldUpdate (event) {
    const { fieldKey, value } = event

    if (selectedDraft.value && event.formValues) {
      batchStore.updateDraftValues(selectedDraft.value.id, event.formValues)
    }

    const categoryKey = packagingCategoryFieldKey.value
    if (categoryKey) {
      if (fieldKey !== categoryKey) {
        return
      }
      const templateType = resolveTemplateTypeFromFieldValue(value)
      if (templateType) {
        await loadTemplateForCategory(templateType)
      }
      return
    }

    if (!LEGACY_PACKAGING_TEMPLATE_TRIGGER_FIELD_KEYS.has(fieldKey)) {
      return
    }

    const templateType = resolveLegacyTemplateType(fieldKey, value)
    if (templateType) {
      await loadTemplateForCategory(templateType)
    }
  }

  async function loadTemplateForCategory (mainCategoryCode) {
    if (!activeFormId.value || !mainCategoryCode || loadingTemplate.value) {
      return
    }

    loadingTemplate.value = true
    try {
      const template = await packagingService.getPackagingTemplate(activeFormId.value, mainCategoryCode)

      if (template?.template_values && formRendererRef.value) {
        const fields = await formFieldsService.getFields(activeFormId.value, { is_in_template: true })
        const templateValues = {}
        for (const field of fields) {
          if (template.template_values[field.field_key] !== undefined) {
            templateValues[field.field_key] = template.template_values[field.field_key]
          }
        }

        if (Object.keys(templateValues).length > 0 && formRendererRef.value?.setValues) {
          const currentValues = formRendererRef.value.getValues ? formRendererRef.value.getValues() : {}
          const mergedValues = { ...currentValues, ...templateValues }
          formRendererRef.value.setValues(mergedValues)
        }
      }
    } catch (error) {
      console.warn('載入包裝模板失敗', error)
    } finally {
      loadingTemplate.value = false
    }
  }

  onMounted(() => {
    refreshFormContext()
    window.addEventListener(FORMS_UPDATED_EVENT, refreshFormContext)
  })

  onUnmounted(() => {
    window.removeEventListener(FORMS_UPDATED_EVENT, refreshFormContext)
  })

  watch(() => route.query.tab, tab => {
    if (tab === 'apply') {
      refreshFormContext()
    }
  })

  watch(() => selectedDraft.value?.formId, async () => {
    await refreshFormContext()
  })

  watch(activeFormId, async (formId, prevId) => {
    if (!formId || formId === prevId) {
      return
    }
    await loadPackagingTemplateConfig()
    if (!packagingCategoryFieldKey.value) {
      await loadTemplateForCategory(PACKAGING_TEMPLATE_DEFAULT_TYPE)
    }
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
