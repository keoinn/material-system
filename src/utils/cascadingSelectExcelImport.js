import * as XLSX from 'xlsx'

/** Excel 匯入格式最多支援的層級數 */
export const MAX_CASCADING_EXCEL_LEVELS = 4

function cellToString (cell) {
  if (cell === null || cell === undefined) {
    return ''
  }
  return String(cell).trim()
}

function buildRow2Labels (levelCount) {
  const row = []
  for (let i = 1; i <= levelCount; i++) {
    row.push(`level${i}_code`, `level${i}_text`)
  }
  return row
}

function detectNewFormat (rows) {
  const row0 = rows[0] || []
  const row1 = rows[1] || []
  const a0 = cellToString(row0[0]).toLowerCase()
  const a1 = cellToString(row1[0]).toLowerCase()
  if (a0.includes('level1_key_name') || a0.includes('key_name')) {
    return true
  }
  if (a1.includes('level1_code') || (a1.includes('code') && cellToString(row1[1]).toLowerCase().includes('text'))) {
    return true
  }
  return false
}

function countLevelsFromKeyRow (row0, maxLevels) {
  let count = 0
  for (let level = 0; level < maxLevels; level++) {
    const fieldKey = cellToString(row0[level * 2 + 1])
    if (!fieldKey) {
      break
    }
    count += 1
  }
  return count
}

function extractFieldKeysFromRow (row0, levelCount) {
  const keys = []
  for (let level = 0; level < levelCount; level++) {
    keys.push(cellToString(row0[level * 2 + 1]))
  }
  return keys
}

/**
 * 從資料列建立多層選單選項樹（code / text 欄位對）
 */
export function buildCascadingOptionsFromExcelRows (rows, levelCount, dataStartRowIndex = 0) {
  const root = []
  const errors = []

  for (let rowIndex = dataStartRowIndex; rowIndex < rows.length; rowIndex++) {
    const row = rows[rowIndex]
    if (!row || row.every(c => cellToString(c) === '')) {
      continue
    }

    let currentList = root
    let pathPrefix = ''

    for (let level = 0; level < levelCount; level++) {
      const codeCol = level * 2
      const textCol = level * 2 + 1
      const value = cellToString(row[codeCol])
      const label = cellToString(row[textCol]) || value

      if (!value) {
        break
      }

      let node = currentList.find(o => o.value === value)
      if (!node) {
        node = { value, label, children: [] }
        currentList.push(node)
      } else if (label && node.label !== label) {
        node.label = label
      }

      pathPrefix = pathPrefix ? `${pathPrefix} > ${value}` : value
      currentList = node.children
    }

    if (pathPrefix === '') {
      errors.push(`第 ${rowIndex + 1} 列：至少需填寫層級 1 的 code`)
    }
  }

  return { options: root, errors }
}

function parseLegacyFormat (rawRows, levelCount) {
  let dataRows = rawRows.map(row => (Array.isArray(row) ? row : [row]))
  const joined = dataRows[0]?.map(cellToString).join(' ') || ''
  if (/層級|level|值|標籤|value|label/i.test(joined)) {
    dataRows = dataRows.slice(1)
  }
  const { options, errors } = buildCascadingOptionsFromExcelRows(dataRows, levelCount, 0)
  return {
    options,
    fieldKeys: [],
    errors,
    rowCount: dataRows.length,
    format: 'legacy',
  }
}

function parseKeyOptionFormat (rawRows, configuredLevelCount) {
  if (rawRows.length < 3) {
    throw new Error('Excel 至少需要 3 列（欄位鍵值列、標題列、一筆選項資料）')
  }

  const row0 = rawRows[0] || []
  const keysInFile = countLevelsFromKeyRow(row0, MAX_CASCADING_EXCEL_LEVELS)
  const levelCount = keysInFile > 0
    ? keysInFile
    : Math.min(Math.max(configuredLevelCount || 1, 1), MAX_CASCADING_EXCEL_LEVELS)

  if (levelCount < 1) {
    throw new Error('第 1 列請在 B/D/F/H 欄填寫各層級欄位鍵值')
  }

  const fieldKeys = extractFieldKeysFromRow(row0, levelCount)
  const dataRows = rawRows.slice(2)
  const { options, errors } = buildCascadingOptionsFromExcelRows(dataRows, levelCount, 0)

  if (options.length === 0) {
    throw new Error(errors[0] || '沒有可匯入的選項資料（請從第 3 列開始填寫）')
  }

  return {
    options,
    fieldKeys,
    errors,
    rowCount: dataRows.filter(r => r && !r.every(c => cellToString(c) === '')).length,
    format: 'key_option',
    levelCount,
  }
}

