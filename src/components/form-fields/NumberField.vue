<template>
  <div>
    <v-label v-if="fieldLabel" class="mb-2">
      {{ fieldLabel }}
      <span v-if="field.is_required" class="text-error">*</span>
    </v-label>
    <v-text-field
      :model-value="modelValue"
      :label="fieldLabel ? undefined : (field.field_label || field.field_key)"
      :placeholder="field.placeholder"
      :hint="field.help_text"
      :required="field.is_required"
      :rules="validationRules"
      :disabled="field.is_readonly || disabled"
      :readonly="field.is_readonly"
      type="number"
      :variant="variant"
      :density="density"
      :suffix="unit"
      :step="step"
      :min="min"
      :max="max"
      :bg-color="field.is_readonly ? 'grey-lighten-4' : undefined"
      @update:model-value="handleUpdate"
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
    type: [String, Number],
    default: null,
  },
  disabled: {
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

const unit = computed(() => {
  return fieldConfig.value.unit || ''
})

const step = computed(() => {
  return fieldConfig.value.step || 1
})

const min = computed(() => {
  return fieldConfig.value.min ?? props.field.validation_rules?.min ?? undefined
})

const max = computed(() => {
  return fieldConfig.value.max ?? props.field.validation_rules?.max ?? undefined
})

function handleUpdate (value) {
  // 轉換為數字
  const numValue = value === '' || value === null ? null : Number(value)
  emit('update:modelValue', numValue)
}

const validationRules = computed(() => {
  const rules = []
  
  if (props.field.is_required) {
    rules.push((v) => {
      if (v === null || v === undefined || v === '') {
        return '此欄位為必填'
      }
      return true
    })
  }

  rules.push((v) => {
    if (v !== null && v !== undefined && v !== '') {
      if (isNaN(Number(v))) {
        return '請輸入有效的數字'
      }
    }
    return true
  })

  if (min.value !== undefined) {
    rules.push((v) => {
      if (v !== null && v !== undefined && v !== '') {
        if (Number(v) < min.value) {
          return `數值不能小於 ${min.value}`
        }
      }
      return true
    })
  }

  if (max.value !== undefined) {
    rules.push((v) => {
      if (v !== null && v !== undefined && v !== '') {
        if (Number(v) > max.value) {
          return `數值不能大於 ${max.value}`
        }
      }
      return true
    })
  }

  return rules
})
</script>
