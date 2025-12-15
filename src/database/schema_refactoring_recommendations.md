# 資料表重構建議

## 分析結果

根據 `supabase_schema.sql` 的分析，以下選項建議獨立成新的資料表，以提升維護性和擴展性：

---

## 🔴 高優先級：建議獨立成資料表

### 1. **產品分類系統** (`product_categories`)
**原因：**
- 有明確的三層階層結構（大類 → 中類 → 小類）
- 資料量大（約 60+ 筆記錄）
- 層級關係明確，適合用關聯式資料表
- 未來可能需要擴展屬性（如圖示、排序順序等）

**建議結構：**
```sql
CREATE TABLE product_categories (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(10) NOT NULL UNIQUE,  -- 分類代碼 (H, S, M, 01, 02, A, B, C)
  name VARCHAR(255) NOT NULL,        -- 分類名稱
  name_cn VARCHAR(255),               -- 中文名稱
  level INTEGER NOT NULL,             -- 層級 (1=大類, 2=中類, 3=小類)
  parent_id BIGINT REFERENCES product_categories(id), -- 父層分類
  main_category_code VARCHAR(1),      -- 大類代碼 (H, S, M, D, F, B, I, O)
  display_order INTEGER DEFAULT 0,     -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE,     -- 是否啟用
  description TEXT,                   -- 說明
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**優點：**
- 清晰的階層關係
- 易於查詢和維護
- 支援遞迴查詢（如查詢某大類下的所有子分類）
- 可擴展屬性

---

### 2. **供應商** (`suppliers`)
**原因：**
- 目前只有代碼和名稱，但 `schema.js` 中已定義完整的供應商結構
- 未來需要擴展為完整的供應商管理系統（聯絡人、地址、電話等）
- 與申請資料有外鍵關聯需求

**建議結構：**
```sql
CREATE TABLE suppliers (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,   -- 供應商代碼 (SUP001, SUP002)
  name VARCHAR(255) NOT NULL,         -- 供應商名稱
  contact_person VARCHAR(100),         -- 聯絡人
  email VARCHAR(255),                  -- Email
  phone VARCHAR(50),                   -- 電話
  address TEXT,                        -- 地址
  country VARCHAR(100),                -- 國家
  is_active BOOLEAN DEFAULT TRUE,     -- 是否啟用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**優點：**
- 符合 `schema.js` 中的 `supplierSchema` 定義
- 可擴展為完整的供應商管理
- 與申請資料表可建立外鍵關聯

---

### 3. **包裝選項** (`packaging_options`)
**原因：**
- 資料量大（約 40+ 筆記錄）
- 有明確的分類結構（8個包裝類別）
- 未來可能需要擴展屬性（如成本、圖片等）

**建議結構：**
```sql
CREATE TABLE packaging_categories (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,   -- 類別代碼 (productPackaging, innerBox, etc.)
  name VARCHAR(255) NOT NULL,         -- 類別名稱
  name_cn VARCHAR(255),               -- 中文名稱
  display_order INTEGER DEFAULT 0,     -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE,     -- 是否啟用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE packaging_options (
  id BIGSERIAL PRIMARY KEY,
  category_id BIGINT NOT NULL REFERENCES packaging_categories(id),
  code VARCHAR(100) NOT NULL,          -- 選項代碼
  name VARCHAR(255) NOT NULL,         -- 選項名稱
  description TEXT,                    -- 說明
  display_order INTEGER DEFAULT 0,     -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE,     -- 是否啟用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(category_id, code)
);
```

**優點：**
- 分類清晰
- 易於維護和擴展
- 支援分類管理

---

### 4. **類別預設包裝** (`category_packaging_defaults`)
**原因：**
- 目前以 JSON 格式儲存陣列，不利於查詢和維護
- 需要關聯產品分類和包裝選項

**建議結構：**
```sql
CREATE TABLE category_packaging_defaults (
  id BIGSERIAL PRIMARY KEY,
  main_category_code VARCHAR(1) NOT NULL,  -- 產品大類代碼 (H, S, M)
  packaging_category_id BIGINT NOT NULL REFERENCES packaging_categories(id),
  packaging_option_id BIGINT NOT NULL REFERENCES packaging_options(id),
  display_order INTEGER DEFAULT 0,         -- 顯示順序
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(main_category_code, packaging_category_id, packaging_option_id)
);
```

**優點：**
- 關聯式結構，易於查詢
- 可建立外鍵約束，確保資料完整性
- 易於維護和修改

---

## 🟡 中優先級：可考慮獨立

### 5. **材質與表面處理** (`materials`, `surface_finishes`)
**原因：**
- 屬於產品屬性，資料量中等
- 未來可能需要擴展屬性（如成本、適用材質等）

**建議結構：**
```sql
CREATE TABLE materials (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,   -- 材質代碼
  name VARCHAR(255) NOT NULL,         -- 材質名稱
  name_cn VARCHAR(255),               -- 中文名稱
  description TEXT,                   -- 說明
  display_order INTEGER DEFAULT 0,    -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE,     -- 是否啟用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE surface_finishes (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,   -- 表面處理代碼
  name VARCHAR(255) NOT NULL,         -- 表面處理名稱
  name_cn VARCHAR(255),               -- 中文名稱
  description TEXT,                   -- 說明
  display_order INTEGER DEFAULT 0,    -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE,    -- 是否啟用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

### 6. **單位** (`units`)
**原因：**
- 標準化的單位系統
- 未來可能需要擴展屬性（如換算率、國際標準代碼等）

**建議結構：**
```sql
CREATE TABLE units (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(10) NOT NULL UNIQUE,   -- 單位代碼 (PCS, SET, KG)
  name VARCHAR(255) NOT NULL,         -- 單位名稱
  name_cn VARCHAR(255),               -- 中文名稱
  description TEXT,                   -- 說明
  unit_type VARCHAR(50),              -- 單位類型 (count, weight, length, volume)
  display_order INTEGER DEFAULT 0,     -- 顯示順序
  is_active BOOLEAN DEFAULT TRUE,    -- 是否啟用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 🟢 低優先級：可保留在 system_options

### 7. **系統設定選項**
- `serialDigits` (3個選項)
- `boolean` (2個選項)
- `approvalLevel` (3個選項)
- `exportFormat` (3個選項)
- `currency` (5個選項)
- `fileType` (4個選項)
- `priority` (3個選項)
- `approvalAction` (4個選項)
- `userRole` (3個選項)
- `applicationStatus` (4個選項)

**原因：**
- 資料量小
- 變動頻率低
- 結構簡單，不需要複雜的關聯

**建議：** 保留在 `system_options` 表中

---

## 📊 重構後的資料表架構

### 核心資料表
1. `system_options` - 保留系統設定類的選項
2. `product_categories` - 產品分類系統（三層階層）
3. `suppliers` - 供應商資料
4. `packaging_categories` - 包裝類別
5. `packaging_options` - 包裝選項
6. `category_packaging_defaults` - 類別預設包裝
7. `materials` - 材質選項（可選）
8. `surface_finishes` - 表面處理選項（可選）
9. `units` - 單位選項（可選）

---

## 🔄 遷移建議

### 階段一：高優先級
1. 建立 `product_categories` 表
2. 建立 `suppliers` 表
3. 遷移現有資料
4. 更新應用程式程式碼

### 階段二：包裝系統
1. 建立 `packaging_categories` 和 `packaging_options` 表
2. 建立 `category_packaging_defaults` 表
3. 遷移現有資料
4. 更新應用程式程式碼

### 階段三：可選項目
1. 根據實際需求決定是否獨立 `materials`、`surface_finishes`、`units`
2. 如果資料量增加或需要擴展屬性，再進行獨立

---

## 💡 優點總結

### 獨立資料表的優點：
1. **資料完整性**：可建立外鍵約束，確保資料一致性
2. **查詢效能**：針對性索引，查詢更快
3. **擴展性**：易於新增欄位和屬性
4. **維護性**：結構清晰，易於理解和維護
5. **關聯查詢**：支援 JOIN 查詢，獲取完整資訊

### 保留在 system_options 的優點：
1. **簡單性**：結構簡單，不需要複雜的關聯
2. **靈活性**：可快速新增選項，不需要修改資料表結構
3. **統一管理**：所有選項集中在一個地方

---

## 📝 注意事項

1. **向後相容**：遷移時需要確保應用程式能正常運作
2. **資料遷移**：需要編寫遷移腳本，確保資料正確轉換
3. **API 更新**：需要更新相關的 API 和查詢邏輯
4. **測試**：充分測試遷移後的系統功能

