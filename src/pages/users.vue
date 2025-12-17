<template>
  <div class="users-management">
    <v-container fluid>
      <v-card>
        <v-card-title class="system-header">
          <h2>使用者管理</h2>
          <v-spacer />
          <v-btn
            color="primary"
            prepend-icon="mdi-plus"
            @click="openCreateDialog"
          >
            新增使用者
          </v-btn>
        </v-card-title>

        <v-card-text class="pt-6">
          <!-- 篩選條件 -->
          <v-row class="mb-4">
            <v-col cols="12" md="4">
              <v-text-field
                v-model="filters.search"
                clearable
                label="搜尋（姓名、Email）"
                prepend-inner-icon="mdi-magnify"
                variant="outlined"
                @update:model-value="loadUsers"
              />
            </v-col>
            <v-col cols="12" md="3">
              <v-select
                v-model="filters.role"
                clearable
                :items="roleOptions"
                label="角色"
                variant="outlined"
                @update:model-value="loadUsers"
              />
            </v-col>
            <v-col cols="12" md="3">
              <v-select
                v-model="filters.is_active"
                clearable
                :items="statusOptions"
                label="狀態"
                variant="outlined"
                @update:model-value="loadUsers"
              />
            </v-col>
            <v-col cols="12" md="2">
              <v-btn
                block
                color="grey"
                variant="outlined"
                @click="clearFilters"
              >
                清除
              </v-btn>
            </v-col>
          </v-row>

          <v-progress-linear
            v-if="loading"
            indeterminate
            color="primary"
            class="mb-4"
          />

          <!-- 使用者列表 -->
          <v-data-table
            :headers="headers"
            :items="users"
            :items-per-page="10"
            class="elevation-1"
          >
            <template #item.email="{ item }">
              {{ item.email || 'N/A' }}
            </template>

            <template #item.role="{ item }">
              <v-chip
                :color="getRoleColor(item.role)"
                size="small"
                variant="flat"
              >
                {{ getRoleText(item.role) }}
              </v-chip>
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

            <template #item.created_at="{ item }">
              {{ formatDate(item.created_at) }}
            </template>

            <template #item.last_login="{ item }">
              {{ item.last_login ? formatDate(item.last_login) : '從未登入' }}
            </template>

            <template #item.actions="{ item }">
              <v-btn
                color="info"
                icon="mdi-pencil"
                size="small"
                variant="text"
                @click="openEditDialog(item)"
              />
              <v-btn
                :color="item.is_active ? 'warning' : 'success'"
                :icon="item.is_active ? 'mdi-account-off' : 'mdi-account-check'"
                size="small"
                variant="text"
                @click="toggleUserActive(item)"
              />
              <v-btn
                color="error"
                icon="mdi-delete"
                size="small"
                variant="text"
                @click="openDeleteDialog(item)"
              />
            </template>
          </v-data-table>
        </v-card-text>
      </v-card>

      <!-- 新增/編輯對話框 -->
      <v-dialog
        v-model="userDialog"
        max-width="600"
        persistent
        scrollable
      >
        <v-card>
          <v-card-title class="d-flex align-center bg-primary text-white">
            <v-icon class="mr-2">{{ isEditMode ? 'mdi-pencil' : 'mdi-plus' }}</v-icon>
            <span>{{ isEditMode ? '編輯使用者' : '新增使用者' }}</span>
            <v-spacer />
            <v-btn
              icon
              variant="text"
              @click="closeDialog"
            >
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-card-title>

          <v-card-text class="pa-4">
            <v-form ref="formRef" v-model="formValid">
              <v-text-field
                v-if="!isEditMode"
                v-model="formData.email"
                label="Email *"
                :rules="[rules.required, rules.email]"
                variant="outlined"
              />

              <v-text-field
                v-if="!isEditMode"
                v-model="formData.password"
                label="密碼 *"
                :rules="[rules.required, rules.min(6)]"
                type="password"
                variant="outlined"
              />

              <v-text-field
                v-if="isEditMode"
                v-model="formData.email"
                label="Email（無法修改）"
                disabled
                variant="outlined"
              />

              <v-text-field
                v-if="isEditMode"
                v-model="formData.newPassword"
                label="新密碼（留空則不修改）"
                :rules="[rules.min(6)]"
                type="password"
                variant="outlined"
              />

              <v-text-field
                v-model="formData.username"
                label="姓名 *"
                :rules="[rules.required]"
                variant="outlined"
              />

              <v-select
                v-model="formData.role"
                :items="roleOptions"
                label="角色 *"
                :rules="[rules.required]"
                variant="outlined"
              />

              <v-text-field
                v-model="formData.department"
                label="部門"
                variant="outlined"
              />

              <v-text-field
                v-model="formData.position"
                label="職位"
                variant="outlined"
              />

              <v-text-field
                v-model="formData.phone"
                label="電話"
                variant="outlined"
              />

              <v-switch
                v-model="formData.is_active"
                color="primary"
                label="啟用帳號"
              />
            </v-form>
          </v-card-text>

          <v-divider />

          <v-card-actions class="pa-4">
            <v-spacer />
            <v-btn
              color="grey"
              variant="outlined"
              @click="closeDialog"
            >
              取消
            </v-btn>
            <v-btn
              color="primary"
              :loading="saving"
              variant="flat"
              @click="saveUser"
            >
              儲存
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <!-- 刪除確認對話框 -->
      <v-dialog
        v-model="deleteDialog"
        max-width="400"
        persistent
      >
        <v-card>
          <v-card-title class="text-h6">
            確認刪除
          </v-card-title>
          <v-card-text>
            確定要刪除使用者「{{ selectedUser?.username || selectedUser?.email }}」嗎？此操作無法復原。
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn
              color="grey"
              variant="outlined"
              @click="deleteDialog = false"
            >
              取消
            </v-btn>
            <v-btn
              color="error"
              :loading="deleting"
              variant="flat"
              @click="confirmDelete"
            >
              刪除
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-container>
  </div>
