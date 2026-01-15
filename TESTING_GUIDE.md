# 動態表單系統測試指南

## 測試前準備

### 1. 資料庫設置

#### 步驟 1：執行資料庫結構腳本

在 Supabase Dashboard 的 SQL Editor 中執行：

```sql
-- 執行表單結構腳本
\i src/database/supabase/dynamic_forms_schema.sql
```

或直接在 SQL Editor 中貼上 `src/database/supabase/dynamic_forms_schema.sql` 的內容並執行。

這個腳本會：
- 建立 `forms`、`form_fields`、`form_data_values` 三個資料表
- 建立必要的索引和約束
- 插入預設的物料申請表單定義

#### 步驟 2：（可選）執行遷移腳本

如果您有現有的 `applications` 表資料需要遷移：

```sql
-- 執行遷移腳本
\i src/database/supabase/migrate_applications_to_dynamic_forms.sql
```

**注意**：執行前請先備份資料庫！

### 2. 確認環境變數

確認 `.env` 或環境變數中已設定 Supabase 連線資訊：

```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. 啟動開發伺服器

```bash
npm run dev
```

## 測試流程

### 階段一：表單管理功能測試

#### 測試 1：訪問表單管理頁面

1. 登入系統（需要管理員權限）
2. 訪問 `/forms` 頁面
3. 應該看到：
   - 表單列表（如果有已建立的表單）
   - 「建立新表單」按鈕
   - 每個表單的操作按鈕（編輯、複製、刪除）

**預期結果**：
- 頁面正常載入
- 可以看到表單列表或空狀態提示

#### 測試 2：建立新表單

1. 點擊「建立新表單」按鈕
2. 填寫表單基本資訊：
   - 表單代碼：`test_form`
   - 表單名稱（中文）：`測試表單`
   - 表單名稱（英文）：`Test Form`
   - 表單說明：`這是一個測試表單`
   - 啟用：勾選
3. 切換到「欄位設定」標籤
4. 點擊「新增欄位」

**預期結果**：
- 表單設計器對話框正常開啟
- 可以填寫表單基本資訊
- 可以切換到欄位設定標籤

#### 測試 3：新增欄位

1. 在欄位編輯對話框中填寫：
   - 欄位鍵值：`name`
   - 欄位類型：選擇「文字」
   - 欄位標籤（中文）：`名稱`
   - 欄位標籤（英文）：`Name`
   - 字元長度：`100`
   - 必填：勾選
   - 群組名稱：`基本資訊`
   - 顯示順序：`1`
2. 點擊「儲存」

**預期結果**：
- 欄位成功新增到列表
- 欄位顯示正確的資訊（標籤、類型、必填標記等）

#### 測試 4：新增多種類型欄位

重複測試 3，建立以下欄位：

| 欄位鍵值 | 類型 | 標籤 | 必填 | 群組 | 順序 |
|---------|------|------|------|------|------|
| `name` | text | 名稱 | ✓ | 基本資訊 | 1 |
| `description` | textarea | 說明 | - | 基本資訊 | 2 |
| `age` | number | 年齡 | - | 基本資訊 | 3 |
| `status` | select | 狀態 | ✓ | 基本資訊 | 4 |
| `tags` | multiselect | 標籤 | - | 基本資訊 | 5 |
| `birthday` | date | 生日 | - | 基本資訊 | 6 |

對於 `status` 欄位，在「選項設定」中新增：
- 值：`active`，標籤：`啟用`
- 值：`inactive`，標籤：`停用`

對於 `tags` 欄位，在「選項設定」中新增：
- 值：`tag1`，標籤：`標籤1`
- 值：`tag2`，標籤：`標籤2`

**預期結果**：
- 所有欄位成功新增
- 欄位按順序顯示
- 選項正確設定

#### 測試 5：欄位排序

1. 使用上下按鈕調整欄位順序
2. 觀察順序變化

**預期結果**：
- 欄位順序可以調整
- 顯示順序數字正確更新

#### 測試 6：編輯欄位

1. 點擊欄位列表中的「編輯」按鈕
2. 修改欄位屬性（例如：修改標籤、取消必填）
3. 點擊「儲存」

**預期結果**：
- 欄位資訊正確載入
- 修改後正確保存
- 列表顯示更新後的資訊

#### 測試 7：刪除欄位

1. 點擊欄位列表中的「刪除」按鈕
2. 確認刪除

**預期結果**：
- 欄位從列表中移除
- 其他欄位的順序自動調整

#### 測試 8：表單預覽

1. 切換到「預覽」標籤
2. 觀察表單渲染效果
3. 測試欄位互動（輸入、選擇等）

**預期結果**：
- 表單正確渲染
- 所有欄位正常顯示
- 欄位互動正常
- 必填欄位有紅色星號
- 群組正確分類

#### 測試 9：儲存表單

1. 切換回「基本資訊」或「欄位設定」標籤
2. 點擊「儲存表單」按鈕
3. 觀察儲存結果

**預期結果**：
- 表單成功儲存
- 顯示成功訊息
- 表單設計器關閉
- 表單列表更新

### 階段二：動態表單渲染測試

#### 測試 10：使用動態表單渲染器

建立一個測試頁面或修改現有頁面來測試 `DynamicFormRenderer`：

```vue
<template>
  <DynamicFormRenderer
    ref="formRef"
    form-id="test_form"
    @submit="handleSubmit"
  />
