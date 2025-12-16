-- ============================================================================
-- Supabase Schema: 系統資料表
-- ============================================================================
-- 根據 schema.js (310-701行) 生成
-- 已重構：高優先級項目獨立成專門資料表
-- ============================================================================

-- 建立更新時間的自動更新觸發器函數
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 1. 產品分類系統 (product_categories)
-- ============================================================================
-- 三層階層結構：大類 → 中類 → 小類
CREATE TABLE IF NOT EXISTS product_categories (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(10) NOT NULL,        -- 分類代碼 (H, S, M, 01, 02, A, B, C)
  name VARCHAR(255) NOT NULL,               -- 分類名稱（英文）
  name_cn VARCHAR(255),                     -- 中文名稱
  level INTEGER NOT NULL,                   -- 層級 (1=大類, 2=中類, 3=小類)
  parent_id BIGINT REFERENCES product_categories(id), -- 父層分類
  main_category_code VARCHAR(1),            -- 大類代碼 (H, S, M, D, F, B, I, O)
  display_order INTEGER DEFAULT 0,          -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE,          -- 是否啟用
  description TEXT,                        -- 說明
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(level, code, main_category_code) -- 複合唯一約束：同一層級、同一大類下 code 必須唯一
);

COMMENT ON TABLE product_categories IS '產品分類系統：三層階層結構（大類、中類、小類）';
COMMENT ON COLUMN product_categories.level IS '層級：1=大類, 2=中類, 3=小類';
COMMENT ON COLUMN product_categories.main_category_code IS '大類代碼：用於快速查詢和關聯';

CREATE INDEX idx_product_categories_level ON product_categories(level);
CREATE INDEX idx_product_categories_parent_id ON product_categories(parent_id);
CREATE INDEX idx_product_categories_main_category_code ON product_categories(main_category_code);

CREATE TRIGGER update_product_categories_updated_at
  BEFORE UPDATE ON product_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. 供應商 (suppliers)
