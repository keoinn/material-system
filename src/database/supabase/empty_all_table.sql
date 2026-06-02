-- ============================================================================
-- 移除所有資料的 SQL 語句
-- ============================================================================
-- 注意：此腳本會刪除所有資料，但保留資料表結構
-- 執行前請確認已備份重要資料
--
-- 涵蓋全部 23 張資料表（與 supabase_schema_master.sql 一致）
-- ============================================================================

-- 1. 刪除所有子表資料（按照外鍵依賴順序，先刪除子表）

-- 1.1 審核流程
DELETE FROM approval_action_logs;
DELETE FROM approval_records;
DELETE FROM approval_workflow_steps;
DELETE FROM approval_workflows;
DELETE FROM approval_statuses;

-- 1.2 角色權限
DELETE FROM role_page_access;
DELETE FROM role_permissions;

-- 1.3 選項活頁簿
DELETE FROM option_workbook_rows;
DELETE FROM option_workbook_columns;
DELETE FROM option_workbooks;

-- 1.4 包裝模板
DELETE FROM packaging_templates;

-- 1.5 表單與資料
DELETE FROM form_data_values;
DELETE FROM attachments;
DELETE FROM form_fields;
DELETE FROM forms;

-- 1.6 部門
DELETE FROM departments;

-- 1.7 其他依賴 user_profiles 的表
DELETE FROM code_counters;
DELETE FROM export_logs;

-- 2. 刪除父表資料

-- 2.1 角色與權限主表
DELETE FROM permissions;
DELETE FROM roles;

-- 2.2 系統表
DELETE FROM system_options;
DELETE FROM system_settings;

-- 2.3 使用者資料（注意：此表關聯到 auth.users，只刪除應用程式層面的資料）
DELETE FROM user_profiles;

-- ============================================================================
-- 重置序列（可選，如果需要重置 ID 計數器）
-- ============================================================================
-- ALTER SEQUENCE approval_action_logs_id_seq RESTART WITH 1;
-- ALTER SEQUENCE approval_records_id_seq RESTART WITH 1;
-- ALTER SEQUENCE approval_workflow_steps_id_seq RESTART WITH 1;
-- ALTER SEQUENCE approval_workflows_id_seq RESTART WITH 1;
-- ALTER SEQUENCE approval_statuses_id_seq RESTART WITH 1;
-- ALTER SEQUENCE role_page_access_id_seq RESTART WITH 1;
-- ALTER SEQUENCE role_permissions_id_seq RESTART WITH 1;
-- ALTER SEQUENCE option_workbook_rows_id_seq RESTART WITH 1;
-- ALTER SEQUENCE option_workbook_columns_id_seq RESTART WITH 1;
-- ALTER SEQUENCE option_workbooks_id_seq RESTART WITH 1;
-- ALTER SEQUENCE packaging_templates_id_seq RESTART WITH 1;
-- ALTER SEQUENCE form_data_values_id_seq RESTART WITH 1;
-- ALTER SEQUENCE attachments_id_seq RESTART WITH 1;
-- ALTER SEQUENCE form_fields_id_seq RESTART WITH 1;
-- ALTER SEQUENCE forms_id_seq RESTART WITH 1;
-- ALTER SEQUENCE departments_id_seq RESTART WITH 1;
-- ALTER SEQUENCE code_counters_id_seq RESTART WITH 1;
-- ALTER SEQUENCE export_logs_id_seq RESTART WITH 1;
-- ALTER SEQUENCE permissions_id_seq RESTART WITH 1;
-- ALTER SEQUENCE roles_id_seq RESTART WITH 1;
-- ALTER SEQUENCE system_options_id_seq RESTART WITH 1;
-- ALTER SEQUENCE system_settings_id_seq RESTART WITH 1;

-- ============================================================================
-- 驗證刪除結果（可選）
-- ============================================================================
-- SELECT 'approval_action_logs' AS table_name, COUNT(*) AS count FROM approval_action_logs
-- UNION ALL SELECT 'approval_records', COUNT(*) FROM approval_records
-- UNION ALL SELECT 'approval_workflow_steps', COUNT(*) FROM approval_workflow_steps
-- UNION ALL SELECT 'approval_workflows', COUNT(*) FROM approval_workflows
-- UNION ALL SELECT 'approval_statuses', COUNT(*) FROM approval_statuses
-- UNION ALL SELECT 'role_page_access', COUNT(*) FROM role_page_access
-- UNION ALL SELECT 'role_permissions', COUNT(*) FROM role_permissions
-- UNION ALL SELECT 'option_workbook_rows', COUNT(*) FROM option_workbook_rows
-- UNION ALL SELECT 'option_workbook_columns', COUNT(*) FROM option_workbook_columns
-- UNION ALL SELECT 'option_workbooks', COUNT(*) FROM option_workbooks
-- UNION ALL SELECT 'packaging_templates', COUNT(*) FROM packaging_templates
-- UNION ALL SELECT 'form_data_values', COUNT(*) FROM form_data_values
-- UNION ALL SELECT 'attachments', COUNT(*) FROM attachments
-- UNION ALL SELECT 'form_fields', COUNT(*) FROM form_fields
-- UNION ALL SELECT 'forms', COUNT(*) FROM forms
-- UNION ALL SELECT 'departments', COUNT(*) FROM departments
-- UNION ALL SELECT 'code_counters', COUNT(*) FROM code_counters
-- UNION ALL SELECT 'export_logs', COUNT(*) FROM export_logs
-- UNION ALL SELECT 'permissions', COUNT(*) FROM permissions
-- UNION ALL SELECT 'roles', COUNT(*) FROM roles
-- UNION ALL SELECT 'system_options', COUNT(*) FROM system_options
-- UNION ALL SELECT 'system_settings', COUNT(*) FROM system_settings
-- UNION ALL SELECT 'user_profiles', COUNT(*) FROM user_profiles;
