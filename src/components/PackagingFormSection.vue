<!--
  PackagingFormSection.vue
  
  注意：此組件目前未在專案中使用。
  系統已改為使用 DynamicFormRenderer 動態渲染表單欄位。
  
  此組件保留作為：
  1. 包裝表單的參考實現
  2. 未來可能需要單獨使用包裝表單的場景
  
  如需使用，請在組件中導入：
  import PackagingFormSection from '@/components/PackagingFormSection.vue'
  
  組件功能：
  - 組合 8 個 PackagingSection 組件，形成完整的包裝說明表單
  - 包含：個別產品包裝、配件內容、配件、內盒、外箱、運輸與托盤要求、裝櫃要求、其他說明
  - 使用 packagingStore 載入包裝選項
-->

<template>
  <div class="form-section">
    <h3>包裝說明</h3>

    <!-- 1. 個別產品包裝 -->
    <PackagingSection
      v-model="localPackaging.productPackaging"
      :options="packagingOptions.productPackaging || []"
      placeholder="額外說明（如：1PC/塑膠袋，印刷回收標誌04 PE-LD）"
      title="1. 個別產品包裝"
    />

    <!-- 2. 配件內容 -->
    <PackagingSection
      v-model="localPackaging.accessoriesContent"
      :options="packagingOptions.accessoriesContent || []"
      placeholder="額外說明（如：附木螺絲4顆，螺絲散裝）"
      title="2. 配件內容"
    />

    <!-- 3. 配件 -->
    <PackagingSection
      v-model="localPackaging.accessories"
      :options="packagingOptions.accessories || []"
      placeholder="額外說明"
      title="3. 配件"
    />

    <!-- 4. 內盒 -->
    <PackagingSection
      v-model="localPackaging.innerBox"
      :options="packagingOptions.innerBox || []"
      placeholder="額外說明（如：內盒上需印製ITEM NO. & Q'TY）"
      title="4. 內盒"
    />

    <!-- 5. 外箱 -->
    <PackagingSection
      v-model="localPackaging.outerBox"
      :options="packagingOptions.outerBox || []"
      placeholder="額外說明（如：外箱側嘜之ITEM NO.請印製客戶產品編號）"
      title="5. 外箱"
    />

    <!-- 6. 運輸與托盤要求 -->
    <PackagingSection
      v-model="localPackaging.transport"
      :options="packagingOptions.transport || []"
      placeholder="額外說明（如：出貨提供EUDR文件）"
      title="6. 運輸與托盤要求"
    />

    <!-- 7. 裝櫃要求 -->
    <PackagingSection
      v-model="localPackaging.container"
      :options="packagingOptions.container || []"
      placeholder="額外說明（如：256SETS/1X40FCL）"
      title="7. 裝櫃要求"
    />

    <!-- 8. 其他說明 -->
    <PackagingSection
      v-model="localPackaging.other"
      :options="packagingOptions.other || []"
      placeholder="額外說明（如：供應商具FSC證書）"
      title="8. 其他說明"
    />
  </div>
</template>

<script setup>
  import { computed, onMounted } from 'vue'
  import { storeToRefs } from 'pinia'
  import { usePackagingStore } from '@/stores/packaging'
  import PackagingSection from './PackagingSection.vue'

  const props = defineProps({
    modelValue: {
      type: Object,
      required: true,
    },
    category: {
      type: String,
      default: '',
    },
  })

  const emit = defineEmits(['update:modelValue'])

  const packagingStore = usePackagingStore()
  const { packagingOptions } = storeToRefs(packagingStore)

  const localPackaging = computed({
    get: () => props.modelValue,
    set: value => emit('update:modelValue', value),
  })

  // 確保包裝選項已載入
  onMounted(async () => {
    await packagingStore.loadPackagingOptions()
  })
</script>

<style scoped lang="scss">
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
</style>
