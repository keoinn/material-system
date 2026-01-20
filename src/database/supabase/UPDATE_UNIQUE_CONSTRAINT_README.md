# 更新 form_data_values 唯一約束說明

## 問題描述

當保存 `cascading_select`（多層式下拉選單）欄位時，每個層級的值需要分別保存到對應的 `field_key`。但如果多個層級使用同一個主欄位的 `field_id`，會違反現有的唯一約束 `UNIQUE(form_id, field_id, record_id)`。

## 解決方案

將唯一約束從 `UNIQUE(form_id, field_id, record_id)` 更新為 `UNIQUE(form_id, field_id, record_id, field_key)`，這樣可以允許同一個 `field_id` 在同一個 `record_id` 下有多筆記錄，只要 `field_key` 不同。

## 執行步驟

### 步驟 1：在 Supabase Dashboard 中執行 SQL

1. 登入 Supabase Dashboard
2. 進入 **SQL Editor**
3. 複製 `update_form_data_values_unique_constraint.sql` 文件的全部內容
4. 貼上到 SQL Editor
5. 點擊 **Run** 執行

### 步驟 2：驗證約束已更新

執行以下 SQL 查詢來驗證約束已正確更新：

```sql
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'form_data_values'::regclass 
AND contype = 'u';
```

應該會看到新的約束：
- 約束名稱：`form_data_values_form_id_field_id_record_id_field_key_key`
- 約束定義：`UNIQUE (form_id, field_id, record_id, field_key)`

### 步驟 3：測試

執行更新後，嘗試提交包含 `cascading_select` 欄位的表單，應該可以正常保存了。

## 注意事項

- 此更新不會影響現有資料
- 如果執行時出現錯誤，請檢查是否有其他約束衝突
- 建議在執行前先備份資料庫
