-- ============================================================================
-- 更新 user_profiles.department 欄位註解
-- 用途：說明 department 欄位應儲存 departments.department_code
-- ============================================================================

-- 更新欄位註解
COMMENT ON COLUMN user_profiles.department IS '部門代碼：對應到 departments.department_code，儲存部門的唯一識別碼（如：IT, HR, FINANCE）';

-- 可選：添加外鍵約束（如果需要資料完整性檢查）
-- 注意：執行前請確認所有現有的 department 值都存在於 departments.department_code 中
-- ALTER TABLE user_profiles
--   ADD CONSTRAINT fk_user_profiles_department
--   FOREIGN KEY (department) REFERENCES departments(department_code) ON DELETE SET NULL;

-- 可選：添加索引以提升查詢效能
CREATE INDEX IF NOT EXISTS idx_user_profiles_department ON user_profiles(department);
