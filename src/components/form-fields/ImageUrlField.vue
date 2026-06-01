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
      <div v-if="hasValue" class="image-url-field-display">
        <component
          :is="clickable ? 'a' : 'div'"
          class="image-url-field-frame"
          :class="{ 'image-url-field-frame--clickable': clickable }"
          :href="clickable ? normalizedUrl : undefined"
          :rel="clickable && openInNewTab ? 'noopener noreferrer' : undefined"
          :style="frameStyle"
          :target="clickable && openInNewTab ? '_blank' : undefined"
        >
          <img
            v-if="!imageLoadFailed"
            :alt="imageAlt"
            class="image-url-field-img"
            :src="normalizedUrl"
            :style="imageStyle"
            @error="imageLoadFailed = true"
            @load="imageLoadFailed = false"
          >
          <div v-else class="image-url-field-fallback">
            <v-icon class="mb-1" color="medium-emphasis">mdi-image-off-outline</v-icon>
            <span class="text-caption text-medium-emphasis">圖片無法載入</span>
            <a
              v-if="clickable"
              class="image-url-field-link mt-1"
              :href="normalizedUrl"
              :rel="openInNewTab ? 'noopener noreferrer' : undefined"
              :target="openInNewTab ? '_blank' : undefined"
            >
              開啟連結
            </a>
          </div>
        </component>
        <div v-if="showUrlText" class="text-caption text-medium-emphasis mt-1 image-url-field-text">
          {{ displayUrl }}
        </div>
      </div>
      <span v-else class="text-medium-emphasis">-</span>
    </div>

    <div v-else>
      <v-text-field
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
        @update:model-value="onInput"
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

      <div v-if="hasValue && showPreview" class="image-url-field-preview mt-2">
        <div class="text-caption text-medium-emphasis mb-1">預覽</div>
        <div
          class="image-url-field-frame"
          :style="frameStyle"
        >
          <img
            v-if="!imageLoadFailed"
            :alt="imageAlt"
            class="image-url-field-img"
            :src="normalizedUrl"
            :style="imageStyle"
            @error="imageLoadFailed = true"
            @load="imageLoadFailed = false"
          >
          <div v-else class="image-url-field-fallback">
            <v-icon class="mb-1" color="medium-emphasis">mdi-image-off-outline</v-icon>
            <span class="text-caption text-medium-emphasis">無法載入圖片，請確認網址是否為有效圖片連結</span>
          </div>
        </div>
      </div>
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

  const imageLoadFailed = ref(false)

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

  const clickable = computed(() => {
    return fieldConfig.value.clickable !== false
  })

  const showPreview = computed(() => {
    return fieldConfig.value.showPreview !== false
  })

  const showUrlText = computed(() => {
    return fieldConfig.value.showUrlText === true
  })

  const allowedProtocols = computed(() => {
    const protocols = fieldConfig.value.allowedProtocols
    if (Array.isArray(protocols) && protocols.length > 0) {
      return protocols
    }
    return ['http', 'https']
  })

  const maxHeight = computed(() => {
    const value = fieldConfig.value.maxHeight
    if (value === null || value === undefined || value === '') {
      return 200
    }
    return value
  })

  const maxWidth = computed(() => {
    const value = fieldConfig.value.maxWidth
    if (value === null || value === undefined || value === '') {
      return '100%'
    }
    return value
  })

  const objectFit = computed(() => {
    return fieldConfig.value.objectFit || 'contain'
  })

  const imageAlt = computed(() => {
    return fieldConfig.value.alt || fieldLabel.value || '外部圖片'
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

  const frameStyle = computed(() => {
    return {
      maxHeight: typeof maxHeight.value === 'number' ? `${maxHeight.value}px` : maxHeight.value,
      maxWidth: typeof maxWidth.value === 'number' ? `${maxWidth.value}px` : maxWidth.value,
    }
  })

  const imageStyle = computed(() => {
    return {
      maxHeight: typeof maxHeight.value === 'number' ? `${maxHeight.value}px` : maxHeight.value,
      maxWidth: typeof maxWidth.value === 'number' ? `${maxWidth.value}px` : maxWidth.value,
      objectFit: objectFit.value,
    }
  })

  watch(normalizedUrl, () => {
    imageLoadFailed.value = false
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

  function onInput (value) {
    imageLoadFailed.value = false
    emit('update:modelValue', value)
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
        return `請輸入有效的圖片網址（允許：${allowedProtocols.value.join('、')}）`
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
.image-url-field-display,
.image-url-field-preview {
  width: 100%;
}

.image-url-field-frame {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: fit-content;
  max-width: 100%;
  border: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
  border-radius: 4px;
  background: rgba(var(--v-theme-on-surface), 0.03);
  overflow: hidden;
}

.image-url-field-frame--clickable {
  text-decoration: none;
  cursor: pointer;
}

.image-url-field-frame--clickable:hover {
  border-color: rgb(var(--v-theme-primary));
}

.image-url-field-img {
  display: block;
  width: auto;
  height: auto;
}

.image-url-field-fallback {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 80px;
  padding: 12px 16px;
  text-align: center;
}

.image-url-field-link {
  color: rgb(var(--v-theme-primary));
  text-decoration: none;
}

.image-url-field-link:hover {
  text-decoration: underline;
}

.image-url-field-text {
  word-break: break-all;
}
</style>