</template>

<script setup>
import { ref } from 'vue'
import DynamicFormRenderer from '@/components/DynamicFormRenderer.vue'
import { formDataService } from '@/api/services/formData'

const formRef = ref(null)

async function handleSubmit (formValues) {
  console.log('表單值:', formValues)
  // 儲存表單資料
  await formDataService.createFormData('test_form', formValues, {
    createRecord: true,
    recordId: Date.now()
  })
}
</script>
```

**預期結果**：
- 表單正確載入並渲染
- 所有欄位正常顯示
- 可以正常輸入和選擇
- 提交時可以取得表單值

#### 測試 11：表單驗證

1. 在動態表單中測試必填欄位驗證
2. 嘗試提交空表單
3. 填寫必填欄位後再次提交

**預期結果**：
- 必填欄位驗證正常
- 空表單無法提交
- 填寫必填欄位後可以提交

#### 測試 12：不同欄位類型測試

測試各種欄位類型的互動：

- **文字欄位**：輸入文字，測試最大長度限制
- **多行文字**：輸入多行文字
- **數字欄位**：輸入數字，測試最小值/最大值
- **下拉選單**：選擇選項
- **多選下拉**：選擇多個選項
- **日期**：選擇日期
- **日期時間**：選擇日期和時間

**預期結果**：
- 所有欄位類型正常運作
- 驗證規則正確執行
- 資料格式正確

### 階段三：API 服務測試

#### 測試 13：表單定義 API

在瀏覽器控制台測試：

```javascript
import { formsService } from '@/api/services/forms'

// 取得所有表單
const forms = await formsService.getForms()
console.log('表單列表:', forms)

// 取得單一表單
const form = await formsService.getForm('test_form', true)
console.log('表單定義:', form)
```

**預期結果**：
- API 正常運作
- 返回正確的資料格式

#### 測試 14：欄位定義 API

```javascript
import { formFieldsService } from '@/api/services/formFields'

// 取得表單的所有欄位
const fields = await formFieldsService.getFields('test_form')
console.log('欄位列表:', fields)

// 取得單一欄位
const field = await formFieldsService.getField('test_form', 'name')
console.log('欄位定義:', field)
```

**預期結果**：
- API 正常運作
- 返回正確的欄位資料

#### 測試 15：表單資料 API

```javascript
import { formDataService } from '@/api/services/formData'

// 建立表單資料
const formData = await formDataService.createFormData('test_form', {
  name: '測試名稱',
  description: '測試說明',
  age: 25,
  status: 'active',
  tags: ['tag1', 'tag2'],
  birthday: '2024-01-01'
}, {
  createRecord: true,
  recordId: 1001
})
console.log('建立的資料:', formData)

