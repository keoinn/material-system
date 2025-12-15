# Schema 分析報告

## 📋 表單欄位 vs Schema 對照

### ✅ 已實現的欄位

| 欄位名稱 | Schema | 表單 | 狀態 |
|---------|--------|------|------|
| id | ✅ | ✅ (自動產生) | ✅ |
| submitDate | ✅ | ✅ (自動產生) | ✅ |
| status | ✅ | ✅ (自動設定) | ✅ |
| itemCode | ✅ | ✅ | ✅ |
| mainCategory | ✅ | ✅ | ✅ |
| subCategory | ✅ | ✅ | ✅ |
| specCategory | ✅ | ✅ | ✅ |
| itemNameCN | ✅ | ✅ | ✅ |
| itemNameEN | ✅ | ✅ | ✅ |
| customerRef | ✅ | ✅ | ✅ |
| supplier | ✅ | ✅ | ✅ |
| material | ✅ | ✅ | ✅ |
| surfaceFinish | ✅ | ✅ | ✅ |
| dimensions | ✅ | ✅ | ✅ |
| packaging | ✅ | ✅ | ✅ |
| applicant | ✅ | ✅ (自動取得) | ✅ |
| approvalDate | ✅ | ✅ (審核時設定) | ✅ |
| rejectDate | ✅ | ✅ (退回時設定) | ✅ |
| rejectReason | ✅ | ✅ (退回時輸入) | ✅ |
| approver | ✅ | ✅ (審核時設定) | ✅ |

### ❌ Schema 中有但表單中缺少的欄位

| 欄位名稱 | Schema | 表單 | 建議 |
|---------|--------|------|------|
| moq | ✅ | ❌ | **需要加入表單** |
| unit | ✅ | ❌ | **需要加入表單** |

### 🔍 建議新增的欄位

#### 1. 版本控制與追蹤
- `version` - 資料版本號
- `updatedAt` - 最後更新時間
- `updatedBy` - 最後更新人
- `createdAt` - 建立時間（已有 submitDate，但可區分）

#### 2. 備註與說明
- `notes` - 備註欄位
- `internalNotes` - 內部備註（僅審核人員可見）
- `remarks` - 備註說明

#### 3. 附件與檔案
- `attachments` - 附件列表（圖片、文件等）
- `drawings` - 圖面檔案
- `specifications` - 規格文件

#### 4. 優先級與分類
- `priority` - 優先級（高、中、低）
- `tags` - 標籤（用於分類搜尋）
- `projectCode` - 專案代碼

#### 5. 成本與價格
- `unitPrice` - 單價
- `cost` - 成本
- `currency` - 幣別

#### 6. 供應商詳細資訊
- `supplierName` - 供應商名稱（目前只有代碼）
- `supplierContact` - 供應商聯絡人
- `supplierEmail` - 供應商Email
- `supplierPhone` - 供應商電話

#### 7. 客戶詳細資訊
- `customerName` - 客戶名稱
- `customerContact` - 客戶聯絡人
- `customerEmail` - 客戶Email

#### 8. 審核流程增強
- `approvalLevel` - 當前審核層級
- `approvalStatus` - 審核狀態（更詳細）
- `approvalHistory` - 審核歷史（關聯到 approvalLog）
- `nextApprover` - 下一審核人

#### 9. 其他實用欄位
- `estimatedDeliveryDate` - 預估交期
- `leadTime` - 交期（天數）
- `safetyStock` - 安全庫存
- `reorderPoint` - 再訂購點
- `storageLocation` - 儲存位置
- `barcode` - 條碼
- `qrCode` - QR Code

## 📊 Schema 完整性評估

### 當前 Schema 完整度：75%

**優點：**
- ✅ 基本欄位完整
- ✅ 包裝說明結構完整
- ✅ 審核流程欄位完整

**不足之處：**
- ❌ 缺少 MOQ 和 Unit 欄位在表單中
- ❌ 缺少版本控制
- ❌ 缺少附件管理
- ❌ 缺少成本相關欄位
- ❌ 缺少詳細的供應商/客戶資訊
- ❌ 缺少審核歷史關聯

## 🎯 建議優先順序

### 高優先級（必須）
1. ✅ 在表單中加入 MOQ 和 Unit 欄位
2. ✅ 加入版本控制欄位（updatedAt, updatedBy）
3. ✅ 加入備註欄位（notes）

### 中優先級（建議）
4. ⚠️ 加入附件管理欄位
5. ⚠️ 加入優先級欄位
6. ⚠️ 加入供應商/客戶詳細資訊

### 低優先級（未來擴展）
7. 📝 加入成本相關欄位
8. 📝 加入庫存相關欄位
9. 📝 加入條碼/QR Code 欄位

