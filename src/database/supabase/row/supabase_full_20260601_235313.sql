


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."create_application_from_form_data"("p_form_id" bigint, "p_record_id" bigint, "p_applicant_id" "uuid") RETURNS bigint
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."create_application_from_form_data"("p_form_id" bigint, "p_record_id" bigint, "p_applicant_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."create_application_from_form_data"("p_form_id" bigint, "p_record_id" bigint, "p_applicant_id" "uuid") IS '從 form_data_values 創建 applications 記錄的函數';



CREATE OR REPLACE FUNCTION "public"."get_application_form_data"("p_application_id" bigint) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."get_application_form_data"("p_application_id" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_application_form_data"("p_application_id" bigint) IS '獲取申請的動態表單資料（JSON格式）';



CREATE OR REPLACE FUNCTION "public"."get_current_approvers"("p_approval_record_id" bigint) RETURNS TABLE("user_id" "uuid", "username" character varying, "role" character varying, "approver_type" character varying)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_step_id BIGINT;
  v_approver_type VARCHAR(50);
  v_approver_config JSONB;
  v_approval_departments TEXT[];
  v_approver_user_ids UUID[];
BEGIN
  -- 獲取當前步驟
  SELECT current_step_id INTO v_step_id
  FROM approval_records
  WHERE id = p_approval_record_id;

  IF v_step_id IS NULL THEN
    RETURN;
  END IF;

  -- 獲取步驟的審核人配置（包含新的欄位）
  SELECT approver_type, approver_config, approval_departments, approver_user_ids
  INTO v_approver_type, v_approver_config, v_approval_departments, v_approver_user_ids
  FROM approval_workflow_steps
  WHERE id = v_step_id;

  IF v_approver_type IS NULL THEN
    RETURN;
  END IF;

  -- 根據審核人類型返回對應的使用者
  IF v_approver_type = 'USER' THEN
    -- 返回指定的使用者（優先使用 approver_user_ids，否則使用 approver_config）
    IF v_approver_user_ids IS NOT NULL AND array_length(v_approver_user_ids, 1) > 0 THEN
      RETURN QUERY
      SELECT 
        up.id AS user_id,
        up.username,
        up.role,
        'USER'::VARCHAR(50) AS approver_type
      FROM user_profiles up
      WHERE up.id = ANY(v_approver_user_ids)
      AND up.is_active = TRUE
      -- 如果有指定審核權限部門，進一步篩選
      AND (v_approval_departments IS NULL OR array_length(v_approval_departments, 1) = 0 OR up.department = ANY(v_approval_departments));
    ELSIF v_approver_config IS NOT NULL AND v_approver_config ? 'user_ids' THEN
      RETURN QUERY
      SELECT 
        up.id AS user_id,
        up.username,
        up.role,
        'USER'::VARCHAR(50) AS approver_type
      FROM user_profiles up
      WHERE up.id::TEXT = ANY(
        SELECT jsonb_array_elements_text(v_approver_config->'user_ids')
      )
      AND up.is_active = TRUE
      -- 如果有指定審核權限部門，進一步篩選
      AND (v_approval_departments IS NULL OR array_length(v_approval_departments, 1) = 0 OR up.department = ANY(v_approval_departments));
    END IF;
  ELSIF v_approver_type = 'ROLE' THEN
    -- 返回指定角色的使用者
    RETURN QUERY
    SELECT 
      up.id AS user_id,
      up.username,
      up.role,
      'ROLE'::VARCHAR(50) AS approver_type
    FROM user_profiles up
    WHERE up.role = v_approver_config->>'role'
    AND up.is_active = TRUE
    -- 如果有指定審核權限部門，進一步篩選
    AND (v_approval_departments IS NULL OR array_length(v_approval_departments, 1) = 0 OR up.department = ANY(v_approval_departments))
    -- 如果有指定審核人列表，進一步篩選
    AND (v_approver_user_ids IS NULL OR array_length(v_approver_user_ids, 1) = 0 OR up.id = ANY(v_approver_user_ids));
  ELSIF v_approver_type = 'DEPARTMENT' THEN
    -- 返回指定部門的使用者（部門值對應 system_options 的 key）
    RETURN QUERY
    SELECT 
      up.id AS user_id,
      up.username,
      up.role,
      'DEPARTMENT'::VARCHAR(50) AS approver_type
    FROM user_profiles up
    WHERE (
      -- 從 approver_config 中取得部門
      (v_approver_config IS NOT NULL AND v_approver_config ? 'department' AND up.department = v_approver_config->>'department')
      OR
      -- 從 approver_config 中取得多個部門
      (v_approver_config IS NOT NULL AND v_approver_config ? 'departments' AND up.department = ANY(
        SELECT jsonb_array_elements_text(v_approver_config->'departments')
      ))
      OR
      -- 從 approval_departments 欄位取得部門
      (v_approval_departments IS NOT NULL AND array_length(v_approval_departments, 1) > 0 AND up.department = ANY(v_approval_departments))
    )
    AND up.is_active = TRUE
    -- 如果有指定審核人列表，進一步篩選
    AND (v_approver_user_ids IS NULL OR array_length(v_approver_user_ids, 1) = 0 OR up.id = ANY(v_approver_user_ids));
  END IF;
END;
$$;


ALTER FUNCTION "public"."get_current_approvers"("p_approval_record_id" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_current_approvers"("p_approval_record_id" bigint) IS '獲取申請的當前審核人列表（支援審核權限部門和審核人列表）';



CREATE OR REPLACE FUNCTION "public"."get_users_with_email"("p_role" character varying DEFAULT NULL::character varying, "p_is_active" boolean DEFAULT NULL::boolean, "p_search" character varying DEFAULT NULL::character varying) RETURNS TABLE("id" "uuid", "username" character varying, "role" character varying, "department" character varying, "position" character varying, "phone" character varying, "avatar_url" character varying, "is_active" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "last_login" timestamp with time zone, "last_login_ip" character varying, "email" character varying)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    up.id,
    up.username,
    up.role,
    up.department,
    up.position,
    up.phone,
    up.avatar_url,
    up.is_active,
    up.created_at,
    up.updated_at,
    up.last_login,
    up.last_login_ip,
    au.email
  FROM public.user_profiles up
  LEFT JOIN auth.users au ON up.id = au.id
  WHERE 
    (p_role IS NULL OR up.role = p_role)
    AND (p_is_active IS NULL OR up.is_active = p_is_active)
    AND (p_search IS NULL OR up.username ILIKE '%' || p_search || '%' OR au.email ILIKE '%' || p_search || '%')
  ORDER BY up.created_at DESC;
END;
$$;


ALTER FUNCTION "public"."get_users_with_email"("p_role" character varying, "p_is_active" boolean, "p_search" character varying) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_users_with_email"("p_role" character varying, "p_is_active" boolean, "p_search" character varying) IS '獲取使用者列表（包含 email），需要 SECURITY DEFINER 權限來訪問 auth.users';



CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, email, role, is_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
    NEW.email, -- 同步 email
    COALESCE(NEW.raw_user_meta_data->>'role', 'applicant'),
    FALSE  -- 新註冊用戶預設未啟用，需等待管理員審核
  );
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."migrate_application_to_form_data"("p_application_id" bigint, "p_form_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."migrate_application_to_form_data"("p_application_id" bigint, "p_form_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."migrate_field_value"("p_form_id" bigint, "p_field_key" character varying, "p_text_value" "text", "p_record_id" bigint, "p_json_value" "jsonb", "p_number_value" numeric, "p_date_value" "date", "p_datetime_value" timestamp with time zone) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."migrate_field_value"("p_form_id" bigint, "p_field_key" character varying, "p_text_value" "text", "p_record_id" bigint, "p_json_value" "jsonb", "p_number_value" numeric, "p_date_value" "date", "p_datetime_value" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_user_profiles_email"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.user_profiles up
  SET email = au.email
  FROM auth.users au
  WHERE up.id = au.id AND (up.email IS NULL OR up.email != au.email);
END;
$$;


ALTER FUNCTION "public"."sync_user_profiles_email"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_application_status"("p_application_id" bigint, "p_status" character varying, "p_approval_status" character varying, "p_approver_id" "uuid", "p_reject_reason" "text" DEFAULT NULL::"text", "p_comment" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."update_application_status"("p_application_id" bigint, "p_status" character varying, "p_approval_status" character varying, "p_approver_id" "uuid", "p_reject_reason" "text", "p_comment" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_application_status"("p_application_id" bigint, "p_status" character varying, "p_approval_status" character varying, "p_approver_id" "uuid", "p_reject_reason" "text", "p_comment" "text") IS '更新申請狀態並創建審核記錄';



CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."approval_action_logs" (
    "id" bigint NOT NULL,
    "approval_record_id" bigint NOT NULL,
    "step_id" bigint,
    "action" character varying(50) NOT NULL,
    "approver_id" "uuid",
    "approver_name" character varying(255),
    "approver_role" character varying(50),
    "from_status_code" character varying(50),
    "to_status_code" character varying(50),
    "comment" "text",
    "reason" "text",
    "action_date" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."approval_action_logs" OWNER TO "postgres";


COMMENT ON TABLE "public"."approval_action_logs" IS '審核操作記錄表：記錄每次審核操作的詳細資訊';



COMMENT ON COLUMN "public"."approval_action_logs"."action" IS '操作類型：SUBMIT=提交, APPROVE=核准, REJECT=退回, RETURN=退回修改, SKIP=跳過';



CREATE SEQUENCE IF NOT EXISTS "public"."approval_action_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."approval_action_logs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."approval_action_logs_id_seq" OWNED BY "public"."approval_action_logs"."id";



CREATE TABLE IF NOT EXISTS "public"."approval_records" (
    "id" bigint NOT NULL,
    "form_id" bigint NOT NULL,
    "record_id" bigint NOT NULL,
    "workflow_id" bigint,
    "current_step_id" bigint,
    "current_status_code" character varying(50),
    "applicant_id" "uuid" NOT NULL,
    "submit_date" timestamp with time zone DEFAULT "now"(),
    "approval_date" timestamp with time zone,
    "reject_date" timestamp with time zone,
    "reject_reason" "text",
    "is_completed" boolean DEFAULT false,
    "workflow_config" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."approval_records" OWNER TO "postgres";


COMMENT ON TABLE "public"."approval_records" IS '申請審核記錄表：追蹤每個申請的審核進度和記錄';



COMMENT ON COLUMN "public"."approval_records"."record_id" IS '申請記錄 ID：對應 form_data_values.record_id';



COMMENT ON COLUMN "public"."approval_records"."current_step_id" IS '當前步驟：null 表示流程已完成或尚未開始';



COMMENT ON COLUMN "public"."approval_records"."workflow_config" IS '流程配置快照：記錄審核時的流程配置，避免流程變更影響歷史記錄';



CREATE SEQUENCE IF NOT EXISTS "public"."approval_records_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."approval_records_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."approval_records_id_seq" OWNED BY "public"."approval_records"."id";



CREATE TABLE IF NOT EXISTS "public"."approval_statuses" (
    "id" bigint NOT NULL,
    "status_code" character varying(50) NOT NULL,
    "status_name" character varying(100) NOT NULL,
    "status_name_en" character varying(100),
    "description" "text",
    "status_type" character varying(50) DEFAULT 'INTERMEDIATE'::character varying NOT NULL,
    "color" character varying(50) DEFAULT 'grey'::character varying,
    "icon" character varying(100),
    "is_active" boolean DEFAULT true,
    "display_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."approval_statuses" OWNER TO "postgres";


COMMENT ON TABLE "public"."approval_statuses" IS '審核狀態定義表：定義系統中可用的審核狀態';



COMMENT ON COLUMN "public"."approval_statuses"."status_code" IS '狀態代碼：唯一識別碼，例如 PENDING, IN_REVIEW, APPROVED, REJECTED';



COMMENT ON COLUMN "public"."approval_statuses"."status_type" IS '狀態類型：INITIAL=初始狀態, INTERMEDIATE=中間狀態, FINAL=最終狀態';



CREATE SEQUENCE IF NOT EXISTS "public"."approval_statuses_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."approval_statuses_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."approval_statuses_id_seq" OWNED BY "public"."approval_statuses"."id";



CREATE TABLE IF NOT EXISTS "public"."approval_workflow_steps" (
    "id" bigint NOT NULL,
    "workflow_id" bigint NOT NULL,
    "step_order" integer NOT NULL,
    "step_name" character varying(255) NOT NULL,
    "step_name_en" character varying(255),
    "description" "text",
    "status_code" character varying(50),
    "approver_type" character varying(50) DEFAULT 'USER'::character varying NOT NULL,
    "approver_config" "jsonb",
    "approval_departments" "text"[],
    "approver_user_ids" "uuid"[],
    "approve_status_code" character varying(50),
    "reject_status_code" character varying(50),
    "next_step_on_approve" integer,
    "next_step_on_reject" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "is_conditional" boolean DEFAULT false NOT NULL,
    "trigger_insert_order" integer,
    "trigger_field" character varying(255),
    "trigger_value" "text",
    "trigger_operator" character varying(20) DEFAULT 'equals'::character varying NOT NULL
);


ALTER TABLE "public"."approval_workflow_steps" OWNER TO "postgres";


COMMENT ON TABLE "public"."approval_workflow_steps" IS '審核流程步驟表：定義審核流程中的每個步驟';



COMMENT ON COLUMN "public"."approval_workflow_steps"."status_code" IS '當前單據狀態：此步驟執行時的狀態';



COMMENT ON COLUMN "public"."approval_workflow_steps"."approver_type" IS '審核人類型：USER=指定使用者, ROLE=指定角色, DEPARTMENT=指定部門, AUTO=自動通過';



COMMENT ON COLUMN "public"."approval_workflow_steps"."approver_config" IS '審核人配置：JSON格式，例如 {"user_ids": ["uuid1"]} 或 {"role": "approver"}';



COMMENT ON COLUMN "public"."approval_workflow_steps"."approval_departments" IS '審核權限部門列表：對應 system_options 的 key 值，用於篩選可審核的使用者';



COMMENT ON COLUMN "public"."approval_workflow_steps"."approver_user_ids" IS '審核人 ID 列表：直接指定可審核的使用者';



COMMENT ON COLUMN "public"."approval_workflow_steps"."approve_status_code" IS '審核通過狀態：核准後要設定的狀態';



COMMENT ON COLUMN "public"."approval_workflow_steps"."reject_status_code" IS '退回狀態：退回後要設定的狀態';



COMMENT ON COLUMN "public"."approval_workflow_steps"."next_step_on_approve" IS '核准後的下一步驟：null 表示流程結束（已核准）';



COMMENT ON COLUMN "public"."approval_workflow_steps"."next_step_on_reject" IS '退回後的下一步驟：通常回到初始狀態或退回狀態';



COMMENT ON COLUMN "public"."approval_workflow_steps"."is_conditional" IS '是否為條件型流程步驟（插入於一般步驟之間）';



COMMENT ON COLUMN "public"."approval_workflow_steps"."trigger_insert_order" IS '插入位置：0 表示 0→1（第一個一般步驟前），N 表示 N→N+1';



COMMENT ON COLUMN "public"."approval_workflow_steps"."trigger_field" IS '觸發欄位：對應 form_fields.field_key';



COMMENT ON COLUMN "public"."approval_workflow_steps"."trigger_value" IS '觸發值：欄位值符合時啟用此條件步驟';



COMMENT ON COLUMN "public"."approval_workflow_steps"."trigger_operator" IS '觸發運算：equals（預設，完全相等）';



CREATE SEQUENCE IF NOT EXISTS "public"."approval_workflow_steps_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."approval_workflow_steps_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."approval_workflow_steps_id_seq" OWNED BY "public"."approval_workflow_steps"."id";



CREATE TABLE IF NOT EXISTS "public"."approval_workflows" (
    "id" bigint NOT NULL,
    "workflow_code" character varying(100) NOT NULL,
    "workflow_name" character varying(255) NOT NULL,
    "workflow_name_en" character varying(255),
    "description" "text",
    "is_default" boolean DEFAULT false,
    "is_active" boolean DEFAULT true,
    "initial_status_code" character varying(50),
    "final_status_code" character varying(50),
    "reject_status_code" character varying(50),
    "created_by_id" "uuid",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."approval_workflows" OWNER TO "postgres";


COMMENT ON TABLE "public"."approval_workflows" IS '審核流程配置表：定義審核流程（所有表單共用）';



COMMENT ON COLUMN "public"."approval_workflows"."workflow_code" IS '流程代碼：唯一識別碼，例如 default_workflow';



CREATE SEQUENCE IF NOT EXISTS "public"."approval_workflows_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."approval_workflows_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."approval_workflows_id_seq" OWNED BY "public"."approval_workflows"."id";



CREATE TABLE IF NOT EXISTS "public"."attachments" (
    "id" bigint NOT NULL,
    "form_id" bigint,
    "record_id" bigint,
    "file_name" character varying(255) NOT NULL,
    "original_file_name" character varying(255) NOT NULL,
    "file_type" character varying(50) NOT NULL,
    "file_size" bigint NOT NULL,
    "mime_type" character varying(100),
    "file_url" character varying(500) NOT NULL,
    "thumbnail_url" character varying(500),
    "uploaded_by_id" "uuid" NOT NULL,
    "uploaded_at" timestamp with time zone DEFAULT "now"(),
    "description" "text"
);


ALTER TABLE "public"."attachments" OWNER TO "postgres";


COMMENT ON TABLE "public"."attachments" IS '附件表：申請的附件檔案';



COMMENT ON COLUMN "public"."attachments"."file_type" IS '檔案類型：image=圖片, document=文件, drawing=圖面, other=其他';



CREATE SEQUENCE IF NOT EXISTS "public"."attachments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."attachments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."attachments_id_seq" OWNED BY "public"."attachments"."id";



CREATE TABLE IF NOT EXISTS "public"."code_counters" (
    "id" bigint NOT NULL,
    "key" character varying(50) NOT NULL,
    "counter" integer DEFAULT 0 NOT NULL,
    "last_used_date" timestamp with time zone,
    "last_used_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."code_counters" OWNER TO "postgres";


COMMENT ON TABLE "public"."code_counters" IS '編碼計數器表：用於產生料號的流水號計數器';



CREATE SEQUENCE IF NOT EXISTS "public"."code_counters_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."code_counters_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."code_counters_id_seq" OWNED BY "public"."code_counters"."id";



CREATE TABLE IF NOT EXISTS "public"."departments" (
    "id" bigint NOT NULL,
    "department_code" character varying(50) NOT NULL,
    "department_name" character varying(100) NOT NULL,
    "department_name_en" character varying(100),
    "parent_id" bigint,
    "manager_id" "uuid",
    "description" "text",
    "is_active" boolean DEFAULT true,
    "display_order" integer DEFAULT 0,
    "created_by_id" "uuid",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."departments" OWNER TO "postgres";


COMMENT ON TABLE "public"."departments" IS '部門表：定義組織中的各個部門';



COMMENT ON COLUMN "public"."departments"."department_code" IS '部門代碼：唯一識別碼（如：IT, HR, FINANCE）';



COMMENT ON COLUMN "public"."departments"."department_name" IS '部門名稱（中文）';



COMMENT ON COLUMN "public"."departments"."parent_id" IS '上級部門ID：支援階層結構，NULL表示頂層部門';



COMMENT ON COLUMN "public"."departments"."manager_id" IS '部門主管ID：關聯到 user_profiles.id';



COMMENT ON COLUMN "public"."departments"."is_active" IS '是否啟用：停用的部門將無法分配給新用戶';



CREATE SEQUENCE IF NOT EXISTS "public"."departments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."departments_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."departments_id_seq" OWNED BY "public"."departments"."id";



CREATE TABLE IF NOT EXISTS "public"."export_logs" (
    "id" bigint NOT NULL,
    "category" character varying(50),
    "status" character varying(50),
    "start_date" "date",
    "end_date" "date",
    "record_count" integer,
    "file_name" character varying(255) NOT NULL,
    "file_path" character varying(500),
    "file_size" bigint,
    "format" character varying(20),
    "exported_by_id" "uuid" NOT NULL,
    "exported_at" timestamp with time zone DEFAULT "now"(),
    "download_count" integer DEFAULT 0
);


ALTER TABLE "public"."export_logs" OWNER TO "postgres";


COMMENT ON TABLE "public"."export_logs" IS '匯出記錄表：記錄Excel匯出操作';



CREATE SEQUENCE IF NOT EXISTS "public"."export_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."export_logs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."export_logs_id_seq" OWNED BY "public"."export_logs"."id";



CREATE TABLE IF NOT EXISTS "public"."form_data_values" (
    "id" bigint NOT NULL,
    "form_id" bigint NOT NULL,
    "field_id" bigint NOT NULL,
    "record_id" bigint,
    "field_key" character varying(100) NOT NULL,
    "field_value" "text",
    "field_value_json" "jsonb",
    "field_value_number" numeric,
    "field_value_date" "date",
    "field_value_datetime" timestamp with time zone,
    "file_url" character varying(500),
    "created_by_id" "uuid",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."form_data_values" OWNER TO "postgres";


COMMENT ON TABLE "public"."form_data_values" IS '表單資料值表：儲存動態欄位的實際資料值';



COMMENT ON COLUMN "public"."form_data_values"."record_id" IS '記錄ID：可關聯到其他表的記錄，例如 application_id';



COMMENT ON COLUMN "public"."form_data_values"."field_value" IS '欄位值（文字）：用於儲存 text, textarea, select, radio 等類型的值';



COMMENT ON COLUMN "public"."form_data_values"."field_value_json" IS '欄位值（JSON）：用於儲存 multiselect, checkbox, json 等類型的值';



COMMENT ON COLUMN "public"."form_data_values"."field_value_number" IS '欄位值（數字）：用於儲存 number 類型的值';



COMMENT ON COLUMN "public"."form_data_values"."field_value_date" IS '欄位值（日期）：用於儲存 date 類型的值';



COMMENT ON COLUMN "public"."form_data_values"."field_value_datetime" IS '欄位值（日期時間）：用於儲存 datetime 類型的值';



COMMENT ON COLUMN "public"."form_data_values"."file_url" IS '檔案URL：用於儲存 file 類型的檔案路徑';



CREATE SEQUENCE IF NOT EXISTS "public"."form_data_values_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."form_data_values_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."form_data_values_id_seq" OWNED BY "public"."form_data_values"."id";



CREATE TABLE IF NOT EXISTS "public"."form_fields" (
    "id" bigint NOT NULL,
    "form_id" bigint NOT NULL,
    "field_key" character varying(100) NOT NULL,
    "field_label" character varying(255) NOT NULL,
    "field_label_en" character varying(255),
    "field_type" character varying(50) NOT NULL,
    "max_length" integer,
    "is_required" boolean DEFAULT false,
    "field_group" character varying(100),
    "sub_group" character varying(100),
    "display_order" integer DEFAULT 0,
    "field_config" "jsonb",
    "default_value" "text",
    "placeholder" "text",
    "help_text" "text",
    "validation_rules" "jsonb",
    "is_visible" boolean DEFAULT true,
    "is_readonly" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "is_in_template" boolean DEFAULT false
);


ALTER TABLE "public"."form_fields" OWNER TO "postgres";


COMMENT ON TABLE "public"."form_fields" IS '表單欄位定義表：儲存表單的欄位定義資訊';



COMMENT ON COLUMN "public"."form_fields"."field_type" IS '欄位類型：text=文字, textarea=多行文字, number=數字, select=下拉選單, multiselect=多選下拉, checkbox=複選框, radio=單選框, date=日期, datetime=日期時間, file=檔案, json=JSON資料';



COMMENT ON COLUMN "public"."form_fields"."field_group" IS '欄位群組：用於分組顯示，例如「基本資訊」、「分類資訊」等';



COMMENT ON COLUMN "public"."form_fields"."sub_group" IS '子群組名稱：用於排版顯示，例如「基本資訊區塊」、「詳細資訊區塊」等';



COMMENT ON COLUMN "public"."form_fields"."is_in_template" IS '是否加入模板：記錄該欄位是否出現在包裝模板設定中';



CREATE SEQUENCE IF NOT EXISTS "public"."form_fields_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."form_fields_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."form_fields_id_seq" OWNED BY "public"."form_fields"."id";



CREATE TABLE IF NOT EXISTS "public"."forms" (
    "id" bigint NOT NULL,
    "form_code" character varying(100) NOT NULL,
    "form_name" character varying(255) NOT NULL,
    "form_name_en" character varying(255),
    "description" "text",
    "version" integer DEFAULT 1,
    "is_active" boolean DEFAULT true,
    "is_default" boolean DEFAULT false,
    "form_config" "jsonb",
    "created_by_id" "uuid",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."forms" OWNER TO "postgres";


COMMENT ON TABLE "public"."forms" IS '表單定義主表：儲存表單的基本定義資訊';



COMMENT ON COLUMN "public"."forms"."form_code" IS '表單代碼：唯一識別碼，例如 material_application';



COMMENT ON COLUMN "public"."forms"."form_config" IS '表單設定：JSON格式，可儲存表單級別的額外設定';



CREATE SEQUENCE IF NOT EXISTS "public"."forms_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."forms_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."forms_id_seq" OWNED BY "public"."forms"."id";



CREATE TABLE IF NOT EXISTS "public"."option_workbook_columns" (
    "id" bigint NOT NULL,
    "workbook_id" bigint NOT NULL,
    "column_key" character varying(100) NOT NULL,
    "column_label" character varying(255) NOT NULL,
    "column_type" character varying(50) DEFAULT 'text'::character varying,
    "is_key" boolean DEFAULT false,
    "is_label" boolean DEFAULT false,
    "is_option_source" boolean DEFAULT false,
    "display_order" integer DEFAULT 0,
    "column_config" "jsonb",
    "is_visible" boolean DEFAULT true,
    "is_required" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."option_workbook_columns" OWNER TO "postgres";


COMMENT ON TABLE "public"."option_workbook_columns" IS '選項活頁簿欄位定義表：定義活頁簿的欄位結構';



COMMENT ON COLUMN "public"."option_workbook_columns"."column_key" IS '欄位鍵值：用於儲存和讀取資料';



COMMENT ON COLUMN "public"."option_workbook_columns"."column_label" IS '欄位標籤：顯示給使用者看的欄位名稱';



COMMENT ON COLUMN "public"."option_workbook_columns"."is_key" IS '是否為key欄位：用於識別記錄的唯一值';



COMMENT ON COLUMN "public"."option_workbook_columns"."is_label" IS '是否為label欄位：用於顯示記錄的名稱';



COMMENT ON COLUMN "public"."option_workbook_columns"."is_option_source" IS '是否作為選項來源：此欄位的值可以作為表單選項使用';



COMMENT ON COLUMN "public"."option_workbook_columns"."column_config" IS '欄位設定：JSON格式，可儲存選項列表、驗證規則等';



CREATE SEQUENCE IF NOT EXISTS "public"."option_workbook_columns_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."option_workbook_columns_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."option_workbook_columns_id_seq" OWNED BY "public"."option_workbook_columns"."id";



CREATE TABLE IF NOT EXISTS "public"."option_workbook_rows" (
    "id" bigint NOT NULL,
    "workbook_id" bigint NOT NULL,
    "row_key" character varying(100) NOT NULL,
    "row_label" character varying(255) NOT NULL,
    "row_data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "display_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_by_id" "uuid",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."option_workbook_rows" OWNER TO "postgres";


COMMENT ON TABLE "public"."option_workbook_rows" IS '選項活頁簿資料表：儲存活頁簿的實際資料';



COMMENT ON COLUMN "public"."option_workbook_rows"."row_key" IS '資料行的key值：用於識別記錄的唯一值';



COMMENT ON COLUMN "public"."option_workbook_rows"."row_label" IS '資料行的label值：用於顯示記錄的名稱';



COMMENT ON COLUMN "public"."option_workbook_rows"."row_data" IS '其他欄位資料：JSON格式，儲存除key和label外的所有欄位資料';



CREATE SEQUENCE IF NOT EXISTS "public"."option_workbook_rows_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."option_workbook_rows_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."option_workbook_rows_id_seq" OWNED BY "public"."option_workbook_rows"."id";



CREATE TABLE IF NOT EXISTS "public"."option_workbooks" (
    "id" bigint NOT NULL,
    "workbook_key" character varying(100) NOT NULL,
    "workbook_name" character varying(255) NOT NULL,
    "description" "text",
    "is_active" boolean DEFAULT true,
    "created_by_id" "uuid",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."option_workbooks" OWNER TO "postgres";


COMMENT ON TABLE "public"."option_workbooks" IS '選項活頁簿主表：儲存活頁簿的基本資訊';



COMMENT ON COLUMN "public"."option_workbooks"."workbook_key" IS '活頁簿唯一識別碼：用於系統內部引用';



COMMENT ON COLUMN "public"."option_workbooks"."workbook_name" IS '活頁簿名稱：顯示給使用者看的分頁名稱';



CREATE SEQUENCE IF NOT EXISTS "public"."option_workbooks_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."option_workbooks_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."option_workbooks_id_seq" OWNED BY "public"."option_workbooks"."id";



CREATE TABLE IF NOT EXISTS "public"."packaging_templates" (
    "id" bigint NOT NULL,
    "form_id" bigint NOT NULL,
    "template_type" character varying(50) NOT NULL,
    "template_values" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_by_id" "uuid",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."packaging_templates" OWNER TO "postgres";


COMMENT ON TABLE "public"."packaging_templates" IS '包裝說明模板表：儲存不同產品類型的包裝說明模板值';



COMMENT ON COLUMN "public"."packaging_templates"."form_id" IS '所屬表單 ID';



COMMENT ON COLUMN "public"."packaging_templates"."template_type" IS '模板類型：H=手把, S=滑軌, M=模組, D=裝飾五金, F=功能五金, B=建築五金, I=工業零件, O=其他';



COMMENT ON COLUMN "public"."packaging_templates"."template_values" IS '模板值：JSON格式，儲存欄位鍵值對，例如：{"field_key1": "value1", "field_key2": "value2"}';



CREATE SEQUENCE IF NOT EXISTS "public"."packaging_templates_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."packaging_templates_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."packaging_templates_id_seq" OWNED BY "public"."packaging_templates"."id";



CREATE TABLE IF NOT EXISTS "public"."user_profiles" (
    "id" "uuid" NOT NULL,
    "username" character varying(100),
    "role" character varying(50) DEFAULT 'applicant'::character varying NOT NULL,
    "department" character varying(100),
    "position" character varying(100),
    "phone" character varying(50),
    "avatar_url" character varying(500),
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "last_login" timestamp with time zone,
    "last_login_ip" character varying(50),
    "email" character varying(255)
);


ALTER TABLE "public"."user_profiles" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_profiles" IS '使用者資料表：儲存應用程式特定的使用者資料，關聯到 auth.users';



COMMENT ON COLUMN "public"."user_profiles"."id" IS '使用者ID：關聯到 auth.users.id (UUID)';



COMMENT ON COLUMN "public"."user_profiles"."role" IS '角色：admin=系統管理員, approver=審核人員, applicant=申請人員';



COMMENT ON COLUMN "public"."user_profiles"."department" IS '部門代碼：對應到 departments.department_code，儲存部門的唯一識別碼（如：IT, HR, FINANCE）';



COMMENT ON COLUMN "public"."user_profiles"."email" IS 'Email（從 auth.users 同步）';



CREATE OR REPLACE VIEW "public"."pending_approval_applications_view" AS
 SELECT DISTINCT "ar"."id" AS "approval_record_id",
    "ar"."form_id",
    "ar"."record_id",
    "ar"."workflow_id",
    "ar"."current_step_id",
    "ar"."current_status_code",
    "ar"."applicant_id",
    "ar"."submit_date",
    "ar"."approval_date",
    "ar"."reject_date",
    "ar"."reject_reason",
    "ar"."is_completed",
    "up"."username" AS "applicant_username",
    "aws"."step_name" AS "current_step_name",
    "aws"."step_order" AS "current_step_order",
    "ast"."status_name" AS "current_status_name",
    "ast"."color" AS "status_color",
    "ast"."icon" AS "status_icon",
    "aw"."workflow_name",
    "aw"."workflow_code"
   FROM (((("public"."approval_records" "ar"
     LEFT JOIN "public"."user_profiles" "up" ON (("ar"."applicant_id" = "up"."id")))
     LEFT JOIN "public"."approval_workflow_steps" "aws" ON (("ar"."current_step_id" = "aws"."id")))
     LEFT JOIN "public"."approval_statuses" "ast" ON ((("ar"."current_status_code")::"text" = ("ast"."status_code")::"text")))
     LEFT JOIN "public"."approval_workflows" "aw" ON (("ar"."workflow_id" = "aw"."id")))
  WHERE ("ar"."is_completed" = false)
  ORDER BY "ar"."submit_date" DESC;


ALTER VIEW "public"."pending_approval_applications_view" OWNER TO "postgres";


COMMENT ON VIEW "public"."pending_approval_applications_view" IS '待審核申請列表視圖：包含審核流程資訊';



CREATE TABLE IF NOT EXISTS "public"."permissions" (
    "id" bigint NOT NULL,
    "permission_code" character varying(100) NOT NULL,
    "permission_name" character varying(100) NOT NULL,
    "permission_name_en" character varying(100),
    "module" character varying(100),
    "description" "text",
    "is_system_permission" boolean DEFAULT false,
    "is_active" boolean DEFAULT true,
    "display_order" integer DEFAULT 0,
    "created_by_id" "uuid",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."permissions" OWNER TO "postgres";


COMMENT ON TABLE "public"."permissions" IS '權限表：定義系統中的各種權限';



COMMENT ON COLUMN "public"."permissions"."permission_code" IS '權限代碼：唯一識別碼（如：APPLY, REVIEW, SETTINGS）';



COMMENT ON COLUMN "public"."permissions"."permission_name" IS '權限名稱（中文）';



COMMENT ON COLUMN "public"."permissions"."module" IS '所屬模組：權限所屬的功能模組';



COMMENT ON COLUMN "public"."permissions"."is_system_permission" IS '是否為系統內建權限：系統內建權限不可刪除';



COMMENT ON COLUMN "public"."permissions"."is_active" IS '是否啟用：停用的權限將無法分配給角色';



CREATE SEQUENCE IF NOT EXISTS "public"."permissions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."permissions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."permissions_id_seq" OWNED BY "public"."permissions"."id";



CREATE TABLE IF NOT EXISTS "public"."role_page_access" (
    "id" bigint NOT NULL,
    "role_id" bigint NOT NULL,
    "page_code" character varying(100) NOT NULL,
    "page_name" character varying(100) NOT NULL,
    "is_accessible" boolean DEFAULT true,
    "created_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."role_page_access" OWNER TO "postgres";


COMMENT ON TABLE "public"."role_page_access" IS '角色頁面權限關聯表：定義哪些角色可以訪問哪些頁面';



COMMENT ON COLUMN "public"."role_page_access"."role_id" IS '角色ID';



COMMENT ON COLUMN "public"."role_page_access"."page_code" IS '頁面代碼：唯一識別碼（如：apply, packaging, review）';



COMMENT ON COLUMN "public"."role_page_access"."page_name" IS '頁面名稱（中文）';



COMMENT ON COLUMN "public"."role_page_access"."is_accessible" IS '是否可以訪問：控制角色是否可以訪問該頁面';



CREATE SEQUENCE IF NOT EXISTS "public"."role_page_access_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."role_page_access_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."role_page_access_id_seq" OWNED BY "public"."role_page_access"."id";



CREATE TABLE IF NOT EXISTS "public"."role_permissions" (
    "id" bigint NOT NULL,
    "role_id" bigint NOT NULL,
    "permission_id" bigint NOT NULL,
    "created_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."role_permissions" OWNER TO "postgres";


COMMENT ON TABLE "public"."role_permissions" IS '角色權限關聯表：定義哪些角色擁有哪些權限';



COMMENT ON COLUMN "public"."role_permissions"."role_id" IS '角色ID';



COMMENT ON COLUMN "public"."role_permissions"."permission_id" IS '權限ID';



CREATE SEQUENCE IF NOT EXISTS "public"."role_permissions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."role_permissions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."role_permissions_id_seq" OWNED BY "public"."role_permissions"."id";



CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" bigint NOT NULL,
    "role_code" character varying(50) NOT NULL,
    "role_name" character varying(100) NOT NULL,
    "role_name_en" character varying(100),
    "description" "text",
    "is_system_role" boolean DEFAULT false,
    "is_active" boolean DEFAULT true,
    "display_order" integer DEFAULT 0,
    "created_by_id" "uuid",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


COMMENT ON TABLE "public"."roles" IS '角色表：定義系統中的各種角色';



COMMENT ON COLUMN "public"."roles"."role_code" IS '角色代碼：唯一識別碼（如：admin, approver, applicant）';



COMMENT ON COLUMN "public"."roles"."role_name" IS '角色名稱（中文）';



COMMENT ON COLUMN "public"."roles"."is_system_role" IS '是否為系統內建角色：系統內建角色不可刪除';



COMMENT ON COLUMN "public"."roles"."is_active" IS '是否啟用：停用的角色將無法分配給新用戶';



CREATE SEQUENCE IF NOT EXISTS "public"."roles_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."roles_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."roles_id_seq" OWNED BY "public"."roles"."id";



CREATE TABLE IF NOT EXISTS "public"."system_options" (
    "id" bigint NOT NULL,
    "module" character varying(100) NOT NULL,
    "cate" character varying(100) NOT NULL,
    "parent_key" character varying(100) DEFAULT NULL::character varying,
    "key" character varying(100) NOT NULL,
    "value" "text" NOT NULL,
    "label" character varying(255) DEFAULT NULL::character varying,
    "desc" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."system_options" OWNER TO "postgres";


COMMENT ON TABLE "public"."system_options" IS '系統參數資料表：儲存系統設定類的選項參數（狀態、優先級、角色等）';



COMMENT ON COLUMN "public"."system_options"."module" IS '模組名稱：在哪一個表單使用的參數';



COMMENT ON COLUMN "public"."system_options"."cate" IS '類別名稱：變數名稱移除 Options';



COMMENT ON COLUMN "public"."system_options"."parent_key" IS '父層鍵值：多層參數時父層的 key';



COMMENT ON COLUMN "public"."system_options"."key" IS '鍵值：對應物件的 Key';



COMMENT ON COLUMN "public"."system_options"."value" IS '值：對應物件的 value';



COMMENT ON COLUMN "public"."system_options"."label" IS '標籤：顯示用的中文標籤';



COMMENT ON COLUMN "public"."system_options"."desc" IS '說明：詳細描述';



CREATE SEQUENCE IF NOT EXISTS "public"."system_options_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."system_options_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."system_options_id_seq" OWNED BY "public"."system_options"."id";



CREATE TABLE IF NOT EXISTS "public"."system_settings" (
    "id" bigint NOT NULL,
    "setting_key" character varying(100) NOT NULL,
    "setting_value" "text" NOT NULL,
    "setting_type" character varying(50) DEFAULT 'string'::character varying,
    "description" "text",
    "updated_by_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."system_settings" OWNER TO "postgres";


COMMENT ON TABLE "public"."system_settings" IS '系統設定表：儲存系統設定值';



COMMENT ON COLUMN "public"."system_settings"."setting_type" IS '設定類型：string=字串, number=數字, boolean=布林值, json=JSON格式';



CREATE SEQUENCE IF NOT EXISTS "public"."system_settings_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."system_settings_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."system_settings_id_seq" OWNED BY "public"."system_settings"."id";



ALTER TABLE ONLY "public"."approval_action_logs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."approval_action_logs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."approval_records" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."approval_records_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."approval_statuses" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."approval_statuses_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."approval_workflow_steps" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."approval_workflow_steps_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."approval_workflows" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."approval_workflows_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."attachments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."attachments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."code_counters" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."code_counters_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."departments" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."departments_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."export_logs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."export_logs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."form_data_values" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."form_data_values_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."form_fields" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."form_fields_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."forms" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."forms_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."option_workbook_columns" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."option_workbook_columns_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."option_workbook_rows" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."option_workbook_rows_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."option_workbooks" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."option_workbooks_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."packaging_templates" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."packaging_templates_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."permissions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."permissions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."role_page_access" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."role_page_access_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."role_permissions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."role_permissions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."roles" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."roles_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."system_options" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."system_options_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."system_settings" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."system_settings_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."approval_action_logs"
    ADD CONSTRAINT "approval_action_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."approval_records"
    ADD CONSTRAINT "approval_records_form_id_record_id_key" UNIQUE ("form_id", "record_id");



ALTER TABLE ONLY "public"."approval_records"
    ADD CONSTRAINT "approval_records_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."approval_statuses"
    ADD CONSTRAINT "approval_statuses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."approval_statuses"
    ADD CONSTRAINT "approval_statuses_status_code_key" UNIQUE ("status_code");



ALTER TABLE ONLY "public"."approval_workflow_steps"
    ADD CONSTRAINT "approval_workflow_steps_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."approval_workflow_steps"
    ADD CONSTRAINT "approval_workflow_steps_workflow_id_step_order_key" UNIQUE ("workflow_id", "step_order");



ALTER TABLE ONLY "public"."approval_workflows"
    ADD CONSTRAINT "approval_workflows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."approval_workflows"
    ADD CONSTRAINT "approval_workflows_workflow_code_key" UNIQUE ("workflow_code");



ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."code_counters"
    ADD CONSTRAINT "code_counters_key_key" UNIQUE ("key");



ALTER TABLE ONLY "public"."code_counters"
    ADD CONSTRAINT "code_counters_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_department_code_key" UNIQUE ("department_code");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."export_logs"
    ADD CONSTRAINT "export_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."form_data_values"
    ADD CONSTRAINT "form_data_values_form_id_field_id_record_id_field_key_key" UNIQUE ("form_id", "field_id", "record_id", "field_key");



ALTER TABLE ONLY "public"."form_data_values"
    ADD CONSTRAINT "form_data_values_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."form_fields"
    ADD CONSTRAINT "form_fields_form_id_field_key_key" UNIQUE ("form_id", "field_key");



ALTER TABLE ONLY "public"."form_fields"
    ADD CONSTRAINT "form_fields_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."forms"
    ADD CONSTRAINT "forms_form_code_key" UNIQUE ("form_code");



ALTER TABLE ONLY "public"."forms"
    ADD CONSTRAINT "forms_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."option_workbook_columns"
    ADD CONSTRAINT "option_workbook_columns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."option_workbook_columns"
    ADD CONSTRAINT "option_workbook_columns_workbook_id_column_key_key" UNIQUE ("workbook_id", "column_key");



ALTER TABLE ONLY "public"."option_workbook_rows"
    ADD CONSTRAINT "option_workbook_rows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."option_workbook_rows"
    ADD CONSTRAINT "option_workbook_rows_workbook_id_row_key_key" UNIQUE ("workbook_id", "row_key");



ALTER TABLE ONLY "public"."option_workbooks"
    ADD CONSTRAINT "option_workbooks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."option_workbooks"
    ADD CONSTRAINT "option_workbooks_workbook_key_key" UNIQUE ("workbook_key");



ALTER TABLE ONLY "public"."packaging_templates"
    ADD CONSTRAINT "packaging_templates_form_id_template_type_key" UNIQUE ("form_id", "template_type");



ALTER TABLE ONLY "public"."packaging_templates"
    ADD CONSTRAINT "packaging_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_permission_code_key" UNIQUE ("permission_code");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_page_access"
    ADD CONSTRAINT "role_page_access_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_page_access"
    ADD CONSTRAINT "role_page_access_role_id_page_code_key" UNIQUE ("role_id", "page_code");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_permission_id_key" UNIQUE ("role_id", "permission_id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_role_code_key" UNIQUE ("role_code");



ALTER TABLE ONLY "public"."system_options"
    ADD CONSTRAINT "system_options_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_settings"
    ADD CONSTRAINT "system_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_settings"
    ADD CONSTRAINT "system_settings_setting_key_key" UNIQUE ("setting_key");



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_username_key" UNIQUE ("username");



CREATE INDEX "idx_approval_action_logs_action" ON "public"."approval_action_logs" USING "btree" ("action");



CREATE INDEX "idx_approval_action_logs_action_date" ON "public"."approval_action_logs" USING "btree" ("action_date");



CREATE INDEX "idx_approval_action_logs_approval_record_id" ON "public"."approval_action_logs" USING "btree" ("approval_record_id");



CREATE INDEX "idx_approval_action_logs_approver_id" ON "public"."approval_action_logs" USING "btree" ("approver_id");



CREATE INDEX "idx_approval_action_logs_step_id" ON "public"."approval_action_logs" USING "btree" ("step_id");



CREATE INDEX "idx_approval_records_applicant_id" ON "public"."approval_records" USING "btree" ("applicant_id");



CREATE INDEX "idx_approval_records_current_status_code" ON "public"."approval_records" USING "btree" ("current_status_code");



CREATE INDEX "idx_approval_records_current_step_id" ON "public"."approval_records" USING "btree" ("current_step_id");



CREATE INDEX "idx_approval_records_form_id" ON "public"."approval_records" USING "btree" ("form_id");



CREATE INDEX "idx_approval_records_form_record" ON "public"."approval_records" USING "btree" ("form_id", "record_id");



CREATE INDEX "idx_approval_records_is_completed" ON "public"."approval_records" USING "btree" ("is_completed");



CREATE INDEX "idx_approval_records_record_id" ON "public"."approval_records" USING "btree" ("record_id");



CREATE INDEX "idx_approval_records_submit_date" ON "public"."approval_records" USING "btree" ("submit_date");



CREATE INDEX "idx_approval_records_workflow_id" ON "public"."approval_records" USING "btree" ("workflow_id");



CREATE INDEX "idx_approval_statuses_is_active" ON "public"."approval_statuses" USING "btree" ("is_active");



CREATE INDEX "idx_approval_statuses_status_code" ON "public"."approval_statuses" USING "btree" ("status_code");



CREATE INDEX "idx_approval_statuses_status_type" ON "public"."approval_statuses" USING "btree" ("status_type");



CREATE INDEX "idx_approval_workflow_steps_conditional" ON "public"."approval_workflow_steps" USING "btree" ("workflow_id", "is_conditional", "trigger_insert_order");



CREATE INDEX "idx_approval_workflow_steps_status_code" ON "public"."approval_workflow_steps" USING "btree" ("status_code");



CREATE INDEX "idx_approval_workflow_steps_step_order" ON "public"."approval_workflow_steps" USING "btree" ("workflow_id", "step_order");



CREATE INDEX "idx_approval_workflow_steps_workflow_id" ON "public"."approval_workflow_steps" USING "btree" ("workflow_id");



CREATE INDEX "idx_approval_workflows_is_active" ON "public"."approval_workflows" USING "btree" ("is_active");



CREATE INDEX "idx_approval_workflows_is_default" ON "public"."approval_workflows" USING "btree" ("is_default");



CREATE INDEX "idx_approval_workflows_workflow_code" ON "public"."approval_workflows" USING "btree" ("workflow_code");



CREATE INDEX "idx_attachments_file_type" ON "public"."attachments" USING "btree" ("file_type");



CREATE INDEX "idx_attachments_form_id" ON "public"."attachments" USING "btree" ("form_id");



CREATE INDEX "idx_attachments_record_id" ON "public"."attachments" USING "btree" ("record_id");



CREATE INDEX "idx_attachments_uploaded_by_id" ON "public"."attachments" USING "btree" ("uploaded_by_id");



CREATE INDEX "idx_code_counters_key" ON "public"."code_counters" USING "btree" ("key");



CREATE INDEX "idx_departments_department_code" ON "public"."departments" USING "btree" ("department_code");



CREATE INDEX "idx_departments_display_order" ON "public"."departments" USING "btree" ("display_order");



CREATE INDEX "idx_departments_is_active" ON "public"."departments" USING "btree" ("is_active");



CREATE INDEX "idx_departments_manager_id" ON "public"."departments" USING "btree" ("manager_id");



CREATE INDEX "idx_departments_parent_id" ON "public"."departments" USING "btree" ("parent_id");



CREATE INDEX "idx_export_logs_exported_at" ON "public"."export_logs" USING "btree" ("exported_at");



CREATE INDEX "idx_export_logs_exported_by_id" ON "public"."export_logs" USING "btree" ("exported_by_id");



CREATE INDEX "idx_export_logs_status" ON "public"."export_logs" USING "btree" ("status");



CREATE INDEX "idx_form_data_values_created_by_id" ON "public"."form_data_values" USING "btree" ("created_by_id");



CREATE INDEX "idx_form_data_values_field_id" ON "public"."form_data_values" USING "btree" ("field_id");



CREATE INDEX "idx_form_data_values_field_key" ON "public"."form_data_values" USING "btree" ("field_key");



CREATE INDEX "idx_form_data_values_form_id" ON "public"."form_data_values" USING "btree" ("form_id");



CREATE INDEX "idx_form_data_values_form_record" ON "public"."form_data_values" USING "btree" ("form_id", "record_id");



CREATE INDEX "idx_form_data_values_record_id" ON "public"."form_data_values" USING "btree" ("record_id");



CREATE INDEX "idx_form_fields_display_order" ON "public"."form_fields" USING "btree" ("form_id", "display_order");



CREATE INDEX "idx_form_fields_field_group" ON "public"."form_fields" USING "btree" ("field_group");



CREATE INDEX "idx_form_fields_field_key" ON "public"."form_fields" USING "btree" ("field_key");



CREATE INDEX "idx_form_fields_field_type" ON "public"."form_fields" USING "btree" ("field_type");



CREATE INDEX "idx_form_fields_form_id" ON "public"."form_fields" USING "btree" ("form_id");



CREATE INDEX "idx_form_fields_is_in_template" ON "public"."form_fields" USING "btree" ("is_in_template");



CREATE INDEX "idx_form_fields_is_visible" ON "public"."form_fields" USING "btree" ("is_visible");



CREATE INDEX "idx_form_fields_sub_group" ON "public"."form_fields" USING "btree" ("form_id", "field_group", "sub_group");



CREATE INDEX "idx_forms_created_by_id" ON "public"."forms" USING "btree" ("created_by_id");



CREATE INDEX "idx_forms_form_code" ON "public"."forms" USING "btree" ("form_code");



CREATE INDEX "idx_forms_is_active" ON "public"."forms" USING "btree" ("is_active");



CREATE INDEX "idx_forms_is_default" ON "public"."forms" USING "btree" ("is_default");



CREATE INDEX "idx_option_workbook_columns_display_order" ON "public"."option_workbook_columns" USING "btree" ("workbook_id", "display_order");



CREATE INDEX "idx_option_workbook_columns_is_option_source" ON "public"."option_workbook_columns" USING "btree" ("workbook_id", "is_option_source");



CREATE INDEX "idx_option_workbook_columns_workbook_id" ON "public"."option_workbook_columns" USING "btree" ("workbook_id");



CREATE INDEX "idx_option_workbook_rows_display_order" ON "public"."option_workbook_rows" USING "btree" ("workbook_id", "display_order");



CREATE INDEX "idx_option_workbook_rows_is_active" ON "public"."option_workbook_rows" USING "btree" ("workbook_id", "is_active");



CREATE INDEX "idx_option_workbook_rows_row_key" ON "public"."option_workbook_rows" USING "btree" ("workbook_id", "row_key");



CREATE INDEX "idx_option_workbook_rows_workbook_id" ON "public"."option_workbook_rows" USING "btree" ("workbook_id");



CREATE INDEX "idx_option_workbooks_is_active" ON "public"."option_workbooks" USING "btree" ("is_active");



CREATE INDEX "idx_option_workbooks_workbook_key" ON "public"."option_workbooks" USING "btree" ("workbook_key");



CREATE INDEX "idx_packaging_templates_form_id" ON "public"."packaging_templates" USING "btree" ("form_id");



CREATE INDEX "idx_packaging_templates_form_type" ON "public"."packaging_templates" USING "btree" ("form_id", "template_type");



CREATE INDEX "idx_packaging_templates_template_type" ON "public"."packaging_templates" USING "btree" ("template_type");



CREATE INDEX "idx_permissions_display_order" ON "public"."permissions" USING "btree" ("display_order");



CREATE INDEX "idx_permissions_is_active" ON "public"."permissions" USING "btree" ("is_active");



CREATE INDEX "idx_permissions_module" ON "public"."permissions" USING "btree" ("module");



CREATE INDEX "idx_permissions_permission_code" ON "public"."permissions" USING "btree" ("permission_code");



CREATE INDEX "idx_role_page_access_page_code" ON "public"."role_page_access" USING "btree" ("page_code");



CREATE INDEX "idx_role_page_access_role_id" ON "public"."role_page_access" USING "btree" ("role_id");



CREATE INDEX "idx_role_permissions_permission_id" ON "public"."role_permissions" USING "btree" ("permission_id");



CREATE INDEX "idx_role_permissions_role_id" ON "public"."role_permissions" USING "btree" ("role_id");



CREATE INDEX "idx_roles_display_order" ON "public"."roles" USING "btree" ("display_order");



CREATE INDEX "idx_roles_is_active" ON "public"."roles" USING "btree" ("is_active");



CREATE INDEX "idx_roles_role_code" ON "public"."roles" USING "btree" ("role_code");



CREATE INDEX "idx_system_options_cate" ON "public"."system_options" USING "btree" ("cate");



CREATE INDEX "idx_system_options_module" ON "public"."system_options" USING "btree" ("module");



CREATE INDEX "idx_system_options_module_cate" ON "public"."system_options" USING "btree" ("module", "cate");



CREATE UNIQUE INDEX "idx_system_options_unique" ON "public"."system_options" USING "btree" ("module", "cate", COALESCE("parent_key", ''::character varying), "key");



CREATE INDEX "idx_system_settings_key" ON "public"."system_settings" USING "btree" ("setting_key");



CREATE INDEX "idx_user_profiles_department" ON "public"."user_profiles" USING "btree" ("department");



CREATE INDEX "idx_user_profiles_email" ON "public"."user_profiles" USING "btree" ("email");



CREATE INDEX "idx_user_profiles_is_active" ON "public"."user_profiles" USING "btree" ("is_active");



CREATE INDEX "idx_user_profiles_role" ON "public"."user_profiles" USING "btree" ("role");



CREATE INDEX "idx_user_profiles_username" ON "public"."user_profiles" USING "btree" ("username");



CREATE OR REPLACE TRIGGER "update_approval_records_updated_at" BEFORE UPDATE ON "public"."approval_records" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_approval_statuses_updated_at" BEFORE UPDATE ON "public"."approval_statuses" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_approval_workflow_steps_updated_at" BEFORE UPDATE ON "public"."approval_workflow_steps" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_approval_workflows_updated_at" BEFORE UPDATE ON "public"."approval_workflows" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_code_counters_updated_at" BEFORE UPDATE ON "public"."code_counters" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_departments_updated_at" BEFORE UPDATE ON "public"."departments" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_form_data_values_updated_at" BEFORE UPDATE ON "public"."form_data_values" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_form_fields_updated_at" BEFORE UPDATE ON "public"."form_fields" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_forms_updated_at" BEFORE UPDATE ON "public"."forms" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_option_workbook_columns_updated_at" BEFORE UPDATE ON "public"."option_workbook_columns" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_option_workbook_rows_updated_at" BEFORE UPDATE ON "public"."option_workbook_rows" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_option_workbooks_updated_at" BEFORE UPDATE ON "public"."option_workbooks" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_packaging_templates_updated_at" BEFORE UPDATE ON "public"."packaging_templates" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_permissions_updated_at" BEFORE UPDATE ON "public"."permissions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_role_page_access_updated_at" BEFORE UPDATE ON "public"."role_page_access" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_roles_updated_at" BEFORE UPDATE ON "public"."roles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_system_options_updated_at" BEFORE UPDATE ON "public"."system_options" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_system_settings_updated_at" BEFORE UPDATE ON "public"."system_settings" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_profiles_updated_at" BEFORE UPDATE ON "public"."user_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."approval_action_logs"
    ADD CONSTRAINT "approval_action_logs_approval_record_id_fkey" FOREIGN KEY ("approval_record_id") REFERENCES "public"."approval_records"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."approval_action_logs"
    ADD CONSTRAINT "approval_action_logs_approver_id_fkey" FOREIGN KEY ("approver_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."approval_action_logs"
    ADD CONSTRAINT "approval_action_logs_from_status_code_fkey" FOREIGN KEY ("from_status_code") REFERENCES "public"."approval_statuses"("status_code");



ALTER TABLE ONLY "public"."approval_action_logs"
    ADD CONSTRAINT "approval_action_logs_step_id_fkey" FOREIGN KEY ("step_id") REFERENCES "public"."approval_workflow_steps"("id");



ALTER TABLE ONLY "public"."approval_action_logs"
    ADD CONSTRAINT "approval_action_logs_to_status_code_fkey" FOREIGN KEY ("to_status_code") REFERENCES "public"."approval_statuses"("status_code");



ALTER TABLE ONLY "public"."approval_records"
    ADD CONSTRAINT "approval_records_applicant_id_fkey" FOREIGN KEY ("applicant_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."approval_records"
    ADD CONSTRAINT "approval_records_current_status_code_fkey" FOREIGN KEY ("current_status_code") REFERENCES "public"."approval_statuses"("status_code");



ALTER TABLE ONLY "public"."approval_records"
    ADD CONSTRAINT "approval_records_current_step_id_fkey" FOREIGN KEY ("current_step_id") REFERENCES "public"."approval_workflow_steps"("id");



ALTER TABLE ONLY "public"."approval_records"
    ADD CONSTRAINT "approval_records_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."approval_records"
    ADD CONSTRAINT "approval_records_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."approval_workflows"("id");



ALTER TABLE ONLY "public"."approval_workflow_steps"
    ADD CONSTRAINT "approval_workflow_steps_approve_status_code_fkey" FOREIGN KEY ("approve_status_code") REFERENCES "public"."approval_statuses"("status_code");



ALTER TABLE ONLY "public"."approval_workflow_steps"
    ADD CONSTRAINT "approval_workflow_steps_next_step_on_approve_fkey" FOREIGN KEY ("next_step_on_approve") REFERENCES "public"."approval_workflow_steps"("id");



ALTER TABLE ONLY "public"."approval_workflow_steps"
    ADD CONSTRAINT "approval_workflow_steps_next_step_on_reject_fkey" FOREIGN KEY ("next_step_on_reject") REFERENCES "public"."approval_workflow_steps"("id");



ALTER TABLE ONLY "public"."approval_workflow_steps"
    ADD CONSTRAINT "approval_workflow_steps_reject_status_code_fkey" FOREIGN KEY ("reject_status_code") REFERENCES "public"."approval_statuses"("status_code");



ALTER TABLE ONLY "public"."approval_workflow_steps"
    ADD CONSTRAINT "approval_workflow_steps_status_code_fkey" FOREIGN KEY ("status_code") REFERENCES "public"."approval_statuses"("status_code");



ALTER TABLE ONLY "public"."approval_workflow_steps"
    ADD CONSTRAINT "approval_workflow_steps_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."approval_workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."approval_workflows"
    ADD CONSTRAINT "approval_workflows_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."approval_workflows"
    ADD CONSTRAINT "approval_workflows_final_status_code_fkey" FOREIGN KEY ("final_status_code") REFERENCES "public"."approval_statuses"("status_code");



ALTER TABLE ONLY "public"."approval_workflows"
    ADD CONSTRAINT "approval_workflows_initial_status_code_fkey" FOREIGN KEY ("initial_status_code") REFERENCES "public"."approval_statuses"("status_code");



ALTER TABLE ONLY "public"."approval_workflows"
    ADD CONSTRAINT "approval_workflows_reject_status_code_fkey" FOREIGN KEY ("reject_status_code") REFERENCES "public"."approval_statuses"("status_code");



ALTER TABLE ONLY "public"."approval_workflows"
    ADD CONSTRAINT "approval_workflows_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_uploaded_by_id_fkey" FOREIGN KEY ("uploaded_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."code_counters"
    ADD CONSTRAINT "code_counters_last_used_by_id_fkey" FOREIGN KEY ("last_used_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_manager_id_fkey" FOREIGN KEY ("manager_id") REFERENCES "public"."user_profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."departments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."export_logs"
    ADD CONSTRAINT "export_logs_exported_by_id_fkey" FOREIGN KEY ("exported_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."form_data_values"
    ADD CONSTRAINT "form_data_values_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."form_data_values"
    ADD CONSTRAINT "form_data_values_field_id_fkey" FOREIGN KEY ("field_id") REFERENCES "public"."form_fields"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."form_data_values"
    ADD CONSTRAINT "form_data_values_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."form_data_values"
    ADD CONSTRAINT "form_data_values_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."form_fields"
    ADD CONSTRAINT "form_fields_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."forms"
    ADD CONSTRAINT "forms_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."forms"
    ADD CONSTRAINT "forms_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."option_workbook_columns"
    ADD CONSTRAINT "option_workbook_columns_workbook_id_fkey" FOREIGN KEY ("workbook_id") REFERENCES "public"."option_workbooks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."option_workbook_rows"
    ADD CONSTRAINT "option_workbook_rows_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."option_workbook_rows"
    ADD CONSTRAINT "option_workbook_rows_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."option_workbook_rows"
    ADD CONSTRAINT "option_workbook_rows_workbook_id_fkey" FOREIGN KEY ("workbook_id") REFERENCES "public"."option_workbooks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."option_workbooks"
    ADD CONSTRAINT "option_workbooks_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."option_workbooks"
    ADD CONSTRAINT "option_workbooks_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."packaging_templates"
    ADD CONSTRAINT "packaging_templates_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."packaging_templates"
    ADD CONSTRAINT "packaging_templates_form_id_fkey" FOREIGN KEY ("form_id") REFERENCES "public"."forms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."packaging_templates"
    ADD CONSTRAINT "packaging_templates_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."role_page_access"
    ADD CONSTRAINT "role_page_access_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."role_page_access"
    ADD CONSTRAINT "role_page_access_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."system_settings"
    ADD CONSTRAINT "system_settings_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "public"."user_profiles"("id");



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON FUNCTION "public"."create_application_from_form_data"("p_form_id" bigint, "p_record_id" bigint, "p_applicant_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_application_from_form_data"("p_form_id" bigint, "p_record_id" bigint, "p_applicant_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_application_from_form_data"("p_form_id" bigint, "p_record_id" bigint, "p_applicant_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_application_form_data"("p_application_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_application_form_data"("p_application_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_application_form_data"("p_application_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_approvers"("p_approval_record_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_current_approvers"("p_approval_record_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_current_approvers"("p_approval_record_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_users_with_email"("p_role" character varying, "p_is_active" boolean, "p_search" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."get_users_with_email"("p_role" character varying, "p_is_active" boolean, "p_search" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_users_with_email"("p_role" character varying, "p_is_active" boolean, "p_search" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."migrate_application_to_form_data"("p_application_id" bigint, "p_form_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."migrate_application_to_form_data"("p_application_id" bigint, "p_form_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."migrate_application_to_form_data"("p_application_id" bigint, "p_form_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."migrate_field_value"("p_form_id" bigint, "p_field_key" character varying, "p_text_value" "text", "p_record_id" bigint, "p_json_value" "jsonb", "p_number_value" numeric, "p_date_value" "date", "p_datetime_value" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."migrate_field_value"("p_form_id" bigint, "p_field_key" character varying, "p_text_value" "text", "p_record_id" bigint, "p_json_value" "jsonb", "p_number_value" numeric, "p_date_value" "date", "p_datetime_value" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."migrate_field_value"("p_form_id" bigint, "p_field_key" character varying, "p_text_value" "text", "p_record_id" bigint, "p_json_value" "jsonb", "p_number_value" numeric, "p_date_value" "date", "p_datetime_value" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_user_profiles_email"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_user_profiles_email"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_user_profiles_email"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_application_status"("p_application_id" bigint, "p_status" character varying, "p_approval_status" character varying, "p_approver_id" "uuid", "p_reject_reason" "text", "p_comment" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_application_status"("p_application_id" bigint, "p_status" character varying, "p_approval_status" character varying, "p_approver_id" "uuid", "p_reject_reason" "text", "p_comment" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_application_status"("p_application_id" bigint, "p_status" character varying, "p_approval_status" character varying, "p_approver_id" "uuid", "p_reject_reason" "text", "p_comment" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";


















GRANT ALL ON TABLE "public"."approval_action_logs" TO "anon";
GRANT ALL ON TABLE "public"."approval_action_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."approval_action_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."approval_action_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."approval_action_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."approval_action_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."approval_records" TO "anon";
GRANT ALL ON TABLE "public"."approval_records" TO "authenticated";
GRANT ALL ON TABLE "public"."approval_records" TO "service_role";



GRANT ALL ON SEQUENCE "public"."approval_records_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."approval_records_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."approval_records_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."approval_statuses" TO "anon";
GRANT ALL ON TABLE "public"."approval_statuses" TO "authenticated";
GRANT ALL ON TABLE "public"."approval_statuses" TO "service_role";



GRANT ALL ON SEQUENCE "public"."approval_statuses_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."approval_statuses_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."approval_statuses_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."approval_workflow_steps" TO "anon";
GRANT ALL ON TABLE "public"."approval_workflow_steps" TO "authenticated";
GRANT ALL ON TABLE "public"."approval_workflow_steps" TO "service_role";



GRANT ALL ON SEQUENCE "public"."approval_workflow_steps_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."approval_workflow_steps_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."approval_workflow_steps_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."approval_workflows" TO "anon";
GRANT ALL ON TABLE "public"."approval_workflows" TO "authenticated";
GRANT ALL ON TABLE "public"."approval_workflows" TO "service_role";



GRANT ALL ON SEQUENCE "public"."approval_workflows_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."approval_workflows_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."approval_workflows_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."attachments" TO "anon";
GRANT ALL ON TABLE "public"."attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."attachments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."attachments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."attachments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."attachments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."code_counters" TO "anon";
GRANT ALL ON TABLE "public"."code_counters" TO "authenticated";
GRANT ALL ON TABLE "public"."code_counters" TO "service_role";



GRANT ALL ON SEQUENCE "public"."code_counters_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."code_counters_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."code_counters_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."departments" TO "anon";
GRANT ALL ON TABLE "public"."departments" TO "authenticated";
GRANT ALL ON TABLE "public"."departments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."departments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."departments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."departments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."export_logs" TO "anon";
GRANT ALL ON TABLE "public"."export_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."export_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."export_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."export_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."export_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."form_data_values" TO "anon";
GRANT ALL ON TABLE "public"."form_data_values" TO "authenticated";
GRANT ALL ON TABLE "public"."form_data_values" TO "service_role";



GRANT ALL ON SEQUENCE "public"."form_data_values_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."form_data_values_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."form_data_values_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."form_fields" TO "anon";
GRANT ALL ON TABLE "public"."form_fields" TO "authenticated";
GRANT ALL ON TABLE "public"."form_fields" TO "service_role";



GRANT ALL ON SEQUENCE "public"."form_fields_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."form_fields_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."form_fields_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."forms" TO "anon";
GRANT ALL ON TABLE "public"."forms" TO "authenticated";
GRANT ALL ON TABLE "public"."forms" TO "service_role";



GRANT ALL ON SEQUENCE "public"."forms_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."forms_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."forms_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."option_workbook_columns" TO "anon";
GRANT ALL ON TABLE "public"."option_workbook_columns" TO "authenticated";
GRANT ALL ON TABLE "public"."option_workbook_columns" TO "service_role";



GRANT ALL ON SEQUENCE "public"."option_workbook_columns_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."option_workbook_columns_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."option_workbook_columns_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."option_workbook_rows" TO "anon";
GRANT ALL ON TABLE "public"."option_workbook_rows" TO "authenticated";
GRANT ALL ON TABLE "public"."option_workbook_rows" TO "service_role";



GRANT ALL ON SEQUENCE "public"."option_workbook_rows_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."option_workbook_rows_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."option_workbook_rows_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."option_workbooks" TO "anon";
GRANT ALL ON TABLE "public"."option_workbooks" TO "authenticated";
GRANT ALL ON TABLE "public"."option_workbooks" TO "service_role";



GRANT ALL ON SEQUENCE "public"."option_workbooks_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."option_workbooks_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."option_workbooks_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."packaging_templates" TO "anon";
GRANT ALL ON TABLE "public"."packaging_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."packaging_templates" TO "service_role";



GRANT ALL ON SEQUENCE "public"."packaging_templates_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."packaging_templates_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."packaging_templates_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_profiles" TO "anon";
GRANT ALL ON TABLE "public"."user_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."pending_approval_applications_view" TO "anon";
GRANT ALL ON TABLE "public"."pending_approval_applications_view" TO "authenticated";
GRANT ALL ON TABLE "public"."pending_approval_applications_view" TO "service_role";



GRANT ALL ON TABLE "public"."permissions" TO "anon";
GRANT ALL ON TABLE "public"."permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."permissions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."permissions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."permissions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."permissions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."role_page_access" TO "anon";
GRANT ALL ON TABLE "public"."role_page_access" TO "authenticated";
GRANT ALL ON TABLE "public"."role_page_access" TO "service_role";



GRANT ALL ON SEQUENCE "public"."role_page_access_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."role_page_access_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."role_page_access_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."role_permissions" TO "anon";
GRANT ALL ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."role_permissions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."system_options" TO "anon";
GRANT ALL ON TABLE "public"."system_options" TO "authenticated";
GRANT ALL ON TABLE "public"."system_options" TO "service_role";



GRANT ALL ON SEQUENCE "public"."system_options_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."system_options_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."system_options_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."system_settings" TO "anon";
GRANT ALL ON TABLE "public"."system_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."system_settings" TO "service_role";



GRANT ALL ON SEQUENCE "public"."system_settings_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."system_settings_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."system_settings_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