</template>

<script setup>
  import { onMounted, reactive, ref } from 'vue'
  import { usersService } from '@/api/services/users'
  import { useSwal } from '@/composables/useSwal'

  const swal = useSwal()

  const loading = ref(false)
  const saving = ref(false)
  const deleting = ref(false)
  const users = ref([])
  const userDialog = ref(false)
  const deleteDialog = ref(false)
  const isEditMode = ref(false)
  const selectedUser = ref(null)
  const formRef = ref(null)
  const formValid = ref(false)

  const filters = reactive({
    search: '',
    role: null,
    is_active: null,
  })

  const formData = reactive({
    email: '',
    password: '',
    newPassword: '',
    username: '',
    role: 'applicant',
    department: '',
    position: '',
    phone: '',
    is_active: true,
  })

  const roleOptions = [
    { title: '申請人員', value: 'applicant' },
    { title: '審核人員', value: 'approver' },
    { title: '系統管理員', value: 'admin' },
  ]

  const statusOptions = [
    { title: '啟用', value: true },
    { title: '停用', value: false },
  ]

  const headers = [
    { title: 'Email', key: 'email', sortable: true },
    { title: '姓名', key: 'username', sortable: true },
    { title: '角色', key: 'role', sortable: true },
    { title: '部門', key: 'department', sortable: true },
    { title: '職位', key: 'position', sortable: true },
    { title: '電話', key: 'phone', sortable: false },
    { title: '狀態', key: 'is_active', sortable: true },
    { title: '建立時間', key: 'created_at', sortable: true },
    { title: '最後登入', key: 'last_login', sortable: true },
    { title: '操作', key: 'actions', sortable: false },
  ]

  const rules = {
    required: value => !!value || '此欄位為必填',
    email: value => {
      if (!value) return true
      const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      return pattern.test(value) || '請輸入有效的 Email 格式'
    },
    min: len => value => {
      if (!value) return true
      return value.length >= len || `最少 ${len} 個字元`
    },
  }

  function getRoleColor (role) {
    const colors = {
      admin: 'error',
      approver: 'warning',
      applicant: 'info',
    }
    return colors[role] || 'grey'
  }

  function getRoleText (role) {
    const texts = {
      admin: '系統管理員',
      approver: '審核人員',
      applicant: '申請人員',
    }
    return texts[role] || role
  }

  function formatDate (dateString) {
    if (!dateString) return ''
    return new Date(dateString).toLocaleString('zh-TW')
  }

  async function loadUsers () {
    loading.value = true
    try {
      const data = await usersService.getUsers(filters)
      users.value = data || []
    } catch (error) {
      console.error('載入使用者列表失敗', error)
      await swal.error('載入失敗', error.message || '無法取得使用者列表')
    } finally {
      loading.value = false
    }
  }

  function clearFilters () {
    filters.search = ''
    filters.role = null
    filters.is_active = null
    loadUsers()
  }

  function openCreateDialog () {
    isEditMode.value = false
    selectedUser.value = null
    resetForm()
    userDialog.value = true
  }

  function openEditDialog (user) {
    isEditMode.value = true
    selectedUser.value = user
    formData.email = user.email || user.id || '' // 如果沒有 email，顯示 ID
    formData.username = user.username || ''
    formData.role = user.role || 'applicant'
    formData.department = user.department || ''
    formData.position = user.position || ''
    formData.phone = user.phone || ''
    formData.is_active = user.is_active !== undefined ? user.is_active : true
    formData.newPassword = ''
    userDialog.value = true
  }

  function closeDialog () {
    userDialog.value = false
    resetForm()
  }

  function resetForm () {
    formData.email = ''
    formData.password = ''
    formData.newPassword = ''
    formData.username = ''
    formData.role = 'applicant'
    formData.department = ''
    formData.position = ''
    formData.phone = ''
    formData.is_active = true
    formRef.value?.resetValidation()
  }

  async function saveUser () {
    const { valid } = await formRef.value.validate()
    if (!valid) {
      return
    }

    saving.value = true
    try {
      if (isEditMode.value) {
        const updates = {
          username: formData.username,
          role: formData.role,
          department: formData.department || null,
          position: formData.position || null,
          phone: formData.phone || null,
          // 確保 is_active 是 boolean 類型
          is_active: Boolean(formData.is_active),
        }

        if (formData.newPassword) {
          updates.password = formData.newPassword
        }

        // 注意：前端無法更新 auth.users 的 email
        // 如果需要更新 email，需要通過後端 API 或 Supabase Edge Function

        await usersService.updateUser(selectedUser.value.id, updates)
        await swal.success('更新成功', '使用者資料已更新')
      } else {
        await usersService.createUser({
          email: formData.email,
          password: formData.password,
          username: formData.username,
          role: formData.role,
          department: formData.department || null,
          position: formData.position || null,
          phone: formData.phone || null,
          // 確保 is_active 是 boolean 類型
          is_active: Boolean(formData.is_active),
        })
        await swal.success('建立成功', '使用者已建立')
      }

      closeDialog()
      await loadUsers()
    } catch (error) {
      console.error('儲存使用者失敗', error)
      await swal.error('儲存失敗', error.message || '無法儲存使用者資料')
    } finally {
      saving.value = false
    }
  }

  function openDeleteDialog (user) {
    selectedUser.value = user
    deleteDialog.value = true
  }

  async function confirmDelete () {
    deleting.value = true
    try {
      await usersService.deleteUser(selectedUser.value.id)
      await swal.success('刪除成功', '使用者已刪除')
      deleteDialog.value = false
      await loadUsers()
    } catch (error) {
      console.error('刪除使用者失敗', error)
      await swal.error('刪除失敗', error.message || '無法刪除使用者')
    } finally {
      deleting.value = false
    }
  }

  async function toggleUserActive (user) {
    try {
      const newStatus = !user.is_active
      await usersService.toggleUserActive(user.id, newStatus)
      await swal.success('更新成功', `使用者已${newStatus ? '啟用' : '停用'}`)
      await loadUsers()
    } catch (error) {
      console.error('更新使用者狀態失敗', error)
      await swal.error('更新失敗', error.message || '無法更新使用者狀態')
    }
  }

  onMounted(() => {
    loadUsers()
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.users-management {
  .system-header {
    display: flex;
    align-items: center;
    padding: 20px 24px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;

    h2 {
      margin: 0;
      font-size: 1.5em;
      font-weight: bold;
    }
  }
}
</style>

