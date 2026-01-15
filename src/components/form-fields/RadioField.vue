<template>
  <div>
    <div v-if="field.field_label" class="mb-2">
      <span :class="{ 'text-error': field.is_required }">
        {{ fieldLabel }}
        <span v-if="field.is_required" class="text-error">*</span>
      </span>
    </div>
    
    <v-radio-group
      :model-value="modelValue"
      :disabled="field.is_readonly || disabled"
      :readonly="field.is_readonly"
      :density="density"
      @update:model-value="$emit('update:modelValue', $event)"
    >
      <v-radio
        v-for="option in items"
        :key="option.value"
        :label="option.title || option.label || option.value"
        :value="option.value"
      />
    </v-radio-group>
    
    <div v-if="field.help_text" class="text-caption text-medium-emphasis mt-1">
      {{ field.help_text }}
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
    type: [String, Number],
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

const fieldConfig = computed(() => {
  return props.field.field_config || {}
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
</script>
