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
            :loading="loadingPreview"
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
  import { applicationsService } from '@/api/services/applications'
  import { exportLogsService } from '@/api/services/exportLogs'
  import { isSupabaseAvailable, supabase } from '@/api/supabase'
  import { packagingService } from '@/api/services/packaging'
  import { categoriesService } from '@/api/services/categories'

  const swal = useSwal()

  const formRef = ref(null)
  const exporting = ref(false)
  const previewData = ref([])
  const loadingPreview = ref(false)

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

  /**
   * 獲取完整的申請資料（包含包裝和分類資訊）
   */
  async function fetchApplicationsForExport () {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 構建查詢條件（只包含有值的條件）
    const queryFilters = {}

    // 狀態篩選
    if (filters.status && filters.status !== 'ALL') {
      queryFilters.status = filters.status
    }

    // 日期篩選（確保日期格式正確）
    // 注意：Supabase 的日期查詢使用 submit_date 欄位，類型為 TIMESTAMP WITH TIME ZONE
    if (filters.startDate) {
      // 確保日期格式為 YYYY-MM-DD
      // 直接使用日期字符串，Supabase 會自動處理時區
      queryFilters.dateFrom = filters.startDate
    }

    if (filters.endDate) {
      // 確保日期格式為 YYYY-MM-DD
      // 直接使用日期字符串，Supabase 會自動處理時區
      queryFilters.dateTo = filters.endDate
    }

    // 如果選擇了特定類別，需要先查找類別 ID
    if (filters.category && filters.category !== 'ALL') {
      try {
        const mainCategories = await categoriesService.getMainCategories()
        const mainCategory = mainCategories.find(cat => cat.code === filters.category)
        if (mainCategory) {
          queryFilters.mainCategory = mainCategory.id
        } else {
          console.warn(`找不到類別代碼: ${filters.category}`)
        }
      } catch (error) {
        console.error('獲取分類失敗', error)
        // 不拋出錯誤，繼續查詢其他條件
      }
    }

    console.log('查詢條件:', JSON.stringify(queryFilters, null, 2))

    // 獲取申請列表
    let applications = []
    try {
      applications = await applicationsService.getApplications(queryFilters) || []
      console.log('查詢結果數量:', applications.length)
      
      if (applications.length === 0) {
        console.warn('沒有找到符合條件的申請記錄')
        console.log('查詢條件詳情:', {
          status: filters.status,
          category: filters.category,
          startDate: filters.startDate,
          endDate: filters.endDate,
          queryFilters,
        })
        return []
      }
    } catch (error) {
      console.error('查詢申請記錄時發生錯誤:', error)
      throw error
    }

    // 收集所有需要查詢的分類 ID
    const categoryIds = new Set()
    for (const app of applications) {
      if (app.main_category_id) categoryIds.add(app.main_category_id)
      if (app.sub_category_id) categoryIds.add(app.sub_category_id)
      if (app.spec_category_id) categoryIds.add(app.spec_category_id)
    }

    // 一次性獲取所有分類資訊
    const categoryMap = new Map()
    if (categoryIds.size > 0) {
      const { data: categories } = await supabase
        .from('product_categories')
        .select('id, code')
        .in('id', Array.from(categoryIds))

      if (categories) {
        for (const cat of categories) {
          categoryMap.set(cat.id, cat.code)
        }
      }
    }

    // 收集所有申請 ID
    const applicationIds = applications.map(app => app.id)

    // 一次性獲取所有包裝資料
    const packagingMap = new Map()
    if (applicationIds.length > 0) {
      const { data: allPackaging } = await supabase
        .from('application_packaging')
        .select(`
          application_id,
          packaging_categories (
            code
          ),
          packaging_options (
            name
          ),
          description
        `)
        .in('application_id', applicationIds)
        .order('application_id', { ascending: true })
        .order('packaging_category_id', { ascending: true })

      if (allPackaging) {
        for (const pkg of allPackaging) {
          if (!packagingMap.has(pkg.application_id)) {
            packagingMap.set(pkg.application_id, [])
          }
          packagingMap.get(pkg.application_id).push(pkg)
        }
      }
    }

    // 轉換資料格式
    return applications.map((app) => {
      const packagingData = packagingMap.get(app.id) || []
      const packaging = transformPackagingData(packagingData)

      return {
        ...app,
        itemCode: app.item_code,
        itemNameCN: app.item_name_cn,
        itemNameEN: app.item_name_en,
        mainCategory: categoryMap.get(app.main_category_id) || null,
        subCategory: categoryMap.get(app.sub_category_id) || null,
        specCategory: categoryMap.get(app.spec_category_id) || null,
        material: app.material,
        dimensions: app.dimensions,
        packaging,
      }
    })
  }

  /**
   * 轉換包裝資料格式
   */
  function transformPackagingData (packagingData) {
    const packaging = {
      productPackaging: { description: '' },
      accessoriesContent: { description: '' },
      accessories: { description: '' },
      innerBox: { description: '' },
      outerBox: { description: '' },
      transport: { description: '' },
      container: { description: '' },
      other: { description: '' },
    }

    // 包裝類別代碼映射
    const categoryCodeMap = {
      productPackaging: 'productPackaging',
      accessoriesContent: 'accessoriesContent',
      accessories: 'accessories',
      innerBox: 'innerBox',
      outerBox: 'outerBox',
      transport: 'transport',
      container: 'container',
      other: 'other',
    }

    // 按類別分組
    const groupedByCategory = {}
    for (const item of packagingData || []) {
      const categoryCode = item.packaging_categories?.code
      if (!categoryCode) continue

      if (!groupedByCategory[categoryCode]) {
        groupedByCategory[categoryCode] = []
      }

      const optionName = item.packaging_options?.name || ''
      const description = item.description || ''

      if (optionName) {
        groupedByCategory[categoryCode].push(optionName)
      }
      if (description && description.trim()) {
        groupedByCategory[categoryCode].push(description.trim())
      }
    }

    // 構建描述文字
    for (const [code, items] of Object.entries(groupedByCategory)) {
      const categoryKey = Object.keys(categoryCodeMap).find(
        key => categoryCodeMap[key] === code,
      )
      if (categoryKey && packaging[categoryKey]) {
        // 去重並合併
        const uniqueItems = [...new Set(items)]
        packaging[categoryKey].description = uniqueItems.join('; ')
      }
    }

    return packaging
  }

  async function exportToExcel () {
    exporting.value = true

    try {
      // 從 Supabase 獲取資料
      const data = await fetchApplicationsForExport()

      if (data.length === 0) {
        // 提供更詳細的錯誤信息
        let message = '沒有符合條件的資料。\n\n'
        message += '請檢查：\n'
        message += '1. 日期範圍是否正確\n'
        message += '2. 狀態篩選是否合適\n'
        message += '3. 物料大類是否正確\n'
        message += '4. 資料庫中是否有申請記錄'
        
        await swal.warning('沒有符合條件的資料', message)
        return
      }

      // 產生CSV格式
      let csv = '料號,料件說明,客戶說明,產品大類,產品中類,產品小類,料件基本材質,料件外型長,料件外型寬,料件外型高,料件外型重量,個別產品包裝,配件內容,配件,內盒,外箱,運輸與托盤要求,裝櫃要求,其他\n'

      for (const app of data) {
        csv += `${app.itemCode || ''},`
        csv += `"${(app.itemNameCN || '').replace(/"/g, '""')}",`
        csv += `"${(app.itemNameEN || '').replace(/"/g, '""')}",`
        csv += `${app.mainCategory || ''},`
        csv += `${app.subCategory || ''},`
        csv += `${app.specCategory || ''},`
        csv += `${app.material || ''},`
        csv += `${app.dimensions?.length || ''},`
        csv += `${app.dimensions?.width || ''},`
        csv += `${app.dimensions?.height || ''},`
        csv += `${app.dimensions?.weight || ''},`
        csv += `"${(app.packaging?.productPackaging?.description || '').replace(/"/g, '""')}",`
        csv += `"${(app.packaging?.accessoriesContent?.description || '').replace(/"/g, '""')}",`
        csv += `"${(app.packaging?.accessories?.description || '').replace(/"/g, '""')}",`
        csv += `"${(app.packaging?.innerBox?.description || '').replace(/"/g, '""')}",`
        csv += `"${(app.packaging?.outerBox?.description || '').replace(/"/g, '""')}",`
        csv += `"${(app.packaging?.transport?.description || '').replace(/"/g, '""')}",`
        csv += `"${(app.packaging?.container?.description || '').replace(/"/g, '""')}",`
        csv += `"${(app.packaging?.other?.description || '').replace(/"/g, '""')}"\n`
      }

      // 下載檔案
      const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      link.href = URL.createObjectURL(blob)
      const category = filters.category === 'ALL' ? 'ALL' : filters.category
      const date = new Date().toISOString().split('T')[0]
      const fileName = `SAP_Material_Export_${category}_${date}.csv`
      link.download = fileName
      link.click()

      // 記錄匯出日誌
      try {
        await exportLogsService.createExportLog({
          category: filters.category !== 'ALL' ? filters.category : null,
          status: filters.status !== 'ALL' ? filters.status : null,
          startDate: filters.startDate || null,
          endDate: filters.endDate || null,
          recordCount: data.length,
          fileName,
          fileSize: blob.size,
          format: 'CSV',
        })
      } catch (logError) {
        console.warn('記錄匯出日誌失敗', logError)
        // 不影響匯出流程
      }

      await swal.success(`已匯出 ${data.length} 筆資料！`, '匯出成功')
    } catch (error) {
      console.error('匯出失敗', error)
      await swal.error('匯出時發生錯誤', error.message || '無法匯出資料')
    } finally {
      exporting.value = false
    }
  }

  async function previewExport () {
    loadingPreview.value = true
    try {
      const data = await fetchApplicationsForExport()
      previewData.value = data.map(app => ({
        itemCode: app.itemCode,
        itemNameCN: app.itemNameCN,
        itemNameEN: app.itemNameEN,
        mainCategory: app.mainCategory,
        status: app.status,
      }))
    } catch (error) {
      console.error('預覽失敗', error)
      await swal.error('預覽失敗', error.message || '無法載入資料')
    } finally {
      loadingPreview.value = false
    }
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
