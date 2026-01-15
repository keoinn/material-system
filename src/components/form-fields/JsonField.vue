<template>
  <div>
    <v-textarea
      :model-value="displayValue"
      :label="fieldLabel"
      :placeholder="field.placeholder"
      :hint="field.help_text"
      :required="field.is_required"
      :rules="validationRules"
      :disabled="field.is_readonly || disabled"
      :readonly="field.is_readonly"
      :variant="variant"
      :density="density"
      :rows="rows"
      :auto-grow="autoGrow"
      :bg-color="field.is_readonly ? 'grey-lighten-4' : undefined"
      @update:model-value="handleUpdate"
    />
    <div v-if="jsonError" class="text-error text-caption mt-1">
      {{ jsonError }}
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
    type: [Object, Array, String],
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
  rows: {
    type: Number,
    default: 5,
  },
  autoGrow: {
    type: Boolean,
    default: true,
  },
})

const emit = defineEmits(['update:modelValue'])

const fieldLabel = computed(() => {
  return props.field.field_label || props.field.field_key
})

const jsonError = ref('')

const displayValue = computed(() => {
  if (!props.modelValue) {
    return ''
  }
  
  if (typeof props.modelValue === 'string') {
    return props.modelValue
  }
  
  try {
    return JSON.stringify(props.modelValue, null, 2)
  } catch (error) {
    jsonError.value = '無法序列化 JSON'
    return String(props.modelValue)
  }
})

function handleUpdate (value) {
  if (!value || value.trim() === '') {
    emit('update:modelValue', null)
    jsonError.value = ''
    return
  }
  
  try {
    const parsed = JSON.parse(value)
    emit('update:modelValue', parsed)
    jsonError.value = ''
  } catch (error) {
    jsonError.value = '無效的 JSON 格式'
    // 仍然更新值，讓用戶可以繼續編輯
    emit('update:modelValue', value)
  }
}

const validationRules = computed(() => {
  const rules = []
  
  if (props.field.is_required) {
    rules.push((v) => {
      if (!v || v.trim() === '') {
        return '此欄位為必填'
      }
      return true
    })
  }

  rules.push((v) => {
    if (v && v.trim() !== '') {
      try {
        JSON.parse(v)
        return true
      } catch (error) {
        return '請輸入有效的 JSON 格式'
      }
    }
    return true
  })

  return rules
})

// 監聽 modelValue 變化清除錯誤
watch(() => props.modelValue, () => {
  if (jsonError.value) {
    jsonError.value = ''
  }
})
</script>
