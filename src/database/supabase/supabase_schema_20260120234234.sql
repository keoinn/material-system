-- ============================================================================
-- Supabase Schema: 整理後的資料庫結構
-- ============================================================================
-- 建立日期: 2026-01-20
-- 說明: 整理資料庫，僅保留必要的資料表
-- 保留的表: code_counters, export_logs, attachments, form_data_values, 
--           form_fields, forms, system_options, system_settings, user_profiles
-- ============================================================================

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

CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON user_profiles(username);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON user_profiles(is_active);

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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(form_id, field_key) -- 同一表單內欄位鍵值必須唯一
);

COMMENT ON TABLE form_fields IS '表單欄位定義表：儲存表單的欄位定義資訊';
COMMENT ON COLUMN form_fields.field_type IS '欄位類型：text=文字, textarea=多行文字, number=數字, select=下拉選單, multiselect=多選下拉, checkbox=複選框, radio=單選框, date=日期, datetime=日期時間, file=檔案, json=JSON資料';
COMMENT ON COLUMN form_fields.field_group IS '欄位群組：用於分組顯示，例如「基本資訊」、「分類資訊」等';
COMMENT ON COLUMN form_fields.sub_group IS '子群組名稱：用於排版顯示，例如「基本資訊區塊」、「詳細資訊區塊」等';

CREATE INDEX IF NOT EXISTS idx_form_fields_form_id ON form_fields(form_id);
CREATE INDEX IF NOT EXISTS idx_form_fields_field_key ON form_fields(field_key);
CREATE INDEX IF NOT EXISTS idx_form_fields_field_type ON form_fields(field_type);
CREATE INDEX IF NOT EXISTS idx_form_fields_field_group ON form_fields(field_group);
CREATE INDEX IF NOT EXISTS idx_form_fields_sub_group ON form_fields(form_id, field_group, sub_group);
CREATE INDEX IF NOT EXISTS idx_form_fields_display_order ON form_fields(form_id, display_order);
CREATE INDEX IF NOT EXISTS idx_form_fields_is_visible ON form_fields(is_visible);

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
INSERT INTO "public"."system_options" ("id", "module", "cate", "parent_key", "key", "value", "label", "desc", "created_at", "updated_at") VALUES 
('1', 'application_query', 'applicationStatus', null, 'PENDING', 'PENDING', '待審核', '等待審核中', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('2', 'application_query', 'applicationStatus', null, 'APPROVED', 'APPROVED', '已核准', '已通過審核', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('3', 'application_query', 'applicationStatus', null, 'REJECTED', 'REJECTED', '已退回', '已退回修改', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('4', 'application_query', 'applicationStatus', null, 'ALL', 'ALL', '全部', '所有狀態', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('5', 'review_management', 'applicationStatus', null, 'PENDING', 'PENDING', '待審核', '等待審核中', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('6', 'review_management', 'applicationStatus', null, 'APPROVED', 'APPROVED', '已核准', '已通過審核', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('7', 'review_management', 'applicationStatus', null, 'REJECTED', 'REJECTED', '已退回', '已退回修改', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('8', 'excel_export', 'applicationStatus', null, 'ALL', 'ALL', '全部', '所有狀態', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('9', 'excel_export', 'applicationStatus', null, 'APPROVED', 'APPROVED', '已核准', '已通過審核', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('10', 'excel_export', 'applicationStatus', null, 'PENDING', 'PENDING', '待審核', '等待審核中', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('11', 'excel_export', 'applicationStatus', null, 'REJECTED', 'REJECTED', '已退回', '已退回修改', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('15', 'review_management', 'approvalAction', null, 'SUBMIT', 'SUBMIT', '提交', '提交申請', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('16', 'review_management', 'approvalAction', null, 'APPROVE', 'APPROVE', '核准', '核准申請', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('17', 'review_management', 'approvalAction', null, 'REJECT', 'REJECT', '退回', '退回申請', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('18', 'review_management', 'approvalAction', null, 'RETURN', 'RETURN', '退回修改', '退回修改', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('22', 'system_settings', 'serialDigits', null, '4', '4', '4位數', '0001-9999', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('23', 'system_settings', 'serialDigits', null, '5', '5', '5位數', '00001-99999', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('24', 'system_settings', 'serialDigits', null, '6', '6', '6位數', '000001-999999', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('25', 'system_settings', 'boolean', null, 'true', 'true', '開啟', '啟用此功能', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('26', 'system_settings', 'boolean', null, 'false', 'false', '關閉', '停用此功能', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('27', 'system_settings', 'approvalLevel', null, '1', '1', '單層審核', '只需一層審核', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('28', 'system_settings', 'approvalLevel', null, '2', '2', '雙層審核', '需要兩層審核', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('29', 'system_settings', 'approvalLevel', null, '3', '3', '三層審核', '需要三層審核', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('30', 'excel_export', 'exportFormat', null, 'CSV', 'CSV', 'CSV', '逗號分隔值檔案', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('31', 'excel_export', 'exportFormat', null, 'XLSX', 'XLSX', 'Excel', 'Excel檔案格式', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
('32', 'excel_export', 'exportFormat', null, 'PDF', 'PDF', 'PDF', 'PDF檔案格式', '2025-12-17 02:11:35.66813+00', '2025-12-17 02:11:35.66813+00'), 
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
