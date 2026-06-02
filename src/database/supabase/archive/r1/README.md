# 已歸檔的 r1 文件

此目錄保存自 `src/database/supabase/r1/` 移出的歷史文件（2026-06-02）。

這些文件引用已刪除的 SQL 腳本與舊版 schema 路徑，**請勿再依此操作**。新環境請改用：

- **完整建庫**：`../supabase_schema_master.sql`
- **清空資料**：`../empty_all_table.sql`
- **刪除結構**：`../remove_all_table.sql`

| 檔案 | 說明 |
|------|------|
| `DYNAMIC_FORMS_README.md` | 舊版動態表單說明（引用已刪除的 `dynamic_forms_schema.sql`） |
| `REVIEW_MANAGEMENT_SETUP.md` | 舊版審核管理設定（引用已刪除的 `applications` 表相關視圖） |
| `UPDATE_UNIQUE_CONSTRAINT_README.md` | 舊版唯一約束更新說明（已併入 master schema） |
