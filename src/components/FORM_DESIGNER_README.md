# 表單設計器使用說明

## 概述

表單設計器（FormDesigner）是一個完整的表單管理工具，允許管理員建立、編輯和管理動態表單定義。

## 功能特性

### 1. 表單基本資訊管理
- 表單代碼（唯一識別碼）
- 表單名稱（中英文）
- 表單說明
- 啟用/停用狀態

### 2. 欄位管理
- 新增/編輯/刪除欄位
- 拖曳排序（使用上下按鈕）
- 欄位屬性設定：
  - 欄位鍵值（唯一識別碼）
  - 欄位類型（11種類型）
  - 欄位標籤（中英文）
  - 字元長度限制
  - 必填/顯示/唯讀設定
  - 群組名稱
  - 顯示順序
  - 提示文字和說明
  - 預設值
  - 選項列表（select, radio, checkbox）
  - 進階配置（JSON格式）

### 3. 即時預覽
- 即時預覽表單效果
- 測試欄位互動
- 驗證表單結構

### 4. 表單管理
- 建立新表單
- 編輯現有表單
- 複製表單
- 刪除表單

## 使用方式

### 基本使用

```vue
<template>
  <FormDesigner
    :form-id="formId"
    @saved="handleSaved"
    @cancel="handleCancel"
  />
</template>

<script setup>
import FormDesigner from '@/components/FormDesigner.vue'

function handleSaved (formId) {
  console.log('表單已儲存，ID:', formId)
}

function handleCancel () {
  console.log('取消編輯')
}
</script>
```

### 在表單管理頁面使用

```vue
<template>
  <v-dialog v-model="designerDialog" max-width="1200" fullscreen>
    <FormDesigner
      :form-id="editingFormId"
      @saved="handleFormSaved"
      @cancel="designerDialog = false"
    />
  </v-dialog>
</template>
```

## 欄位類型

支援以下 11 種欄位類型：

1. **text** - 文字輸入框
2. **textarea** - 多行文字輸入框
3. **number** - 數字輸入框
4. **select** - 下拉選單（單選）
5. **multiselect** - 多選下拉選單
6. **checkbox** - 複選框
7. **radio** - 單選框
8. **date** - 日期選擇器
9. **datetime** - 日期時間選擇器
10. **file** - 檔案上傳
11. **json** - JSON 資料編輯

## 欄位屬性說明

### 基本屬性

- **欄位鍵值** (field_key) - 唯一識別碼，例如：`item_name_cn`
- **欄位類型** (field_type) - 從下拉選單選擇
- **欄位標籤** (field_label) - 顯示名稱（中文）
- **欄位標籤（英文）** (field_label_en) - 顯示名稱（英文）
- **字元長度** (max_length) - 最大字元數，用於計算版面大小
- **顯示順序** (display_order) - 欄位顯示順序
- **群組名稱** (field_group) - 用於分組顯示，例如：「基本資訊」、「分類資訊」

### 狀態屬性

- **必填** (is_required) - 是否為必填欄位
- **顯示** (is_visible) - 是否顯示欄位
- **唯讀** (is_readonly) - 是否為唯讀欄位

### 提示屬性

- **提示文字** (placeholder) - 輸入框的提示文字
- **說明文字** (help_text) - 欄位下方的說明文字
- **預設值** (default_value) - 欄位的預設值

### 選項設定（select, radio, checkbox）

對於需要選項的欄位類型，可以設定選項列表：

```javascript
[
  { value: 'H', label: 'Handle' },
  { value: 'S', label: 'Slide' },
  { value: 'M', label: 'Module' }
]
```

### 進階配置（JSON）

可以透過 JSON 格式設定進階選項：

```json
{
  "source": "product_categories",
  "filter": { "level": 1 },
  "dependsOn": "main_category_id",
  "cols": 12,
  "md": 6,
  "unit": "mm",
  "step": 1,
  "min": 0,
  "max": 100
}
```

## 操作流程

### 建立新表單

1. 點擊「建立新表單」
2. 填寫表單基本資訊（表單代碼、名稱等）
3. 切換到「欄位設定」標籤
4. 點擊「新增欄位」
5. 設定欄位屬性
6. 重複步驟 4-5 新增更多欄位
7. 使用上下按鈕調整欄位順序
8. 切換到「預覽」標籤查看效果
9. 點擊「儲存表單」

### 編輯現有表單

1. 在表單列表中點擊「編輯」按鈕
2. 修改表單基本資訊或欄位
3. 點擊「儲存表單」

### 複製表單

1. 在表單列表中點擊「複製」按鈕
2. 確認複製操作
3. 系統會建立一個新的表單副本

### 刪除表單

1. 在表單列表中點擊「刪除」按鈕
2. 確認刪除操作
3. 表單及其所有欄位定義將被刪除

## 注意事項

1. **表單代碼唯一性**：表單代碼必須唯一，且只能包含小寫字母、數字和底線，必須以字母開頭。

2. **欄位鍵值唯一性**：同一表單內的欄位鍵值必須唯一。

3. **欄位順序**：欄位會按照 `display_order` 排序顯示，可以透過上下按鈕調整。

4. **群組顯示**：設定 `field_group` 後，欄位會按群組分類顯示。

5. **選項設定**：select、radio、checkbox 類型的欄位需要設定選項列表。

6. **預覽功能**：預覽功能使用實際的欄位組件，可以測試表單的互動效果。

7. **儲存驗證**：儲存前會驗證表單基本資訊和欄位設定。

## 欄位配置範例

### 文字欄位

```javascript
{
  field_key: 'item_name_cn',
  field_label: '物料名稱（中文）',
  field_type: 'text',
  max_length: 500,
  is_required: true,
  field_group: '基本資訊',
  display_order: 1
}
```

### 下拉選單欄位

```javascript
{
  field_key: 'material',
  field_label: '基本材質',
  field_type: 'select',
  is_required: true,
  field_group: '物料資訊',
  display_order: 10,
  field_config: {
    options: [
      { value: 'Steel', label: 'Steel' },
      { value: 'Aluminum', label: 'Aluminum' }
    ]
  }
}
```

### 數字欄位

```javascript
{
  field_key: 'moq',
  field_label: '最小訂購量',
  field_type: 'number',
  field_group: '訂購資訊',
  display_order: 20,
  field_config: {
    min: 1,
    unit: 'PCS'
  }
}
```

## 相關組件

- `DynamicFormRenderer.vue` - 動態表單渲染器
- `form-fields/*.vue` - 各種欄位類型組件
- `forms.vue` - 表單管理頁面
