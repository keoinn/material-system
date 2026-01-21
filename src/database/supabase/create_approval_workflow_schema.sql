-- ============================================================================
-- 審核流程自定義功能 - 資料庫結構
-- ============================================================================
-- 建立日期: 2026-01-20
-- 說明: 支援使用者自定義審核流程，包括狀態定義和審核層級配置
-- ============================================================================

-- ============================================================================
-- 第一部分：刪除舊的審核流程相關表（如果存在）
-- ============================================================================
-- 注意：按照外鍵依賴順序刪除，先刪除子表，再刪除父表

DROP TABLE IF EXISTS approval_action_logs CASCADE;
DROP TABLE IF EXISTS approval_records CASCADE;
DROP TABLE IF EXISTS approval_workflow_steps CASCADE;
DROP TABLE IF EXISTS approval_workflows CASCADE;
DROP TABLE IF EXISTS approval_statuses CASCADE;

-- 刪除相關視圖和函數
DROP VIEW IF EXISTS pending_approval_applications_view CASCADE;
DROP FUNCTION IF EXISTS get_current_approvers(BIGINT) CASCADE;

-- ============================================================================
-- 1. 審核狀態定義表 (approval_statuses)
-- ============================================================================
-- 用於定義系統中可用的審核狀態
CREATE TABLE IF NOT EXISTS approval_statuses (
  id BIGSERIAL PRIMARY KEY,
  status_code VARCHAR(50) NOT NULL UNIQUE, -- 狀態代碼（例如：PENDING, IN_REVIEW, APPROVED, REJECTED）
  status_name VARCHAR(100) NOT NULL, -- 狀態名稱（中文）
  status_name_en VARCHAR(100), -- 狀態名稱（英文）
  description TEXT, -- 狀態說明
  status_type VARCHAR(50) NOT NULL DEFAULT 'INTERMEDIATE', -- 狀態類型：INITIAL=初始狀態, INTERMEDIATE=中間狀態, FINAL=最終狀態
  color VARCHAR(50) DEFAULT 'grey', -- 顯示顏色（用於 UI）
  icon VARCHAR(100), -- 圖示名稱（用於 UI）
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  display_order INTEGER DEFAULT 0, -- 顯示順序
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE approval_statuses IS '審核狀態定義表：定義系統中可用的審核狀態';
COMMENT ON COLUMN approval_statuses.status_code IS '狀態代碼：唯一識別碼，例如 PENDING, IN_REVIEW, APPROVED, REJECTED';
COMMENT ON COLUMN approval_statuses.status_type IS '狀態類型：INITIAL=初始狀態, INTERMEDIATE=中間狀態, FINAL=最終狀態';

CREATE INDEX IF NOT EXISTS idx_approval_statuses_status_code ON approval_statuses(status_code);
CREATE INDEX IF NOT EXISTS idx_approval_statuses_status_type ON approval_statuses(status_type);
CREATE INDEX IF NOT EXISTS idx_approval_statuses_is_active ON approval_statuses(is_active);

CREATE TRIGGER update_approval_statuses_updated_at
  BEFORE UPDATE ON approval_statuses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. 審核流程配置表 (approval_workflows)
-- ============================================================================
-- 用於定義審核流程（所有表單共用）
CREATE TABLE IF NOT EXISTS approval_workflows (
  id BIGSERIAL PRIMARY KEY,
  workflow_code VARCHAR(100) NOT NULL UNIQUE, -- 流程代碼（例如：default_workflow）
  workflow_name VARCHAR(255) NOT NULL, -- 流程名稱（中文）
  workflow_name_en VARCHAR(255), -- 流程名稱（英文）
  description TEXT, -- 流程說明
  is_default BOOLEAN DEFAULT FALSE, -- 是否為預設流程
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  initial_status_code VARCHAR(50) REFERENCES approval_statuses(status_code), -- 初始狀態
  final_status_code VARCHAR(50) REFERENCES approval_statuses(status_code), -- 最終狀態（核准）
  reject_status_code VARCHAR(50) REFERENCES approval_statuses(status_code), -- 退回狀態
  created_by_id UUID REFERENCES user_profiles(id), -- 建立人
  updated_by_id UUID REFERENCES user_profiles(id), -- 更新人
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE approval_workflows IS '審核流程配置表：定義審核流程（所有表單共用）';
COMMENT ON COLUMN approval_workflows.workflow_code IS '流程代碼：唯一識別碼，例如 default_workflow';

CREATE INDEX IF NOT EXISTS idx_approval_workflows_workflow_code ON approval_workflows(workflow_code);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_is_default ON approval_workflows(is_default);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_is_active ON approval_workflows(is_active);

CREATE TRIGGER update_approval_workflows_updated_at
  BEFORE UPDATE ON approval_workflows
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. 審核流程步驟表 (approval_workflow_steps)
-- ============================================================================
-- 定義審核流程中的每個步驟
CREATE TABLE IF NOT EXISTS approval_workflow_steps (
  id BIGSERIAL PRIMARY KEY,
  workflow_id BIGINT NOT NULL REFERENCES approval_workflows(id) ON DELETE CASCADE, -- 所屬流程
  step_order INTEGER NOT NULL, -- 步驟順序（從 1 開始）
  step_name VARCHAR(255) NOT NULL, -- 步驟名稱
  step_name_en VARCHAR(255), -- 步驟名稱（英文）
  description TEXT, -- 步驟說明
  status_code VARCHAR(50) REFERENCES approval_statuses(status_code), -- 當前單據狀態（此步驟執行時的狀態）
  approver_type VARCHAR(50) NOT NULL DEFAULT 'USER', -- 審核人類型：USER=指定使用者, ROLE=指定角色, DEPARTMENT=指定部門, AUTO=自動通過
  approver_config JSONB, -- 審核人配置（JSON格式，根據 approver_type 不同而不同）
  -- 例如：{"user_ids": ["uuid1", "uuid2"]} 或 {"role": "approver"} 或 {"departments": ["IT", "財務"]}
  -- 新增欄位：審核權限部門（多選，從 system_options 中選擇）
  approval_departments TEXT[], -- 審核權限部門列表（對應 system_options 的 key 值）
  -- 新增欄位：審核人列表（多選）
  approver_user_ids UUID[], -- 審核人 ID 列表（直接指定使用者）
  approve_status_code VARCHAR(50) REFERENCES approval_statuses(status_code), -- 審核通過狀態（核准後要設定的狀態）
  reject_status_code VARCHAR(50) REFERENCES approval_statuses(status_code), -- 退回狀態（退回後要設定的狀態）
  next_step_on_approve INTEGER REFERENCES approval_workflow_steps(id), -- 核准後的下一步驟（null 表示流程結束）
  next_step_on_reject INTEGER REFERENCES approval_workflow_steps(id), -- 退回後的下一步驟（通常回到初始狀態或退回狀態）
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- 同一流程內步驟順序必須唯一
  UNIQUE(workflow_id, step_order)
);

COMMENT ON TABLE approval_workflow_steps IS '審核流程步驟表：定義審核流程中的每個步驟';
COMMENT ON COLUMN approval_workflow_steps.status_code IS '當前單據狀態：此步驟執行時的狀態';
COMMENT ON COLUMN approval_workflow_steps.approver_type IS '審核人類型：USER=指定使用者, ROLE=指定角色, DEPARTMENT=指定部門, AUTO=自動通過';
COMMENT ON COLUMN approval_workflow_steps.approver_config IS '審核人配置：JSON格式，例如 {"user_ids": ["uuid1"]} 或 {"role": "approver"}';
COMMENT ON COLUMN approval_workflow_steps.approval_departments IS '審核權限部門列表：對應 system_options 的 key 值，用於篩選可審核的使用者';
COMMENT ON COLUMN approval_workflow_steps.approver_user_ids IS '審核人 ID 列表：直接指定可審核的使用者';
COMMENT ON COLUMN approval_workflow_steps.approve_status_code IS '審核通過狀態：核准後要設定的狀態';
COMMENT ON COLUMN approval_workflow_steps.reject_status_code IS '退回狀態：退回後要設定的狀態';
COMMENT ON COLUMN approval_workflow_steps.next_step_on_approve IS '核准後的下一步驟：null 表示流程結束（已核准）';
COMMENT ON COLUMN approval_workflow_steps.next_step_on_reject IS '退回後的下一步驟：通常回到初始狀態或退回狀態';

CREATE INDEX IF NOT EXISTS idx_approval_workflow_steps_workflow_id ON approval_workflow_steps(workflow_id);
CREATE INDEX IF NOT EXISTS idx_approval_workflow_steps_step_order ON approval_workflow_steps(workflow_id, step_order);
CREATE INDEX IF NOT EXISTS idx_approval_workflow_steps_status_code ON approval_workflow_steps(status_code);

CREATE TRIGGER update_approval_workflow_steps_updated_at
  BEFORE UPDATE ON approval_workflow_steps
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. 申請審核記錄表 (approval_records)
-- ============================================================================
-- 追蹤每個申請的審核進度和記錄
CREATE TABLE IF NOT EXISTS approval_records (
  id BIGSERIAL PRIMARY KEY,
  form_id BIGINT NOT NULL REFERENCES forms(id) ON DELETE CASCADE, -- 所屬表單
  record_id BIGINT NOT NULL, -- 申請記錄 ID（對應 form_data_values.record_id）
  workflow_id BIGINT REFERENCES approval_workflows(id), -- 使用的審核流程
  current_step_id BIGINT REFERENCES approval_workflow_steps(id), -- 當前步驟
  current_status_code VARCHAR(50) REFERENCES approval_statuses(status_code), -- 當前狀態
  applicant_id UUID NOT NULL REFERENCES user_profiles(id), -- 申請人
  submit_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 提交日期
  approval_date TIMESTAMP WITH TIME ZONE, -- 最終核准日期
  reject_date TIMESTAMP WITH TIME ZONE, -- 退回日期
  reject_reason TEXT, -- 退回原因
  is_completed BOOLEAN DEFAULT FALSE, -- 是否已完成（已核准或已退回）
  workflow_config JSONB, -- 流程配置快照（用於記錄審核時的流程配置）
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- 同一表單的同一記錄只能有一筆審核記錄
  UNIQUE(form_id, record_id)
);

COMMENT ON TABLE approval_records IS '申請審核記錄表：追蹤每個申請的審核進度和記錄';
COMMENT ON COLUMN approval_records.record_id IS '申請記錄 ID：對應 form_data_values.record_id';
COMMENT ON COLUMN approval_records.current_step_id IS '當前步驟：null 表示流程已完成或尚未開始';
COMMENT ON COLUMN approval_records.workflow_config IS '流程配置快照：記錄審核時的流程配置，避免流程變更影響歷史記錄';

CREATE INDEX IF NOT EXISTS idx_approval_records_form_id ON approval_records(form_id);
CREATE INDEX IF NOT EXISTS idx_approval_records_record_id ON approval_records(record_id);
CREATE INDEX IF NOT EXISTS idx_approval_records_form_record ON approval_records(form_id, record_id);
CREATE INDEX IF NOT EXISTS idx_approval_records_workflow_id ON approval_records(workflow_id);
CREATE INDEX IF NOT EXISTS idx_approval_records_current_step_id ON approval_records(current_step_id);
CREATE INDEX IF NOT EXISTS idx_approval_records_current_status_code ON approval_records(current_status_code);
CREATE INDEX IF NOT EXISTS idx_approval_records_applicant_id ON approval_records(applicant_id);
CREATE INDEX IF NOT EXISTS idx_approval_records_is_completed ON approval_records(is_completed);
CREATE INDEX IF NOT EXISTS idx_approval_records_submit_date ON approval_records(submit_date);

CREATE TRIGGER update_approval_records_updated_at
  BEFORE UPDATE ON approval_records
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. 審核操作記錄表 (approval_action_logs)
-- ============================================================================
-- 記錄每次審核操作的詳細資訊
CREATE TABLE IF NOT EXISTS approval_action_logs (
  id BIGSERIAL PRIMARY KEY,
  approval_record_id BIGINT NOT NULL REFERENCES approval_records(id) ON DELETE CASCADE, -- 審核記錄 ID
  step_id BIGINT REFERENCES approval_workflow_steps(id), -- 執行的步驟
  action VARCHAR(50) NOT NULL, -- 操作類型：SUBMIT=提交, APPROVE=核准, REJECT=退回, RETURN=退回修改, SKIP=跳過
  approver_id UUID REFERENCES user_profiles(id), -- 審核人（null 表示系統自動操作）
  approver_name VARCHAR(255), -- 審核人姓名（冗余，用於歷史記錄）
  approver_role VARCHAR(50), -- 審核人角色（冗余）
  from_status_code VARCHAR(50) REFERENCES approval_statuses(status_code), -- 操作前狀態
  to_status_code VARCHAR(50) REFERENCES approval_statuses(status_code), -- 操作後狀態
  comment TEXT, -- 審核意見
  reason TEXT, -- 退回原因
  action_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 操作時間
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE approval_action_logs IS '審核操作記錄表：記錄每次審核操作的詳細資訊';
COMMENT ON COLUMN approval_action_logs.action IS '操作類型：SUBMIT=提交, APPROVE=核准, REJECT=退回, RETURN=退回修改, SKIP=跳過';

CREATE INDEX IF NOT EXISTS idx_approval_action_logs_approval_record_id ON approval_action_logs(approval_record_id);
CREATE INDEX IF NOT EXISTS idx_approval_action_logs_step_id ON approval_action_logs(step_id);
CREATE INDEX IF NOT EXISTS idx_approval_action_logs_approver_id ON approval_action_logs(approver_id);
CREATE INDEX IF NOT EXISTS idx_approval_action_logs_action ON approval_action_logs(action);
CREATE INDEX IF NOT EXISTS idx_approval_action_logs_action_date ON approval_action_logs(action_date);

-- ============================================================================
-- 6. 初始化部門選項（如果不存在）
-- ============================================================================
-- 在 system_options 中初始化部門選項（不指定 ID，讓資料庫自動產生）
-- 先同步序列，然後使用 DO 語句逐個檢查並插入，避免主鍵和唯一索引衝突
DO $$
DECLARE
  v_exists BOOLEAN;
  v_max_id BIGINT;
BEGIN
  -- 先同步序列，確保序列值大於表中的最大 ID
  SELECT COALESCE(MAX(id), 0) INTO v_max_id FROM system_options;
  IF v_max_id > 0 THEN
    PERFORM setval('system_options_id_seq', v_max_id, true);
  END IF;

  -- IT 部門
  SELECT EXISTS (
    SELECT 1 FROM system_options 
    WHERE module = 'approval_workflow' AND cate = 'department' AND parent_key IS NULL AND key = 'IT'
  ) INTO v_exists;
  IF NOT v_exists THEN
    INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc")
    VALUES ('approval_workflow', 'department', null, 'IT', 'IT', '資訊部門', '資訊技術部門');
  END IF;

  -- HR 部門
  SELECT EXISTS (
    SELECT 1 FROM system_options 
    WHERE module = 'approval_workflow' AND cate = 'department' AND parent_key IS NULL AND key = 'HR'
  ) INTO v_exists;
  IF NOT v_exists THEN
    INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc")
    VALUES ('approval_workflow', 'department', null, 'HR', 'HR', '人事部門', '人力資源部門');
  END IF;

  -- FINANCE 部門
  SELECT EXISTS (
    SELECT 1 FROM system_options 
    WHERE module = 'approval_workflow' AND cate = 'department' AND parent_key IS NULL AND key = 'FINANCE'
  ) INTO v_exists;
  IF NOT v_exists THEN
    INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc")
    VALUES ('approval_workflow', 'department', null, 'FINANCE', 'FINANCE', '財務部門', '財務會計部門');
  END IF;

  -- PROCUREMENT 部門
  SELECT EXISTS (
    SELECT 1 FROM system_options 
    WHERE module = 'approval_workflow' AND cate = 'department' AND parent_key IS NULL AND key = 'PROCUREMENT'
  ) INTO v_exists;
  IF NOT v_exists THEN
    INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc")
    VALUES ('approval_workflow', 'department', null, 'PROCUREMENT', 'PROCUREMENT', '採購部門', '採購部門');
  END IF;

  -- QUALITY 部門
  SELECT EXISTS (
    SELECT 1 FROM system_options 
    WHERE module = 'approval_workflow' AND cate = 'department' AND parent_key IS NULL AND key = 'QUALITY'
  ) INTO v_exists;
  IF NOT v_exists THEN
    INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc")
    VALUES ('approval_workflow', 'department', null, 'QUALITY', 'QUALITY', '品保部門', '品質保證部門');
  END IF;

  -- PRODUCTION 部門
  SELECT EXISTS (
    SELECT 1 FROM system_options 
    WHERE module = 'approval_workflow' AND cate = 'department' AND parent_key IS NULL AND key = 'PRODUCTION'
  ) INTO v_exists;
  IF NOT v_exists THEN
    INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc")
    VALUES ('approval_workflow', 'department', null, 'PRODUCTION', 'PRODUCTION', '生產部門', '生產製造部門');
  END IF;

  -- SALES 部門
  SELECT EXISTS (
    SELECT 1 FROM system_options 
    WHERE module = 'approval_workflow' AND cate = 'department' AND parent_key IS NULL AND key = 'SALES'
  ) INTO v_exists;
  IF NOT v_exists THEN
    INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc")
    VALUES ('approval_workflow', 'department', null, 'SALES', 'SALES', '業務部門', '業務銷售部門');
  END IF;

  -- MANAGEMENT 部門
  SELECT EXISTS (
    SELECT 1 FROM system_options 
    WHERE module = 'approval_workflow' AND cate = 'department' AND parent_key IS NULL AND key = 'MANAGEMENT'
  ) INTO v_exists;
  IF NOT v_exists THEN
    INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc")
    VALUES ('approval_workflow', 'department', null, 'MANAGEMENT', 'MANAGEMENT', '管理部門', '管理階層');
  END IF;
END $$;

-- ============================================================================
-- 7. 初始化預設審核狀態
-- ============================================================================
INSERT INTO approval_statuses (status_code, status_name, status_name_en, description, status_type, color, icon, display_order) VALUES
  ('DRAFT', '草稿', 'Draft', '申請草稿，尚未提交', 'INITIAL', 'grey', 'mdi-file-document-outline', 1),
  ('PENDING', '待審核', 'Pending', '等待審核中', 'INTERMEDIATE', 'warning', 'mdi-clock-outline', 2),
  ('IN_REVIEW', '審核中', 'In Review', '正在審核中', 'INTERMEDIATE', 'info', 'mdi-eye-outline', 3),
  ('APPROVED', '已核准', 'Approved', '已通過審核', 'FINAL', 'success', 'mdi-check-circle', 4),
  ('REJECTED', '已退回', 'Rejected', '已退回修改', 'FINAL', 'error', 'mdi-close-circle', 5),
  ('RETURNED', '退回修改', 'Returned', '退回申請人修改', 'INTERMEDIATE', 'warning', 'mdi-arrow-left-circle', 6)
ON CONFLICT (status_code) DO UPDATE SET
  status_name = EXCLUDED.status_name,
  status_name_en = EXCLUDED.status_name_en,
  description = EXCLUDED.description,
  status_type = EXCLUDED.status_type,
  color = EXCLUDED.color,
  icon = EXCLUDED.icon,
  display_order = EXCLUDED.display_order,
  updated_at = NOW();

-- ============================================================================
-- 8. 創建視圖：待審核申請列表（包含審核流程資訊）
-- ============================================================================
CREATE OR REPLACE VIEW pending_approval_applications_view AS
SELECT DISTINCT
  ar.id AS approval_record_id,
  ar.form_id,
  ar.record_id,
  ar.workflow_id,
  ar.current_step_id,
  ar.current_status_code,
  ar.applicant_id,
  ar.submit_date,
  ar.approval_date,
  ar.reject_date,
  ar.reject_reason,
  ar.is_completed,
  -- 申請人資訊
  up.username AS applicant_username,
  -- 當前步驟資訊
  aws.step_name AS current_step_name,
  aws.step_order AS current_step_order,
  -- 狀態資訊
  ast.status_name AS current_status_name,
  ast.color AS status_color,
  ast.icon AS status_icon,
  -- 流程資訊
  aw.workflow_name,
  aw.workflow_code
FROM approval_records ar
LEFT JOIN user_profiles up ON ar.applicant_id = up.id
LEFT JOIN approval_workflow_steps aws ON ar.current_step_id = aws.id
LEFT JOIN approval_statuses ast ON ar.current_status_code = ast.status_code
LEFT JOIN approval_workflows aw ON ar.workflow_id = aw.id
WHERE ar.is_completed = FALSE
ORDER BY ar.submit_date DESC;

COMMENT ON VIEW pending_approval_applications_view IS '待審核申請列表視圖：包含審核流程資訊';

-- ============================================================================
-- 9. 創建函數：獲取申請的當前審核人
-- ============================================================================
CREATE OR REPLACE FUNCTION get_current_approvers(
  p_approval_record_id BIGINT
)
RETURNS TABLE (
  user_id UUID,
  username VARCHAR(100),
  role VARCHAR(50),
  approver_type VARCHAR(50)
) AS $$
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
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_current_approvers IS '獲取申請的當前審核人列表（支援審核權限部門和審核人列表）';
