-- 添加 sub_group 欄位到 form_fields 表
-- 用於支援子群組功能

ALTER TABLE form_fields 
ADD COLUMN IF NOT EXISTS sub_group VARCHAR(100);

-- 添加註釋
COMMENT ON COLUMN form_fields.sub_group IS '子群組名稱（用於排版顯示）';

-- 添加索引以提升查詢效能（如果需要）
CREATE INDEX IF NOT EXISTS idx_form_fields_sub_group 
ON form_fields(form_id, field_group, sub_group);
