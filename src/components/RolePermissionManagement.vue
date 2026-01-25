<template>
  <div class="role-permission-management">
    <v-card>
      <v-card-title class="d-flex align-center">
        <h3>角色管理</h3>
        <v-spacer />
        <v-btn
          color="primary"
          prepend-icon="mdi-plus"
          @click="openCreateRoleDialog"
        >
          新增角色
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
          :headers="roleHeaders"
          :items="roles"
          :items-per-page="10"
          class="elevation-1"
        >
          <template #item.is_system_role="{ item }">
            <v-chip
              v-if="item.is_system_role"
              color="info"
              size="small"
              variant="flat"
            >
              系統內建
            </v-chip>
            <span v-else>自訂</span>
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
              @click="openEditRoleDialog(item)"
            />
            <v-btn
              color="primary"
              icon="mdi-shield-key"
              size="small"
              variant="text"
              @click="openPermissionDialog(item)"
            />
            <v-btn
              v-if="!item.is_system_role"
              color="error"
              icon="mdi-delete"
              size="small"
              variant="text"
              @click="openDeleteRoleDialog(item)"
            />
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>

    <!-- 新增/編輯角色對話框 -->
    <v-dialog
      v-model="roleDialog"
      max-width="600"
      persistent
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-primary text-white">
          <v-icon class="mr-2">{{ isEditRoleMode ? 'mdi-pencil' : 'mdi-plus' }}</v-icon>
          <span>{{ isEditRoleMode ? '編輯角色' : '新增角色' }}</span>
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="closeRoleDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>

        <v-card-text class="pa-4">
          <v-tabs v-model="roleDialogTab" bg-color="grey-lighten-4">
            <v-tab value="basic">
              <v-icon start>mdi-information</v-icon>
              基本資訊
            </v-tab>
            <v-tab value="pages">
              <v-icon start>mdi-view-dashboard</v-icon>
              頁面權限
            </v-tab>
          </v-tabs>

          <v-window v-model="roleDialogTab" class="mt-4">
            <!-- 基本資訊分頁 -->
            <v-window-item value="basic">
              <v-form ref="roleFormRef" v-model="roleFormValid">
                <v-text-field
                  v-model="roleFormData.role_code"
                  :disabled="isEditRoleMode"
                  label="角色代碼 *"
                  :rules="[rules.required, rules.roleCode]"
                  variant="outlined"
                />

                <v-text-field
                  v-model="roleFormData.role_name"
                  label="角色名稱（中文） *"
                  :rules="[rules.required]"
                  variant="outlined"
                />

                <v-text-field
                  v-model="roleFormData.role_name_en"
                  label="角色名稱（英文）"
                  variant="outlined"
                />

                <v-textarea
                  v-model="roleFormData.description"
                  label="說明"
                  rows="3"
                  variant="outlined"
                />

                <v-text-field
                  v-model.number="roleFormData.display_order"
                  label="顯示順序"
                  type="number"
                  variant="outlined"
                />

                <v-switch
                  v-model="roleFormData.is_active"
                  color="primary"
                  label="啟用"
                />
              </v-form>
            </v-window-item>

            <!-- 頁面權限分頁 -->
            <v-window-item value="pages">
              <div>
                <v-progress-linear
                  v-if="loadingPageAccess"
                  indeterminate
                  color="primary"
                  class="mb-4"
                />

                <div class="text-body-2 mb-4">
                  選擇該角色可以訪問的頁面：
                </div>

                <v-row>
                  <v-col
                    v-for="page in availablePages"
                    :key="page.code"
                    cols="12"
                    md="6"
                  >
                    <v-switch
                      v-model="selectedPageCodes"
                      :value="page.code"
                      :label="page.name"
                      :hint="page.description"
                      persistent-hint
                      color="primary"
                      hide-details="auto"
                    />
                  </v-col>
                </v-row>
              </div>
            </v-window-item>
          </v-window>
        </v-card-text>

        <v-divider />

          <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn
            color="grey"
            variant="outlined"
            @click="closeRoleDialog"
          >
            取消
          </v-btn>
          <v-btn
            color="primary"
            :loading="savingRole || savingPageAccess"
            variant="flat"
            @click="saveRole"
          >
            儲存
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- 權限分配對話框 -->
    <v-dialog
      v-model="permissionDialog"
      max-width="800"
      persistent
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-primary text-white">
          <v-icon class="mr-2">mdi-shield-key</v-icon>
          <span>分配權限：{{ selectedRole?.role_name }}</span>
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="closePermissionDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>

        <v-card-text class="pa-4">
          <v-progress-linear
            v-if="loadingPermissions"
            indeterminate
            color="primary"
            class="mb-4"
          />

          <v-checkbox
            v-for="permission in permissions"
            :key="permission.id"
            v-model="selectedPermissionIds"
            :value="permission.id"
            :label="`${permission.permission_name} (${permission.permission_code})`"
            :hint="permission.description"
            persistent-hint
            class="mb-2"
          />
        </v-card-text>

        <v-divider />

        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn
            color="grey"
            variant="outlined"
            @click="closePermissionDialog"
          >
            取消
          </v-btn>
          <v-btn
            color="primary"
            :loading="savingPermissions"
            variant="flat"
            @click="savePermissions"
          >
            儲存
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- 刪除確認對話框 -->
    <v-dialog
      v-model="deleteRoleDialog"
      max-width="400"
      persistent
    >
      <v-card>
        <v-card-title class="text-h6">
          確認刪除
        </v-card-title>
        <v-card-text>
          確定要刪除角色「{{ selectedRole?.role_name }}」嗎？此操作無法復原。
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn
            color="grey"
            variant="outlined"
            @click="deleteRoleDialog = false"
          >
            取消
          </v-btn>
          <v-btn
            color="error"
            :loading="deletingRole"
            variant="flat"
            @click="confirmDeleteRole"
          >
            刪除
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup>
  import { onMounted, reactive, ref } from 'vue'
  import { permissionsService, rolesService } from '@/api/services'
  import { useSwal } from '@/composables/useSwal'

  const swal = useSwal()

  const loading = ref(false)
  const savingRole = ref(false)
  const deletingRole = ref(false)
  const loadingPermissions = ref(false)
  const savingPermissions = ref(false)
  const loadingPageAccess = ref(false)
  const savingPageAccess = ref(false)
  const roles = ref([])
  const permissions = ref([])
  const roleDialog = ref(false)
  const permissionDialog = ref(false)
  const deleteRoleDialog = ref(false)
  const isEditRoleMode = ref(false)
  const selectedRole = ref(null)
  const selectedPermissionIds = ref([])
  const selectedPageCodes = ref([])
  const roleDialogTab = ref('basic')
  const roleFormRef = ref(null)
  const roleFormValid = ref(false)

  const roleFormData = reactive({
    role_code: '',
    role_name: '',
    role_name_en: '',
    description: '',
    display_order: 0,
    is_active: true,
  })

  const roleHeaders = [
    { title: '角色代碼', key: 'role_code', sortable: true },
    { title: '角色名稱', key: 'role_name', sortable: true },
    { title: '角色名稱（英文）', key: 'role_name_en', sortable: true },
    { title: '類型', key: 'is_system_role', sortable: true },
    { title: '狀態', key: 'is_active', sortable: true },
    { title: '顯示順序', key: 'display_order', sortable: true },
    { title: '操作', key: 'actions', sortable: false },
  ]

  // 可用頁面列表（參考 src/pages/index.vue）
  const availablePages = [
    { code: 'apply', name: '物料申請', description: '提交物料申請表單' },
    { code: 'packaging', name: '包裝說明設定', description: '設定包裝說明模板' },
    { code: 'review', name: '審核管理', description: '審核待審核的申請' },
    { code: 'export', name: 'EXCEL匯出', description: '匯出申請資料為EXCEL' },
    { code: 'query', name: '申請查詢', description: '查詢申請記錄' },
    { code: 'settings', name: '系統設定', description: '系統設定管理' },
    { code: 'users', name: '使用者管理', description: '管理使用者帳號' },
    { code: 'approval-workflow', name: '審核流程設定', description: '設定審核流程' },
    { code: 'forms', name: '表單管理', description: '管理動態表單' },
    { code: 'option-workbooks', name: '選項活頁簿', description: '管理選項活頁簿資料' },
  ]

  const rules = {
    required: value => !!value || '此欄位為必填',
    roleCode: value => {
      if (!value) return true
      const pattern = /^[a-z0-9_]+$/
      return pattern.test(value) || '角色代碼只能包含小寫字母、數字和底線'
    },
  }

  async function loadRoles () {
    loading.value = true
    try {
      const data = await rolesService.getRoles()
      roles.value = data || []
    } catch (error) {
      console.error('載入角色列表失敗', error)
      await swal.error('載入失敗', error.message || '無法取得角色列表')
    } finally {
      loading.value = false
    }
  }

  async function loadPermissions () {
    loadingPermissions.value = true
    try {
      const data = await permissionsService.getPermissions({ is_active: true })
      permissions.value = data || []
    } catch (error) {
      console.error('載入權限列表失敗', error)
      await swal.error('載入失敗', error.message || '無法取得權限列表')
    } finally {
      loadingPermissions.value = false
    }
  }

  function openCreateRoleDialog () {
    isEditRoleMode.value = false
    selectedRole.value = null
    resetRoleForm()
    roleDialogTab.value = 'basic'
    // 新角色預設所有頁面都可以訪問
    selectedPageCodes.value = availablePages.map(p => p.code)
    roleDialog.value = true
  }

  async function openEditRoleDialog (role) {
    isEditRoleMode.value = true
    selectedRole.value = role
    roleFormData.role_code = role.role_code || ''
    roleFormData.role_name = role.role_name || ''
    roleFormData.role_name_en = role.role_name_en || ''
    roleFormData.description = role.description || ''
    roleFormData.display_order = role.display_order || 0
    roleFormData.is_active = role.is_active !== undefined ? role.is_active : true
    roleDialogTab.value = 'basic'
    roleDialog.value = true

    // 載入該角色的頁面權限
    await loadRolePageAccess(role.id)
  }

  async function openPermissionDialog (role) {
    selectedRole.value = role
    await loadPermissions()

    // 載入該角色的權限
    try {
      const rolePermissions = await rolesService.getRolePermissions(role.id)
      selectedPermissionIds.value = rolePermissions.map(p => p.id)
    } catch (error) {
      console.error('載入角色權限失敗', error)
      await swal.error('載入失敗', error.message || '無法取得角色權限')
      return
    }

    permissionDialog.value = true
  }

  async function loadRolePageAccess (roleId) {
    loadingPageAccess.value = true
    try {
      const pageAccess = await rolesService.getRolePageAccess(roleId)
      // 如果沒有設定過頁面權限，預設所有頁面都可以訪問
      if (!pageAccess || pageAccess.length === 0) {
        selectedPageCodes.value = availablePages.map(p => p.code)
      } else {
        selectedPageCodes.value = pageAccess
          .filter(pa => pa.is_accessible)
          .map(pa => pa.page_code)
      }
    } catch (error) {
      console.error('載入角色頁面權限失敗', error)
      // 如果載入失敗，預設所有頁面都可以訪問
      selectedPageCodes.value = availablePages.map(p => p.code)
    } finally {
      loadingPageAccess.value = false
    }
  }

  function closeRoleDialog () {
    roleDialog.value = false
    roleDialogTab.value = 'basic'
    resetRoleForm()
    selectedPageCodes.value = []
  }

  function closePermissionDialog () {
    permissionDialog.value = false
    selectedPermissionIds.value = []
  }

  function resetRoleForm () {
    roleFormData.role_code = ''
    roleFormData.role_name = ''
    roleFormData.role_name_en = ''
    roleFormData.description = ''
    roleFormData.display_order = 0
    roleFormData.is_active = true
    roleFormRef.value?.resetValidation()
  }

  async function saveRole () {
    // 如果是在基本資訊分頁，驗證表單
    if (roleDialogTab.value === 'basic') {
      const { valid } = await roleFormRef.value.validate()
      if (!valid) {
        return
      }
    }

    savingRole.value = true
    savingPageAccess.value = true
    try {
      let roleId = null

      if (isEditRoleMode.value) {
        // 更新角色基本資訊（如果是在基本資訊分頁）
        if (roleDialogTab.value === 'basic') {
          const updatedRole = await rolesService.updateRole(selectedRole.value.id, roleFormData)
          roleId = updatedRole.id
          await swal.success('更新成功', '角色資料已更新')
        } else {
          // 如果是在頁面權限分頁，只更新頁面權限
          roleId = selectedRole.value.id
          const pageAccess = availablePages.map(page => ({
            page_code: page.code,
            page_name: page.name,
            is_accessible: selectedPageCodes.value.includes(page.code),
          }))
          await rolesService.setRolePageAccess(roleId, pageAccess)
          await swal.success('更新成功', '頁面權限已更新')
        }
      } else {
        // 建立新角色
        const newRole = await rolesService.createRole(roleFormData)
        roleId = newRole.id

        // 設定頁面權限
        const pageAccess = availablePages.map(page => ({
          page_code: page.code,
          page_name: page.name,
          is_accessible: selectedPageCodes.value.includes(page.code),
        }))
        await rolesService.setRolePageAccess(roleId, pageAccess)

        await swal.success('建立成功', '角色已建立')
      }

      // 如果是在頁面權限分頁，重新載入頁面權限
      if (roleDialogTab.value === 'pages' && isEditRoleMode.value) {
        await loadRolePageAccess(roleId)
      }

      await loadRoles()
    } catch (error) {
      console.error('儲存角色失敗', error)
      await swal.error('儲存失敗', error.message || '無法儲存角色資料')
    } finally {
      savingRole.value = false
      savingPageAccess.value = false
    }
  }

  async function savePermissions () {
    savingPermissions.value = true
    try {
      await rolesService.setRolePermissions(selectedRole.value.id, selectedPermissionIds.value)
      await swal.success('更新成功', '角色權限已更新')
      closePermissionDialog()
      await loadRoles()
    } catch (error) {
      console.error('儲存權限失敗', error)
      await swal.error('儲存失敗', error.message || '無法儲存角色權限')
    } finally {
      savingPermissions.value = false
    }
  }

  function openDeleteRoleDialog (role) {
    selectedRole.value = role
    deleteRoleDialog.value = true
  }

  async function confirmDeleteRole () {
    deletingRole.value = true
    try {
      await rolesService.deleteRole(selectedRole.value.id)
      await swal.success('刪除成功', '角色已刪除')
      deleteRoleDialog.value = false
      await loadRoles()
    } catch (error) {
      console.error('刪除角色失敗', error)
      await swal.error('刪除失敗', error.message || '無法刪除角色')
    } finally {
      deletingRole.value = false
    }
  }

  onMounted(() => {
    loadRoles()
  })
</script>

<style scoped lang="scss">
.role-permission-management {
  // 樣式可以根據需要添加
}
</style>
