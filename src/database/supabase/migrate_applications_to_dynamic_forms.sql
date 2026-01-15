-- ============================================================================
-- 遷移腳本：將現有的 applications 表資料對應到動態表單系統
-- ============================================================================
-- 建立日期: 2024
-- 說明: 將現有的 applications 表結構和資料遷移到動態表單系統
-- ============================================================================
-- 
-- 注意事項：
-- 1. 此腳本會將現有的 applications 表資料遷移到 form_data_values 表
-- 2. 執行前請先備份資料庫
-- 3. 建議在測試環境先執行測試
-- 4. 此遷移為單向操作，不會刪除原有的 applications 表資料
-- ============================================================================

-- ============================================================================
-- 步驟 1: 確保表單定義已建立
-- ============================================================================
-- 如果還沒有建立表單定義，先執行 dynamic_forms_schema.sql

-- ============================================================================
-- 步驟 2: 建立遷移函數
-- ============================================================================
-- 此函數用於將單筆 application 記錄遷移到 form_data_values

CREATE OR REPLACE FUNCTION migrate_application_to_form_data(
  p_application_id BIGINT,
  p_form_id BIGINT
)
RETURNS VOID AS $$
DECLARE
  v_app RECORD;
  v_field_id BIGINT;
  v_field_key VARCHAR(100);
