-- ============================================================================
-- 移除所有資料的 SQL 語句
-- ============================================================================
-- 注意：此腳本會刪除所有資料，但保留資料表結構
-- 執行前請確認已備份重要資料
-- 
-- 此腳本僅清空保留的資料表：
-- - code_counters, export_logs, attachments, form_data_values, 
-- - form_fields, forms, system_options, system_settings, user_profiles
-- ============================================================================

-- 1. 刪除所有子表資料（按照外鍵依賴順序，先刪除子表）
-- 1.1 刪除表單資料值（最底層，依賴 form_fields 和 forms）
DELETE FROM form_data_values;

-- 1.2 刪除附件（可能關聯到表單記錄）
DELETE FROM attachments;

-- 1.3 刪除表單欄位定義（依賴 forms）
DELETE FROM form_fields;

-- 1.4 刪除表單定義
DELETE FROM forms;

-- 1.5 刪除編碼計數器（依賴 user_profiles）
DELETE FROM code_counters;

-- 1.6 刪除匯出記錄（依賴 user_profiles）
DELETE FROM export_logs;

-- 2. 刪除父表資料
-- 2.1 刪除系統選項資料
DELETE FROM system_options;

-- 2.2 刪除系統設定資料
DELETE FROM system_settings;

-- 2.3 刪除使用者資料（注意：此表關聯到 auth.users，只刪除應用程式層面的資料）
-- 注意：刪除 user_profiles 前，需先刪除依賴它的表（code_counters, export_logs）
DELETE FROM user_profiles;

-- ============================================================================
-- 重置序列（可選，如果需要重置 ID 計數器）
-- ============================================================================
-- 注意：如果資料表使用 BIGSERIAL，刪除資料後序列不會自動重置
-- 如果需要重置序列，可以執行以下語句：

-- ALTER SEQUENCE code_counters_id_seq RESTART WITH 1;
-- ALTER SEQUENCE export_logs_id_seq RESTART WITH 1;
-- ALTER SEQUENCE attachments_id_seq RESTART WITH 1;
-- ALTER SEQUENCE form_data_values_id_seq RESTART WITH 1;
-- ALTER SEQUENCE form_fields_id_seq RESTART WITH 1;
-- ALTER SEQUENCE forms_id_seq RESTART WITH 1;
-- ALTER SEQUENCE system_options_id_seq RESTART WITH 1;
-- ALTER SEQUENCE system_settings_id_seq RESTART WITH 1;

-- ============================================================================
-- 驗證刪除結果（可選）
-- ============================================================================
-- SELECT 'code_counters' AS table_name, COUNT(*) AS count FROM code_counters
-- UNION ALL
-- SELECT 'export_logs', COUNT(*) FROM export_logs
-- UNION ALL
-- SELECT 'attachments', COUNT(*) FROM attachments
-- UNION ALL
-- SELECT 'form_data_values', COUNT(*) FROM form_data_values
-- UNION ALL
-- SELECT 'form_fields', COUNT(*) FROM form_fields
-- UNION ALL
-- SELECT 'forms', COUNT(*) FROM forms
-- UNION ALL
-- SELECT 'system_options', COUNT(*) FROM system_options
-- UNION ALL
-- SELECT 'system_settings', COUNT(*) FROM system_settings
-- UNION ALL
-- SELECT 'user_profiles', COUNT(*) FROM user_profiles;