-- ============================================================================
CREATE TABLE IF NOT EXISTS suppliers (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,         -- 供應商代碼 (SUP001, SUP002)
  name VARCHAR(255) NOT NULL,               -- 供應商名稱
  contact_person VARCHAR(100),              -- 聯絡人
  email VARCHAR(255),                       -- Email
  phone VARCHAR(50),                        -- 電話
  address TEXT,                             -- 地址
  country VARCHAR(100),                     -- 國家
  is_active BOOLEAN DEFAULT TRUE,          -- 是否啟用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE suppliers IS '供應商資料表：符合 schema.js 中的 supplierSchema 定義';

CREATE INDEX idx_suppliers_code ON suppliers(code);
CREATE INDEX idx_suppliers_is_active ON suppliers(is_active);

CREATE TRIGGER update_suppliers_updated_at
  BEFORE UPDATE ON suppliers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. 包裝類別與選項 (packaging_categories, packaging_options)
-- ============================================================================
CREATE TABLE IF NOT EXISTS packaging_categories (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,         -- 類別代碼 (productPackaging, innerBox, etc.)
  name VARCHAR(255) NOT NULL,               -- 類別名稱（英文）
  name_cn VARCHAR(255),                     -- 中文名稱
  display_order INTEGER DEFAULT 0,          -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE,          -- 是否啟用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE packaging_categories IS '包裝類別：8個包裝類別（個別產品包裝、配件內容、配件、內盒、外箱、運輸、裝櫃、其他）';

CREATE INDEX idx_packaging_categories_code ON packaging_categories(code);
CREATE INDEX idx_packaging_categories_display_order ON packaging_categories(display_order);

CREATE TRIGGER update_packaging_categories_updated_at
  BEFORE UPDATE ON packaging_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS packaging_options (
  id BIGSERIAL PRIMARY KEY,
  category_id BIGINT NOT NULL REFERENCES packaging_categories(id) ON DELETE CASCADE,
  code VARCHAR(100) NOT NULL,              -- 選項代碼（通常與名稱相同）
  name VARCHAR(255) NOT NULL,               -- 選項名稱
  description TEXT,                         -- 說明
  display_order INTEGER DEFAULT 0,          -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE,          -- 是否啟用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(category_id, code)
);

COMMENT ON TABLE packaging_options IS '包裝選項：各類別下的具體包裝選項';

CREATE INDEX idx_packaging_options_category_id ON packaging_options(category_id);
CREATE INDEX idx_packaging_options_display_order ON packaging_options(display_order);

CREATE TRIGGER update_packaging_options_updated_at
  BEFORE UPDATE ON packaging_options
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. 類別預設包裝 (category_packaging_defaults)
-- ============================================================================
CREATE TABLE IF NOT EXISTS category_packaging_defaults (
  id BIGSERIAL PRIMARY KEY,
  main_category_code VARCHAR(1) NOT NULL, -- 產品大類代碼 (H, S, M)
  packaging_category_id BIGINT NOT NULL REFERENCES packaging_categories(id) ON DELETE CASCADE,
  packaging_option_id BIGINT NOT NULL REFERENCES packaging_options(id) ON DELETE CASCADE,
  display_order INTEGER DEFAULT 0,          -- 顯示順序
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(main_category_code, packaging_category_id, packaging_option_id)
);

COMMENT ON TABLE category_packaging_defaults IS '類別預設包裝：各產品大類的預設包裝選項';

CREATE INDEX idx_category_packaging_defaults_main_category ON category_packaging_defaults(main_category_code);
CREATE INDEX idx_category_packaging_defaults_packaging_category ON category_packaging_defaults(packaging_category_id);

CREATE TRIGGER update_category_packaging_defaults_updated_at
  BEFORE UPDATE ON category_packaging_defaults
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. 系統參數資料表 (system_options)
-- ============================================================================
-- 保留用於系統設定類的選項（資料量小、變動頻率低）
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

CREATE INDEX idx_system_options_module ON system_options(module);
CREATE INDEX idx_system_options_cate ON system_options(cate);
CREATE INDEX idx_system_options_module_cate ON system_options(module, cate);

CREATE TRIGGER update_system_options_updated_at
  BEFORE UPDATE ON system_options
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 插入資料
-- ============================================================================

-- 1. 產品分類系統資料
-- 1.1 大類 (Level 1)
INSERT INTO product_categories (code, name, name_cn, level, parent_id, main_category_code, display_order, description) VALUES
('H', 'Handle', 'H - Handle (把手)', 1, NULL, 'H', 1, '各類把手、拉手、旋鈕'),
('S', 'Slide', 'S - Slide (滑軌)', 1, NULL, 'S', 2, '抽屜滑軌、工業滑軌'),
('M', 'Module/Assy', 'M - Module/Assy (模組)', 1, NULL, 'M', 3, '組合件、系統模組'),
('D', 'Decorative Hardware', 'D - Decorative Hardware (裝飾五金)', 1, NULL, 'D', 4, '裝飾性配件'),
('F', 'Functional Hardware', 'F - Functional Hardware (功能五金)', 1, NULL, 'F', 5, '功能性配件'),
('B', 'Builders Hardware', 'B - Builders Hardware (建築五金)', 1, NULL, 'B', 6, '建築用五金'),
('I', 'Industrial Parts Solution', 'I - Industrial Parts Solution (工業零件)', 1, NULL, 'I', 7, '工業解決方案'),
('O', 'Others', 'O - Others (其他)', 1, NULL, 'O', 8, '未分類項目')
ON CONFLICT (level, code, main_category_code) DO NOTHING;

-- 1.2 中類 (Level 2) - H 類別
INSERT INTO product_categories (code, name, name_cn, level, parent_id, main_category_code, display_order, description) VALUES
('00', '未分類', '未分類', 2, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 0, NULL),
('01', 'Knob', 'Knob', 2, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 1, '旋鈕'),
('02', 'Pull', 'Pull', 2, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 2, '拉手'),
('03', 'Handle', 'Handle', 2, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 3, '把手'),
('04', 'Bar Handle', 'Bar Handle', 2, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 4, '橫桿把手'),
('05', 'Cup Pull', 'Cup Pull', 2, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 5, '杯型拉手'),
('06', 'Ring Pull', 'Ring Pull', 2, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 6, '環型拉手')
ON CONFLICT (level, code, main_category_code) DO NOTHING;

-- 1.3 中類 (Level 2) - S 類別
INSERT INTO product_categories (code, name, name_cn, level, parent_id, main_category_code, display_order, description) VALUES
('00', '未分類', '未分類', 2, (SELECT id FROM product_categories WHERE code = 'S' AND level = 1), 'S', 0, NULL),
('01', 'Ball Bearing Slide', 'Ball Bearing Slide', 2, (SELECT id FROM product_categories WHERE code = 'S' AND level = 1), 'S', 1, '滾珠滑軌'),
('02', 'Undermount Slide', 'Undermount Slide', 2, (SELECT id FROM product_categories WHERE code = 'S' AND level = 1), 'S', 2, '底裝滑軌'),
('03', 'Soft Close Slide', 'Soft Close Slide', 2, (SELECT id FROM product_categories WHERE code = 'S' AND level = 1), 'S', 3, '緩衝滑軌'),
('04', 'Heavy Duty Slide', 'Heavy Duty Slide', 2, (SELECT id FROM product_categories WHERE code = 'S' AND level = 1), 'S', 4, '重載滑軌')
ON CONFLICT (level, code, main_category_code) DO NOTHING;

-- 1.4 中類 (Level 2) - M 類別
INSERT INTO product_categories (code, name, name_cn, level, parent_id, main_category_code, display_order, description) VALUES
('00', '未分類', '未分類', 2, (SELECT id FROM product_categories WHERE code = 'M' AND level = 1), 'M', 0, NULL),
('01', 'Drawer System', 'Drawer System', 2, (SELECT id FROM product_categories WHERE code = 'M' AND level = 1), 'M', 1, '抽屜系統'),
('02', 'Pull-Out System', 'Pull-Out System', 2, (SELECT id FROM product_categories WHERE code = 'M' AND level = 1), 'M', 2, '拉出系統'),
('03', 'Organizer', 'Organizer', 2, (SELECT id FROM product_categories WHERE code = 'M' AND level = 1), 'M', 3, '收納系統'),
('04', 'Basket System', 'Basket System', 2, (SELECT id FROM product_categories WHERE code = 'M' AND level = 1), 'M', 4, '籃架系統')
ON CONFLICT (level, code, main_category_code) DO NOTHING;

-- 1.5 中類 (Level 2) - D, F, B, I, O 類別
INSERT INTO product_categories (code, name, name_cn, level, parent_id, main_category_code, display_order, description) VALUES
-- D 類別
('00', '未分類', '未分類', 2, (SELECT id FROM product_categories WHERE code = 'D' AND level = 1), 'D', 0, NULL),
('01', 'Furniture Leg', 'Furniture Leg', 2, (SELECT id FROM product_categories WHERE code = 'D' AND level = 1), 'D', 1, '家具腳'),
('02', 'Decorative Handle', 'Decorative Handle', 2, (SELECT id FROM product_categories WHERE code = 'D' AND level = 1), 'D', 2, '裝飾把手'),
('03', 'Ornament', 'Ornament', 2, (SELECT id FROM product_categories WHERE code = 'D' AND level = 1), 'D', 3, '裝飾品'),
-- F 類別
('00', '未分類', '未分類', 2, (SELECT id FROM product_categories WHERE code = 'F' AND level = 1), 'F', 0, NULL),
('01', 'Hinge', 'Hinge', 2, (SELECT id FROM product_categories WHERE code = 'F' AND level = 1), 'F', 1, '鉸鏈'),
('02', 'Caster', 'Caster', 2, (SELECT id FROM product_categories WHERE code = 'F' AND level = 1), 'F', 2, '腳輪'),
('03', 'Lock', 'Lock', 2, (SELECT id FROM product_categories WHERE code = 'F' AND level = 1), 'F', 3, '鎖具'),
('04', 'Catch', 'Catch', 2, (SELECT id FROM product_categories WHERE code = 'F' AND level = 1), 'F', 4, '扣件'),
-- B 類別
('00', '未分類', '未分類', 2, (SELECT id FROM product_categories WHERE code = 'B' AND level = 1), 'B', 0, NULL),
('01', 'Door Hardware', 'Door Hardware', 2, (SELECT id FROM product_categories WHERE code = 'B' AND level = 1), 'B', 1, '門用五金'),
('02', 'Window Hardware', 'Window Hardware', 2, (SELECT id FROM product_categories WHERE code = 'B' AND level = 1), 'B', 2, '窗用五金'),
('03', 'Gate Hardware', 'Gate Hardware', 2, (SELECT id FROM product_categories WHERE code = 'B' AND level = 1), 'B', 3, '門閘五金'),
-- I 類別
('00', '未分類', '未分類', 2, (SELECT id FROM product_categories WHERE code = 'I' AND level = 1), 'I', 0, NULL),
('01', 'Industrial Slide', 'Industrial Slide', 2, (SELECT id FROM product_categories WHERE code = 'I' AND level = 1), 'I', 1, '工業滑軌'),
('02', 'Heavy Duty Component', 'Heavy Duty Component', 2, (SELECT id FROM product_categories WHERE code = 'I' AND level = 1), 'I', 2, '重載組件'),
('03', 'Custom Solution', 'Custom Solution', 2, (SELECT id FROM product_categories WHERE code = 'I' AND level = 1), 'I', 3, '客製化解決方案'),
-- O 類別
('00', '未分類', '未分類', 2, (SELECT id FROM product_categories WHERE code = 'O' AND level = 1), 'O', 0, NULL),
('99', '其他', '其他', 2, (SELECT id FROM product_categories WHERE code = 'O' AND level = 1), 'O', 99, NULL)
ON CONFLICT (level, code, main_category_code) DO NOTHING;

-- 1.6 小類 (Level 3) - H 類別
INSERT INTO product_categories (code, name, name_cn, level, parent_id, main_category_code, display_order, description) VALUES
('A', 'Aluminum', 'Aluminum', 3, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 1, '鋁'),
('B', 'Brass', 'Brass', 3, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 2, '黃銅'),
('C', 'Chrome', 'Chrome', 3, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 3, '鍍鉻'),
('S', 'Stainless Steel', 'Stainless Steel', 3, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 4, '不鏽鋼'),
('Z', 'Zinc Alloy', 'Zinc Alloy', 3, (SELECT id FROM product_categories WHERE code = 'H' AND level = 1), 'H', 5, '鋅合金')
ON CONFLICT (level, code, main_category_code) DO NOTHING;

-- 1.7 小類 (Level 3) - S, M, D, F, B, I, O 類別
INSERT INTO product_categories (code, name, name_cn, level, parent_id, main_category_code, display_order, description) VALUES
-- S 類別
('B', 'Ball Bearing', 'Ball Bearing', 3, (SELECT id FROM product_categories WHERE code = 'S' AND level = 1), 'S', 1, '滾珠軸承'),
('S', 'Soft Close', 'Soft Close', 3, (SELECT id FROM product_categories WHERE code = 'S' AND level = 1), 'S', 2, '緩衝關閉'),
('F', 'Full Extension', 'Full Extension', 3, (SELECT id FROM product_categories WHERE code = 'S' AND level = 1), 'S', 3, '全開式'),
('P', 'Partial Extension', 'Partial Extension', 3, (SELECT id FROM product_categories WHERE code = 'S' AND level = 1), 'S', 4, '部分開啟'),
-- M 類別
('D', 'Drawer', 'Drawer', 3, (SELECT id FROM product_categories WHERE code = 'M' AND level = 1), 'M', 1, '抽屜'),
('P', 'Pull-Out', 'Pull-Out', 3, (SELECT id FROM product_categories WHERE code = 'M' AND level = 1), 'M', 2, '拉出'),
('O', 'Organizer', 'Organizer', 3, (SELECT id FROM product_categories WHERE code = 'M' AND level = 1), 'M', 3, '收納'),
('B', 'Basket', 'Basket', 3, (SELECT id FROM product_categories WHERE code = 'M' AND level = 1), 'M', 4, '籃架'),
-- D 類別
('L', 'Leg', 'Leg', 3, (SELECT id FROM product_categories WHERE code = 'D' AND level = 1), 'D', 1, '腳'),
('H', 'Handle', 'Handle', 3, (SELECT id FROM product_categories WHERE code = 'D' AND level = 1), 'D', 2, '把手'),
('O', 'Ornament', 'Ornament', 3, (SELECT id FROM product_categories WHERE code = 'D' AND level = 1), 'D', 3, '裝飾'),
-- F 類別
('H', 'Hinge', 'Hinge', 3, (SELECT id FROM product_categories WHERE code = 'F' AND level = 1), 'F', 1, '鉸鏈'),
('C', 'Caster', 'Caster', 3, (SELECT id FROM product_categories WHERE code = 'F' AND level = 1), 'F', 2, '腳輪'),
('L', 'Lock', 'Lock', 3, (SELECT id FROM product_categories WHERE code = 'F' AND level = 1), 'F', 3, '鎖具'),
('T', 'Catch', 'Catch', 3, (SELECT id FROM product_categories WHERE code = 'F' AND level = 1), 'F', 4, '扣件'),
-- B 類別
('D', 'Door', 'Door', 3, (SELECT id FROM product_categories WHERE code = 'B' AND level = 1), 'B', 1, '門'),
('W', 'Window', 'Window', 3, (SELECT id FROM product_categories WHERE code = 'B' AND level = 1), 'B', 2, '窗'),
('G', 'Gate', 'Gate', 3, (SELECT id FROM product_categories WHERE code = 'B' AND level = 1), 'B', 3, '門閘'),
-- I 類別
('S', 'Slide', 'Slide', 3, (SELECT id FROM product_categories WHERE code = 'I' AND level = 1), 'I', 1, '滑軌'),
('H', 'Heavy Duty', 'Heavy Duty', 3, (SELECT id FROM product_categories WHERE code = 'I' AND level = 1), 'I', 2, '重載'),
('C', 'Custom', 'Custom', 3, (SELECT id FROM product_categories WHERE code = 'I' AND level = 1), 'I', 3, '客製化'),
-- O 類別
('X', '其他', '其他', 3, (SELECT id FROM product_categories WHERE code = 'O' AND level = 1), 'O', 1, NULL)
ON CONFLICT (level, code, main_category_code) DO NOTHING;

-- 2. 供應商資料
INSERT INTO suppliers (code, name, contact_person, email, phone, address, country, is_active) VALUES
('SUP001', '供應商A', NULL, NULL, NULL, NULL, NULL, TRUE),
('SUP002', '供應商B', NULL, NULL, NULL, NULL, NULL, TRUE),
('SUP003', '供應商C', NULL, NULL, NULL, NULL, NULL, TRUE)
ON CONFLICT (code) DO NOTHING;

-- 3. 包裝類別資料
INSERT INTO packaging_categories (code, name, name_cn, display_order) VALUES
('productPackaging', 'Product Packaging', '個別產品包裝', 1),
('accessoriesContent', 'Accessories Content', '配件內容', 2),
('accessories', 'Accessories', '配件', 3),
('innerBox', 'Inner Box', '內盒', 4),
('outerBox', 'Outer Box', '外箱', 5),
('transport', 'Transport', '運輸與托盤要求', 6),
('container', 'Container', '裝櫃要求', 7),
('other', 'Other', '其他說明', 8)
ON CONFLICT (code) DO NOTHING;

-- 4. 包裝選項資料
-- 4.1 個別產品包裝選項
INSERT INTO packaging_options (category_id, code, name, description, display_order) VALUES
((SELECT id FROM packaging_categories WHERE code = 'productPackaging'), '塑膠袋', '塑膠袋', 'PE/PP塑膠袋包裝', 1),
((SELECT id FROM packaging_categories WHERE code = 'productPackaging'), '氣泡袋', '氣泡袋', '氣泡袋保護包裝', 2),
((SELECT id FROM packaging_categories WHERE code = 'productPackaging'), 'PE/PP材質', 'PE/PP材質', 'PE或PP材質包裝', 3),
((SELECT id FROM packaging_categories WHERE code = 'productPackaging'), '彩盒包裝', '彩盒包裝', '彩色印刷紙盒包裝', 4),
((SELECT id FROM packaging_categories WHERE code = 'productPackaging'), '回收標誌', '回收標誌', '印刷回收標誌', 5),
((SELECT id FROM packaging_categories WHERE code = 'productPackaging'), '產品標籤', '產品標籤', '產品標籤貼紙', 6),
((SELECT id FROM packaging_categories WHERE code = 'productPackaging'), '說明書', '說明書', '產品說明書', 7);

-- 4.2 配件內容選項
INSERT INTO packaging_options (category_id, code, name, description, display_order) VALUES
((SELECT id FROM packaging_categories WHERE code = 'accessoriesContent'), '螺絲', '螺絲', '安裝用螺絲', 1),
((SELECT id FROM packaging_categories WHERE code = 'accessoriesContent'), '支架', '支架', '安裝支架', 2),
((SELECT id FROM packaging_categories WHERE code = 'accessoriesContent'), '蓋子/端蓋', '蓋子/端蓋', '端蓋或蓋子', 3),
((SELECT id FROM packaging_categories WHERE code = 'accessoriesContent'), '緩衝墊', '緩衝墊', '緩衝保護墊', 4),
((SELECT id FROM packaging_categories WHERE code = 'accessoriesContent'), '散裝', '散裝', '散裝配件', 5);

-- 4.3 配件選項
INSERT INTO packaging_options (category_id, code, name, description, display_order) VALUES
((SELECT id FROM packaging_categories WHERE code = 'accessories'), '供應商提供', '供應商提供', '由供應商提供', 1),
((SELECT id FROM packaging_categories WHERE code = 'accessories'), '客戶提供', '客戶提供', '由客戶提供', 2),
((SELECT id FROM packaging_categories WHERE code = 'accessories'), '標準配件', '標準配件', '標準配置配件', 3),
((SELECT id FROM packaging_categories WHERE code = 'accessories'), '選配配件', '選配配件', '選購配件', 4);

-- 4.4 內盒選項
INSERT INTO packaging_options (category_id, code, name, description, display_order) VALUES
((SELECT id FROM packaging_categories WHERE code = 'innerBox'), '印製ITEM NO.', '印製ITEM NO.', '內盒印製料號', 1),
((SELECT id FROM packaging_categories WHERE code = 'innerBox'), '印製數量', '印製數量', '內盒印製數量', 2),
((SELECT id FROM packaging_categories WHERE code = 'innerBox'), '條碼', '條碼', '內盒貼條碼', 3),
((SELECT id FROM packaging_categories WHERE code = 'innerBox'), '標籤', '標籤', '內盒貼標籤', 4),
((SELECT id FROM packaging_categories WHERE code = 'innerBox'), '客戶Logo', '客戶Logo', '內盒印製客戶Logo', 5);

-- 4.5 外箱選項
INSERT INTO packaging_options (category_id, code, name, description, display_order) VALUES
((SELECT id FROM packaging_categories WHERE code = 'outerBox'), '瓦楞紙箱', '瓦楞紙箱', '瓦楞紙箱包裝', 1),
((SELECT id FROM packaging_categories WHERE code = 'outerBox'), '側嘜', '側嘜', '外箱側面標籤', 2),
((SELECT id FROM packaging_categories WHERE code = 'outerBox'), '客戶產品編號', '客戶產品編號', '印製客戶產品編號', 3),
((SELECT id FROM packaging_categories WHERE code = 'outerBox'), '出貨嘜頭', '出貨嘜頭', '出貨標記', 4),
((SELECT id FROM packaging_categories WHERE code = 'outerBox'), '易碎標誌', '易碎標誌', '易碎物品標誌', 5),
((SELECT id FROM packaging_categories WHERE code = 'outerBox'), '向上標誌', '向上標誌', '向上箭頭標誌', 6);

-- 4.6 運輸與托盤要求選項
INSERT INTO packaging_options (category_id, code, name, description, display_order) VALUES
((SELECT id FROM packaging_categories WHERE code = 'transport'), '托盤/Pallet', '托盤/Pallet', '使用托盤', 1),
((SELECT id FROM packaging_categories WHERE code = 'transport'), '纏繞膜', '纏繞膜', '使用纏繞膜保護', 2),
((SELECT id FROM packaging_categories WHERE code = 'transport'), '護角', '護角', '使用護角保護', 3),
((SELECT id FROM packaging_categories WHERE code = 'transport'), '打包帶', '打包帶', '使用打包帶固定', 4),
((SELECT id FROM packaging_categories WHERE code = 'transport'), 'EUDR文件', 'EUDR文件', '提供EUDR文件', 5);

-- 4.7 裝櫃要求選項
INSERT INTO packaging_options (category_id, code, name, description, display_order) VALUES
((SELECT id FROM packaging_categories WHERE code = 'container'), '20呎櫃', '20呎櫃', '20呎貨櫃', 1),
((SELECT id FROM packaging_categories WHERE code = 'container'), '40呎櫃', '40呎櫃', '40呎貨櫃', 2),
((SELECT id FROM packaging_categories WHERE code = 'container'), '40呎高櫃', '40呎高櫃', '40呎高櫃', 3),
((SELECT id FROM packaging_categories WHERE code = 'container'), '棧板出貨', '棧板出貨', '使用棧板出貨', 4),
((SELECT id FROM packaging_categories WHERE code = 'container'), '散裝裝櫃', '散裝裝櫃', '散裝方式裝櫃', 5);

-- 4.8 其他說明選項
INSERT INTO packaging_options (category_id, code, name, description, display_order) VALUES
((SELECT id FROM packaging_categories WHERE code = 'other'), 'FSC認證', 'FSC認證', 'FSC森林認證', 1),
((SELECT id FROM packaging_categories WHERE code = 'other'), 'RoHS認證', 'RoHS認證', 'RoHS環保認證', 2),
((SELECT id FROM packaging_categories WHERE code = 'other'), 'REACH認證', 'REACH認證', 'REACH化學品認證', 3),
((SELECT id FROM packaging_categories WHERE code = 'other'), 'ISO認證', 'ISO認證', 'ISO品質認證', 4),
((SELECT id FROM packaging_categories WHERE code = 'other'), '測試報告', '測試報告', '提供測試報告', 5);

-- 5. 類別預設包裝資料
-- 5.1 H 類別預設值
INSERT INTO category_packaging_defaults (main_category_code, packaging_category_id, packaging_option_id, display_order) VALUES
-- productPackaging
('H', (SELECT id FROM packaging_categories WHERE code = 'productPackaging'), (SELECT id FROM packaging_options WHERE code = '塑膠袋' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'productPackaging')), 1),
('H', (SELECT id FROM packaging_categories WHERE code = 'productPackaging'), (SELECT id FROM packaging_options WHERE code = '產品標籤' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'productPackaging')), 2),
-- accessoriesContent
('H', (SELECT id FROM packaging_categories WHERE code = 'accessoriesContent'), (SELECT id FROM packaging_options WHERE code = '螺絲' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'accessoriesContent')), 1),
-- innerBox
('H', (SELECT id FROM packaging_categories WHERE code = 'innerBox'), (SELECT id FROM packaging_options WHERE code = '印製ITEM NO.' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'innerBox')), 1),
('H', (SELECT id FROM packaging_categories WHERE code = 'innerBox'), (SELECT id FROM packaging_options WHERE code = '印製數量' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'innerBox')), 2),
-- outerBox
('H', (SELECT id FROM packaging_categories WHERE code = 'outerBox'), (SELECT id FROM packaging_options WHERE code = '瓦楞紙箱' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'outerBox')), 1),
('H', (SELECT id FROM packaging_categories WHERE code = 'outerBox'), (SELECT id FROM packaging_options WHERE code = '側嘜' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'outerBox')), 2);

