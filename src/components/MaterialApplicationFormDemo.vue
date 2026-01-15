<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>物料申請</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-progress-linear
        v-if="loading"
        class="mb-4"
        color="primary"
        indeterminate
      />

      <v-form ref="formRef" v-model="valid">
        <!-- 基本資料 -->
        <div class="form-section">
          <h3>基本資料</h3>
          <v-row>
            <v-col cols="12" md="3">
              <v-select
                v-model="form.mainCategory"
                :items="mainCategories"
                label="產品大類 *"
                placeholder="請選擇"
                required
                :rules="[rules.required]"
                variant="outlined"
                @update:model-value="handleMainCategoryChange"
              />
            </v-col>
            <v-col cols="12" md="3">
              <v-select
                v-model="form.subCategory"
                :disabled="!form.mainCategory"
                :items="subCategories"
                label="產品中類 *"
                placeholder="請選擇"
                required
                :rules="[rules.required]"
                variant="outlined"
                @update:model-value="handleSubCategoryChange"
              />
            </v-col>
            <v-col cols="12" md="3">
              <v-select
                v-model="form.specCategory"
                :disabled="!form.subCategory"
                :items="specCategories"
                label="產品小類 *"
                placeholder="請選擇"
                required
                :rules="[rules.required]"
                variant="outlined"
                @update:model-value="handleSpecCategoryChange"
              />
            </v-col>
            <v-col cols="12" md="3">
              <v-text-field
                v-model="form.itemCode"
                bg-color="grey-lighten-4"
                label="系統編碼"
                readonly
                variant="outlined"
              />
            </v-col>
          </v-row>
        </div>

        <!-- 物料資訊 -->
        <div class="form-section">
          <h3>物料資訊</h3>
          <v-row>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.itemNameCN"
                label="料件說明 (中文) *"
                required
                :rules="[rules.required]"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.itemNameEN"
                label="料件說明 (英文) *"
                required
                :rules="[rules.required]"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.customerRef"
                label="客戶參考貨號"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-select
                v-model="form.supplier"
                :items="suppliers"
                label="供應商"
                placeholder="請選擇"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-select
                v-model="form.material"
                :items="materials"
                label="基本材質 *"
                placeholder="請選擇"
                required
                :rules="[rules.required]"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-select
                v-model="form.surfaceFinish"
                :items="surfaceFinishes"
                label="表面處理"
                placeholder="請選擇"
                variant="outlined"
              />
            </v-col>
          </v-row>
        </div>

        <!-- 尺寸規格 -->
        <div class="form-section">
          <h3>尺寸規格</h3>
          <v-row>
            <v-col cols="12" md="3">
              <v-text-field
                v-model.number="form.dimensions.length"
                label="長度 (mm)"
                type="number"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="3">
              <v-text-field
                v-model.number="form.dimensions.width"
                label="寬度 (mm)"
                type="number"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="3">
              <v-text-field
                v-model.number="form.dimensions.height"
                label="高度 (mm)"
                type="number"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="3">
              <v-text-field
                v-model.number="form.dimensions.weight"
                label="重量 (g)"
                type="number"
                variant="outlined"
              />
            </v-col>
          </v-row>
        </div>

        <!-- 包裝說明 -->
        <PackagingFormSection v-model="form.packaging" :category="form.mainCategory" />

        <!-- 按鈕 -->
        <div class="d-flex justify-center gap-4 mt-6">
          <v-btn
            color="grey"
            size="large"
            @click="clearForm"
          >
            清除表單
          </v-btn>
          <v-btn
            color="primary"
            :loading="submitting"
            size="large"
            @click="submitApplication"
          >
            提交申請
          </v-btn>
          <v-btn
            color="info"
            size="large"
            @click="saveAsDraft"
          >
            儲存草稿
          </v-btn>
        </div>
      </v-form>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { onMounted, reactive, ref } from 'vue'
  import { useRouter } from 'vue-router'
  import { applicationsService } from '@/api/services/applications'
  import { categoriesService } from '@/api/services/categories'
  import { codeCountersService } from '@/api/services/codeCounters'
  import { packagingService } from '@/api/services/packaging'
  import { settingsService } from '@/api/services/settings'
  import { suppliersService } from '@/api/services/suppliers'
  import { systemOptionsService } from '@/api/services/systemOptions'
  import { useSwal } from '@/composables/useSwal'
  import { usePackagingStore } from '@/stores/packaging'
  import PackagingFormSection from './PackagingFormSection.vue'

  const swal = useSwal()
  const router = useRouter()

  const packagingStore = usePackagingStore()

  const formRef = ref(null)
  const valid = ref(false)
  const submitting = ref(false)
  const loading = ref(false)

  // 資料載入狀態
  const mainCategories = ref([])
  const subCategories = ref([])
  const specCategories = ref([])
  const suppliers = ref([])
  const materials = ref([])
  const surfaceFinishes = ref([])

  // 載入分類資料
  async function loadMainCategories () {
    try {
      const data = await categoriesService.getMainCategories()
      mainCategories.value = (data || []).map(cat => ({
        title: `${cat.name_cn || cat.name}`,
        value: cat.code,
      }))
    } catch (error) {
      console.error('載入產品大類失敗', error)
      await swal.error('載入產品大類失敗，請重新整理頁面')
    }
  }

  // 載入中類資料
  async function loadSubCategories () {
    if (!form.mainCategory) {
      subCategories.value = []
      return
    }

    try {
      const data = await categoriesService.getSubCategories(form.mainCategory)
      subCategories.value = (data || []).map(cat => ({
        title: `${cat.code} - ${cat.name_cn || cat.name}`,
        value: cat.code,
      }))
    } catch (error) {
      console.error('載入產品中類失敗', error)
      subCategories.value = []
    }
  }

  // 載入小類資料
  async function loadSpecCategories () {
    if (!form.mainCategory) {
      specCategories.value = []
      return
    }

    try {
      const data = await categoriesService.getSpecCategories(form.mainCategory)
      specCategories.value = (data || []).map(cat => ({
        title: `${cat.code} - ${cat.name_cn || cat.name}`,
        value: cat.code,
      }))
    } catch (error) {
      console.error('載入產品小類失敗', error)
      specCategories.value = []
    }
  }

  // 載入供應商資料
  async function loadSuppliers () {
    try {
      const data = await suppliersService.getSuppliers({ isActive: true })
      suppliers.value = (data || []).map(sup => ({
        title: sup.name,
        value: sup.code || sup.id.toString(),
      }))
    } catch (error) {
      console.error('載入供應商失敗', error)
      await swal.warning('載入供應商失敗，將使用預設值')
    }
  }

  // 載入材質選項
  async function loadMaterials () {
    try {
      const data = await systemOptionsService.getOptions('material_application', 'material')
      materials.value = (data || []).map(item => ({
        title: item.label || item.value,
        value: item.value,
      }))
    } catch (error) {
      console.error('載入材質選項失敗', error)
      // 使用預設值
      materials.value = [
        'Steel',
        'Stainless Steel',
        'Brass',
        'Zinc Alloy (Zamak)',
        'Aluminum',
        'Plastic',
        'Wood',
        'Others',
      ].map(item => ({
        title: item,
        value: item,
      }))
    }
  }

  // 載入表面處理選項
  async function loadSurfaceFinishes () {
    try {
      const data = await systemOptionsService.getOptions('material_application', 'surfaceFinish')
      surfaceFinishes.value = (data || []).map(item => ({
        title: item.label || item.value,
        value: item.value,
      }))
    } catch (error) {
      console.error('載入表面處理選項失敗', error)
      // 使用預設值
      surfaceFinishes.value = [
        'Chrome Plated',
        'Nickel Plated',
        'Zinc Plated',
        'Powder Coating',
        'Anodized',
        'Natural',
      ].map(item => ({
        title: item,
        value: item,
      }))
    }
  }

  // 初始化載入所有資料
  async function loadAllData () {
    loading.value = true
    try {
      await Promise.all([
        loadMainCategories(),
        loadSuppliers(),
        loadMaterials(),
        loadSurfaceFinishes(),
      ])
    } catch (error) {
      console.error('載入資料失敗', error)
    } finally {
      loading.value = false
    }
  }

  onMounted(() => {
    loadAllData()
    // 處理必填欄位的紅色星號
    styleRequiredAsterisks()
  })

  // 處理必填欄位的紅色星號
  function styleRequiredAsterisks () {
    // 使用 nextTick 確保 DOM 已渲染
    setTimeout(() => {
      const labels = document.querySelectorAll('.v-field-label')
      for (const label of labels) {
        if (label.textContent && label.textContent.includes('*')) {
          // 創建一個 span 來包裹星號
          const text = label.textContent.trim()
          const asteriskIndex = text.indexOf('*')
          if (asteriskIndex !== -1) {
            const beforeAsterisk = text.slice(0, asteriskIndex)
            const asterisk = text.slice(asteriskIndex)
            // 清空 label 內容
            label.innerHTML = ''
            // 添加文字部分
            if (beforeAsterisk) {
              label.append(document.createTextNode(beforeAsterisk))
            }
            // 添加紅色星號
            const asteriskSpan = document.createElement('span')
            asteriskSpan.textContent = asterisk
            asteriskSpan.style.color = '#f44336'
            asteriskSpan.style.fontWeight = 'bold'
            label.append(asteriskSpan)
          }
        }
      }
    }, 100)
  }

  const form = reactive({
    mainCategory: null,
    subCategory: null,
    specCategory: null,
    itemCode: '',
    itemNameCN: '',
    itemNameEN: '',
    customerRef: '',
    supplier: null,
    material: null,
    surfaceFinish: null,
    dimensions: {
      length: null,
      width: null,
      height: null,
      weight: null,
    },
    packaging: {
      productPackaging: { options: [], description: '' },
      accessoriesContent: { options: [], description: '' },
      accessories: { options: [], description: '' },
      innerBox: { options: [], description: '' },
      outerBox: { options: [], description: '' },
      transport: { options: [], description: '' },
      container: { options: [], description: '' },
      other: { options: [], description: '' },
    },
  })

  const rules = {
    required: value => !!value || '此欄位為必填',
  }

  async function handleMainCategoryChange () {
    form.subCategory = null
    form.specCategory = null
    form.itemCode = ''
    await loadSubCategories()
    await loadSpecCategories()
    await loadDefaultPackaging()
    // 重新處理星號樣式
    setTimeout(() => styleRequiredAsterisks(), 50)
  }

  async function handleSubCategoryChange () {
    form.specCategory = null
    form.itemCode = ''
    await loadSpecCategories()
    // 重新處理星號樣式
    setTimeout(() => styleRequiredAsterisks(), 50)
  }

  function handleSpecCategoryChange () {
    generateItemCode()
  }

  async function generateItemCode () {
    if (!form.mainCategory || !form.subCategory || !form.specCategory) {
      form.itemCode = ''
      return
    }

    try {
      // 1. 獲取系統設定（流水號位數）
      const settings = await settingsService.getSettings()
      const serialDigits = settings.serialDigits || 5

      // 2. 構建計數器鍵值（格式: {大類}{中類}.{小類}）
      const counterKey = `${form.mainCategory}${form.subCategory}.${form.specCategory}`

      // 3. 獲取並增加計數器
      const counter = await codeCountersService.getAndIncrementCounter(counterKey)

      // 4. 根據編碼格式生成編碼
      // 格式: {大類}{中類}.{小類}.{流水號}
      const serial = String(counter).padStart(serialDigits, '0')
      const itemCode = `${form.mainCategory}${form.subCategory}.${form.specCategory}.${serial}`

      form.itemCode = itemCode
    } catch (error) {
      console.error('生成系統編碼失敗', error)
      await swal.error('生成系統編碼失敗', error.message || '無法生成系統編碼，請稍後再試')
      form.itemCode = ''
    }
  }

  async function loadDefaultPackaging () {
    if (!form.mainCategory) {
      return
    }

    try {
      // 從 Supabase 讀取預設包裝選項
      const defaults = await packagingService.getCategoryDefaults(form.mainCategory)

      // 將 Supabase 返回的格式轉換成表單需要的格式
      // Supabase 返回格式: { categoryCode: [optionCode, ...] }
      // 表單需要格式: form.packaging.categoryCode.options = [optionCode, ...]
      if (defaults.productPackaging && Array.isArray(defaults.productPackaging)) {
        form.packaging.productPackaging.options = defaults.productPackaging
      }
      if (defaults.accessoriesContent && Array.isArray(defaults.accessoriesContent)) {
        form.packaging.accessoriesContent.options = defaults.accessoriesContent
      }
      if (defaults.accessories && Array.isArray(defaults.accessories)) {
        form.packaging.accessories.options = defaults.accessories
      }
      if (defaults.innerBox && Array.isArray(defaults.innerBox)) {
        form.packaging.innerBox.options = defaults.innerBox
      }
      if (defaults.outerBox && Array.isArray(defaults.outerBox)) {
        form.packaging.outerBox.options = defaults.outerBox
      }
      if (defaults.transport && Array.isArray(defaults.transport)) {
        form.packaging.transport.options = defaults.transport
      }
      if (defaults.container && Array.isArray(defaults.container)) {
        form.packaging.container.options = defaults.container
      }
      if (defaults.other && Array.isArray(defaults.other)) {
        form.packaging.other.options = defaults.other
      }
    } catch (error) {
      console.error('載入預設包裝選項失敗', error)
      // 如果 Supabase 載入失敗，回退到 store 中的預設值
      const fallbackDefaults = packagingStore.getDefaultOptions(form.mainCategory)
      if (fallbackDefaults.productPackaging) {
        form.packaging.productPackaging.options = fallbackDefaults.productPackaging
      }
      if (fallbackDefaults.accessoriesContent) {
        form.packaging.accessoriesContent.options = fallbackDefaults.accessoriesContent
      }
      if (fallbackDefaults.innerBox) {
        form.packaging.innerBox.options = fallbackDefaults.innerBox
      }
      if (fallbackDefaults.outerBox) {
        form.packaging.outerBox.options = fallbackDefaults.outerBox
      }
    }
  }

  async function submitApplication () {
    const { valid: isValid } = await formRef.value.validate()
    if (!isValid) {
      return
    }

    if (!form.itemCode || !form.itemNameCN || !form.itemNameEN || !form.material) {
      await swal.warning('請填寫所有必填欄位！', '驗證失敗')
      return
    }

    submitting.value = true

    try {
      const applicationData = {
        itemCode: form.itemCode,
        mainCategory: form.mainCategory,
        subCategory: form.subCategory,
        specCategory: form.specCategory,
        itemNameCN: form.itemNameCN,
        itemNameEN: form.itemNameEN,
        customerRef: form.customerRef,
        supplier: form.supplier,
        material: form.material,
        surfaceFinish: form.surfaceFinish,
        dimensions: form.dimensions,
        packaging: form.packaging,
      }

      // 提交到 Supabase
      const application = await applicationsService.createApplication(applicationData)
      await swal.success(`申請單號：${application.id}\n料號：${application.item_code}`, '申請已提交！')
      clearForm()
      // 跳轉到審核管理頁面
      router.push({ path: '/', query: { tab: 'review' } })
    } catch (error) {
      console.error('提交申請失敗', error)
      const errorMessage = error.message || '提交申請時發生錯誤'
      await swal.error(errorMessage)
    } finally {
      submitting.value = false
    }
  }

  function clearForm () {
    Object.assign(form, {
      mainCategory: null,
      subCategory: null,
      specCategory: null,
      itemCode: '',
      itemNameCN: '',
      itemNameEN: '',
      customerRef: '',
      supplier: null,
      material: null,
      surfaceFinish: null,
      dimensions: {
        length: null,
        width: null,
        height: null,
        weight: null,
      },
      packaging: {
        productPackaging: { options: [], description: '' },
        accessoriesContent: { options: [], description: '' },
        accessories: { options: [], description: '' },
        innerBox: { options: [], description: '' },
        outerBox: { options: [], description: '' },
        transport: { options: [], description: '' },
        container: { options: [], description: '' },
        other: { options: [], description: '' },
      },
    })
    formRef.value?.resetValidation()
  }

  async function saveAsDraft () {
    try {
      localStorage.setItem('draft_v35', JSON.stringify(form))
      await swal.success('草稿已儲存！')
    } catch (error) {
      console.error('儲存草稿失敗', error)
      await swal.error('儲存草稿時發生錯誤')
    }
  }

  // 載入草稿
  const draft = localStorage.getItem('draft_v35')
  if (draft) {
    try {
      const draftData = JSON.parse(draft)
      Object.assign(form, draftData)
      if (form.mainCategory) {
        handleMainCategoryChange()
      }
    } catch (error) {
      console.error('載入草稿失敗', error)
    }
  }
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.form-section {
  margin-bottom: 30px;
  padding: 25px;
  background: #f8f9fa;
  border-radius: 10px;

  h3 {
    color: #667eea;
    margin-bottom: 20px;
    font-size: 1.3em;
    border-bottom: 2px solid #667eea;
    padding-bottom: 10px;
  }
}

.gap-4 {
  gap: 16px;
}

// 必填欄位的紅色星號
// Vuetify 3 會在有 required 屬性或 rules 時自動添加星號元素
:deep(.v-label__asterisk) {
  color: #f44336 !important;
}

// 針對不同狀態的 label
:deep(.v-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label--floating .v-label__asterisk) {
  color: #f44336 !important;
}

// 針對 v-field 內的星號
:deep(.v-field .v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

// 針對 v-input 內的星號
:deep(.v-input .v-label__asterisk) {
  color: #f44336 !important;
}
</style>
