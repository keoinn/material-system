<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>EXCEL檔案匯出</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-alert class="mb-4" type="info" variant="tonal">
        <strong>注意：</strong>
        系統將根據動態表單欄位定義產生對應的EXCEL格式。每個表單都有專屬的欄位配置。
      </v-alert>

      <v-form ref="formRef">
        <v-row>
          <v-col cols="12" md="3">
            <v-select
              v-model="filters.formId"
              :items="formOptions"
              label="表單"
              variant="outlined"
              @update:model-value="onFormChange"
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
          >
            <template #item.status="{ item }">
              <v-chip
                :color="getStatusColor(item.status)"
                size="small"
                variant="flat"
              >
                {{ getStatusText(item.status) }}
              </v-chip>
            </template>
          </v-data-table>
        </v-card-text>
      </v-card>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { computed, onMounted, reactive, ref } from 'vue'
  import { useSwal } from '@/composables/useSwal'
  import { approvalWorkflowsService } from '@/api/services/approvalWorkflows'
  import { formDataService } from '@/api/services/formData'
  import { formsService } from '@/api/services/forms'
  import { exportLogsService } from '@/api/services/exportLogs'
  import { optionWorkbooksService } from '@/api/services/optionWorkbooks'
  import { suppliersService } from '@/api/services/suppliers'

  const swal = useSwal()

  const formRef = ref(null)
  const exporting = ref(false)
  const previewData = ref([])
  const loadingPreview = ref(false)
  const loadingForms = ref(false)
  const forms = ref([])
  const formFields = ref([]) // 當前選中表單的欄位定義
  const approvalStatuses = ref([]) // 審核狀態列表
  const fieldOptionsCache = reactive({}) // 欄位選項快取（用於選項活頁簿）
  const suppliersCache = reactive({}) // 供應商快取

  const filters = reactive({
    formId: null,
    startDate: '',
    endDate: '',
    status: '',
  })

  const formOptions = computed(() => {
    return forms.value.map(form => ({
      title: form.form_name,
      value: form.id,
    }))
  })

  // 從審核流程讀取狀態選項
  const statusOptions = computed(() => {
    const options = [{ title: '全部', value: '' }]
    const statuses = approvalStatuses.value
      .filter(s => s.is_active)
      .sort((a, b) => a.display_order - b.display_order)
      .map(s => ({
        title: s.status_name,
        value: s.status_code,
      }))
    return [...options, ...statuses]
  })

  const previewHeaders = ref([
    { title: '單號', key: 'record_id', sortable: true },
    { title: '料號', key: 'item_code', sortable: true },
    { title: '狀態', key: 'status', sortable: true },
  ])

  /**
   * 載入表單列表
   */
  async function loadForms () {
    loadingForms.value = true
    try {
      const data = await formsService.getForms({ is_active: true })
      forms.value = data || []
      
      // 如果有表單，預設選擇第一個
      if (forms.value.length > 0 && !filters.formId) {
        filters.formId = forms.value[0].id
        await onFormChange()
      }
    } catch (error) {
      console.error('載入表單列表失敗', error)
      await swal.error('載入失敗', error.message || '無法取得表單列表')
    } finally {
      loadingForms.value = false
    }
  }

  /**
   * 當表單改變時，載入欄位定義
   */
  async function onFormChange () {
    if (!filters.formId) {
      formFields.value = []
      return
    }

    try {
      const form = await formsService.getForm(filters.formId, true)
      if (form && form.fields) {
        // 過濾掉聚合欄位（通常不需要匯出，因為它們是計算得出的）
        formFields.value = form.fields
          .filter(f => f.field_type !== 'aggregated')
          .sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
      } else {
        formFields.value = []
      }
    } catch (error) {
      console.error('載入表單欄位定義失敗', error)
      formFields.value = []
    }
  }

  /**
   * 取得 checkbox 欄位的所有選項
   * @param {Object} field - 欄位定義
   * @returns {Promise<Array>} 選項列表
   */
  async function getCheckboxFieldOptions (field) {
    const config = field.field_config || {}
    
    // 如果使用選項活頁簿
    if (config.option_workbook_key) {
      const cacheKey = config.option_workbook_key
      if (!fieldOptionsCache[cacheKey]) {
        try {
          const options = await optionWorkbooksService.getWorkbookOptions(config.option_workbook_key)
          fieldOptionsCache[cacheKey] = options
        } catch (error) {
          console.error(`載入選項活頁簿 ${config.option_workbook_key} 失敗`, error)
          fieldOptionsCache[cacheKey] = []
        }
      }
      return fieldOptionsCache[cacheKey] || []
    }
    
    // 如果有 options 配置
    if (config.options && Array.isArray(config.options)) {
      return config.options.map(opt => {
        if (typeof opt === 'string') {
          return { value: opt, label: opt, title: opt }
        }
        return {
          value: opt.value || opt,
          label: opt.label || opt.title || opt.value || opt,
          title: opt.title || opt.label || opt.value || opt,
        }
      })
    }
    
    return []
  }

  /**
   * 格式化欄位值為字串（用於 Excel 匯出）
   * @param {any} value - 欄位值
   * @param {Object} field - 欄位定義
   * @param {Object} app - 應用記錄（包含 _fields）
   * @returns {Promise<string>|string} 格式化後的字串
   */
  async function formatFieldValue (value, field, app = null) {
    if (value === null || value === undefined || value === '') {
      return ''
    }

    const config = field.field_config || {}

    // 處理 select 和 multiselect 欄位
    if (field.field_type === 'select' || field.field_type === 'multiselect') {
      // 如果使用選項活頁簿
      if (config.option_workbook_key) {
        const cacheKey = config.option_workbook_key
        if (!fieldOptionsCache[cacheKey]) {
          try {
            const options = await optionWorkbooksService.getWorkbookOptions(config.option_workbook_key)
            fieldOptionsCache[cacheKey] = options
          } catch (error) {
            console.error(`載入選項活頁簿 ${config.option_workbook_key} 失敗`, error)
            fieldOptionsCache[cacheKey] = []
          }
        }
        
        const options = fieldOptionsCache[cacheKey] || []
        if (Array.isArray(value)) {
          // multiselect
          return value.map(v => {
            const option = options.find(opt => opt.value === v)
            return option ? (option.label || option.title || v) : v
          }).join('; ')
        } else {
          // select
          const option = options.find(opt => opt.value === value)
          return option ? (option.label || option.title || value) : value
        }
      }
      
      // 如果有 options 配置
      if (config.options && Array.isArray(config.options)) {
        if (Array.isArray(value)) {
          // multiselect
          return value.map(v => {
            const option = config.options.find(opt => {
              if (typeof opt === 'string') {
                return opt === v
              }
              return (opt.value || opt) === v
            })
            if (option) {
              if (typeof option === 'string') {
                return option
              }
              return option.title || option.label || option.value || v
            }
            return v
          }).join('; ')
        } else {
          // select
          const option = config.options.find(opt => {
            if (typeof opt === 'string') {
              return opt === value
            }
            return (opt.value || opt) === value
          })
          if (option) {
            if (typeof option === 'string') {
              return option
            }
            return option.title || option.label || option.value || value
          }
        }
      }
      
      // 如果是供應商欄位（根據欄位 key 判斷）
      if (field.field_key && (field.field_key.toLowerCase().includes('supplier') || field.field_key.toLowerCase().includes('供應商'))) {
        try {
          // 嘗試從快取獲取
          if (!suppliersCache[value]) {
            const supplier = await suppliersService.getSupplier(value)
            if (supplier) {
              suppliersCache[value] = supplier.name || supplier.code || value
            } else {
              suppliersCache[value] = value
            }
          }
          return suppliersCache[value]
        } catch (error) {
          console.warn(`獲取供應商 ${value} 名稱失敗`, error)
          return value
        }
      }
    }

    switch (field.field_type) {
      case 'number':
        return value.toString()

      case 'date':
        if (value instanceof Date) {
          return value.toISOString().split('T')[0]
        }
        if (typeof value === 'string') {
          return value.split('T')[0] // 移除時間部分
        }
        return String(value)

      case 'datetime':
        if (value instanceof Date) {
          return value.toISOString()
        }
        return String(value)

      case 'checkbox':
        if (Array.isArray(value)) {
          return value.join('; ')
        }
        return String(value)

      case 'cascading_select':
        if (Array.isArray(value)) {
          return value.filter(v => v !== null && v !== undefined).join(' - ')
        }
        return String(value)

      case 'json':
        if (typeof value === 'object') {
          return JSON.stringify(value)
        }
        return String(value)

      case 'file':
        return String(value)

      default:
        return String(value)
    }
  }

  /**
   * 獲取完整的申請資料（從動態表單讀取）
   */
  async function fetchApplicationsForExport () {
    if (!filters.formId) {
      throw new Error('請選擇表單')
    }

    // 構建審核記錄的篩選條件
    const approvalFilters = {}

    // 狀態篩選
    if (filters.status && filters.status !== '') {
      approvalFilters.status_code = filters.status
    }

    // 日期篩選
    if (filters.startDate) {
      approvalFilters.dateFrom = filters.startDate
    }

    if (filters.endDate) {
      approvalFilters.dateTo = filters.endDate
    }

    // 獲取所有審核記錄
    const approvalRecords = await approvalWorkflowsService.getAllApprovalApplications(approvalFilters)

    // 過濾出當前表單的記錄
    const formRecords = approvalRecords.filter(record => record.form_id === filters.formId)

    if (formRecords.length === 0) {
      return []
    }

    // 為每個記錄獲取表單資料
    const applications = await Promise.all(
      formRecords.map(async (record) => {
        try {
          // 從 form_data_values 獲取表單資料
          const formData = await formDataService.getFormData(
            filters.formId,
            record.record_id,
            { includeFieldDefinitions: true }
          )

          const values = formData?.values || {}
          const fields = formData?.fields || []

          // 查找欄位定義以確定正確的 field_key
          // 料號對應到「系統編碼」欄位（system_code）
          const systemCodeField = fields.find(f => f.field_key === 'system_code' || f.field_key === 'systemCode')
          const itemCodeField = systemCodeField || fields.find(f => f.field_key === 'item_code' || f.field_key === 'itemCode')

          let itemCode = values.system_code || values.systemCode || values.item_code || values.itemCode
          // 如果是聚合欄位，嘗試重新計算
          if (itemCodeField && itemCodeField.field_type === 'aggregated' && itemCodeField.field_config?.template) {
            try {
              itemCode = await formDataService._calculateAggregatedValue(
                itemCodeField.field_config.template,
                values,
                itemCodeField.field_config.counterKey || itemCodeField.field_key,
              )
            } catch (error) {
              console.warn('重新計算聚合料號失敗，使用原始值', error)
            }
          }
          if (!itemCode || itemCode === '') {
            itemCode = 'N/A'
          }

          // 構建應用記錄物件
          const app = {
            record_id: record.record_id,
            item_code: itemCode,
            status: record.current_status_code,
            status_name: record.current_status_name,
            applicant_name: record.applicant_username || 'Unknown',
            submit_date: record.submit_date,
            approval_date: record.approval_date,
            reject_date: record.reject_date,
            reject_reason: record.reject_reason,
            // 添加所有欄位值
            ...values,
            // 保存欄位定義以便後續使用
            _fields: fields,
          }

          return app
        } catch (error) {
          console.error(`載入申請 ${record.record_id} 的表單資料失敗`, error)
          return null
        }
      })
    )

    // 過濾掉 null 值
    return applications.filter(app => app !== null)
  }

  async function exportToExcel () {
    exporting.value = true

    try {
      // 從動態表單獲取資料
      const data = await fetchApplicationsForExport()

      if (data.length === 0) {
        let message = '沒有符合條件的資料。\n\n'
        message += '請檢查：\n'
        message += '1. 日期範圍是否正確\n'
        message += '2. 狀態篩選是否合適\n'
        message += '3. 表單是否正確\n'
        message += '4. 資料庫中是否有申請記錄'

        await swal.warning('沒有符合條件的資料', message)
        return
      }

      // 動態生成 CSV 標題行
      const headers = ['單號', '狀態', '申請人', '提交日期', '核准日期', '退回日期', '退回原因']
      
      // 預先載入所有 checkbox 欄位的選項（用於展開列）
      const checkboxFieldsMap = new Map() // Map<field_key, options[]>
      for (const field of formFields.value) {
        if (field.field_type === 'checkbox') {
          const options = await getCheckboxFieldOptions(field)
          checkboxFieldsMap.set(field.field_key, options)
        }
      }
      
      // 添加表單欄位標題
      for (const field of formFields.value) {
        if (field.field_type === 'checkbox') {
          // checkbox 欄位：每個選項變成一個列（不加上子群組名稱）
          const options = checkboxFieldsMap.get(field.field_key) || []
          for (const option of options) {
            const optionLabel = typeof option === 'string' ? option : (option.label || option.title || option.value || '')
            headers.push(`${field.field_label} - ${optionLabel}`)
          }
        } else {
          // 其他欄位：如果有子群組，加上子群組名稱
          if (field.sub_group) {
            headers.push(`${field.sub_group} - ${field.field_label}`)
          } else {
            headers.push(field.field_label)
          }
        }
      }

      // 產生 CSV 內容
      let csv = headers.map(h => `"${h.replace(/"/g, '""')}"`).join(',') + '\n'

      for (const app of data) {
        const row = [
          app.record_id || '',
          app.status_name || app.status || '',
          app.applicant_name || '',
          app.submit_date ? new Date(app.submit_date).toISOString().split('T')[0] : '',
          app.approval_date ? new Date(app.approval_date).toISOString().split('T')[0] : '',
          app.reject_date ? new Date(app.reject_date).toISOString().split('T')[0] : '',
          (app.reject_reason || '').replace(/"/g, '""'),
        ]

        // 添加表單欄位值
        for (const field of formFields.value) {
          const value = app[field.field_key]
          
          if (field.field_type === 'checkbox') {
            // checkbox 欄位：每個選項變成一個列，用 V 或空白表示
            const options = checkboxFieldsMap.get(field.field_key) || []
            const selectedValues = Array.isArray(value) ? value : (value ? [value] : [])
            
            for (const option of options) {
              const optionValue = typeof option === 'string' ? option : (option.value || option)
              const isSelected = selectedValues.includes(optionValue)
              row.push(isSelected ? 'V' : '')
            }
          } else {
            // 其他欄位：正常格式化
            const formattedValue = await formatFieldValue(value, field, app)
            row.push(String(formattedValue).replace(/"/g, '""'))
          }
        }

        csv += row.map(cell => `"${cell}"`).join(',') + '\n'
      }

      // 下載檔案
      const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      link.href = URL.createObjectURL(blob)
      const form = forms.value.find(f => f.id === filters.formId)
      const formCode = form?.form_code || 'unknown'
      const date = new Date().toISOString().split('T')[0]
      const fileName = `Export_${formCode}_${date}.csv`
      link.download = fileName
      link.click()

      // 記錄匯出日誌
      try {
        await exportLogsService.createExportLog({
          category: formCode,
          status: filters.status || null,
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

  // 從審核流程狀態定義獲取顏色
  function getStatusColor (status) {
    if (!status) return 'grey'
    const statusDef = approvalStatuses.value.find(s => s.status_code === status)
    return statusDef?.color || 'grey'
  }

  // 從審核流程狀態定義獲取文字
  function getStatusText (status) {
    if (!status) return '未知狀態'
    const statusDef = approvalStatuses.value.find(s => s.status_code === status)
    return statusDef?.status_name || status
  }

  // 載入審核狀態定義
  async function loadApprovalStatuses () {
    try {
      approvalStatuses.value = await approvalWorkflowsService.getApprovalStatuses({ is_active: true })
    } catch (error) {
      console.error('載入審核狀態失敗', error)
      // 如果載入失敗，使用預設狀態（向後兼容）
      approvalStatuses.value = [
        { status_code: 'DRAFT', status_name: '草稿', color: 'grey', is_active: true, display_order: 1 },
        { status_code: 'PENDING', status_name: '待審核', color: 'warning', is_active: true, display_order: 2 },
        { status_code: 'IN_REVIEW', status_name: '審核中', color: 'info', is_active: true, display_order: 3 },
        { status_code: 'APPROVED', status_name: '已核准', color: 'success', is_active: true, display_order: 4 },
        { status_code: 'REJECTED', status_name: '已退回', color: 'error', is_active: true, display_order: 5 },
        { status_code: 'RETURNED', status_name: '退回修改', color: 'warning', is_active: true, display_order: 6 },
      ]
    }
  }

  async function previewExport () {
    loadingPreview.value = true
    try {
      const data = await fetchApplicationsForExport()
      
      // 動態生成預覽標題（只顯示前幾個重要欄位）
      const headers = [
        { title: '單號', key: 'record_id', sortable: true },
        { title: '料號', key: 'item_code', sortable: true },
        { title: '狀態', key: 'status', sortable: true },
      ]
      
      // 預先載入所有 checkbox 欄位的選項（用於展開列）
      const checkboxFieldsMap = new Map() // Map<field_key, options[]>
      
      // 添加表單欄位的前幾個作為預覽
      if (formFields.value.length > 0) {
        const previewFieldCount = Math.min(5, formFields.value.length)
        for (let i = 0; i < previewFieldCount; i++) {
          const field = formFields.value[i]
          
          if (field.field_type === 'checkbox') {
            // checkbox 欄位：每個選項變成一個列（不加上子群組名稱）
            const options = await getCheckboxFieldOptions(field)
            checkboxFieldsMap.set(field.field_key, options)
            
            for (const option of options) {
              const optionLabel = typeof option === 'string' ? option : (option.label || option.title || option.value || '')
              const optionValue = typeof option === 'string' ? option : (option.value || option)
              headers.push({
                title: `${field.field_label} - ${optionLabel}`,
                key: `field_${field.field_key}_${optionValue}`,
                sortable: false,
              })
            }
          } else {
            // 其他欄位：如果有子群組，加上子群組名稱
            const title = field.sub_group ? `${field.sub_group} - ${field.field_label}` : field.field_label
            headers.push({
              title,
              key: `field_${field.field_key}`,
              sortable: false,
            })
          }
        }
      }
      
      // 更新預覽標題
      previewHeaders.value = headers
      
      // 轉換為預覽格式（需要處理 async formatFieldValue）
      const previewItems = []
      for (const app of data) {
        const previewItem = {
          record_id: app.record_id,
          item_code: app.item_code || 'N/A',
          status: app.status,
        }

        // 添加前幾個欄位作為預覽
        if (formFields.value.length > 0) {
          const previewFieldCount = Math.min(5, formFields.value.length)
          for (let i = 0; i < previewFieldCount; i++) {
            const field = formFields.value[i]
            const value = app[field.field_key]
            
            if (field.field_type === 'checkbox') {
              // checkbox 欄位：每個選項變成一個欄位
              const options = checkboxFieldsMap.get(field.field_key) || []
              const selectedValues = Array.isArray(value) ? value : (value ? [value] : [])
              
              for (const option of options) {
                const optionValue = typeof option === 'string' ? option : (option.value || option)
                const isSelected = selectedValues.includes(optionValue)
                previewItem[`field_${field.field_key}_${optionValue}`] = isSelected ? 'V' : ''
              }
            } else {
              // 其他欄位：正常格式化
              previewItem[`field_${field.field_key}`] = await formatFieldValue(value, field, app)
            }
          }
        }

        previewItems.push(previewItem)
      }
      
      previewData.value = previewItems
    } catch (error) {
      console.error('預覽失敗', error)
      await swal.error('預覽失敗', error.message || '無法載入資料')
    } finally {
      loadingPreview.value = false
    }
  }

  onMounted(async () => {
    // 設定預設日期
    const today = new Date().toISOString().split('T')[0]
    filters.endDate = today

    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    filters.startDate = thirtyDaysAgo.toISOString().split('T')[0]

    // 載入審核狀態和表單列表
    await Promise.all([
      loadApprovalStatuses(),
      loadForms(),
    ])
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.gap-4 {
  gap: 16px;
}
</style>
