<template>
  <div>
    <v-label v-if="fieldLabel" class="mb-2">
      {{ fieldLabel }}
      <span v-if="field.is_required" class="text-error">*</span>
    </v-label>
    <v-select
      :bg-color="field.is_readonly ? 'grey-lighten-4' : undefined"
      :density="density"
      :disabled="field.is_readonly || disabled || loading"
      :hint="field.help_text"
      :item-title="itemTitle"
      :item-value="itemValue"
      :items="items"
      :label="fieldLabel ? undefined : (field.field_label || field.field_key)"
      :loading="loading"
      :model-value="modelValue"
      :placeholder="field.placeholder || '請選擇'"
      :readonly="field.is_readonly"
      :required="field.is_required"
      :return-object="returnObject"
      :rules="validationRules"
      :variant="variant"
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
      type: [String, Number, Object],
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

  const items = computed(() => {
    if (props.options && props.options.length > 0) {
      return props.options
    }

    // 如果沒有提供選項，嘗試從 field_config 取得
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

  const itemTitle = computed(() => {
    return fieldConfig.value.itemTitle || 'title'
  })

  const itemValue = computed(() => {
    return fieldConfig.value.itemValue || 'value'
  })

  const returnObject = computed(() => {
    return fieldConfig.value.returnObject || false
  })

  function handleUpdate (value) {
    if (returnObject.value && typeof value === 'object') {
      emit('update:modelValue', value[itemValue.value])
    } else {
      emit('update:modelValue', value)
    }
  }

  const validationRules = computed(() => {
    const rules = []

    if (props.field.is_required) {
      rules.push(v => {
        if (v === null || v === undefined || v === '') {
          return '此欄位為必填'
        }
        return true
      })
    }

    return rules
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
