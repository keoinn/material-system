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
      type="date"
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
    return props.modelValue.toISOString().split('T')[0]
  }
  
  if (typeof props.modelValue === 'string') {
    // 如果是 ISO 格式，轉換為 YYYY-MM-DD
    if (props.modelValue.includes('T')) {
      return props.modelValue.split('T')[0]
    }
    return props.modelValue
  }
  
  return props.modelValue
})

function handleUpdate (value) {
  emit('update:modelValue', value || null)
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