-- 5.2 S 類別預設值
INSERT INTO category_packaging_defaults (main_category_code, packaging_category_id, packaging_option_id, display_order) VALUES
-- productPackaging
('S', (SELECT id FROM packaging_categories WHERE code = 'productPackaging'), (SELECT id FROM packaging_options WHERE code = '氣泡袋' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'productPackaging')), 1),
('S', (SELECT id FROM packaging_categories WHERE code = 'productPackaging'), (SELECT id FROM packaging_options WHERE code = 'PE/PP材質' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'productPackaging')), 2),
-- accessoriesContent (注意：根據實際資料，說明書在 productPackaging 類別下，所以這裡只保留螺絲)
('S', (SELECT id FROM packaging_categories WHERE code = 'accessoriesContent'), (SELECT id FROM packaging_options WHERE code = '螺絲' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'accessoriesContent')), 1),
-- innerBox
('S', (SELECT id FROM packaging_categories WHERE code = 'innerBox'), (SELECT id FROM packaging_options WHERE code = '印製ITEM NO.' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'innerBox')), 1),
('S', (SELECT id FROM packaging_categories WHERE code = 'innerBox'), (SELECT id FROM packaging_options WHERE code = '條碼' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'innerBox')), 2),
-- outerBox
('S', (SELECT id FROM packaging_categories WHERE code = 'outerBox'), (SELECT id FROM packaging_options WHERE code = '瓦楞紙箱' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'outerBox')), 1),
('S', (SELECT id FROM packaging_categories WHERE code = 'outerBox'), (SELECT id FROM packaging_options WHERE code = '易碎標誌' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'outerBox')), 2);

