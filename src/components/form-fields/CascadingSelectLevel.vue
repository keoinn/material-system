<template>
  <div class="cascading-select-level">
    <v-label v-if="levelLabel" class="mb-2">
      {{ levelLabel }}
      <span v-if="isLevelRequired" class="text-error">*</span>
    </v-label>
    <v-select
      :model-value="selectedValue"
      :label="levelLabel ? undefined : (level.label || level.field_label || `第 ${levelIndex + 1} 層`)"
      :placeholder="level.placeholder || '請選擇'"
      :hint="levelIndex === 0 ? field.help_text : level.help_text || ''"
      :items="levelOptions"
      :required="isLevelRequired"
      :rules="levelRules"
      :disabled="field.is_readonly || disabled || loading || !isLevelEnabled"
      :readonly="field.is_readonly"
      :variant="variant"
      :density="density"
      :loading="loading"
      :item-title="itemTitle"
      :item-value="itemValue"
      @update:model-value="$emit('update:modelValue', $event)"
    />
  </div>
</template>

<script setup>
  import { computed } from 'vue'

  const props = defineProps({
    field: {
      type: Object,
      required: true,
    },
    level: {
      type: Object,
      required: true,
    },
    levelIndex: {
      type: Number,
      required: true,
    },
    selectedValues: {
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

  const fieldConfig = computed(() => {
    return props.field.field_config || {}
  })

  const levels = computed(() => {
    const config = fieldConfig.value
    if (config.levels && Array.isArray(config.levels)) {
      return config.levels
    }
    return []
  })

  const selectedValue = computed(() => {
    if (Array.isArray(props.selectedValues)) {
      return props.selectedValues[props.levelIndex] || null
    }
    return null
  })

  const levelLabel = computed(() => {
    return props.level.label || props.level.field_label || `第 ${props.levelIndex + 1} 層`
  })

  const isLevelRequired = computed(() => {
    // 優先使用層級的 is_required 設定
    if (props.level.is_required !== undefined) {
      return props.level.is_required
    }
    // 如果層級沒有設定，且是第一層，則使用欄位的 is_required
    if (props.levelIndex === 0 && props.field.is_required) {
      return true
    }
    return false
  })

  const isLevelEnabled = computed(() => {
    if (props.levelIndex === 0) {
      return true
    }
    // 檢查上一層是否有選擇
    const prevValue = props.selectedValues[props.levelIndex - 1]
    return prevValue !== null && prevValue !== undefined && prevValue !== ''
  })

  const levelOptions = computed(() => {
    const level = levels.value[props.levelIndex]
    if (!level) {
      return []
    }

    // 如果是第一層，從 cascading_options 讀取選項
    if (props.levelIndex === 0) {
      // 優先從 cascading_options 讀取
      const cascadingOptions = fieldConfig.value.cascading_options
      if (cascadingOptions && Array.isArray(cascadingOptions)) {
        return formatOptions(cascadingOptions)
      }
      // 兼容舊格式：如果沒有 cascading_options，嘗試從 level.options 讀取
      return formatOptions(level.options || [])
    }

    // 如果是後續層級，需要根據前面所有層級的選擇來過濾選項
    // 從 cascading_options 開始（第一層的選項）
    let currentOptions = []
    const cascadingOptions = fieldConfig.value.cascading_options
    if (cascadingOptions && Array.isArray(cascadingOptions)) {
      currentOptions = cascadingOptions
    } else if (levels.value[0] && levels.value[0].options) {
      // 兼容舊格式
      currentOptions = levels.value[0].options
    }
    
    // 如果沒有選項，直接返回空陣列
    if (!currentOptions || currentOptions.length === 0) {
      return []
    }
    
    // 根據前面所有層級的選擇來過濾選項
    for (let i = 0; i < props.levelIndex; i++) {
      const selectedValue = props.selectedValues[i]
      if (selectedValue === null || selectedValue === undefined || selectedValue === '') {
        return []
      }
      
      // 查找對應的選項
      const selectedOption = findOptionByValue(currentOptions, selectedValue)
      if (!selectedOption) {
        // 如果找不到選項，返回空陣列
        console.warn(`找不到層級 ${i + 1} 的值 "${selectedValue}" 對應的選項`, {
          levelIndex: i,
          selectedValue,
          currentOptions: currentOptions.slice(0, 3), // 只顯示前3個選項用於調試
        })
        return []
      }
      
      // 檢查是否有子選項
      if (!selectedOption.children || !Array.isArray(selectedOption.children) || selectedOption.children.length === 0) {
        // 如果沒有子選項，返回空陣列
        return []
      }
      
      // 進入下一層的選項
      currentOptions = selectedOption.children
    }
    
    return formatOptions(currentOptions)
  })

  const levelRules = computed(() => {
    const rules = []
    
    if (isLevelRequired.value) {
      rules.push((v) => {
        if (v === null || v === undefined || v === '') {
          return '此欄位為必填'
        }
        return true
      })
    }

    return rules
  })

  const itemTitle = computed(() => {
    return fieldConfig.value.itemTitle || 'title'
  })

  const itemValue = computed(() => {
    return fieldConfig.value.itemValue || 'value'
  })

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
    if (value === null || value === undefined || value === '') {
      return null
    }

    for (const opt of options) {
      let optValue
      if (typeof opt === 'string') {
        optValue = opt
      } else {
        // 嘗試多種可能的屬性名稱
        optValue = opt.value !== undefined ? opt.value : (opt.id !== undefined ? opt.id : opt)
      }

      // 進行類型轉換比較（支持字符串和數字的互換）
      // 先進行嚴格相等比較
      if (optValue === value) {
        return typeof opt === 'string' ? { value: opt } : opt
      }

      // 如果嚴格相等不匹配，嘗試字符串轉換比較
      const optValueStr = String(optValue)
      const valueStr = String(value)
      if (optValueStr === valueStr) {
        return typeof opt === 'string' ? { value: opt } : opt
      }

      // 如果字符串比較不匹配，嘗試數字轉換比較（僅當兩者都是有效數字時）
      const optValueNum = Number(optValue)
      const valueNum = Number(value)
      if (!isNaN(optValueNum) && !isNaN(valueNum) && optValueNum === valueNum) {
        return typeof opt === 'string' ? { value: opt } : opt
      }
    }
    return null
  }
</script>

<style scoped lang="scss">
.cascading-select-level {
  .v-label {
    display: block;
    font-size: 0.875rem;
    font-weight: 500;
    color: rgba(var(--v-theme-on-surface), var(--v-medium-emphasis-opacity));
  }
}
</style>