// 取得表單資料
const data = await formDataService.getFormData('test_form', 1001)
console.log('取得的資料:', data)

// 更新表單資料
await formDataService.updateFormData('test_form', 1001, {
  name: '更新後的名稱'
})
```

**預期結果**：
- 資料正確建立
- 資料正確讀取
- 資料正確更新

### 階段四：整合測試

#### 測試 16：完整流程測試

1. **建立表單**：使用表單設計器建立一個完整的表單
2. **填寫表單**：使用動態表單渲染器填寫表單
3. **儲存資料**：提交表單資料
4. **查詢資料**：查詢已儲存的表單資料
5. **編輯資料**：編輯已儲存的表單資料

**預期結果**：
- 整個流程順暢
- 資料正確儲存和讀取
- 沒有錯誤訊息

#### 測試 17：編輯模式測試

1. 建立表單資料（recordId = 1001）
2. 使用 `DynamicFormRenderer` 載入已存在的資料：

```vue
<DynamicFormRenderer
  form-id="test_form"
  :record-id="1001"
  @submit="handleUpdate"
/>
```

**預期結果**：
- 表單正確載入現有資料
- 可以修改資料
- 更新後資料正確保存

## 常見問題排查

### 問題 1：表單設計器無法開啟

**可能原因**：
- 路由未正確設定
- 組件未正確導入

**解決方法**：
- 確認 `pages/forms.vue` 存在
- 確認 `FormDesigner` 組件正確導入
- 檢查瀏覽器控制台錯誤訊息

### 問題 2：表單無法儲存

**可能原因**：
- 資料庫連線問題
- 表單代碼重複
- 欄位鍵值重複

**解決方法**：
- 檢查 Supabase 連線設定
- 確認表單代碼唯一
- 確認欄位鍵值在同一表單內唯一
- 檢查瀏覽器控制台錯誤訊息

### 問題 3：表單無法載入

**可能原因**：
- 表單不存在
- API 服務錯誤
- 資料格式問題

**解決方法**：
- 確認表單 ID 或 form_code 正確
- 檢查 API 服務是否正常運作
- 檢查資料庫中是否有對應的表單定義

### 問題 4：欄位無法顯示

**可能原因**：
- 欄位組件未正確導入
- 欄位類型不支援
- 欄位設定錯誤

**解決方法**：
- 確認所有欄位組件檔案存在
- 檢查欄位類型是否在支援列表中
- 檢查欄位設定是否正確

### 問題 5：預覽功能無法使用

**可能原因**：
- 欄位組件未正確導入
- 預覽邏輯錯誤

**解決方法**：
- 確認所有欄位組件已導入
- 檢查預覽相關的 computed 屬性
- 查看瀏覽器控制台錯誤訊息

## 測試檢查清單

- [ ] 資料庫結構已建立
- [ ] 表單管理頁面可以訪問
- [ ] 可以建立新表單
- [ ] 可以新增欄位
- [ ] 可以編輯欄位
- [ ] 可以刪除欄位
- [ ] 可以調整欄位順序
- [ ] 預覽功能正常
- [ ] 表單可以儲存
- [ ] 動態表單渲染器正常運作
- [ ] 所有欄位類型正常顯示
- [ ] 表單驗證正常
- [ ] API 服務正常運作
- [ ] 可以建立表單資料
- [ ] 可以讀取表單資料
- [ ] 可以更新表單資料
- [ ] 編輯模式正常運作

## 下一步

測試完成後，您可以：

1. **整合到現有系統**：將動態表單系統整合到現有的物料申請流程中
2. **擴展功能**：根據需求新增更多欄位類型或功能
3. **優化效能**：針對大量欄位的表單進行效能優化
4. **使用者體驗**：根據實際使用情況調整 UI/UX

## 需要幫助？

如果遇到問題，請檢查：

1. 瀏覽器控制台的錯誤訊息
2. Supabase Dashboard 的日誌
3. 網路請求的狀態碼和回應
4. 資料庫中的實際資料

祝測試順利！🎉
