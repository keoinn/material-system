-- ============================================================================
-- 003_seed_default_roles.sql（已整併）
-- ============================================================================
-- 請改執行 supabase_schema_seeder_master.sql 之「1. 系統內建角色」章節。
-- 本檔保留相同內容，供僅需補齊 roles 表時單獨執行。
-- ============================================================================

INSERT INTO roles (role_code, role_name, role_name_en, description, is_system_role, is_active, display_order)
VALUES
  ('admin', '系統管理員', 'Administrator', '擁有所有權限', TRUE, TRUE, 1),
  ('approver', '審核人員', 'Approver', '可審核物料申請', TRUE, TRUE, 2),
  ('applicant', '申請人員', 'Applicant', '可提交物料申請', TRUE, TRUE, 3)
ON CONFLICT (role_code) DO UPDATE SET
  role_name = EXCLUDED.role_name,
  role_name_en = EXCLUDED.role_name_en,
  description = EXCLUDED.description,
  is_system_role = EXCLUDED.is_system_role,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order;
