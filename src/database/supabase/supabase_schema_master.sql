-- ============================================================================
-- Supabase Schema Master（完整資料庫結構）
-- ============================================================================
-- 建立日期: 2026-06-02
-- 說明: 合併所有必要 migration，新環境只需執行此單一檔案
--
-- 涵蓋 23 張資料表:
--   user_profiles, code_counters, export_logs, attachments,
--   forms, form_fields, form_data_values, system_options, system_settings,
--   roles, permissions, role_permissions, role_page_access,
--   approval_statuses, approval_workflows, approval_workflow_steps,
--   approval_records, approval_action_logs,
--   departments,
--   option_workbooks, option_workbook_columns, option_workbook_rows,
--   packaging_templates
--
-- 使用方式: 在 Supabase SQL Editor 貼上並執行全文
-- 個別模組檔案仍保留於同目錄，供參考或局部更新
-- ============================================================================

-- 第一部分：刪除不需要的資料表
-- ============================================================================
-- 注意：按照外鍵依賴順序刪除，先刪除子表，再刪除父表

-- 刪除申請相關表
DROP TABLE IF EXISTS application_packaging CASCADE;
DROP TABLE IF EXISTS approval_logs CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS drafts CASCADE;

-- 刪除包裝相關表
DROP TABLE IF EXISTS category_packaging_defaults CASCADE;
DROP TABLE IF EXISTS packaging_options CASCADE;
DROP TABLE IF EXISTS packaging_categories CASCADE;

-- 刪除其他系統表
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;

-- ============================================================================
-- 第二部分：建立更新時間的自動更新觸發器函數
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 第二部分（補充）：更新 form_data_values 的唯一約束（如果表已存在）
-- ============================================================================
-- 注意：此部分用於更新已存在的表，將唯一約束從 (form_id, field_id, record_id)
-- 改為 (form_id, field_id, record_id, field_key)，以支援 cascading_select 欄位
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- 如果 form_data_values 表已存在，則更新唯一約束
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'form_data_values') THEN
        -- 查找並刪除舊的唯一約束（不包含 field_key）
        FOR constraint_name IN 
            SELECT conname 
            FROM pg_constraint 
            WHERE conrelid = 'form_data_values'::regclass 
            AND contype = 'u'
            AND (
                pg_get_constraintdef(oid) LIKE '%form_id%field_id%record_id%'
                AND pg_get_constraintdef(oid) NOT LIKE '%field_key%'
            )
        LOOP
            EXECUTE format('ALTER TABLE form_data_values DROP CONSTRAINT IF EXISTS %I', constraint_name);
            RAISE NOTICE '已刪除舊約束: %', constraint_name;
        END LOOP;

        -- 創建新的唯一約束（包含 field_key），如果不存在
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conrelid = 'form_data_values'::regclass 
            AND conname = 'form_data_values_form_id_field_id_record_id_field_key_key'
        ) THEN
            ALTER TABLE form_data_values
            ADD CONSTRAINT form_data_values_form_id_field_id_record_id_field_key_key
            UNIQUE (form_id, field_id, record_id, field_key);
            RAISE NOTICE '已創建新約束: form_data_values_form_id_field_id_record_id_field_key_key';
        END IF;
    END IF;
END $$;

-- ============================================================================
-- 第三部分：建立需要保留的資料表
-- ============================================================================

-- ============================================================================
-- 1. 使用者資料表 (user_profiles)
-- ============================================================================
-- 注意：Supabase 已提供 auth.users 表用於身份驗證
-- 此表用於儲存應用程式特定的使用者資料，關聯到 auth.users.id
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username VARCHAR(100) UNIQUE,
  role VARCHAR(50) NOT NULL DEFAULT 'applicant', -- admin, approver, applicant
  department VARCHAR(100),
  position VARCHAR(100),
  phone VARCHAR(50),
  avatar_url VARCHAR(500),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE,
  last_login_ip VARCHAR(50)
);

COMMENT ON TABLE user_profiles IS '使用者資料表：儲存應用程式特定的使用者資料，關聯到 auth.users';
COMMENT ON COLUMN user_profiles.id IS '使用者ID：關聯到 auth.users.id (UUID)';
COMMENT ON COLUMN user_profiles.role IS '角色：admin=系統管理員, approver=審核人員, applicant=申請人員';
COMMENT ON COLUMN user_profiles.department IS '部門代碼：對應到 departments.department_code，儲存部門的唯一識別碼（如：IT, HR, FINANCE）';

CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON user_profiles(username);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON user_profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_user_profiles_department ON user_profiles(department);

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 建立函數：當 auth.users 建立新使用者時，自動建立 user_profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, role, is_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'applicant'),
    FALSE  -- 新註冊用戶預設未啟用，需等待管理員審核
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 建立觸發器：當 auth.users 有新使用者時自動建立 profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 2. 編碼計數器表 (code_counters)
-- ============================================================================
CREATE TABLE IF NOT EXISTS code_counters (
  id BIGSERIAL PRIMARY KEY,
  key VARCHAR(50) NOT NULL UNIQUE, -- 格式: {大類}{中類}.{小類} 例如: H01.C
  counter INTEGER NOT NULL DEFAULT 0,
  last_used_date TIMESTAMP WITH TIME ZONE,
  last_used_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE code_counters IS '編碼計數器表：用於產生料號的流水號計數器';

CREATE INDEX IF NOT EXISTS idx_code_counters_key ON code_counters(key);

CREATE TRIGGER update_code_counters_updated_at
  BEFORE UPDATE ON code_counters
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. 匯出記錄表 (export_logs)
-- ============================================================================
CREATE TABLE IF NOT EXISTS export_logs (
  id BIGSERIAL PRIMARY KEY,
  category VARCHAR(50), -- 匯出類別
  status VARCHAR(50), -- 匯出狀態：ALL, APPROVED, PENDING, REJECTED
  start_date DATE,
  end_date DATE,
  record_count INTEGER,
  file_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(500),
  file_size BIGINT, -- bytes
  format VARCHAR(20), -- CSV, XLSX, PDF
  exported_by_id UUID NOT NULL REFERENCES user_profiles(id),
  exported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  download_count INTEGER DEFAULT 0
);

COMMENT ON TABLE export_logs IS '匯出記錄表：記錄Excel匯出操作';

CREATE INDEX IF NOT EXISTS idx_export_logs_exported_by_id ON export_logs(exported_by_id);
CREATE INDEX IF NOT EXISTS idx_export_logs_exported_at ON export_logs(exported_at);
CREATE INDEX IF NOT EXISTS idx_export_logs_status ON export_logs(status);

-- ============================================================================
-- 4. 附件表 (attachments)
-- ============================================================================
-- 注意：此表原本關聯到 applications，現在改為關聯到 form_data_values 的 record_id
CREATE TABLE IF NOT EXISTS attachments (
  id BIGSERIAL PRIMARY KEY,
  form_id BIGINT, -- 關聯到 forms.id（可選）
  record_id BIGINT, -- 關聯到表單記錄ID（例如：form_data_values.record_id）
  file_name VARCHAR(255) NOT NULL,
  original_file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(50) NOT NULL, -- image, document, drawing, other
  file_size BIGINT NOT NULL, -- bytes
  mime_type VARCHAR(100),
  file_url VARCHAR(500) NOT NULL,
  thumbnail_url VARCHAR(500), -- 縮圖URL（圖片用）
  uploaded_by_id UUID NOT NULL REFERENCES user_profiles(id),
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  description TEXT
);

COMMENT ON TABLE attachments IS '附件表：申請的附件檔案';
COMMENT ON COLUMN attachments.file_type IS '檔案類型：image=圖片, document=文件, drawing=圖面, other=其他';

CREATE INDEX IF NOT EXISTS idx_attachments_form_id ON attachments(form_id);
CREATE INDEX IF NOT EXISTS idx_attachments_record_id ON attachments(record_id);
CREATE INDEX IF NOT EXISTS idx_attachments_uploaded_by_id ON attachments(uploaded_by_id);
CREATE INDEX IF NOT EXISTS idx_attachments_file_type ON attachments(file_type);

-- ============================================================================
-- 5. 表單定義主表 (forms)
-- ============================================================================
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

CREATE INDEX IF NOT EXISTS idx_forms_form_code ON forms(form_code);
CREATE INDEX IF NOT EXISTS idx_forms_is_active ON forms(is_active);
CREATE INDEX IF NOT EXISTS idx_forms_is_default ON forms(is_default);
CREATE INDEX IF NOT EXISTS idx_forms_created_by_id ON forms(created_by_id);

CREATE TRIGGER update_forms_updated_at
  BEFORE UPDATE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. 表單欄位定義表 (form_fields)
-- ============================================================================
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
  is_in_template BOOLEAN DEFAULT FALSE, -- 是否加入包裝模板
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(form_id, field_key) -- 同一表單內欄位鍵值必須唯一
);

