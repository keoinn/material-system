-- ============================================================================
-- 編碼計數器表 (code_counters)
-- 用於聚合資料欄位的系統計數序號
-- ============================================================================

-- 如果表已存在，先刪除（可選，用於重新創建）
-- DROP TABLE IF EXISTS code_counters CASCADE;

CREATE TABLE IF NOT EXISTS code_counters (
  id BIGSERIAL PRIMARY KEY,
  key VARCHAR(50) NOT NULL UNIQUE, -- 計數器鍵值，格式可自定義，例如: {大類}{中類}.{小類} 或 {欄位key}
  counter INTEGER NOT NULL DEFAULT 0, -- 當前計數值
  last_used_date TIMESTAMP WITH TIME ZONE, -- 最後使用日期
  last_used_by_id UUID REFERENCES user_profiles(id), -- 最後使用人
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 創建時間
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() -- 更新時間
);

COMMENT ON TABLE code_counters IS '編碼計數器表：用於產生聚合資料欄位的流水號計數器';
COMMENT ON COLUMN code_counters.key IS '計數器鍵值，用於唯一標識一個計數器';
COMMENT ON COLUMN code_counters.counter IS '當前計數值，從 0 開始';
COMMENT ON COLUMN code_counters.last_used_date IS '最後使用日期';
COMMENT ON COLUMN code_counters.last_used_by_id IS '最後使用人 ID';

-- 創建索引以提升查詢效能
CREATE INDEX IF NOT EXISTS idx_code_counters_key ON code_counters(key);
CREATE INDEX IF NOT EXISTS idx_code_counters_last_used_date ON code_counters(last_used_date);

-- 創建更新時間自動更新的觸發器（如果 update_updated_at_column 函數存在）
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') THEN
    DROP TRIGGER IF EXISTS update_code_counters_updated_at ON code_counters;
    CREATE TRIGGER update_code_counters_updated_at
      BEFORE UPDATE ON code_counters
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;
