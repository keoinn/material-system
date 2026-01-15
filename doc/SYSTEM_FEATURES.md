# 系統功能與特點清單

## 📋 快速索引

本文檔提供系統功能與特點的快速參考，詳細說明請參考 `REFACTORING_PLAN.md`。

---

## 核心功能模組

### 1. 動態表單系統 ⭐⭐⭐
- **優先級**：最高
- **功能**：允許系統管理員透過資料庫定義表單結構
- **核心組件**：
  - FormDesigner.vue - 表單設計器
  - DynamicFormRenderer.vue - 表單渲染器
  - form-fields/ - 欄位組件庫（12 種欄位類型）
- **資料表**：forms, form_fields, form_data_values
- **特色**：欄位群組、動態選項、自動產生、驗證規則

### 2. 使用者管理模組 ⭐⭐⭐
- **優先級**：最高
- **功能**：使用者帳號、角色、權限管理
- **核心組件**：
  - pages/users.vue - 使用者管理頁面
  - stores/auth.js - 認證 Store
  - composables/usePermissions.js - 權限檢查
- **資料表**：auth.users, user_profiles
- **角色**：admin, approver, applicant
- **特色**：註冊審核、角色權限、登入記錄

### 3. 部門管理模組 ⭐⭐
- **優先級**：高
- **功能**：組織架構管理
- **現況**：簡化版本（department 欄位）
- **建議擴展**：獨立部門表、階層結構、部門主管
- **資料表**：departments（需建立）

### 4. 審核流程模組 ⭐⭐⭐
- **優先級**：最高
- **功能**：多層級審核流程管理
- **核心組件**：
  - ReviewManagement.vue - 審核管理組件
  - approval_logs 表 - 審核記錄
- **審核狀態**：PENDING, IN_REVIEW, APPROVED, REJECTED, RETURN
- **特色**：多層級審核、審核意見、審計追蹤

### 5. 編輯紀錄模組 ⭐⭐
- **優先級**：高
- **功能**：追蹤資料變更歷史
- **現況**：透過 approval_logs 和 updated_at
- **建議擴展**：獨立的 audit_logs 表
- **記錄內容**：變更時間、人員、欄位、前後值、IP

### 6. 物料申請管理 ⭐⭐⭐
- **優先級**：最高
- **功能**：物料編碼申請與管理
- **核心組件**：
  - MaterialApplicationForm.vue - 申請表單
  - ApplicationQuery.vue - 申請查詢
- **資料表**：applications, product_categories, code_counters
- **分類架構**：三層階層（大類/中類/小類）
- **特色**：自動產生料號、三層分類、規格管理

### 7. 包裝管理模組 ⭐⭐
- **優先級**：中
- **功能**：產品包裝說明管理
- **核心組件**：
  - PackagingSection.vue - 包裝區塊
  - PackagingTemplateSettings.vue - 包裝模板設定
- **資料表**：packaging_categories, packaging_options, category_packaging_defaults
- **8大類別**：個別產品包裝、配件內容、配件、內盒、外箱、運輸、裝櫃、其他
- **特色**：智能預設值、類別預設值設定

### 8. 附件管理模組 ⭐⭐
- **優先級**：中
- **功能**：檔案上傳與管理
- **核心組件**：
  - form-fields/FileField.vue - 檔案上傳欄位
- **資料表**：attachments
- **特色**：支援 Supabase Storage 和傳統上傳

### 9. Excel 匯出模組 ⭐⭐
- **優先級**：中
- **功能**：多條件篩選與 Excel 匯出
- **核心組件**：
  - ExcelExport.vue - Excel 匯出組件
- **資料表**：export_logs
- **特色**：多條件篩選、匯出記錄、下載統計

### 10. 系統設定模組 ⭐
- **優先級**：低
- **功能**：系統參數管理
- **核心組件**：
  - SystemSettings.vue - 系統設定頁面
- **資料表**：system_settings, system_options
- **特色**：編碼規則、審核流程設定

### 11. 供應商管理模組 ⭐
- **優先級**：低
- **功能**：供應商資料管理
- **資料表**：suppliers
- **特色**：CRUD、啟用/停用

### 12. 草稿功能 ⭐
- **優先級**：低
- **功能**：未提交申請的草稿儲存
- **資料表**：drafts
- **特色**：自動儲存、草稿列表