-- 5.3 M 類別預設值
INSERT INTO category_packaging_defaults (main_category_code, packaging_category_id, packaging_option_id, display_order) VALUES
-- productPackaging
('M', (SELECT id FROM packaging_categories WHERE code = 'productPackaging'), (SELECT id FROM packaging_options WHERE code = '彩盒包裝' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'productPackaging')), 1),
-- accessoriesContent (注意：根據實際資料，說明書在 productPackaging 類別下，所以這裡只保留螺絲和支架)
('M', (SELECT id FROM packaging_categories WHERE code = 'accessoriesContent'), (SELECT id FROM packaging_options WHERE code = '螺絲' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'accessoriesContent')), 1),
('M', (SELECT id FROM packaging_categories WHERE code = 'accessoriesContent'), (SELECT id FROM packaging_options WHERE code = '支架' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'accessoriesContent')), 2),
-- innerBox
('M', (SELECT id FROM packaging_categories WHERE code = 'innerBox'), (SELECT id FROM packaging_options WHERE code = '印製ITEM NO.' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'innerBox')), 1),
('M', (SELECT id FROM packaging_categories WHERE code = 'innerBox'), (SELECT id FROM packaging_options WHERE code = '客戶Logo' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'innerBox')), 2),
-- outerBox
('M', (SELECT id FROM packaging_categories WHERE code = 'outerBox'), (SELECT id FROM packaging_options WHERE code = '瓦楞紙箱' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'outerBox')), 1),
('M', (SELECT id FROM packaging_categories WHERE code = 'outerBox'), (SELECT id FROM packaging_options WHERE code = '向上標誌' AND category_id = (SELECT id FROM packaging_categories WHERE code = 'outerBox')), 2);

