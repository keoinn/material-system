-- ============================================================================
-- 移除所有資料表結構的 SQL 語句
-- ============================================================================
-- 注意：此腳本會刪除所有應用程式資料表、視圖、觸發器和函數
-- 執行前請確認已備份重要資料和結構
--
-- 涵蓋全部 23 張資料表（與 supabase_schema_master.sql 一致）
-- ============================================================================

-- 1. 刪除視圖
DROP VIEW IF EXISTS pending_approval_applications_view CASCADE;
DROP VIEW IF EXISTS pending_applications_view CASCADE;

-- 2. 刪除 auth.users 上的觸發器
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 3. 刪除所有資料表（按照外鍵依賴順序，先刪除子表，再刪除父表）

-- 3.1 審核流程（子表 → 父表）
DROP TABLE IF EXISTS approval_action_logs CASCADE;
DROP TABLE IF EXISTS approval_records CASCADE;
DROP TABLE IF EXISTS approval_workflow_steps CASCADE;
DROP TABLE IF EXISTS approval_workflows CASCADE;
DROP TABLE IF EXISTS approval_statuses CASCADE;

-- 3.2 角色權限
DROP TABLE IF EXISTS role_page_access CASCADE;
DROP TABLE IF EXISTS role_permissions CASCADE;

-- 3.3 選項活頁簿
DROP TABLE IF EXISTS option_workbook_rows CASCADE;
DROP TABLE IF EXISTS option_workbook_columns CASCADE;
DROP TABLE IF EXISTS option_workbooks CASCADE;

-- 3.4 包裝模板
DROP TABLE IF EXISTS packaging_templates CASCADE;

-- 3.5 表單與資料
DROP TABLE IF EXISTS form_data_values CASCADE;
DROP TABLE IF EXISTS attachments CASCADE;
DROP TABLE IF EXISTS form_fields CASCADE;
DROP TABLE IF EXISTS forms CASCADE;

-- 3.6 部門（依賴 user_profiles，含自引用 parent_id）
DROP TABLE IF EXISTS departments CASCADE;

-- 3.7 其他依賴 user_profiles 的表
DROP TABLE IF EXISTS code_counters CASCADE;
DROP TABLE IF EXISTS export_logs CASCADE;

-- 3.8 角色與權限主表
DROP TABLE IF EXISTS permissions CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- 3.9 系統表
DROP TABLE IF EXISTS system_options CASCADE;
DROP TABLE IF EXISTS system_settings CASCADE;

-- 3.10 使用者資料表
DROP TABLE IF EXISTS user_profiles CASCADE;

-- 4. 刪除舊版/已棄用資料表（若仍存在）
DROP TABLE IF EXISTS application_packaging CASCADE;
DROP TABLE IF EXISTS approval_logs CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS drafts CASCADE;
DROP TABLE IF EXISTS category_packaging_defaults CASCADE;
DROP TABLE IF EXISTS packaging_options CASCADE;
DROP TABLE IF EXISTS packaging_categories CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;

-- 5. 刪除函數
DROP FUNCTION IF EXISTS public.get_users_with_email(VARCHAR, BOOLEAN, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.get_current_approvers(BIGINT) CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.sync_user_profiles_email() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- ============================================================================
-- 驗證刪除結果（可選）
-- ============================================================================
-- SELECT table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'public'
-- ORDER BY table_name;
