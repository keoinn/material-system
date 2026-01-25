# 選項活頁簿功能說明

## 概述

選項活頁簿功能允許使用者自定義資料儲存欄位，可以從指定的欄位作為選項提供給表單使用，並且可以讓使用者顯示和編輯資料。

## 功能特性

### 1. 活頁簿管理
- **分頁名稱與Key**：每個活頁簿都有唯一的名稱和key，用於系統內部引用
- **基本資訊**：活頁簿名稱、說明、啟用狀態

### 2. 欄位定義
- **自定義欄位**：使用者可以定義多個欄位，每個欄位包含：
  - `column_key`：欄位鍵值（用於儲存和讀取）
  - `column_label`：欄位標籤（顯示名稱）
  - `column_type`：欄位類型（text, number, boolean, date, select）
  - `is_key`：是否為key欄位（用於識別記錄）
  - `is_label`：是否為label欄位（用於顯示記錄）
  - `is_option_source`：是否作為選項來源（此欄位的值可以作為表單選項使用）

### 3. 資料編輯（類似Excel）
- **表格編輯**：使用類似Excel的表格編輯器
- **內聯編輯**：直接在表格中編輯資料
- **批量操作**：支援複製、刪除選中的資料行
- **資料結構**：
  - `row_key`：資料行的key值（必填）
  - `row_label`：資料行的label值（必填）
  - `row_data`：其他欄位資料（JSON格式）

## 資料庫結構

### option_workbooks（活頁簿主表）
- `id`：主鍵
- `workbook_key`：活頁簿唯一識別碼
- `workbook_name`：活頁簿名稱
- `description`：說明
- `is_active`：是否啟用

### option_workbook_columns（欄位定義表）
- `id`：主鍵
- `workbook_id`：所屬活頁簿ID
- `column_key`：欄位鍵值
- `column_label`：欄位標籤
- `column_type`：欄位類型
- `is_key`：是否為key欄位
- `is_label`：是否為label欄位
- `is_option_source`：是否作為選項來源
- `column_config`：欄位額外設定（JSON）

### option_workbook_rows（資料表）
- `id`：主鍵
- `workbook_id`：所屬活頁簿ID
- `row_key`：資料行的key值
- `row_label`：資料行的label值
- `row_data`：其他欄位資料（JSON格式）

## API 使用方式

### 取得活頁簿列表
```javascript
import { optionWorkbooksService } from '@/api/services/optionWorkbooks'

const workbooks = await optionWorkbooksService.getWorkbooks({ is_active: true })
```

### 取得單一活頁簿
```javascript
const workbook = await optionWorkbooksService.getWorkbook(workbookId, true, true)
// 參數：id或key, 是否包含欄位定義, 是否包含資料行
```

### 建立活頁簿
```javascript
const newWorkbook = await optionWorkbooksService.createWorkbook({
  workbook_key: 'suppliers',
  workbook_name: '供應商清單',
  description: '供應商資料管理',
  is_active: true,
  columns: [
    {
      column_key: 'code',
      column_label: '供應商代碼',
      column_type: 'text',
      is_key: true,
      is_label: false,
      is_option_source: false,
    },
    {
      column_key: 'name',
      column_label: '供應商名稱',
      column_type: 'text',
      is_key: false,
      is_label: true,
      is_option_source: true,
    },
    {
      column_key: 'contact',
      column_label: '聯絡人',
      column_type: 'text',
      is_key: false,
      is_label: false,
      is_option_source: false,
    },
  ],
  rows: [
    {
      row_key: 'SUP001',
      row_label: '供應商A',
      row_data: {
        contact: '張三',
      },
    },
  ],
})
```

### 取得活頁簿選項（用於表單）
```javascript
// 取得活頁簿的選項列表（用於表單選項）
const options = await optionWorkbooksService.getWorkbookOptions('suppliers', 'name')
// 參數：workbook_key, 選項欄位key（可選，預設使用row_key和row_label）
```

## 前端組件使用

### OptionWorkbooks.vue（主組件）
顯示活頁簿列表，提供新增、編輯、刪除功能。

### OptionWorkbookEditor.vue（編輯器組件）
提供類似Excel的編輯體驗：
- 欄位定義管理
- 資料行編輯（內聯編輯）
- 批量操作（複製、刪除）

## 使用範例

### 在表單中使用活頁簿選項

```javascript
// 在表單欄位配置中使用活頁簿選項
const fieldConfig = {
  field_type: 'select',
  field_config: {
    options_source: {
      type: 'workbook',
      workbook_key: 'suppliers',
      option_column_key: 'name', // 可選，指定使用哪個欄位作為選項值
    },
  },
}
```

## 注意事項

1. **Key和Label欄位**：每個活頁簿必須定義一個key欄位和一個label欄位
2. **欄位Key唯一性**：同一活頁簿內欄位key必須唯一
3. **資料行Key唯一性**：同一活頁簿內資料行的row_key必須唯一
4. **選項來源**：標記為`is_option_source`的欄位可以作為表單選項使用
5. **資料格式**：除了key和label，其他欄位資料都儲存在`row_data` JSON欄位中
