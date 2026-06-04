<template>
  <v-card>
    <v-card-title class="system-header d-flex align-center flex-wrap ga-2">
      <div>
        <h2 class="ma-0">包裝說明模板管理</h2>
        <div
          v-if="currentStep === 2 && selectedForm"
          class="text-caption text-white mt-1 packaging-header-form-name"
        >
          表單名稱：{{ selectedForm.form_name }}（{{ selectedForm.form_code }}）
        </div>
      </div>
      <v-spacer />
      <v-btn
        v-if="currentStep === 2"
        class="mr-2"
        prepend-icon="mdi-file-import"
        variant="outlined"
        @click="openImportJsonDialog"
      >
        JSON 導入
      </v-btn>
      <v-btn
        v-if="currentStep === 2"
        prepend-icon="mdi-arrow-left"
        variant="outlined"
        @click="goToFormSelection"
      >
        選擇表單
      </v-btn>
    </v-card-title>

    <v-card-text class="pt-6">
      <v-progress-linear
        v-if="loadingForms || loading"
        class="mb-4"
        color="primary"
        indeterminate
      />

      <v-window v-model="currentStep">
        <!-- 步驟一：選擇表單 -->
        <v-window-item :value="1">
          <p class="text-body-2 text-medium-emphasis mb-4">
            請選擇要設定包裝說明模板的表單（僅顯示啟用中的表單，不同表單可各自維護模板）
          </p>

          <v-alert
            v-if="!loadingForms && availableForms.length === 0"
            type="warning"
            variant="tonal"
          >
            目前沒有啟用中的表單，請先到「表單管理」建立或啟用表單。
          </v-alert>

          <v-row v-else>
            <v-col
              v-for="form in availableForms"
              :key="form.id"
              cols="12"
              sm="6"
              md="4"
              lg="3"
            >
              <v-btn
                block
                class="form-select-btn"
                color="primary"
                height="auto"
                :loading="loadingForms"
                variant="outlined"
                @click="selectForm(form)"
              >
                <div class="form-select-btn__content py-4">
                  <v-icon class="mb-2" color="primary" size="32">
                    mdi-file-document-outline
                  </v-icon>
                  <div class="text-subtitle-1 font-weight-medium">
                    {{ form.form_name }}
                  </div>
                  <div class="text-caption text-medium-emphasis form-select-btn__en">
                    {{ form.form_name_en || '\u00a0' }}
                  </div>
                  <div class="text-caption mt-1">
                    {{ form.form_code }}
                  </div>
                </div>
              </v-btn>
            </v-col>
          </v-row>
        </v-window-item>

        <!-- 步驟二：模板管理 -->
        <v-window-item :value="2">
          <template v-if="selectedFormId">
            <p class="mb-4">
              請先設定並儲存「模板分類依據欄位」，再進行欄位勾選與模板預設值編輯。
            </p>

            <!-- 步驟 2-1：模板分類依據（須先儲存） -->
            <v-card
              class="mb-4"
              variant="outlined"
            >
              <v-card-title class="text-subtitle-1 py-3">
                1. 模板分類依據
              </v-card-title>
              <v-card-text class="pt-0">
                <v-row>
                  <v-col
                    cols="12"
                    :md="categoryBasisConfirmed ? 12 : 8"
                  >
                    <v-select
                      v-model="categoryFieldKeyDraft"
                      :items="categoryFieldSelectItems"
                      item-title="title"
                      item-value="value"
                      label="模板分類依據欄位"
                      hint="下拉或多層選單（取第一層選項）；留空則為通用模板"
                      persistent-hint
                      :clearable="!categoryBasisConfirmed"
                      :disabled="categoryBasisConfirmed"
                      variant="outlined"
                    />
                  </v-col>
                  <v-col
                    v-if="!categoryBasisConfirmed"
                    class="d-flex align-center"
                    cols="12"
                    md="4"
                  >
                    <v-btn
                      color="primary"
                      :disabled="savingCategoryField"
                      :loading="savingCategoryField"
                      @click="confirmCategoryBasis"
                    >
                      儲存並繼續
                    </v-btn>
                  </v-col>
                </v-row>
                <v-alert
                  v-if="!categoryBasisConfirmed"
                  class="mt-2"
                  density="compact"
                  type="warning"
                  variant="tonal"
                >
                  請先儲存分類依據，才能設定模板分類、欄位分類與模板內容。
                </v-alert>
              </v-card-text>
            </v-card>

            <template v-if="categoryBasisConfirmed">
              <div class="d-flex align-center flex-wrap ga-2 mb-4">
                <v-chip
                  color="primary"
                  size="small"
                  variant="tonal"
                >
                  {{ categoryBasisSummary }}
                </v-chip>
                <v-btn
                  size="small"
                  variant="text"
                  @click="reopenCategoryBasis"
                >
                  重新設定分類依據
                </v-btn>
              </div>

              <!-- 步驟 2-2：模板分類 + 欄位群組 -->
              <v-row class="mb-4">
                <v-col
                  v-if="useCategoryClassification"
                  cols="12"
                  md="6"
                >
                  <v-select
                    v-model="selectedTemplateType"
                    :items="templateVariantOptions"
                    item-title="title"
                    item-value="value"
                    label="2. 選擇模板分類"
                    hint="依所選欄位第一層選項值區分不同模板"
                    persistent-hint
                    variant="outlined"
                    @update:model-value="handleTemplateTypeChange"
                  />
                </v-col>
                <v-col
                  v-else
                  cols="12"
                  md="6"
                >
                  <v-alert
                    density="compact"
                    type="info"
                    variant="tonal"
                  >
                    目前為<strong>通用模板</strong>，申請表單載入時將直接套用，不需再選分類。
                  </v-alert>
                </v-col>
                <v-col cols="12" md="6">
                  <v-select
                    v-model="selectedFieldGroup"
                    :items="fieldGroupOptions"
                    item-title="title"
                    item-value="value"
                    label="3. 選擇欄位分類"
                    hint="僅顯示該分類下的欄位供勾選與編輯"
                    persistent-hint
                    variant="outlined"
                    @update:model-value="onFieldGroupChange"
                  />
                </v-col>
              </v-row>

              <!-- 4. 勾選加入模板的欄位 -->
              <v-card
                v-if="inclusionFields.length > 0"
                class="mb-4"
                variant="outlined"
              >
              <v-card-title class="text-subtitle-1 py-3">
                4. 模板欄位設定
                <span class="text-caption text-medium-emphasis ml-2">
                  （{{ selectedFieldGroup || '全部分類' }}）
                </span>
              </v-card-title>
              <v-card-text class="pt-0">
                <template v-for="(subGroup, subGroupName) in inclusionFieldsBySubGroup" :key="subGroupName || '_root'">
                  <div v-if="subGroupName" class="text-subtitle-2 mb-2 mt-2">
                    {{ subGroupName }}
                  </div>
                  <v-row dense>
                    <v-col
                      v-for="field in subGroup"
                      :key="field.id"
                      cols="12"
                      sm="6"
                      md="4"
                    >
                      <v-checkbox
                        v-model="fieldTemplateFlags[field.id]"
                        color="primary"
                        density="compact"
                        hide-details
                        :label="field.field_label || field.field_key"
                        @update:model-value="markFieldFlagsDirty"
                      />
                    </v-col>
                  </v-row>
                </template>
                <div class="d-flex flex-wrap ga-2 mt-3">
                  <v-btn
                    color="primary"
                    :disabled="!fieldFlagsDirty || savingFieldFlags"
                    :loading="savingFieldFlags"
                    variant="outlined"
                    @click="saveFieldInclusion"
                  >
                    儲存欄位設定
                  </v-btn>
                  <v-btn
                    variant="text"
                    :disabled="!fieldFlagsDirty"
                    @click="resetFieldFlags"
                  >
                    還原
                  </v-btn>
                </div>
              </v-card-text>
            </v-card>

            <v-alert
              v-else-if="!loading && selectedFieldGroup"
              class="mb-4"
              type="info"
              variant="tonal"
            >
              此分類下尚無欄位，請到「表單管理」新增欄位。
            </v-alert>

            <!-- 5. 模板預設值編輯區（所有已勾選加入模板的欄位） -->
            <p
              v-if="fields.length > 0"
              class="text-body-2 text-medium-emphasis mb-3"
            >
              以下顯示<strong>所有</strong>已勾選「加入模板」的欄位（含其他欄位分類），與上方「選擇欄位分類」僅用於勾選欄位無關。
            </p>
            <template v-for="(group, groupName) in groupedFields" :key="groupName">
              <div
                v-if="((group.subGroups && Object.keys(group.subGroups).length > 0) || (group.ungrouped && group.ungrouped.length > 0)) && groupName !== '_ungrouped'"
                class="form-section"
              >
                <h3>{{ groupName }}</h3>
                <template v-for="(subGroup, subGroupName) in getSubGroupsForDisplay(groupName, group)" :key="subGroupName">
                  <div v-if="subGroupName" class="subgroup-container">
                    <h4 class="subgroup-title">{{ subGroupName }}</h4>
                    <div class="subgroup-content">
                      <v-row>
                        <template v-for="field in subGroup" :key="field.id">
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

                  <v-row v-else>
                    <template v-for="field in subGroup" :key="field.id">
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

            <div v-if="ungroupedFields.length > 0" class="form-section">
              <h3>未分組欄位</h3>
              <v-row>
                <template v-for="field in ungroupedFields" :key="field.id">
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

            <v-alert
              v-if="!loading && fields.length === 0"
              class="mt-4"
              type="info"
              variant="tonal"
            >
              請在「模板欄位設定」勾選「加入模板」並儲存；可切換欄位分類分批勾選，儲存後會在此顯示全部已勾選欄位。
            </v-alert>

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
            </template>
          </template>
        </v-window-item>
      </v-window>
    </v-card-text>

    <input
      ref="importJsonFileInputRef"
      accept=".json,application/json"
      class="d-none"
      type="file"
      @change="handleImportJsonFile"
    >

    <v-dialog
      v-model="importJsonDialog"
      max-width="960"
      persistent
      scrollable
    >
      <v-card>
        <v-card-title class="d-flex align-center">
          <v-icon class="mr-2">mdi-file-import</v-icon>
          包裝模板 JSON 導入
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="closeImportJsonDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>
        <v-card-text>
          <div
            class="packaging-json-editor-pane"
            :class="{ 'packaging-json-editor-pane--error': importJsonDraftError }"
          >
            <JsonCodeEditor v-model="importJsonDraft" />
          </div>
          <div
            v-if="importJsonDraftError"
            class="text-error text-caption mt-2"
          >
            JSON 格式錯誤，請檢查語法
          </div>
          <v-alert
            class="mt-4"
            type="info"
            variant="tonal"
          >
            支援格式：<code>templates</code> 陣列（多個分類）、單筆
            <code>template_type</code> + <code>template_values</code>、或純欄位鍵值物件（套用至目前分類）。
            可選 <code>packaging_template_category_field_key</code> 更新分類依據。
          </v-alert>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-btn
            prepend-icon="mdi-file-upload-outline"
            variant="text"
            @click="triggerImportJsonFilePicker"
          >
            選擇檔案
          </v-btn>
          <v-btn
            prepend-icon="mdi-format-align-left"
            variant="text"
            @click="formatImportJsonDraft"
          >
            格式化
          </v-btn>
          <v-spacer />
          <v-btn
            variant="text"
            @click="closeImportJsonDialog"
          >
            取消
          </v-btn>
          <v-btn
            :disabled="importJsonDraftError"
            variant="tonal"
            @click="applyImportJsonToEditor"
          >
            套用至編輯區
          </v-btn>
          <v-btn
            color="primary"
            :disabled="importJsonDraftError || saving"
            :loading="importJsonSaving"
            variant="flat"
            @click="commitImportJson"
          >
            導入並儲存
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script setup>
  import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
  import { useRoute } from 'vue-router'
  import { formFieldsService } from '@/api/services/formFields'
  import { formsService } from '@/api/services/forms'
  import { packagingService } from '@/api/services/packaging'
  import { useSwal } from '@/composables/useSwal'
  import { FORMS_UPDATED_EVENT } from '@/utils/formsUpdatedEvent'
  import {
    buildCategoryFieldSelectItems,
    buildPackagingTemplatesExportSnapshot,
    getCategoryFieldDisplayLabel,
    getPackagingCategoryFieldKey,
    getTemplateCategoryFieldOptions,
    isCategoryBasisConfigured,
    PACKAGING_TEMPLATE_CATEGORY_BASIS_CONFIGURED_KEY,
    PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY,
    PACKAGING_TEMPLATE_DEFAULT_TYPE,
    parsePackagingTemplatesImportPayload,
  } from '@/utils/packagingTemplateConfig'
  import JsonCodeEditor from './JsonCodeEditor.vue'
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

  const route = useRoute()
  const swal = useSwal()

  const currentStep = ref(1)
  const loadingForms = ref(false)
  const loading = ref(false)
  const saving = ref(false)
  const savingFieldFlags = ref(false)
  const savingCategoryField = ref(false)
  const availableForms = ref([])
  const selectedForm = ref(null)
  const currentFormConfig = ref({})
  const allFields = ref([])
  const fields = ref([])
  const fieldTemplateFlags = reactive({})
  const savedFieldTemplateFlags = reactive({})
  const fieldFlagsDirty = ref(false)
  const templateValues = reactive({})
  const fieldLoading = reactive({})
  const groupOrder = ref([])
  const subGroups = ref(new Map())
  const categoryFieldKeyDraft = ref(null)
  const categoryFieldKey = ref(null)
  const categoryBasisConfirmed = ref(false)
  const selectedTemplateType = ref('')
  const selectedFieldGroup = ref(null)
  const importJsonDialog = ref(false)
  const importJsonDraft = ref('')
  const importJsonDraftError = ref(false)
  const importJsonSaving = ref(false)
  const importJsonFileInputRef = ref(null)

  const selectedFormId = computed(() => selectedForm.value?.id ?? null)

  const useCategoryClassification = computed(() => Boolean(categoryFieldKey.value))

  const categorySourceFieldDraft = computed(() =>
    allFields.value.find(f => f.field_key === categoryFieldKeyDraft.value) ?? null,
  )

  const categoryBasisSummary = computed(() => {
    if (!categoryFieldKey.value) {
      return '分類依據：通用模板'
    }
    const field = categorySourceField.value
    return `分類依據：${getCategoryFieldDisplayLabel(field)}`
  })

  const categoryFieldSelectItems = computed(() =>
    buildCategoryFieldSelectItems(allFields.value),
  )

  const categorySourceField = computed(() =>
    allFields.value.find(f => f.field_key === categoryFieldKey.value) ?? null,
  )

  const templateVariantOptions = computed(() =>
    getTemplateCategoryFieldOptions(categorySourceField.value),
  )

  const activeTemplateType = computed(() =>
    useCategoryClassification.value
      ? selectedTemplateType.value
      : PACKAGING_TEMPLATE_DEFAULT_TYPE,
  )

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

  const fieldGroupOptions = computed(() => {
    const groups = new Set()
    for (const field of allFields.value) {
      if (field.field_group) {
        groups.add(field.field_group)
      }
    }
    const ordered = []
    for (const name of groupOrder.value) {
      if (groups.has(name)) {
        ordered.push({ title: name, value: name })
        groups.delete(name)
      }
    }
    for (const name of [...groups].toSorted()) {
      ordered.push({ title: name, value: name })
    }
    return ordered
  })

  const inclusionFields = computed(() => {
    if (!selectedFieldGroup.value) {
      return []
    }
    return allFields.value
      .filter(f => f.field_group === selectedFieldGroup.value)
      .toSorted((a, b) => (a.display_order || 0) - (b.display_order || 0))
  })

  const inclusionFieldsBySubGroup = computed(() => {
    const result = {}
    for (const field of inclusionFields.value) {
      const key = field.sub_group || ''
      if (!result[key]) {
        result[key] = []
      }
      result[key].push(field)
    }
    return result
  })

  const groupedFields = computed(() => {
    const groups = {}
    const ungrouped = []

    for (const field of fields.value) {
      if (field.field_group) {
        if (!groups[field.field_group]) {
          groups[field.field_group] = { subGroups: {}, ungrouped: [] }
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

    for (const groupName of Object.keys(groups)) {
      for (const subGroupName of Object.keys(groups[groupName].subGroups)) {
        groups[groupName].subGroups[subGroupName].sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
      }
      groups[groupName].ungrouped.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    }
    ungrouped.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))

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
      orderedGroups._ungrouped = { subGroups: {}, ungrouped }
    }
    return orderedGroups
  })

  const ungroupedFields = computed(() => groupedFields.value._ungrouped?.ungrouped || [])

  function getSubGroupsForGroup (groupName) {
    const subGroupsList = subGroups.value.get(groupName) || []
    return subGroupsList.toSorted((a, b) => (a.order || 0) - (b.order || 0))
  }

  function getSubGroupsForDisplay (groupName, groupData) {
    const result = {}
    if (!groupData) {
      groupData = { subGroups: {}, ungrouped: [] }
    }
    if (!groupData.subGroups) {
      groupData.subGroups = {}
    }
    const subGroupsList = getSubGroupsForGroup(groupName)
    if (subGroupsList?.length > 0) {
      for (const subGroup of subGroupsList) {
        result[subGroup.name] = groupData.subGroups[subGroup.name] || []
      }
    }
    if (groupData.subGroups) {
      for (const subGroupName of Object.keys(groupData.subGroups)) {
        if ((!subGroupsList || !subGroupsList.some(sg => sg.name === subGroupName)) && groupData.subGroups[subGroupName]?.length > 0) {
          result[subGroupName] = groupData.subGroups[subGroupName]
        }
      }
    }
    if (groupData.ungrouped?.length > 0) {
      result[''] = groupData.ungrouped
    }
    return result
  }

  function syncFieldFlagsFromFields (fieldList) {
    for (const key of Object.keys(fieldTemplateFlags)) {
      delete fieldTemplateFlags[key]
    }
    for (const key of Object.keys(savedFieldTemplateFlags)) {
      delete savedFieldTemplateFlags[key]
    }
    for (const field of fieldList) {
      const flag = Boolean(field.is_in_template)
      fieldTemplateFlags[field.id] = flag
      savedFieldTemplateFlags[field.id] = flag
    }
    fieldFlagsDirty.value = false
  }

  function markFieldFlagsDirty () {
    fieldFlagsDirty.value = inclusionFields.value.some(
      f => fieldTemplateFlags[f.id] !== savedFieldTemplateFlags[f.id],
    )
  }

  function resetFieldFlags () {
    for (const field of inclusionFields.value) {
      fieldTemplateFlags[field.id] = savedFieldTemplateFlags[field.id]
    }
    fieldFlagsDirty.value = false
  }

  function rebuildTemplateFieldsList () {
    // 模板預設值編輯區：顯示所有已勾選「加入模板」的欄位（不限目前欄位分類）
    fields.value = allFields.value
      .filter(f => fieldTemplateFlags[f.id])
      .toSorted((a, b) => (a.display_order || 0) - (b.display_order || 0))

    for (const field of fields.value) {
      if (templateValues[field.field_key] === undefined) {
        templateValues[field.field_key] = field.default_value || getDefaultValueForFieldType(field.field_type)
      }
    }
  }

  async function loadAvailableForms () {
    loadingForms.value = true
    try {
      const all = await formsService.getForms({ is_active: true })
      availableForms.value = all.sort((a, b) =>
        (a.form_name || '').localeCompare(b.form_name || '', 'zh-Hant'),
      )
    } catch (error) {
      console.error('載入表單列表失敗', error)
      availableForms.value = []
      await swal.error('載入表單列表失敗，請稍後再試')
    } finally {
      loadingForms.value = false
    }
  }

  async function selectForm (form) {
    selectedForm.value = form
    currentStep.value = 2
    await loadFormTemplateData()
  }

  function goToFormSelection () {
    currentStep.value = 1
    selectedForm.value = null
    allFields.value = []
    fields.value = []
    selectedFieldGroup.value = null
    categoryFieldKeyDraft.value = null
    categoryFieldKey.value = null
    categoryBasisConfirmed.value = false
    selectedTemplateType.value = ''
    currentFormConfig.value = {}
  }

  function pickDefaultFieldGroup () {
    const preferred = '包裝說明'
    const options = fieldGroupOptions.value
    if (options.some(o => o.value === preferred)) {
      return preferred
    }
    return options[0]?.value ?? null
  }

  async function loadFormTemplateData () {
    if (!selectedFormId.value) {
      return
    }

    loading.value = true
    try {
      const form = await formsService.getForm(selectedFormId.value, false)
      currentFormConfig.value = form?.form_config && typeof form.form_config === 'object'
        ? { ...form.form_config }
        : {}
      const savedKey = getPackagingCategoryFieldKey(currentFormConfig.value)
      categoryFieldKeyDraft.value = savedKey
      categoryFieldKey.value = savedKey
      categoryBasisConfirmed.value = isCategoryBasisConfigured(currentFormConfig.value)

      if (form?.form_config?.group_order && Array.isArray(form.form_config.group_order)) {
        groupOrder.value = [...form.form_config.group_order]
      } else {
        groupOrder.value = []
      }

      if (form?.form_config?.sub_groups && Object.keys(form.form_config.sub_groups).length > 0) {
        subGroups.value = new Map(
          Object.entries(form.form_config.sub_groups).map(([groupName, subGroupsList]) => [
            groupName,
            subGroupsList.map((sg, index) => ({
              name: typeof sg === 'string' ? sg : sg.name,
              order: typeof sg === 'string' ? index : (sg.order ?? index),
            })),
          ]),
        )
      } else {
        subGroups.value = new Map()
      }

      allFields.value = await formFieldsService.getFields(selectedFormId.value)

      if (groupOrder.value.length === 0) {
        const groupSet = new Set()
        for (const field of allFields.value) {
          if (field.field_group) {
            groupSet.add(field.field_group)
          }
        }
        groupOrder.value = [...groupSet].toSorted()
      }

      if (subGroups.value.size === 0) {
        const extracted = new Map()
        for (const field of allFields.value) {
          if (field.field_group && field.sub_group) {
            if (!extracted.has(field.field_group)) {
              extracted.set(field.field_group, new Set())
            }
            extracted.get(field.field_group).add(field.sub_group)
          }
        }
        for (const [groupName, subGroupSet] of extracted.entries()) {
          subGroups.value.set(
            groupName,
            [...subGroupSet].map((name, index) => ({ name, order: index })),
          )
        }
      }

      if (categoryBasisConfirmed.value) {
        await initializeTemplateEditorState()
      }
    } catch (error) {
      console.error('載入表單模板資料失敗', error)
      await swal.error('載入表單模板資料失敗，請稍後再試')
    } finally {
      loading.value = false
    }
  }

  function syncTemplateTypeSelection () {
    if (!useCategoryClassification.value) {
      selectedTemplateType.value = PACKAGING_TEMPLATE_DEFAULT_TYPE
      return
    }
    const options = templateVariantOptions.value
    if (!options.length) {
      selectedTemplateType.value = ''
      return
    }
    if (!options.some(o => o.value === selectedTemplateType.value)) {
      selectedTemplateType.value = options[0].value
    }
  }

  async function initializeTemplateEditorState () {
    syncFieldFlagsFromFields(allFields.value)
    selectedFieldGroup.value = pickDefaultFieldGroup()
    rebuildTemplateFieldsList()
    syncTemplateTypeSelection()
    if (activeTemplateType.value) {
      await loadTemplateByType(activeTemplateType.value)
    }
  }

  async function saveCategoryFieldConfig (fieldKey) {
    if (!selectedFormId.value) {
      return
    }
    savingCategoryField.value = true
    try {
      const nextConfig = { ...currentFormConfig.value }
      if (fieldKey) {
        nextConfig[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY] = fieldKey
      } else {
        delete nextConfig[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY]
      }
      nextConfig[PACKAGING_TEMPLATE_CATEGORY_BASIS_CONFIGURED_KEY] = true
      const updated = await formsService.updateForm(selectedFormId.value, {
        form_config: nextConfig,
      })
      currentFormConfig.value = updated?.form_config || nextConfig
      if (selectedForm.value) {
        selectedForm.value = { ...selectedForm.value, form_config: currentFormConfig.value }
      }
    } finally {
      savingCategoryField.value = false
    }
  }

  async function confirmCategoryBasis () {
    const draftKey = categoryFieldKeyDraft.value || null
    if (draftKey) {
      const options = getTemplateCategoryFieldOptions(categorySourceFieldDraft.value)
      if (!options.length) {
        await swal.warning('此欄位尚無第一層選項，請先到表單管理設定選項')
        return
      }
    }

    savingCategoryField.value = true
    try {
      await saveCategoryFieldConfig(draftKey)
      categoryFieldKey.value = draftKey
      categoryBasisConfirmed.value = true
      await initializeTemplateEditorState()
      await swal.success('分類依據已儲存，可繼續設定模板內容')
    } catch (error) {
      console.error('儲存模板分類設定失敗', error)
      await swal.error('儲存模板分類設定失敗', error.message || '請稍後再試')
    } finally {
      savingCategoryField.value = false
    }
  }

  function clearTemplateEditorState () {
    fields.value = []
    for (const key of Object.keys(templateValues)) {
      delete templateValues[key]
    }
    selectedTemplateType.value = ''
    selectedFieldGroup.value = null
    fieldFlagsDirty.value = false
    for (const key of Object.keys(fieldTemplateFlags)) {
      delete fieldTemplateFlags[key]
    }
    for (const key of Object.keys(savedFieldTemplateFlags)) {
      delete savedFieldTemplateFlags[key]
    }
  }

  async function reopenCategoryBasis () {
    const result = await swal.confirm(
      '重新設定分類依據會將當前模板移除，是否執行？',
      '確認重新設定',
    )
    if (!result.isConfirmed) {
      return
    }

    if (!selectedFormId.value) {
      return
    }

    loading.value = true
    try {
      await packagingService.deleteAllPackagingTemplatesForForm(selectedFormId.value)

      const nextConfig = { ...currentFormConfig.value }
      delete nextConfig[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY]
      delete nextConfig[PACKAGING_TEMPLATE_CATEGORY_BASIS_CONFIGURED_KEY]
      const updated = await formsService.updateForm(selectedFormId.value, {
        form_config: nextConfig,
      })
      currentFormConfig.value = updated?.form_config || nextConfig
      if (selectedForm.value) {
        selectedForm.value = { ...selectedForm.value, form_config: currentFormConfig.value }
      }

      categoryBasisConfirmed.value = false
      categoryFieldKey.value = null
      categoryFieldKeyDraft.value = null
      clearTemplateEditorState()
    } catch (error) {
      console.error('重新設定分類依據失敗', error)
      await swal.error('移除模板失敗', error.message || '請稍後再試')
    } finally {
      loading.value = false
    }
  }

  async function onFieldGroupChange () {
    resetFieldFlags()
  }

  async function saveFieldInclusion () {
    if (!selectedFormId.value) {
      return
    }

    const changed = inclusionFields.value.filter(
      f => fieldTemplateFlags[f.id] !== savedFieldTemplateFlags[f.id],
    )
    if (changed.length === 0) {
      return
    }

    savingFieldFlags.value = true
    try {
      for (const field of changed) {
        await formFieldsService.updateField(selectedFormId.value, field.id, {
          is_in_template: Boolean(fieldTemplateFlags[field.id]),
        })
        field.is_in_template = Boolean(fieldTemplateFlags[field.id])
        savedFieldTemplateFlags[field.id] = fieldTemplateFlags[field.id]
      }
      fieldFlagsDirty.value = false
      rebuildTemplateFieldsList()
      if (activeTemplateType.value) {
        await loadTemplateByType(activeTemplateType.value)
      }
      await swal.success('欄位設定已儲存')
    } catch (error) {
      console.error('儲存欄位設定失敗', error)
      await swal.error('儲存欄位設定失敗', error.message || '請稍後再試')
    } finally {
      savingFieldFlags.value = false
    }
  }

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

  async function loadTemplateByType (templateType) {
    if (!templateType || !selectedFormId.value) {
      return
    }

    for (const key of Object.keys(templateValues)) {
      delete templateValues[key]
    }

    try {
      const savedTemplate = await packagingService.getPackagingTemplate(selectedFormId.value, templateType)
      if (savedTemplate?.template_values) {
        Object.assign(templateValues, savedTemplate.template_values)
      }
    } catch (error) {
      console.warn('載入已儲存的模板失敗，使用預設值', error)
    }

    const templateFields = allFields.value.filter(f => fieldTemplateFlags[f.id])
    for (const field of templateFields) {
      if (templateValues[field.field_key] === undefined) {
        templateValues[field.field_key] = field.default_value || getDefaultValueForFieldType(field.field_type)
      }
    }
    rebuildTemplateFieldsList()
  }

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

  function shouldShowField (field) {
    return field.is_visible !== false
  }

  function getFieldComponent (fieldType) {
    return fieldComponents[fieldType] || TextField
  }

  function getFieldOptions (field) {
    if (field.field_config?.options) {
      return Array.isArray(field.field_config.options) ? field.field_config.options : []
    }
    return []
  }

  function getFieldCols (field) {
    return field.field_config?.cols || 12
  }

  function getFieldMd (field) {
    const config = field.field_config || {}
    return config.md || config.cols || 12
  }

  function getLevelCols (level) {
    return level.cols || 12
  }

  function getLevelMd (level) {
    return level.md || level.cols || 12
  }

  function getFieldWithReadonly (field) {
    return { ...field, is_readonly: false }
  }

  function handleFieldUpdate (fieldKey, value) {
    templateValues[fieldKey] = value
  }

  function handleCascadingLevelUpdate (fieldKey, levelIndex, value) {
    if (!templateValues[fieldKey]) {
      templateValues[fieldKey] = []
    }
    templateValues[fieldKey][levelIndex] = value
  }

  async function saveTemplate () {
    if (!selectedFormId.value) {
      await swal.warning('請先選擇表單')
      return
    }
    if (useCategoryClassification.value && !selectedTemplateType.value) {
      await swal.warning('請先選擇模板分類')
      return
    }
    if (useCategoryClassification.value && templateVariantOptions.value.length === 0) {
      await swal.warning('分類依據欄位尚無選項，請先到表單管理設定下拉選項')
      return
    }
    if (fieldFlagsDirty.value) {
      const result = await swal.confirm('欄位設定尚未儲存，是否先儲存欄位設定？', '未儲存的變更')
      if (result.isConfirmed) {
        await saveFieldInclusion()
      }
    }

    saving.value = true
    try {
      const payload = { ...templateValues }
      await packagingService.savePackagingTemplate(
        selectedFormId.value,
        activeTemplateType.value,
        payload,
      )
      await swal.success('模板已儲存！')
    } catch (error) {
      console.error('儲存模板失敗', error)
      await swal.error('儲存模板失敗', error.message || '請稍後再試')
    } finally {
      saving.value = false
    }
  }

  function buildImportJsonSample () {
    return buildPackagingTemplatesExportSnapshot({
      formConfig: currentFormConfig.value,
      templates: [{
        template_type: activeTemplateType.value || PACKAGING_TEMPLATE_DEFAULT_TYPE,
        template_values: { ...templateValues },
      }],
    })
  }

  function validateImportJsonDraft () {
    if (!importJsonDraft.value || !importJsonDraft.value.trim()) {
      importJsonDraftError.value = false
      return true
    }
    try {
      JSON.parse(importJsonDraft.value)
      importJsonDraftError.value = false
      return true
    } catch {
      importJsonDraftError.value = true
      return false
    }
  }

  function openImportJsonDialog () {
    if (!selectedFormId.value) {
      void swal.warning('請先選擇表單')
      return
    }
    importJsonDraft.value = buildImportJsonSample()
    importJsonDraftError.value = false
    importJsonDialog.value = true
  }

  function closeImportJsonDialog () {
    importJsonDialog.value = false
  }

  function formatImportJsonDraft () {
    if (!validateImportJsonDraft()) {
      return
    }
    try {
      importJsonDraft.value = JSON.stringify(JSON.parse(importJsonDraft.value || '{}'), null, 2)
      importJsonDraftError.value = false
    } catch {
      importJsonDraftError.value = true
    }
  }

  function triggerImportJsonFilePicker () {
    importJsonFileInputRef.value?.click()
  }

  function handleImportJsonFile (event) {
    const file = event.target?.files?.[0]
    if (!file) {
      return
    }
    const reader = new FileReader()
    reader.onload = () => {
      importJsonDraft.value = String(reader.result || '')
      validateImportJsonDraft()
    }
    reader.onerror = () => {
      void swal.error('讀取檔案失敗')
    }
    reader.readAsText(file)
    event.target.value = ''
  }

  function parseImportDraft () {
    if (!validateImportJsonDraft()) {
      throw new Error('JSON 格式錯誤')
    }
    return parsePackagingTemplatesImportPayload(importJsonDraft.value, {
      defaultTemplateType: activeTemplateType.value || PACKAGING_TEMPLATE_DEFAULT_TYPE,
    })
  }

  async function applyFormConfigPatch (formConfigPatch) {
    if (!formConfigPatch || Object.keys(formConfigPatch).length === 0) {
      return
    }
    const nextConfig = {
      ...currentFormConfig.value,
      ...formConfigPatch,
    }
    if (formConfigPatch[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY] === null) {
      delete nextConfig[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY]
    }
    const updated = await formsService.updateForm(selectedFormId.value, {
      form_config: nextConfig,
    })
    currentFormConfig.value = updated?.form_config || nextConfig
    if (selectedForm.value) {
      selectedForm.value = { ...selectedForm.value, form_config: currentFormConfig.value }
    }
    categoryFieldKey.value = getPackagingCategoryFieldKey(currentFormConfig.value)
    categoryBasisConfirmed.value = isCategoryBasisConfigured(currentFormConfig.value)
    categoryFieldKeyDraft.value = categoryFieldKey.value
  }

  function applyTemplateValuesToEditor (templateType, values) {
    if (useCategoryClassification.value) {
      if (templateType !== activeTemplateType.value) {
        selectedTemplateType.value = templateType
      }
    } else if (templateType !== PACKAGING_TEMPLATE_DEFAULT_TYPE) {
      void swal.warning(`目前為通用模板模式，已略過分類「${templateType}」的編輯區套用`)
      return false
    }
    Object.assign(templateValues, values)
    rebuildTemplateFieldsList()
    return true
  }

  async function applyImportJsonToEditor () {
    let parsed
    try {
      parsed = parseImportDraft()
    } catch (error) {
      await swal.warning(error.message || 'JSON 內容格式不正確')
      return
    }

    const { formConfigPatch, templates } = parsed
    const activeType = activeTemplateType.value
    const match = templates.find(t => t.template_type === activeType)
    const target = match ?? templates[0]
    if (templates.length > 1 && !match) {
      await swal.info(
        `目前分類「${activeType}」不在 JSON 中，已套用「${target.template_type}」至編輯區`,
      )
    }
    applyTemplateValuesToEditor(target.template_type, target.template_values)

    if (Object.keys(formConfigPatch).length > 0) {
      const result = await swal.confirm(
        'JSON 含分類依據設定，是否一併寫入表單設定？',
        '表單設定',
      )
      if (result.isConfirmed) {
        try {
          await applyFormConfigPatch(formConfigPatch)
        } catch (error) {
          await swal.error('更新表單設定失敗', error.message)
          return
        }
      }
    }

    importJsonDialog.value = false
    await swal.success(
      `已套用「${target.template_type}」至編輯區，請按「儲存模板」寫入資料庫`,
    )
  }

  async function commitImportJson () {
    if (!selectedFormId.value) {
      await swal.warning('請先選擇表單')
      return
    }

    let parsed
    try {
      parsed = parseImportDraft()
    } catch (error) {
      await swal.warning(error.message || 'JSON 內容格式不正確')
      return
    }

    const { formConfigPatch, templates } = parsed
    const result = await swal.confirm(
      `將寫入 ${templates.length} 筆包裝模板${Object.keys(formConfigPatch).length > 0 ? '，並更新分類依據設定' : ''}，是否繼續？`,
      '確認導入',
    )
    if (!result.isConfirmed) {
      return
    }

    importJsonSaving.value = true
    try {
      if (Object.keys(formConfigPatch).length > 0) {
        await applyFormConfigPatch(formConfigPatch)
      }
      for (const entry of templates) {
        await packagingService.savePackagingTemplate(
          selectedFormId.value,
          entry.template_type,
          entry.template_values,
        )
      }
      const activeEntry = templates.find(t => t.template_type === activeTemplateType.value)
        ?? templates[templates.length - 1]
      if (activeEntry) {
        if (useCategoryClassification.value && activeEntry.template_type !== selectedTemplateType.value) {
          selectedTemplateType.value = activeEntry.template_type
        }
        await loadTemplateByType(activeEntry.template_type)
      }
      importJsonDialog.value = false
      await swal.success(`已成功導入 ${templates.length} 筆模板`)
    } catch (error) {
      console.error('JSON 導入失敗', error)
      await swal.error('JSON 導入失敗', error.message || '請稍後再試')
    } finally {
      importJsonSaving.value = false
    }
  }

  watch(() => importJsonDraft.value, () => {
    if (importJsonDialog.value) {
      validateImportJsonDraft()
    }
  })

  async function resetTemplate () {
    if (!selectedFormId.value) {
      return
    }
    const result = await swal.confirm('確定要重置為預設值嗎？', '確認重置')
    if (result.isConfirmed) {
      saving.value = true
      try {
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

  async function handleFormsUpdated () {
    await loadAvailableForms()
    if (selectedForm.value) {
      const refreshed = availableForms.value.find(f => f.id === selectedForm.value.id)
      if (refreshed) {
        selectedForm.value = refreshed
        await loadFormTemplateData()
      } else {
        goToFormSelection()
      }
    }
  }

  onMounted(() => {
    loadAvailableForms()
    window.addEventListener(FORMS_UPDATED_EVENT, handleFormsUpdated)
  })

  onUnmounted(() => {
    window.removeEventListener(FORMS_UPDATED_EVENT, handleFormsUpdated)
  })

  watch(() => route.query.tab, tab => {
    if (tab === 'packaging') {
      loadAvailableForms()
      if (currentStep.value === 2 && selectedFormId.value) {
        loadFormTemplateData()
      }
    }
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.packaging-header-form-name {
  color: #fff;
  opacity: 0.95;
}

.form-select-btn {
  text-transform: none;
  letter-spacing: normal;
}

.form-select-btn__content {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
  white-space: normal;
  text-align: center;
}

.form-select-btn__en {
  min-height: 20px;
  line-height: 20px;
}

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
  display: block;
}

.gap-4 {
  gap: 16px;
}

.packaging-json-editor-pane {
  min-height: 360px;
  height: 50vh;
  max-height: 520px;
  overflow: hidden;
  border: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
  border-radius: 4px;
  background: #fafafa;
}

.packaging-json-editor-pane--error {
  border-color: rgb(var(--v-theme-error));
}

.packaging-json-editor-pane :deep(.cm-editor) {
  height: 100%;
}
</style>
