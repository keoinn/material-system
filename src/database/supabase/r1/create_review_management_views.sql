-- ============================================================================
-- 審核管理視圖和函數
-- 用於查詢待審核的動態表單申請
-- ============================================================================

-- 創建視圖：待審核申請列表（包含動態表單資料）
CREATE OR REPLACE VIEW pending_applications_view AS
SELECT DISTINCT
  a.id,
  a.item_code,
  a.item_name_cn,
  a.item_name_en,
  a.material,
  a.surface_finish,
  a.dimensions,
  a.customer_ref,
  a.supplier_id,
  a.main_category_id,
  a.sub_category_id,
  a.spec_category_id,
  a.notes,
  a.applicant_id,
  a.status,
  a.approval_status,
  a.submit_date,
  a.priority,
  a.created_at,
  a.updated_at,
  -- 申請人資訊
  up.username AS applicant_username,
  -- 表單資訊（如果來自動態表單）
  f.id AS form_id,
  f.form_code,
  f.form_name,
  -- 判斷是否為動態表單申請
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM form_data_values fdv 
      WHERE fdv.record_id = a.id AND fdv.form_id = f.id
    ) THEN TRUE
    ELSE FALSE
  END AS is_dynamic_form
FROM applications a
LEFT JOIN user_profiles up ON a.applicant_id = up.id
LEFT JOIN forms f ON f.form_code = 'material_application'
WHERE a.status = 'PENDING' AND a.approval_status = 'PENDING'
ORDER BY a.submit_date DESC, a.created_at DESC;

COMMENT ON VIEW pending_applications_view IS '待審核申請列表視圖：包含傳統和動態表單申請';

-- 創建函數：獲取申請的動態表單資料
CREATE OR REPLACE FUNCTION get_application_form_data(
  p_application_id BIGINT
)
RETURNS JSONB AS $$
DECLARE
  v_form_id BIGINT;
  v_result JSONB := '{}'::JSONB;
BEGIN
  -- 查找對應的表單 ID
  SELECT f.id INTO v_form_id
  FROM forms f
  WHERE f.form_code = 'material_application'
  LIMIT 1;

  IF v_form_id IS NULL THEN
    RETURN v_result;
  END IF;

  -- 從 form_data_values 提取所有欄位值
  SELECT jsonb_object_agg(
    fdv.field_key,
    CASE
      WHEN fdv.field_value IS NOT NULL THEN fdv.field_value::JSONB
      WHEN fdv.field_value_json IS NOT NULL THEN fdv.field_value_json
      WHEN fdv.field_value_number IS NOT NULL THEN fdv.field_value_number::JSONB
      WHEN fdv.field_value_date IS NOT NULL THEN to_jsonb(fdv.field_value_date)
      WHEN fdv.field_value_datetime IS NOT NULL THEN to_jsonb(fdv.field_value_datetime)
      WHEN fdv.file_url IS NOT NULL THEN fdv.file_url::JSONB
      ELSE NULL::JSONB
    END
  ) INTO v_result
  FROM form_data_values fdv
  WHERE fdv.form_id = v_form_id
    AND fdv.record_id = p_application_id;

  RETURN COALESCE(v_result, '{}'::JSONB);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_application_form_data IS '獲取申請的動態表單資料（JSON格式）';

-- 創建函數：更新申請狀態（支援審核記錄）
CREATE OR REPLACE FUNCTION update_application_status(
  p_application_id BIGINT,
  p_status VARCHAR(50),
  p_approval_status VARCHAR(50),
  p_approver_id UUID,
  p_reject_reason TEXT DEFAULT NULL,
  p_comment TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_approver_name VARCHAR(255);
  v_approver_role VARCHAR(50);
BEGIN
  -- 獲取審核人資訊
  SELECT full_name, role INTO v_approver_name, v_approver_role
  FROM user_profiles
  WHERE id = p_approver_id;

  -- 更新申請狀態
  UPDATE applications
  SET 
    status = p_status,
    approval_status = p_approval_status,
    approver_id = p_approver_id,
    approval_date = CASE WHEN p_status = 'APPROVED' THEN NOW() ELSE approval_date END,
    reject_date = CASE WHEN p_status = 'REJECTED' THEN NOW() ELSE reject_date END,
    reject_reason = p_reject_reason,
    updated_at = NOW()
  WHERE id = p_application_id;

  -- 創建審核記錄
  INSERT INTO approval_logs (
    application_id,
    action,
    approver_id,
    approver_name,
    approver_role,
    reason,
    comment,
    timestamp
  ) VALUES (
    p_application_id,
    CASE 
      WHEN p_status = 'APPROVED' THEN 'APPROVE'
      WHEN p_status = 'REJECTED' THEN 'REJECT'
      ELSE 'SUBMIT'
    END,
    p_approver_id,
    v_approver_name,
    v_approver_role,
    p_reject_reason,
    p_comment,
    NOW()
  );

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_application_status IS '更新申請狀態並創建審核記錄';

-- 創建索引以提升查詢效能
CREATE INDEX IF NOT EXISTS idx_applications_status_approval_status 
  ON applications(status, approval_status);

CREATE INDEX IF NOT EXISTS idx_form_data_values_record_id_form_id 
  ON form_data_values(record_id, form_id);
