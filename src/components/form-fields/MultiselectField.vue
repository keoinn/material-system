<template>
  <!-- Chip Group 模式 -->
  <div v-if="useChipGroup" class="multiselect-chip-group">
    <v-label v-if="fieldLabel" class="mb-2">
      {{ fieldLabel }}
      <span v-if="field.is_required" class="text-error">*</span>
    </v-label>
    <v-chip-group
      :disabled="field.is_readonly || disabled || loading"
      :model-value="selectedValues"
      multiple
      selected-class="text-primary"
      @update:model-value="handleChipGroupUpdate"
    >
      <v-chip
        v-for="item in chipOptions"
        :key="getChipValue(item)"
        filter
        :value="getChipValue(item)"
        variant="outlined"
      >
        {{ getChipTitle(item) }}
      </v-chip>
    </v-chip-group>
    <div v-if="field.help_text" class="text-caption text-medium-emphasis mt-1">
      {{ field.help_text }}
    </div>
    <div v-if="showValidationError" class="text-error text-caption mt-1">
      {{ validationError }}
    </div>
  </div>

  <!-- 預設 Select 模式 -->
  <div v-else>
    <v-label v-if="fieldLabel" class="mb-2">
      {{ fieldLabel }}
      <span v-if="field.is_required" class="text-error">*</span>
    </v-label>
    <v-select
      :bg-color="field.is_readonly ? 'grey-lighten-4' : undefined"
      chips
      closable-chips
      :density="density"
      :disabled="field.is_readonly || disabled || loading"
      :hint="field.help_text"
      :item-title="itemTitle"
      :item-value="itemValue"
      :items="items"
      :label="fieldLabel ? undefined : (field.field_label || field.field_key)"
      :loading="loading"
      :model-value="modelValue"
      multiple
      :placeholder="field.placeholder || '請選擇'"
      :readonly="field.is_readonly"
      :required="field.is_required"
      :rules="validationRules"
      :variant="variant"
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
    modelValue: {
      type: Array,
      default: () => [],
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

  // 判斷是否使用 Chip Group 模式
  const useChipGroup = computed(() => {
    return fieldConfig.value.display_mode === 'chip_group'
      || fieldConfig.value.use_chip_group === true
  })

  const items = computed(() => {
    if (props.options && props.options.length > 0) {
      return props.options
    }

    if (fieldConfig.value.options && Array.isArray(fieldConfig.value.options)) {
      return fieldConfig.value.options.map(opt => {
        if (typeof opt === 'string') {
          return { title: opt, value: opt }
        }
        return opt
      })
    }

    return []
  })

  // Chip Group 使用的選項（簡化為字符串或值）
  const chipOptions = computed(() => {
    return items.value
  })

  // 取得 Chip 的值
  function getChipValue (item) {
    if (typeof item === 'string') {
      return item
    }
    if (item && typeof item === 'object') {
      return item.value || item.title || item
    }
    return item
  }

  // 取得 Chip 的標題
  function getChipTitle (item) {
    if (typeof item === 'string') {
      return item
    }
    if (item && typeof item === 'object') {
      return item.title || item.label || item.value || item
    }
    return item
  }

  // Chip Group 的選中值
  const selectedValues = computed({
    get: () => {
      if (!Array.isArray(props.modelValue)) {
        return []
      }
      return props.modelValue.map(val => {
        // 如果值是對象，提取 value
        if (val && typeof val === 'object') {
          return val.value || val
        }
        return val
      })
    },
    set: newValues => {
      emit('update:modelValue', newValues)
    },
  })

  // 處理 Chip Group 更新
  function handleChipGroupUpdate (newValues) {
    selectedValues.value = newValues
  }

  // 驗證錯誤
  const validationError = computed(() => {
    if (props.field.is_required && (!props.modelValue || (Array.isArray(props.modelValue) && props.modelValue.length === 0))) {
      return '此欄位為必填'
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

  const validationRules = computed(() => {
    const rules = []

    if (props.field.is_required) {
      rules.push(v => {
        if (!v || (Array.isArray(v) && v.length === 0)) {
          return '此欄位為必填'
        }
        return true
      })
    }

    return rules
  })
</script>

<style scoped lang="scss">
.multiselect-chip-group {
  .v-label {
    display: block;
    font-size: 0.875rem;
    font-weight: 500;
    color: rgba(var(--v-theme-on-surface), var(--v-medium-emphasis-opacity));
  }
}
</style>