COMMENT ON TABLE form_fields IS '表單欄位定義表：儲存表單的欄位定義資訊';
COMMENT ON COLUMN form_fields.field_type IS '欄位類型：text=文字, textarea=多行文字, number=數字, select=下拉選單, multiselect=多選下拉, checkbox=複選框, radio=單選框, date=日期, datetime=日期時間, file=檔案, json=JSON資料';
COMMENT ON COLUMN form_fields.field_group IS '欄位群組：用於分組顯示，例如「基本資訊」、「分類資訊」等';
COMMENT ON COLUMN form_fields.sub_group IS '子群組名稱：用於排版顯示，例如「基本資訊區塊」、「詳細資訊區塊」等';
COMMENT ON COLUMN form_fields.is_in_template IS '是否加入模板：記錄該欄位是否出現在包裝模板設定中';

CREATE INDEX IF NOT EXISTS idx_form_fields_form_id ON form_fields(form_id);
CREATE INDEX IF NOT EXISTS idx_form_fields_field_key ON form_fields(field_key);
CREATE INDEX IF NOT EXISTS idx_form_fields_field_type ON form_fields(field_type);
CREATE INDEX IF NOT EXISTS idx_form_fields_field_group ON form_fields(field_group);
CREATE INDEX IF NOT EXISTS idx_form_fields_sub_group ON form_fields(form_id, field_group, sub_group);
CREATE INDEX IF NOT EXISTS idx_form_fields_display_order ON form_fields(form_id, display_order);
CREATE INDEX IF NOT EXISTS idx_form_fields_is_visible ON form_fields(is_visible);
CREATE INDEX IF NOT EXISTS idx_form_fields_is_in_template ON form_fields(is_in_template);

CREATE TRIGGER update_form_fields_updated_at
  BEFORE UPDATE ON form_fields
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. 表單資料值表 (form_data_values)
-- ============================================================================
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
  -- 唯一約束：同一表單、同一記錄、同一欄位、同一欄位鍵值只能有一筆資料
  -- 注意：包含 field_key 是為了支援 cascading_select 欄位，允許同一個 field_id 有多筆記錄（只要 field_key 不同）
  UNIQUE(form_id, field_id, record_id, field_key)
);

COMMENT ON TABLE form_data_values IS '表單資料值表：儲存動態欄位的實際資料值';
COMMENT ON COLUMN form_data_values.record_id IS '記錄ID：可關聯到其他表的記錄，例如 application_id';
COMMENT ON COLUMN form_data_values.field_value IS '欄位值（文字）：用於儲存 text, textarea, select, radio 等類型的值';
COMMENT ON COLUMN form_data_values.field_value_json IS '欄位值（JSON）：用於儲存 multiselect, checkbox, json 等類型的值';
COMMENT ON COLUMN form_data_values.field_value_number IS '欄位值（數字）：用於儲存 number 類型的值';
COMMENT ON COLUMN form_data_values.field_value_date IS '欄位值（日期）：用於儲存 date 類型的值';
COMMENT ON COLUMN form_data_values.field_value_datetime IS '欄位值（日期時間）：用於儲存 datetime 類型的值';
COMMENT ON COLUMN form_data_values.file_url IS '檔案URL：用於儲存 file 類型的檔案路徑';

CREATE INDEX IF NOT EXISTS idx_form_data_values_form_id ON form_data_values(form_id);
CREATE INDEX IF NOT EXISTS idx_form_data_values_field_id ON form_data_values(field_id);
CREATE INDEX IF NOT EXISTS idx_form_data_values_record_id ON form_data_values(record_id);
CREATE INDEX IF NOT EXISTS idx_form_data_values_field_key ON form_data_values(field_key);
CREATE INDEX IF NOT EXISTS idx_form_data_values_form_record ON form_data_values(form_id, record_id);
CREATE INDEX IF NOT EXISTS idx_form_data_values_created_by_id ON form_data_values(created_by_id);