-- 6. 系統設定選項（保留在 system_options 表）
-- 6.1 申請狀態選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('application_query', 'applicationStatus', NULL, 'PENDING', 'PENDING', '待審核', '等待審核中'),
('application_query', 'applicationStatus', NULL, 'APPROVED', 'APPROVED', '已核准', '已通過審核'),
('application_query', 'applicationStatus', NULL, 'REJECTED', 'REJECTED', '已退回', '已退回修改'),
('application_query', 'applicationStatus', NULL, 'ALL', 'ALL', '全部', '所有狀態'),
('review_management', 'applicationStatus', NULL, 'PENDING', 'PENDING', '待審核', '等待審核中'),
('review_management', 'applicationStatus', NULL, 'APPROVED', 'APPROVED', '已核准', '已通過審核'),
('review_management', 'applicationStatus', NULL, 'REJECTED', 'REJECTED', '已退回', '已退回修改'),
('excel_export', 'applicationStatus', NULL, 'ALL', 'ALL', '全部', '所有狀態'),
('excel_export', 'applicationStatus', NULL, 'APPROVED', 'APPROVED', '已核准', '已通過審核'),
('excel_export', 'applicationStatus', NULL, 'PENDING', 'PENDING', '待審核', '等待審核中'),
('excel_export', 'applicationStatus', NULL, 'REJECTED', 'REJECTED', '已退回', '已退回修改')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.2 優先級選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('material_application', 'priority', NULL, 'HIGH', 'HIGH', '高', '高優先級'),
('material_application', 'priority', NULL, 'MEDIUM', 'MEDIUM', '中', '中優先級'),
('material_application', 'priority', NULL, 'LOW', 'LOW', '低', '低優先級')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.3 審核動作選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('review_management', 'approvalAction', NULL, 'SUBMIT', 'SUBMIT', '提交', '提交申請'),
('review_management', 'approvalAction', NULL, 'APPROVE', 'APPROVE', '核准', '核准申請'),
('review_management', 'approvalAction', NULL, 'REJECT', 'REJECT', '退回', '退回申請'),
('review_management', 'approvalAction', NULL, 'RETURN', 'RETURN', '退回修改', '退回修改')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.4 使用者角色選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('user_management', 'userRole', NULL, 'admin', 'admin', '系統管理員', '擁有所有權限'),
('user_management', 'userRole', NULL, 'approver', 'approver', '審核人員', '可審核申請'),
('user_management', 'userRole', NULL, 'applicant', 'applicant', '申請人員', '可提交申請')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.5 流水號位數選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('system_settings', 'serialDigits', NULL, '4', '4', '4位數', '0001-9999'),
('system_settings', 'serialDigits', NULL, '5', '5', '5位數', '00001-99999'),
('system_settings', 'serialDigits', NULL, '6', '6', '6位數', '000001-999999')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.6 布林值選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('system_settings', 'boolean', NULL, 'true', 'true', '開啟', '啟用此功能'),
('system_settings', 'boolean', NULL, 'false', 'false', '關閉', '停用此功能')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.7 審核層級選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('system_settings', 'approvalLevel', NULL, '1', '1', '單層審核', '只需一層審核'),
('system_settings', 'approvalLevel', NULL, '2', '2', '雙層審核', '需要兩層審核'),
('system_settings', 'approvalLevel', NULL, '3', '3', '三層審核', '需要三層審核')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.8 匯出格式選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('excel_export', 'exportFormat', NULL, 'CSV', 'CSV', 'CSV', '逗號分隔值檔案'),
('excel_export', 'exportFormat', NULL, 'XLSX', 'XLSX', 'Excel', 'Excel檔案格式'),
('excel_export', 'exportFormat', NULL, 'PDF', 'PDF', 'PDF', 'PDF檔案格式')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.9 幣別選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('material_application', 'currency', NULL, 'TWD', 'TWD', 'TWD', '新台幣'),
('material_application', 'currency', NULL, 'USD', 'USD', 'USD', '美元'),
('material_application', 'currency', NULL, 'CNY', 'CNY', 'CNY', '人民幣'),
('material_application', 'currency', NULL, 'EUR', 'EUR', 'EUR', '歐元'),
('material_application', 'currency', NULL, 'JPY', 'JPY', 'JPY', '日圓')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.10 檔案類型選項
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('attachment_management', 'fileType', NULL, 'image', 'image', '圖片', '圖片檔案'),
('attachment_management', 'fileType', NULL, 'document', 'document', '文件', '文件檔案'),
('attachment_management', 'fileType', NULL, 'drawing', 'drawing', '圖面', '工程圖面'),
('attachment_management', 'fileType', NULL, 'other', 'other', '其他', '其他類型檔案')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.11 基本材質選項（保留在 system_options，未來可考慮獨立）
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('material_application', 'material', NULL, 'Steel', 'Steel', 'Steel', '鋼材'),
('material_application', 'material', NULL, 'Stainless Steel', 'Stainless Steel', 'Stainless Steel', '不鏽鋼'),
('material_application', 'material', NULL, 'Brass', 'Brass', 'Brass', '黃銅'),
('material_application', 'material', NULL, 'Zinc Alloy (Zamak)', 'Zinc Alloy (Zamak)', 'Zinc Alloy (Zamak)', '鋅合金'),
('material_application', 'material', NULL, 'Aluminum', 'Aluminum', 'Aluminum', '鋁'),
('material_application', 'material', NULL, 'Plastic', 'Plastic', 'Plastic', '塑膠'),
('material_application', 'material', NULL, 'Wood', 'Wood', 'Wood', '木材'),
('material_application', 'material', NULL, 'Others', 'Others', 'Others', '其他')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.12 表面處理選項（保留在 system_options，未來可考慮獨立）
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('material_application', 'surfaceFinish', NULL, 'Chrome Plated', 'Chrome Plated', 'Chrome Plated', '鍍鉻'),
('material_application', 'surfaceFinish', NULL, 'Nickel Plated', 'Nickel Plated', 'Nickel Plated', '鍍鎳'),
('material_application', 'surfaceFinish', NULL, 'Zinc Plated', 'Zinc Plated', 'Zinc Plated', '鍍鋅'),
('material_application', 'surfaceFinish', NULL, 'Powder Coating', 'Powder Coating', 'Powder Coating', '粉體塗裝'),
('material_application', 'surfaceFinish', NULL, 'Anodized', 'Anodized', 'Anodized', '陽極處理'),
('material_application', 'surfaceFinish', NULL, 'Natural', 'Natural', 'Natural', '原色/自然')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- 6.13 單位選項（保留在 system_options，未來可考慮獨立）
INSERT INTO system_options (module, cate, parent_key, key, value, label, "desc") VALUES
('material_application', 'unit', NULL, 'PCS', 'PCS', 'PCS', '個/件 (Pieces)'),
('material_application', 'unit', NULL, 'SET', 'SET', 'SET', '組/套 (Set)'),
('material_application', 'unit', NULL, 'PAIR', 'PAIR', 'PAIR', '對/雙 (Pair)'),
('material_application', 'unit', NULL, 'KG', 'KG', 'KG', '公斤 (Kilogram)'),
('material_application', 'unit', NULL, 'G', 'G', 'G', '公克 (Gram)'),
('material_application', 'unit', NULL, 'M', 'M', 'M', '公尺 (Meter)'),
('material_application', 'unit', NULL, 'CM', 'CM', 'CM', '公分 (Centimeter)'),
('material_application', 'unit', NULL, 'MM', 'MM', 'MM', '公釐 (Millimeter)'),
('material_application', 'unit', NULL, 'M²', 'M²', 'M²', '平方公尺 (Square Meter)'),
('material_application', 'unit', NULL, 'M³', 'M³', 'M³', '立方公尺 (Cubic Meter)'),
('material_application', 'unit', NULL, 'L', 'L', 'L', '公升 (Liter)'),
('material_application', 'unit', NULL, 'ML', 'ML', 'ML', '毫升 (Milliliter)')
ON CONFLICT (module, cate, COALESCE(parent_key, ''), key) DO NOTHING;