---

## 技術架構特點

### 前端技術棧
- ✅ Vue 3 (Composition API)
- ✅ Vuetify 3
- ✅ Pinia (狀態管理)
- ✅ Vue Router (auto-route)
- ✅ SCSS
- ✅ Plain JavaScript (ES6+)

### 後端架構
- ✅ **雙後端支援**：Supabase 和 SQL Server + Axios
- ✅ **統一 API 介面**：業務邏輯層無需關心後端實作
- ✅ **環境變數切換**：VITE_API_BACKEND

### API 層架構
```
services/
├── [service].js          # 統一介面層
├── axios/[service].js    # Axios 實作
└── supabase/[service].js # Supabase 實作
```

---

## 資料庫架構

### 核心資料表

#### 系統參數與選項
- `product_categories` - 產品分類（三層階層）
- `suppliers` - 供應商
- `packaging_categories` - 包裝類別
- `packaging_options` - 包裝選項
- `category_packaging_defaults` - 類別預設包裝
- `system_options` - 系統參數

#### 使用者與認證
- `auth.users` (Supabase) - 認證資訊
- `user_profiles` - 使用者資料

#### 申請與審核
- `applications` - 申請主表
- `approval_logs` - 審核記錄
- `code_counters` - 編碼計數器

#### 動態表單
- `forms` - 表單定義
- `form_fields` - 欄位定義
- `form_data_values` - 表單資料值

#### 其他
- `attachments` - 附件
- `export_logs` - 匯出記錄
- `drafts` - 草稿

---

## 功能優先級矩陣

| 功能模組 | 優先級 | 複雜度 | 依賴關係 |
|---------|--------|--------|----------|
| 動態表單系統 | ⭐⭐⭐ | 高 | 無 |
| 使用者管理 | ⭐⭐⭐ | 中 | 無 |
| 認證系統 | ⭐⭐⭐ | 中 | 使用者管理 |
| 審核流程 | ⭐⭐⭐ | 高 | 使用者管理、動態表單 |
| 物料申請 | ⭐⭐⭐ | 高 | 動態表單、產品分類 |
| 編輯紀錄 | ⭐⭐ | 中 | 審核流程 |
| 部門管理 | ⭐⭐ | 中 | 使用者管理 |
| 包裝管理 | ⭐⭐ | 中 | 產品分類 |
| 附件管理 | ⭐⭐ | 低 | 無 |
| Excel 匯出 | ⭐⭐ | 中 | 物料申請 |
| 系統設定 | ⭐ | 低 | 無 |
| 供應商管理 | ⭐ | 低 | 無 |
| 草稿功能 | ⭐ | 低 | 物料申請 |

---

## 開發建議

### 階段一：基礎架構（必須）
1. 專案初始化
2. API 層基礎架構
3. 認證與使用者管理
4. 動態表單系統

### 階段二：核心功能（必須）
1. 審核流程模組
2. 物料申請管理
3. 編輯紀錄模組

### 階段三：擴展功能（重要）
1. 部門管理模組
2. 包裝管理模組
3. Excel 匯出模組

### 階段四：輔助功能（可選）
1. 附件管理
2. 系統設定
3. 供應商管理
4. 草稿功能

---

## 參考檔案位置

### Legacy 檔案
- `public/prototype/` - Legacy HTML/JavaScript 版本

### 現有實作參考
- `src/components/` - 組件實作
- `src/pages/` - 頁面實作
- `src/stores/` - Store 實作
- `src/api/services/` - API 實作
- `src/database/supabase/` - 資料庫結構

### 文件
- `doc/REFACTORING_PLAN.md` - 完整重構計劃
- `doc/SYSTEM_FEATURES.md` - 本文件（功能清單）

---

## 快速查詢

### 我需要實作...
- **表單系統** → 參考 `REFACTORING_PLAN.md` Step 2.3
- **使用者管理** → 參考 `REFACTORING_PLAN.md` Step 2.1
- **審核流程** → 參考 `REFACTORING_PLAN.md` Step 2.4
- **API 架構** → 參考 `REFACTORING_PLAN.md` Step 1.2
- **資料庫結構** → 參考 `src/database/supabase/supabase_schema.sql`

---

**最後更新**：2024
**版本**：V3.6 → 重構計劃
