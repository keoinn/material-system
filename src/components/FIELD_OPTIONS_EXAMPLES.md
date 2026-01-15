# 欄位選項設定範例

## 概述

對於需要選項的欄位類型（select, multiselect, checkbox, radio），需要在「選項設定」中定義選項列表。

## 支援的欄位類型

- **select** - 下拉選單（單選）
- **multiselect** - 多選下拉選單
- **checkbox** - 複選框
- **radio** - 單選框

## 選項格式

每個選項包含兩個屬性：
- **值 (value)** - 儲存在資料庫中的值
- **標籤 (label)** - 顯示給使用者看的文字

## 範例

### 範例 1：基本選項（狀態選擇）

適用於：select, radio

```
值：active    標籤：啟用
值：inactive  標籤：停用
值：pending   標籤：待處理
```

### 範例 2：多選標籤（標籤選擇）

適用於：multiselect, checkbox

```
值：tag1  標籤：標籤 1
值：tag2  標籤：標籤 2
值：tag3  標籤：標籤 3
值：tag4  標籤：標籤 4
```

### 範例 3：產品分類（下拉選單）

適用於：select

```
值：H  標籤：H - Handle (把手)
值：S  標籤：S - Slide (滑軌)
值：M  標籤：M - Module/Assy (模組)
值：D  標籤：D - Decorative Hardware (裝飾五金)
值：F  標籤：F - Functional Hardware (功能五金)
值：B  標籤：B - Builders Hardware (建築五金)
值：I  標籤：I - Industrial Parts Solution (工業零件)
值：O  標籤：O - Others (其他)
```

### 範例 4：優先級選擇（單選框）

適用於：radio

```
值：HIGH    標籤：高
值：MEDIUM  標籤：中
值：LOW     標籤：低
```

### 範例 5：包裝選項（多選複選框）

適用於：checkbox, multiselect

```
值：plastic_bag      標籤：塑膠袋
值：bubble_wrap      標籤：氣泡袋
值：color_box        標籤：彩盒包裝
值：recycle_symbol   標籤：回收標誌
值：product_label    標籤：產品標籤
值：manual           標籤：說明書
```

## 在表單設計器中使用

### 步驟 1：選擇欄位類型

選擇需要選項的欄位類型（select, multiselect, checkbox, radio）

### 步驟 2：新增選項

1. 點擊「新增選項」按鈕
2. 填寫「值」和「標籤」
3. 重複步驟 1-2 新增更多選項

### 步驟 3：使用範例（可選）

點擊「載入範例」按鈕可以快速載入預設的範例選項，然後根據需求修改。

### 步驟 4：調整順序

選項的順序會影響顯示順序，可以透過刪除和重新新增來調整。

## 資料儲存格式

### Select / Radio（單選）

儲存格式：字串
```javascript
"active"  // 單一值
```

### Multiselect / Checkbox（多選）

儲存格式：陣列
```javascript
["tag1", "tag2", "tag3"]  // 多個值的陣列
```

## 實際應用範例

### 物料申請表單的產品大類

**欄位設定：**
- 欄位鍵值：`main_category`
- 欄位類型：`select`
- 欄位標籤：`產品大類`
- 必填：是

**選項設定：**
```
值：H  標籤：H - Handle (把手)
值：S  標籤：S - Slide (滑軌)
值：M  標籤：M - Module/Assy (模組)
值：D  標籤：D - Decorative Hardware (裝飾五金)
值：F  標籤：F - Functional Hardware (功能五金)
值：B  標籤：B - Builders Hardware (建築五金)
值：I  標籤：I - Industrial Parts Solution (工業零件)
值：O  標籤：O - Others (其他)
```

### 物料申請表單的標籤（多選）

**欄位設定：**
- 欄位鍵值：`tags`
- 欄位類型：`multiselect`
- 欄位標籤：`標籤`
- 必填：否

**選項設定：**
```
值：urgent     標籤：緊急
值：important  標籤：重要
值：new        標籤：新產品
值：custom     標籤：客製化
值：standard   標籤：標準品
```

## 注意事項

1. **值必須唯一**：同一欄位內的選項值不能重複
2. **值建議使用英文**：值會儲存在資料庫中，建議使用英文或代碼
3. **標籤可以使用中文**：標籤是顯示給使用者看的，可以使用中文
4. **多選欄位**：multiselect 和 checkbox 會儲存為陣列格式
5. **必填驗證**：如果欄位設為必填，使用者必須至少選擇一個選項

## 快速建立選項的技巧

1. **使用範例**：點擊「載入範例」快速建立基本選項
2. **批量複製**：可以從 Excel 或其他工具複製選項列表
3. **使用代碼**：值使用簡短的代碼，標籤使用完整描述

## 常見問題

### Q: 選項可以動態載入嗎？

A: 可以，透過 `field_config` 中的 `source` 設定可以動態載入選項，例如從資料庫查詢。

### Q: 可以設定選項的預設值嗎？

A: 可以，在欄位的「預設值」欄位中設定。

### Q: 多選欄位的值如何儲存？

A: 多選欄位（multiselect, checkbox）會儲存為 JSON 陣列格式，例如：`["tag1", "tag2"]`

### Q: 可以設定選項的圖示或顏色嗎？

A: 目前不支援，但可以透過 `field_config` 的 JSON 設定擴展功能。
