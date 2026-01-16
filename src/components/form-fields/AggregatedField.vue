<template>
  <div>
    <v-label v-if="fieldLabel" class="mb-2">
      {{ fieldLabel }}
      <span v-if="field.is_required" class="text-error">*</span>
    </v-label>
    <v-text-field
      :model-value="computedValue"
      :label="fieldLabel ? undefined : (field.field_label || field.field_key)"
      :placeholder="field.placeholder"
      :hint="field.help_text || '此欄位由其他欄位自動聚合生成'"
      :required="field.is_required"
      :rules="validationRules"
      :disabled="true"
      :readonly="true"
      :variant="variant"
      :density="density"
      bg-color="grey-lighten-4"
    />
  </div>
</template>

<script setup>
  import { computed, watch } from 'vue'

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
    formValues: {
      type: Object,
      default: () => ({}),
    },
  })

  const emit = defineEmits(['update:modelValue'])

  const fieldLabel = computed(() => {
    return props.field.field_label || props.field.field_key
  })

  const fieldConfig = computed(() => {
    return props.field.field_config || {}
  })

  const template = computed(() => {
    return fieldConfig.value.template || ''
  })

  // 計算聚合值
  const computedValue = computed(() => {
    if (!template.value) {
      return props.modelValue || ''
    }

    try {
      const result = generateAggregatedValue(template.value, props.formValues || {})
      return result
    } catch (error) {
      console.error('聚合資料生成失敗', error)
      return props.modelValue || ''
    }
  })

  // 從值中提取實際的字符串值
  function extractValue (value) {
    if (value === null || value === undefined || value === '') {
      return ''
    }

    // 如果是陣列
    if (Array.isArray(value)) {
      // 過濾掉 null/undefined/空值，然後取第一個有效值
      const validValues = value.filter(v => v !== null && v !== undefined && v !== '')
      if (validValues.length === 0) {
        return ''
      }
      // 遞迴處理第一個有效值
      return extractValue(validValues[0])
    }

    // 如果是物件，嘗試提取 value 屬性
    if (typeof value === 'object') {
      // 常見的屬性名稱
      const valueKeys = ['value', 'id', 'key', 'code']
      for (const key of valueKeys) {
        if (value[key] !== undefined && value[key] !== null && value[key] !== '') {
          return String(value[key])
        }
      }
      // 如果沒有找到，嘗試使用第一個可用的屬性
      const keys = Object.keys(value)
      if (keys.length > 0) {
        const firstValue = value[keys[0]]
        if (firstValue !== null && firstValue !== undefined && firstValue !== '') {
          return String(firstValue)
        }
      }
      return ''
    }

    // 其他情況直接轉為字串
    return String(value)
  }

  // 生成聚合值
  function generateAggregatedValue (templateStr, values) {
    if (!templateStr) {
      return ''
    }

    let result = templateStr

    // 處理欄位值替換 {#field_key}
    result = result.replace(/\{#(\w+)\}/g, (match, fieldKey) => {
      const value = values[fieldKey]
      return extractValue(value)
    })

    // 處理系統計數序號 {@sn#n}
    result = result.replace(/\{@sn#(\d+)\}/g, (match, digits) => {
      const digitCount = parseInt(digits, 10)
      // 從 field_config 讀取計數器值，如果沒有則使用 0
      const counterValue = fieldConfig.value.counterValue || 0
      return String(counterValue).padStart(digitCount, '0')
    })

    return result
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

  // 監聽 computedValue 變化，同步到 modelValue
  watch(() => computedValue.value, (newValue) => {
    if (newValue !== props.modelValue) {
      emit('update:modelValue', newValue)
    }
  }, { immediate: true })
</script>

<style scoped lang="scss">
// 聚合資料欄位樣式
</style>
