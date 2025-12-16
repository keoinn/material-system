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

      <!-- 申請詳情對話框 -->
      <v-dialog
        v-model="detailDialog"
        max-width="900"
        scrollable
        persistent
      >
        <v-card v-if="selectedApplication">
          <v-card-title class="d-flex align-center bg-primary text-white">
            <v-icon class="mr-2">mdi-file-document-outline</v-icon>
            <span>申請詳情</span>
            <v-spacer />
            <v-btn
              icon
              variant="text"
              @click="detailDialog = false"
            >
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-card-title>

          <v-card-text class="pa-0">
            <v-container>
              <!-- 基本資訊區塊 -->
              <v-card
                class="mb-4"
                variant="outlined"
              >
                <v-card-title class="text-subtitle-1 bg-grey-lighten-4">
                  <v-icon class="mr-2">mdi-information</v-icon>
                  基本資訊
                </v-card-title>
                <v-card-text>
                  <v-row>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請單號：</span>
                        <span class="detail-value">{{ selectedApplication.id }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">料號：</span>
                        <span class="detail-value font-weight-bold text-primary">
                          {{ selectedApplication.itemCode }}
                        </span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">中文名稱：</span>
                        <span class="detail-value">{{ selectedApplication.itemNameCN }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">英文名稱：</span>
                        <span class="detail-value">{{ selectedApplication.itemNameEN }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">材質：</span>
                        <span class="detail-value">{{ selectedApplication.material }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">表面處理：</span>
                        <span class="detail-value">{{ selectedApplication.surfaceFinish || 'N/A' }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請人：</span>
                        <span class="detail-value">{{ selectedApplication.applicant }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">申請日期：</span>
                        <span class="detail-value">{{ formatDate(selectedApplication.submitDate) }}</span>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div class="detail-item">
                        <span class="detail-label">狀態：</span>
                        <v-chip
                          :color="getStatusColor(selectedApplication.status)"
                          size="small"
                          variant="flat"
                        >
                          {{ getStatusText(selectedApplication.status) }}
                        </v-chip>
                      </div>
                    </v-col>
                  </v-row>
                </v-card-text>
              </v-card>

              <!-- 包裝說明區塊 -->
              <v-card variant="outlined">
                <v-card-title class="text-subtitle-1 bg-grey-lighten-4">
                  <v-icon class="mr-2">mdi-package-variant</v-icon>
                  包裝說明
                </v-card-title>
                <v-card-text>
                  <div
                    v-for="(section, key) in selectedApplication.packaging"
                    :key="key"
                    class="packaging-section"
                  >
                    <div class="packaging-section-title">
                      {{ getPackagingSectionName(key) }}
                    </div>
                    <div class="packaging-section-content">
                      <div v-if="section.options?.length" class="mb-2">
                        <span class="text-grey-darken-1">選項：</span>
                        <v-chip
                          v-for="(option, index) in section.options"
                          :key="index"
                          class="ma-1"
                          color="primary"
                          size="small"
                          variant="outlined"
                        >
                          {{ option }}
                        </v-chip>
                      </div>
                      <div v-if="section.description">
                        <span class="text-grey-darken-1">說明：</span>
                        <span>{{ section.description }}</span>
                      </div>
                      <div
                        v-if="!section.options?.length && !section.description"
                        class="text-grey"
                      >
                        無資料
                      </div>
                    </div>
                  </div>
                </v-card-text>
              </v-card>
            </v-container>
          </v-card-text>

          <v-divider />

          <v-card-actions class="pa-4">
            <v-spacer />
            <v-btn
              color="primary"
              variant="flat"
              @click="detailDialog = false"
            >
              關閉
            </v-btn>
          </v-card-actions>
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

.detail-item {
  padding: 8px 0;
  min-height: 40px;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
}

.detail-label {
  font-weight: 600;
  color: rgba(0, 0, 0, 0.6);
  margin-right: 8px;
  min-width: 100px;
}

.detail-value {
  color: rgba(0, 0, 0, 0.87);
  flex: 1;
}

.packaging-section {
  margin-bottom: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.12);

  &:last-child {
    border-bottom: none;
    margin-bottom: 0;
    padding-bottom: 0;
  }
}

.packaging-section-title {
  font-weight: 600;
  color: rgba(0, 0, 0, 0.87);
  margin-bottom: 8px;
  font-size: 0.95rem;
}

.packaging-section-content {
  padding-left: 16px;
  color: rgba(0, 0, 0, 0.7);
}
</style>
