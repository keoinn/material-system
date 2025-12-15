<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>包裝說明模板管理</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <p class="mb-4">在此設定各類別的預設勾選項目和說明模板</p>

      <v-row>
        <v-col cols="12" md="4">
          <v-select
            v-model="selectedCategory"
            :items="categoryOptions"
            label="選擇產品大類"
            variant="outlined"
            @update:model-value="loadTemplate"
          />
        </v-col>
      </v-row>

      <div v-if="selectedCategory" class="mt-4">
        <div class="form-section">
          <h4>設定預設包裝選項</h4>
          <p class="text-grey">
            選擇此類別產品常用的包裝選項，這些選項將在申請時自動勾選
          </p>

          <div
            v-for="(options, sectionKey) in packagingOptions"
            :key="sectionKey"
            class="packaging-section mt-4"
          >
            <h4>{{ getSectionName(sectionKey) }}</h4>
            <v-chip-group
              v-model="template[sectionKey]"
              multiple
              selected-class="text-primary"
            >
              <v-chip
                v-for="option in options"
                :key="option"
                filter
                :value="option"
                variant="outlined"
              >
                {{ option }}
              </v-chip>
            </v-chip-group>
          </div>
        </div>

        <div class="d-flex justify-center gap-4 mt-4">
          <v-btn
            color="primary"
            size="large"
            @click="saveTemplate"
          >
            儲存模板
          </v-btn>
          <v-btn
            color="grey"
            size="large"
            @click="resetTemplate"
          >
            重置為預設
          </v-btn>
        </div>
      </div>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { reactive, ref } from 'vue'
  import { useSwal } from '@/composables/useSwal'
  import { usePackagingStore } from '@/stores/packaging'

  const swal = useSwal()

  const packagingStore = usePackagingStore()

  const selectedCategory = ref('')
  const template = reactive({})

  const categoryOptions = [
    { title: 'H - Handle (把手)', value: 'H' },
    { title: 'S - Slide (滑軌)', value: 'S' },
    { title: 'M - Module/Assy (模組)', value: 'M' },
    { title: 'D - Decorative Hardware (裝飾五金)', value: 'D' },
    { title: 'F - Functional Hardware (功能五金)', value: 'F' },
    { title: 'B - Builders Hardware (建築五金)', value: 'B' },
    { title: 'I - Industrial Parts Solution (工業零件)', value: 'I' },
    { title: 'O - Others (其他)', value: 'O' },
  ]

  const packagingOptions = packagingStore.packagingOptions

  function getSectionName (key) {
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

  function loadTemplate () {
    if (!selectedCategory.value) {
      for (const key of Object.keys(template)) delete template[key]
      return
    }

    const savedTemplate = packagingStore.getTemplate(selectedCategory.value)
    const defaults = packagingStore.getDefaultOptions(selectedCategory.value)

    for (const key of Object.keys(packagingOptions)) {
      template[key] = savedTemplate[key] || defaults[key] || []
    }
  }

  async function saveTemplate () {
    if (!selectedCategory.value) {
      await swal.warning('請先選擇產品大類', '驗證失敗')
      return
    }

    const templateData = {}
    for (const key of Object.keys(packagingOptions)) {
      templateData[key] = template[key] || []
    }

    packagingStore.saveTemplate(selectedCategory.value, templateData)
    await swal.success('模板已儲存！')
  }

  async function resetTemplate () {
    if (!selectedCategory.value) {
      return
    }

    const result = await swal.confirm('確定要重置為預設值嗎？', '確認重置')
    if (result.isConfirmed) {
      const defaults = packagingStore.getDefaultOptions(selectedCategory.value)
      for (const key of Object.keys(packagingOptions)) {
        template[key] = defaults[key] || []
      }
      await swal.success('已重置為預設值！')
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

  h4 {
    color: #495057;
    margin-bottom: 15px;
    font-size: 1.1em;
  }
}

.packaging-section {
  background: #fff;
  border: 2px solid #dee2e6;
  border-radius: 10px;
  padding: 20px;
  margin-bottom: 20px;

  h4 {
    color: #495057;
    margin-bottom: 15px;
    font-size: 1.1em;
  }
}

.gap-4 {
  gap: 16px;
}
</style>
