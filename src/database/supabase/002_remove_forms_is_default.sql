-- 移除 forms.is_default（改由申請介面僅顯示啟用中表單供使用者選擇）
DROP INDEX IF EXISTS idx_forms_is_default;
ALTER TABLE forms DROP COLUMN IF EXISTS is_default;
