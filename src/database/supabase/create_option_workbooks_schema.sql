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