-- ============================================================================
-- 查詢範例
-- ============================================================================

-- 查詢產品分類（大類）
-- SELECT * FROM product_categories WHERE level = 1 ORDER BY display_order;

-- 查詢特定大類下的中類
-- SELECT * FROM product_categories WHERE parent_id = (SELECT id FROM product_categories WHERE code = 'H') ORDER BY display_order;

-- 查詢特定大類下的所有小類
-- SELECT * FROM product_categories WHERE main_category_code = 'H' AND level = 3 ORDER BY display_order;

-- 查詢供應商
-- SELECT * FROM suppliers WHERE is_active = TRUE ORDER BY code;

-- 查詢包裝類別
-- SELECT * FROM packaging_categories ORDER BY display_order;

-- 查詢特定類別下的包裝選項
-- SELECT * FROM packaging_options WHERE category_id = (SELECT id FROM packaging_categories WHERE code = 'productPackaging') ORDER BY display_order;

-- 查詢特定大類的預設包裝選項
-- SELECT 
--   cpd.main_category_code,
--   pc.name_cn AS category_name,
--   po.name AS option_name
-- FROM category_packaging_defaults cpd
-- JOIN packaging_categories pc ON cpd.packaging_category_id = pc.id
-- JOIN packaging_options po ON cpd.packaging_option_id = po.id
-- WHERE cpd.main_category_code = 'H'
-- ORDER BY pc.display_order, cpd.display_order;

