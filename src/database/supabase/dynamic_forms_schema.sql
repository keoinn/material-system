-- ============================================================================
-- 動態表單系統資料庫結構
-- ============================================================================
-- 建立日期: 2024
-- 說明: 用於支援動態表單定義和資料儲存的資料庫結構
-- ============================================================================

-- ============================================================================
-- 1. 表單定義主表 (forms)
-- ============================================================================
-- 用於儲存表單的基本定義資訊
CREATE TABLE IF NOT EXISTS forms (
  id BIGSERIAL PRIMARY KEY,
  form_code VARCHAR(100) NOT NULL UNIQUE, -- 表單代碼（例如：material_application）
  form_name VARCHAR(255) NOT NULL, -- 表單名稱（中文）
  form_name_en VARCHAR(255), -- 表單名稱（英文）
  description TEXT, -- 表單說明
  version INTEGER DEFAULT 1, -- 表單版本號
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  is_default BOOLEAN DEFAULT FALSE, -- 是否為預設表單
  form_config JSONB, -- 表單級別的額外設定（JSON格式）
  created_by_id UUID REFERENCES user_profiles(id), -- 建立人
  updated_by_id UUID REFERENCES user_profiles(id), -- 更新人
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE forms IS '表單定義主表：儲存表單的基本定義資訊';
COMMENT ON COLUMN forms.form_code IS '表單代碼：唯一識別碼，例如 material_application';
COMMENT ON COLUMN forms.form_config IS '表單設定：JSON格式，可儲存表單級別的額外設定';

CREATE INDEX idx_forms_form_code ON forms(form_code);
CREATE INDEX idx_forms_is_active ON forms(is_active);
CREATE INDEX idx_forms_is_default ON forms(is_default);
CREATE INDEX idx_forms_created_by_id ON forms(created_by_id);

CREATE TRIGGER update_forms_updated_at
  BEFORE UPDATE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. 表單欄位定義表 (form_fields)
-- ============================================================================
-- 用於儲存表單的欄位定義資訊
CREATE TABLE IF NOT EXISTS form_fields (
  id BIGSERIAL PRIMARY KEY,
  form_id BIGINT NOT NULL REFERENCES forms(id) ON DELETE CASCADE, -- 所屬表單
  field_key VARCHAR(100) NOT NULL, -- 欄位鍵值（例如：item_name_cn）
  field_label VARCHAR(255) NOT NULL, -- 欄位標籤（顯示名稱）
  field_label_en VARCHAR(255), -- 欄位標籤（英文）
  field_type VARCHAR(50) NOT NULL, -- 欄位類型：text, textarea, number, select, multiselect, checkbox, radio, date, datetime, file, json
  max_length INTEGER, -- 字元長度限制（用於計算版面大小）
  is_required BOOLEAN DEFAULT FALSE, -- 是否必填
  field_group VARCHAR(100), -- 欄位群組（用於分組顯示）
  sub_group VARCHAR(100), -- 子群組名稱（用於排版顯示）
  display_order INTEGER DEFAULT 0, -- 顯示順序
  field_config JSONB, -- 欄位額外設定（JSON格式，儲存選項、驗證規則等）
  default_value TEXT, -- 預設值
  placeholder TEXT, -- 提示文字
  help_text TEXT, -- 說明文字
  validation_rules JSONB, -- 驗證規則（JSON格式）
  is_visible BOOLEAN DEFAULT TRUE, -- 是否顯示
  is_readonly BOOLEAN DEFAULT FALSE, -- 是否唯讀
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(form_id, field_key) -- 同一表單內欄位鍵值必須唯一
);

COMMENT ON TABLE form_fields IS '表單欄位定義表：儲存表單的欄位定義資訊';
COMMENT ON COLUMN form_fields.field_type IS '欄位類型：text=文字, textarea=多行文字, number=數字, select=下拉選單, multiselect=多選下拉, checkbox=複選框, radio=單選框, date=日期, datetime=日期時間, file=檔案, json=JSON資料';
COMMENT ON COLUMN form_fields.max_length IS '字元長度：用於計算版面大小和驗證';
COMMENT ON COLUMN form_fields.field_group IS '欄位群組：用於分組顯示，例如「基本資訊」、「分類資訊」等';
COMMENT ON COLUMN form_fields.sub_group IS '子群組名稱：用於排版顯示，例如「基本資訊區塊」、「詳細資訊區塊」等';
COMMENT ON COLUMN form_fields.field_config IS '欄位設定：JSON格式，可儲存選項列表、樣式設定等，例如：{"options": [{"value": "H", "label": "Handle"}]}';
COMMENT ON COLUMN form_fields.validation_rules IS '驗證規則：JSON格式，例如：{"min": 0, "max": 100, "pattern": "^[A-Z]+$"}';

CREATE INDEX idx_form_fields_form_id ON form_fields(form_id);
CREATE INDEX idx_form_fields_field_key ON form_fields(field_key);
CREATE INDEX idx_form_fields_field_type ON form_fields(field_type);
CREATE INDEX idx_form_fields_field_group ON form_fields(field_group);
CREATE INDEX idx_form_fields_sub_group ON form_fields(form_id, field_group, sub_group);
CREATE INDEX idx_form_fields_display_order ON form_fields(form_id, display_order);
CREATE INDEX idx_form_fields_is_visible ON form_fields(is_visible);

CREATE TRIGGER update_form_fields_updated_at
  BEFORE UPDATE ON form_fields
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. 表單資料值表 (form_data_values)
-- ============================================================================
-- 用於儲存動態欄位的實際資料值
CREATE TABLE IF NOT EXISTS form_data_values (
  id BIGSERIAL PRIMARY KEY,
  form_id BIGINT NOT NULL REFERENCES forms(id) ON DELETE CASCADE, -- 所屬表單
  field_id BIGINT NOT NULL REFERENCES form_fields(id) ON DELETE CASCADE, -- 所屬欄位
  record_id BIGINT, -- 記錄ID（例如：application_id，可關聯到其他表）
  field_key VARCHAR(100) NOT NULL, -- 欄位鍵值（冗余，用於快速查詢）
  field_value TEXT, -- 欄位值（文字類型）
  field_value_json JSONB, -- 欄位值（JSON類型，用於複雜資料）
  field_value_number NUMERIC, -- 欄位值（數字類型）
  field_value_date DATE, -- 欄位值（日期類型）
  field_value_datetime TIMESTAMP WITH TIME ZONE, -- 欄位值（日期時間類型）
  file_url VARCHAR(500), -- 檔案URL（檔案類型用）
  created_by_id UUID REFERENCES user_profiles(id), -- 建立人
  updated_by_id UUID REFERENCES user_profiles(id), -- 更新人
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- 唯一約束：同一表單、同一記錄、同一欄位只能有一筆資料
  UNIQUE(form_id, field_id, record_id)
);

COMMENT ON TABLE form_data_values IS '表單資料值表：儲存動態欄位的實際資料值';
COMMENT ON COLUMN form_data_values.record_id IS '記錄ID：可關聯到其他表的記錄，例如 application_id';
COMMENT ON COLUMN form_data_values.field_value IS '欄位值（文字）：用於儲存 text, textarea, select, radio 等類型的值';
COMMENT ON COLUMN form_data_values.field_value_json IS '欄位值（JSON）：用於儲存 multiselect, checkbox, json 等類型的值';
COMMENT ON COLUMN form_data_values.field_value_number IS '欄位值（數字）：用於儲存 number 類型的值';
COMMENT ON COLUMN form_data_values.field_value_date IS '欄位值（日期）：用於儲存 date 類型的值';
COMMENT ON COLUMN form_data_values.field_value_datetime IS '欄位值（日期時間）：用於儲存 datetime 類型的值';
COMMENT ON COLUMN form_data_values.file_url IS '檔案URL：用於儲存 file 類型的檔案路徑';

CREATE INDEX idx_form_data_values_form_id ON form_data_values(form_id);
CREATE INDEX idx_form_data_values_field_id ON form_data_values(field_id);
CREATE INDEX idx_form_data_values_record_id ON form_data_values(record_id);
CREATE INDEX idx_form_data_values_field_key ON form_data_values(field_key);
CREATE INDEX idx_form_data_values_form_record ON form_data_values(form_id, record_id);
CREATE INDEX idx_form_data_values_created_by_id ON form_data_values(created_by_id);

CREATE TRIGGER update_form_data_values_updated_at
  BEFORE UPDATE ON form_data_values
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 插入預設表單定義（物料申請表單）
-- ============================================================================
-- 建立物料申請表單的基本定義
INSERT INTO forms (form_code, form_name, form_name_en, description, is_default, form_config) VALUES
('material_application', '物料申請表單', 'Material Application Form', '物料申請表單定義', TRUE, '{"version": 1, "submitAction": "create_application"}')
ON CONFLICT (form_code) DO NOTHING;

-- 取得表單ID（用於後續插入欄位）
DO $$
DECLARE
  v_form_id BIGINT;
BEGIN
  SELECT id INTO v_form_id FROM forms WHERE form_code = 'material_application';
  
  -- 如果表單不存在，則建立
  IF v_form_id IS NULL THEN
    INSERT INTO forms (form_code, form_name, form_name_en, description, is_default, form_config)
    VALUES ('material_application', '物料申請表單', 'Material Application Form', '物料申請表單定義', TRUE, '{"version": 1, "submitAction": "create_application"}')
    RETURNING id INTO v_form_id;
  END IF;

  -- 插入表單欄位定義（對應現有的 applications 表結構）
  -- 基本識別資訊
  INSERT INTO form_fields (form_id, field_key, field_label, field_label_en, field_type, max_length, is_required, field_group, display_order, field_config) VALUES
  (v_form_id, 'item_code', '料號', 'Item Code', 'text', 100, TRUE, '基本資訊', 1, '{"readonly": true, "autoGenerate": true}'),
  (v_form_id, 'id', '申請ID', 'Application ID', 'number', NULL, FALSE, '基本資訊', 0, '{"readonly": true, "hidden": true}'),
  
  -- 分類資訊
  (v_form_id, 'main_category_id', '產品大類', 'Main Category', 'select', NULL, TRUE, '分類資訊', 10, '{"source": "product_categories", "filter": {"level": 1}}'),
  (v_form_id, 'sub_category_id', '產品中類', 'Sub Category', 'select', NULL, FALSE, '分類資訊', 11, '{"source": "product_categories", "filter": {"level": 2}, "dependsOn": "main_category_id"}'),
  (v_form_id, 'spec_category_id', '產品小類', 'Spec Category', 'select', NULL, FALSE, '分類資訊', 12, '{"source": "product_categories", "filter": {"level": 3}, "dependsOn": "sub_category_id"}'),
  
  -- 物料基本資訊
  (v_form_id, 'item_name_cn', '中文名稱', 'Item Name (CN)', 'text', 500, TRUE, '物料基本資訊', 20, '{}'),
  (v_form_id, 'item_name_en', '英文名稱', 'Item Name (EN)', 'text', 500, TRUE, '物料基本資訊', 21, '{}'),
  (v_form_id, 'material', '基本材質', 'Material', 'select', 255, FALSE, '物料基本資訊', 22, '{"source": "system_options", "filter": {"module": "material_application", "cate": "material"}}'),
  (v_form_id, 'surface_finish', '表面處理', 'Surface Finish', 'select', 255, FALSE, '物料基本資訊', 23, '{"source": "system_options", "filter": {"module": "material_application", "cate": "surfaceFinish"}}'),
  
  -- 尺寸規格（JSON格式）
  (v_form_id, 'dimensions', '尺寸規格', 'Dimensions', 'json', NULL, FALSE, '尺寸規格', 30, '{"schema": {"length": "number", "width": "number", "height": "number", "weight": "number"}}'),
  (v_form_id, 'dimensions.length', '長度 (mm)', 'Length (mm)', 'number', NULL, FALSE, '尺寸規格', 31, '{"unit": "mm", "min": 0}'),
  (v_form_id, 'dimensions.width', '寬度 (mm)', 'Width (mm)', 'number', NULL, FALSE, '尺寸規格', 32, '{"unit": "mm", "min": 0}'),
  (v_form_id, 'dimensions.height', '高度 (mm)', 'Height (mm)', 'number', NULL, FALSE, '尺寸規格', 33, '{"unit": "mm", "min": 0}'),
  (v_form_id, 'dimensions.weight', '重量 (g)', 'Weight (g)', 'number', NULL, FALSE, '尺寸規格', 34, '{"unit": "g", "min": 0}'),
  
  -- 訂購資訊
  (v_form_id, 'moq', '最小訂購量', 'MOQ', 'number', NULL, FALSE, '訂購資訊', 40, '{"min": 1}'),
  (v_form_id, 'unit', '單位', 'Unit', 'select', 20, FALSE, '訂購資訊', 41, '{"source": "system_options", "filter": {"module": "material_application", "cate": "unit"}}'),
  
  -- 客戶資訊
  (v_form_id, 'customer_ref', '客戶參考貨號', 'Customer Reference', 'text', 255, FALSE, '客戶資訊', 50, '{}'),
  
  -- 供應商資訊
  (v_form_id, 'supplier_id', '供應商', 'Supplier', 'select', NULL, FALSE, '供應商資訊', 60, '{"source": "suppliers", "filter": {"is_active": true}}'),
  
  -- 備註與說明
  (v_form_id, 'notes', '備註', 'Notes', 'textarea', NULL, FALSE, '備註與說明', 70, '{}'),
  (v_form_id, 'internal_notes', '內部備註', 'Internal Notes', 'textarea', NULL, FALSE, '備註與說明', 71, '{"visibleTo": ["admin", "approver"]}'),
  
  -- 申請流程資訊
  (v_form_id, 'submit_date', '提交日期', 'Submit Date', 'datetime', NULL, FALSE, '申請流程資訊', 80, '{"readonly": true}'),
  (v_form_id, 'status', '狀態', 'Status', 'select', 50, TRUE, '申請流程資訊', 81, '{"source": "system_options", "filter": {"module": "application_query", "cate": "applicationStatus"}, "readonly": true}'),
  (v_form_id, 'applicant_id', '申請人', 'Applicant', 'select', NULL, TRUE, '申請流程資訊', 82, '{"source": "user_profiles", "readonly": true}'),
  (v_form_id, 'priority', '優先級', 'Priority', 'radio', 20, FALSE, '申請流程資訊', 83, '{"source": "system_options", "filter": {"module": "material_application", "cate": "priority"}, "default": "MEDIUM"}'),
  
  -- 審核資訊
  (v_form_id, 'approval_level', '審核層級', 'Approval Level', 'number', NULL, FALSE, '審核資訊', 90, '{"min": 1, "max": 3, "default": 1, "readonly": true}'),
  (v_form_id, 'approval_status', '審核狀態', 'Approval Status', 'select', 50, FALSE, '審核資訊', 91, '{"source": "system_options", "readonly": true}'),
  (v_form_id, 'approval_date', '核准日期', 'Approval Date', 'datetime', NULL, FALSE, '審核資訊', 92, '{"readonly": true}'),
  (v_form_id, 'reject_date', '退回日期', 'Reject Date', 'datetime', NULL, FALSE, '審核資訊', 93, '{"readonly": true}'),
  (v_form_id, 'reject_reason', '退回原因', 'Reject Reason', 'textarea', NULL, FALSE, '審核資訊', 94, '{"readonly": true}'),
  (v_form_id, 'approver_id', '審核人', 'Approver', 'select', NULL, FALSE, '審核資訊', 95, '{"source": "user_profiles", "readonly": true}'),
  (v_form_id, 'next_approver_id', '下一審核人', 'Next Approver', 'select', NULL, FALSE, '審核資訊', 96, '{"source": "user_profiles", "readonly": true}'),
  
  -- 成本資訊
  (v_form_id, 'unit_price', '單價', 'Unit Price', 'number', NULL, FALSE, '成本資訊', 100, '{"min": 0, "precision": 2}'),
  (v_form_id, 'cost', '成本', 'Cost', 'number', NULL, FALSE, '成本資訊', 101, '{"min": 0, "precision": 2}'),
  (v_form_id, 'currency', '幣別', 'Currency', 'select', 10, FALSE, '成本資訊', 102, '{"source": "system_options", "filter": {"module": "material_application", "cate": "currency"}, "default": "TWD"}'),
  
  -- 庫存資訊
  (v_form_id, 'safety_stock', '安全庫存', 'Safety Stock', 'number', NULL, FALSE, '庫存資訊', 110, '{"min": 0}'),
  (v_form_id, 'reorder_point', '再訂購點', 'Reorder Point', 'number', NULL, FALSE, '庫存資訊', 111, '{"min": 0}'),
  (v_form_id, 'storage_location', '儲存位置', 'Storage Location', 'text', 255, FALSE, '庫存資訊', 112, '{}'),
  
  -- 其他資訊
  (v_form_id, 'tags', '標籤', 'Tags', 'multiselect', NULL, FALSE, '其他資訊', 120, '{"allowCustom": true}'),
  (v_form_id, 'project_code', '專案代碼', 'Project Code', 'text', 100, FALSE, '其他資訊', 121, '{}'),
  (v_form_id, 'barcode', '條碼', 'Barcode', 'text', 255, FALSE, '其他資訊', 122, '{}'),
  (v_form_id, 'qr_code', 'QR Code', 'QR Code', 'text', 255, FALSE, '其他資訊', 123, '{}'),
  (v_form_id, 'estimated_delivery_date', '預估交期', 'Estimated Delivery Date', 'date', NULL, FALSE, '其他資訊', 124, '{}'),
  (v_form_id, 'lead_time', '交期（天數）', 'Lead Time (Days)', 'number', NULL, FALSE, '其他資訊', 125, '{"min": 0}'),
  
  -- 版本控制
  (v_form_id, 'version', '版本', 'Version', 'number', NULL, FALSE, '版本控制', 130, '{"readonly": true, "default": 1}'),
  (v_form_id, 'created_at', '建立時間', 'Created At', 'datetime', NULL, FALSE, '版本控制', 131, '{"readonly": true}'),
  (v_form_id, 'updated_at', '更新時間', 'Updated At', 'datetime', NULL, FALSE, '版本控制', 132, '{"readonly": true}'),
  (v_form_id, 'updated_by_id', '更新人', 'Updated By', 'select', NULL, FALSE, '版本控制', 133, '{"source": "user_profiles", "readonly": true}')
  ON CONFLICT (form_id, field_key) DO NOTHING;
END $$;

-- ============================================================================
-- 查詢範例
-- ============================================================================

-- 查詢表單定義及其欄位
-- SELECT 
--   f.*,
--   ff.id AS field_id,
--   ff.field_key,
--   ff.field_label,
--   ff.field_type,
--   ff.field_group,
--   ff.display_order
-- FROM forms f
-- LEFT JOIN form_fields ff ON f.id = ff.form_id
-- WHERE f.form_code = 'material_application'
-- ORDER BY ff.display_order;

-- 查詢表單資料值
-- SELECT 
--   fdv.*,
--   ff.field_label,
--   ff.field_type
-- FROM form_data_values fdv
-- JOIN form_fields ff ON fdv.field_id = ff.id
-- WHERE fdv.form_id = 1 AND fdv.record_id = 123
-- ORDER BY ff.display_order;

-- 查詢完整表單資料（含欄位定義和值）
-- SELECT 
--   f.form_code,
--   f.form_name,
--   ff.field_key,
--   ff.field_label,
--   ff.field_type,
--   ff.field_group,
--   fdv.field_value,
--   fdv.field_value_json,
--   fdv.field_value_number
-- FROM forms f
-- JOIN form_fields ff ON f.id = ff.form_id
-- LEFT JOIN form_data_values fdv ON ff.id = fdv.field_id AND fdv.record_id = 123
-- WHERE f.form_code = 'material_application'
-- ORDER BY ff.display_order;
