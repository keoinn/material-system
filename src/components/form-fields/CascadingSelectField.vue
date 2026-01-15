<template>
  <div class="cascading-select-field">
    <v-label v-if="fieldLabel" class="mb-2">
      {{ fieldLabel }}
      <span v-if="field.is_required" class="text-error">*</span>
    </v-label>

    <div class="cascading-levels-container">
      <div
        v-for="(level, levelIndex) in levels"
        :key="levelIndex"
        class="cascading-level"
        :style="getLevelStyle(levelIndex)"
      >
        <v-label v-if="getLevelLabel(levelIndex)" class="mb-2">
          {{ getLevelLabel(levelIndex) }}
          <span v-if="isLevelRequired(levelIndex)" class="text-error">*</span>
        </v-label>
        <v-select
          :model-value="selectedValues[levelIndex]"
          :label="getLevelLabel(levelIndex) ? undefined : (level.label || level.field_label || `第 ${levelIndex + 1} 層`)"
          :placeholder="level.placeholder || '請選擇'"
          :hint="levelIndex === 0 ? field.help_text : level.help_text || ''"
          :items="getLevelOptions(levelIndex)"
          :required="isLevelRequired(levelIndex)"
          :rules="getLevelRules(levelIndex)"
          :disabled="field.is_readonly || disabled || loading || !isLevelEnabled(levelIndex)"
          :readonly="field.is_readonly"
          :variant="variant"
          :density="density"
          :loading="loading"
          :item-title="itemTitle"
          :item-value="itemValue"
          @update:model-value="handleLevelChange(levelIndex, $event)"
        />
      </div>
    </div>

    <div v-if="showValidationError" class="text-error text-caption mt-1">
      {{ validationError }}
    </div>
  </div>
</template>

