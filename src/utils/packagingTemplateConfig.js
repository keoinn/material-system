/** 通用模板（未指定分類欄位時）的 template_type 識別碼 */
export const PACKAGING_TEMPLATE_DEFAULT_TYPE = '_default'

/** forms.form_config 內儲存「模板分類依據」下拉欄位的 key */
export const PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY = 'packaging_template_category_field_key'

/** 是否已完成「模板分類依據」設定（含選擇通用模板） */
export const PACKAGING_TEMPLATE_CATEGORY_BASIS_CONFIGURED_KEY = 'packaging_template_category_basis_configured'

export function isCategoryBasisConfigured (formConfig) {
  return Boolean(formConfig?.[PACKAGING_TEMPLATE_CATEGORY_BASIS_CONFIGURED_KEY])
}

export function getPackagingCategoryFieldKey (formConfig) {
  const key = formConfig?.[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY]
  return typeof key === 'string' && key.trim() ? key.trim() : null
}

function normalizeOptionList (options = []) {
  if (!Array.isArray(options)) {
    return []
  }
  return options
    .map(opt => {
      const value = opt.value ?? opt.label ?? opt.title ?? ''
      return {
        title: opt.label || opt.title || String(value),
        value: String(value),
      }
    })
    .filter(o => o.value !== undefined && o.value !== '')
}

/** 多層選單第一層選項（等同一般下拉） */
export function getFirstLevelCascadingOptions (field) {
  const config = field?.field_config || {}
  if (config.cascading_options && Array.isArray(config.cascading_options) && config.cascading_options.length > 0) {
    return normalizeOptionList(config.cascading_options)
  }
  const level0 = config.levels?.[0]
  if (level0?.options && Array.isArray(level0.options) && level0.options.length > 0) {
    return normalizeOptionList(level0.options)
  }
  return []
}

/** 可作為模板分類依據的欄位：select，或具第一層選項的 cascading_select */
export function getCategoryCapableFields (fields = []) {
  return fields.filter(f => {
    if (f.field_type === 'select') {
      return getTemplateCategoryFieldOptions(f).length > 0
    }
    if (f.field_type === 'cascading_select') {
      return getFirstLevelCascadingOptions(f).length > 0
    }
    return false
  })
}

export function getTemplateCategoryFieldOptions (field) {
  if (!field) {
    return []
  }
  if (field.field_type === 'select') {
    return normalizeOptionList(field.field_config?.options)
  }
  if (field.field_type === 'cascading_select') {
    return getFirstLevelCascadingOptions(field)
  }
  return []
}

export function getCategoryFieldDisplayLabel (field) {
  if (!field) {
    return ''
  }
  if (field.field_type === 'cascading_select') {
    const firstLevel = field.field_config?.levels?.[0]
    const layerName = firstLevel?.field_label || firstLevel?.label || '第一層'
    return `${field.field_label || field.field_key}（${field.field_key} · ${layerName}）`
  }
  return `${field.field_label || field.field_key}（${field.field_key}）`
}

/** 從表單欄位值解析 packaging_templates.template_type */
export function resolveTemplateTypeFromFieldValue (value) {
  if (value == null || value === '') {
    return null
  }
  if (Array.isArray(value)) {
    const first = value.find(v => v != null && v !== '')
    return first != null ? String(first) : null
  }
  if (typeof value === 'string') {
    return value.trim() || null
  }
  if (typeof value === 'number') {
    return String(value)
  }
  if (typeof value === 'object') {
    if (value.value != null && value.value !== '') {
      return String(value.value)
    }
    if (value.label != null && value.label !== '') {
      return String(value.label)
    }
  }
  return null
}

export function buildCategoryFieldSelectItems (fields = []) {
  const capableFields = getCategoryCapableFields(fields)
  return [
    { title: '（不使用分類，通用模板）', value: null },
    ...capableFields.map(f => ({
      title: getCategoryFieldDisplayLabel(f),
      value: f.field_key,
    })),
  ]
}

