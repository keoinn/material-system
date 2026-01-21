# 審核流程自定義功能使用指南

## 概述

審核流程自定義功能允許系統管理員定義申請單的審核流程，包括：
- 定義自定義的審核狀態
- 配置多層級的審核流程
- 指定每個審核層級由誰審核或核准

## 功能特點

1. **自定義審核狀態**：可以定義系統中使用的審核狀態（如：待審核、審核中、已核准、已退回等）
2. **多層級審核流程**：可以配置多個審核步驟，每個步驟可以指定不同的審核人
3. **靈活的審核人配置**：支援指定使用者、角色或部門作為審核人
4. **審核記錄追蹤**：完整記錄每次審核操作的歷史

## 資料庫設置

### 1. 執行 SQL 腳本

在 Supabase SQL Editor 中執行以下 SQL 文件：

```sql
-- 創建審核流程相關的資料表
\i src/database/supabase/r1/create_approval_workflow_schema.sql
```

### 2. 驗證設置

執行以下查詢驗證設置是否成功：

```sql
-- 檢查資料表是否存在
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'approval_statuses',
  'approval_workflows',
  'approval_workflow_steps',
  'approval_records',
  'approval_action_logs'
);

-- 檢查預設狀態是否已創建
SELECT * FROM approval_statuses;
```

## 使用步驟

### 步驟 1：定義審核狀態

1. 進入「系統設定」頁面
2. 切換到「審核流程設定」標籤
3. 點擊「新增狀態」按鈕
4. 填寫狀態資訊：
   - **狀態代碼**：唯一識別碼（例如：PENDING, IN_REVIEW, APPROVED）
   - **狀態名稱**：顯示名稱（中文）
   - **狀態類型**：選擇「初始狀態」、「中間狀態」或「最終狀態」
   - **顏色**：用於 UI 顯示的顏色
   - **圖示**：可選的圖示名稱
   - **顯示順序**：用於排序的數字

### 步驟 2：創建審核流程

1. 在「審核流程設定」標籤中，切換到「審核流程」子標籤
2. 點擊「新增流程」按鈕
3. 填寫流程資訊：
   - **流程代碼**：唯一識別碼（例如：material_application_default）
   - **流程名稱**：顯示名稱
   - **關聯表單**：可選，指定此流程適用的表單（留空表示通用流程）
   - **初始狀態**：申請提交時的初始狀態
   - **最終狀態**：核准完成時的狀態
   - **退回狀態**：退回時的狀態
   - **設為預設流程**：是否為預設流程

### 步驟 3：配置審核步驟

1. 在流程列表中，點擊「查看步驟」圖示
2. 點擊「新增步驟」按鈕
3. 為每個步驟配置：
   - **步驟順序**：步驟的執行順序（從 1 開始）
   - **步驟名稱**：步驟的顯示名稱
   - **對應狀態**：此步驟對應的審核狀態
   - **審核人類型**：選擇以下之一：
     - **指定使用者**：選擇具體的使用者
     - **指定角色**：選擇角色（如：approver）
     - **指定部門**：輸入部門名稱
     - **自動通過**：自動通過此步驟
   - **必須審核**：是否必須審核
   - **可跳過**：是否可跳過此步驟
   - **自動核准天數**：可選，設定自動核准的天數

### 步驟 4：設定流程關聯

- 如果流程關聯到特定表單，該表單的申請會自動使用此流程
- 如果流程沒有關聯表單（通用流程），會作為預設流程使用

## 審核流程範例

### 範例 1：兩層審核流程

1. **步驟 1：部門主管審核**
   - 審核人類型：指定角色（approver）
   - 對應狀態：IN_REVIEW
   - 核准後：進入步驟 2

2. **步驟 2：總經理核准**
   - 審核人類型：指定使用者（總經理）
   - 對應狀態：APPROVED
   - 核准後：流程結束

### 範例 2：三層審核流程

1. **步驟 1：部門主管審核**
   - 審核人類型：指定部門（IT）
   - 對應狀態：IN_REVIEW
   - 核准後：進入步驟 2

2. **步驟 2：財務審核**
   - 審核人類型：指定角色（approver）
   - 對應狀態：IN_REVIEW
   - 核准後：進入步驟 3

3. **步驟 3：總經理核准**
   - 審核人類型：指定使用者（總經理）
   - 對應狀態：APPROVED
   - 核准後：流程結束

## 審核操作

### 提交申請

當使用者提交申請時：
1. 系統會自動查找適用的審核流程（優先使用表單關聯的流程，否則使用預設流程）
2. 創建審核記錄，狀態設為初始狀態
3. 將申請分配給第一個步驟的審核人

### 審核申請

