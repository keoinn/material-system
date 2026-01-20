# 動態表單系統資料庫結構說明

## 概述

此資料庫結構用於支援動態表單系統，允許系統管理員透過資料庫定義表單結構，而不需要修改程式碼。系統包含三個主要資料表：

1. **forms** - 表單定義主表
2. **form_fields** - 表單欄位定義表
3. **form_data_values** - 表單資料值表

## 資料表結構

### 1. forms（表單定義主表）

儲存表單的基本定義資訊。

**主要欄位：**
- `id` - 主鍵
- `form_code` - 表單代碼（唯一識別碼，例如：material_application）
- `form_name` - 表單名稱（中文）
- `form_name_en` - 表單名稱（英文）
- `description` - 表單說明
- `version` - 表單版本號
- `is_active` - 是否啟用
- `is_default` - 是否為預設表單
- `form_config` - 表單級別的額外設定（JSON格式）

### 2. form_fields（表單欄位定義表）

儲存表單的欄位定義資訊。

**主要欄位：**
- `id` - 主鍵
- `form_id` - 所屬表單（外鍵）
- `field_key` - 欄位鍵值（例如：item_name_cn）
- `field_label` - 欄位標籤（顯示名稱）
- `field_type` - 欄位類型（見下方說明）
- `max_length` - 字元長度限制（用於計算版面大小）
- `is_required` - 是否必填
- `field_group` - 欄位群組（用於分組顯示）
- `display_order` - 顯示順序
- `field_config` - 欄位額外設定（JSON格式，儲存選項、驗證規則等）
- `default_value` - 預設值
- `validation_rules` - 驗證規則（JSON格式）
- `is_visible` - 是否顯示
- `is_readonly` - 是否唯讀

**支援的欄位類型：**
- `text` - 文字輸入框
- `textarea` - 多行文字輸入框
- `number` - 數字輸入框
- `select` - 下拉選單（單選）
- `multiselect` - 多選下拉選單
- `checkbox` - 複選框
- `radio` - 單選框
- `date` - 日期選擇器
- `datetime` - 日期時間選擇器
- `file` - 檔案上傳
- `json` - JSON資料

### 3. form_data_values（表單資料值表）

儲存動態欄位的實際資料值。

**主要欄位：**
- `id` - 主鍵
- `form_id` - 所屬表單（外鍵）
- `field_id` - 所屬欄位（外鍵）
- `record_id` - 記錄ID（可關聯到其他表的記錄，例如：application_id）
- `field_key` - 欄位鍵值（冗余，用於快速查詢）
- `field_value` - 欄位值（文字類型）
- `field_value_json` - 欄位值（JSON類型，用於複雜資料）
- `field_value_number` - 欄位值（數字類型）
- `field_value_date` - 欄位值（日期類型）
- `field_value_datetime` - 欄位值（日期時間類型）
- `file_url` - 檔案URL（檔案類型用）

## 安裝步驟

### 步驟 1：執行表單結構腳本

首先執行 `dynamic_forms_schema.sql` 來建立資料表結構：

```sql
-- 在 Supabase SQL Editor 中執行
\i src/database/supabase/dynamic_forms_schema.sql
```

或在 Supabase Dashboard 的 SQL Editor 中直接貼上並執行腳本內容。

此腳本會：
1. 建立三個主要資料表
2. 建立必要的索引和約束
3. 建立更新時間的自動更新觸發器
4. 插入預設的物料申請表單定義

### 步驟 2：執行遷移腳本（可選）

如果您有現有的 `applications` 表資料需要遷移到動態表單系統，執行 `migrate_applications_to_dynamic_forms.sql`：

```sql
-- 在 Supabase SQL Editor 中執行
\i src/database/supabase/migrate_applications_to_dynamic_forms.sql
```

**注意事項：**
- 執行前請先備份資料庫
- 建議在測試環境先執行測試
- 此遷移為單向操作，不會刪除原有的 `applications` 表資料
- 遷移後，原有的 `applications` 表仍然存在，可以繼續使用

## 使用範例

### 查詢表單定義及其欄位

```sql
SELECT 
  f.form_code,
  f.form_name,
  ff.field_key,
  ff.field_label,
  ff.field_type,
  ff.field_group,
  ff.display_order,
  ff.field_config
FROM forms f
LEFT JOIN form_fields ff ON f.id = ff.form_id
WHERE f.form_code = 'material_application'
ORDER BY ff.display_order;
```

### 查詢表單資料值

```sql
SELECT 
  fdv.record_id,
  ff.field_key,
  ff.field_label,
  ff.field_type,
  fdv.field_value,
  fdv.field_value_json,
  fdv.field_value_number,
  fdv.field_value_date,
  fdv.field_value_datetime
FROM form_data_values fdv
JOIN form_fields ff ON fdv.field_id = ff.id
WHERE fdv.form_id = (SELECT id FROM forms WHERE form_code = 'material_application')
  AND fdv.record_id = 123
ORDER BY ff.display_order;
```

