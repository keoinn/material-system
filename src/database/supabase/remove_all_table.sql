-- ============================================================================
-- 移除所有資料表結構的 SQL 語句
-- ============================================================================
-- 注意：此腳本會刪除所有資料表、觸發器和函數
-- 執行前請確認已備份重要資料和結構
-- ============================================================================

-- 1. 刪除所有觸發器
DROP TRIGGER IF EXISTS update_product_categories_updated_at ON product_categories;
DROP TRIGGER IF EXISTS update_suppliers_updated_at ON suppliers;
DROP TRIGGER IF EXISTS update_packaging_categories_updated_at ON packaging_categories;
DROP TRIGGER IF EXISTS update_packaging_options_updated_at ON packaging_options;
DROP TRIGGER IF EXISTS update_category_packaging_defaults_updated_at ON category_packaging_defaults;
DROP TRIGGER IF EXISTS update_system_options_updated_at ON system_options;
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
DROP TRIGGER IF EXISTS update_applications_updated_at ON applications;
DROP TRIGGER IF EXISTS update_code_counters_updated_at ON code_counters;
DROP TRIGGER IF EXISTS update_drafts_last_modified_at ON drafts;
DROP TRIGGER IF EXISTS update_system_settings_updated_at ON system_settings;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. 刪除所有資料表（按照外鍵依賴順序，先刪除子表，再刪除父表）
-- 2.1 刪除申請相關的子表
DROP TABLE IF EXISTS application_packaging CASCADE;
DROP TABLE IF EXISTS attachments CASCADE;
DROP TABLE IF EXISTS approval_logs CASCADE;

-- 2.2 刪除申請主表
DROP TABLE IF EXISTS applications CASCADE;

-- 2.3 刪除類別預設包裝表
DROP TABLE IF EXISTS category_packaging_defaults CASCADE;

-- 2.4 刪除包裝選項表
DROP TABLE IF EXISTS packaging_options CASCADE;

-- 2.5 刪除包裝類別表
DROP TABLE IF EXISTS packaging_categories CASCADE;

-- 2.6 刪除編碼計數器表
DROP TABLE IF EXISTS code_counters CASCADE;

-- 2.7 刪除匯出記錄表
DROP TABLE IF EXISTS export_logs CASCADE;

-- 2.8 刪除草稿表
DROP TABLE IF EXISTS drafts CASCADE;

-- 2.9 刪除系統設定表
DROP TABLE IF EXISTS system_settings CASCADE;

-- 2.10 刪除使用者資料表（注意：此表關聯到 auth.users，但我們只刪除應用程式層面的表）
DROP TABLE IF EXISTS user_profiles CASCADE;

-- 2.11 刪除產品分類表（有自引用，使用 CASCADE 自動處理）
DROP TABLE IF EXISTS product_categories CASCADE;

-- 2.12 刪除供應商表
DROP TABLE IF EXISTS suppliers CASCADE;

-- 2.13 刪除系統選項表
DROP TABLE IF EXISTS system_options CASCADE;

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