-- ============================================================================
-- 更新 form_data_values 表的唯一約束
-- ============================================================================
-- 將唯一約束從 (form_id, field_id, record_id) 改為 (form_id, field_id, record_id, field_key)
-- 這樣可以允許同一個 field_id 在同一個 record_id 下有多筆記錄，只要 field_key 不同
-- 這對於 cascading_select 欄位的層級值保存是必要的

-- 1. 先查詢現有的唯一約束名稱（用於確認）
-- SELECT conname, pg_get_constraintdef(oid) 
-- FROM pg_constraint 
-- WHERE conrelid = 'form_data_values'::regclass 
-- AND contype = 'u';

-- 2. 刪除舊的唯一約束（嘗試所有可能的約束名稱）
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- 查找所有唯一約束
    FOR constraint_name IN 
        SELECT conname 
        FROM pg_constraint 
        WHERE conrelid = 'form_data_values'::regclass 
        AND contype = 'u'
        AND (
            pg_get_constraintdef(oid) LIKE '%form_id%field_id%record_id%'
            AND pg_get_constraintdef(oid) NOT LIKE '%field_key%'
        )
    LOOP
        EXECUTE format('ALTER TABLE form_data_values DROP CONSTRAINT IF EXISTS %I', constraint_name);
        RAISE NOTICE '已刪除約束: %', constraint_name;
    END LOOP;
END $$;

-- 3. 創建新的唯一約束（包含 field_key）
ALTER TABLE form_data_values
ADD CONSTRAINT form_data_values_form_id_field_id_record_id_field_key_key
UNIQUE (form_id, field_id, record_id, field_key);

-- 4. 添加註釋
COMMENT ON CONSTRAINT form_data_values_form_id_field_id_record_id_field_key_key ON form_data_values IS 
'唯一約束：同一表單、同一記錄、同一欄位、同一欄位鍵值只能有一筆資料（允許同一個 field_id 有多筆記錄，只要 field_key 不同）';

-- 5. 驗證約束已創建
-- SELECT conname, pg_get_constraintdef(oid) 
-- FROM pg_constraint 
-- WHERE conrelid = 'form_data_values'::regclass 
-- AND contype = 'u';