function normalizeTemplateEntry (entry, index) {
  if (!entry || typeof entry !== 'object' || Array.isArray(entry)) {
    throw new Error(`templates[${index}] 必須為物件`)
  }
  const templateType = String(entry.template_type ?? entry.type ?? '').trim()
  if (!templateType) {
    throw new Error(`templates[${index}] 缺少 template_type`)
  }
  const templateValues = entry.template_values ?? entry.values
  if (templateValues === undefined) {
    throw new Error(`templates[${index}] 缺少 template_values`)
  }
  if (!templateValues || typeof templateValues !== 'object' || Array.isArray(templateValues)) {
    throw new Error(`templates[${index}].template_values 必須為物件`)
  }
  return {
    template_type: templateType,
    template_values: { ...templateValues },
  }
}

/**
 * 解析包裝模板 JSON 導入內容
 * 支援：{ templates: [...] }、單筆 { template_type, template_values }、純 template_values 物件
 */
export function parsePackagingTemplatesImportPayload (rawText, options = {}) {
  const defaultTemplateType = options.defaultTemplateType || PACKAGING_TEMPLATE_DEFAULT_TYPE
  let parsed
  try {
    parsed = typeof rawText === 'string' ? JSON.parse(rawText || '{}') : rawText
  } catch {
    throw new Error('JSON 語法錯誤')
  }

  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('JSON 必須為物件格式')
  }

  const formConfigPatch = {}
  if (parsed.packaging_template_category_field_key !== undefined) {
    const key = parsed.packaging_template_category_field_key
    formConfigPatch[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY] =
      key === null || key === '' ? null : String(key).trim()
  } else if (parsed.form_config?.[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY] !== undefined) {
    const key = parsed.form_config[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY]
    formConfigPatch[PACKAGING_TEMPLATE_CATEGORY_FIELD_CONFIG_KEY] =
      key === null || key === '' ? null : String(key).trim()
  }

  if (parsed.packaging_template_category_basis_configured !== undefined) {
    formConfigPatch[PACKAGING_TEMPLATE_CATEGORY_BASIS_CONFIGURED_KEY] =
      Boolean(parsed.packaging_template_category_basis_configured)
  } else if (parsed.form_config?.[PACKAGING_TEMPLATE_CATEGORY_BASIS_CONFIGURED_KEY] !== undefined) {
    formConfigPatch[PACKAGING_TEMPLATE_CATEGORY_BASIS_CONFIGURED_KEY] =
      Boolean(parsed.form_config[PACKAGING_TEMPLATE_CATEGORY_BASIS_CONFIGURED_KEY])
  }

  let templates = []
  if (Array.isArray(parsed.templates)) {
    templates = parsed.templates.map((entry, index) => normalizeTemplateEntry(entry, index))
  } else if (parsed.template_type !== undefined || parsed.template_values !== undefined || parsed.values !== undefined) {
    templates = [normalizeTemplateEntry(parsed, 0)]
  } else {
    const reservedKeys = new Set([
      'form_config',
      'packaging_template_category_field_key',
      'packaging_template_category_basis_configured',
      'templates',
      'template_type',
      'template_values',
      'values',
    ])
    const looksLikeTemplateValues = Object.keys(parsed).some(key => !reservedKeys.has(key))
    if (looksLikeTemplateValues) {
      templates = [{
        template_type: defaultTemplateType,
        template_values: { ...parsed },
      }]
    }
  }

  if (templates.length === 0) {
    throw new Error('找不到可導入的 templates 或 template_values')
  }

  return { formConfigPatch, templates }
}

export function buildPackagingTemplatesExportSnapshot ({
  formConfig = {},
  templates = [],
} = {}) {
  const payload = {
    packaging_template_category_field_key:
      getPackagingCategoryFieldKey(formConfig),
    packaging_template_category_basis_configured:
      isCategoryBasisConfigured(formConfig),
    templates: templates.map(t => ({
      template_type: t.template_type,
      template_values: t.template_values || {},
    })),
  }
  return JSON.stringify(payload, null, 2)
}
