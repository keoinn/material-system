-- ============================================================================
-- 移除所有資料的 SQL 語句
-- ============================================================================
-- 注意：此腳本會刪除所有資料，但保留資料表結構
-- 執行前請確認已備份重要資料
-- ============================================================================

-- 1. 刪除所有子表資料（有外鍵依賴的表）
-- 1.1 刪除申請相關的子表資料
DELETE FROM application_packaging;
DELETE FROM attachments;
DELETE FROM approval_logs;
DELETE FROM code_counters;
DELETE FROM export_logs;
DELETE FROM drafts;

-- 1.2 刪除申請主表資料
DELETE FROM applications;

-- 1.3 刪除類別預設包裝資料
DELETE FROM category_packaging_defaults;

-- 1.4 刪除包裝選項資料
DELETE FROM packaging_options;

-- 2. 刪除父表資料
-- 2.1 刪除產品分類（需要按照層級順序刪除：先刪除小類，再刪除中類，最後刪除大類）
DELETE FROM product_categories WHERE level = 3; -- 小類
DELETE FROM product_categories WHERE level = 2; -- 中類
DELETE FROM product_categories WHERE level = 1; -- 大類

-- 2.2 刪除供應商資料
DELETE FROM suppliers;

-- 2.3 刪除包裝類別資料
DELETE FROM packaging_categories;

-- 2.4 刪除系統選項資料
DELETE FROM system_options;

-- 2.5 刪除系統設定資料
DELETE FROM system_settings;

-- 2.6 刪除使用者資料（注意：此表關聯到 auth.users，只刪除應用程式層面的資料）
DELETE FROM user_profiles;

-- ============================================================================
-- 重置序列（可選，如果需要重置 ID 計數器）
-- ============================================================================
-- 注意：如果資料表使用 BIGSERIAL，刪除資料後序列不會自動重置
-- 如果需要重置序列，可以執行以下語句：

-- ALTER SEQUENCE product_categories_id_seq RESTART WITH 1;
-- ALTER SEQUENCE suppliers_id_seq RESTART WITH 1;
-- ALTER SEQUENCE packaging_categories_id_seq RESTART WITH 1;
-- ALTER SEQUENCE packaging_options_id_seq RESTART WITH 1;
-- ALTER SEQUENCE category_packaging_defaults_id_seq RESTART WITH 1;
-- ALTER SEQUENCE system_options_id_seq RESTART WITH 1;
-- ALTER SEQUENCE applications_id_seq RESTART WITH 1;
-- ALTER SEQUENCE application_packaging_id_seq RESTART WITH 1;
-- ALTER SEQUENCE attachments_id_seq RESTART WITH 1;
-- ALTER SEQUENCE approval_logs_id_seq RESTART WITH 1;
-- ALTER SEQUENCE code_counters_id_seq RESTART WITH 1;
-- ALTER SEQUENCE export_logs_id_seq RESTART WITH 1;
-- ALTER SEQUENCE drafts_id_seq RESTART WITH 1;
-- ALTER SEQUENCE system_settings_id_seq RESTART WITH 1;

-- ============================================================================
-- 驗證刪除結果（可選）
-- ============================================================================
-- SELECT 'product_categories' AS table_name, COUNT(*) AS count FROM product_categories
-- UNION ALL
-- SELECT 'suppliers', COUNT(*) FROM suppliers
-- UNION ALL
-- SELECT 'packaging_categories', COUNT(*) FROM packaging_categories
-- UNION ALL
-- SELECT 'packaging_options', COUNT(*) FROM packaging_options
-- UNION ALL
-- SELECT 'category_packaging_defaults', COUNT(*) FROM category_packaging_defaults
-- UNION ALL
-- SELECT 'system_options', COUNT(*) FROM system_options
-- UNION ALL
-- SELECT 'system_settings', COUNT(*) FROM system_settings
-- UNION ALL
-- SELECT 'user_profiles', COUNT(*) FROM user_profiles
-- UNION ALL
-- SELECT 'applications', COUNT(*) FROM applications
-- UNION ALL
-- SELECT 'application_packaging', COUNT(*) FROM application_packaging
-- UNION ALL
-- SELECT 'attachments', COUNT(*) FROM attachments
-- UNION ALL
-- SELECT 'approval_logs', COUNT(*) FROM approval_logs
-- UNION ALL
-- SELECT 'code_counters', COUNT(*) FROM code_counters
-- UNION ALL
-- SELECT 'export_logs', COUNT(*) FROM export_logs
-- UNION ALL
-- SELECT 'drafts', COUNT(*) FROM drafts;