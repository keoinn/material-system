# 審核管理功能設置指南

## 概述

此指南說明如何設置審核管理功能，使其能夠查詢和審核動態表單提交的申請。

## 資料庫設置步驟

### 1. 執行 SQL 文件

在 Supabase SQL Editor 或 PostgreSQL 客戶端中執行以下 SQL 文件（按順序）：

```sql
-- 1. 創建審核管理視圖和函數
\i src/database/supabase/create_review_management_views.sql

-- 2. 確保動態表單結構已創建（如果尚未執行）
\i src/database/supabase/dynamic_forms_schema.sql

-- 3. 確保 applications 表已創建（如果尚未執行）
-- 這通常在 supabase_schema.sql 中
```

### 2. 驗證視圖和函數

執行以下查詢驗證設置是否成功：

```sql
-- 檢查視圖是否存在
SELECT * FROM pending_applications_view LIMIT 5;

-- 檢查函數是否存在
SELECT proname FROM pg_proc WHERE proname = 'get_application_form_data';
SELECT proname FROM pg_proc WHERE proname = 'update_application_status';
```

## 功能說明

### 1. 視圖：`pending_applications_view`

此視圖提供待審核申請的統一查詢介面，包含：
- 傳統 applications 表申請
- 動態表單申請（form_data_values）
- 申請人資訊
- 表單類型標記（is_dynamic_form）

### 2. 函數：`get_application_form_data(application_id)`

獲取指定申請的動態表單資料，返回 JSONB 格式。

### 3. 函數：`update_application_status(...)`

更新申請狀態並創建審核記錄，支援：
- 核准申請
- 退回申請
- 記錄審核意見

## 測試步驟

### 前置條件

1. 確保已登入系統
2. 確保有「審核管理」權限
3. 確保已創建至少一個動態表單（form_code = 'material_application'）

### 測試流程

#### 步驟 1：提交動態表單申請

1. 導航到「物料申請」頁面
2. 填寫表單欄位
3. 點擊「提交申請」
4. 確認提交成功，記錄申請單號

#### 步驟 2：驗證資料庫記錄

在 Supabase SQL Editor 中執行：

```sql
-- 檢查 applications 表是否有新記錄
SELECT id, item_code, item_name_cn, status, approval_status, submit_date
FROM applications
WHERE status = 'PENDING'
ORDER BY created_at DESC
LIMIT 5;

-- 檢查 form_data_values 表是否有對應資料
SELECT fdv.record_id, fdv.field_key, fdv.field_value, f.form_code
FROM form_data_values fdv
JOIN forms f ON fdv.form_id = f.id
WHERE f.form_code = 'material_application'
ORDER BY fdv.created_at DESC
LIMIT 10;
```

#### 步驟 3：在審核管理中查看申請

1. 導航到「審核管理」頁面
2. 確認可以看到剛才提交的申請
3. 檢查申請列表顯示：
   - 申請日期
   - 申請單號
   - 料號
   - 料件說明
   - 申請人
   - 狀態（應顯示「待審核」）

#### 步驟 4：查看申請詳情

1. 點擊申請的「詳情」按鈕
2. 確認詳情對話框顯示：
   - 基本資訊區塊（申請單號、料號、名稱等）
   - 表單資料區塊（動態表單欄位值）
   - 所有欄位值正確顯示

#### 步驟 5：核准申請

1. 點擊「核准」按鈕
2. 確認對話框
3. 確認申請狀態變更為「已核准」
4. 確認申請從待審核列表中移除

#### 步驟 6：驗證審核記錄

在 Supabase SQL Editor 中執行：

```sql
-- 檢查審核記錄
SELECT 
  al.id,
  al.application_id,
  al.action,
  al.approver_name,
  al.reason,
  al.comment,
  al.timestamp
FROM approval_logs al
ORDER BY al.timestamp DESC
LIMIT 5;

-- 檢查申請狀態是否已更新
SELECT id, status, approval_status, approver_id, approval_date
FROM applications
WHERE status = 'APPROVED'
ORDER BY approval_date DESC
LIMIT 5;
```

#### 步驟 7：測試退回功能

1. 提交一個新的申請
2. 在審核管理中點擊「退回」按鈕
3. 輸入退回原因
4. 確認退回
5. 驗證申請狀態變更為「已退回」
6. 驗證審核記錄中有退回記錄

## 常見問題排查

### 問題 1：審核管理中看不到申請

**可能原因：**
- 申請狀態不是 'PENDING'
- 視圖未正確創建
- 權限問題

**解決方法：**
```sql
-- 檢查申請狀態
SELECT id, status, approval_status FROM applications WHERE id = <申請ID>;

-- 檢查視圖
SELECT * FROM pending_applications_view WHERE id = <申請ID>;
```

### 問題 2：動態表單資料不顯示

**可能原因：**
- form_data_values 表中沒有資料
- form_id 不匹配
- record_id 不匹配

**解決方法：**
```sql
-- 檢查 form_data_values
SELECT * FROM form_data_values 
WHERE record_id = <申請ID> 
AND form_id = (SELECT id FROM forms WHERE form_code = 'material_application');
```

### 問題 3：審核操作失敗

**可能原因：**
- 函數未創建
- 權限不足
- 審核人資訊缺失

**解決方法：**
```sql
-- 檢查函數
SELECT proname FROM pg_proc WHERE proname = 'update_application_status';

-- 檢查用戶權限
SELECT id, username, role FROM user_profiles WHERE id = <用戶ID>;
```

## 資料庫結構說明

### 相關表

1. **applications** - 申請主表
2. **form_data_values** - 動態表單資料值表
3. **forms** - 表單定義表
4. **form_fields** - 表單欄位定義表
5. **approval_logs** - 審核記錄表
6. **user_profiles** - 用戶資料表

### 關鍵欄位

- `applications.id` - 申請 ID（與 form_data_values.record_id 關聯）
- `form_data_values.form_id` - 表單 ID
- `form_data_values.record_id` - 記錄 ID（對應 applications.id）
- `applications.status` - 申請狀態（PENDING, APPROVED, REJECTED）
- `applications.approval_status` - 審核狀態

## 注意事項

1. **資料一致性**：確保 applications 表和 form_data_values 表的 record_id 一致
2. **權限設置**：確保審核人員有適當的資料庫權限
3. **效能優化**：如果申請數量很大，考慮添加適當的索引
4. **備份**：在執行 SQL 文件前，建議先備份資料庫

## 後續優化建議

1. 添加審核流程多層級支援
2. 添加審核歷史記錄查詢
3. 添加審核通知功能
4. 優化大量申請的查詢效能
5. 添加審核統計報表
