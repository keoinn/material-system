-- 審核流程：新增套用表單代碼列表（可多筆 form_code）
ALTER TABLE approval_workflows
  ADD COLUMN IF NOT EXISTS form_codes JSONB NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN approval_workflows.form_codes IS '套用此流程的表單代碼列表（JSON 陣列）；空陣列表示通用流程';
