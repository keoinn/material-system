<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>包裝說明模板管理</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-alert
        v-if="!defaultFormId && !loading"
        class="mb-4"
        type="warning"
        variant="tonal"
      >
        尚未設定預設表單，請先到「表單管理」設定預設表單。
      </v-alert>

      <v-progress-linear
        v-if="loading"
        class="mb-4"
        color="primary"
        indeterminate
      />

      <div v-if="defaultFormId && !loading">
        <p class="mb-4">在此設定包裝說明模板，只會顯示已標記為「加入模板」的欄位</p>

        <!-- 模板類型選擇下拉選單 -->
        <v-row class="mb-4">
          <v-col cols="12" md="4">
            <v-select
              v-model="selectedTemplateType"
              :items="templateTypeOptions"
              label="選擇模板類型"
              variant="outlined"
              @update:model-value="handleTemplateTypeChange"
            />
          </v-col>
        </v-row>

        <!-- 按群組渲染欄位（支援子群組和群組順序） -->
        <template v-for="(group, groupName) in groupedFields" :key="groupName">
          <div v-if="((group.subGroups && Object.keys(group.subGroups).length > 0) || (group.ungrouped && group.ungrouped.length > 0)) && groupName !== '_ungrouped'" class="form-section">
            <h3>{{ groupName }}</h3>
            <!-- 按子群組分組顯示 -->
            <template v-for="(subGroup, subGroupName) in getSubGroupsForDisplay(groupName, group)" :key="subGroupName">
              <!-- 子群組容器（用方框包圍） -->
              <div v-if="subGroupName" class="subgroup-container">
                <h4 class="subgroup-title">{{ subGroupName }}</h4>
                <div class="subgroup-content">
                  <v-row>
                    <template v-for="field in subGroup" :key="field.id">
                      <!-- 多層選單：將每個層級作為獨立的 v-col 渲染 -->
                      <template v-if="field.field_type === 'cascading_select' && field.field_config?.levels">
                        <template
                          v-for="(level, levelIndex) in field.field_config.levels"
                          :key="`${field.id}-level-${levelIndex}`"
                        >
                          <v-col
                            v-if="shouldShowField(field) && (level.is_visible !== false)"
                            :cols="getLevelCols(level)"
                            :md="getLevelMd(level)"
                          >
                            <CascadingSelectLevel
                              :field="getFieldWithReadonly(field)"
                              :level="level"
                              :level-index="levelIndex"
                              :loading="fieldLoading[field.field_key] || false"
                              :selected-values="templateValues[field.field_key] || []"
                              @update:model-value="handleCascadingLevelUpdate(field.field_key, levelIndex, $event)"
                            />
                          </v-col>
                        </template>
                      </template>
                      <!-- 其他欄位：正常渲染 -->
                      <v-col
                        v-else-if="shouldShowField(field)"
                        :cols="getFieldCols(field)"
                        :md="getFieldMd(field)"
                      >
                        <component
                          :is="getFieldComponent(field.field_type)"
                          :field="getFieldWithReadonly(field)"
                          :form-values="templateValues"
                          :loading="fieldLoading[field.field_key] || false"
                          :model-value="templateValues[field.field_key]"
                          :options="getFieldOptions(field)"
                          @update:model-value="handleFieldUpdate(field.field_key, $event)"
                        />
                      </v-col>
                    </template>
                  </v-row>
                </div>
              </div>

              <!-- 未分組到子群組的欄位 -->
              <v-row v-else>
                <template v-for="field in subGroup" :key="field.id">
                  <!-- 多層選單：將每個層級作為獨立的 v-col 渲染 -->
                  <template v-if="field.field_type === 'cascading_select' && field.field_config?.levels">
                    <template
                      v-for="(level, levelIndex) in field.field_config.levels"
                      :key="`${field.id}-level-${levelIndex}`"
                    >
                      <v-col
                        v-if="shouldShowField(field) && (level.is_visible !== false)"
                        :cols="getLevelCols(level)"
                        :md="getLevelMd(level)"
                      >
                        <CascadingSelectLevel
                          :field="getFieldWithReadonly(field)"
                          :level="level"
                          :level-index="levelIndex"
                          :loading="fieldLoading[field.field_key] || false"
                          :selected-values="templateValues[field.field_key] || []"
                          @update:model-value="handleCascadingLevelUpdate(field.field_key, levelIndex, $event)"
                        />
                      </v-col>
                    </template>
                  </template>
                  <!-- 其他欄位：正常渲染 -->
                  <v-col
                    v-else-if="shouldShowField(field)"
                    :cols="getFieldCols(field)"
                    :md="getFieldMd(field)"
                  >
                    <component
                      :is="getFieldComponent(field.field_type)"
                      :field="getFieldWithReadonly(field)"
                      :form-values="templateValues"
                      :loading="fieldLoading[field.field_key] || false"
                      :model-value="templateValues[field.field_key]"
                      :options="getFieldOptions(field)"
                      @update:model-value="handleFieldUpdate(field.field_key, $event)"
                    />
                  </v-col>
                </template>
              </v-row>
            </template>
          </div>
        </template>

        <!-- 未分組欄位 -->
        <div v-if="ungroupedFields.length > 0" class="form-section">
          <h3>未分組欄位</h3>
          <v-row>
            <template v-for="field in ungroupedFields" :key="field.id">
              <!-- 多層選單：將每個層級作為獨立的 v-col 渲染 -->
              <template v-if="field.field_type === 'cascading_select' && field.field_config?.levels">
                <template
                  v-for="(level, levelIndex) in field.field_config.levels"
                  :key="`${field.id}-level-${levelIndex}`"
                >
                  <v-col
                    v-if="shouldShowField(field) && (level.is_visible !== false)"
                    :cols="getLevelCols(level)"
                    :md="getLevelMd(level)"
                  >
                    <CascadingSelectLevel
                      :field="getFieldWithReadonly(field)"
                      :level="level"
                      :level-index="levelIndex"
                      :loading="fieldLoading[field.field_key] || false"
                      :selected-values="templateValues[field.field_key] || []"
                      @update:model-value="handleCascadingLevelUpdate(field.field_key, levelIndex, $event)"
                    />
                  </v-col>
                </template>
              </template>
              <!-- 其他欄位：正常渲染 -->
              <v-col
                v-else-if="shouldShowField(field)"
                :cols="getFieldCols(field)"
                :md="getFieldMd(field)"
              >
                <component
                  :is="getFieldComponent(field.field_type)"
                  :field="getFieldWithReadonly(field)"
                  :form-values="templateValues"
                  :loading="fieldLoading[field.field_key] || false"
                  :model-value="templateValues[field.field_key]"
                  :options="getFieldOptions(field)"
                  @update:model-value="handleFieldUpdate(field.field_key, $event)"
                />
              </v-col>
            </template>
          </v-row>
        </div>

        <!-- 如果沒有任何模板欄位 -->
        <v-alert
          v-if="!loading && fields.length === 0"
          class="mt-4"
          type="info"
          variant="tonal"
        >
          目前沒有標記為「加入模板」的欄位，請先到「表單管理」中編輯欄位並勾選「加入模板」。
        </v-alert>

        <!-- 操作按鈕 -->
        <div v-if="fields.length > 0" class="d-flex justify-center gap-4 mt-4">
          <v-btn
            color="primary"
            :disabled="saving"
            :loading="saving"
            size="large"
            @click="saveTemplate"
          >
            儲存模板
          </v-btn>
          <v-btn
            color="grey"
            :disabled="saving"
            size="large"
            @click="resetTemplate"
          >
            重置為預設
          </v-btn>
        </div>
      </div>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { computed, onMounted, reactive, ref } from 'vue'
  import { formFieldsService } from '@/api/services/formFields'
  import { formsService } from '@/api/services/forms'
  import { packagingService } from '@/api/services/packaging'
  import { useSwal } from '@/composables/useSwal'
  import AggregatedField from './form-fields/AggregatedField.vue'
  import CascadingSelectField from './form-fields/CascadingSelectField.vue'
  import CascadingSelectLevel from './form-fields/CascadingSelectLevel.vue'
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

  const swal = useSwal()

  const loading = ref(false)
  const saving = ref(false)
  const defaultFormId = ref(null)
  const fields = ref([])
  const templateValues = reactive({})
  const fieldLoading = reactive({})
  const groupOrder = ref([])
  const subGroups = ref(new Map())
  const selectedTemplateType = ref('')

  // 模板類型選項
  const templateTypeOptions = [
    { title: 'H - Handle (手把)', value: 'H' },
    { title: 'S - Slide (滑軌)', value: 'S' },
    { title: 'M - Module/Assy (模組)', value: 'M' },
    { title: 'D - Decorative Hardware (裝飾五金)', value: 'D' },
    { title: 'F - Functional Hardware (功能五金)', value: 'F' },
    { title: 'B - Builders Hardware (建築五金)', value: 'B' },
    { title: 'I - Industrial Parts Solution (工業零件)', value: 'I' },
    { title: 'O - Others (其他)', value: 'O' },
  ]

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
            subGroups: {},
            ungrouped: [],
          }
        }

        if (field.sub_group) {
          if (!groups[field.field_group].subGroups[field.sub_group]) {
            groups[field.field_group].subGroups[field.sub_group] = []
          }
          groups[field.field_group].subGroups[field.sub_group].push(field)
        } else {
          groups[field.field_group].ungrouped.push(field)
        }
      } else {
        ungrouped.push(field)
      }
    }

    // 按 display_order 排序每個群組內的欄位
    for (const groupName of Object.keys(groups)) {
      for (const subGroupName of Object.keys(groups[groupName].subGroups)) {
        groups[groupName].subGroups[subGroupName].sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
      }
      groups[groupName].ungrouped.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    }

    ungrouped.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))

    // 按照 groupOrder 排序群組
    const orderedGroups = {}

    for (const groupName of groupOrder.value) {
      if (groups[groupName]) {
        orderedGroups[groupName] = groups[groupName]
      }
    }

    for (const groupName of Object.keys(groups)) {
      if (groupName !== '_ungrouped' && !groupOrder.value.includes(groupName)) {
        orderedGroups[groupName] = groups[groupName]
      }
    }

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

    if (!groupData.subGroups) {
      groupData.subGroups = {}
    }

    const subGroupsList = getSubGroupsForGroup(groupName)
    if (subGroupsList && subGroupsList.length > 0) {
      for (const subGroup of subGroupsList) {
        result[subGroup.name] = groupData.subGroups[subGroup.name] || []
      }
    }

    if (groupData.subGroups) {
      for (const subGroupName of Object.keys(groupData.subGroups)) {
        if ((!subGroupsList || !subGroupsList.some(sg => sg.name === subGroupName)) && groupData.subGroups[subGroupName] && groupData.subGroups[subGroupName].length > 0) {
          result[subGroupName] = groupData.subGroups[subGroupName]
        }
      }
    }

    if (groupData.ungrouped && groupData.ungrouped.length > 0) {
      result[''] = groupData.ungrouped
    }

    return result
  }

  // 載入預設表單
  async function loadDefaultForm () {
    loading.value = true
    try {
      const defaultForms = await formsService.getForms({ is_default: true, is_active: true })
      if (defaultForms && defaultForms.length > 0) {
        defaultFormId.value = defaultForms[0].id
        await loadTemplateFields()
      } else {
        try {
          const materialForm = await formsService.getForm('material_application', false)
          if (materialForm && materialForm.is_active) {
            defaultFormId.value = materialForm.id
            await loadTemplateFields()
          }
        } catch (error) {
          console.error('載入 material_application 表單失敗', error)
        }
      }
    } catch (error) {
      console.error('載入預設表單失敗', error)
      await swal.error('載入表單定義失敗，請稍後再試')
    } finally {
      loading.value = false
    }
  }

  // 載入模板欄位（只載入 is_in_template 為 true 的欄位）
  async function loadTemplateFields () {
    if (!defaultFormId.value) return

    loading.value = true
    try {
      // 載入表單定義以獲取群組順序和子群組設定
      const form = await formsService.getForm(defaultFormId.value, false)
      if (form) {
        // 載入群組順序（從 form_config 中）
        if (form.form_config && form.form_config.group_order && Array.isArray(form.form_config.group_order)) {
          groupOrder.value = [...form.form_config.group_order]
        } else {
          const allGroups = new Set()
          const templateFields = await formFieldsService.getFields(defaultFormId.value, { is_in_template: true })
          for (const field of templateFields) {
            if (field.field_group) {
              allGroups.add(field.field_group)
            }
          }
          groupOrder.value = Array.from(allGroups).toSorted()
        }

        // 載入子群組資料（從 form_config 中）
        if (form.form_config && form.form_config.sub_groups && Object.keys(form.form_config.sub_groups).length > 0) {
          subGroups.value = new Map(Object.entries(form.form_config.sub_groups).map(([groupName, subGroupsList]) => {
            return [groupName, subGroupsList.map((sg, index) => ({
              name: typeof sg === 'string' ? sg : sg.name,
              order: typeof sg === 'string' ? index : (sg.order || index),
            }))]
          }))
        } else {
          // 從欄位中提取子群組
          const templateFields = await formFieldsService.getFields(defaultFormId.value, { is_in_template: true })
          const extractedSubGroups = new Map()
          for (const field of templateFields) {
            if (field.field_group && field.sub_group) {
              if (!extractedSubGroups.has(field.field_group)) {
                extractedSubGroups.set(field.field_group, new Set())
              }
              extractedSubGroups.get(field.field_group).add(field.sub_group)
            }
          }
          for (const [groupName, subGroupSet] of extractedSubGroups.entries()) {
            const subGroupsList = Array.from(subGroupSet).map((name, index) => ({
              name,
              order: index,
            }))
            subGroups.value.set(groupName, subGroupsList)
          }
        }
      }

      // 載入模板欄位
      const templateFields = await formFieldsService.getFields(defaultFormId.value, { is_in_template: true })
      fields.value = templateFields

      // 初始化模板值
      for (const field of fields.value) {
        if (templateValues[field.field_key] === undefined) {
          templateValues[field.field_key] = field.default_value || getDefaultValueForFieldType(field.field_type)
        }
      }

      // 如果有選項，預設選擇第一個
      if (templateTypeOptions.length > 0 && !selectedTemplateType.value) {
        selectedTemplateType.value = templateTypeOptions[0].value
      }

      // 載入當前選擇的模板類型對應的模板值
      if (selectedTemplateType.value) {
        await loadTemplateByType(selectedTemplateType.value)
      }
    } catch (error) {
      console.error('載入模板欄位失敗', error)
      await swal.error('載入模板欄位失敗，請稍後再試')
    } finally {
      loading.value = false
    }
  }

  // 處理模板類型變更
  async function handleTemplateTypeChange (templateType) {
    if (!templateType) {
      return
    }

    loading.value = true
    try {
      await loadTemplateByType(templateType)
    } catch (error) {
      console.error('載入模板失敗', error)
      await swal.error('載入模板失敗，請稍後再試')
    } finally {
      loading.value = false
    }
  }

  // 根據模板類型載入模板值
  async function loadTemplateByType (templateType) {
    if (!templateType || !defaultFormId.value) {
      return
    }

    try {
      // 先重置為欄位的預設值
      for (const field of fields.value) {
        templateValues[field.field_key] = field.default_value || getDefaultValueForFieldType(field.field_type)
      }

      // 從資料庫載入對應模板類型的模板值
      try {
        const savedTemplate = await packagingService.getPackagingTemplate(defaultFormId.value, templateType)
        if (savedTemplate && savedTemplate.template_values) {
          // 只載入存在的欄位值
          for (const field of fields.value) {
            if (savedTemplate.template_values[field.field_key] !== undefined) {
              templateValues[field.field_key] = savedTemplate.template_values[field.field_key]
            }
          }
        }
      } catch (error) {
        console.warn('載入已儲存的模板失敗，使用預設值', error)
        // 如果載入失敗，繼續使用預設值
      }
    } catch (error) {
      console.error('載入模板失敗', error)
      throw error
    }
  }

  // 根據欄位類型取得預設值
  function getDefaultValueForFieldType (fieldType) {
    switch (fieldType) {
      case 'checkbox':
      case 'multiselect': {
        return []
      }
      case 'number': {
        return null
      }
      case 'json': {
        return {}
      }
      default: {
        return ''
      }
    }
  }

  // 判斷是否顯示欄位
  function shouldShowField (field) {
    return field.is_visible !== false
  }

  // 取得欄位組件
  function getFieldComponent (fieldType) {
    return fieldComponents[fieldType] || TextField
  }

  // 取得欄位選項
  function getFieldOptions (field) {
    if (field.field_config && field.field_config.options) {
      return Array.isArray(field.field_config.options)
        ? field.field_config.options
        : []
    }
    return []
  }

  // 取得欄位寬度
  function getFieldCols (field) {
    const config = field.field_config || {}
    return config.cols || 12
  }

  function getFieldMd (field) {
    const config = field.field_config || {}
    return config.md || config.cols || 12
  }

  // 取得層級寬度
  function getLevelCols (level) {
    return level.cols || 12
  }

  function getLevelMd (level) {
    return level.md || level.cols || 12
  }

  // 取得唯讀欄位
  function getFieldWithReadonly (field) {
    return {
      ...field,
      is_readonly: false, // 模板設定中允許編輯
    }
  }

  // 處理欄位更新
  function handleFieldUpdate (fieldKey, value) {
    templateValues[fieldKey] = value
  }

  // 處理多層選單更新
  function handleCascadingLevelUpdate (fieldKey, levelIndex, value) {
    if (!templateValues[fieldKey]) {
      templateValues[fieldKey] = []
    }
    templateValues[fieldKey][levelIndex] = value
  }

  // 儲存模板
  async function saveTemplate () {
    if (!defaultFormId.value) {
      await swal.warning('表單尚未載入完成')
      return
    }

    if (!selectedTemplateType.value) {
      await swal.warning('請先選擇模板類型')
      return
    }

    saving.value = true
    try {
      // 儲存模板到資料庫
      await packagingService.savePackagingTemplate(
        defaultFormId.value,
        selectedTemplateType.value,
        templateValues,
      )
      await swal.success('模板已儲存！')
    } catch (error) {
      console.error('儲存模板失敗', error)
      await swal.error('儲存模板失敗', error.message || '請稍後再試')
    } finally {
      saving.value = false
    }
  }

  // 重置模板
  async function resetTemplate () {
    if (!defaultFormId.value) {
      return
    }

    const result = await swal.confirm('確定要重置為預設值嗎？', '確認重置')
    if (result.isConfirmed) {
      saving.value = true
      try {
        // 重置為欄位的預設值
        for (const field of fields.value) {
          templateValues[field.field_key] = field.default_value || getDefaultValueForFieldType(field.field_type)
        }
        await swal.success('已重置為預設值！')
      } catch (error) {
        console.error('重置模板失敗', error)
        await swal.error('重置模板失敗，請稍後再試')
      } finally {
        saving.value = false
      }
    }
  }

  onMounted(() => {
    loadDefaultForm()
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.form-section {
  margin-bottom: 30px;
  padding: 25px;
  background: #f8f9fa;
  border-radius: 10px;

  h3 {
    color: #495057;
    margin-bottom: 20px;
    font-size: 1.2em;
    font-weight: 600;
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
  font-weight: 600;
}

.subgroup-content {
  /* 不需要額外的 padding，因為 container 已經有 padding */
  display: block;
}

.gap-4 {
  gap: 16px;
}
</style>
