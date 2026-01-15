<template>
  <div>
    <v-label v-if="fieldLabel" class="mb-2">
      {{ fieldLabel }}
      <span v-if="field.is_required" class="text-error">*</span>
    </v-label>
    <v-text-field
      :model-value="displayValue"
      :label="fieldLabel ? undefined : (field.field_label || field.field_key)"
      :placeholder="field.placeholder"
      :hint="field.help_text"
      :required="field.is_required"
      :rules="validationRules"
      :disabled="field.is_readonly || disabled"
      :readonly="field.is_readonly"
      :variant="variant"
      :density="density"
      :bg-color="field.is_readonly ? 'grey-lighten-4' : undefined"
      type="datetime-local"
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
    type: [String, Date],
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

const displayValue = computed(() => {
  if (!props.modelValue) {
    return null
  }
  
  if (props.modelValue instanceof Date) {
    // 轉換為 datetime-local 格式 (YYYY-MM-DDTHH:mm)
    const year = props.modelValue.getFullYear()
    const month = String(props.modelValue.getMonth() + 1).padStart(2, '0')
    const day = String(props.modelValue.getDate()).padStart(2, '0')
    const hours = String(props.modelValue.getHours()).padStart(2, '0')
    const minutes = String(props.modelValue.getMinutes()).padStart(2, '0')
    return `${year}-${month}-${day}T${hours}:${minutes}`
  }
  
  if (typeof props.modelValue === 'string') {
    // 如果是 ISO 格式，轉換為 datetime-local 格式
    if (props.modelValue.includes('T')) {
      return props.modelValue.slice(0, 16) // YYYY-MM-DDTHH:mm
    }
    return props.modelValue
  }
  
  return props.modelValue
})

function handleUpdate (value) {
  if (!value || value === '') {
    emit('update:modelValue', null)
    return
  }
  
  // 轉換為 ISO 格式
  const date = new Date(value)
  emit('update:modelValue', date.toISOString())
}

const validationRules = computed(() => {
  const rules = []
  
  if (props.field.is_required) {
    rules.push((v) => {
      if (!v || v === '') {
        return '此欄位為必填'
      }
      return true
    })
  }

  return rules
})
</script>
