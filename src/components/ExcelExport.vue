<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>EXCEL檔案匯出</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-alert class="mb-4" type="info" variant="tonal">
        <strong>注意：</strong>
        系統將根據選擇的物料大類產生對應的EXCEL格式。每個大類都有專屬的欄位配置。
      </v-alert>

      <v-form ref="formRef">
        <v-row>
          <v-col cols="12" md="3">
            <v-select
              v-model="filters.category"
              :items="categoryOptions"
              label="物料大類"
              variant="outlined"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-text-field
              v-model="filters.startDate"
              label="開始日期"
              type="date"
              variant="outlined"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-text-field
              v-model="filters.endDate"
              label="結束日期"
              type="date"
              variant="outlined"
            />
          </v-col>
          <v-col cols="12" md="3">
            <v-select
              v-model="filters.status"
              :items="statusOptions"
              label="狀態"
              variant="outlined"
            />
          </v-col>
        </v-row>

        <div class="d-flex justify-center gap-4 mt-4">
          <v-btn
            color="success"
            :loading="exporting"
            size="large"
            @click="exportToExcel"
          >
            匯出EXCEL
          </v-btn>
          <v-btn
            color="info"
            size="large"
            @click="previewExport"
          >
            預覽資料
          </v-btn>
        </div>
      </v-form>

      <!-- 預覽資料 -->
      <v-card v-if="previewData.length > 0" class="mt-4">
        <v-card-title>預覽資料（共 {{ previewData.length }} 筆）</v-card-title>
        <v-card-text>
          <v-data-table
            class="elevation-1"
            :headers="previewHeaders"
            :items="previewData"
            :items-per-page="10"
          />
        </v-card-text>
      </v-card>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { onMounted, reactive, ref } from 'vue'
  import { useSwal } from '@/composables/useSwal'
  import { useApplicationsStore } from '@/stores/applications'

  const swal = useSwal()

  const applicationsStore = useApplicationsStore()

  const formRef = ref(null)
  const exporting = ref(false)
  const previewData = ref([])

  const filters = reactive({
    category: 'ALL',
    startDate: '',
    endDate: '',
    status: 'ALL',
  })

  const categoryOptions = [
    { title: '全部', value: 'ALL' },
    { title: 'H - Handle (把手)', value: 'H' },
    { title: 'S - Slide (滑軌)', value: 'S' },
    { title: 'M - Module/Assy (模組)', value: 'M' },
    { title: 'D - Decorative Hardware (裝飾五金)', value: 'D' },
    { title: 'F - Functional Hardware (功能五金)', value: 'F' },
    { title: 'B - Builders Hardware (建築五金)', value: 'B' },
    { title: 'I - Industrial Parts Solution (工業零件)', value: 'I' },
    { title: 'O - Others (其他)', value: 'O' },
  ]

  const statusOptions = [
    { title: '全部', value: 'ALL' },
    { title: '已核准', value: 'APPROVED' },
    { title: '待審核', value: 'PENDING' },
    { title: '已退回', value: 'REJECTED' },
  ]

  const previewHeaders = [
    { title: '料號', key: 'itemCode' },
    { title: '料件說明', key: 'itemNameCN' },
    { title: '客戶說明', key: 'itemNameEN' },
    { title: '產品大類', key: 'mainCategory' },
    { title: '狀態', key: 'status' },
  ]

  async function exportToExcel () {
    exporting.value = true

    try {
      const data = applicationsStore.exportApplications(filters)

      // 產生CSV格式
      let csv = '料號,料件說明,客戶說明,產品大類,產品中類,產品小類,料件基本材質,料件外型長,料件外型寬,料件外型高,料件外型重量,個別產品包裝,配件內容,配件,內盒,外箱,運輸與托盤要求,裝櫃要求,其他\n'

      for (const app of data) {
        csv += `${app.itemCode || ''},`
        csv += `"${app.itemNameCN || ''}",`
        csv += `"${app.itemNameEN || ''}",`
        csv += `${app.mainCategory || ''},`
        csv += `${app.subCategory || ''},`
        csv += `${app.specCategory || ''},`
        csv += `${app.material || ''},`
        csv += `${app.dimensions?.length || ''},`
        csv += `${app.dimensions?.width || ''},`
        csv += `${app.dimensions?.height || ''},`
        csv += `${app.dimensions?.weight || ''},`
        csv += `"${app.packaging?.productPackaging?.description || ''}",`
        csv += `"${app.packaging?.accessoriesContent?.description || ''}",`
        csv += `"${app.packaging?.accessories?.description || ''}",`
        csv += `"${app.packaging?.innerBox?.description || ''}",`
        csv += `"${app.packaging?.outerBox?.description || ''}",`
        csv += `"${app.packaging?.transport?.description || ''}",`
        csv += `"${app.packaging?.container?.description || ''}",`
        csv += `"${app.packaging?.other?.description || ''}"\n`
      }

      // 下載檔案
      const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      link.href = URL.createObjectURL(blob)
      const category = filters.category === 'ALL' ? 'ALL' : filters.category
      const date = new Date().toISOString().split('T')[0]
      link.download = `SAP_Material_Export_${category}_${date}.csv`
      link.click()

      await swal.success(`已匯出 ${data.length} 筆資料！`, '匯出成功')
    } catch (error) {
      console.error('匯出失敗', error)
      await swal.error('匯出時發生錯誤')
    } finally {
      exporting.value = false
    }
  }

  function previewExport () {
    previewData.value = applicationsStore.exportApplications(filters)
  }

  onMounted(() => {
    // 設定預設日期
    const today = new Date().toISOString().split('T')[0]
    filters.endDate = today

    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    filters.startDate = thirtyDaysAgo.toISOString().split('T')[0]
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.gap-4 {
  gap: 16px;
}
</style>
