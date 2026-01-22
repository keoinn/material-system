<template>
  <div class="department-management">
    <v-card>
      <v-card-title class="d-flex align-center">
        <h3>部門管理</h3>
        <v-spacer />
        <v-btn
          color="primary"
          prepend-icon="mdi-plus"
          @click="openCreateDepartmentDialog"
        >
          新增部門
        </v-btn>
      </v-card-title>

      <v-card-text>
        <v-progress-linear
          v-if="loading"
          indeterminate
          color="primary"
          class="mb-4"
        />

        <v-data-table
          :headers="departmentHeaders"
          :items="departments"
          :items-per-page="10"
          class="elevation-1"
        >
          <template #item.parent="{ item }">
            {{ item.parent ? item.parent.department_name : '頂層部門' }}
          </template>

          <template #item.manager="{ item }">
            {{ item.manager ? item.manager.username : '未設定' }}
          </template>

          <template #item.is_active="{ item }">
            <v-chip
              :color="item.is_active ? 'success' : 'error'"
              size="small"
              variant="flat"
            >
              {{ item.is_active ? '啟用' : '停用' }}
            </v-chip>
          </template>

          <template #item.actions="{ item }">
            <v-btn
              color="info"
              icon="mdi-pencil"
              size="small"
              variant="text"
              @click="openEditDepartmentDialog(item)"
            />
            <v-btn
              color="error"
              icon="mdi-delete"
              size="small"
              variant="text"
              @click="openDeleteDepartmentDialog(item)"
            />
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>

    <!-- 新增/編輯部門對話框 -->
    <v-dialog
      v-model="departmentDialog"
      max-width="600"
      persistent
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-primary text-white">
          <v-icon class="mr-2">{{ isEditDepartmentMode ? 'mdi-pencil' : 'mdi-plus' }}</v-icon>
          <span>{{ isEditDepartmentMode ? '編輯部門' : '新增部門' }}</span>
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="closeDepartmentDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>

        <v-card-text class="pa-4">
          <v-form ref="departmentFormRef" v-model="departmentFormValid">
            <v-text-field
              v-model="departmentFormData.department_code"
              :disabled="isEditDepartmentMode"
              label="部門代碼 *"
              :rules="[rules.required, rules.departmentCode]"
              variant="outlined"
            />

            <v-text-field
              v-model="departmentFormData.department_name"
              label="部門名稱（中文） *"
              :rules="[rules.required]"
              variant="outlined"
            />

            <v-text-field
              v-model="departmentFormData.department_name_en"
              label="部門名稱（英文）"
              variant="outlined"
            />

            <v-select
              v-model="departmentFormData.parent_id"
              :items="parentDepartmentOptions"
              label="上級部門"
              clearable
              variant="outlined"
            />

            <v-select
              v-model="departmentFormData.manager_id"
              :items="managerOptions"
              label="部門主管"
              clearable
              variant="outlined"
            />

            <v-textarea
              v-model="departmentFormData.description"
              label="說明"
              rows="3"
              variant="outlined"
            />

            <v-text-field
              v-model.number="departmentFormData.display_order"
              label="顯示順序"
              type="number"
              variant="outlined"
            />

            <v-switch
              v-model="departmentFormData.is_active"
              color="primary"
              label="啟用"
            />
          </v-form>
        </v-card-text>

        <v-divider />

        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn
            color="grey"
            variant="outlined"
            @click="closeDepartmentDialog"
          >
            取消
          </v-btn>
          <v-btn
            color="primary"
            :loading="savingDepartment"
            variant="flat"
            @click="saveDepartment"
          >
            儲存
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- 刪除確認對話框 -->
    <v-dialog
      v-model="deleteDepartmentDialog"
      max-width="400"
      persistent
    >
      <v-card>
        <v-card-title class="text-h6">
          確認刪除
        </v-card-title>
        <v-card-text>
          確定要刪除部門「{{ selectedDepartment?.department_name }}」嗎？此操作無法復原。
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn
            color="grey"
            variant="outlined"
            @click="deleteDepartmentDialog = false"
          >
            取消
          </v-btn>
          <v-btn
            color="error"
            :loading="deletingDepartment"
            variant="flat"
            @click="confirmDeleteDepartment"
          >
            刪除
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup>
  import { computed, onMounted, reactive, ref } from 'vue'
  import { departmentsService, usersService } from '@/api/services'
  import { useSwal } from '@/composables/useSwal'

  const swal = useSwal()

  const loading = ref(false)
  const savingDepartment = ref(false)
  const deletingDepartment = ref(false)
  const departments = ref([])
  const users = ref([])
  const departmentDialog = ref(false)
  const deleteDepartmentDialog = ref(false)
  const isEditDepartmentMode = ref(false)
  const selectedDepartment = ref(null)
  const departmentFormRef = ref(null)
  const departmentFormValid = ref(false)

  const departmentFormData = reactive({
    department_code: '',
    department_name: '',
    department_name_en: '',
    parent_id: null,
    manager_id: null,
    description: '',
    display_order: 0,
    is_active: true,
  })

  const departmentHeaders = [
    { title: '部門代碼', key: 'department_code', sortable: true },
    { title: '部門名稱', key: 'department_name', sortable: true },
    { title: '部門名稱（英文）', key: 'department_name_en', sortable: true },
    { title: '上級部門', key: 'parent', sortable: false },
    { title: '部門主管', key: 'manager', sortable: false },
    { title: '狀態', key: 'is_active', sortable: true },
    { title: '顯示順序', key: 'display_order', sortable: true },
    { title: '操作', key: 'actions', sortable: false },
  ]

  const parentDepartmentOptions = computed(() => {
    return departments.value
      .filter(d => !isEditDepartmentMode.value || d.id !== selectedDepartment.value?.id)
      .map(d => ({
        title: d.department_name,
        value: d.id,
      }))
  })

  const managerOptions = computed(() => {
    return users.value.map(u => ({
      title: u.username || u.email,
      value: u.id,
    }))
  })

  const rules = {
    required: value => !!value || '此欄位為必填',
    departmentCode: value => {
      if (!value) return true
      const pattern = /^[A-Z0-9_]+$/
      return pattern.test(value) || '部門代碼只能包含大寫字母、數字和底線'
    },
  }

  async function loadDepartments () {
    loading.value = true
    try {
      const data = await departmentsService.getDepartments()
      departments.value = data || []
    } catch (error) {
      console.error('載入部門列表失敗', error)
      await swal.error('載入失敗', error.message || '無法取得部門列表')
    } finally {
      loading.value = false
    }
  }

  async function loadUsers () {
    try {
      const data = await usersService.getUsers({ is_active: true })
      users.value = data || []
    } catch (error) {
      console.error('載入使用者列表失敗', error)
    }
  }

  function openCreateDepartmentDialog () {
    isEditDepartmentMode.value = false
    selectedDepartment.value = null
    resetDepartmentForm()
    departmentDialog.value = true
  }

  function openEditDepartmentDialog (department) {
    isEditDepartmentMode.value = true
    selectedDepartment.value = department
    departmentFormData.department_code = department.department_code || ''
    departmentFormData.department_name = department.department_name || ''
    departmentFormData.department_name_en = department.department_name_en || ''
    departmentFormData.parent_id = department.parent_id || null
    departmentFormData.manager_id = department.manager_id || null
    departmentFormData.description = department.description || ''
    departmentFormData.display_order = department.display_order || 0
    departmentFormData.is_active = department.is_active !== undefined ? department.is_active : true
    departmentDialog.value = true
  }

  function closeDepartmentDialog () {
    departmentDialog.value = false
    resetDepartmentForm()
  }

  function resetDepartmentForm () {
    departmentFormData.department_code = ''
    departmentFormData.department_name = ''
    departmentFormData.department_name_en = ''
    departmentFormData.parent_id = null
    departmentFormData.manager_id = null
    departmentFormData.description = ''
    departmentFormData.display_order = 0
    departmentFormData.is_active = true
    departmentFormRef.value?.resetValidation()
  }

  async function saveDepartment () {
    const { valid } = await departmentFormRef.value.validate()
    if (!valid) {
      return
    }

    savingDepartment.value = true
    try {
      const data = {
        ...departmentFormData,
        parent_id: departmentFormData.parent_id || null,
        manager_id: departmentFormData.manager_id || null,
      }

      if (isEditDepartmentMode.value) {
        await departmentsService.updateDepartment(selectedDepartment.value.id, data)
        await swal.success('更新成功', '部門資料已更新')
      } else {
        await departmentsService.createDepartment(data)
        await swal.success('建立成功', '部門已建立')
      }

      closeDepartmentDialog()
      await loadDepartments()
    } catch (error) {
      console.error('儲存部門失敗', error)
      await swal.error('儲存失敗', error.message || '無法儲存部門資料')
    } finally {
      savingDepartment.value = false
    }
  }

  function openDeleteDepartmentDialog (department) {
    selectedDepartment.value = department
    deleteDepartmentDialog.value = true
  }

  async function confirmDeleteDepartment () {
    deletingDepartment.value = true
    try {
      await departmentsService.deleteDepartment(selectedDepartment.value.id)
      await swal.success('刪除成功', '部門已刪除')
      deleteDepartmentDialog.value = false
      await loadDepartments()
    } catch (error) {
      console.error('刪除部門失敗', error)
      await swal.error('刪除失敗', error.message || '無法刪除部門')
    } finally {
      deletingDepartment.value = false
    }
  }

  onMounted(() => {
    loadDepartments()
    loadUsers()
  })
</script>

<style scoped lang="scss">
.department-management {
  // 樣式可以根據需要添加
}
</style>
