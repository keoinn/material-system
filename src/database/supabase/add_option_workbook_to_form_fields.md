# 表單欄位選項活頁簿功能說明

## 概述

此功能允許在表單管理的欄位設定中，為下拉式選單（select）和多選下拉（multiselect）欄位指定使用選項活頁簿作為選項來源。

## 資料庫結構

**不需要修改資料庫結構**，因為選項活頁簿的設定儲存在 `form_fields` 表的 `field_config` JSONB 欄位中。

### field_config 結構

當欄位使用選項活頁簿時，`field_config` 會包含以下欄位：

```json
{
  "option_workbook_key": "workbook_key_value",
  "cols": 12,
  // ... 其他設定
}
```

當欄位不使用選項活頁簿時，`field_config` 會包含：

```json
{
  "options": [
    { "value": "value1", "label": "Label 1" },
    { "value": "value2", "label": "Label 2" }
  ],
  "cols": 12,
  // ... 其他設定
}
```

## 功能說明

1. **在表單設計器中**：
   - 當欄位類型為 `select` 或 `multiselect` 時，會在「加入模板」v-switch 之後顯示「選項活頁簿」v-switch
   - 當「選項活頁簿」v-switch 為 `true` 時，會顯示一個下拉式選單
   - 下拉式選單顯示所有啟用的選項活頁簿，選項顯示為「活頁簿名稱（活頁簿鍵值）」
   - 選擇活頁簿後，該欄位的選項將從選項活頁簿中動態載入

2. **資料儲存**：
   - 選中的活頁簿鍵值儲存在 `field_config.option_workbook_key` 中
   - 如果使用選項活頁簿，則不會儲存手動設定的選項（`options` 欄位會被移除）
   - 如果不使用選項活頁簿，則 `option_workbook_key` 欄位會被移除

## 使用方式

1. 在表單管理中編輯表單
2. 編輯或新增一個下拉式選單或多選下拉欄位
3. 在「加入模板」v-switch 之後，找到「選項活頁簿」v-switch
4. 開啟「選項活頁簿」v-switch
5. 從下拉式選單中選擇要使用的活頁簿
6. 儲存欄位設定

## 注意事項

- 選項活頁簿功能僅適用於 `select` 和 `multiselect` 欄位類型
- 使用選項活頁簿時，手動設定的選項會被清空
- 選項活頁簿必須是啟用狀態（`is_active = true`）才會出現在下拉式選單中
- 選項活頁簿的資料會動態載入，無需手動更新表單欄位設定
