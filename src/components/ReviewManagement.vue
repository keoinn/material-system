<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>待審核申請</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-data-table
        class="elevation-1"
        :headers="headers"
        :items="pendingApplications"
        :loading="loading"
      >
        <template #item.submitDate="{ item }">
          {{ formatDate(item.submitDate) }}
        </template>

        <template #item.status="{ item }">
          <v-chip
            :color="getStatusColor(item.status)"
            size="small"
            variant="flat"
          >
            {{ getStatusText(item.status) }}
          </v-chip>
        </template>

        <template #item.actions="{ item }">
          <v-btn
            class="mr-2"
            color="success"
            size="small"
            @click="approveApplication(item.id)"
          >
            核准
          </v-btn>
          <v-btn
            class="mr-2"
            color="error"
            size="small"
            @click="rejectApplication(item.id)"
          >
            退回
          </v-btn>
          <v-btn
            color="info"
            size="small"
            @click="viewDetails(item.id)"
          >
            詳情
          </v-btn>
        </template>

        <template #no-data>
          <div class="text-center py-4">
            目前沒有待審核的申請
          </div>
        </template>
      </v-data-table>

      <!-- 詳情對話框 -->
      <v-dialog v-model="detailDialog" max-width="800">
        <v-card v-if="selectedApplication">
          <v-card-title>
            申請詳情
            <v-spacer />
            <v-btn icon @click="detailDialog = false">
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-card-title>

          <v-card-text>
            <v-row>
              <v-col cols="12" md="6">
                <strong>申請單號：</strong>{{ selectedApplication.id }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>料號：</strong>{{ selectedApplication.itemCode }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>中文名稱：</strong>{{ selectedApplication.itemNameCN }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>英文名稱：</strong>{{ selectedApplication.itemNameEN }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>材質：</strong>{{ selectedApplication.material }}
              </v-col>
              <v-col cols="12" md="6">
                <strong>表面處理：</strong>{{ selectedApplication.surfaceFinish || 'N/A' }}
              </v-col>
            </v-row>

            <v-divider class="my-4" />

            <h3 class="mb-2">包裝說明</h3>
            <div v-for="(section, key) in selectedApplication.packaging" :key="key">
              <strong>{{ getPackagingSectionName(key) }}：</strong>
              <span v-if="section.options?.length">
                {{ section.options.join(', ') }}
              </span>
              <span v-if="section.description">{{ section.description }}</span>
            </div>
          </v-card-text>
        </v-card>
      </v-dialog>

      <!-- 退回原因對話框 -->
      <v-dialog v-model="rejectDialog" max-width="500">
        <v-card>
          <v-card-title>輸入退回原因</v-card-title>
          <v-card-text>
            <v-textarea
              v-model="rejectReason"
              label="退回原因"
              rows="3"
              variant="outlined"
            />
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn @click="rejectDialog = false">取消</v-btn>
            <v-btn color="error" @click="confirmReject">確認退回</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { computed, ref } from 'vue'
  import { useSwal } from '@/composables/useSwal'
  import { useApplicationsStore } from '@/stores/applications'
  import { useAuthStore } from '@/stores/auth'

  const swal = useSwal()

  const applicationsStore = useApplicationsStore()
  const authStore = useAuthStore()

  const loading = ref(false)
  const detailDialog = ref(false)
  const rejectDialog = ref(false)
  const selectedApplication = ref(null)
  const rejectReason = ref('')
  const rejectApplicationId = ref(null)

  const pendingApplications = computed(() => applicationsStore.pendingApplications)

  const headers = [
    { title: '申請日期', key: 'submitDate', sortable: true },
    { title: '申請單號', key: 'id', sortable: true },
    { title: '料號', key: 'itemCode', sortable: true },
    { title: '料件說明', key: 'itemNameCN', sortable: true },
    { title: '申請人', key: 'applicant', sortable: true },
    { title: '狀態', key: 'status', sortable: true },
    { title: '操作', key: 'actions', sortable: false },
  ]

  function formatDate (dateString) {
    if (!dateString) return ''
    return new Date(dateString).toLocaleDateString('zh-TW')
  }

  function getStatusColor (status) {
    const colors = {
      PENDING: 'warning',
      APPROVED: 'success',
      REJECTED: 'error',
    }
    return colors[status] || 'grey'
  }

  function getStatusText (status) {
    const texts = {
      PENDING: '待審核',
      APPROVED: '已核准',
      REJECTED: '已退回',
    }
    return texts[status] || status
  }

  function getPackagingSectionName (key) {
    const names = {
      productPackaging: '1. 個別產品包裝',
      accessoriesContent: '2. 配件內容',
      accessories: '3. 配件',
      innerBox: '4. 內盒',
      outerBox: '5. 外箱',
      transport: '6. 運輸與托盤要求',
      container: '7. 裝櫃要求',
      other: '8. 其他說明',
    }
    return names[key] || key
  }

  async function approveApplication (id) {
    const result = await swal.confirm('確定要核准此申請嗎？', '確認核准')
    if (result.isConfirmed) {
      const approver = authStore.currentUser?.username || 'System'
      applicationsStore.approveApplication(id, approver)
      await swal.success('申請已核准！')
    }
  }

  function rejectApplication (id) {
    rejectApplicationId.value = id
    rejectReason.value = ''
    rejectDialog.value = true
  }

  async function confirmReject () {
    if (!rejectReason.value.trim()) {
      await swal.warning('請輸入退回原因', '驗證失敗')
      return
    }

    const approver = authStore.currentUser?.username || 'System'
    applicationsStore.rejectApplication(rejectApplicationId.value, rejectReason.value, approver)
    rejectDialog.value = false
    rejectReason.value = ''
    await swal.success('申請已退回！')
  }

  function viewDetails (id) {
    selectedApplication.value = applicationsStore.getApplication(id)
    detailDialog.value = true
  }
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';
</style>
