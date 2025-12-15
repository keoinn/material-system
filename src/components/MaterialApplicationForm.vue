<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>物料申請</h2>
    </v-card-title>

    <v-card-text class="pt-6">
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
                :rules="[rules.required]"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.itemNameEN"
                label="料件說明 (英文) *"
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
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-select
                v-model="form.material"
                :items="materials"
                label="基本材質 *"
                :rules="[rules.required]"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-select
                v-model="form.surfaceFinish"
                :items="surfaceFinishes"
                label="表面處理"
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
  import { computed, reactive, ref, watch } from 'vue'
  import { useSwal } from '@/composables/useSwal'
  import { useApplicationsStore } from '@/stores/applications'
  import { useAuthStore } from '@/stores/auth'
  import { usePackagingStore } from '@/stores/packaging'
  import PackagingFormSection from './PackagingFormSection.vue'

  const swal = useSwal()

  const applicationsStore = useApplicationsStore()
  const authStore = useAuthStore()
  const packagingStore = usePackagingStore()

  const formRef = ref(null)
  const valid = ref(false)
  const submitting = ref(false)

  // 分類資料
  const categories = {
    H: {
      name: 'Handle',
      subCategories: {
        '00': '未分類',
        '01': 'Knob',
        '02': 'Pull',
        '03': 'Handle',
        '04': 'Bar Handle',
        '05': 'Cup Pull',
        '06': 'Ring Pull',
      },
      specs: {
        A: 'Aluminum',
        B: 'Brass',
        C: 'Chrome',
        S: 'Stainless Steel',
        Z: 'Zinc Alloy',
      },
    },
    S: {
      name: 'Slide',
      subCategories: {
        '00': '未分類',
        '01': 'Ball Bearing Slide',
        '02': 'Undermount Slide',
        '03': 'Soft Close Slide',
        '04': 'Heavy Duty Slide',
      },
      specs: {
        B: 'Ball Bearing',
        S: 'Soft Close',
        F: 'Full Extension',
        P: 'Partial Extension',
      },
    },
    M: {
      name: 'Module/Assy',
      subCategories: {
        '00': '未分類',
        '01': 'Drawer System',
        '02': 'Pull-Out System',
        '03': 'Organizer',
        '04': 'Basket System',
      },
      specs: {
        D: 'Drawer',
        P: 'Pull-Out',
        O: 'Organizer',
        B: 'Basket',
      },
    },
    D: {
      name: 'Decorative Hardware',
      subCategories: {
        '00': '未分類',
        '01': 'Furniture Leg',
        '02': 'Decorative Handle',
        '03': 'Ornament',
      },
      specs: {
        L: 'Leg',
        H: 'Handle',
        O: 'Ornament',
      },
    },
    F: {
      name: 'Functional Hardware',
      subCategories: {
        '00': '未分類',
        '01': 'Hinge',
        '02': 'Caster',
        '03': 'Lock',
        '04': 'Catch',
      },
      specs: {
        H: 'Hinge',
        C: 'Caster',
        L: 'Lock',
        T: 'Catch',
      },
    },
    B: {
      name: 'Builders Hardware',
      subCategories: {
        '00': '未分類',
        '01': 'Door Hardware',
        '02': 'Window Hardware',
        '03': 'Gate Hardware',
      },
      specs: {
        D: 'Door',
        W: 'Window',
        G: 'Gate',
      },
    },
    I: {
      name: 'Industrial Parts Solution',
      subCategories: {
        '00': '未分類',
        '01': 'Industrial Slide',
        '02': 'Heavy Duty Component',
        '03': 'Custom Solution',
      },
      specs: {
        S: 'Slide',
        H: 'Heavy Duty',
        C: 'Custom',
      },
    },
    O: {
      name: 'Others',
      subCategories: {
        '00': '未分類',
        '99': '其他',
      },
      specs: {
        X: '其他',
      },
    },
  }

  const mainCategories = [
    { title: 'H - Handle (把手)', value: 'H' },
    { title: 'S - Slide (滑軌)', value: 'S' },
    { title: 'M - Module/Assy (模組)', value: 'M' },
    { title: 'D - Decorative Hardware (裝飾五金)', value: 'D' },
    { title: 'F - Functional Hardware (功能五金)', value: 'F' },
    { title: 'B - Builders Hardware (建築五金)', value: 'B' },
    { title: 'I - Industrial Parts Solution (工業零件)', value: 'I' },
    { title: 'O - Others (其他)', value: 'O' },
  ]

  const subCategories = computed(() => {
    if (!form.mainCategory || !categories[form.mainCategory]) {
      return []
    }
    const subCats = categories[form.mainCategory].subCategories
    return Object.entries(subCats).map(([code, name]) => ({
      title: `${code} - ${name}`,
      value: code,
    }))
  })

  const specCategories = computed(() => {
    if (!form.mainCategory || !categories[form.mainCategory]) {
      return []
    }
    const specs = categories[form.mainCategory].specs
    return Object.entries(specs).map(([code, name]) => ({
      title: `${code} - ${name}`,
      value: code,
    }))
  })

  const suppliers = [
    { title: '供應商A', value: 'SUP001' },
    { title: '供應商B', value: 'SUP002' },
    { title: '供應商C', value: 'SUP003' },
  ]

  const materials = [
    'Steel',
    'Stainless Steel',
    'Brass',
    'Zinc Alloy (Zamak)',
    'Aluminum',
    'Plastic',
    'Wood',
    'Others',
  ]

  const surfaceFinishes = [
    'Chrome Plated',
    'Nickel Plated',
    'Zinc Plated',
    'Powder Coating',
    'Anodized',
    'Natural',
  ]

  const form = reactive({
    mainCategory: '',
    subCategory: '',
    specCategory: '',
    itemCode: '',
    itemNameCN: '',
    itemNameEN: '',
    customerRef: '',
    supplier: '',
    material: '',
    surfaceFinish: '',
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

  function handleMainCategoryChange () {
    form.subCategory = ''
    form.specCategory = ''
    form.itemCode = ''
    loadDefaultPackaging()
  }

  function handleSubCategoryChange () {
    form.specCategory = ''
    form.itemCode = ''
  }

  function handleSpecCategoryChange () {
    generateItemCode()
  }

  function generateItemCode () {
    if (form.mainCategory && form.subCategory && form.specCategory) {
      const code = applicationsStore.generateItemCode(
        form.mainCategory,
        form.subCategory,
        form.specCategory,
      )
      if (code) {
        form.itemCode = code
      }
    }
  }

  function loadDefaultPackaging () {
    if (form.mainCategory) {
      const defaults = packagingStore.getDefaultOptions(form.mainCategory)
      if (defaults.productPackaging) {
        form.packaging.productPackaging.options = defaults.productPackaging
      }
      if (defaults.accessoriesContent) {
        form.packaging.accessoriesContent.options = defaults.accessoriesContent
      }
      if (defaults.innerBox) {
        form.packaging.innerBox.options = defaults.innerBox
      }
      if (defaults.outerBox) {
        form.packaging.outerBox.options = defaults.outerBox
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
        applicant: authStore.currentUser?.username || 'Guest User',
      }

      const application = applicationsStore.addApplication(applicationData)
      await swal.success(`申請單號：${application.id}\n料號：${application.itemCode}`, '申請已提交！')
      clearForm()
    } catch (error) {
      console.error('提交申請失敗', error)
      await swal.error('提交申請時發生錯誤')
    } finally {
      submitting.value = false
    }
  }

  function clearForm () {
    Object.assign(form, {
      mainCategory: '',
      subCategory: '',
      specCategory: '',
      itemCode: '',
      itemNameCN: '',
      itemNameEN: '',
      customerRef: '',
      supplier: '',
      material: '',
      surfaceFinish: '',
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
</style>
