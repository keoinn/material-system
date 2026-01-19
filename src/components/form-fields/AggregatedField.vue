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
  import { computed, onMounted, ref, watch } from 'vue'
  import { codeCountersService } from '@/api/services/codeCounters'

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

  // 計數器值（從資料庫獲取）
  const counterValue = ref(0)
  const counterLoading = ref(false)

  // 生成計數器 key
  function generateCounterKey () {
    // 優先使用 field_config 中配置的 counterKey
    if (fieldConfig.value.counterKey) {
      return fieldConfig.value.counterKey
    }

    // 如果模板中包含 {@sn#n}，嘗試從模板中的其他欄位值構建 key
    // 例如：如果模板是 "{#type}.{#subtype}.{#detail}.{@sn#5}"
    // 可以構建 key 為 "{type值}{subtype值}.{detail值}"
    const templateStr = template.value
    if (templateStr) {
      // 提取所有 {#field_key} 的欄位
      const fieldKeyMatches = templateStr.matchAll(/\{#(\w+)\}/g)
      const fieldKeys = Array.from(fieldKeyMatches, m => m[1])
      
      // 如果有多個欄位，嘗試構建 key
      if (fieldKeys.length > 0) {
        const keyParts = []
        for (const fieldKey of fieldKeys) {
          const value = extractValue(props.formValues[fieldKey] || '')
          if (value) {
            keyParts.push(value)
          }
        }
        
        // 如果所有欄位都有值，構建 key（格式：{值1}{值2}.{值3}）
        if (keyParts.length === fieldKeys.length && keyParts.length >= 2) {
          // 前兩個值合併，後面的值用點分隔
          const prefix = keyParts.slice(0, 2).join('')
          const suffix = keyParts.slice(2).join('.')
          return suffix ? `${prefix}.${suffix}` : prefix
        } else if (keyParts.length === 1) {
          // 只有一個值，使用欄位 key 作為後綴
          return `${keyParts[0]}.${props.field.field_key}`
        }
      }
    }

    // 預設使用欄位 key
    return props.field.field_key || 'default'
  }

  // 載入計數器值
  async function loadCounterValue () {
    const counterKey = generateCounterKey()
    if (!counterKey) {
      counterValue.value = 1 // 預設從 1 開始
      return
    }

    counterLoading.value = true
    try {
      const value = await codeCountersService.getCounter(counterKey)
      // 確保計數器值至少為 1（起始值）
      counterValue.value = value && value > 0 ? value : 1
    } catch (error) {
      console.error('載入計數器值失敗', error)
      counterValue.value = 1 // 錯誤時也從 1 開始
    } finally {
      counterLoading.value = false
    }
  }

  // 計算聚合值
  const computedValue = computed(() => {
    if (!template.value) {
      return props.modelValue || ''
    }

    try {
      const result = generateAggregatedValue(template.value, props.formValues || {}, counterValue.value)
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
  function generateAggregatedValue (templateStr, values, currentCounterValue) {
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
      // 使用從資料庫獲取的計數器值
      const value = currentCounterValue || 0
      return String(value).padStart(digitCount, '0')
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

  // 監聽 formValues 變化，重新載入計數器（當計數器 key 依賴於其他欄位值時）
  watch(() => {
    // 生成一個依賴於 formValues 的 key，用於觸發重新載入
    const counterKey = generateCounterKey()
    return counterKey
  }, async () => {
    await loadCounterValue()
  }, { immediate: false })

  // 組件掛載時載入計數器
  onMounted(() => {
    loadCounterValue()
  })
</script>

<style scoped lang="scss">
// 聚合資料欄位樣式
</style>
