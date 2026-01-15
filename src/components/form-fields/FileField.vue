<template>
  <div>
    <v-file-input
      :model-value="fileInput"
      :label="fieldLabel"
      :placeholder="field.placeholder"
      :hint="field.help_text"
      :required="field.is_required"
      :rules="validationRules"
      :disabled="field.is_readonly || disabled"
      :readonly="field.is_readonly"
      :variant="variant"
      :density="density"
      :accept="accept"
      :multiple="multiple"
      :show-size="showSize"
      :bg-color="field.is_readonly ? 'grey-lighten-4' : undefined"
      @update:model-value="handleFileSelect"
    />
    
    <div v-if="currentFileUrl" class="mt-2">
      <v-chip
        color="primary"
        variant="outlined"
        closable
        @click:close="handleRemoveFile"
      >
        <v-icon start>mdi-file</v-icon>
        已上傳檔案
      </v-chip>
      <v-btn
        v-if="showPreview"
        class="ml-2"
        size="small"
        variant="text"
        @click="handlePreview"
      >
        預覽
      </v-btn>
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
    type: [String, File, Array],
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

const fieldConfig = computed(() => {
  return props.field.field_config || {}
})

const accept = computed(() => {
  return fieldConfig.value.accept || '*/*'
})

const multiple = computed(() => {
  return fieldConfig.value.multiple || false
})

const showSize = computed(() => {
  return fieldConfig.value.showSize !== false
})

const showPreview = computed(() => {
  return fieldConfig.value.showPreview !== false
})

const fileInput = ref(null)
const currentFileUrl = ref(null)

watch(() => props.modelValue, (newValue) => {
  if (typeof newValue === 'string') {
    currentFileUrl.value = newValue
    fileInput.value = null
  } else if (newValue instanceof File) {
    fileInput.value = newValue
    currentFileUrl.value = null
  } else {
    fileInput.value = null
    currentFileUrl.value = null
  }
}, { immediate: true })

async function handleFileSelect (files) {
  if (!files || (Array.isArray(files) && files.length === 0)) {
    emit('update:modelValue', null)
    return
  }

  // 這裡應該上傳檔案到伺服器
  // 目前先直接使用 File 物件，實際使用時需要上傳並取得 URL
  if (multiple.value && Array.isArray(files)) {
    // 多檔案上傳
    const fileUrls = await Promise.all(files.map(file => uploadFile(file)))
    emit('update:modelValue', fileUrls)
  } else {
    const file = Array.isArray(files) ? files[0] : files
    const fileUrl = await uploadFile(file)
    emit('update:modelValue', fileUrl)
  }
}

async function uploadFile (file) {
  // TODO: 實作檔案上傳邏輯
  // 這裡應該呼叫檔案上傳 API
  // 目前先返回一個臨時 URL
  return URL.createObjectURL(file)
}

function handleRemoveFile () {
  currentFileUrl.value = null
  fileInput.value = null
  emit('update:modelValue', null)
}

function handlePreview () {
  if (currentFileUrl.value) {
    window.open(currentFileUrl.value, '_blank')
  }
}

const validationRules = computed(() => {
  const rules = []
  
  if (props.field.is_required) {
    rules.push((v) => {
      if (!v || (Array.isArray(v) && v.length === 0)) {
        return '此欄位為必填'
      }
      return true
    })
  }

  if (fieldConfig.value.maxSize) {
    rules.push((v) => {
      if (v instanceof File) {
        if (v.size > fieldConfig.value.maxSize) {
          return `檔案大小不能超過 ${formatFileSize(fieldConfig.value.maxSize)}`
        }
      }
      return true
    })
  }

  if (fieldConfig.value.allowedTypes && Array.isArray(fieldConfig.value.allowedTypes)) {
    rules.push((v) => {
      if (v instanceof File) {
        const fileType = v.type || ''
        const isValid = fieldConfig.value.allowedTypes.some(type => 
          fileType.includes(type) || v.name.endsWith(`.${type}`)
        )
        if (!isValid) {
          return `不支援的檔案類型，允許的類型：${fieldConfig.value.allowedTypes.join(', ')}`
        }
      }
      return true
    })
  }

  return rules
})

function formatFileSize (bytes) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}
</script>
