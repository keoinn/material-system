# 物料編碼申請管理系統 - 重構計劃

## 📋 目錄

1. [系統功能與特點分析](#系統功能與特點分析)
2. [技術架構分析](#技術架構分析)
3. [重構目標](#重構目標)
4. [重構步驟與 Prompt](#重構步驟與-prompt)
5. [參考檔案整理指南](#參考檔案整理指南)

---

## 系統功能與特點分析

### 核心功能模組

#### 1. **動態表單系統**
- **功能描述**：允許系統管理員透過資料庫定義表單結構，無需修改程式碼
- **核心資料表**：
  - `forms` - 表單定義主表
  - `form_fields` - 表單欄位定義表
  - `form_data_values` - 表單資料值表
- **支援欄位類型**：text, textarea, number, select, multiselect, checkbox, radio, date, datetime, file, json
- **特色功能**：
  - 欄位群組管理
  - 動態選項載入（依賴其他欄位）
  - 自動產生欄位（如料號）
  - 欄位驗證規則
  - 欄位顯示/隱藏控制

#### 2. **使用者管理模組**
- **功能描述**：完整的使用者帳號、角色、權限管理
- **核心資料表**：
  - `auth.users` (Supabase) - 認證資訊
  - `user_profiles` - 使用者資料
- **角色系統**：
  - `admin` - 系統管理員（完整權限）
  - `approver` - 審核人員（審核、查詢權限）
  - `applicant` - 申請人員（申請、查詢權限）
- **功能特色**：
  - 使用者註冊與審核啟用機制
  - 角色權限控制
  - 最後登入時間與 IP 記錄
  - 使用者狀態管理（啟用/停用）

#### 3. **部門管理模組**
- **功能描述**：組織架構管理（目前為簡化版本）
- **現況**：部門資訊儲存在 `user_profiles.department` 欄位
- **建議擴展**：
  - 獨立部門資料表
  - 部門階層結構
  - 部門主管設定
  - 部門權限管理

#### 4. **審核流程模組**
- **功能描述**：多層級審核流程管理
- **核心資料表**：
  - `applications` - 申請主表
  - `approval_logs` - 審核記錄表
- **審核狀態**：
  - `PENDING` - 待審核
  - `IN_REVIEW` - 審核中
  - `APPROVED` - 已核准
  - `REJECTED` - 已退回
  - `RETURN` - 退回修改
- **功能特色**：
  - 多層級審核支援
  - 審核意見記錄
  - 審核人資訊追蹤
  - IP 位址與 User Agent 記錄（審計用）

#### 5. **編輯紀錄模組**
- **功能描述**：追蹤資料變更歷史
- **實作方式**：
  - `approval_logs` 表記錄審核相關變更
  - `updated_at` 欄位記錄最後更新時間
  - 建議擴展：獨立的 `audit_logs` 表記錄所有資料變更
- **記錄內容**：
  - 變更時間
  - 變更人員
  - 變更欄位
  - 變更前後值
  - IP 位址與 User Agent

#### 6. **物料申請管理**
- **功能描述**：物料編碼申請與管理
- **核心資料表**：
  - `applications` - 申請主表
  - `product_categories` - 產品分類（三層階層結構）
  - `code_counters` - 編碼計數器
- **分類架構**：
  - 大類（Level 1）：H, S, M, D, F, B, I, O
  - 中類（Level 2）：01, 02, 03...
  - 小類（Level 3）：A, B, C...
- **功能特色**：
  - 自動產生料號（格式：{大類}{中類}.{小類}.{流水號}）
  - 三層分類選擇
  - 物料規格管理
  - 供應商關聯

#### 7. **包裝管理模組**
- **功能描述**：產品包裝說明管理
- **核心資料表**：
  - `packaging_categories` - 包裝類別（8個類別）
  - `packaging_options` - 包裝選項
  - `category_packaging_defaults` - 類別預設包裝
- **8大包裝類別**：
  1. 個別產品包裝
  2. 配件內容
  3. 配件
  4. 內盒
  5. 外箱
  6. 運輸與托盤要求
  7. 裝櫃要求
  8. 其他說明
- **功能特色**：
  - 智能預設值（根據產品類別）
  - 包裝選項管理
  - 類別預設值設定

#### 8. **其他功能模組**
- **附件管理**：檔案上傳與管理（`attachments` 表）
- **Excel 匯出**：多條件篩選與匯出（`export_logs` 表）
- **草稿功能**：未提交申請的草稿儲存（`drafts` 表）
- **供應商管理**：供應商資料管理（`suppliers` 表）
- **系統設定**：系統參數管理（`system_options` 表）

---

## 技術架構分析

### 前端技術棧

- **框架**：Vue 3 (Composition API)
- **UI 框架**：Vuetify 3
- **狀態管理**：Pinia
- **路由**：Vue Router (auto-route)
- **樣式**：SCSS
- **語言**：Plain JavaScript (ES6+)

### 後端架構

#### 雙後端支援架構

系統支援兩種後端串接方式：

1. **Supabase 後端**
   - 使用 Supabase Client 直接操作資料庫
   - 使用 Supabase Auth 進行身份驗證
   - 使用 Supabase Storage 處理檔案上傳
   - 環境變數：`VITE_API_BACKEND=supabase`

2. **SQL Server + Axios 後端**
   - 使用 Axios 呼叫 REST API
   - 傳統 RESTful API 架構
   - 環境變數：`VITE_API_BACKEND=axios`

#### API 層架構

```
src/api/
├── client.js              # Axios 客戶端配置
├── supabase.js           # Supabase 客戶端配置
├── index.js              # 統一匯出
└── services/             # API 服務層
    ├── index.js          # 服務統一匯出
    ├── [service].js      # 統一介面層（自動選擇後端）
    ├── axios/            # Axios 實作層
    │   └── [service].js
    └── supabase/         # Supabase 實作層
        └── [service].js
```

**設計模式**：
- 統一介面層根據環境變數自動選擇後端實作
- 業務邏輯層無需關心後端實作細節
- 所有服務函數提供一致的 API 介面

### 資料庫架構

#### Supabase 資料表結構

1. **系統參數與選項**
   - `product_categories` - 產品分類
   - `suppliers` - 供應商
   - `packaging_categories` - 包裝類別
   - `packaging_options` - 包裝選項
   - `category_packaging_defaults` - 類別預設包裝
   - `system_options` - 系統參數

2. **使用者與認證**
   - `auth.users` (Supabase 內建)
   - `user_profiles` - 使用者資料

3. **申請與審核**
   - `applications` - 申請主表
   - `approval_logs` - 審核記錄
   - `code_counters` - 編碼計數器

4. **動態表單**
   - `forms` - 表單定義
   - `form_fields` - 欄位定義
   - `form_data_values` - 表單資料值

5. **其他**
   - `attachments` - 附件
   - `export_logs` - 匯出記錄
   - `drafts` - 草稿

---

## 重構目標

### 主要目標

1. **從零開始重構**：基於現有系統分析，建立全新的、結構清晰的專案
2. **保持功能完整性**：確保所有現有功能在新系統中都能正常運作
3. **改善程式碼品質**：提升可維護性、可擴展性、可測試性
4. **優化架構設計**：採用最佳實踐，建立清晰的模組化架構
5. **支援雙後端**：完整支援 Supabase 和 SQL Server + Axios 兩種後端

### 重構原則

1. **模組化設計**：每個功能模組獨立，低耦合高內聚
2. **統一介面**：API 層提供統一介面，隱藏後端實作細節
3. **型別安全**：雖然使用 JavaScript，但透過 JSDoc 提供型別提示
4. **錯誤處理**：統一的錯誤處理機制
5. **文件完整**：每個模組都有完整的文件說明

---

## 重構步驟與 Prompt

### 階段一：專案初始化與基礎架構

#### Step 1.1: 建立新專案基礎架構

**Prompt:**

```
請幫我建立一個新的 Vue3 + Vuetify3 + Pinia 專案，使用以下技術棧：

技術要求：
- Vue 3 (Composition API)
- Vuetify 3
- Pinia (狀態管理)
- Vue Router (使用 auto-route)
- SCSS (樣式預處理器)
- Plain JavaScript (不使用 TypeScript)
- Vite (建置工具)

專案結構要求：
- 使用 unplugin-vue-router 實現自動路由
- 使用 unplugin-auto-import 實現自動匯入
- 使用 unplugin-vue-components 實現自動組件註冊
- 支援 Vuetify 自動匯入

請建立基本的專案結構，包含：
1. package.json 與依賴套件
2. vite.config.mjs 配置檔
3. 基本的目錄結構（src/components, src/pages, src/stores, src/api 等）
4. 基本的 Vuetify 配置
5. 基本的路由配置
6. 基本的 Pinia store 配置
7. 基本的 SCSS 變數檔案

參考檔案位置：@public/prototype/ 資料夾中的 legacy 檔案
```

#### Step 1.2: 建立 API 層基礎架構

**Prompt:**

```
請建立支援雙後端的 API 層架構，需要：

1. 環境變數配置
   - VITE_API_BACKEND: 'supabase' | 'axios'
   - Supabase 相關環境變數
   - Axios 相關環境變數

2. API 客戶端配置
   - src/api/client.js: Axios 客戶端配置（包含攔截器）
   - src/api/supabase.js: Supabase 客戶端配置

3. API 服務層架構
   - src/api/services/index.js: 服務統一匯出
   - src/api/services/[service].js: 統一介面層（根據環境變數選擇後端）
   - src/api/services/axios/[service].js: Axios 實作
   - src/api/services/supabase/[service].js: Supabase 實作

4. 錯誤處理機制
   - 統一的錯誤格式
   - 錯誤攔截器
   - 錯誤訊息處理

參考現有專案的 API 層結構：src/api/
```

### 階段二：核心功能模組開發

#### Step 2.1: 認證與使用者管理模組

**Prompt:**

```
請實作認證與使用者管理模組，包含：

1. 認證 Store (src/stores/auth.js)
   - 登入/登出功能
   - 認證狀態檢查
   - Session 管理
   - 支援 Supabase Auth 和傳統 JWT

2. 使用者管理 API
   - src/api/services/auth.js: 認證相關 API
   - src/api/services/users.js: 使用者管理 API
   - 支援 Supabase 和 Axios 兩種實作

3. 使用者管理頁面
   - src/pages/users.vue: 使用者列表與管理
   - 功能：新增、編輯、刪除、啟用/停用使用者
   - 角色管理（admin, approver, applicant）
   - 部門欄位管理

4. 登入/註冊頁面
   - src/pages/login.vue: 登入頁面
   - src/pages/register.vue: 註冊頁面（需管理員審核啟用）

5. 權限管理
   - src/composables/usePermissions.js: 權限檢查工具
   - 路由守衛：根據權限控制頁面存取

參考檔案：
- 現有實作：src/stores/auth.js, src/pages/users.vue
- 資料庫結構：src/database/supabase/supabase_schema.sql (user_profiles 表)
```

#### Step 2.2: 部門管理模組

**Prompt:**

```
請實作部門管理模組，包含：

1. 部門資料表設計（SQL）
   - departments 表：部門基本資訊
   - 支援階層結構（parent_id）
   - 部門主管關聯（manager_id -> user_profiles.id）

2. 部門管理 API
   - src/api/services/departments.js: 部門管理 API
   - 功能：CRUD、階層查詢、部門成員查詢

3. 部門管理頁面
   - src/pages/departments.vue: 部門列表與管理
   - 功能：新增、編輯、刪除部門
   - 階層結構顯示（樹狀結構）
   - 部門成員管理

4. 使用者與部門關聯
   - 更新 user_profiles 表，將 department 改為外鍵關聯
   - 或保持現有設計，但提供部門查詢功能

參考檔案：
- 現有實作：src/pages/users.vue (department 欄位)
- 資料庫結構：src/database/supabase/supabase_schema.sql
```

#### Step 2.3: 動態表單系統

**Prompt:**

```
請實作動態表單系統，包含：

1. 表單設計器組件
   - src/components/FormDesigner.vue: 表單設計器
   - 功能：建立/編輯表單、欄位管理、欄位設定、預覽

2. 表單渲染器組件
   - src/components/DynamicFormRenderer.vue: 動態表單渲染器
   - 根據表單定義動態渲染表單欄位

3. 表單欄位組件庫
   - src/components/form-fields/: 各種欄位類型組件
   - TextField, TextareaField, NumberField, SelectField, 
     MultiselectField, CheckboxField, RadioField, DateField, 
     DatetimeField, FileField, JsonField

4. 表單管理 API
   - src/api/services/forms.js: 表單定義 API
   - src/api/services/formFields.js: 欄位定義 API
   - src/api/services/formData.js: 表單資料 API

5. 表單管理頁面
   - src/pages/forms.vue: 表單列表與管理

6. 資料庫結構
   - forms, form_fields, form_data_values 表的 SQL 腳本

參考檔案：
- 現有實作：src/components/FormDesigner.vue, src/components/DynamicFormRenderer.vue
- 資料庫結構：src/database/supabase/dynamic_forms_schema.sql
- 文件：src/database/supabase/DYNAMIC_FORMS_README.md
```

#### Step 2.4: 審核流程模組

**Prompt:**

```
請實作審核流程模組，包含：

1. 審核流程設定
   - 多層級審核支援
   - 審核人員指派
   - 審核規則設定

2. 審核管理 API
   - src/api/services/applications.js: 申請管理 API
   - 功能：提交申請、核准、退回、查詢待審核列表

3. 審核記錄 API
   - src/api/services/approvalLogs.js: 審核記錄 API
   - 記錄所有審核動作（SUBMIT, APPROVE, REJECT, RETURN）

4. 審核管理頁面
   - src/components/ReviewManagement.vue: 待審核申請列表
   - 功能：查看待審核申請、核准、退回、查看詳情

5. 審核記錄顯示
   - 顯示完整的審核歷史
   - 包含審核人、時間、意見、IP 等資訊

6. 資料庫結構
   - approval_logs 表的 SQL 腳本

參考檔案：
- 現有實作：src/components/ReviewManagement.vue
- 資料庫結構：src/database/supabase/supabase_schema.sql (approval_logs 表)
- API 實作：src/api/services/supabase/applications.js
```

#### Step 2.5: 編輯紀錄模組

**Prompt:**

```
請實作編輯紀錄（Audit Log）模組，包含：

1. 審計日誌資料表設計（SQL）
   - audit_logs 表：記錄所有資料變更
   - 欄位：table_name, record_id, field_name, old_value, 
          new_value, changed_by_id, changed_at, ip_address, user_agent

2. 審計日誌 API
   - src/api/services/auditLogs.js: 審計日誌查詢 API
   - 功能：查詢變更記錄、依條件篩選

3. 審計日誌顯示組件
   - src/components/AuditLogViewer.vue: 顯示資料變更歷史
   - 功能：時間軸顯示、變更對比、篩選功能

4. 自動記錄機制
   - 在資料更新時自動記錄變更
   - 可透過資料庫 Trigger 或應用程式層實作

5. 審計日誌查詢頁面
   - src/pages/audit-logs.vue: 審計日誌查詢與管理

參考檔案：
- 現有實作：approval_logs 表的設計
- 資料庫結構：src/database/supabase/supabase_schema.sql
```

### 階段三：業務功能模組開發

#### Step 3.1: 物料申請管理模組

**Prompt:**

```
請實作物料申請管理模組，包含：

1. 產品分類管理
   - src/api/services/categories.js: 分類管理 API
   - 三層階層結構（大類/中類/小類）
   - 分類選擇組件

2. 編碼計數器管理
   - src/api/services/codeCounters.js: 編碼計數器 API
   - 自動產生料號功能

3. 物料申請表單
   - 使用動態表單系統渲染
   - 或使用專用的物料申請組件

4. 申請管理 API
   - src/api/services/applications.js: 申請管理 API
   - 功能：建立、查詢、更新、刪除申請

5. 申請查詢頁面
   - src/components/ApplicationQuery.vue: 申請查詢組件
   - 多條件篩選功能

6. 資料庫結構
   - applications, product_categories, code_counters 表的 SQL 腳本

參考檔案：
- 現有實作：src/components/MaterialApplicationForm.vue
- 資料庫結構：src/database/supabase/supabase_schema.sql
- Legacy 檔案：@public/prototype/material_system_v3.5_complete.html
```

#### Step 3.2: 包裝管理模組

**Prompt:**

```
請實作包裝管理模組，包含：

1. 包裝類別管理 API
   - src/api/services/packaging.js: 包裝管理 API
   - 8大包裝類別管理

2. 包裝選項管理
   - 包裝選項的 CRUD 功能
   - 類別預設值設定

3. 包裝設定頁面
   - src/components/PackagingTemplateSettings.vue: 包裝模板設定
   - 功能：設定各產品類別的預設包裝選項

4. 包裝表單組件
   - src/components/PackagingFormSection.vue: 包裝表單區塊
   - 在申請表單中使用

5. 資料庫結構
   - packaging_categories, packaging_options, 
     category_packaging_defaults 表的 SQL 腳本

參考檔案：
- 現有實作：src/components/PackagingSection.vue, 
            src/components/PackagingTemplateSettings.vue
- 資料庫結構：src/database/supabase/supabase_schema.sql
```

#### Step 3.3: 附件管理模組

**Prompt:**

```
請實作附件管理模組，包含：

1. 附件上傳 API
   - src/api/services/attachments.js: 附件管理 API
   - 支援 Supabase Storage 和傳統檔案上傳

2. 附件上傳組件
   - src/components/form-fields/FileField.vue: 檔案上傳欄位
   - 功能：單檔/多檔上傳、進度顯示、預覽

3. 附件管理功能
   - 附件列表顯示
   - 附件下載
   - 附件刪除

4. 資料庫結構
   - attachments 表的 SQL 腳本

參考檔案：
- 現有實作：src/components/form-fields/FileField.vue
- API 實作：src/api/services/attachments.js
- 資料庫結構：src/database/supabase/supabase_schema.sql
```

#### Step 3.4: Excel 匯出模組

**Prompt:**

```
請實作 Excel 匯出模組，包含：

1. Excel 匯出 API
   - src/api/services/exportLogs.js: 匯出記錄 API
   - 後端處理 Excel 產生（或前端使用 SheetJS）

2. Excel 匯出組件
   - src/components/ExcelExport.vue: Excel 匯出功能
   - 功能：多條件篩選、格式選擇、匯出記錄

3. 匯出記錄查詢
   - 顯示匯出歷史
   - 下載次數統計

4. 資料庫結構
   - export_logs 表的 SQL 腳本

參考檔案：
- 現有實作：src/components/ExcelExport.vue
- API 實作：src/api/services/exportLogs.js
- Legacy 檔案：@public/prototype/excel_processor_v35_optimized.py
```

### 階段四：系統設定與其他功能

#### Step 4.1: 系統設定模組

**Prompt:**

```
請實作系統設定模組，包含：

1. 系統設定 API
   - src/api/services/settings.js: 系統設定 API
   - src/api/services/systemOptions.js: 系統選項 API

2. 系統設定頁面
   - src/components/SystemSettings.vue: 系統設定管理
   - 功能：編碼規則設定、審核流程設定、系統參數管理

3. 資料庫結構
   - system_settings, system_options 表的 SQL 腳本

參考檔案：
- 現有實作：src/components/SystemSettings.vue
- 資料庫結構：src/database/supabase/supabase_schema.sql
```

#### Step 4.2: 供應商管理模組

**Prompt:**

```
請實作供應商管理模組，包含：

1. 供應商管理 API
   - src/api/services/suppliers.js: 供應商管理 API

2. 供應商管理頁面
   - src/pages/suppliers.vue: 供應商列表與管理
   - 功能：CRUD、啟用/停用

3. 資料庫結構
   - suppliers 表的 SQL 腳本

參考檔案：
- 資料庫結構：src/database/supabase/supabase_schema.sql
```

#### Step 4.3: 草稿功能

**Prompt:**

```
請實作草稿功能，包含：

1. 草稿管理 API
   - src/api/services/drafts.js: 草稿管理 API
   - 功能：儲存草稿、載入草稿、刪除草稿

2. 自動儲存機制
   - 表單自動儲存（每 30 秒或失去焦點時）
   - 使用防抖（debounce）機制

3. 草稿列表
   - 顯示使用者的所有草稿
   - 可繼續編輯或刪除

4. 資料庫結構
   - drafts 表的 SQL 腳本

參考檔案：
- 資料庫結構：src/database/supabase/supabase_schema.sql
```

### 階段五：整合測試與優化

#### Step 5.1: 雙後端整合測試

**Prompt:**

```
請建立雙後端整合測試，確保：

1. Supabase 後端功能正常
   - 所有 API 在 Supabase 模式下正常運作
   - 認證流程正常
   - 資料庫操作正常

2. Axios 後端功能正常
   - 所有 API 在 Axios 模式下正常運作
   - REST API 呼叫正常
   - 錯誤處理正常

3. 後端切換測試
   - 透過環境變數切換後端
   - 確保功能一致性

4. 測試文件
   - 建立測試檢查清單
   - 記錄測試結果
```

#### Step 5.2: 效能優化

**Prompt:**

```
請進行效能優化，包含：

1. 程式碼優化
   - 組件懶加載
   - API 請求優化
   - 資料快取機制

2. 使用者體驗優化
   - 載入狀態顯示
   - 錯誤訊息優化
   - 操作回饋優化

3. 響應式設計優化
   - 確保所有頁面在各種裝置上正常顯示
   - 觸控操作優化
```

#### Step 5.3: 文件撰寫

**Prompt:**

```
請撰寫完整的專案文件，包含：

1. README.md
   - 專案簡介
   - 安裝與執行指南
   - 功能說明

2. API 文件
   - 所有 API 的說明文件
   - 請求/回應格式
   - 錯誤碼說明

3. 資料庫文件
   - 資料表結構說明
   - 關聯關係圖
   - 遷移腳本說明

4. 開發指南
   - 開發環境設定
   - 程式碼規範
   - 貢獻指南
```

---

## 參考檔案整理指南

### 需要整理的參考檔案

為了讓新專案能夠參考現有實作，建議將以下檔案整理到一個集中的參考資料夾：

#### 1. Legacy 網頁檔案（已在 @public/prototype）

- `material_system_v3.5_complete.html` - 完整的 Legacy HTML 版本
- `v35_optimized_script.js` - Legacy JavaScript 檔案
- `excel_processor_v35_optimized.py` - Excel 處理腳本
- `README_V3.5_OPTIMIZED.md` - Legacy 版本文件

#### 2. 資料庫結構檔案

建議整理到 `doc/reference/database/`：

- `supabase_schema.sql` - Supabase 完整資料庫結構
- `dynamic_forms_schema.sql` - 動態表單資料庫結構
- `database_relations.md` - 資料庫關聯圖
- `schema.js` - JavaScript Schema 定義

#### 3. API 實作參考檔案

建議整理到 `doc/reference/api/`：

- `src/api/services/` - 所有 API 服務實作
- `src/api/README.md` - API 層說明文件

#### 4. 組件實作參考檔案

建議整理到 `doc/reference/components/`：

- `src/components/FormDesigner.vue` - 表單設計器
- `src/components/DynamicFormRenderer.vue` - 表單渲染器
- `src/components/form-fields/` - 所有欄位組件
- `src/components/ReviewManagement.vue` - 審核管理
- 其他重要組件

#### 5. Store 實作參考檔案

建議整理到 `doc/reference/stores/`：

- `src/stores/auth.js` - 認證 Store
- `src/stores/applications.js` - 申請 Store
- 其他 Store 檔案

#### 6. 頁面實作參考檔案

建議整理到 `doc/reference/pages/`：

- `src/pages/users.vue` - 使用者管理頁面
- `src/pages/forms.vue` - 表單管理頁面
- 其他頁面檔案

### 整理步驟 Prompt

**Prompt:**

```
請幫我整理參考檔案，建立以下目錄結構：

doc/reference/
├── database/          # 資料庫結構參考
│   ├── supabase_schema.sql
│   ├── dynamic_forms_schema.sql
│   ├── database_relations.md
│   └── schema.js
├── api/               # API 實作參考
│   ├── services/
│   └── README.md
├── components/        # 組件實作參考
│   ├── FormDesigner.vue
│   ├── DynamicFormRenderer.vue
│   ├── form-fields/
│   └── ...
├── stores/            # Store 實作參考
│   └── ...
├── pages/             # 頁面實作參考
│   └── ...
└── legacy/            # Legacy 檔案（從 @public/prototype 複製）
    ├── material_system_v3.5_complete.html
    ├── v35_optimized_script.js
    └── ...

請將對應的檔案複製到上述目錄結構中，並建立一個 README.md 說明每個資料夾的用途。
```

---

## 總結

本重構計劃提供了完整的系統分析與重構步驟，每個步驟都包含詳細的 Prompt，可以直接用於指導 AI 助手或開發團隊進行重構工作。

### 重構優先順序建議

1. **第一優先**：階段一（專案初始化）→ 階段二（核心功能模組）
2. **第二優先**：階段三（業務功能模組）
3. **第三優先**：階段四（系統設定與其他功能）
4. **最後**：階段五（整合測試與優化）

### 注意事項

1. 每個步驟完成後，建議進行程式碼審查與測試
2. 保持與現有系統的功能一致性
3. 確保雙後端支援的完整性
4. 重視文件撰寫，便於後續維護
5. 參考檔案整理完成後，新專案開發時可以隨時參考

### 後續工作

完成重構後，建議：

1. 進行完整的整合測試
2. 效能測試與優化
3. 安全性檢查
4. 使用者接受度測試（UAT）
5. 部署與遷移計劃
