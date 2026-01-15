# 重構文件總覽

## 📚 文件索引

本資料夾包含系統重構相關的所有文件，用於指導從零開始重構新系統。

### 主要文件

1. **[REFACTORING_PLAN.md](./REFACTORING_PLAN.md)** ⭐ **必讀**
   - 完整的重構計劃與步驟
   - 包含所有開發步驟的詳細 Prompt
   - 系統功能與特點分析
   - 技術架構分析
   - 參考檔案整理指南

2. **[SYSTEM_FEATURES.md](./SYSTEM_FEATURES.md)** ⭐ **必讀**
   - 系統功能與特點快速參考
   - 功能優先級矩陣
   - 開發建議
   - 快速查詢索引

### 閱讀順序建議

1. **先讀** `SYSTEM_FEATURES.md` - 快速了解系統功能
2. **再讀** `REFACTORING_PLAN.md` - 了解完整重構計劃
3. **開始開發** - 按照 `REFACTORING_PLAN.md` 中的步驟進行

---

## 🎯 重構目標

基於現有的物料編碼申請管理系統 V3.6，從零開始重構一個全新的、結構清晰的系統。

### 核心要求

- ✅ Vue3 + Vuetify + SCSS + Plain JavaScript
- ✅ 支援 Supabase 和 SQL Server + Axios 雙後端
- ✅ 動態表單系統（可自訂義表單和選項）
- ✅ 使用者管理模組與部門管理模組
- ✅ 審核流程與編輯紀錄

---

## 📋 系統功能摘要

### 核心功能模組

1. **動態表單系統** - 允許系統管理員透過資料庫定義表單結構
2. **使用者管理** - 完整的帳號、角色、權限管理
3. **部門管理** - 組織架構管理（需擴展）
4. **審核流程** - 多層級審核流程管理
5. **編輯紀錄** - 資料變更歷史追蹤
6. **物料申請** - 物料編碼申請與管理
7. **包裝管理** - 產品包裝說明管理
8. **附件管理** - 檔案上傳與管理
9. **Excel 匯出** - 多條件篩選與匯出
10. **系統設定** - 系統參數管理

詳細說明請參考 [SYSTEM_FEATURES.md](./SYSTEM_FEATURES.md)

---

## 🚀 快速開始

### 1. 了解系統

閱讀以下文件：
- [SYSTEM_FEATURES.md](./SYSTEM_FEATURES.md) - 系統功能清單
- [REFACTORING_PLAN.md](./REFACTORING_PLAN.md) - 完整重構計劃

### 2. 整理參考檔案

按照 `REFACTORING_PLAN.md` 中的「參考檔案整理指南」整理現有實作：
- Legacy 檔案（已在 `public/prototype/`）
- 資料庫結構檔案
- API 實作參考
- 組件實作參考
- Store 實作參考
- 頁面實作參考

### 3. 開始重構

按照 `REFACTORING_PLAN.md` 中的步驟進行：

**階段一：專案初始化與基礎架構**
- Step 1.1: 建立新專案基礎架構
- Step 1.2: 建立 API 層基礎架構

**階段二：核心功能模組開發**
- Step 2.1: 認證與使用者管理模組
- Step 2.2: 部門管理模組
- Step 2.3: 動態表單系統
- Step 2.4: 審核流程模組
- Step 2.5: 編輯紀錄模組

**階段三：業務功能模組開發**
- Step 3.1: 物料申請管理模組
- Step 3.2: 包裝管理模組
- Step 3.3: 附件管理模組
- Step 3.4: Excel 匯出模組

**階段四：系統設定與其他功能**
- Step 4.1: 系統設定模組
- Step 4.2: 供應商管理模組
- Step 4.3: 草稿功能

**階段五：整合測試與優化**
- Step 5.1: 雙後端整合測試
- Step 5.2: 效能優化
- Step 5.3: 文件撰寫

---

## 📁 參考檔案位置

### Legacy 檔案
- `public/prototype/` - Legacy HTML/JavaScript 版本
  - `material_system_v3.5_complete.html`
  - `v35_optimized_script.js`
  - `excel_processor_v35_optimized.py`
  - `README_V3.5_OPTIMIZED.md`

### 現有實作參考
- `src/components/` - 組件實作
- `src/pages/` - 頁面實作
- `src/stores/` - Store 實作
- `src/api/services/` - API 實作
- `src/database/supabase/` - 資料庫結構

### 建議整理的參考資料夾
按照 `REFACTORING_PLAN.md` 中的指南，建議建立：
```
doc/reference/
├── database/      # 資料庫結構參考
├── api/           # API 實作參考
├── components/    # 組件實作參考
├── stores/        # Store 實作參考
├── pages/         # 頁面實作參考
└── legacy/        # Legacy 檔案
```

---

## 💡 使用提示

### 如何使用 Prompt

每個步驟都包含詳細的 Prompt，可以直接：

1. **複製 Prompt** - 將 Prompt 內容複製給 AI 助手（如 Cursor、ChatGPT）
2. **提供參考檔案** - 如果 Prompt 中提到參考檔案，確保這些檔案可存取
3. **逐步執行** - 按照順序執行每個步驟，完成後再進行下一步
4. **測試驗證** - 每個步驟完成後進行測試，確保功能正常

### 開發建議

1. **優先順序**：先完成階段一和階段二（核心功能），再進行其他階段
2. **測試驅動**：每個模組完成後立即測試，不要累積問題
3. **文件同步**：開發過程中同步更新文件
4. **程式碼審查**：重要模組完成後進行程式碼審查

---

## 📝 注意事項

1. **保持功能一致性**：確保新系統功能與現有系統一致
2. **雙後端支援**：確保 Supabase 和 Axios 兩種後端都能正常運作
3. **資料庫遷移**：新系統需要執行資料庫遷移腳本
4. **向後相容**：考慮資料遷移和向後相容性
5. **安全性**：確保認證、授權、資料驗證等安全機制完整

---

## 🔗 相關文件

- [專案 README](../README.md) - 專案主要說明文件
- [API 文件](../src/api/README.md) - API 層說明
- [資料庫關聯圖](../src/database/database_relations.md) - 資料庫關聯說明
- [動態表單文件](../src/database/supabase/DYNAMIC_FORMS_README.md) - 動態表單系統說明

---

## 📞 支援

如有問題或建議，請參考：
- 現有程式碼實作
- 資料庫結構檔案
- Legacy 檔案說明

---

**建立日期**：2024  
**版本**：V3.6 重構計劃  
**狀態**：進行中