審核人可以：
1. **核准**：將申請推進到下一個步驟，或完成審核（如果是最後一步）
2. **退回**：將申請退回，狀態設為退回狀態
3. **退回修改**：將申請退回給申請人修改

### 查看審核記錄

在審核管理頁面可以：
- 查看待審核的申請列表
- 查看申請的詳細資訊
- 查看審核歷史記錄

## API 使用

### 創建審核記錄

```javascript
import { approvalWorkflowsService } from '@/api/services/approvalWorkflows'

// 在表單提交時自動創建（已在 formDataService 中實現）
await approvalWorkflowsService.createApprovalRecord({
  form_id: formId,
  record_id: recordId,
  applicant_id: userId,
})
```

### 執行審核操作

```javascript
// 核准申請
await approvalWorkflowsService.executeApprovalAction({
  approval_record_id: approvalRecordId,
  action: 'APPROVE',
  approver_id: approverId,
  comment: '審核意見',
})

// 退回申請
await approvalWorkflowsService.executeApprovalAction({
  approval_record_id: approvalRecordId,
  action: 'REJECT',
  approver_id: approverId,
  reason: '退回原因',
})
```

### 查詢審核記錄

```javascript
// 取得申請的審核記錄
const record = await approvalWorkflowsService.getApprovalRecord(formId, recordId)

// 取得當前審核人列表
const approvers = await approvalWorkflowsService.getCurrentApprovers(approvalRecordId)

// 取得審核操作歷史
const logs = await approvalWorkflowsService.getApprovalActionLogs(approvalRecordId)
```

## 資料表結構

### approval_statuses（審核狀態定義表）

- `status_code`：狀態代碼（主鍵）
- `status_name`：狀態名稱（中文）
- `status_type`：狀態類型（INITIAL, INTERMEDIATE, FINAL）
- `color`：顯示顏色
- `icon`：圖示名稱

### approval_workflows（審核流程配置表）

- `id`：流程 ID（主鍵）
- `workflow_code`：流程代碼（唯一）
- `workflow_name`：流程名稱
- `form_id`：關聯的表單 ID（可選）
- `initial_status_code`：初始狀態
- `final_status_code`：最終狀態
- `reject_status_code`：退回狀態

### approval_workflow_steps（審核流程步驟表）

- `id`：步驟 ID（主鍵）
- `workflow_id`：所屬流程 ID
- `step_order`：步驟順序
- `step_name`：步驟名稱
- `status_code`：對應狀態
- `approver_type`：審核人類型（USER, ROLE, DEPARTMENT, AUTO）
- `approver_config`：審核人配置（JSON）

### approval_records（申請審核記錄表）

- `id`：記錄 ID（主鍵）
- `form_id`：表單 ID
- `record_id`：申請記錄 ID
- `workflow_id`：使用的流程 ID
- `current_step_id`：當前步驟 ID
- `current_status_code`：當前狀態
- `applicant_id`：申請人 ID
- `is_completed`：是否已完成

### approval_action_logs（審核操作記錄表）

- `id`：記錄 ID（主鍵）
- `approval_record_id`：審核記錄 ID
- `step_id`：執行的步驟 ID
- `action`：操作類型（SUBMIT, APPROVE, REJECT, RETURN）
- `approver_id`：審核人 ID
- `from_status_code`：操作前狀態
- `to_status_code`：操作後狀態
- `comment`：審核意見
- `reason`：退回原因

## 注意事項

1. **狀態定義**：確保定義的狀態代碼是唯一的，建議使用大寫字母和下劃線
2. **流程配置**：每個流程至少需要一個步驟，步驟順序必須連續
3. **審核人配置**：確保指定的使用者、角色或部門存在且有效
4. **預設流程**：建議為每個表單類型設定一個預設流程
5. **向後相容**：如果沒有配置審核流程，系統會使用舊的審核方式（直接更新狀態）

## 故障排除

### 問題：無法創建審核記錄

**解決方案**：
1. 檢查資料表是否已創建
2. 檢查表單 ID 和記錄 ID 是否有效
3. 檢查是否有預設流程配置

### 問題：審核人無法看到待審核申請

**解決方案**：
1. 檢查審核人配置是否正確
2. 檢查使用者角色是否匹配
3. 檢查申請的當前狀態是否正確

### 問題：流程無法推進到下一步

**解決方案**：
1. 檢查步驟配置中的 `next_step_on_approve` 是否正確
2. 檢查下一步驟是否存在
3. 檢查流程是否已完成

## 未來改進

- [ ] 支援條件式審核流程（根據申請內容決定審核路徑）
- [ ] 支援並行審核（多個審核人同時審核）
- [ ] 支援審核時限提醒
- [ ] 支援審核委派功能
- [ ] 支援審核流程版本管理