### 查詢完整表單資料（含欄位定義和值）

```sql
SELECT 
  f.form_code,
  f.form_name,
  ff.field_key,
  ff.field_label,
  ff.field_type,
  ff.field_group,
  ff.display_order,
  fdv.field_value,
  fdv.field_value_json,
  fdv.field_value_number,
  fdv.field_value_date,
  fdv.field_value_datetime
FROM forms f
JOIN form_fields ff ON f.id = ff.form_id
LEFT JOIN form_data_values fdv ON ff.id = fdv.field_id AND fdv.record_id = 123
WHERE f.form_code = 'material_application'
ORDER BY ff.display_order;
```

## 欄位設定說明

### field_config（欄位設定）

`field_config` 欄位使用 JSON 格式儲存欄位的額外設定，常見的設定包括：

```json
{
  "source": "product_categories",
  "filter": {"level": 1},
  "dependsOn": "main_category_id",
  "readonly": true,
  "autoGenerate": true,
  "options": [
    {"value": "H", "label": "Handle"},
    {"value": "S", "label": "Slide"}
  ],
  "min": 0,
  "max": 100,
  "pattern": "^[A-Z]+$",
  "unit": "mm",
  "precision": 2
}
```

**常用設定說明：**
- `source` - 資料來源（例如：product_categories, system_options, suppliers）
- `filter` - 過濾條件（JSON格式）
- `dependsOn` - 依賴的欄位（用於動態載入選項）
- `readonly` - 是否唯讀
- `autoGenerate` - 是否自動產生（例如：料號）
- `options` - 選項列表（用於 select, radio, checkbox）
- `min` / `max` - 數值範圍（用於 number 類型）
- `pattern` - 正則表達式驗證（用於 text 類型）
- `unit` - 單位（例如：mm, kg）
- `precision` - 小數位數（用於 number 類型）

### validation_rules（驗證規則）

`validation_rules` 欄位使用 JSON 格式儲存驗證規則：

```json
{
  "required": true,
  "min": 0,
  "max": 100,
  "minLength": 1,
  "maxLength": 255,
  "pattern": "^[A-Z]+$",
  "custom": "function_name"
}
```

## 擴展說明

### 新增表單

要新增一個新的表單，需要：

1. 在 `forms` 表中插入表單定義
2. 在 `form_fields` 表中插入欄位定義

範例：

```sql
-- 插入表單定義
INSERT INTO forms (form_code, form_name, form_name_en, description, is_default, form_config)
VALUES ('new_form', '新表單', 'New Form', '新表單說明', FALSE, '{"version": 1}');

-- 取得表單ID
SELECT id INTO v_form_id FROM forms WHERE form_code = 'new_form';

-- 插入欄位定義
INSERT INTO form_fields (form_id, field_key, field_label, field_type, max_length, is_required, field_group, display_order)
VALUES 
  (v_form_id, 'field1', '欄位1', 'text', 100, TRUE, '基本資訊', 1),
  (v_form_id, 'field2', '欄位2', 'number', NULL, FALSE, '基本資訊', 2);
```

### 修改表單結構

要修改表單結構，可以直接更新 `form_fields` 表的記錄：

```sql
-- 更新欄位標籤
UPDATE form_fields 
SET field_label = '新標籤', updated_at = NOW()
WHERE form_id = (SELECT id FROM forms WHERE form_code = 'material_application')
  AND field_key = 'item_name_cn';

-- 新增欄位
INSERT INTO form_fields (form_id, field_key, field_label, field_type, max_length, is_required, field_group, display_order)
VALUES (
  (SELECT id FROM forms WHERE form_code = 'material_application'),
  'new_field',
  '新欄位',
  'text',
  255,
  FALSE,
  '其他資訊',
  200
);
```

## 注意事項

1. **資料完整性**：`form_data_values` 表使用 `(form_id, field_id, record_id)` 作為唯一約束，確保同一記錄的同一欄位只有一筆資料。

2. **效能考量**：查詢表單資料時，建議使用適當的索引。系統已建立以下索引：
   - `form_id` 和 `record_id` 的複合索引
   - `field_id` 索引
   - `field_key` 索引

3. **版本控制**：表單定義支援版本控制，可以透過 `version` 欄位追蹤表單結構的變更。

4. **資料遷移**：遷移腳本會將現有的 `applications` 表資料對應到新的動態表單系統，但不會刪除原有資料。

5. **向後相容**：原有的 `applications` 表仍然存在，可以繼續使用。新系統和舊系統可以並存。

## 相關檔案

- `dynamic_forms_schema.sql` - 表單結構定義腳本
- `migrate_applications_to_dynamic_forms.sql` - 遷移腳本
- `supabase_schema.sql` - 原始資料庫結構（包含 applications 表）
