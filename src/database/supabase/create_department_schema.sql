-- ============================================================================
-- 部門管理資料表
-- 用途：動態管理組織部門
-- ============================================================================

-- ============================================================================
-- 1. 部門表 (departments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS departments (
  id BIGSERIAL PRIMARY KEY,
  department_code VARCHAR(50) NOT NULL UNIQUE, -- 部門代碼（如：IT, HR, FINANCE）
  department_name VARCHAR(100) NOT NULL, -- 部門名稱（中文）
  department_name_en VARCHAR(100), -- 部門名稱（英文）
  parent_id BIGINT REFERENCES departments(id) ON DELETE SET NULL, -- 上級部門ID（支援階層結構）
  manager_id UUID REFERENCES user_profiles(id) ON DELETE SET NULL, -- 部門主管ID
  description TEXT, -- 部門說明
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  display_order INTEGER DEFAULT 0, -- 顯示順序
  created_by_id UUID REFERENCES user_profiles(id),
  updated_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE departments IS '部門表：定義組織中的各個部門';
COMMENT ON COLUMN departments.department_code IS '部門代碼：唯一識別碼（如：IT, HR, FINANCE）';
COMMENT ON COLUMN departments.department_name IS '部門名稱（中文）';
COMMENT ON COLUMN departments.parent_id IS '上級部門ID：支援階層結構，NULL表示頂層部門';
COMMENT ON COLUMN departments.manager_id IS '部門主管ID：關聯到 user_profiles.id';
COMMENT ON COLUMN departments.is_active IS '是否啟用：停用的部門將無法分配給新用戶';

CREATE INDEX IF NOT EXISTS idx_departments_department_code ON departments(department_code);
CREATE INDEX IF NOT EXISTS idx_departments_parent_id ON departments(parent_id);
CREATE INDEX IF NOT EXISTS idx_departments_manager_id ON departments(manager_id);
CREATE INDEX IF NOT EXISTS idx_departments_is_active ON departments(is_active);
CREATE INDEX IF NOT EXISTS idx_departments_display_order ON departments(display_order);

DROP TRIGGER IF EXISTS update_departments_updated_at ON departments;
CREATE TRIGGER update_departments_updated_at
  BEFORE UPDATE ON departments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. 初始化預設部門（從 system_options 遷移）
-- ============================================================================
-- 從 system_options 表中讀取部門選項並插入到 departments 表
INSERT INTO departments (department_code, department_name, department_name_en, is_active, display_order)
SELECT 
  key AS department_code,
  label AS department_name,
  value AS department_name_en,
  TRUE AS is_active,
  ROW_NUMBER() OVER (ORDER BY id) AS display_order
FROM system_options
WHERE module = 'approval_workflow' AND cate = 'department'
ON CONFLICT (department_code) DO UPDATE SET
  department_name = EXCLUDED.department_name,
  department_name_en = EXCLUDED.department_name_en,
  updated_at = NOW();

-- ============================================================================
-- 3. 更新 user_profiles.department 為外鍵關聯（可選，需要時再執行）
-- ============================================================================
-- 注意：此步驟會修改現有資料結構，建議先備份
-- ALTER TABLE user_profiles
--   DROP COLUMN IF EXISTS department,
--   ADD COLUMN department_id BIGINT REFERENCES departments(id) ON DELETE SET NULL;

-- 或者保留 department 欄位作為字串，但建議使用 department_id 作為外鍵
-- 目前先保留現有結構，部門代碼存儲在 user_profiles.department 中
