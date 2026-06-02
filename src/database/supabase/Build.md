# Supabase 後端建置指引

本文件供維運人員在新環境建立 **物料編碼系統 v3.6** 的 Supabase 後端，包含：

- PostgreSQL 資料庫（23 張表）
- Storage Bucket（附件上傳）
- Edge Function（管理者重設密碼）

> 前端需設定 `VITE_API_BACKEND=supabase` 才會使用此後端。

---

## 目錄

1. [前置需求](#1-前置需求)
2. [建立 Supabase 專案](#2-建立-supabase-專案)
3. [初始化資料庫 Schema](#3-初始化資料庫-schema)
4. [建立 Storage Bucket](#4-建立-storage-bucket)
5. [部署 Edge Function](#5-部署-edge-function)
6. [設定環境變數](#6-設定環境變數)
7. [驗證建置結果](#7-驗證建置結果)
8. [維護腳本](#8-維護腳本)
9. [故障排除](#9-故障排除)

---

## 1. 前置需求

| 項目 | 說明 |
|------|------|
| Supabase 帳號 | [https://supabase.com](https://supabase.com) |
| Supabase CLI | 部署 Edge Function 用，[安裝說明](https://supabase.com/docs/guides/cli) |
| 專案原始碼 | 含 `src/database/supabase/` 與 `supabase/functions/` |

安裝並登入 CLI（範例）：

```bash
npm install -g supabase
supabase login
```

---

## 2. 建立 Supabase 專案

1. 登入 [Supabase Dashboard](https://supabase.com/dashboard)
2. **New project** → 選擇 Organization、輸入專案名稱、設定 Database Password、選擇 Region
3. 等待專案建立完成（約 1–2 分鐘）
4. 至 **Project Settings → API** 記下：
   - **Project URL** → 對應 `VITE_SUPABASE_URL`
   - **anon / publishable key** → 對應 `VITE_SUPABASE_ANON_KEY`
   - **service_role key** → 僅供 Edge Function 使用，**不可**放入前端打包

若使用 CLI 連結遠端專案（部署 Function 前）：

```bash
cd /path/to/material-system-v36
supabase link --project-ref <your-project-ref>
```

`<your-project-ref>` 可在 Dashboard → Project Settings → General 找到。

---

## 3. 初始化資料庫 Schema

### 3.1 全新環境（建議）

1. 開啟 Dashboard → **SQL Editor**
2. 開啟專案內 **`src/database/supabase/supabase_schema_withoutdata_master.sql`**
3. 複製**全文**貼入 SQL Editor → **Run**

此檔案一次建立：

- 23 張資料表（使用者、表單、審核流程、角色權限、部門、選項活頁簿、包裝模板等）
- 觸發器、視圖、RPC 函數（含 `get_users_with_email`）
- **不含**種子資料（避免 `user_profiles` 外鍵依賴 `auth.users` 導致部署失敗）

若需要連同預設表單、系統設定等種子資料一併匯入，請改用 `supabase_schema_master.sql`（需先於 Authentication 建立對應 UUID 的使用者）。

### 3.2 重置現有環境（慎用）

| 目的 | 腳本 | 說明 |
|------|------|------|
| 只清空資料、保留表結構 | `empty_all_table.sql` | 刪除全部 23 張表的資料 |
| 完全刪除表結構 | `remove_all_table.sql` | 刪除表、視圖、函數；之後需重新執行 master schema |

> ⚠️ 以上操作不可逆，執行前請先備份。

### 3.3 Auth 使用者與 user_profiles

Schema 會建立 `handle_new_user` 觸發器：新使用者在 `auth.users` 註冊時，自動在 `user_profiles` 建立一筆記錄（預設 `is_active = false`，需管理員啟用）。

種子資料中的 `user_profiles` 需對應已存在於 **Authentication → Users** 的 UUID；若為全新專案，請先建立管理員帳號，或調整 seed 中的 UUID。

---

## 4. 建立 Storage Bucket

應用程式透過 Supabase Storage 儲存附件（圖片、文件、圖面等）。

### 4.1 建立 Bucket

1. Dashboard → **Storage** → **New bucket**
2. 設定：
   - **Name**：`attachments`（或自訂名稱，需與環境變數一致）
   - **Public bucket**：**建議開啟**（前端使用 `getPublicUrl` 取得檔案連結）

### 4.2 Storage Policies

若 Bucket 設為 Public，仍建議限制**寫入**僅限已登入使用者。至 **Storage → attachments → Policies**，新增以下政策（或在 SQL Editor 執行）：

```sql
-- 已登入使用者可上傳
CREATE POLICY "attachments_insert_authenticated"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'attachments');

-- 已登入使用者可更新自己上傳的檔案（選用）
CREATE POLICY "attachments_update_authenticated"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'attachments');

-- 已登入使用者可刪除（選用）
CREATE POLICY "attachments_delete_authenticated"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'attachments');

-- Public bucket 讀取（若 bucket 已設為 public，通常已可讀）
CREATE POLICY "attachments_select_public"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'attachments');
```

### 4.3 檔案路徑慣例

上傳路徑格式（見 `src/api/services/supabase/attachments.js`）：

```
applications/{recordId}/{timestamp}-{filename}
```

資料庫 `attachments` 表儲存 `file_url`（公開 URL）及相關 metadata。

---

## 5. 部署 Edge Function

本專案使用 **1 個** Edge Function，供管理員重設其他使用者密碼（前端 anon key 無法直接修改他人密碼）。

| 項目 | 值 |
|------|-----|
| 路徑 | `supabase/functions/admin-reset-password/` |
| 用途 | 驗證呼叫者為 `admin` 後，以 service role 重設指定使用者密碼 |
| 前端呼叫 | `supabase.functions.invoke('admin-reset-password', ...)` |

### 5.1 設定 Function Secret

Service Role Key **不可**以前端環境變數暴露。請設為 Supabase Function Secret：

```bash
cd /path/to/material-system-v36

# 連結專案（若尚未 link）
supabase link --project-ref <your-project-ref>

# 設定 secret（Supabase CLI 不允許 SUPABASE_ 前綴的自訂 secret 名稱）
supabase secrets set SERVICE_ROLE_KEY="<your-service-role-key>"
```

`SUPABASE_URL` 與 `SUPABASE_ANON_KEY` 由 Supabase 執行環境自動注入，無需手動設定。

### 5.2 部署 Function

```bash
supabase functions deploy admin-reset-password
```

本 Function 附帶 `config.toml`：

```toml
verify_jwt = false
```

必須設為 `false`，否則瀏覽器 CORS preflight（`OPTIONS`）會在到達程式碼前被 Gateway 擋下。Function 內部仍會自行驗證 JWT 與 admin 角色。

部署後若修改過 `config.toml`，請重新 deploy 一次。

### 5.3 權限說明

- 呼叫者必須已登入（Bearer JWT）
- `user_profiles.role` 必須為 `admin` 且 `is_active = true`
- Request Body：`{ "userId": "<uuid>", "newPassword": "<至少6字元>" }`

---

## 6. 設定環境變數

前端建置與開發時，在專案根目錄建立 **`.env.local`**（勿提交版控），參考 `.env` 模板：

```env
# 後端類型（使用 Supabase 時必填）
VITE_API_BACKEND=supabase

# ============================================================================
# Supabase 設定
# ============================================================================
VITE_SUPABASE_URL=https://<your-project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<your-anon-key>
VITE_SUPABASE_STORAGE_BUCKET=attachments
VITE_SUPABASE_SERVICE_ROLE_KEY="<your-service-role-key>"
```

### 變數說明

| 變數 | 必填 | 用途 | 取得位置 |
|------|------|------|----------|
| `VITE_API_BACKEND` | ✅ | 設為 `supabase` 啟用 Supabase 後端 | 固定值 |
| `VITE_SUPABASE_URL` | ✅ | Supabase 專案 API URL | Dashboard → Settings → API |
| `VITE_SUPABASE_ANON_KEY` | ✅ | 前端公開金鑰，打包進瀏覽器 | Dashboard → Settings → API |
| `VITE_SUPABASE_STORAGE_BUCKET` | ✅ | Storage bucket 名稱，預設 `attachments` | 第 4 節建立的 bucket |
| `VITE_SUPABASE_SERVICE_ROLE_KEY` | ⚠️ | Service Role 金鑰 | Dashboard → Settings → API |

### 安全注意事項

| 金鑰 | 前端 `.env.local` | Edge Function Secret |
|------|-------------------|----------------------|
| Anon Key | ✅ 需要 | 自動注入 |
| Service Role Key | ❌ **不建議**放入前端 | ✅ 以 `SERVICE_ROLE_KEY` 設定 |

- **Service Role Key 擁有完整資料庫權限**，絕不可 commit 至 Git 或暴露於公開前端。
- 本專案前端程式**未使用** `VITE_SUPABASE_SERVICE_ROLE_KEY`；管理者改密碼功能透過 Edge Function + `SERVICE_ROLE_KEY` secret 運作。
- `.env.local` 已在 `.gitignore`；請確認勿將含真實 key 的檔案提交。

---

## 7. 驗證建置結果

### 7.1 資料庫

SQL Editor 執行：

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

應包含 `user_profiles`、`forms`、`approval_records`、`roles` 等 23 張表。

### 7.2 Storage

Dashboard → Storage → `attachments` → 確認 bucket 存在且 policies 已設定。

### 7.3 Edge Function

Dashboard → Edge Functions → 確認 `admin-reset-password` 狀態為 deployed。

### 7.4 前端連線測試

```bash
npm install
npm run dev
```

瀏覽器開啟 **`/testing/supabase`** 頁面，依序測試：

1. 環境變數狀態（URL、Anon Key、Bucket）
2. 連線測試
3. 認證測試（登入後）
4. Storage 測試

---

## 8. 維護腳本

| 檔案 | 用途 |
|------|------|
| `supabase_schema_withoutdata_master.sql` | 完整建庫（**新環境建議**，僅 DDL） |
| `supabase_schema_master.sql` | 完整建庫 + 種子資料 |
| `empty_all_table.sql` | 清空全部表資料 |
| `remove_all_table.sql` | 刪除全部表結構與函數 |

---

## 9. 故障排除

### Schema 執行失敗

- 確認在**空專案**或已先執行 `remove_all_table.sql` 清理舊結構
- 若 `auth.users` 觸發器報錯，確認 Supabase Auth 已啟用

### 附件上傳失敗（403 / RLS）

- 確認 Storage bucket 名稱與 `VITE_SUPABASE_STORAGE_BUCKET` 一致
- 確認使用者已登入
- 檢查 Storage Policies 是否允許 `authenticated` 使用者 INSERT

### 管理者無法重設密碼

- 確認 Edge Function 已部署：`supabase functions deploy admin-reset-password`
- 確認 secret 已設定：`supabase secrets list` 應含 `SERVICE_ROLE_KEY`
- 確認呼叫者 `user_profiles.role = 'admin'` 且已啟用
- 若 CORS 錯誤，確認 `verify_jwt = false` 並重新 deploy

### 前端顯示「Supabase 未初始化」

- 確認 `.env.local` 存在且含 `VITE_SUPABASE_URL`、`VITE_SUPABASE_ANON_KEY`
- 修改 `.env.local` 後需**重啟** `npm run dev`

---

## 建置檢查清單

```
[ ] Supabase 專案已建立
[ ] 已執行 supabase_schema_withoutdata_master.sql
[ ] Storage bucket「attachments」已建立並設定 policies
[ ] Edge Function admin-reset-password 已部署
[ ] SERVICE_ROLE_KEY secret 已設定
[ ] .env.local 已設定 VITE_SUPABASE_* 變數
[ ] npm run dev 後 /testing/supabase 測試通過
[ ] 管理員帳號可登入且 user_profiles.is_active = true
```
