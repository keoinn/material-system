# Schema 改進建議總結

## 🔍 發現的問題

### 1. ❌ 表單中缺少的欄位（高優先級）

#### MOQ 和 Unit 欄位
- **問題**：Schema 中定義了 `moq` 和 `unit`，但表單中沒有這些欄位
- **影響**：無法記錄最小訂購量和單位資訊
- **建議**：在 `MaterialApplicationForm.vue` 的「尺寸規格」區塊後新增「訂購資訊」區塊

```vue
<!-- 訂購資訊 -->
<div class="form-section">
  <h3>訂購資訊</h3>
  <v-row>
    <v-col cols="12" md="6">
      <v-text-field
        v-model.number="form.moq"
        label="最小訂購量 (MOQ)"
        type="number"
        variant="outlined"
      />
    </v-col>
    <v-col cols="12" md="6">
      <v-select
        v-model="form.unit"
        label="單位"
        :items="units"
        variant="outlined"
      />
    </v-col>
  </v-row>
</div>
```

### 2. ⚠️ Schema 需要加強的欄位

#### 版本控制欄位
- `version` - 資料版本號
- `createdAt` - 建立時間（與 submitDate 區分）
- `updatedAt` - 最後更新時間
- `updatedBy` - 最後更新人

#### 備註欄位
- `notes` - 一般備註
- `internalNotes` - 內部備註（僅審核人員可見）

#### 審核流程增強
- `approvalLevel` - 當前審核層級
- `approvalStatus` - 詳細審核狀態
- `nextApprover` - 下一審核人
- `priority` - 優先級

## 📊 Schema 完整性評估

### 當前狀態：75% 完整

**已實現：**
- ✅ 基本申請欄位完整
- ✅ 包裝說明結構完整
- ✅ 審核流程基本欄位完整

**需要改進：**
- ❌ 表單缺少 MOQ 和 Unit 欄位
- ⚠️ 缺少版本控制機制
- ⚠️ 缺少備註功能
- ⚠️ 缺少附件管理
- ⚠️ 缺少詳細的供應商/客戶資訊

## 🎯 建議實施順序

### 階段一：立即修正（必須）
1. ✅ 在表單中加入 MOQ 和 Unit 欄位
2. ✅ 更新 form 物件和 submitApplication 函數

### 階段二：基礎增強（建議）
3. ⚠️ 加入版本控制欄位（updatedAt, updatedBy）
4. ⚠️ 加入備註欄位（notes）
5. ⚠️ 加入優先級欄位（priority）

### 階段三：功能擴展（未來）
6. 📝 加入附件管理功能
7. 📝 加入供應商/客戶詳細資訊管理
8. 📝 加入成本相關欄位
9. 📝 加入庫存相關欄位

## 📝 新增的 Schema 表

已新增以下 Schema 表：
- `attachmentSchema` - 附件管理
- `supplierSchema` - 供應商詳細資訊
- `customerSchema` - 客戶詳細資訊
- `draftSchema` - 草稿管理

## 🔗 關聯關係

建議的資料表關聯：
- `applications` ← `attachments` (一對多)
- `applications` ← `approvalLog` (一對多)
- `applications` → `supplier` (多對一)
- `applications` → `customer` (多對一)
- `applications` → `user` (申請人、審核人)

