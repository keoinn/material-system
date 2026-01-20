-- ============================================================================
-- 建立從 form_data_values 創建 applications 記錄的函數
-- ============================================================================
-- 此函數用於當動態表單提交時，自動在 applications 表中創建對應的記錄
-- 這樣可以確保資料在資料庫後台可見

-- 創建函數：從 form_data_values 創建 applications 記錄
CREATE OR REPLACE FUNCTION create_application_from_form_data(
  p_form_id BIGINT,
  p_record_id BIGINT,
  p_applicant_id UUID
)
RETURNS BIGINT AS $$
DECLARE
  v_application_id BIGINT;
  v_item_code TEXT;
  v_item_name_cn TEXT;
  v_item_name_en TEXT;
  v_material TEXT;
  v_surface_finish TEXT;
  v_dimensions JSONB;
  v_customer_ref TEXT;
  v_supplier_id BIGINT;
  v_main_category_id BIGINT;
  v_sub_category_id BIGINT;
  v_spec_category_id BIGINT;
  v_notes TEXT;
BEGIN
  -- 從 form_data_values 提取欄位值
  -- 注意：這裡假設欄位 key 與 applications 表的欄位對應
  -- 您可能需要根據實際的欄位 key 調整這些查詢

  -- 提取 item_code（料號）
  SELECT field_value INTO v_item_code
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'item_code'
  LIMIT 1;

  -- 提取 item_name_cn（物料名稱中文）
  SELECT field_value INTO v_item_name_cn
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'item_name_cn'
  LIMIT 1;

  -- 提取 item_name_en（物料名稱英文）
  SELECT field_value INTO v_item_name_en
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'item_name_en'
  LIMIT 1;

  -- 提取 material（材質）
  SELECT field_value INTO v_material
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'material'
  LIMIT 1;

  -- 提取 surface_finish（表面處理）
  SELECT field_value INTO v_surface_finish
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'surface_finish'
  LIMIT 1;

  -- 提取 dimensions（尺寸，JSON 格式）
  SELECT field_value_json INTO v_dimensions
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'dimensions'
  LIMIT 1;

  -- 提取 customer_ref（客戶參考貨號）
  SELECT field_value INTO v_customer_ref
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'customer_ref'
  LIMIT 1;

  -- 提取 supplier_id（供應商 ID）
  SELECT field_value_number::BIGINT INTO v_supplier_id
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'supplier_id'
  LIMIT 1;

  -- 提取 main_category_id（大類 ID）
  SELECT field_value_number::BIGINT INTO v_main_category_id
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'main_category_id'
  LIMIT 1;

  -- 提取 sub_category_id（中類 ID）
  SELECT field_value_number::BIGINT INTO v_sub_category_id
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'sub_category_id'
  LIMIT 1;

  -- 提取 spec_category_id（小類 ID）
  SELECT field_value_number::BIGINT INTO v_spec_category_id
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'spec_category_id'
  LIMIT 1;

  -- 提取 notes（備註）
  SELECT field_value INTO v_notes
  FROM form_data_values
  WHERE form_id = p_form_id
    AND record_id = p_record_id
    AND field_key = 'notes'
  LIMIT 1;

  -- 如果沒有 item_code，生成一個臨時的（使用 record_id）
  IF v_item_code IS NULL OR v_item_code = '' THEN
    v_item_code := 'TEMP-' || p_record_id::TEXT;
  END IF;

  -- 如果沒有 item_name_cn，使用預設值
  IF v_item_name_cn IS NULL OR v_item_name_cn = '' THEN
    v_item_name_cn := '未命名物料';
  END IF;

  -- 如果沒有 item_name_en，使用預設值
  IF v_item_name_en IS NULL OR v_item_name_en = '' THEN
    v_item_name_en := 'Unnamed Material';
  END IF;

  -- 在 applications 表中創建記錄
  INSERT INTO applications (
    item_code,
    item_name_cn,
    item_name_en,
    material,
    surface_finish,
    dimensions,
    customer_ref,
    supplier_id,
    main_category_id,
    sub_category_id,
    spec_category_id,
    notes,
    applicant_id,
    status,
    approval_status,
    submit_date
  ) VALUES (
    v_item_code,
    v_item_name_cn,
    v_item_name_en,
    v_material,
    v_surface_finish,
    v_dimensions,
    v_customer_ref,
    v_supplier_id,
    v_main_category_id,
    v_sub_category_id,
    v_spec_category_id,
    v_notes,
    p_applicant_id,
    'PENDING',
    'PENDING',
    NOW()
  )
  RETURNING id INTO v_application_id;

  -- 更新 form_data_values 中的 record_id，使其指向新創建的 application id
  -- 這樣可以確保資料關聯正確
  UPDATE form_data_values
  SET record_id = v_application_id
  WHERE form_id = p_form_id
    AND record_id = p_record_id;

  RETURN v_application_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_application_from_form_data IS '從 form_data_values 創建 applications 記錄的函數';

-- ============================================================================
-- 可選：創建觸發器，當 form_data_values 插入資料時自動創建 applications 記錄
-- 注意：這可能會影響性能，建議在應用層面手動調用函數
-- ============================================================================
-- CREATE OR REPLACE FUNCTION trigger_create_application_from_form_data()
-- RETURNS TRIGGER AS $$
-- DECLARE
--   v_form_code TEXT;
--   v_applicant_id UUID;
-- BEGIN
--   -- 檢查是否為 material_application 表單
--   SELECT form_code INTO v_form_code
--   FROM forms
--   WHERE id = NEW.form_id;
--
--   IF v_form_code = 'material_application' THEN
--     -- 獲取申請人 ID（從 created_by_id 或當前用戶）
--     v_applicant_id := NEW.created_by_id;
--
--     -- 如果還沒有對應的 application 記錄，創建一個
--     IF NOT EXISTS (
--       SELECT 1 FROM applications WHERE id = NEW.record_id
--     ) THEN
--       PERFORM create_application_from_form_data(
--         NEW.form_id,
--         NEW.record_id,
--         COALESCE(v_applicant_id, auth.uid())
--       );
--     END IF;
--   END IF;
--
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
--
-- CREATE TRIGGER trg_create_application_from_form_data
--   AFTER INSERT ON form_data_values
--   FOR EACH ROW
--   EXECUTE FUNCTION trigger_create_application_from_form_data();