<script setup>
  import { computed, ref, watch } from 'vue'

  const props = defineProps({
    field: {
      type: Object,
      required: true,
    },
    modelValue: {
      type: [String, Number, Array, Object],
      default: null,
    },
    options: {
      type: Array,
      default: () => [],
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    loading: {
      type: Boolean,
      default: false,
    },
    variant: {
      type: String,
      default: 'outlined',
    },
    density: {
      type: String,
      default: undefined,
    },
  })

  const emit = defineEmits(['update:modelValue'])

  const fieldLabel = computed(() => {
    return props.field.field_label || props.field.field_key
  })

  const fieldConfig = computed(() => {
    return props.field.field_config || {}
  })

  // 取得層級配置
  const levels = computed(() => {
    const config = fieldConfig.value
    if (config.levels && Array.isArray(config.levels)) {
      return config.levels
    }
    // 如果沒有配置，使用預設的單層
    return [{ label: fieldLabel.value, options: [] }]
  })

  // 選中的值（陣列形式，每個元素對應一層）
  const selectedValues = computed({
    get: () => {
      if (Array.isArray(props.modelValue)) {
        return props.modelValue
      }
      if (props.modelValue !== null && props.modelValue !== undefined) {
        return [props.modelValue]
      }
      return Array.from({ length: levels.value.length }, () => null)
    },
    set: (newValues) => {
      emit('update:modelValue', newValues)
    },
  })

  // 判斷層級是否啟用（上層必須有選擇才能啟用下層）
  function isLevelEnabled (levelIndex) {
    if (levelIndex === 0) {
      return true
    }
    // 檢查上一層是否有選擇
    return selectedValues.value[levelIndex - 1] !== null &&
           selectedValues.value[levelIndex - 1] !== undefined &&
           selectedValues.value[levelIndex - 1] !== ''
  }

  // 取得指定層級的選項
  function getLevelOptions (levelIndex) {
    const level = levels.value[levelIndex]
    if (!level) {
      return []
    }

    // 如果是第一層，直接返回該層的選項
    if (levelIndex === 0) {
      return formatOptions(level.options || [])
    }

    // 如果是後續層級，需要根據前面所有層級的選擇來過濾選項
    // 從第一層開始，逐層找到對應的選項
    let currentOptions = levels.value[0].options || []
    
    for (let i = 0; i < levelIndex; i++) {
      const selectedValue = selectedValues.value[i]
      if (!selectedValue) {
        return []
      }
      
      // 在當前選項中找到對應的選項
      const selectedOption = findOptionByValue(currentOptions, selectedValue)
      if (!selectedOption || !selectedOption.children) {
        return []
      }
      
      // 進入下一層的選項
      currentOptions = selectedOption.children
    }
    
    return formatOptions(currentOptions)
  }

  // 取得層級的欄寬
  function getLevelColumnSize (levelIndex) {
    const level = levels.value[levelIndex]
    if (!level) {
      return 12
    }
    // 從 level.columnSize 讀取，如果沒有則使用預設值 12
    return level.columnSize !== undefined && level.columnSize !== null ? Number(level.columnSize) : 12
  }

  // 取得層級的樣式
  function getLevelStyle (levelIndex) {
    const columnSize = getLevelColumnSize(levelIndex)
    const percentage = (columnSize / 12) * 100
    
    return {
      width: `${percentage}%`,
      maxWidth: `${percentage}%`,
      flexBasis: `${percentage}%`,
    }
  }

  // 格式化選項
  function formatOptions (options) {
    if (!Array.isArray(options)) {
      return []
    }
    return options.map(opt => {
      if (typeof opt === 'string') {
        return { title: opt, value: opt }
      }
      return {
        title: opt.label || opt.title || opt.value || opt,
        value: opt.value || opt,
        children: opt.children || []
      }
    })
  }

  // 根據值查找選項
  function findOptionByValue (options, value) {
    for (const opt of options) {
      const optValue = typeof opt === 'string' ? opt : (opt.value || opt)
      if (optValue === value) {
        return typeof opt === 'string' ? { value: opt } : opt
      }
      // 遞迴查找子選項
      if (opt.children) {
        const found = findOptionByValue(opt.children, value)
        if (found) {
          return found
        }
      }
    }
    return null
  }

  // 處理層級選擇變更
  function handleLevelChange (levelIndex, value) {
    const newValues = [...selectedValues.value]
    newValues[levelIndex] = value

    // 清除後續層級的選擇
    for (let i = levelIndex + 1; i < newValues.length; i++) {
      newValues[i] = null
    }

    selectedValues.value = newValues
  }

  // 取得層級標籤（包含必填星號）
  function getLevelLabel (levelIndex) {
    const level = levels.value[levelIndex]
    if (!level) {
      return `第 ${levelIndex + 1} 層`
    }
    const label = level.label || level.field_label || `第 ${levelIndex + 1} 層`
    // 如果該層級設為必填，會在 label 中顯示星號（通過 :required prop）
    return label
  }

  // 判斷層級是否必填
  function isLevelRequired (levelIndex) {
    const level = levels.value[levelIndex]
    if (!level) {
      return false
    }
    // 優先使用層級的 is_required 設定
    if (level.is_required !== undefined) {
      return level.is_required
    }
    // 如果層級沒有設定，且是第一層，則使用欄位的 is_required
    if (levelIndex === 0 && props.field.is_required) {
      return true
    }
    return false
  }

  // 取得層級驗證規則
  function getLevelRules (levelIndex) {
    const rules = []
    
    // 檢查該層級是否必填
    if (isLevelRequired(levelIndex)) {
      rules.push((v) => {
        if (v === null || v === undefined || v === '') {
          return '此欄位為必填'
        }
        return true
      })
    }

    return rules
  }

  // 驗證錯誤
  const validationError = computed(() => {
    // 檢查所有必填層級
    for (let i = 0; i < levels.value.length; i++) {
      if (isLevelRequired(i)) {
        const levelValue = selectedValues.value[i]
        if (!levelValue || levelValue === '') {
          const level = levels.value[i]
          const levelName = level?.label || level?.field_label || `第 ${i + 1} 層`
          return `${levelName} 為必填`
        }
      }
    }
    return ''
  })

  const showValidationError = computed(() => {
    return validationError.value !== ''
  })

  const itemTitle = computed(() => {
    return fieldConfig.value.itemTitle || 'title'
  })

  const itemValue = computed(() => {
    return fieldConfig.value.itemValue || 'value'
  })
</script>

<style scoped lang="scss">
.cascading-select-field {
  .v-label {
    display: block;
    font-size: 0.875rem;
    font-weight: 500;
    color: rgba(var(--v-theme-on-surface), var(--v-medium-emphasis-opacity));
  }

  .cascading-levels-container {
    display: flex;
    flex-wrap: wrap;
    width: 100%;
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    overflow: hidden; // 防止內容溢出
    
    // 在大螢幕時，如果總寬度不超過 12，則不換行
    @media (min-width: 961px) {
      flex-wrap: nowrap;
    }
  }

  .cascading-level {
    flex: 0 0 auto;
    min-width: 0;
    padding: 0;
    margin: 0;
    box-sizing: border-box;
    overflow: hidden; // 防止內容溢出
    
    // 除了最後一個層級，其他層級添加右邊距
    &:not(:last-child) {
      padding-right: 12px;
    }
    
    // 小螢幕時強制換行並佔滿整行
    @media (max-width: 960px) {
      width: 100% !important;
      max-width: 100% !important;
      flex: 0 0 100% !important;
      flex-basis: 100% !important;
      padding-right: 0 !important;
      margin-bottom: 16px;
      
      &:last-child {
        margin-bottom: 0;
      }
    }
  }
}
</style>
