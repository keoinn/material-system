# 動態表單系統前端組件說明

## 概述

動態表單系統提供了完整的前端組件，可以根據資料庫中的表單定義動態渲染表單。

## 主要組件

### DynamicFormRenderer.vue

主要的動態表單渲染器，根據 `form_fields` 資料動態渲染表單。

**Props:**
- `formId` (String|Number, required) - 表單 ID 或 form_code
- `recordId` (String|Number, optional) - 記錄 ID（用於編輯模式）
- `initialValues` (Object, optional) - 初始值
- `showTitle` (Boolean, default: true) - 是否顯示標題
- `showActions` (Boolean, default: true) - 是否顯示操作按鈕
- `showCancel` (Boolean, default: true) - 是否顯示取消按鈕
- `submitText` (String, default: '提交') - 提交按鈕文字
- `cancelText` (String, default: '取消') - 取消按鈕文字
- `validateOnSubmit` (Boolean, default: true) - 是否在提交時驗證
- `autoLoad` (Boolean, default: true) - 是否自動載入資料

**Events:**
- `submit` - 提交表單時觸發，參數為表單值
- `cancel` - 取消時觸發
- `update:modelValue` - 表單值更新時觸發
- `field-update` - 單一欄位更新時觸發

**Methods (透過 ref 暴露):**
- `validate()` - 驗證表單，返回 Promise<boolean>
- `reset()` - 重置表單
- `getValues()` - 取得表單值
- `setValues(values)` - 設定表單值

## 欄位類型組件

### TextField.vue
文字輸入框組件。

**支援的欄位類型:** `text`

**特性:**
- 支援最大長度限制
- 支援必填驗證
- 支援正則表達式驗證
- 支援唯讀模式

### TextareaField.vue
多行文字輸入框組件。

**支援的欄位類型:** `textarea`

**特性:**
- 支援最大長度限制
- 支援自動增長
- 支援自訂行數

### NumberField.vue
數字輸入框組件。

**支援的欄位類型:** `number`

**特性:**
- 支援最小值/最大值驗證
- 支援步進值設定
- 支援單位顯示

### SelectField.vue
下拉選單組件（單選）。

**支援的欄位類型:** `select`

**特性:**
- 支援動態載入選項
- 支援自訂 item-title 和 item-value
- 支援返回物件模式

### MultiselectField.vue
多選下拉選單組件。

**支援的欄位類型:** `multiselect`

**特性:**
- 支援多選
- 顯示為 chips
- 支援動態載入選項

### CheckboxField.vue
複選框組件。

**支援的欄位類型:** `checkbox`

**特性:**
- 支援多選
- 支援動態選項
- 支援必填驗證

### RadioField.vue
單選框組件。

**支援的欄位類型:** `radio`

**特性:**
- 單選模式
- 支援動態選項
- 支援必填驗證

### DateField.vue
日期選擇器組件。

**支援的欄位類型:** `date`

**特性:**
- 使用 HTML5 date input
- 自動格式化日期
- 支援必填驗證

### DatetimeField.vue
日期時間選擇器組件。

**支援的欄位類型:** `datetime`

**特性:**
- 使用 HTML5 datetime-local input
- 自動格式化日期時間
- 支援必填驗證

### FileField.vue
檔案上傳組件。

**支援的欄位類型:** `file`

**特性:**
- 支援單檔案/多檔案上傳
- 支援檔案類型限制
- 支援檔案大小限制
- 支援預覽功能

### JsonField.vue
JSON 資料編輯組件。

**支援的欄位類型:** `json`

**特性:**
- JSON 格式驗證
- 自動格式化
- 語法高亮（可擴展）

## 使用範例

### 基本使用

