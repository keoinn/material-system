# 動態表單系統 API 服務說明

## 概述

動態表單系統提供了三個主要的 API 服務模組：

1. **formsService** - 表單定義管理
2. **formFieldsService** - 表單欄位定義管理
3. **formDataService** - 表單資料管理

所有服務都支援 Supabase 和 Axios 兩種後端實作，會根據環境變數自動選擇。

## 安裝與使用

### 導入服務

```javascript
import { formsService, formFieldsService, formDataService } from '@/api/services'
```

或單獨導入：

```javascript
import formsService from '@/api/services/forms.js'
import formFieldsService from '@/api/services/formFields.js'
import formDataService from '@/api/services/formData.js'
```

## Forms Service（表單定義管理）

### 取得所有表單列表

```javascript
// 取得所有啟用的表單
const forms = await formsService.getForms({ is_active: true })

// 取得預設表單
const defaultForms = await formsService.getForms({ is_default: true })
```

### 取得單一表單定義（含所有欄位）

```javascript
// 使用表單 ID
const form = await formsService.getForm(1, true)

// 使用 form_code
const form = await formsService.getForm('material_application', true)

// 不包含欄位定義
const form = await formsService.getForm('material_application', false)
```

### 建立表單定義

```javascript
const newForm = await formsService.createForm({
  form_code: 'custom_form',
  form_name: '自訂表單',
  form_name_en: 'Custom Form',
  description: '這是一個自訂表單',
  form_config: {
    version: 1,
    submitAction: 'custom_action'
  },
  is_active: true,
  is_default: false
})
```

### 更新表單定義

```javascript
const updatedForm = await formsService.updateForm(1, {
  form_name: '更新後的表單名稱',
  is_active: false
})
```

### 刪除表單定義

```javascript
await formsService.deleteForm(1)
```

### 複製表單定義

```javascript
const copiedForm = await formsService.duplicateForm(1, {
  form_code: 'material_application_copy',
  form_name: '物料申請表單 (複製)'
})
```

## Form Fields Service（表單欄位定義管理）

### 取得表單的所有欄位定義

```javascript
// 取得所有欄位
const fields = await formFieldsService.getFields('material_application')

// 取得特定群組的欄位
const fields = await formFieldsService.getFields('material_application', {
  field_group: '基本資訊'
})

// 只取得可見的欄位
const fields = await formFieldsService.getFields('material_application', {
  is_visible: true
})
```

### 取得單一欄位定義

```javascript
// 使用欄位 ID
const field = await formFieldsService.getField('material_application', 1)

// 使用 field_key
const field = await formFieldsService.getField('material_application', 'item_name_cn')
```

### 建立欄位定義

```javascript
const newField = await formFieldsService.createField('material_application', {
  field_key: 'custom_field',
  field_label: '自訂欄位',
  field_type: 'text',
  max_length: 255,
  is_required: true,
  field_group: '基本資訊',
  display_order: 100,
  field_config: {
    placeholder: '請輸入...'
  }
})
```

### 更新欄位定義

```javascript
const updatedField = await formFieldsService.updateField('material_application', 1, {
  field_label: '更新後的欄位標籤',
  is_required: false
})
```

### 刪除欄位定義

```javascript
await formFieldsService.deleteField('material_application', 1)
```

### 批量更新欄位順序

```javascript
await formFieldsService.updateFieldOrders('material_application', [
  { id: 1, display_order: 10 },
  { id: 2, display_order: 20 },
  { id: 3, display_order: 30 }
])
```

## Form Data Service（表單資料管理）

### 取得表單資料（單一記錄）

```javascript
// 取得記錄的所有欄位值
const formData = await formDataService.getFormData('material_application', 123)

// 包含欄位定義
const formData = await formDataService.getFormData('material_application', 123, {
  includeFieldDefinitions: true
})

// 結果格式：
// {
//   form_id: 1,
//   record_id: 123,
//   values: {
//     item_name_cn: '物料名稱',
//     item_name_en: 'Material Name',
//     ...
//   },
//   fields: [...] // 如果 includeFieldDefinitions 為 true
// }
```

### 取得表單資料列表（多筆記錄）

```javascript
// 取得所有記錄
const formDataList = await formDataService.getFormDataList('material_application')

// 根據特定欄位值篩選
const formDataList = await formDataService.getFormDataList('material_application', {
  field_key: 'status',
  field_value: 'APPROVED'
})
```

### 建立表單資料

