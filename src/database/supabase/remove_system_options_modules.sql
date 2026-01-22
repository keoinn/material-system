-- ============================================================================
-- 移除 system_options 中特定 module 的記錄
-- ============================================================================
-- 執行日期: 2026-01-20
-- 說明: 移除以下 module 的所有記錄：
--       - application_query
--       - review_management
--       - system_settings
--       - excel_export
-- ============================================================================

-- 刪除指定 module 的所有記錄
DELETE FROM "public"."system_options"
WHERE "module" IN (
  'application_query',
  'review_management',
  'system_settings',
  'excel_export'
);

-- 驗證刪除結果（可選，執行後可查看剩餘記錄）
-- SELECT "module", COUNT(*) as count
-- FROM "public"."system_options"
-- GROUP BY "module";