/**
 * 讀取 .xlsx / .xls / .csv 並解析為多層選單選項
 */
export async function parseCascadingSelectExcelFile (file, configuredLevelCount) {
  if (!file) {
    throw new Error('請選擇檔案')
  }
  if (!configuredLevelCount || configuredLevelCount < 1) {
    throw new Error('請先設定層次數量')
  }

  const buffer = await file.arrayBuffer()
  const workbook = XLSX.read(buffer, { type: 'array' })
  const sheetName = workbook.SheetNames[0]
  if (!sheetName) {
    throw new Error('Excel 檔案沒有工作表')
  }

  const sheet = workbook.Sheets[sheetName]
  const rawRows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' })
  if (!rawRows.length) {
    throw new Error('工作表沒有資料')
  }

  const rows = rawRows.map(row => (Array.isArray(row) ? row : [row]))

  if (detectNewFormat(rows)) {
    return parseKeyOptionFormat(rows, configuredLevelCount)
  }

  if (configuredLevelCount > MAX_CASCADING_EXCEL_LEVELS) {
    return parseLegacyFormat(rows, MAX_CASCADING_EXCEL_LEVELS)
  }

  return parseLegacyFormat(rows, configuredLevelCount)
}

/** 合併兩棵選項樹（以 value 為鍵） */
export function mergeCascadingOptionTrees (existing = [], incoming = []) {
  const result = existing.map(o => ({
    ...o,
    children: [...(o.children || [])],
  }))

  for (const node of incoming) {
    const found = result.find(o => o.value === node.value)
    if (found) {
      found.label = node.label || found.label
      found.children = mergeCascadingOptionTrees(found.children || [], node.children || [])
    } else {
      result.push({
        value: node.value,
        label: node.label || node.value,
        children: (node.children || []).map(c => ({
          ...c,
          children: [...(c.children || [])],
        })),
      })
    }
  }

  return result
}

/** public/ 內靜態範本路徑（對應 public/templates/excel/cascading-select-import-template.xlsx） */
export const CASCADING_SELECT_EXCEL_TEMPLATE_PATH =
  'templates/excel/cascading-select-import-template.xlsx'

export function getCascadingSelectExcelTemplateUrl () {
  const base = import.meta.env.BASE_URL || '/'
  const normalizedBase = base.endsWith('/') ? base : `${base}/`
  return `${normalizedBase}${CASCADING_SELECT_EXCEL_TEMPLATE_PATH}`
}

/** 下載 public 資料夾內的 Excel 匯入範本 */
export function downloadPublicCascadingSelectExcelTemplate (
  filename = 'cascading-select-import-template.xlsx',
) {
  const link = document.createElement('a')
  link.href = getCascadingSelectExcelTemplateUrl()
  link.download = filename
  link.rel = 'noopener'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

/** 產生 Excel 範本並觸發下載（程式動態產生，供測試或備用） */
export function downloadCascadingSelectExcelTemplate (
  levelCount,
  levelFieldKeys = [],
  filename = '動態下拉選單匯入範本.xlsx',
) {
  const n = Math.min(levelCount, MAX_CASCADING_EXCEL_LEVELS)
  const row1 = []
  const row2 = buildRow2Labels(n)

  for (let i = 0; i < n; i++) {
    row1.push(`level${i + 1}_key_name`, levelFieldKeys[i] || `level_${i + 1}_field_key`)
  }

  const sampleRows = [
    ['H', 'Hand 手把', '00', 'Test', 'S', 'Steel'],
    ['H', 'Hand 手把', '00', 'Test', 'A', 'Ag'],
    ['H', 'Hand 手把', '01', 'Test', 'B', 'Block'],
  ].map(row => row.slice(0, n * 2))

  const ws = XLSX.utils.aoa_to_sheet([
    row1,
    row2,
    ...sampleRows,
  ])
  ws['!cols'] = Array.from({ length: n * 2 }, () => ({ wch: 16 }))
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, '選項')
  XLSX.writeFile(wb, filename)
}
