# 物料編碼申請管理系統 V3.6

## 專案簡介

這是物料編碼申請管理系統的 Vue3 + Vuetify 版本，從原本的 HTML/JavaScript 版本改寫而來。

## 技術棧

- **Vue 3** - 前端框架
- **Vuetify 3** - Material Design 組件庫
- **Pinia** - 狀態管理
- **Vue Router** - 路由管理（使用 auto-route）
- **SCSS** - 樣式預處理器
- **Supabase** - Auth / Database（支援 Edge Functions）

## 專案結構

```text
src/
├── components/          # Vue 組件
│   ├── MaterialApplicationForm.vue    # 物料申請表單
│   ├── PackagingFormSection.vue      # 包裝表單區塊
│   ├── PackagingSection.vue          # 單一包裝區塊
│   ├── ReviewManagement.vue          # 審核管理
│   ├── ExcelExport.vue               # Excel匯出
│   ├── ApplicationQuery.vue          # 申請查詢
│   ├── SystemSettings.vue            # 系統設定
│   └── PackagingTemplateSettings.vue # 包裝模板設定
├── database/            # 資料庫 Schema（目前僅定義，未實現）
│   └── schema.js
├── layouts/             # 佈局組件
│   └── default.vue
├── pages/               # 頁面組件（自動路由）
│   ├── index.vue       # 主頁面
│   └── login.vue       # 登入頁面
├── plugins/             # Vue 插件
│   ├── index.js
│   └── vuetify.js
├── router/              # 路由設定
│   └── index.js
├── stores/              # Pinia Stores
│   ├── auth.js         # 認證 Store
│   ├── applications.js # 申請資料 Store
│   ├── settings.js     # 設定 Store
│   └── packaging.js    # 包裝模板 Store
└── styles/              # 樣式檔案
    ├── material-system.scss
    └── variables.scss
```

## 功能特色

### 1. 物料申請

- 三層分類架構（大類/中類/小類）
- 自動產生料號
- 完整的包裝說明（8個類別）
- 自動儲存草稿

### 2. 審核管理

- 待審核申請列表
- 核准/退回功能
- 申請詳情查看

### 3. Excel匯出

- 支援多條件篩選
- CSV格式匯出
- 資料預覽功能

### 4. 申請查詢

- 多條件搜尋
- 申請記錄查詢
- 詳情查看

### 5. 系統設定

- 編碼規則設定
- 審核流程設定

### 6. 包裝模板管理

- 類別預設值設定
- 模板儲存與載入

## 管理者變更其他使用者密碼（Supabase）

在 `VITE_API_BACKEND=supabase` 模式下，前端無法使用 anon key 直接修改「其他使用者」的 Auth 密碼。本專案使用 Supabase Edge Function 來讓 **admin** 角色執行密碼重設。

- **Edge Function**: `supabase/functions/admin-reset-password/index.ts`
- **權限**: 只有 `user_profiles.role = 'admin'` 且帳號啟用者可呼叫
- **需要設定的 Function Secrets**
  - `SERVICE_ROLE_KEY`（Supabase CLI 不允許 `SUPABASE_` 前綴的自訂 secrets）

部署方式（範例）請使用 Supabase CLI：

```bash
supabase functions deploy admin-reset-password
supabase secrets set SERVICE_ROLE_KEY="<service_role_key>"
```

如果你在瀏覽器端呼叫時遇到 CORS preflight（`OPTIONS`）被擋，請確保此 function **沒有啟用 gateway JWT 驗證**（因為 preflight 不會帶 Authorization，會在到達程式碼前就被擋下）。本專案已提供 `supabase/functions/admin-reset-password/config.toml`：

```toml
verify_jwt = false
```

部署後請重新部署一次 function 以套用設定：

```bash
supabase functions deploy admin-reset-password
```

## 快速開始

### 安裝依賴

```bash
npm install
```

### 開發模式

```bash
npm run dev
```

### 建置生產版本

```bash
npm run build
```

### 預覽生產版本

```bash
npm run preview
```

## 登入說明

系統預設提供兩個測試帳號：

- **使用者名稱**: `admin` / **密碼**: 任意（開發模式）
- **使用者名稱**: `user` / **密碼**: 任意（開發模式）

## 快捷鍵

- `Alt + N`: 切換到物料申請
- `Alt + R`: 切換到審核管理
- `Alt + E`: 切換到Excel匯出
- `Alt + Q`: 切換到申請查詢
- `Alt + S`: 切換到系統設定

## 資料儲存

系統使用 `localStorage` 儲存資料：

- `applications_v35`: 申請資料
- `codeCounter_v35`: 編碼計數器
- `settings_v35`: 系統設定
- `packagingTemplates_v35`: 包裝模板
- `draft_v35`: 草稿資料
- `user`: 使用者資料
- `auth_token`: 認證 Token

## 響應式設計

系統支援響應式設計，可在以下裝置使用：

- 桌面電腦（1920px+）
- 筆記型電腦（1366px+）
- 平板（768px+）
- 手機（320px+）

## 瀏覽器支援

- Chrome 90+
- Edge 90+
- Firefox 88+
- Safari 14+

## 開發注意事項

1. 使用 `auto-route`，頁面檔案放在 `src/pages/` 會自動產生路由
2. Pinia stores 使用 Composition API 風格
3. 樣式使用 SCSS，符合原始設計的顏色和排版
4. 路由守衛會檢查認證狀態，未登入會重導向到登入頁面

## 資料庫 Schema

資料庫 Schema 定義在 `src/database/schema.js`，目前僅定義結構，尚未實現實際的資料庫功能。

## 版本資訊

- **版本**: V3.6
- **基於**: V3.5 優化版
- **改寫日期**: 2024

## 授權

內部使用系統，未經授權不得對外發布。