```javascript
const formData = await formDataService.createFormData('material_application', {
  item_name_cn: '物料名稱',
  item_name_en: 'Material Name',
  material: 'Steel',
  dimensions: {
    length: 100,
    width: 50,
    height: 20
  }
}, {
  createRecord: true,
  recordId: 123 // 可選，如果不提供會自動產生
})
```

### 更新表單資料

```javascript
const updatedData = await formDataService.updateFormData('material_application', 123, {
  item_name_cn: '更新後的物料名稱',
  status: 'APPROVED'
})
```

### 儲存表單資料（自動判斷建立或更新）

```javascript
// 如果 recordId 存在，會更新；否則會建立
const savedData = await formDataService.saveFormData('material_application', 123, {
  item_name_cn: '物料名稱',
  item_name_en: 'Material Name'
})

// 建立新記錄（不提供 recordId）
const newData = await formDataService.saveFormData('material_application', null, {
  item_name_cn: '新物料名稱'
}, {
  createRecord: true
})
```

### 刪除表單資料

```javascript
await formDataService.deleteFormData('material_application', 123)
```

### 取得單一欄位值

```javascript
const value = await formDataService.getFieldValue('material_application', 123, 'item_name_cn')
```

### 設定單一欄位值

```javascript
await formDataService.setFieldValue('material_application', 123, 'item_name_cn', '新的物料名稱')
```

## 完整使用範例

### 範例 1：建立並填寫表單

```javascript
// 1. 取得表單定義
const form = await formsService.getForm('material_application', true)

// 2. 建立表單資料
const formData = await formDataService.createFormData('material_application', {
  item_name_cn: '把手 A',
  item_name_en: 'Handle A',
  material: 'Steel',
  dimensions: {
    length: 100,
    width: 50,
    height: 20
  }
}, {
  createRecord: true,
  recordId: 1001
})

console.log('建立的記錄 ID:', formData.record_id)
```

### 範例 2：動態建立表單和欄位

```javascript
// 1. 建立新表單
const newForm = await formsService.createForm({
  form_code: 'custom_form',
  form_name: '自訂表單',
  form_name_en: 'Custom Form',
  is_active: true
})

// 2. 建立欄位
await formFieldsService.createField(newForm.id, {
  field_key: 'name',
  field_label: '名稱',
  field_type: 'text',
  max_length: 100,
  is_required: true,
  display_order: 1
})

await formFieldsService.createField(newForm.id, {
  field_key: 'description',
  field_label: '說明',
  field_type: 'textarea',
  display_order: 2
})

// 3. 填寫表單資料
await formDataService.createFormData(newForm.id, {
  name: '測試項目',
  description: '這是一個測試項目'
}, {
  createRecord: true,
  recordId: 2001
})
```

### 範例 3：查詢和更新表單資料

```javascript
// 1. 取得表單資料
const formData = await formDataService.getFormData('material_application', 123, {
  includeFieldDefinitions: true
})

// 2. 顯示所有欄位值
console.log('表單資料:', formData.values)

// 3. 更新特定欄位
await formDataService.setFieldValue('material_application', 123, 'status', 'APPROVED')

// 4. 批量更新多個欄位
await formDataService.updateFormData('material_application', 123, {
  status: 'APPROVED',
  approval_date: new Date().toISOString()
})
```

## 欄位類型支援

表單系統支援以下欄位類型：

- **text** - 文字輸入框
- **textarea** - 多行文字輸入框
- **number** - 數字輸入框
- **select** - 下拉選單（單選）
- **multiselect** - 多選下拉選單
- **checkbox** - 複選框
- **radio** - 單選框
- **date** - 日期選擇器
- **datetime** - 日期時間選擇器
- **file** - 檔案上傳
- **json** - JSON 資料

## 錯誤處理

所有 API 方法都可能拋出錯誤，建議使用 try-catch 處理：

```javascript
try {
  const form = await formsService.getForm('material_application')
} catch (error) {
  console.error('取得表單失敗:', error.message)
}
```

## 注意事項

1. **表單 ID vs form_code**：所有服務都支援使用表單 ID（數字）或 form_code（字串）來識別表單。

2. **欄位 ID vs field_key**：formFieldsService 支援使用欄位 ID 或 field_key 來識別欄位。

3. **資料類型轉換**：formDataService 會自動根據欄位類型轉換資料格式（文字、數字、日期、JSON 等）。

4. **批量操作**：某些操作（如批量更新欄位順序）會自動處理，無需手動循環。

5. **向後相容**：這些服務與現有的 applications 表完全相容，可以並存使用。
