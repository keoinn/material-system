-- ============================================================================
-- 移除所有資料表結構的 SQL 語句
-- ============================================================================
-- 注意：此腳本會刪除所有資料表、觸發器和函數
-- 執行前請確認已備份重要資料和結構
-- 
-- 此腳本僅移除保留的資料表：
-- - code_counters, export_logs, attachments, form_data_values, 
-- - form_fields, forms, system_options, system_settings, user_profiles
-- ============================================================================

-- 1. 刪除所有觸發器（按照表順序）
-- 1.1 刪除表單相關觸發器
DROP TRIGGER IF EXISTS update_form_data_values_updated_at ON form_data_values;
DROP TRIGGER IF EXISTS update_form_fields_updated_at ON form_fields;
DROP TRIGGER IF EXISTS update_forms_updated_at ON forms;

-- 1.2 刪除其他表觸發器
DROP TRIGGER IF EXISTS update_code_counters_updated_at ON code_counters;
DROP TRIGGER IF EXISTS update_system_options_updated_at ON system_options;
DROP TRIGGER IF EXISTS update_system_settings_updated_at ON system_settings;
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;

-- 1.3 刪除 auth.users 上的觸發器
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. 刪除所有資料表（按照外鍵依賴順序，先刪除子表，再刪除父表）
-- 2.1 刪除表單資料值表（最底層，依賴 form_fields 和 forms）
DROP TABLE IF EXISTS form_data_values CASCADE;

-- 2.2 刪除附件表（可能關聯到表單記錄）
DROP TABLE IF EXISTS attachments CASCADE;

-- 2.3 刪除表單欄位定義表（依賴 forms）
DROP TABLE IF EXISTS form_fields CASCADE;

-- 2.4 刪除表單定義表
DROP TABLE IF EXISTS forms CASCADE;

-- 2.5 刪除編碼計數器表（依賴 user_profiles）
DROP TABLE IF EXISTS code_counters CASCADE;

-- 2.6 刪除匯出記錄表（依賴 user_profiles）
DROP TABLE IF EXISTS export_logs CASCADE;

-- 2.7 刪除系統選項表
DROP TABLE IF EXISTS system_options CASCADE;

-- 2.8 刪除系統設定表
DROP TABLE IF EXISTS system_settings CASCADE;

-- 2.9 刪除使用者資料表（注意：此表關聯到 auth.users，但我們只刪除應用程式層面的表）
-- 注意：刪除 user_profiles 前，需先刪除依賴它的表（code_counters, export_logs）
DROP TABLE IF EXISTS user_profiles CASCADE;

-- 3. 刪除函數
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- ============================================================================
-- 驗證刪除結果（可選）
-- ============================================================================
-- 查詢所有剩餘的資料表（應該只剩下 Supabase 系統表）
-- SELECT table_name 
-- FROM information_schema.tables 
-- WHERE table_schema = 'public' 
-- ORDER BY table_name;