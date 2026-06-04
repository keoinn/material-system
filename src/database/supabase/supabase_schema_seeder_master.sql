-- ============================================================================
-- Supabase Schema Seeder Master（系統預設資料）
-- ============================================================================
-- 建立日期: 2026-06-05
-- 說明: 在結構建立完成後執行本檔，寫入系統內建 seed 資料
--
-- 使用方式:
--   1. 先執行 supabase_schema_withoutdata_master.sql（或等效結構）
--   2. 再執行本檔全文
--
-- 個別 migration 對照:
--   003_seed_default_roles.sql → 本章節「1. 系統內建角色」
-- ============================================================================

-- ============================================================================
-- 1. 系統內建角色
-- （原 003_seed_default_roles.sql）
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

-- ============================================================================
-- 2. 系統內建權限
-- ============================================================================
INSERT INTO permissions (permission_code, permission_name, permission_name_en, module, description, is_system_permission, is_active, display_order)
VALUES
  ('APPLY', '物料申請', 'Material Application', 'application', '可提交物料申請', TRUE, TRUE, 1),
  ('PACKAGING', '包裝說明設定', 'Packaging Settings', 'packaging', '可設定包裝說明', TRUE, TRUE, 2),
  ('REVIEW', '審核管理', 'Review Management', 'review', '可審核申請', TRUE, TRUE, 3),
  ('EXPORT', 'EXCEL匯出', 'Excel Export', 'export', '可匯出EXCEL', TRUE, TRUE, 4),
  ('QUERY', '申請查詢', 'Application Query', 'query', '可查詢申請記錄', TRUE, TRUE, 5),
  ('SETTINGS', '系統設定', 'System Settings', 'settings', '可管理系統設定', TRUE, TRUE, 6),
  ('USERS', '使用者管理', 'User Management', 'user', '可管理使用者', TRUE, TRUE, 7),
  ('APPROVAL_WORKFLOW', '審核流程設定', 'Approval Workflow Settings', 'workflow', '可設定審核流程', TRUE, TRUE, 8),
  ('FORMS', '表單管理', 'Form Management', 'form', '可管理表單', TRUE, TRUE, 9),
  ('ROLE_PERMISSION', '角色權限管理', 'Role Permission Management', 'admin', '可管理角色和權限', TRUE, TRUE, 10),
  ('DEPARTMENT', '部門管理', 'Department Management', 'admin', '可管理部門', TRUE, TRUE, 11)
ON CONFLICT (permission_code) DO UPDATE SET
  permission_name = EXCLUDED.permission_name,
  permission_name_en = EXCLUDED.permission_name_en,
  module = EXCLUDED.module,
  description = EXCLUDED.description,
  is_system_permission = EXCLUDED.is_system_permission,
  is_active = EXCLUDED.is_active,
  display_order = EXCLUDED.display_order,
  updated_at = NOW();

-- ============================================================================
-- 3. 角色權限關聯（預設權限分配）
-- ============================================================================
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'approver'
  AND p.permission_code IN ('REVIEW', 'QUERY', 'EXPORT', 'APPLY')
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'applicant'
  AND p.permission_code IN ('APPLY', 'QUERY', 'EXPORT')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ============================================================================
-- 4. 預設審核狀態
-- ============================================================================
INSERT INTO approval_statuses (status_code, status_name, status_name_en, description, status_type, color, icon, display_order) VALUES
  ('DRAFT', '草稿', 'Draft', '申請草稿，尚未提交', 'INITIAL', 'grey', 'mdi-file-document-outline', 1),
  ('PENDING', '待審核', 'Pending', '等待審核中', 'INTERMEDIATE', 'warning', 'mdi-clock-outline', 2),
  ('IN_REVIEW', '審核中', 'In Review', '正在審核中', 'INTERMEDIATE', 'info', 'mdi-eye-outline', 3),
  ('APPROVED', '已核准', 'Approved', '已通過審核', 'FINAL', 'success', 'mdi-check-circle', 4),
  ('REJECTED', '已退回', 'Rejected', '已退回修改', 'FINAL', 'error', 'mdi-close-circle', 5),
  ('RETURNED', '退回修改', 'Returned', '退回申請人修改', 'INTERMEDIATE', 'warning', 'mdi-arrow-left-circle', 6)
ON CONFLICT (status_code) DO UPDATE SET
  status_name = EXCLUDED.status_name,
  status_name_en = EXCLUDED.status_name_en,
  description = EXCLUDED.description,
  status_type = EXCLUDED.status_type,
  color = EXCLUDED.color,
  icon = EXCLUDED.icon,
  display_order = EXCLUDED.display_order,
  updated_at = NOW();

-- ============================================================================
-- 5. 角色頁面權限（選項活頁簿）
-- ============================================================================
INSERT INTO role_page_access (role_id, page_code, page_name, is_accessible)
SELECT
  r.id,
  'option-workbooks',
  '選項活頁簿',
  CASE
    WHEN r.role_code = 'admin' THEN TRUE
    ELSE FALSE
  END
FROM roles r
WHERE NOT EXISTS (
  SELECT 1
  FROM role_page_access rpa
  WHERE rpa.role_id = r.id
    AND rpa.page_code = 'option-workbooks'
)
ON CONFLICT (role_id, page_code) DO NOTHING;
