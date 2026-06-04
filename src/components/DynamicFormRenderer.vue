<template>
  <v-card v-if="form">
    <v-card-title v-if="showTitle" class="system-header">
      <div>
        <h2 class="ma-0">{{ form.form_name || form.form_name_en }}</h2>
        <div
          v-if="form.form_code"
          class="text-caption text-white mt-1 form-renderer-header-form-code"
        >
          表單代碼：{{ form.form_code }}
        </div>
      </div>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-progress-linear
        v-if="loading"
        class="mb-4"
        color="primary"
        indeterminate
      />

      <v-form ref="formRef" v-model="valid">
        <div
          v-if="hasCollapsibleSections"
          class="d-flex justify-end mb-2 ga-2"
        >
          <v-btn
            color="primary"
            size="small"
            variant="text"
            @click="expandAllSections"
          >
            全部展開
          </v-btn>
          <v-btn
            color="primary"
            size="small"
            variant="text"
            @click="collapseAllSections"
          >
            全部摺疊
          </v-btn>
        </div>

        <v-expansion-panels
          v-model="expandedGroups"
          class="form-group-panels"
          multiple
        >
          <template v-for="(group, groupName) in groupedFields" :key="groupName">
            <v-expansion-panel
              v-if="hasGroupContent(group, groupName)"
              :value="groupName"
              class="form-section-panel"
            >
              <v-expansion-panel-title class="form-section-title">
                {{ groupName }}
              </v-expansion-panel-title>
              <v-expansion-panel-text class="form-section-content">
                <v-expansion-panels
                  v-if="hasNamedSubGroups(groupName, group)"
                  :model-value="getExpandedSubGroups(groupName)"
                  class="subgroup-panels"
                  multiple
                  @update:model-value="setExpandedSubGroups(groupName, $event)"
                >
                  <v-expansion-panel
                    v-for="(subGroup, subGroupName) in getNamedSubGroupsForDisplay(groupName, group)"
                    :key="subGroupName"
                    :value="subGroupName"
                    class="subgroup-panel"
                  >
                    <v-expansion-panel-title class="subgroup-title">
                      {{ subGroupName }}
                    </v-expansion-panel-title>
                    <v-expansion-panel-text class="subgroup-content">
                      <DynamicFormFieldsRow :fields="subGroup" />
                    </v-expansion-panel-text>
                  </v-expansion-panel>
                </v-expansion-panels>

                <DynamicFormFieldsRow
                  v-if="getUngroupedFieldsInGroup(groupName, group).length > 0"
                  :fields="getUngroupedFieldsInGroup(groupName, group)"
                />
              </v-expansion-panel-text>
            </v-expansion-panel>
          </template>
        </v-expansion-panels>

        <v-expansion-panels
          v-if="ungroupedFields.length > 0"
          v-model="expandedUngrouped"
          class="form-group-panels mt-4"
          multiple
        >
          <v-expansion-panel
            class="form-section-panel"
            value="_ungrouped"
          >
            <v-expansion-panel-title class="form-section-title">
              未分組欄位
            </v-expansion-panel-title>
            <v-expansion-panel-text class="form-section-content">
              <DynamicFormFieldsRow :fields="ungroupedFields" />
            </v-expansion-panel-text>
          </v-expansion-panel>
        </v-expansion-panels>
      </v-form>
    </v-card-text>

    <v-card-actions v-if="showActions" class="pa-4">
      <v-spacer />
      <v-btn
        v-if="showCancel"
        color="grey"
        variant="outlined"
        @click="handleCancel"
      >
        {{ cancelText }}
      </v-btn>
      <v-btn
        color="primary"
        :disabled="!valid && validateOnSubmit"
        :loading="submitting"
        variant="flat"
        @click="handleSubmit"
      >
        {{ submitText }}
      </v-btn>
    </v-card-actions>
  </v-card>

  <v-card v-else-if="loading">
    <v-card-text>
      <v-progress-linear
        color="primary"
        indeterminate
      />
      <div class="text-center mt-4">載入表單中...</div>
    </v-card-text>
  </v-card>

  <v-card v-else>
    <v-card-text>
      <v-alert type="error" variant="tonal">
        無法載入表單定義
      </v-alert>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { computed, nextTick, onMounted, provide, reactive, ref, watch } from 'vue'
  import { formDataService } from '@/api/services/formData'
  import { formFieldsService } from '@/api/services/formFields'
  import { formsService } from '@/api/services/forms'
  import { optionWorkbooksService } from '@/api/services/optionWorkbooks'
  import DynamicFormFieldsRow from './DynamicFormFieldsRow.vue'
  import AggregatedField from './form-fields/AggregatedField.vue'
  import CascadingSelectField from './form-fields/CascadingSelectField.vue'
  import CheckboxField from './form-fields/CheckboxField.vue'
  import DateField from './form-fields/DateField.vue'
  import DatetimeField from './form-fields/DatetimeField.vue'
  import FileField from './form-fields/FileField.vue'
  import JsonField from './form-fields/JsonField.vue'
  import MultiselectField from './form-fields/MultiselectField.vue'
  import NumberField from './form-fields/NumberField.vue'
  import RadioField from './form-fields/RadioField.vue'
  import SelectField from './form-fields/SelectField.vue'
  import TextareaField from './form-fields/TextareaField.vue'
  import TextField from './form-fields/TextField.vue'
  import ImageUrlField from './form-fields/ImageUrlField.vue'
  import UrlField from './form-fields/UrlField.vue'

  const props = defineProps({
    // 表單 ID 或 form_code
    formId: {
      type: [String, Number],
      required: true,
    },
    // 記錄 ID（用於編輯模式）
    recordId: {
      type: [String, Number],
      default: null,
    },
    // 初始值
    initialValues: {
      type: Object,
      default: () => ({}),
    },
    // 是否顯示標題
    showTitle: {
      type: Boolean,
      default: true,
    },
    // 是否顯示操作按鈕
    showActions: {
      type: Boolean,
      default: true,
    },
    // 是否顯示取消按鈕
    showCancel: {
      type: Boolean,
      default: true,
    },
    // 提交按鈕文字
    submitText: {
      type: String,
      default: '提交',
    },
    // 取消按鈕文字
    cancelText: {
      type: String,
      default: '取消',
    },
    // 是否在提交時驗證
    validateOnSubmit: {
      type: Boolean,
      default: true,
    },
    // 是否自動載入資料
    autoLoad: {
      type: Boolean,
      default: true,
    },
    // 是否唯讀模式
    readonly: {
      type: Boolean,
      default: false,
    },
  })

  const emit = defineEmits(['submit', 'cancel', 'update:modelValue', 'field-update'])

  const formRef = ref(null)
  const valid = ref(false)
  const loading = ref(false)
  const submitting = ref(false)
  const form = ref(null)
  const fields = ref([])
  const formValues = reactive({})
  const fieldLoading = reactive({})
  const fieldOptions = reactive({}) // 儲存已載入的欄位選項
  const groupOrder = ref([]) // 群組順序
  const subGroups = ref(new Map()) // Map<groupName, Array<{name: string, order: number}>>
  const expandedGroups = ref([])
  const expandedSubGroups = reactive({})
  const expandedUngrouped = ref([])

  // 欄位組件映射
  const fieldComponents = {
    text: TextField,
    textarea: TextareaField,
    number: NumberField,
    select: SelectField,
    multiselect: MultiselectField,
    cascading_select: CascadingSelectField,
    checkbox: CheckboxField,
    radio: RadioField,
    date: DateField,
    datetime: DatetimeField,
    file: FileField,
    json: JsonField,
    url: UrlField,
    image_url: ImageUrlField,
    aggregated: AggregatedField,
  }

  // 按群組和子群組分類欄位（支援子群組和群組順序）
  const groupedFields = computed(() => {
    const groups = {}
    const ungrouped = []

    for (const field of fields.value) {
      if (field.field_group) {
        if (!groups[field.field_group]) {
          groups[field.field_group] = {
            subGroups: {}, // Map<subGroupName, Array<field>>
            ungrouped: [], // 沒有子群組的欄位
          }
        }

        if (field.sub_group) {
          // 屬於子群組的欄位
          if (!groups[field.field_group].subGroups[field.sub_group]) {
            groups[field.field_group].subGroups[field.sub_group] = []
          }
          groups[field.field_group].subGroups[field.sub_group].push(field)
        } else {
          // 不屬於任何子群組的欄位
          groups[field.field_group].ungrouped.push(field)
        }
      } else {
        ungrouped.push(field)
      }
    }

    // 按 display_order 排序每個群組內的欄位
    for (const groupName of Object.keys(groups)) {
      // 排序子群組內的欄位
      for (const subGroupName of Object.keys(groups[groupName].subGroups)) {
        groups[groupName].subGroups[subGroupName].sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
      }
      // 排序未分組到子群組的欄位
      groups[groupName].ungrouped.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    }

    ungrouped.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))

    // 按照 groupOrder 排序群組
    const orderedGroups = {}

    // 先添加有順序的群組
    for (const groupName of groupOrder.value) {
      if (groups[groupName]) {
        orderedGroups[groupName] = groups[groupName]
      }
    }

    // 再添加沒有順序的群組（新群組或未在順序列表中的群組）
    for (const groupName of Object.keys(groups)) {
      if (groupName !== '_ungrouped' && !groupOrder.value.includes(groupName)) {
        orderedGroups[groupName] = groups[groupName]
      }
    }

    // 最後添加未分組欄位
    if (ungrouped.length > 0) {
      orderedGroups._ungrouped = {
        subGroups: {},
        ungrouped: ungrouped,
      }
    }

    return orderedGroups
  })

  const ungroupedFields = computed(() => {
    return groupedFields.value._ungrouped?.ungrouped || []
  })

  // 取得指定群組的子群組列表（按順序）
  function getSubGroupsForGroup (groupName) {
    const subGroupsList = subGroups.value.get(groupName) || []
    return subGroupsList.toSorted((a, b) => (a.order || 0) - (b.order || 0))
  }

  // 取得用於顯示的子群組結構（包含子群組和未分組欄位）
  function getSubGroupsForDisplay (groupName, groupData) {
    const result = {}

    if (!groupData) {
      groupData = { subGroups: {}, ungrouped: [] }
    }

    // 確保 groupData.subGroups 存在
    if (!groupData.subGroups) {
      groupData.subGroups = {}
    }

    // 先添加有順序的子群組（即使沒有欄位也要顯示）
    const subGroupsList = getSubGroupsForGroup(groupName)
    if (subGroupsList && subGroupsList.length > 0) {
      for (const subGroup of subGroupsList) {
        // 即使子群組沒有欄位，也要顯示外框
        result[subGroup.name] = groupData.subGroups[subGroup.name] || []
      }
    }

    // 再添加沒有順序的子群組（新子群組或未在順序列表中的子群組）
    // 只添加有欄位的子群組（因為沒有順序的子群組通常是從欄位中提取的）
    if (groupData.subGroups) {
      for (const subGroupName of Object.keys(groupData.subGroups)) {
        // 如果子群組不在已處理的列表中，且有欄位，則添加
        if ((!subGroupsList || !subGroupsList.some(sg => sg.name === subGroupName)) && groupData.subGroups[subGroupName] && groupData.subGroups[subGroupName].length > 0) {
          result[subGroupName] = groupData.subGroups[subGroupName]
        }
      }
    }

    // 最後添加未分組到子群組的欄位
    if (groupData.ungrouped && groupData.ungrouped.length > 0) {
      result[''] = groupData.ungrouped // 空字符串表示未分組
    }

    return result
  }

  function hasGroupContent (group, groupName) {
    return groupName !== '_ungrouped'
      && ((group.subGroups && Object.keys(group.subGroups).length > 0)
        || (group.ungrouped && group.ungrouped.length > 0))
  }

  function getNamedSubGroupsForDisplay (groupName, groupData) {
    const result = {}
    for (const [subGroupName, fields] of Object.entries(getSubGroupsForDisplay(groupName, groupData))) {
      if (subGroupName) {
        result[subGroupName] = fields
      }
    }
    return result
  }

  function getUngroupedFieldsInGroup (groupName, groupData) {
    return getSubGroupsForDisplay(groupName, groupData)[''] || []
  }

  function hasNamedSubGroups (groupName, groupData) {
    return Object.keys(getNamedSubGroupsForDisplay(groupName, groupData)).length > 0
  }

  function getAllGroupNames () {
    return Object.keys(groupedFields.value).filter(groupName => hasGroupContent(groupedFields.value[groupName], groupName))
  }

  function getAllSubGroupNames (groupName) {
    const groupData = groupedFields.value[groupName]
    if (!groupData) {
      return []
    }
    return Object.keys(getNamedSubGroupsForDisplay(groupName, groupData))
  }

  function getExpandedSubGroups (groupName) {
    return expandedSubGroups[groupName] || []
  }

  function setExpandedSubGroups (groupName, value) {
    expandedSubGroups[groupName] = value
  }

  function initExpandedState () {
    expandedGroups.value = getAllGroupNames()
    for (const groupName of expandedGroups.value) {
      expandedSubGroups[groupName] = getAllSubGroupNames(groupName)
    }
    expandedUngrouped.value = ungroupedFields.value.length > 0 ? ['_ungrouped'] : []
  }

  function expandAllSections () {
    initExpandedState()
  }

  function collapseAllSections () {
    expandedGroups.value = []
    for (const groupName of Object.keys(expandedSubGroups)) {
      expandedSubGroups[groupName] = []
    }
    expandedUngrouped.value = []
  }

  const hasCollapsibleSections = computed(() => {
    return getAllGroupNames().length > 0 || ungroupedFields.value.length > 0
  })

  // 載入表單定義
  async function loadForm () {
    loading.value = true
    try {
      form.value = await formsService.getForm(props.formId, true)
      if (form.value && form.value.fields) {
        fields.value = form.value.fields

        // 載入群組順序（從 form_config 中）
        if (form.value.form_config && form.value.form_config.group_order && Array.isArray(form.value.form_config.group_order)) {
          groupOrder.value = [...form.value.form_config.group_order]
        } else {
          // 如果沒有順序設定，使用所有群組的預設順序（按字母排序）
          const allGroups = new Set()
          for (const field of fields.value) {
            if (field.field_group) {
              allGroups.add(field.field_group)
            }
          }
          groupOrder.value = Array.from(allGroups).toSorted()
        }

        // 載入子群組資料（從 form_config 中）
        if (form.value.form_config && form.value.form_config.sub_groups && Object.keys(form.value.form_config.sub_groups).length > 0) {
          subGroups.value = new Map(Object.entries(form.value.form_config.sub_groups).map(([groupName, subGroupsList]) => {
            return [groupName, subGroupsList.map((sg, index) => ({
              name: typeof sg === 'string' ? sg : sg.name,
              order: typeof sg === 'string' ? index : (sg.order || index),
            }))]
          }))
        } else {
          // 從欄位中提取子群組
          const extractedSubGroups = new Map()
          for (const field of fields.value) {
            if (field.field_group && field.sub_group) {
              if (!extractedSubGroups.has(field.field_group)) {
                extractedSubGroups.set(field.field_group, new Set())
              }
              extractedSubGroups.get(field.field_group).add(field.sub_group)
            }
          }
          // 轉換為 Map<groupName, Array<{name: string, order: number}>>
          for (const [groupName, subGroupSet] of extractedSubGroups.entries()) {
            subGroups.value.set(groupName, Array.from(subGroupSet).map((name, index) => ({
              name,
              order: index,
            })))
          }
        }

        // 預先載入所有需要動態載入的欄位選項
        await loadAllFieldOptions()

        // 初始化表單值
        initializeFormValues()
        initExpandedState()
      }
    } catch (error) {
      console.error('載入表單失敗', error)
    } finally {
      loading.value = false
    }
  }

  // 載入表單資料
  async function loadFormData () {
    if (!props.recordId) {
      return
    }

    try {
      // 載入表單資料，包含欄位定義以便正確處理選項活頁簿
      const data = await formDataService.getFormData(props.formId, props.recordId, {
        includeFieldDefinitions: true,
      })
      
      if (!data) {
        console.warn('載入表單資料為空', { formId: props.formId, recordId: props.recordId })
        return
      }
      
      // 先將所有值賦值給 formValues（即使 values 為空也要處理）
      if (data.values) {
        Object.assign(formValues, data.values)
      } else {
        console.warn('表單資料的 values 為空', { formId: props.formId, recordId: props.recordId, data })
        // 即使 values 為空，也要清空 formValues
        Object.keys(formValues).forEach(key => {
          delete formValues[key]
        })
      }
      
      // 如果欄位定義已載入，更新欄位定義並重新載入選項活頁簿選項
      if (data.fields && data.fields.length > 0) {
        // 更新欄位定義（使用從資料庫載入的最新欄位定義）
        fields.value = data.fields
        
        // 找到使用選項活頁簿的欄位
        const fieldsWithWorkbook = data.fields.filter(field => {
          const config = field.field_config || {}
          return config.option_workbook_key && (field.field_type === 'select' || field.field_type === 'multiselect')
        })
        
        // 重新載入使用選項活頁簿的欄位選項
        if (fieldsWithWorkbook.length > 0) {
          await Promise.all(fieldsWithWorkbook.map(async field => {
            const config = field.field_config || {}
            fieldLoading[field.field_key] = true
            try {
              const options = await loadWorkbookOptions(field, config)
              fieldOptions[field.field_key] = options
            } catch (error) {
              console.error(`載入欄位 ${field.field_key} 選項活頁簿失敗`, error)
              fieldOptions[field.field_key] = []
            } finally {
              fieldLoading[field.field_key] = false
            }
          }))
        }
      }
      
      // 如果欄位定義還沒有載入，使用現有的欄位定義重新載入選項活頁簿選項
      else if (fields.value && fields.value.length > 0) {
        const fieldsWithWorkbook = fields.value.filter(field => {
          const config = field.field_config || {}
          return config.option_workbook_key && (field.field_type === 'select' || field.field_type === 'multiselect')
        })
        
        if (fieldsWithWorkbook.length > 0) {
          await Promise.all(fieldsWithWorkbook.map(async field => {
            const config = field.field_config || {}
            // 如果選項還沒有載入，才載入
            if (!fieldOptions[field.field_key]) {
              fieldLoading[field.field_key] = true
              try {
                const options = await loadWorkbookOptions(field, config)
                fieldOptions[field.field_key] = options
              } catch (error) {
                console.error(`載入欄位 ${field.field_key} 選項活頁簿失敗`, error)
                fieldOptions[field.field_key] = []
              } finally {
                fieldLoading[field.field_key] = false
              }
            }
          }))
        }
      }

        // 對於 cascading select 欄位，需要將各個層級的值組合成陣列
      const currentFields = data.fields && data.fields.length > 0 ? data.fields : fields.value
      if (currentFields && currentFields.length > 0) {
        for (const field of currentFields) {
          if (field.field_type === 'cascading_select' && field.field_config?.levels) {
            const levels = field.field_config.levels
            const cascadingValues = []

            // 從 formValues 中讀取各個層級的值（使用層級的 field_key）
            for (const level of levels) {
              if (level && level.field_key) {
                const levelValue = formValues[level.field_key]
                cascadingValues.push(levelValue === undefined ? null : levelValue)
              } else {
                cascadingValues.push(null)
              }
            }

            // 將組合後的陣列存儲到主欄位的 field_key
            formValues[field.field_key] = cascadingValues
          }
        }
      }
    } catch (error) {
      console.error('載入表單資料失敗', error)
    }
  }

  // 初始化表單值
  function initializeFormValues () {
    for (const field of fields.value) {
      // 優先使用 initialValues
      let initialValue = props.initialValues[field.field_key]

      // 如果 initialValues 中沒有，則使用 default_value
      if (initialValue === undefined || initialValue === null) {
        initialValue = field.default_value
      }

      // 對於 checkbox 和 multiselect，確保值是陣列
      if (field.field_type === 'checkbox' || field.field_type === 'multiselect') {
        if (!Array.isArray(initialValue)) {
          initialValue = getDefaultValue(field)
        }
      } else if (field.field_type === 'cascading_select') {
        // 對於多層選單，確保值是陣列（每個元素對應一層的選擇值）
        if (!Array.isArray(initialValue)) {
          // 如果 default_value 是字串，嘗試解析為 JSON
          if (typeof initialValue === 'string' && initialValue.trim().startsWith('[')) {
            try {
              initialValue = JSON.parse(initialValue)
            } catch {
              initialValue = getDefaultValue(field)
            }
          } else {
            initialValue = getDefaultValue(field)
          }
        }
        // 確保陣列長度與層級數量一致
        const levelCount = field.field_config?.levels?.length || 1
        if (Array.isArray(initialValue) && initialValue.length < levelCount) {
          // 補齊到層級數量
          while (initialValue.length < levelCount) {
            initialValue.push(null)
          }
        }
        // 將各層級的值也存儲到 formValues 中，使用層級的 field_key
        if (field.field_config?.levels && Array.isArray(initialValue)) {
          for (let index = 0; index < field.field_config.levels.length; index++) {
            const level = field.field_config.levels[index]
            if (level && level.field_key && initialValue[index] !== undefined) {
              formValues[level.field_key] = initialValue[index]
            }
          }
        }
      } else {
        // 對於其他類型，如果沒有值，使用預設值
        if (initialValue === undefined || initialValue === null || initialValue === '') {
          initialValue = getDefaultValue(field)
        }
      }

      formValues[field.field_key] = initialValue
    }
  }

  // 取得預設值
  function getDefaultValue (field) {
    switch (field.field_type) {
      case 'number': {
        return null
      }
      case 'checkbox':
      case 'multiselect': {
        return []
      }
      case 'cascading_select': {
        // 多層選單的預設值是陣列，每個元素對應一層
        const levelCount = field.field_config?.levels?.length || 1
        return Array.from({ length: levelCount }, () => null)
      }
      case 'json': {
        return {}
      }
      default: {
        return null
      }
    }
  }

  // 取得欄位組件
  function getFieldComponent (fieldType) {
    return fieldComponents[fieldType] || TextField
  }

  // 取得帶有唯讀狀態的欄位（如果 props.readonly 為 true，則將欄位設為唯讀）
  function getFieldWithReadonly (field) {
    if (props.readonly) {
      return {
        ...field,
        is_readonly: true,
      }
    }
    return field
  }

  // 取得欄位選項
  function getFieldOptions (field) {
    const config = field.field_config || {}

    // 如果使用選項活頁簿，從已載入的選項中讀取
    if (config.option_workbook_key) {
      return fieldOptions[field.field_key] || []
    }

    // 如果有 options，直接使用
    if (config.options && Array.isArray(config.options)) {
      return config.options.map(opt => {
        if (typeof opt === 'string') {
          return { title: opt, value: opt }
        }
        return opt
      })
    }

    // 如果有 source，從已載入的選項中讀取
    if (config.source) {
      return fieldOptions[field.field_key] || []
    }

    return []
  }

  // 預先載入所有需要動態載入的欄位選項
  async function loadAllFieldOptions () {
    const loadPromises = fields.value.map(async field => {
      const config = field.field_config || {}

      // 如果欄位使用選項活頁簿，需要動態載入選項
      if (config.option_workbook_key) {
        fieldLoading[field.field_key] = true
        try {
          const options = await loadWorkbookOptions(field, config)
          fieldOptions[field.field_key] = options
        } catch (error) {
          console.error(`載入欄位 ${field.field_key} 選項活頁簿失敗`, error)
          fieldOptions[field.field_key] = []
        } finally {
          fieldLoading[field.field_key] = false
        }
      }
      // 如果欄位有 source 配置，需要動態載入選項
      else if (config.source) {
        fieldLoading[field.field_key] = true
        try {
          const options = await loadFieldOptions(field, config)
          fieldOptions[field.field_key] = options
        } catch (error) {
          console.error(`載入欄位 ${field.field_key} 選項失敗`, error)
          fieldOptions[field.field_key] = []
        } finally {
          fieldLoading[field.field_key] = false
        }
      }
    })

    await Promise.all(loadPromises)
  }

  // 載入選項活頁簿的選項
  async function loadWorkbookOptions (field, config) {
    const workbookKey = config.option_workbook_key
    if (!workbookKey) {
      return []
    }

    try {
      // 使用 optionWorkbooksService 取得活頁簿選項
      // getWorkbookOptions 會自動使用 is_key 和 is_label 欄位
      const options = await optionWorkbooksService.getWorkbookOptions(workbookKey)
      
      // 轉換為 SelectField 需要的格式（title 和 value）
      return options.map(opt => ({
        value: opt.value,
        label: opt.label,
        title: opt.title || opt.label, // SelectField 使用 title
      }))
    } catch (error) {
      console.error(`載入選項活頁簿 ${workbookKey} 失敗`, error)
      return []
    }
  }

  // 載入欄位選項
  async function loadFieldOptions (_field, _config) {
    // 這裡可以根據 config.source 載入不同的資料
    // 例如：system_options, product_categories, suppliers 等
    // 目前先返回空陣列，實際實作時需要根據 source 類型載入
    return []
  }

  // 判斷是否顯示欄位
  function shouldShowField (field) {
    if (!field.is_visible) {
      return false
    }

    // 檢查條件顯示
    const config = field.field_config || {}
    if (config.show_condition) {
      return evaluateCondition(config.show_condition)
    }

    return true
  }

  // 評估顯示條件
  function evaluateCondition (condition) {
    // 簡單的條件評估
    // 例如：{ field: 'main_category', operator: 'equals', value: 'H' }
    if (typeof condition === 'function') {
      return condition(formValues)
    }

    if (typeof condition === 'object') {
      const { field, operator, value } = condition
      const fieldValue = formValues[field]

      switch (operator) {
        case 'equals': {
          return fieldValue === value
        }
        case 'notEquals': {
          return fieldValue !== value
        }
        case 'contains': {
          return Array.isArray(fieldValue) && fieldValue.includes(value)
        }
        case 'notContains': {
          return !Array.isArray(fieldValue) || !fieldValue.includes(value)
        }
        case 'isEmpty': {
          return !fieldValue || (Array.isArray(fieldValue) && fieldValue.length === 0)
        }
        case 'isNotEmpty': {
          return fieldValue && (!Array.isArray(fieldValue) || fieldValue.length > 0)
        }
        default: {
          return true
        }
      }
    }

    return true
  }

  // 取得欄位寬度（cols）
  function getFieldCols (field) {
    const config = field.field_config || {}
    return config.cols || 12
  }

  // 取得欄位寬度（md）
  function getFieldMd (field) {
    const config = field.field_config || {}
    return config.md || config.cols || 12
  }

  // 取得層級寬度（cols）
  function getLevelCols (level) {
    return level.columnSize !== undefined && level.columnSize !== null
      ? Number(level.columnSize)
      : 12
  }

  // 取得層級寬度（md）
  function getLevelMd (level) {
    return level.columnSize !== undefined && level.columnSize !== null
      ? Number(level.columnSize)
      : 12
  }

  // 處理多層選單層級更新
  function handleCascadingLevelUpdate (fieldKey, levelIndex, value) {
    const currentValues = formValues[fieldKey] || []
    const newValues = [...currentValues]

    // 確保陣列長度足夠
    while (newValues.length <= levelIndex) {
      newValues.push(null)
    }

    newValues[levelIndex] = value

    // 清除後續層級的選擇
    for (let i = levelIndex + 1; i < newValues.length; i++) {
      newValues[i] = null
    }

    // 找到對應的欄位配置
    const field = fields.value.find(f => f.field_key === fieldKey)
    if (field && field.field_type === 'cascading_select' && field.field_config?.levels) {
      const level = field.field_config.levels[levelIndex]
      if (level && level.field_key) {
        // 將該層級的值也存儲到 formValues 中，使用層級的 field_key
        formValues[level.field_key] = value

        // 清除後續層級的值
        for (let i = levelIndex + 1; i < field.field_config.levels.length; i++) {
          const nextLevel = field.field_config.levels[i]
          if (nextLevel && nextLevel.field_key) {
            formValues[nextLevel.field_key] = null
          }
        }
      }
    }

    handleFieldUpdate(fieldKey, newValues)
  }

  // 處理欄位更新
  function handleFieldUpdate (fieldKey, value) {
    formValues[fieldKey] = value
    emit('update:modelValue', { ...formValues })
    emit('field-update', { fieldKey, value, formValues: { ...formValues } })
  }

  // 處理提交
  async function handleSubmit () {
    if (props.validateOnSubmit) {
      const { valid: isValid } = await formRef.value.validate()
      if (!isValid) {
        return
      }
    }

    submitting.value = true
    try {
      emit('submit', { ...formValues })
    } finally {
      submitting.value = false
    }
  }

  // 處理取消
  function handleCancel () {
    emit('cancel')
  }

  // 驗證表單
  async function validate () {
    if (formRef.value) {
      const { valid: isValid } = await formRef.value.validate()
      return isValid
    }
    return false
  }

  // 重置表單
  function reset () {
    if (formRef.value) {
      formRef.value.reset()
    }
    initializeFormValues()
  }

  // 取得表單值
  function getValues () {
    return { ...formValues }
  }

  // 設定表單值
  function setValues (values) {
    Object.assign(formValues, values)
  }

  async function applyInitialValuesIfNeeded () {
    const newValues = props.initialValues || {}
    if (!newValues || Object.keys(newValues).length === 0) {
      return
    }
    await nextTick()
    setValues(newValues)
  }

  // 暴露方法給父組件
  defineExpose({
    validate,
    reset,
    getValues,
    setValues,
  })

  // 監聽 formId 變化
  watch(() => props.formId, async () => {
    if (props.autoLoad) {
      await loadForm()
      await applyInitialValuesIfNeeded()
      // 如果已經有 recordId，載入表單資料
      if (props.recordId) {
        await loadFormData()
      }
    }
  }, { immediate: true })

  // 監聽 recordId 變化
  watch(() => props.recordId, async () => {
    if (props.autoLoad && props.recordId) {
      // 確保表單定義已載入
      if (!form.value || !fields.value.length) {
        await loadForm()
      }
      await loadFormData()
    }
  }, { immediate: true })

  // 監聽 initialValues 變化
  watch(() => props.initialValues, newValues => {
    if (newValues && Object.keys(newValues).length > 0) {
      setValues(newValues)
    }
  }, { deep: true, immediate: true })

  provide('dynamicFormContext', {
    formValues,
    fieldLoading,
    shouldShowField,
    getFieldWithReadonly,
    getFieldComponent,
    getFieldOptions,
    handleFieldUpdate,
    handleCascadingLevelUpdate,
    getFieldCols,
    getFieldMd,
    getLevelCols,
    getLevelMd,
  })

  onMounted(async () => {
    if (props.autoLoad) {
      await loadForm()
      await applyInitialValuesIfNeeded()
      if (props.recordId) {
        await loadFormData()
      }
    }
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.form-renderer-header-form-code {
  color: #fff;
  opacity: 0.95;
}

.form-group-panels {
  :deep(.v-expansion-panel) {
    background: transparent;
  }

  :deep(.form-section-panel) {
    margin-bottom: 16px;
    background: #f8f9fa;
    border-radius: 10px;
    overflow: hidden;
  }

  :deep(.form-section-title) {
    color: #667eea;
    font-size: 1.2em;
    font-weight: 600;
    min-height: 52px;
  }

  :deep(.form-section-content) {
    padding-top: 0;
  }
}

.subgroup-panels {
  :deep(.subgroup-panel) {
    background: #fff;
    border: 2px solid #dee2e6;
    border-radius: 10px;
    margin-bottom: 12px;
    overflow: hidden;
  }

  :deep(.subgroup-title) {
    color: #495057;
    font-size: 1.05em;
    font-weight: 600;
    min-height: 48px;
  }

  :deep(.subgroup-content) {
    padding-top: 0;
  }
}

.form-section {
  margin-bottom: 30px;
  padding: 25px;
  background: #f8f9fa;
  border-radius: 10px;

  h3 {
    color: #667eea;
    margin-bottom: 20px;
    font-size: 1.3em;
    border-bottom: 2px solid #667eea;
    padding-bottom: 10px;
  }
}

.subgroup-container {
  background: #fff;
  border: 2px solid #dee2e6;
  border-radius: 10px;
  padding: 20px;
  margin-bottom: 20px;
}

.subgroup-title {
  color: #495057;
  margin-bottom: 15px;
  font-size: 1.1em;
}

// 必填欄位的紅色星號
:deep(.v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label--floating .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field .v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-input .v-label__asterisk) {
  color: #f44336 !important;
}
</style>
