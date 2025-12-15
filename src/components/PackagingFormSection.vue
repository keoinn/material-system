<template>
  <div class="form-section">
    <h3>包裝說明</h3>

    <!-- 1. 個別產品包裝 -->
    <PackagingSection
      v-model="localPackaging.productPackaging"
      :options="packagingOptions.productPackaging"
      placeholder="額外說明（如：1PC/塑膠袋，印刷回收標誌04 PE-LD）"
      title="1. 個別產品包裝"
    />

    <!-- 2. 配件內容 -->
    <PackagingSection
      v-model="localPackaging.accessoriesContent"
      :options="packagingOptions.accessoriesContent"
      placeholder="額外說明（如：附木螺絲4顆，螺絲散裝）"
      title="2. 配件內容"
    />

    <!-- 3. 配件 -->
    <PackagingSection
      v-model="localPackaging.accessories"
      :options="packagingOptions.accessories"
      placeholder="額外說明"
      title="3. 配件"
    />

    <!-- 4. 內盒 -->
    <PackagingSection
      v-model="localPackaging.innerBox"
      :options="packagingOptions.innerBox"
      placeholder="額外說明（如：內盒上需印製ITEM NO. & Q'TY）"
      title="4. 內盒"
    />

    <!-- 5. 外箱 -->
    <PackagingSection
      v-model="localPackaging.outerBox"
      :options="packagingOptions.outerBox"
      placeholder="額外說明（如：外箱側嘜之ITEM NO.請印製客戶產品編號）"
      title="5. 外箱"
    />

    <!-- 6. 運輸與托盤要求 -->
    <PackagingSection
      v-model="localPackaging.transport"
      :options="packagingOptions.transport"
      placeholder="額外說明（如：出貨提供EUDR文件）"
      title="6. 運輸與托盤要求"
    />

    <!-- 7. 裝櫃要求 -->
    <PackagingSection
      v-model="localPackaging.container"
      :options="packagingOptions.container"
      placeholder="額外說明（如：256SETS/1X40FCL）"
      title="7. 裝櫃要求"
    />

    <!-- 8. 其他說明 -->
    <PackagingSection
      v-model="localPackaging.other"
      :options="packagingOptions.other"
      placeholder="額外說明（如：供應商具FSC證書）"
      title="8. 其他說明"
    />
  </div>
</template>

<script setup>
  import { computed } from 'vue'
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
  const packagingOptions = packagingStore.packagingOptions

  const localPackaging = computed({
    get: () => props.modelValue,
    set: value => emit('update:modelValue', value),
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