-- 查詢系統設定選項
-- SELECT * FROM system_options WHERE module = 'system_settings';

-- ============================================================================
-- 表單記錄相關資料表
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

CREATE INDEX idx_user_profiles_username ON user_profiles(username);
CREATE INDEX idx_user_profiles_role ON user_profiles(role);
CREATE INDEX idx_user_profiles_is_active ON user_profiles(is_active);

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 建立函數：當 auth.users 建立新使用者時，自動建立 user_profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'applicant')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 建立觸發器：當 auth.users 有新使用者時自動建立 profile
-- 先刪除已存在的觸發器（如果有的話）
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 2. 申請資料表 (applications) - 主表
-- ============================================================================
CREATE TABLE IF NOT EXISTS applications (
  id BIGSERIAL PRIMARY KEY,
  item_code VARCHAR(100) NOT NULL UNIQUE, -- 料號（系統自動產生）
  
  -- 分類資訊（外鍵關聯）
  main_category_id BIGINT REFERENCES product_categories(id),
  sub_category_id BIGINT REFERENCES product_categories(id),
  spec_category_id BIGINT REFERENCES product_categories(id),
  
  -- 物料基本資訊
  item_name_cn VARCHAR(500) NOT NULL,
  item_name_en VARCHAR(500) NOT NULL,
  material VARCHAR(255),
  surface_finish VARCHAR(255),
  
  -- 尺寸規格（JSON格式儲存）
  dimensions JSONB, -- {length, width, height, weight}
  
  -- 訂購資訊
  moq INTEGER, -- 最小訂購量
  unit VARCHAR(20),
  
  -- 客戶資訊
  customer_ref VARCHAR(255), -- 客戶參考貨號
  
  -- 供應商資訊（外鍵關聯）
  supplier_id BIGINT REFERENCES suppliers(id),
  
  -- 備註與說明
  notes TEXT,
  internal_notes TEXT, -- 內部備註（僅審核人員可見）
  
  -- 申請流程資訊
  submit_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(50) NOT NULL DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
  applicant_id UUID NOT NULL REFERENCES user_profiles(id),
  priority VARCHAR(20) DEFAULT 'MEDIUM', -- HIGH, MEDIUM, LOW
  
  -- 審核資訊
  approval_level INTEGER DEFAULT 1,
  approval_status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, IN_REVIEW, APPROVED, REJECTED
  approval_date TIMESTAMP WITH TIME ZONE,
  reject_date TIMESTAMP WITH TIME ZONE,
  reject_reason TEXT,
  approver_id UUID REFERENCES user_profiles(id),
  next_approver_id UUID REFERENCES user_profiles(id),
  
  -- 成本資訊
  unit_price DECIMAL(15, 2),
  cost DECIMAL(15, 2),
  currency VARCHAR(10) DEFAULT 'TWD',
  
  -- 庫存資訊
  safety_stock INTEGER,
  reorder_point INTEGER,
  storage_location VARCHAR(255),
  
  -- 其他資訊
  tags TEXT[], -- 標籤陣列
  project_code VARCHAR(100),
  barcode VARCHAR(255),
  qr_code VARCHAR(255),
  estimated_delivery_date DATE,
  lead_time INTEGER, -- 交期（天數）
  
  -- 版本控制
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by_id UUID REFERENCES user_profiles(id)
);

COMMENT ON TABLE applications IS '申請資料表：物料申請記錄主表';
COMMENT ON COLUMN applications.dimensions IS '尺寸規格：JSON格式 {length, width, height, weight}';
COMMENT ON COLUMN applications.status IS '狀態：PENDING=待審核, APPROVED=已核准, REJECTED=已退回';
COMMENT ON COLUMN applications.approval_status IS '審核狀態：PENDING=待審核, IN_REVIEW=審核中, APPROVED=已核准, REJECTED=已退回';

