-- ============================================================================
-- 角色權限管理資料表
-- 用途：動態管理系統角色和權限
-- ============================================================================

-- ============================================================================
-- 1. 角色表 (roles)
-- ============================================================================
CREATE TABLE IF NOT EXISTS roles (
  id BIGSERIAL PRIMARY KEY,
  role_code VARCHAR(50) NOT NULL UNIQUE, -- 角色代碼（如：admin, approver, applicant）
  role_name VARCHAR(100) NOT NULL, -- 角色名稱（中文）
  role_name_en VARCHAR(100), -- 角色名稱（英文）
  description TEXT, -- 角色說明
  is_system_role BOOLEAN DEFAULT FALSE, -- 是否為系統內建角色（不可刪除）
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  display_order INTEGER DEFAULT 0, -- 顯示順序
  created_by_id UUID REFERENCES user_profiles(id),
  updated_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE roles IS '角色表：定義系統中的各種角色';
COMMENT ON COLUMN roles.role_code IS '角色代碼：唯一識別碼（如：admin, approver, applicant）';
COMMENT ON COLUMN roles.role_name IS '角色名稱（中文）';
COMMENT ON COLUMN roles.is_system_role IS '是否為系統內建角色：系統內建角色不可刪除';
COMMENT ON COLUMN roles.is_active IS '是否啟用：停用的角色將無法分配給新用戶';

CREATE INDEX IF NOT EXISTS idx_roles_role_code ON roles(role_code);
CREATE INDEX IF NOT EXISTS idx_roles_is_active ON roles(is_active);
CREATE INDEX IF NOT EXISTS idx_roles_display_order ON roles(display_order);

DROP TRIGGER IF EXISTS update_roles_updated_at ON roles;
CREATE TRIGGER update_roles_updated_at
  BEFORE UPDATE ON roles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. 權限表 (permissions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS permissions (
  id BIGSERIAL PRIMARY KEY,
  permission_code VARCHAR(100) NOT NULL UNIQUE, -- 權限代碼（如：APPLY, REVIEW, SETTINGS）
  permission_name VARCHAR(100) NOT NULL, -- 權限名稱（中文）
  permission_name_en VARCHAR(100), -- 權限名稱（英文）
  module VARCHAR(100), -- 所屬模組
  description TEXT, -- 權限說明
  is_system_permission BOOLEAN DEFAULT FALSE, -- 是否為系統內建權限（不可刪除）
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  display_order INTEGER DEFAULT 0, -- 顯示順序
  created_by_id UUID REFERENCES user_profiles(id),
  updated_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE permissions IS '權限表：定義系統中的各種權限';
COMMENT ON COLUMN permissions.permission_code IS '權限代碼：唯一識別碼（如：APPLY, REVIEW, SETTINGS）';
COMMENT ON COLUMN permissions.permission_name IS '權限名稱（中文）';
COMMENT ON COLUMN permissions.module IS '所屬模組：權限所屬的功能模組';
COMMENT ON COLUMN permissions.is_system_permission IS '是否為系統內建權限：系統內建權限不可刪除';
COMMENT ON COLUMN permissions.is_active IS '是否啟用：停用的權限將無法分配給角色';

CREATE INDEX IF NOT EXISTS idx_permissions_permission_code ON permissions(permission_code);
CREATE INDEX IF NOT EXISTS idx_permissions_module ON permissions(module);
CREATE INDEX IF NOT EXISTS idx_permissions_is_active ON permissions(is_active);
CREATE INDEX IF NOT EXISTS idx_permissions_display_order ON permissions(display_order);

DROP TRIGGER IF EXISTS update_permissions_updated_at ON permissions;
CREATE TRIGGER update_permissions_updated_at
  BEFORE UPDATE ON permissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. 角色權限關聯表 (role_permissions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS role_permissions (
  id BIGSERIAL PRIMARY KEY,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(role_id, permission_id) -- 確保同一角色不會重複分配同一權限
);

COMMENT ON TABLE role_permissions IS '角色權限關聯表：定義哪些角色擁有哪些權限';
COMMENT ON COLUMN role_permissions.role_id IS '角色ID';
COMMENT ON COLUMN role_permissions.permission_id IS '權限ID';

CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions(permission_id);

-- ============================================================================
-- 4. 角色頁面權限關聯表 (role_page_access)
-- ============================================================================
CREATE TABLE IF NOT EXISTS role_page_access (
  id BIGSERIAL PRIMARY KEY,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  page_code VARCHAR(100) NOT NULL, -- 頁面代碼（如：apply, packaging, review）
  page_name VARCHAR(100) NOT NULL, -- 頁面名稱（中文）
  is_accessible BOOLEAN DEFAULT TRUE, -- 是否可以訪問
  created_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(role_id, page_code) -- 確保同一角色不會重複設定同一頁面
);

COMMENT ON TABLE role_page_access IS '角色頁面權限關聯表：定義哪些角色可以訪問哪些頁面';
COMMENT ON COLUMN role_page_access.role_id IS '角色ID';
COMMENT ON COLUMN role_page_access.page_code IS '頁面代碼：唯一識別碼（如：apply, packaging, review）';
COMMENT ON COLUMN role_page_access.page_name IS '頁面名稱（中文）';
COMMENT ON COLUMN role_page_access.is_accessible IS '是否可以訪問：控制角色是否可以訪問該頁面';

CREATE INDEX IF NOT EXISTS idx_role_page_access_role_id ON role_page_access(role_id);
CREATE INDEX IF NOT EXISTS idx_role_page_access_page_code ON role_page_access(page_code);

DROP TRIGGER IF EXISTS update_role_page_access_updated_at ON role_page_access;
CREATE TRIGGER update_role_page_access_updated_at
  BEFORE UPDATE ON role_page_access
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. 初始化系統內建角色
-- ============================================================================
INSERT INTO roles (role_code, role_name, role_name_en, description, is_system_role, is_active, display_order)
VALUES
  ('admin', '系統管理員', 'Administrator', '擁有所有權限，可管理系統設定和使用者', TRUE, TRUE, 1),
  ('approver', '審核人員', 'Approver', '可審核和核准物料申請', TRUE, TRUE, 2),
  ('applicant', '申請人員', 'Applicant', '可提交物料申請', TRUE, TRUE, 3)
ON CONFLICT (role_code) DO UPDATE SET
  role_name = EXCLUDED.role_name,
  role_name_en = EXCLUDED.role_name_en,
  description = EXCLUDED.description,
  updated_at = NOW();

-- ============================================================================
-- 5. 初始化系統內建權限
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
  updated_at = NOW();

-- ============================================================================
-- 6. 初始化角色權限關聯（預設權限分配）
-- ============================================================================
-- 系統管理員擁有所有權限
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 審核人員擁有審核、查詢、匯出權限
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'approver'
  AND p.permission_code IN ('REVIEW', 'QUERY', 'EXPORT', 'APPLY')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 申請人員擁有申請、查詢、匯出權限
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'applicant'
  AND p.permission_code IN ('APPLY', 'QUERY', 'EXPORT')
ON CONFLICT (role_id, permission_id) DO NOTHING;
