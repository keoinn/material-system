-- ============================================================================
-- 包裝說明模板表
-- 用途：儲存不同產品類型的包裝說明模板值
-- ============================================================================

-- 創建包裝說明模板表
CREATE TABLE IF NOT EXISTS packaging_templates (
  id BIGSERIAL PRIMARY KEY,
  form_id BIGINT NOT NULL REFERENCES forms(id) ON DELETE CASCADE, -- 所屬表單
  template_type VARCHAR(50) NOT NULL, -- 模板類型（H, S, M, D, F, B, I, O）
  template_values JSONB NOT NULL DEFAULT '{}', -- 模板值（JSON格式，儲存欄位鍵值對）
  created_by_id UUID REFERENCES user_profiles(id), -- 建立人
  updated_by_id UUID REFERENCES user_profiles(id), -- 更新人
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- 同一表單和模板類型的組合必須唯一
  UNIQUE(form_id, template_type)
);

COMMENT ON TABLE packaging_templates IS '包裝說明模板表：儲存不同產品類型的包裝說明模板值';
COMMENT ON COLUMN packaging_templates.form_id IS '所屬表單 ID';
COMMENT ON COLUMN packaging_templates.template_type IS '模板類型：H=手把, S=滑軌, M=模組, D=裝飾五金, F=功能五金, B=建築五金, I=工業零件, O=其他';
COMMENT ON COLUMN packaging_templates.template_values IS '模板值：JSON格式，儲存欄位鍵值對，例如：{"field_key1": "value1", "field_key2": "value2"}';

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_packaging_templates_form_id ON packaging_templates(form_id);
CREATE INDEX IF NOT EXISTS idx_packaging_templates_template_type ON packaging_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_packaging_templates_form_type ON packaging_templates(form_id, template_type);

-- 創建更新時間觸發器
CREATE TRIGGER update_packaging_templates_updated_at
  BEFORE UPDATE ON packaging_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
