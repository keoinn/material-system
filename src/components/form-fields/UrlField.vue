<template>
  <div>
    <v-label v-if="fieldLabel && !isReadonlyDisplay" class="mb-2">
      {{ fieldLabel }}
      <span v-if="field.is_required" class="text-error">*</span>
    </v-label>

    <div v-if="isReadonlyDisplay">
      <div v-if="fieldLabel" class="text-caption text-medium-emphasis mb-1">
        {{ fieldLabel }}
      </div>
      <a
        v-if="hasValue"
        class="url-field-link"
        :href="normalizedUrl"
        :rel="openInNewTab ? 'noopener noreferrer' : undefined"
        :target="openInNewTab ? '_blank' : undefined"
      >
        {{ displayUrl }}
        <v-icon
          v-if="openInNewTab"
          class="ml-1"
          size="small"
        >
          mdi-open-in-new
        </v-icon>
      </a>
      <span v-else class="text-medium-emphasis">-</span>
    </div>

    <v-text-field
      v-else
      :model-value="modelValue"
      :label="fieldLabel ? undefined : (field.field_label || field.field_key)"
      :placeholder="field.placeholder || 'https://'"
      :hint="field.help_text"
      :required="field.is_required"
      :rules="validationRules"
      :disabled="disabled"
      :maxlength="field.max_length"
      :counter="field.max_length ? true : false"
      :variant="variant"
      :density="density"
      type="url"
      @update:model-value="$emit('update:modelValue', $event)"
    >
      <template #append-inner>
        <v-btn
          v-if="hasValue"
          icon
          size="x-small"
          title="開啟連結"
          variant="text"
          @click.stop="openLink"
        >
          <v-icon>mdi-open-in-new</v-icon>
        </v-btn>
      </template>
    </v-text-field>
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

  const fieldConfig = computed(() => props.field.field_config || {})

  const fieldLabel = computed(() => {
    return props.field.field_label || props.field.field_key
  })

  const isReadonlyDisplay = computed(() => {
    return props.field.is_readonly || props.disabled
  })

  const openInNewTab = computed(() => {
    return fieldConfig.value.openInNewTab !== false
  })

  const allowedProtocols = computed(() => {
    const protocols = fieldConfig.value.allowedProtocols
    if (Array.isArray(protocols) && protocols.length > 0) {
      return protocols
    }
    return ['http', 'https', 'mailto']
  })

  const rawValue = computed(() => {
    if (props.modelValue === null || props.modelValue === undefined) {
      return ''
    }
    return String(props.modelValue).trim()
  })

  const hasValue = computed(() => rawValue.value.length > 0)

  const normalizedUrl = computed(() => {
    return normalizeUrl(rawValue.value)
  })

  const displayUrl = computed(() => {
    return rawValue.value
  })

  function normalizeUrl (value) {
    const trimmed = (value || '').trim()
    if (!trimmed) {
      return ''
    }
    if (/^[a-z][a-z0-9+.-]*:/i.test(trimmed)) {
      return trimmed
    }
    return `https://${trimmed}`
  }

  function isAllowedUrl (value) {
    const normalized = normalizeUrl(value)
    if (!normalized) {
      return true
    }

    try {
      const url = new URL(normalized)
      const protocol = url.protocol.replace(':', '')
      return allowedProtocols.value.includes(protocol)
    } catch {
      return false
    }
  }

  function openLink () {
    if (!normalizedUrl.value) {
      return
    }
    window.open(normalizedUrl.value, openInNewTab.value ? '_blank' : '_self', 'noopener,noreferrer')
  }

  const validationRules = computed(() => {
    const rules = []

    if (props.field.is_required) {
      rules.push(v => {
        if (v === null || v === undefined || String(v).trim() === '') {
          return '此欄位為必填'
        }
        return true
      })
    }

    rules.push(v => {
      if (v === null || v === undefined || String(v).trim() === '') {
        return true
      }
      if (!isAllowedUrl(String(v))) {
        return `請輸入有效的網址（允許：${allowedProtocols.value.join('、')}）`
      }
      return true
    })

    if (props.field.max_length) {
      rules.push(v => {
        if (v && String(v).length > props.field.max_length) {
          return `長度不能超過 ${props.field.max_length} 個字元`
        }
        return true
      })
    }

    return rules
  })
</script>

<style scoped>
.url-field-link {
  color: rgb(var(--v-theme-primary));
  text-decoration: none;
  word-break: break-all;
}

.url-field-link:hover {
  text-decoration: underline;
}
</style>
