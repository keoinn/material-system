-- ============================================================================
-- 新增欄位：is_in_template 到 form_fields 表
-- 用途：記錄該欄位是否出現在包裝模板設定中
-- ============================================================================

-- 新增欄位
ALTER TABLE form_fields
ADD COLUMN IF NOT EXISTS is_in_template BOOLEAN DEFAULT FALSE;

-- 添加註解
COMMENT ON COLUMN form_fields.is_in_template IS '是否加入模板：記錄該欄位是否出現在包裝模板設定中';

-- 添加索引（如果需要根據此欄位查詢）
CREATE INDEX IF NOT EXISTS idx_form_fields_is_in_template ON form_fields(is_in_template);
