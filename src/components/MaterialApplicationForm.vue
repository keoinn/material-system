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
    />
  </div>
</template>

<script setup>
  import { onMounted, ref } from 'vue'
  import { useRouter } from 'vue-router'
  import { formDataService } from '@/api/services/formData'
  import { formsService } from '@/api/services/forms'
  import { useSwal } from '@/composables/useSwal'
  import DynamicFormRenderer from './DynamicFormRenderer.vue'

  const swal = useSwal()
  const router = useRouter()

  const formRendererRef = ref(null)
  const loading = ref(false)
  const defaultFormId = ref(null)

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
