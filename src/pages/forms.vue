<template>
  <div class="material-system">
    <v-container fluid>
      <v-card>
        <v-card-title class="system-header">
          <h2>表單管理</h2>
          <v-spacer />
          <v-btn
            color="primary"
            @click="openDesigner(null)"
          >
            <v-icon start>mdi-plus</v-icon>
            建立新表單
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
            :items="forms"
            :items-per-page="10"
            class="elevation-1"
          >
            <template #item.is_active="{ item }">
              <v-chip
                :color="item.is_active ? 'success' : 'grey'"
                size="small"
                variant="flat"
              >
                {{ item.is_active ? '啟用' : '停用' }}
              </v-chip>
            </template>

            <template #item.is_default="{ item }">
              <v-chip
                v-if="item.is_default"
                color="primary"
                size="small"
                variant="flat"
              >
                預設
              </v-chip>
            </template>

            <template #item.created_at="{ item }">
              {{ formatDate(item.created_at) }}
            </template>

            <template #item.actions="{ item }">
              <div class="d-flex align-center" style="gap: 8px;">
                <v-btn
                  icon
                  size="x-small"
                  color="primary"
                  @click="openDesigner(item.id)"
                >
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
                <v-btn
                  icon
                  size="x-small"
                  color="info"
                  @click="duplicateForm(item.id)"
                >
                  <v-icon>mdi-content-copy</v-icon>
                </v-btn>
                <v-btn
                  icon
                  size="x-small"
                  color="error"
                  @click="deleteForm(item.id)"
                >
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </div>
            </template>

            <template #no-data>
              <div class="text-center py-4">
                目前沒有表單
              </div>
            </template>
          </v-data-table>
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
          :form-id="editingFormId"
          @saved="handleFormSaved"
          @cancel="designerDialog = false"
        />
      </v-dialog>
    </v-container>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { formsService } from '@/api/services/forms'
import { useSwal } from '@/composables/useSwal'
import FormDesigner from '@/components/FormDesigner.vue'

const swal = useSwal()

const loading = ref(false)
const forms = ref([])
const designerDialog = ref(false)
const editingFormId = ref(null)

const headers = [
  { title: '表單代碼', key: 'form_code', sortable: true },
  { title: '表單名稱', key: 'form_name', sortable: true },
  { title: '狀態', key: 'is_active', sortable: true },
  { title: '預設', key: 'is_default', sortable: true },
  { title: '建立時間', key: 'created_at', sortable: true },
  { title: '操作', key: 'actions', sortable: false },
]

// 載入表單列表
async function loadForms () {
  loading.value = true
  try {
    forms.value = await formsService.getForms()
  } catch (error) {
    console.error('載入表單列表失敗', error)
    await swal.error('載入表單列表失敗')
  } finally {
    loading.value = false
  }
}

// 開啟設計器
function openDesigner (formId) {
  editingFormId.value = formId
  designerDialog.value = true
}

// 處理表單儲存
async function handleFormSaved (formId) {
  // 儲存成功後不關閉對話視窗，只更新表單列表
  await loadForms()
  // 如果是新建表單，更新 editingFormId 以便後續編輯
  if (!editingFormId.value && formId) {
    editingFormId.value = formId
  }
}

// 複製表單
async function duplicateForm (formId) {
  try {
    const result = await swal.confirm('確定要複製這個表單嗎？')
    if (!result.isConfirmed) return

    await formsService.duplicateForm(formId)
    await swal.success('表單已複製')
    await loadForms()
  } catch (error) {
    console.error('複製表單失敗', error)
    await swal.error('複製表單失敗')
  }
}

// 刪除表單
async function deleteForm (formId) {
  try {
    const result = await swal.confirm('確定要刪除這個表單嗎？此操作無法復原。')
    if (!result.isConfirmed) return

    await formsService.deleteForm(formId)
    await swal.success('表單已刪除')
    await loadForms()
  } catch (error) {
    console.error('刪除表單失敗', error)
    await swal.error('刪除表單失敗')
  }
}

// 格式化日期
function formatDate (date) {
  if (!date) return '-'
  return new Date(date).toLocaleString('zh-TW')
}

onMounted(() => {
  loadForms()
})
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';
</style>
