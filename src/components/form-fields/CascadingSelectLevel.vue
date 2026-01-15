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

    // 如果是第一層，直接返回該層的選項
    if (props.levelIndex === 0) {
      return formatOptions(level.options || [])
    }

    // 如果是後續層級，需要根據前面所有層級的選擇來過濾選項
    let currentOptions = levels.value[0].options || []
    
    for (let i = 0; i < props.levelIndex; i++) {
      const selectedValue = props.selectedValues[i]
      if (!selectedValue) {
        return []
      }
      
      const selectedOption = findOptionByValue(currentOptions, selectedValue)
      if (!selectedOption || !selectedOption.children) {
        return []
      }
      
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
