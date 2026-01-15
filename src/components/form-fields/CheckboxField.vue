<template>
  <div>
    <!-- 顯示欄位標籤（包含必填星號） -->
    <v-label v-if="fieldLabel" class="mb-2">
      {{ fieldLabel }}
      <span v-if="field.is_required" class="text-error">*</span>
    </v-label>

    <v-chip-group
      v-model="selectedOptions"
      :disabled="field.is_readonly || disabled || loading"
      multiple
      selected-class="text-primary"
    >
      <v-chip
        v-for="option in chipOptions"
        :key="getChipValue(option)"
        filter
        :value="getChipValue(option)"
        variant="outlined"
      >
        {{ getChipTitle(option) }}
      </v-chip>
    </v-chip-group>

    <div v-if="field.help_text" class="text-caption text-medium-emphasis mt-1">
      {{ field.help_text }}
    </div>

    <div v-if="showValidationError" class="text-error text-caption mt-1">
      {{ validationError }}
    </div>
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
  })

  const emit = defineEmits(['update:modelValue'])

  const fieldLabel = computed(() => {
    return props.field.field_label || props.field.field_key
  })

  const fieldConfig = computed(() => {
    return props.field.field_config || {}
  })

  // 取得選項列表
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

  // Chip Group 使用的選項
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
  const selectedOptions = computed({
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
</script>

<style scoped lang="scss">
.v-label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  color: rgba(var(--v-theme-on-surface), var(--v-medium-emphasis-opacity));
}
</style>