CREATE TRIGGER update_form_data_values_updated_at
  BEFORE UPDATE ON form_data_values
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 8. 系統參數資料表 (system_options)
-- ============================================================================
CREATE TABLE IF NOT EXISTS system_options (
  id BIGSERIAL PRIMARY KEY,
  module VARCHAR(100) NOT NULL,
  cate VARCHAR(100) NOT NULL,
  parent_key VARCHAR(100) DEFAULT NULL,
  key VARCHAR(100) NOT NULL,
  value TEXT NOT NULL,
  label VARCHAR(255) DEFAULT NULL,
  "desc" TEXT DEFAULT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE system_options IS '系統參數資料表：儲存系統設定類的選項參數（狀態、優先級、角色等）';
COMMENT ON COLUMN system_options.module IS '模組名稱：在哪一個表單使用的參數';
COMMENT ON COLUMN system_options.cate IS '類別名稱：變數名稱移除 Options';
COMMENT ON COLUMN system_options.parent_key IS '父層鍵值：多層參數時父層的 key';
COMMENT ON COLUMN system_options.key IS '鍵值：對應物件的 Key';
COMMENT ON COLUMN system_options.value IS '值：對應物件的 value';
COMMENT ON COLUMN system_options.label IS '標籤：顯示用的中文標籤';
COMMENT ON COLUMN system_options."desc" IS '說明：詳細描述';

CREATE UNIQUE INDEX IF NOT EXISTS idx_system_options_unique 
ON system_options(module, cate, COALESCE(parent_key, ''), key);

CREATE INDEX IF NOT EXISTS idx_system_options_module ON system_options(module);
CREATE INDEX IF NOT EXISTS idx_system_options_cate ON system_options(cate);
CREATE INDEX IF NOT EXISTS idx_system_options_module_cate ON system_options(module, cate);

CREATE TRIGGER update_system_options_updated_at
  BEFORE UPDATE ON system_options
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 9. 系統設定表 (system_settings)
-- ============================================================================
CREATE TABLE IF NOT EXISTS system_settings (
  id BIGSERIAL PRIMARY KEY,
  setting_key VARCHAR(100) NOT NULL UNIQUE,
  setting_value TEXT NOT NULL,
  setting_type VARCHAR(50) DEFAULT 'string', -- string, number, boolean, json
  description TEXT,
  updated_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE system_settings IS '系統設定表：儲存系統設定值';
COMMENT ON COLUMN system_settings.setting_type IS '設定類型：string=字串, number=數字, boolean=布林值, json=JSON格式';

CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(setting_key);

CREATE TRIGGER update_system_settings_updated_at
  BEFORE UPDATE ON system_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================

-- ============================================================================
-- 第十一部分：角色權限管理
-- （來源: create_role_permission_schema.sql）
-- ============================================================================

-- ============================================================================
-- 角色權限管理資料表
-- 用途：動態管理系統角色和權限
-- ============================================================================

-- ============================================================================
-- 1. 角色表 (roles)
-- ============================================================================
CREATE TABLE IF NOT EXISTS roles (
  id BIGSERIAL PRIMARY KEY,
  role_code VARCHAR(50) NOT NULL UNIQUE, -- 角色代碼（如：admin, approver, applicant）
  role_name VARCHAR(100) NOT NULL, -- 角色名稱（中文）
  role_name_en VARCHAR(100), -- 角色名稱（英文）
  description TEXT, -- 角色說明
  is_system_role BOOLEAN DEFAULT FALSE, -- 是否為系統內建角色（不可刪除）
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  display_order INTEGER DEFAULT 0, -- 顯示順序
  created_by_id UUID REFERENCES user_profiles(id),
  updated_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE roles IS '角色表：定義系統中的各種角色';
COMMENT ON COLUMN roles.role_code IS '角色代碼：唯一識別碼（如：admin, approver, applicant）';
COMMENT ON COLUMN roles.role_name IS '角色名稱（中文）';
COMMENT ON COLUMN roles.is_system_role IS '是否為系統內建角色：系統內建角色不可刪除';
COMMENT ON COLUMN roles.is_active IS '是否啟用：停用的角色將無法分配給新用戶';

CREATE INDEX IF NOT EXISTS idx_roles_role_code ON roles(role_code);
CREATE INDEX IF NOT EXISTS idx_roles_is_active ON roles(is_active);
CREATE INDEX IF NOT EXISTS idx_roles_display_order ON roles(display_order);

DROP TRIGGER IF EXISTS update_roles_updated_at ON roles;
CREATE TRIGGER update_roles_updated_at
  BEFORE UPDATE ON roles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. 權限表 (permissions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS permissions (
  id BIGSERIAL PRIMARY KEY,
  permission_code VARCHAR(100) NOT NULL UNIQUE, -- 權限代碼（如：APPLY, REVIEW, SETTINGS）
  permission_name VARCHAR(100) NOT NULL, -- 權限名稱（中文）
  permission_name_en VARCHAR(100), -- 權限名稱（英文）
  module VARCHAR(100), -- 所屬模組
  description TEXT, -- 權限說明
  is_system_permission BOOLEAN DEFAULT FALSE, -- 是否為系統內建權限（不可刪除）
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  display_order INTEGER DEFAULT 0, -- 顯示順序
  created_by_id UUID REFERENCES user_profiles(id),
  updated_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE permissions IS '權限表：定義系統中的各種權限';
COMMENT ON COLUMN permissions.permission_code IS '權限代碼：唯一識別碼（如：APPLY, REVIEW, SETTINGS）';
COMMENT ON COLUMN permissions.permission_name IS '權限名稱（中文）';
COMMENT ON COLUMN permissions.module IS '所屬模組：權限所屬的功能模組';
COMMENT ON COLUMN permissions.is_system_permission IS '是否為系統內建權限：系統內建權限不可刪除';
COMMENT ON COLUMN permissions.is_active IS '是否啟用：停用的權限將無法分配給角色';

CREATE INDEX IF NOT EXISTS idx_permissions_permission_code ON permissions(permission_code);
CREATE INDEX IF NOT EXISTS idx_permissions_module ON permissions(module);
CREATE INDEX IF NOT EXISTS idx_permissions_is_active ON permissions(is_active);
CREATE INDEX IF NOT EXISTS idx_permissions_display_order ON permissions(display_order);

DROP TRIGGER IF EXISTS update_permissions_updated_at ON permissions;
CREATE TRIGGER update_permissions_updated_at
  BEFORE UPDATE ON permissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. 角色權限關聯表 (role_permissions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS role_permissions (
  id BIGSERIAL PRIMARY KEY,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(role_id, permission_id) -- 確保同一角色不會重複分配同一權限
);

COMMENT ON TABLE role_permissions IS '角色權限關聯表：定義哪些角色擁有哪些權限';
COMMENT ON COLUMN role_permissions.role_id IS '角色ID';
COMMENT ON COLUMN role_permissions.permission_id IS '權限ID';

CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions(permission_id);

-- ============================================================================
-- 4. 角色頁面權限關聯表 (role_page_access)
-- ============================================================================
CREATE TABLE IF NOT EXISTS role_page_access (
  id BIGSERIAL PRIMARY KEY,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  page_code VARCHAR(100) NOT NULL, -- 頁面代碼（如：apply, packaging, review）
  page_name VARCHAR(100) NOT NULL, -- 頁面名稱（中文）
  is_accessible BOOLEAN DEFAULT TRUE, -- 是否可以訪問
  created_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(role_id, page_code) -- 確保同一角色不會重複設定同一頁面
);

COMMENT ON TABLE role_page_access IS '角色頁面權限關聯表：定義哪些角色可以訪問哪些頁面';
COMMENT ON COLUMN role_page_access.role_id IS '角色ID';
COMMENT ON COLUMN role_page_access.page_code IS '頁面代碼：唯一識別碼（如：apply, packaging, review）';
COMMENT ON COLUMN role_page_access.page_name IS '頁面名稱（中文）';
COMMENT ON COLUMN role_page_access.is_accessible IS '是否可以訪問：控制角色是否可以訪問該頁面';

CREATE INDEX IF NOT EXISTS idx_role_page_access_role_id ON role_page_access(role_id);
CREATE INDEX IF NOT EXISTS idx_role_page_access_page_code ON role_page_access(page_code);

DROP TRIGGER IF EXISTS update_role_page_access_updated_at ON role_page_access;
CREATE TRIGGER update_role_page_access_updated_at
  BEFORE UPDATE ON role_page_access
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. 初始化系統內建角色
-- ============================================================================
INSERT INTO roles (role_code, role_name, role_name_en, description, is_system_role, is_active, display_order)
VALUES
  ('admin', '系統管理員', 'Administrator', '擁有所有權限，可管理系統設定和使用者', TRUE, TRUE, 1),
  ('approver', '審核人員', 'Approver', '可審核和核准物料申請', TRUE, TRUE, 2),
  ('applicant', '申請人員', 'Applicant', '可提交物料申請', TRUE, TRUE, 3)
ON CONFLICT (role_code) DO UPDATE SET
  role_name = EXCLUDED.role_name,
  role_name_en = EXCLUDED.role_name_en,
  description = EXCLUDED.description,
  updated_at = NOW();

-- ============================================================================
-- 5. 初始化系統內建權限
-- ============================================================================
INSERT INTO permissions (permission_code, permission_name, permission_name_en, module, description, is_system_permission, is_active, display_order)
VALUES
  ('APPLY', '物料申請', 'Material Application', 'application', '可提交物料申請', TRUE, TRUE, 1),
  ('PACKAGING', '包裝說明設定', 'Packaging Settings', 'packaging', '可設定包裝說明', TRUE, TRUE, 2),
  ('REVIEW', '審核管理', 'Review Management', 'review', '可審核申請', TRUE, TRUE, 3),
  ('EXPORT', 'EXCEL匯出', 'Excel Export', 'export', '可匯出EXCEL', TRUE, TRUE, 4),
  ('QUERY', '申請查詢', 'Application Query', 'query', '可查詢申請記錄', TRUE, TRUE, 5),
  ('SETTINGS', '系統設定', 'System Settings', 'settings', '可管理系統設定', TRUE, TRUE, 6),
  ('USERS', '使用者管理', 'User Management', 'user', '可管理使用者', TRUE, TRUE, 7),
  ('APPROVAL_WORKFLOW', '審核流程設定', 'Approval Workflow Settings', 'workflow', '可設定審核流程', TRUE, TRUE, 8),
  ('FORMS', '表單管理', 'Form Management', 'form', '可管理表單', TRUE, TRUE, 9),
  ('ROLE_PERMISSION', '角色權限管理', 'Role Permission Management', 'admin', '可管理角色和權限', TRUE, TRUE, 10),
  ('DEPARTMENT', '部門管理', 'Department Management', 'admin', '可管理部門', TRUE, TRUE, 11)
ON CONFLICT (permission_code) DO UPDATE SET
  permission_name = EXCLUDED.permission_name,
  permission_name_en = EXCLUDED.permission_name_en,
  module = EXCLUDED.module,
  description = EXCLUDED.description,
  updated_at = NOW();

-- ============================================================================
-- 6. 初始化角色權限關聯（預設權限分配）
-- ============================================================================
-- 系統管理員擁有所有權限
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 審核人員擁有審核、查詢、匯出權限
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'approver'
  AND p.permission_code IN ('REVIEW', 'QUERY', 'EXPORT', 'APPLY')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 申請人員擁有申請、查詢、匯出權限
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'applicant'
  AND p.permission_code IN ('APPLY', 'QUERY', 'EXPORT')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ============================================================================
-- 第十二部分：審核流程
-- （來源: create_approval_workflow_schema.sql）
-- ============================================================================

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
  is_conditional BOOLEAN NOT NULL DEFAULT false, -- 是否為條件型流程步驟
  trigger_insert_order INTEGER, -- 插入位置：0=0→1，N=N→N+1
  trigger_field VARCHAR(255), -- 觸發欄位（form_fields.field_key）
  trigger_value TEXT, -- 觸發值
  trigger_operator VARCHAR(20) NOT NULL DEFAULT 'equals', -- 觸發運算
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
COMMENT ON COLUMN approval_workflow_steps.is_conditional IS '是否為條件型流程步驟（插入於一般步驟之間）';
COMMENT ON COLUMN approval_workflow_steps.trigger_insert_order IS '插入位置：0 表示 0→1，N 表示 N→N+1';
COMMENT ON COLUMN approval_workflow_steps.trigger_field IS '觸發欄位：對應 form_fields.field_key';
COMMENT ON COLUMN approval_workflow_steps.trigger_value IS '觸發值：欄位值符合時啟用此條件步驟';
COMMENT ON COLUMN approval_workflow_steps.trigger_operator IS '觸發運算：equals（預設）';

CREATE INDEX IF NOT EXISTS idx_approval_workflow_steps_workflow_id ON approval_workflow_steps(workflow_id);
CREATE INDEX IF NOT EXISTS idx_approval_workflow_steps_step_order ON approval_workflow_steps(workflow_id, step_order);
CREATE INDEX IF NOT EXISTS idx_approval_workflow_steps_status_code ON approval_workflow_steps(status_code);
CREATE INDEX IF NOT EXISTS idx_approval_workflow_steps_conditional
  ON approval_workflow_steps(workflow_id, is_conditional, trigger_insert_order);

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

-- ============================================================================
-- 第十三部分：部門管理
-- （來源: create_department_schema.sql）
-- ============================================================================

-- ============================================================================
-- 部門管理資料表
-- 用途：動態管理組織部門
-- ============================================================================

-- ============================================================================
-- 1. 部門表 (departments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS departments (
  id BIGSERIAL PRIMARY KEY,
  department_code VARCHAR(50) NOT NULL UNIQUE, -- 部門代碼（如：IT, HR, FINANCE）
  department_name VARCHAR(100) NOT NULL, -- 部門名稱（中文）
  department_name_en VARCHAR(100), -- 部門名稱（英文）
  parent_id BIGINT REFERENCES departments(id) ON DELETE SET NULL, -- 上級部門ID（支援階層結構）
  manager_id UUID REFERENCES user_profiles(id) ON DELETE SET NULL, -- 部門主管ID
  description TEXT, -- 部門說明
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  display_order INTEGER DEFAULT 0, -- 顯示順序
  created_by_id UUID REFERENCES user_profiles(id),
  updated_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE departments IS '部門表：定義組織中的各個部門';
COMMENT ON COLUMN departments.department_code IS '部門代碼：唯一識別碼（如：IT, HR, FINANCE）';
COMMENT ON COLUMN departments.department_name IS '部門名稱（中文）';
COMMENT ON COLUMN departments.parent_id IS '上級部門ID：支援階層結構，NULL表示頂層部門';
COMMENT ON COLUMN departments.manager_id IS '部門主管ID：關聯到 user_profiles.id';
COMMENT ON COLUMN departments.is_active IS '是否啟用：停用的部門將無法分配給新用戶';

CREATE INDEX IF NOT EXISTS idx_departments_department_code ON departments(department_code);
CREATE INDEX IF NOT EXISTS idx_departments_parent_id ON departments(parent_id);
CREATE INDEX IF NOT EXISTS idx_departments_manager_id ON departments(manager_id);
CREATE INDEX IF NOT EXISTS idx_departments_is_active ON departments(is_active);
CREATE INDEX IF NOT EXISTS idx_departments_display_order ON departments(display_order);

DROP TRIGGER IF EXISTS update_departments_updated_at ON departments;
CREATE TRIGGER update_departments_updated_at
  BEFORE UPDATE ON departments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. 初始化預設部門（從 system_options 遷移）
-- ============================================================================
-- 從 system_options 表中讀取部門選項並插入到 departments 表
INSERT INTO departments (department_code, department_name, department_name_en, is_active, display_order)
SELECT 
  key AS department_code,
  label AS department_name,
  value AS department_name_en,
  TRUE AS is_active,
  ROW_NUMBER() OVER (ORDER BY id) AS display_order
FROM system_options
WHERE module = 'approval_workflow' AND cate = 'department'
ON CONFLICT (department_code) DO UPDATE SET
  department_name = EXCLUDED.department_name,
  department_name_en = EXCLUDED.department_name_en,
  updated_at = NOW();

-- ============================================================================
-- 3. 更新 user_profiles.department 為外鍵關聯（可選，需要時再執行）
-- ============================================================================
-- 注意：此步驟會修改現有資料結構，建議先備份
-- ALTER TABLE user_profiles
--   DROP COLUMN IF EXISTS department,
--   ADD COLUMN department_id BIGINT REFERENCES departments(id) ON DELETE SET NULL;

-- 或者保留 department 欄位作為字串，但建議使用 department_id 作為外鍵
-- 目前先保留現有結構，部門代碼存儲在 user_profiles.department 中

-- ============================================================================
-- 第十四部分：選項活頁簿
-- （來源: create_option_workbooks_schema.sql）
-- ============================================================================

-- ============================================================================
-- 選項活頁簿功能 - 資料庫結構
-- ============================================================================
-- 建立日期: 2026-01-20
-- 說明: 使用者可以自定義資料儲存欄位，可以從指定的 col 作為 option 提供給表單使用
-- ============================================================================

-- ============================================================================
-- 1. 選項活頁簿主表 (option_workbooks)
-- ============================================================================
-- 儲存活頁簿的基本資訊（分頁名稱與key）
CREATE TABLE IF NOT EXISTS option_workbooks (
  id BIGSERIAL PRIMARY KEY,
  workbook_key VARCHAR(100) NOT NULL UNIQUE, -- 活頁簿唯一識別碼
  workbook_name VARCHAR(255) NOT NULL, -- 活頁簿名稱（分頁名稱）
  description TEXT, -- 說明
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  created_by_id UUID REFERENCES user_profiles(id), -- 建立人
  updated_by_id UUID REFERENCES user_profiles(id), -- 更新人
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE option_workbooks IS '選項活頁簿主表：儲存活頁簿的基本資訊';
COMMENT ON COLUMN option_workbooks.workbook_key IS '活頁簿唯一識別碼：用於系統內部引用';
COMMENT ON COLUMN option_workbooks.workbook_name IS '活頁簿名稱：顯示給使用者看的分頁名稱';

CREATE INDEX IF NOT EXISTS idx_option_workbooks_workbook_key ON option_workbooks(workbook_key);
CREATE INDEX IF NOT EXISTS idx_option_workbooks_is_active ON option_workbooks(is_active);

CREATE TRIGGER update_option_workbooks_updated_at
  BEFORE UPDATE ON option_workbooks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. 選項活頁簿欄位定義表 (option_workbook_columns)
-- ============================================================================
-- 定義活頁簿的欄位結構（key, label, 其他欄位用json儲存）
CREATE TABLE IF NOT EXISTS option_workbook_columns (
  id BIGSERIAL PRIMARY KEY,
  workbook_id BIGINT NOT NULL REFERENCES option_workbooks(id) ON DELETE CASCADE, -- 所屬活頁簿
  column_key VARCHAR(100) NOT NULL, -- 欄位鍵值（例如：value, label, description）
  column_label VARCHAR(255) NOT NULL, -- 欄位標籤（顯示名稱）
  column_type VARCHAR(50) DEFAULT 'text', -- 欄位類型：text, number, date, boolean, select
  is_key BOOLEAN DEFAULT FALSE, -- 是否為key欄位（用於識別）
  is_label BOOLEAN DEFAULT FALSE, -- 是否為label欄位（用於顯示）
  is_option_source BOOLEAN DEFAULT FALSE, -- 是否作為選項來源（用於表單選項）
  display_order INTEGER DEFAULT 0, -- 顯示順序
  column_config JSONB, -- 欄位額外設定（JSON格式，例如：選項列表、驗證規則等）
  is_visible BOOLEAN DEFAULT TRUE, -- 是否顯示
  is_required BOOLEAN DEFAULT FALSE, -- 是否必填
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- 同一活頁簿內欄位鍵值必須唯一
  UNIQUE(workbook_id, column_key)
);

COMMENT ON TABLE option_workbook_columns IS '選項活頁簿欄位定義表：定義活頁簿的欄位結構';
COMMENT ON COLUMN option_workbook_columns.column_key IS '欄位鍵值：用於儲存和讀取資料';
COMMENT ON COLUMN option_workbook_columns.column_label IS '欄位標籤：顯示給使用者看的欄位名稱';
COMMENT ON COLUMN option_workbook_columns.is_key IS '是否為key欄位：用於識別記錄的唯一值';
COMMENT ON COLUMN option_workbook_columns.is_label IS '是否為label欄位：用於顯示記錄的名稱';
COMMENT ON COLUMN option_workbook_columns.is_option_source IS '是否作為選項來源：此欄位的值可以作為表單選項使用';
COMMENT ON COLUMN option_workbook_columns.column_config IS '欄位設定：JSON格式，可儲存選項列表、驗證規則等';

CREATE INDEX IF NOT EXISTS idx_option_workbook_columns_workbook_id ON option_workbook_columns(workbook_id);
CREATE INDEX IF NOT EXISTS idx_option_workbook_columns_display_order ON option_workbook_columns(workbook_id, display_order);
CREATE INDEX IF NOT EXISTS idx_option_workbook_columns_is_option_source ON option_workbook_columns(workbook_id, is_option_source);

CREATE TRIGGER update_option_workbook_columns_updated_at
  BEFORE UPDATE ON option_workbook_columns
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. 選項活頁簿資料表 (option_workbook_rows)
-- ============================================================================
-- 儲存活頁簿的實際資料（key, label, 其他資料用json儲存）
CREATE TABLE IF NOT EXISTS option_workbook_rows (
  id BIGSERIAL PRIMARY KEY,
  workbook_id BIGINT NOT NULL REFERENCES option_workbooks(id) ON DELETE CASCADE, -- 所屬活頁簿
  row_key VARCHAR(100) NOT NULL, -- 資料行的key值（用於識別）
  row_label VARCHAR(255) NOT NULL, -- 資料行的label值（用於顯示）
  row_data JSONB NOT NULL DEFAULT '{}', -- 其他欄位資料（JSON格式）
  display_order INTEGER DEFAULT 0, -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE, -- 是否啟用
  created_by_id UUID REFERENCES user_profiles(id), -- 建立人
  updated_by_id UUID REFERENCES user_profiles(id), -- 更新人
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- 同一活頁簿內key值必須唯一
  UNIQUE(workbook_id, row_key)
);

COMMENT ON TABLE option_workbook_rows IS '選項活頁簿資料表：儲存活頁簿的實際資料';
COMMENT ON COLUMN option_workbook_rows.row_key IS '資料行的key值：用於識別記錄的唯一值';
COMMENT ON COLUMN option_workbook_rows.row_label IS '資料行的label值：用於顯示記錄的名稱';
COMMENT ON COLUMN option_workbook_rows.row_data IS '其他欄位資料：JSON格式，儲存除key和label外的所有欄位資料';

CREATE INDEX IF NOT EXISTS idx_option_workbook_rows_workbook_id ON option_workbook_rows(workbook_id);
CREATE INDEX IF NOT EXISTS idx_option_workbook_rows_row_key ON option_workbook_rows(workbook_id, row_key);
CREATE INDEX IF NOT EXISTS idx_option_workbook_rows_display_order ON option_workbook_rows(workbook_id, display_order);
CREATE INDEX IF NOT EXISTS idx_option_workbook_rows_is_active ON option_workbook_rows(workbook_id, is_active);

CREATE TRIGGER update_option_workbook_rows_updated_at
  BEFORE UPDATE ON option_workbook_rows
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 第十五部分：包裝說明模板
-- （來源: create_packaging_template_table.sql）
-- ============================================================================

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

-- ============================================================================
-- 第十六部分：種子資料
-- （來源: supabase_schema_20260120234234.sql）
-- ============================================================================

-- 第四部分：匯入需要保留的記錄資料
-- ============================================================================

-- 匯入 user_profiles 記錄
INSERT INTO "public"."user_profiles" ("id", "username", "role", "department", "position", "phone", "avatar_url", "is_active", "created_at", "updated_at", "last_login", "last_login_ip") VALUES 
('d5830627-1ee5-4a0b-aa92-fa1375c0990b', '陳泓伸', 'admin', '資訊', null, '0939272530', null, 'true', '2025-12-18 00:38:33.384379+00', '2025-12-18 01:08:03.859653+00', '2025-12-18 01:08:04.325+00', '203.75.190.163'), 
('e09e8326-8ae2-47d4-85bd-0f47792f18de', 'keoinn', 'admin', null, null, null, null, 'true', '2025-12-17 02:31:49.791781+00', '2026-01-20 14:29:41.105063+00', '2026-01-20 14:29:40.948+00', '1.174.5.140')
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  role = EXCLUDED.role,
  department = EXCLUDED.department,
  position = EXCLUDED.position,
  phone = EXCLUDED.phone,
  avatar_url = EXCLUDED.avatar_url,
  is_active = EXCLUDED.is_active,
  updated_at = EXCLUDED.updated_at,
  last_login = EXCLUDED.last_login,
  last_login_ip = EXCLUDED.last_login_ip;

-- 匯入 forms 記錄
INSERT INTO "public"."forms" ("id", "form_code", "form_name", "form_name_en", "description", "version", "is_active", "is_default", "form_config", "created_by_id", "updated_by_id", "created_at", "updated_at") VALUES 
('5', 'ma_r002', '物料申請', '', '', '1', 'true', 'true', '{"sub_groups":{"包裝說明":[{"name":"1. 個別產品包裝","order":0},{"name":"2. 配件內容","order":1},{"name":"3. 配件","order":2},{"name":"4. 內盒","order":3},{"name":"5. 外箱","order":4},{"name":"6. 運輸與托盤要求","order":5},{"name":"7. 裝櫃要求","order":6},{"name":"8. 其他說明","order":7}]},"group_order":["基本資料","物料資訊","尺寸規格","包裝說明"]}', null, null, '2026-01-17 10:37:20.519784+00', '2026-01-20 06:07:09.872034+00')
ON CONFLICT (id) DO UPDATE SET
  form_code = EXCLUDED.form_code,
  form_name = EXCLUDED.form_name,
  form_name_en = EXCLUDED.form_name_en,
  description = EXCLUDED.description,
  version = EXCLUDED.version,
  is_active = EXCLUDED.is_active,
  is_default = EXCLUDED.is_default,
  form_config = EXCLUDED.form_config,
  created_by_id = EXCLUDED.created_by_id,
  updated_by_id = EXCLUDED.updated_by_id,
  updated_at = EXCLUDED.updated_at;

-- 匯入 form_fields 記錄
INSERT INTO "public"."form_fields" ("id", "form_id", "field_key", "field_label", "field_label_en", "field_type", "max_length", "is_required", "field_group", "display_order", "field_config", "default_value", "placeholder", "help_text", "validation_rules", "is_visible", "is_readonly", "created_at", "updated_at", "sub_group") VALUES 
('166', '5', 'system_code', '系統編碼', '', 'aggregated', null, 'false', '基本資料', '2', '{"cols":3,"template":"{#main_type}{#sub_type}.{#detail_type}.{@sn#6}"}', '', '', '', '{}', 'true', 'true', '2026-01-18 15:38:29.214773+00', '2026-01-20 06:07:10.484219+00', ''), 
('167', '5', 'materials_desc_cn', '料件說明 (中文)', '', 'text', null, 'true', '物料資訊', '3', '{"cols":6}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:51:08.471868+00', '2026-01-20 06:07:10.665937+00', ''), 
('168', '5', 'materials_desc_en', '料件說明 (英文)', '', 'text', null, 'true', '物料資訊', '4', '{"cols":6}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:51:08.809392+00', '2026-01-20 06:07:10.8435+00', ''), 
('169', '5', 'customer_product_no', '客戶參考貨號', '', 'text', null, 'false', '物料資訊', '5', '{"cols":6}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:51:09.013009+00', '2026-01-20 06:07:11.016812+00', ''), 
('170', '5', 'supplier', '供應商', '', 'select', null, 'false', '物料資訊', '6', '{"cols":6,"options":[]}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:51:09.321803+00', '2026-01-20 06:07:11.185543+00', ''), 
('171', '5', 'basic_material', '基本材質', '', 'select', null, 'true', '物料資訊', '7', '{"cols":6,"options":[{"label":"Aluminum","title":"Aluminum","value":"A"},{"label":"Brass","title":"Brass","value":"B"},{"label":"Others","title":"Others","value":"C"},{"label":"Plastic","title":"Plastic","value":"P"},{"label":"Stainless Steel","title":"Stainless Steel","value":"SS"},{"label":"Steel","title":"Steel","value":"S"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:51:09.521695+00', '2026-01-20 06:07:11.366549+00', ''), 
('172', '5', 'surface_processing', '表面處理', '', 'select', null, 'false', '物料資訊', '8', '{"cols":6,"options":[{"label":"Anodized","title":"Anodized","value":"A"},{"label":"Chrome Plated","title":"Chrome Plated","value":"CP"},{"label":"Natural","title":"Natural","value":"N"},{"label":"Nickel Plated","title":"Nickel Plated","value":"NP"},{"label":"Powder Coating","title":"Powder Coating","value":"PC"},{"label":"Zinc Plated","title":"Zinc Plated","value":"ZP"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:51:09.836491+00', '2026-01-20 06:07:11.525683+00', ''), 
('173', '5', 'item_length', '長度 (mm)', '', 'number', null, 'false', '尺寸規格', '9', '{"cols":3}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:56:03.005445+00', '2026-01-20 06:07:11.692924+00', ''), 
('174', '5', 'item_width', '寬度 (mm)', '', 'number', null, 'false', '尺寸規格', '10', '{"cols":3}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:56:03.141676+00', '2026-01-20 06:07:11.890646+00', ''), 
('175', '5', 'item_height', '高度 (mm)', '', 'number', null, 'false', '尺寸規格', '11', '{"cols":3}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:56:03.422794+00', '2026-01-20 06:07:12.055026+00', ''), 
('176', '5', 'item_weight', '重量 (g)', '', 'number', null, 'false', '尺寸規格', '12', '{"cols":3}', '', '', '', '{}', 'true', 'false', '2026-01-18 15:56:03.555223+00', '2026-01-20 06:07:12.219515+00', ''), 
('177', '5', 'individual_packaging', '個別產品包裝', '', 'checkbox', null, 'false', '包裝說明', '15', '{"cols":12,"options":[{"label":"塑膠袋","title":"塑膠袋","value":"01"},{"label":"氣泡袋","title":"氣泡袋","value":"02"},{"label":"PE/PP 材質","title":"PE/PP 材質","value":"03"},{"label":"彩盒包裝","title":"彩盒包裝","value":"04"},{"label":"回收標誌","title":"回收標誌","value":"05"},{"label":"產品標籤","title":"產品標籤","value":"06"},{"label":"說明書","title":"說明書","value":"07"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 16:04:19.605989+00', '2026-01-20 06:07:12.740861+00', '1. 個別產品包裝'), 
('178', '5', 'individual_packaging_note', '額外說明', '', 'textarea', null, 'false', '包裝說明', '16', '{"cols":12}', '', '額外說明 (如： 1PC/塑膠袋，印刷回收標誌04 PE-LD)', '', '{}', 'true', 'false', '2026-01-18 16:04:19.897057+00', '2026-01-20 06:07:12.939542+00', '1. 個別產品包裝'), 
('179', '5', 'inner_box', '內盒', '', 'checkbox', null, 'false', '包裝說明', '14', '{"cols":12,"options":[{"label":"印製ITEM NO.","title":"印製ITEM NO.","value":"01"},{"label":"印製數量","title":"印製數量","value":"02"},{"label":"條碼","title":"條碼","value":"03"},{"label":"標籤","title":"標籤","value":"04"},{"label":"客戶Logo","title":"客戶Logo","value":"05"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 16:39:03.743866+00', '2026-01-20 06:07:12.587391+00', '4. 內盒'), 
('180', '5', 'accessories_content', '配件內容', '', 'checkbox', null, 'false', '包裝說明', '17', '{"cols":12,"options":[{"label":"螺絲","title":"螺絲","value":"01"},{"label":"支架","title":"支架","value":"02"},{"label":"蓋子/端蓋","title":"蓋子/端蓋","value":"03"},{"label":"緩衝墊","title":"緩衝墊","value":"04"},{"label":"散裝","title":"散裝","value":"05"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 16:39:04.382086+00', '2026-01-20 06:07:13.110409+00', '2. 配件內容'), 
('181', '5', 'accessories_content_note', '額外說明', '', 'textarea', null, 'false', '包裝說明', '18', '{"cols":12}', '', '額外說明 (如： 附木螺絲4顆，螺絲散裝)', '', '{}', 'true', 'false', '2026-01-18 16:39:04.623435+00', '2026-01-20 06:07:13.27544+00', '2. 配件內容'), 
('182', '5', 'accessories', '配件', '', 'checkbox', null, 'false', '包裝說明', '19', '{"cols":12,"options":[{"label":"供應商提供","title":"供應商提供","value":"01"},{"label":"客戶提供","title":"客戶提供","value":"02"},{"label":"標準配件","title":"標準配件","value":"03"},{"label":"選配配件","title":"選配配件","value":"04"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 16:39:04.735099+00', '2026-01-20 06:07:13.468703+00', '3. 配件'), 
('183', '5', 'accessories_note', '額外說明', '', 'textarea', null, 'false', '包裝說明', '20', '{"cols":12}', '', '額外說明', '', '{}', 'true', 'false', '2026-01-18 16:39:04.862356+00', '2026-01-20 06:07:13.639139+00', '3. 配件'), 
('184', '5', 'inner_box_note', '額外說明', '', 'textarea', null, 'false', '包裝說明', '21', '{"cols":12}', '', '額外說明 (如：內盒上需印製ITEM NO. & Q''TY)', '', '{}', 'true', 'false', '2026-01-18 16:39:05.145885+00', '2026-01-20 06:07:13.815526+00', '4. 內盒'), 
('185', '5', 'outer_box', '外箱', '', 'checkbox', null, 'false', '包裝說明', '22', '{"cols":12,"options":[{"label":"瓦愣紙箱","title":"瓦愣紙箱","value":"01"},{"label":"側嘜","title":"側嘜","value":"02"},{"label":"客戶產品編號","title":"客戶產品編號","value":"03"},{"label":"出貨嘜頭","title":"出貨嘜頭","value":"04"},{"label":"易碎標誌","title":"易碎標誌","value":"05"},{"label":"向上標誌","title":"向上標誌","value":"06"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 16:39:05.329521+00', '2026-01-20 06:07:13.978567+00', '5. 外箱'), 
('186', '5', 'outer_box_note', '額外說明', '', 'textarea', null, 'false', '包裝說明', '23', '{"cols":12}', '', '額外說明 (如：外箱側嘜之ITEM NO.請印製客戶產品編號)', '', '{}', 'true', 'false', '2026-01-18 16:39:05.457221+00', '2026-01-20 06:07:14.134888+00', '5. 外箱'), 
('187', '5', 'trans_pallet_req', '運輸與托盤要求', '', 'checkbox', null, 'false', '包裝說明', '13', '{"cols":12,"options":[{"label":"托盤/Pallet","title":"托盤/Pallet","value":"01"},{"label":"纏繞膜","title":"纏繞膜","value":"02"},{"label":"護角","title":"護角","value":"03"},{"label":"打包帶","title":"打包帶","value":"04"},{"label":"EUDR文件","title":"EUDR文件","value":"05"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 16:51:40.898288+00', '2026-01-20 06:07:12.42072+00', '6. 運輸與托盤要求'), 
('188', '5', 'trans_pallet_req_note', '額外說明', '', 'textarea', null, 'false', '包裝說明', '24', '{"cols":12}', '', '額外說明 (如：出貨提供EUDR文件)', '', '{}', 'true', 'false', '2026-01-18 16:51:43.427537+00', '2026-01-20 06:07:14.285079+00', '6. 運輸與托盤要求'), 
('189', '5', 'cabinet_req', '裝櫃需求', '', 'checkbox', null, 'false', '包裝說明', '25', '{"cols":12,"options":[{"label":"20呎櫃","title":"20呎櫃","value":"01"},{"label":"40呎櫃","title":"40呎櫃","value":"02"},{"label":"40高櫃","title":"40高櫃","value":"03"},{"label":"棧板出貨","title":"棧板出貨","value":"04"},{"label":"散裝貨櫃","title":"散裝貨櫃","value":"05"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 16:51:43.567009+00', '2026-01-20 06:07:14.51222+00', '7. 裝櫃要求'), 
('190', '5', 'cabinet_req_note', '額外說明', '', 'textarea', null, 'false', '包裝說明', '26', '{"cols":12}', '', '額外說明 (如：256SETS/1X40FCL)', '', '{}', 'true', 'false', '2026-01-18 16:51:43.789383+00', '2026-01-20 06:07:14.672737+00', '7. 裝櫃要求'), 
('191', '5', 'other_desc', '其他說明', '', 'checkbox', null, 'false', '包裝說明', '27', '{"cols":12,"options":[{"label":"FSC 認證","title":"FSC 認證","value":"01"},{"label":"RoHS認證","title":"RoHS認證","value":"02"},{"label":"REACH認證","title":"REACH認證","value":"03"},{"label":"ISO認證","title":"ISO認證","value":"04"},{"label":"測試報告","title":"測試報告","value":"05"}]}', '', '', '', '{}', 'true', 'false', '2026-01-18 16:51:43.91465+00', '2026-01-20 06:07:14.835881+00', '8. 其他說明'), 
('192', '5', 'other_desc_note', '額外說明', '', 'textarea', null, 'false', '包裝說明', '28', '{"cols":12}', '', '額外說明 (如：供應商具FSC證書)', '', '{}', 'true', 'false', '2026-01-18 16:51:44.041858+00', '2026-01-20 06:07:15.038164+00', '8. 其他說明'), 
('199', '5', 'type', '', '', 'cascading_select', null, 'false', '基本資料', '1', '{"cols":12,"levels":[{"label":"產品大類","field_key":"main_type","help_text":"","columnSize":3,"is_visible":true,"field_label":"產品大類","is_required":true,"placeholder":"請選擇","default_value":"","display_order":1,"placeholder_text":"產品大類"},{"label":"產品中類","field_key":"sub_type","help_text":"","columnSize":3,"is_visible":true,"field_label":"產品中類","is_required":true,"placeholder":"請選擇","default_value":"","display_order":2,"placeholder_text":"產品中類"},{"label":"產品小類","field_key":"detail_type","help_text":"","columnSize":3,"is_visible":true,"field_label":"產品小類","is_required":true,"placeholder":"請選擇","default_value":"","display_order":3,"placeholder_text":"產品小類"}],"cascading_options":[{"label":"H - Handle (手把)","title":"H - Handle (手把)","value":"H","children":[{"label":"00 - 未分類","value":"00","children":[{"label":"A - Aluminum","value":"A"},{"label":"B - Brass","value":"B"},{"label":"C - Chrome","value":"C"},{"label":"S - Stainless Steel","value":"S"},{"label":"Z - Zinc Alloy","value":"Z"}]},{"label":"01 - Knob","value":"01","children":[{"label":"A - Aluminum","value":"A"},{"label":"B - Brass","value":"B"},{"label":"C - Chrome","value":"C"},{"label":"S - Stainless Steel","value":"S"},{"label":"Z - Zinc Alloy","value":"Z"}]},{"label":"02 - Pull","value":"02","children":[{"label":"A - Aluminum","value":"A"},{"label":"B - Brass","value":"B"},{"label":"C - Chrome","value":"C"},{"label":"S - Stainless Steel","value":"S"},{"label":"Z - Zinc Alloy","value":"Z"}]},{"label":"03 - Handle","value":"03","children":[{"label":"A - Aluminum","value":"A"},{"label":"B - Brass","value":"B"},{"label":"C - Chrome","value":"C"},{"label":"S - Stainless Steel","value":"S"},{"label":"Z - Zinc Alloy","value":"Z"}]},{"label":"04 - Bar Handle","value":"04","children":[{"label":"A - Aluminum","value":"A"},{"label":"B - Brass","value":"B"},{"label":"C - Chrome","value":"C"},{"label":"S - Stainless Steel","value":"S"},{"label":"Z - Zinc Alloy","value":"Z"}]},{"label":"05 - Cup Pull","value":"05","children":[{"label":"A - Aluminum","value":"A"},{"label":"B - Brass","value":"B"},{"label":"C - Chrome","value":"C"},{"label":"S - Stainless Steel","value":"S"},{"label":"Z - Zinc Alloy","value":"Z"}]}]},{"label":"S - Slide (滑軌)","title":"S - Slide (滑軌)","value":"S","children":[{"label":"00 - 未分類","value":"00","children":[{"label":"B - Ball Bearing","value":"B"},{"label":"S - Soft Close","value":"S"},{"label":"F - Full Extension","value":"F"},{"label":"P - Partial Extension","value":"P"}]},{"label":"01 - Ball Bearing Slide","value":"01","children":[{"label":"B - Ball Bearing","value":"B"},{"label":"S - Soft Close","value":"S"},{"label":"F - Full Extension","value":"F"},{"label":"P - Partial Extension","value":"P"}]},{"label":"02 - Undermount Slide","value":"02","children":[{"label":"B - Ball Bearing","value":"B"},{"label":"S - Soft Close","value":"S"},{"label":"F - Full Extension","value":"F"},{"label":"P - Partial Extension","value":"P"}]},{"label":"03 - Soft Close Slide","value":"03","children":[{"label":"B - Ball Bearing","value":"B"},{"label":"S - Soft Close","value":"S"},{"label":"F - Full Extension","value":"F"},{"label":"P - Partial Extension","value":"P"}]},{"label":"04 - Heavy Duty Slide","value":"04","children":[{"label":"B - Ball Bearing","value":"B"},{"label":"S - Soft Close","value":"S"},{"label":"F - Full Extension","value":"F"},{"label":"P - Partial Extension","value":"P"}]}]},{"label":"M - Module/Assy (模組)","title":"M - Module/Assy (模組)","value":"M","children":[{"label":"00 - 未分類","value":"00","children":[{"label":"D - Drawer","value":"D"},{"label":"P - Pull-Out","value":"P"},{"label":"O - Organizer","value":"O"},{"label":"B - Basket","value":"B"}]},{"label":"01 - Drawer System","value":"01","children":[{"label":"D - Drawer","value":"D"},{"label":"P - Pull-Out","value":"P"},{"label":"O - Organizer","value":"O"},{"label":"B - Basket","value":"B"}]},{"label":"02 - Pull-Out System","value":"02","children":[{"label":"D - Drawer","value":"D"},{"label":"P - Pull-Out","value":"P"},{"label":"O - Organizer","value":"O"},{"label":"B - Basket","value":"B"}]},{"label":"03 - Organizer","value":"03","children":[{"label":"D - Drawer","value":"D"},{"label":"P - Pull-Out","value":"P"},{"label":"O - Organizer","value":"O"},{"label":"B - Basket","value":"B"}]},{"label":"04 - Basket System","value":"04","children":[{"label":"D - Drawer","value":"D"},{"label":"P - Pull-Out","value":"P"},{"label":"O - Organizer","value":"O"},{"label":"B - Basket","value":"B"}]}]},{"label":"D - Decorative Hardware (裝飾五金)","title":"D - Decorative Hardware (裝飾五金)","value":"D","children":[{"label":"00 - 未分類","value":"00","children":[{"label":"L - Leg","value":"L"},{"label":"H - Handle","value":"H"},{"label":"O - Ornament","value":"O"}]},{"label":"01 - Furniture Leg","value":"01","children":[{"label":"L - Leg","value":"L"},{"label":"H - Handle","value":"H"},{"label":"O - Ornament","value":"O"}]},{"label":"02 - Decorative Handle","value":"02","children":[{"label":"L - Leg","value":"L"},{"label":"H - Handle","value":"H"},{"label":"O - Ornament","value":"O"}]},{"label":"03 - Ornament","value":"03","children":[{"label":"L - Leg","value":"L"},{"label":"H - Handle","value":"H"},{"label":"O - Ornament","value":"O"}]}]},{"label":"F - Functional Hardware (功能五金)","title":"F - Functional Hardware (功能五金)","value":"F","children":[{"label":"00 - 未分類","value":"00","children":[{"label":"H - Hinge","value":"H"},{"label":"C - Caster","value":"C"},{"label":"L - Lock","value":"L"},{"label":"T - Catch","value":"T"}]},{"label":"01 - Hinge","value":"01","children":[{"label":"H - Hinge","value":"H"},{"label":"C - Caster","value":"C"},{"label":"L - Lock","value":"L"},{"label":"T - Catch","value":"T"}]},{"label":"02 - Caster","value":"02","children":[{"label":"H - Hinge","value":"H"},{"label":"C - Caster","value":"C"},{"label":"L - Lock","value":"L"},{"label":"T - Catch","value":"T"}]},{"label":"03 - Lock","value":"03","children":[{"label":"H - Hinge","value":"H"},{"label":"C - Caster","value":"C"},{"label":"L - Lock","value":"L"},{"label":"T - Catch","value":"T"}]},{"label":"04 - Catch","value":"04","children":[{"label":"H - Hinge","value":"H"},{"label":"C - Caster","value":"C"},{"label":"L - Lock","value":"L"},{"label":"T - Catch","value":"T"}]}]},{"label":"B - Builders Hardware (建築五金)","title":"B - Builders Hardware (建築五金)","value":"B","children":[{"label":"00 - 未分類","value":"00","children":[{"label":"D - Door","value":"D"},{"label":"W - Window","value":"W"},{"label":"G - Gate","value":"G"}]},{"label":"01 - Door Hardware","value":"01","children":[{"label":"D - Door","value":"D"},{"label":"W - Window","value":"W"},{"label":"G - Gate","value":"G"}]},{"label":"02 - Window Hardware","value":"02","children":[{"label":"D - Door","value":"D"},{"label":"W - Window","value":"W"},{"label":"G - Gate","value":"G"}]},{"label":"03 - Gate Hardware","value":"03","children":[{"label":"D - Door","value":"D"},{"label":"W - Window","value":"W"},{"label":"G - Gate","value":"G"}]}]},{"label":"I - Industrial Parts Solution (工業零件)","title":"I - Industrial Parts Solution (工業零件)","value":"I","children":[{"label":"00 - 未分類","value":"00","children":[{"label":"S - Slide","value":"S"},{"label":"H - Heavy Duty","value":"H"},{"label":"C - Custom","value":"C"}]},{"label":"01 - Industrial Slide","value":"01","children":[{"label":"S - Slide","value":"S"},{"label":"H - Heavy Duty","value":"H"},{"label":"C - Custom","value":"C"}]},{"label":"02 - Heavy Duty Component","value":"02","children":[{"label":"S - Slide","value":"S"},{"label":"H - Heavy Duty","value":"H"},{"label":"C - Custom","value":"C"}]},{"label":"03 - Custom Solution","value":"03","children":[{"label":"S - Slide","value":"S"},{"label":"H - Heavy Duty","value":"H"},{"label":"C - Custom","value":"C"}]}]},{"label":"O - Others (其他)","title":"O - Others (其他)","value":"O","children":[{"label":"00 - 未分類","value":"00","children":[{"label":"X - 其他","value":"X"}]},{"label":"99 - 其他","value":"99","children":[{"label":"X - 其他","value":"X"}]}]}]}', '', '', '', '{}', 'true', 'false', '2026-01-20 05:55:26.206329+00', '2026-01-20 06:07:10.294584+00', '')
ON CONFLICT (form_id, field_key) DO UPDATE SET
  field_label = EXCLUDED.field_label,
  field_label_en = EXCLUDED.field_label_en,
  field_type = EXCLUDED.field_type,
  max_length = EXCLUDED.max_length,
  is_required = EXCLUDED.is_required,
  field_group = EXCLUDED.field_group,
  sub_group = EXCLUDED.sub_group,
  display_order = EXCLUDED.display_order,
  field_config = EXCLUDED.field_config,
  default_value = EXCLUDED.default_value,
  placeholder = EXCLUDED.placeholder,
  help_text = EXCLUDED.help_text,
  validation_rules = EXCLUDED.validation_rules,
  is_visible = EXCLUDED.is_visible,
  is_readonly = EXCLUDED.is_readonly,
  updated_at = EXCLUDED.updated_at;

-- 匯入 system_options 記錄
-- 注意：已移除以下 module 的記錄：
--       - application_query
--       - review_management
--       - system_settings
--       - excel_export
-- 僅保留 attachment_management 的記錄
INSERT INTO "public"."system_options" ("id", "module", "cate", "parent_key", "key", "value", "label", "desc", "created_at", "updated_at") VALUES 
('38', 'attachment_management', 'fileType', null, 'image', 'image', '圖片', '圖片檔案', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('39', 'attachment_management', 'fileType', null, 'document', 'document', '文件', '文件檔案', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('40', 'attachment_management', 'fileType', null, 'drawing', 'drawing', '圖面', '工程圖面', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('41', 'attachment_management', 'fileType', null, 'other', 'other', '其他', '其他類型檔案', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO UPDATE SET
  value = EXCLUDED.value,
  label = EXCLUDED.label,
  "desc" = EXCLUDED."desc",
  updated_at = EXCLUDED.updated_at;

-- 匯入 system_settings 記錄
INSERT INTO "public"."system_settings" ("id", "setting_key", "setting_value", "setting_type", "description", "updated_by_id", "created_at", "updated_at") VALUES 
('1', 'serialDigits', '6', 'number', '流水號位數', 'e09e8326-8ae2-47d4-85bd-0f47792f18de', '2025-12-17 02:11:35.66813+00', '2025-12-17 03:38:51.087892+00'), 
('2', 'serialStart', '1', 'string', '流水號起始值', null, '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('3', 'autoApprove', 'false', 'boolean', '自動審核', 'e09e8326-8ae2-47d4-85bd-0f47792f18de', '2025-12-17 02:11:35.66813+00', '2025-12-17 03:38:51.087892+00'), 
('4', 'emailNotify', 'true', 'boolean', 'Email通知', 'e09e8326-8ae2-47d4-85bd-0f47792f18de', '2025-12-17 02:11:35.66813+00', '2025-12-17 03:38:51.087892+00'), 
('5', 'approvalLevel', '1', 'number', '審核層級', null, '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00')
ON CONFLICT (setting_key) DO UPDATE SET
  setting_value = EXCLUDED.setting_value,
  setting_type = EXCLUDED.setting_type,
  description = EXCLUDED.description,
  updated_by_id = EXCLUDED.updated_by_id,
  updated_at = EXCLUDED.updated_at;

-- ============================================================================
-- 第十七部分：選項活頁簿頁面權限
-- （來源: add_option_workbooks_page_access.sql）
-- ============================================================================

-- ============================================================================
-- 為現有角色添加「選項活頁簿」頁面權限
-- 用途：為所有現有角色添加「選項活頁簿」頁面權限
-- 執行時間：在新增「選項活頁簿」功能後執行
-- ============================================================================

-- 為所有現有角色添加「選項活頁簿」頁面權限
-- 預設：系統管理員可以訪問，其他角色需要手動設定
INSERT INTO role_page_access (role_id, page_code, page_name, is_accessible)
SELECT 
  r.id,
  'option-workbooks',
  '選項活頁簿',
  CASE 
    WHEN r.role_code = 'admin' THEN TRUE  -- 系統管理員預設可以訪問
    ELSE FALSE  -- 其他角色預設不可訪問，需要手動設定
  END
FROM roles r
WHERE NOT EXISTS (
  SELECT 1 
  FROM role_page_access rpa 
  WHERE rpa.role_id = r.id 
  AND rpa.page_code = 'option-workbooks'
)
ON CONFLICT (role_id, page_code) DO NOTHING;

-- 如果希望所有角色都可以訪問，可以使用以下 SQL（取消註解）：
-- INSERT INTO role_page_access (role_id, page_code, page_name, is_accessible)
-- SELECT 
--   r.id,
--   'option-workbooks',
--   '選項活頁簿',
--   TRUE  -- 所有角色都可以訪問
-- FROM roles r
-- WHERE NOT EXISTS (
--   SELECT 1 
--   FROM role_page_access rpa 
--   WHERE rpa.role_id = r.id 
--   AND rpa.page_code = 'option-workbooks'
-- )
-- ON CONFLICT (role_id, page_code) DO NOTHING;

-- ============================================================================
-- 第十八部分：RPC 函數
-- （來源: get_users_with_email.sql）
-- ============================================================================

-- ============================================================================
-- RPC 函數：獲取使用者列表（包含 email）
-- ============================================================================
-- 此函數用於從 user_profiles 和 auth.users 獲取使用者資料，包含 email
-- 需要 SECURITY DEFINER 權限來訪問 auth.users

CREATE OR REPLACE FUNCTION public.get_users_with_email(
  p_role VARCHAR DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL,
  p_search VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  username VARCHAR,
  role VARCHAR,
  department VARCHAR,
  "position" VARCHAR,
  phone VARCHAR,
  avatar_url VARCHAR,
  is_active BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  last_login TIMESTAMP WITH TIME ZONE,
  last_login_ip VARCHAR,
  email VARCHAR
) AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_users_with_email IS '獲取使用者列表（包含 email），需要 SECURITY DEFINER 權限來訪問 auth.users';
