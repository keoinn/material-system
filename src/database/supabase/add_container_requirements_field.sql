-- ============================================================================
-- 新增「裝櫃要求」欄位到 material_application 表單
-- ============================================================================
-- 此腳本會在 material_application 表單中新增一個多選下拉欄位「裝櫃要求」

DO $$
DECLARE
  v_form_id BIGINT;
  v_max_order INTEGER;
BEGIN
  -- 取得表單ID
  SELECT id INTO v_form_id FROM forms WHERE form_code = 'material_application';
  
  IF v_form_id IS NULL THEN
    RAISE EXCEPTION '表單 material_application 不存在，請先執行 dynamic_forms_schema.sql';
  END IF;
  
  -- 檢查欄位是否已存在
  IF EXISTS (SELECT 1 FROM form_fields WHERE form_id = v_form_id AND field_key = 'container_requirements') THEN
    RAISE NOTICE '欄位 container_requirements 已存在，跳過新增';
    RETURN;
  END IF;
  
  -- 取得「其他資訊」群組的最大順序，如果沒有則使用 130
  SELECT COALESCE(MAX(display_order), 130) INTO v_max_order
  FROM form_fields
  WHERE form_id = v_form_id AND field_group = '其他資訊';
  
  -- 如果「其他資訊」群組不存在，查找其他群組的最大順序
  IF v_max_order IS NULL OR v_max_order = 130 THEN
    SELECT COALESCE(MAX(display_order), 130) INTO v_max_order
    FROM form_fields
    WHERE form_id = v_form_id;
  END IF;
  
  -- 新增欄位，放在「其他資訊」群組的最後
  INSERT INTO form_fields (
    form_id,
    field_key,
    field_label,
    field_label_en,
    field_type,
    max_length,
    is_required,
    field_group,
    display_order,
    field_config
  ) VALUES (
    v_form_id,
    'container_requirements',
    '裝櫃要求',
    'Container Requirements',
    'multiselect',
    NULL,
    FALSE,
    '其他資訊',
    v_max_order + 1,
    '{
      "options": [
        {"value": "20ft", "label": "20呎櫃"},
        {"value": "40ft", "label": "40呎櫃"},
        {"value": "40ft_hc", "label": "40呎櫃高櫃"},
        {"value": "pallet", "label": "棧板出貨"},
        {"value": "bulk", "label": "散裝裝櫃"}
      ]
    }'::jsonb
  );
  
  RAISE NOTICE '成功新增「裝櫃要求」欄位到 material_application 表單';
END $$;

-- 驗證新增結果
SELECT 
  ff.field_key,
  ff.field_label,
  ff.field_label_en,
  ff.field_type,
  ff.field_group,
  ff.display_order,
  ff.field_config->'options' as options
FROM form_fields ff
JOIN forms f ON ff.form_id = f.id
WHERE f.form_code = 'material_application' 
  AND ff.field_key = 'container_requirements';