```vue
<template>
  <DynamicFormRenderer
    ref="formRef"
    form-id="material_application"
    @submit="handleSubmit"
    @cancel="handleCancel"
  />
</template>

<script setup>
import { ref } from 'vue'
import DynamicFormRenderer from '@/components/DynamicFormRenderer.vue'

const formRef = ref(null)

async function handleSubmit (formValues) {
  console.log('表單值:', formValues)
  // 處理提交邏輯
}

function handleCancel () {
  // 處理取消邏輯
}
</script>
```

### 編輯模式

```vue
<template>
  <DynamicFormRenderer
    form-id="material_application"
    :record-id="123"
    @submit="handleUpdate"
  />
</template>

<script setup>
import DynamicFormRenderer from '@/components/DynamicFormRenderer.vue'

async function handleUpdate (formValues) {
  // 更新表單資料
  await formDataService.updateFormData('material_application', 123, formValues)
}
</script>
```

### 自訂初始值

```vue
<template>
  <DynamicFormRenderer
    form-id="material_application"
    :initial-values="{
      item_name_cn: '預設物料名稱',
      material: 'Steel'
    }"
    @submit="handleSubmit"
  />
</template>
```

### 手動控制表單

```vue
<template>
  <DynamicFormRenderer
    ref="formRef"
    form-id="material_application"
    :auto-load="false"
    @submit="handleSubmit"
  />
  
  <v-btn @click="validateForm">驗證</v-btn>
  <v-btn @click="resetForm">重置</v-btn>
  <v-btn @click="getFormValues">取得值</v-btn>
</template>

<script setup>
import { ref } from 'vue'
import DynamicFormRenderer from '@/components/DynamicFormRenderer.vue'

const formRef = ref(null)

async function validateForm () {
  const isValid = await formRef.value.validate()
  console.log('表單驗證結果:', isValid)
}

function resetForm () {
  formRef.value.reset()
}

function getFormValues () {
  const values = formRef.value.getValues()
  console.log('表單值:', values)
}
</script>
```

## 欄位配置說明

### field_config 範例

```javascript
{
  // 選項列表（用於 select, radio, checkbox）
  options: [
    { value: 'H', label: 'Handle' },
    { value: 'S', label: 'Slide' }
  ],
  
  // 資料來源（動態載入）
  source: 'product_categories',
  filter: { level: 1 },
  
  // 欄位寬度
  cols: 12,
  md: 6,
  
  // 顯示條件
  show_condition: {
    field: 'main_category',
    operator: 'equals',
    value: 'H'
  },
  
  // 驗證規則（在 validation_rules 欄位中）
  validation_rules: {
    min: 0,
    max: 100,
    pattern: '^[A-Z]+$',
    patternMessage: '只能輸入大寫字母'
  },
  
  // 其他設定
  placeholder: '請輸入...',
  unit: 'mm',
  step: 1,
  accept: 'image/*',
  multiple: false
}
```

### show_condition 運算子

- `equals` - 等於
- `notEquals` - 不等於
- `contains` - 包含（用於陣列）
- `notContains` - 不包含（用於陣列）
- `isEmpty` - 為空
- `isNotEmpty` - 不為空

## 樣式自訂

組件使用與 `MaterialApplicationForm.vue` 相同的樣式：

- `.form-section` - 表單區塊樣式
- 必填欄位的紅色星號樣式
- Vuetify 3 的預設樣式

可以透過覆蓋這些樣式來自訂外觀。

## 注意事項

1. **欄位選項載入**: 目前 `loadFieldOptions` 方法需要根據實際需求實作，可以整合現有的 API 服務（如 `systemOptionsService`, `categoriesService` 等）。

2. **檔案上傳**: `FileField` 組件中的 `uploadFile` 方法需要實作實際的檔案上傳邏輯。

3. **條件顯示**: `show_condition` 目前支援簡單的條件判斷，複雜條件可以透過函數方式實作。

4. **驗證規則**: 所有欄位組件都支援 Vuetify 的驗證規則，可以透過 `validation_rules` 欄位設定。

5. **向後相容**: 這些組件與現有的 `MaterialApplicationForm.vue` 完全相容，可以並存使用。
