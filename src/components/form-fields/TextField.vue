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
      :maxlength="field.max_length"
      :counter="field.max_length ? true : false"
      :variant="variant"
      :density="density"
      :bg-color="field.is_readonly ? 'grey-lighten-4' : undefined"
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

defineEmits(['update:modelValue'])

const fieldLabel = computed(() => {
  return props.field.field_label || props.field.field_key
})

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

  if (props.field.max_length) {
    rules.push((v) => {
      if (v && v.length > props.field.max_length) {
        return `長度不能超過 ${props.field.max_length} 個字元`
      }
      return true
    })
  }

  // 檢查驗證規則
  if (props.field.validation_rules) {
    const validationRules = props.field.validation_rules
    
    if (validationRules.pattern) {
      const regex = new RegExp(validationRules.pattern)
      rules.push((v) => {
        if (v && !regex.test(v)) {
          return validationRules.patternMessage || '格式不正確'
        }
        return true
      })
    }

    if (validationRules.minLength) {
      rules.push((v) => {
        if (v && v.length < validationRules.minLength) {
          return `長度不能少於 ${validationRules.minLength} 個字元`
        }
        return true
      })
    }
  }

  return rules
})
</script>