CREATE INDEX idx_applications_item_code ON applications(item_code);
CREATE INDEX idx_applications_main_category_id ON applications(main_category_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_applications_applicant_id ON applications(applicant_id);
CREATE INDEX idx_applications_submit_date ON applications(submit_date);
CREATE INDEX idx_applications_approver_id ON applications(approver_id);
CREATE INDEX idx_applications_supplier_id ON applications(supplier_id);
CREATE INDEX idx_applications_customer_ref ON applications(customer_ref);
CREATE INDEX idx_applications_created_at ON applications(created_at);

CREATE TRIGGER update_applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. 申請包裝資料表 (application_packaging)
-- ============================================================================
-- 用於儲存申請的包裝選項和說明
CREATE TABLE IF NOT EXISTS application_packaging (
  id BIGSERIAL PRIMARY KEY,
  application_id BIGINT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  packaging_category_id BIGINT NOT NULL REFERENCES packaging_categories(id),
  packaging_option_id BIGINT NOT NULL REFERENCES packaging_options(id),
  description TEXT, -- 該選項的額外說明
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE application_packaging IS '申請包裝資料表：儲存申請的包裝選項和說明';

CREATE INDEX idx_application_packaging_application_id ON application_packaging(application_id);
CREATE INDEX idx_application_packaging_category_id ON application_packaging(packaging_category_id);
CREATE INDEX idx_application_packaging_option_id ON application_packaging(packaging_option_id);

-- ============================================================================
-- 4. 附件表 (attachments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS attachments (
  id BIGSERIAL PRIMARY KEY,
  application_id BIGINT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
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

CREATE INDEX idx_attachments_application_id ON attachments(application_id);
CREATE INDEX idx_attachments_uploaded_by_id ON attachments(uploaded_by_id);
CREATE INDEX idx_attachments_file_type ON attachments(file_type);

-- ============================================================================
-- 5. 審核記錄表 (approval_logs)
-- ============================================================================
CREATE TABLE IF NOT EXISTS approval_logs (
  id BIGSERIAL PRIMARY KEY,
  application_id BIGINT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  action VARCHAR(50) NOT NULL, -- SUBMIT, APPROVE, REJECT, RETURN
  approver_id UUID NOT NULL REFERENCES user_profiles(id),
  approver_name VARCHAR(255),
  approver_role VARCHAR(50),
  level INTEGER, -- 審核層級
  reason TEXT,
  comment TEXT, -- 審核意見
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ip_address VARCHAR(50),
  user_agent TEXT
);

COMMENT ON TABLE approval_logs IS '審核記錄表：記錄所有審核動作';
COMMENT ON COLUMN approval_logs.action IS '動作：SUBMIT=提交, APPROVE=核准, REJECT=退回, RETURN=退回修改';

CREATE INDEX idx_approval_logs_application_id ON approval_logs(application_id);
CREATE INDEX idx_approval_logs_approver_id ON approval_logs(approver_id);
CREATE INDEX idx_approval_logs_action ON approval_logs(action);
CREATE INDEX idx_approval_logs_timestamp ON approval_logs(timestamp);

-- ============================================================================
-- 6. 編碼計數器表 (code_counters)
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

CREATE INDEX idx_code_counters_key ON code_counters(key);

CREATE TRIGGER update_code_counters_updated_at
  BEFORE UPDATE ON code_counters
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. 匯出記錄表 (export_logs)
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

CREATE INDEX idx_export_logs_exported_by_id ON export_logs(exported_by_id);
CREATE INDEX idx_export_logs_exported_at ON export_logs(exported_at);
CREATE INDEX idx_export_logs_status ON export_logs(status);

-- ============================================================================
-- 8. 草稿表 (drafts)
-- ============================================================================
CREATE TABLE IF NOT EXISTS drafts (
  id BIGSERIAL PRIMARY KEY,
  application_data JSONB NOT NULL, -- 申請資料（JSON格式）
  saved_by_id UUID NOT NULL REFERENCES user_profiles(id),
  saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE drafts IS '草稿表：儲存未提交的申請草稿';

CREATE INDEX idx_drafts_saved_by_id ON drafts(saved_by_id);
CREATE INDEX idx_drafts_saved_at ON drafts(saved_at);

CREATE TRIGGER update_drafts_last_modified_at
  BEFORE UPDATE ON drafts
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

CREATE INDEX idx_system_settings_key ON system_settings(setting_key);

CREATE TRIGGER update_system_settings_updated_at
  BEFORE UPDATE ON system_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 插入預設系統設定
-- ============================================================================
INSERT INTO system_settings (setting_key, setting_value, setting_type, description) VALUES
('serialDigits', '5', 'number', '流水號位數'),
('serialStart', '1', 'string', '流水號起始值'),
('autoApprove', 'false', 'boolean', '自動審核'),
('emailNotify', 'true', 'boolean', 'Email通知'),
('approvalLevel', '1', 'number', '審核層級')
ON CONFLICT (setting_key) DO NOTHING;

-- ============================================================================
-- 查詢範例
-- ============================================================================

-- 查詢申請記錄（含關聯資料）
-- SELECT 
--   a.*,
--   up1.username AS applicant_name,
--   au1.email AS applicant_email,
--   up2.username AS approver_name,
--   au2.email AS approver_email,
--   s.name AS supplier_name,
--   pc1.name_cn AS main_category_name,
--   pc2.name_cn AS sub_category_name,
--   pc3.name_cn AS spec_category_name
-- FROM applications a
-- LEFT JOIN user_profiles up1 ON a.applicant_id = up1.id
-- LEFT JOIN auth.users au1 ON up1.id = au1.id
-- LEFT JOIN user_profiles up2 ON a.approver_id = up2.id
-- LEFT JOIN auth.users au2 ON up2.id = au2.id
-- LEFT JOIN suppliers s ON a.supplier_id = s.id
-- LEFT JOIN product_categories pc1 ON a.main_category_id = pc1.id
-- LEFT JOIN product_categories pc2 ON a.sub_category_id = pc2.id
-- LEFT JOIN product_categories pc3 ON a.spec_category_id = pc3.id
-- WHERE a.status = 'PENDING'
-- ORDER BY a.submit_date DESC;

-- 查詢申請的包裝選項
-- SELECT 
--   ap.*,
--   pc.name_cn AS category_name,
--   po.name AS option_name
-- FROM application_packaging ap
-- JOIN packaging_categories pc ON ap.packaging_category_id = pc.id
-- JOIN packaging_options po ON ap.packaging_option_id = po.id
-- WHERE ap.application_id = 1
-- ORDER BY pc.display_order, ap.display_order;

-- 查詢申請的審核記錄
-- SELECT 
--   al.*,
--   up.username AS approver_username,
--   au.email AS approver_email
-- FROM approval_logs al
-- JOIN user_profiles up ON al.approver_id = up.id
-- JOIN auth.users au ON up.id = au.id
-- WHERE al.application_id = 1
-- ORDER BY al.timestamp DESC;