BEGIN
  -- 取得 application 記錄
  SELECT * INTO v_app FROM applications WHERE id = p_application_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Application with id % not found', p_application_id;
  END IF;

  -- 遷移基本識別資訊
  PERFORM migrate_field_value(p_form_id, 'id', v_app.id::TEXT, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'item_code', v_app.item_code, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移分類資訊
  PERFORM migrate_field_value(p_form_id, 'main_category_id', v_app.main_category_id::TEXT, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'sub_category_id', v_app.sub_category_id::TEXT, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'spec_category_id', v_app.spec_category_id::TEXT, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移物料基本資訊
  PERFORM migrate_field_value(p_form_id, 'item_name_cn', v_app.item_name_cn, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'item_name_en', v_app.item_name_en, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'material', v_app.material, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'surface_finish', v_app.surface_finish, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移尺寸規格（JSON格式）
  IF v_app.dimensions IS NOT NULL THEN
    PERFORM migrate_field_value(p_form_id, 'dimensions', NULL, p_application_id, v_app.dimensions, NULL, NULL, NULL);
  END IF;

  -- 遷移訂購資訊
  PERFORM migrate_field_value(p_form_id, 'moq', v_app.moq::TEXT, p_application_id, NULL, v_app.moq, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'unit', v_app.unit, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移客戶資訊
  PERFORM migrate_field_value(p_form_id, 'customer_ref', v_app.customer_ref, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移供應商資訊
  PERFORM migrate_field_value(p_form_id, 'supplier_id', v_app.supplier_id::TEXT, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移備註與說明
  PERFORM migrate_field_value(p_form_id, 'notes', v_app.notes, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'internal_notes', v_app.internal_notes, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移申請流程資訊
  PERFORM migrate_field_value(p_form_id, 'submit_date', NULL, p_application_id, NULL, NULL, NULL, v_app.submit_date);
  PERFORM migrate_field_value(p_form_id, 'status', v_app.status, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'applicant_id', v_app.applicant_id::TEXT, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'priority', v_app.priority, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移審核資訊
  PERFORM migrate_field_value(p_form_id, 'approval_level', v_app.approval_level::TEXT, p_application_id, NULL, v_app.approval_level, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'approval_status', v_app.approval_status, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'approval_date', NULL, p_application_id, NULL, NULL, NULL, v_app.approval_date);
  PERFORM migrate_field_value(p_form_id, 'reject_date', NULL, p_application_id, NULL, NULL, NULL, v_app.reject_date);
  PERFORM migrate_field_value(p_form_id, 'reject_reason', v_app.reject_reason, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'approver_id', v_app.approver_id::TEXT, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'next_approver_id', v_app.next_approver_id::TEXT, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移成本資訊
  PERFORM migrate_field_value(p_form_id, 'unit_price', v_app.unit_price::TEXT, p_application_id, NULL, v_app.unit_price, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'cost', v_app.cost::TEXT, p_application_id, NULL, v_app.cost, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'currency', v_app.currency, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移庫存資訊
  PERFORM migrate_field_value(p_form_id, 'safety_stock', v_app.safety_stock::TEXT, p_application_id, NULL, v_app.safety_stock, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'reorder_point', v_app.reorder_point::TEXT, p_application_id, NULL, v_app.reorder_point, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'storage_location', v_app.storage_location, p_application_id, NULL, NULL, NULL, NULL);

  -- 遷移其他資訊
  IF v_app.tags IS NOT NULL AND array_length(v_app.tags, 1) > 0 THEN
    PERFORM migrate_field_value(p_form_id, 'tags', NULL, p_application_id, to_jsonb(v_app.tags), NULL, NULL, NULL);
  END IF;
  PERFORM migrate_field_value(p_form_id, 'project_code', v_app.project_code, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'barcode', v_app.barcode, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'qr_code', v_app.qr_code, p_application_id, NULL, NULL, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'estimated_delivery_date', NULL, p_application_id, NULL, NULL, v_app.estimated_delivery_date, NULL);
  PERFORM migrate_field_value(p_form_id, 'lead_time', v_app.lead_time::TEXT, p_application_id, NULL, v_app.lead_time, NULL, NULL);

  -- 遷移版本控制
  PERFORM migrate_field_value(p_form_id, 'version', v_app.version::TEXT, p_application_id, NULL, v_app.version, NULL, NULL);
  PERFORM migrate_field_value(p_form_id, 'created_at', NULL, p_application_id, NULL, NULL, NULL, v_app.created_at);
  PERFORM migrate_field_value(p_form_id, 'updated_at', NULL, p_application_id, NULL, NULL, NULL, v_app.updated_at);
  PERFORM migrate_field_value(p_form_id, 'updated_by_id', v_app.updated_by_id::TEXT, p_application_id, NULL, NULL, NULL, NULL);

END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 輔助函數：遷移單一欄位值
-- ============================================================================
CREATE OR REPLACE FUNCTION migrate_field_value(
  p_form_id BIGINT,
  p_field_key VARCHAR(100),
  p_text_value TEXT,
  p_record_id BIGINT,
  p_json_value JSONB,
  p_number_value NUMERIC,
  p_date_value DATE,
  p_datetime_value TIMESTAMP WITH TIME ZONE
)
RETURNS VOID AS $$
DECLARE
  v_field_id BIGINT;
BEGIN
  -- 如果值為 NULL，則跳過
  IF p_text_value IS NULL AND p_json_value IS NULL AND p_number_value IS NULL 
     AND p_date_value IS NULL AND p_datetime_value IS NULL THEN
    RETURN;
  END IF;

  -- 取得欄位ID
  SELECT id INTO v_field_id 
  FROM form_fields 
  WHERE form_id = p_form_id AND field_key = p_field_key;

  IF v_field_id IS NULL THEN
    -- 欄位不存在，跳過（可能是新欄位尚未定義）
    RETURN;
  END IF;

  -- 插入或更新資料值
  INSERT INTO form_data_values (
    form_id,
    field_id,
    record_id,
    field_key,
    field_value,
    field_value_json,
    field_value_number,
    field_value_date,
    field_value_datetime,
    created_by_id,
    updated_by_id,
    created_at,
    updated_at
  ) VALUES (
    p_form_id,
    v_field_id,
    p_record_id,
    p_field_key,
    p_text_value,
    p_json_value,
    p_number_value,
    p_date_value,
    p_datetime_value,
    NULL, -- created_by_id（可根據需要設定）
    NULL, -- updated_by_id（可根據需要設定）
    NOW(),
    NOW()
  )
  ON CONFLICT (form_id, field_id, record_id)
  DO UPDATE SET
    field_value = EXCLUDED.field_value,
    field_value_json = EXCLUDED.field_value_json,
    field_value_number = EXCLUDED.field_value_number,
    field_value_date = EXCLUDED.field_value_date,
    field_value_datetime = EXCLUDED.field_value_datetime,
    updated_at = NOW();

END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 步驟 3: 執行遷移
-- ============================================================================
-- 將所有現有的 applications 記錄遷移到 form_data_values

DO $$
DECLARE
  v_form_id BIGINT;
  v_app RECORD;
  v_count INTEGER := 0;
BEGIN
  -- 取得表單ID
  SELECT id INTO v_form_id FROM forms WHERE form_code = 'material_application';
  
  IF v_form_id IS NULL THEN
    RAISE EXCEPTION 'Form "material_application" not found. Please run dynamic_forms_schema.sql first.';
  END IF;

  -- 遍歷所有 applications 記錄
  FOR v_app IN SELECT * FROM applications ORDER BY id
  LOOP
    BEGIN
      -- 遷移單筆記錄
      PERFORM migrate_application_to_form_data(v_app.id, v_form_id);
      v_count := v_count + 1;
      
      -- 每 100 筆記錄輸出一次進度
      IF v_count % 100 = 0 THEN
        RAISE NOTICE 'Migrated % records...', v_count;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Failed to migrate application id %: %', v_app.id, SQLERRM;
    END;
  END LOOP;

  RAISE NOTICE 'Migration completed. Total records migrated: %', v_count;
END $$;

-- ============================================================================
-- 步驟 4: 驗證遷移結果
-- ============================================================================
-- 檢查遷移是否成功

-- 查詢遷移統計
SELECT 
  'Total applications' AS description,
  COUNT(*) AS count
FROM applications
UNION ALL
SELECT 
  'Total form data values' AS description,
  COUNT(*) AS count
FROM form_data_values
WHERE form_id = (SELECT id FROM forms WHERE form_code = 'material_application')
UNION ALL
SELECT 
  'Applications with migrated data' AS description,
  COUNT(DISTINCT record_id) AS count
FROM form_data_values
WHERE form_id = (SELECT id FROM forms WHERE form_code = 'material_application');

-- 查詢每個欄位的遷移情況
SELECT 
  ff.field_key,
  ff.field_label,
  COUNT(fdv.id) AS value_count,
  COUNT(DISTINCT fdv.record_id) AS record_count
FROM form_fields ff
LEFT JOIN form_data_values fdv ON ff.id = fdv.field_id
WHERE ff.form_id = (SELECT id FROM forms WHERE form_code = 'material_application')
GROUP BY ff.id, ff.field_key, ff.field_label
ORDER BY ff.display_order;

-- ============================================================================
-- 清理函數（可選）
-- ============================================================================
-- 如果需要清理遷移函數，可以執行以下命令：
-- DROP FUNCTION IF EXISTS migrate_application_to_form_data(BIGINT, BIGINT);
-- DROP FUNCTION IF EXISTS migrate_field_value(BIGINT, VARCHAR, TEXT, BIGINT, JSONB, NUMERIC, DATE, TIMESTAMP WITH TIME ZONE);
