-- ============================================================================
-- 移除 system_options 表中指定 module 的記錄
-- 用途：刪除 user_management、material_application、auth 模組的選項
-- ============================================================================

-- 刪除 user_management 模組的所有記錄
DELETE FROM system_options
WHERE module = 'user_management';

-- 刪除 material_application 模組的所有記錄
DELETE FROM system_options
WHERE module = 'material_application';

-- 刪除 auth 模組的所有記錄
DELETE FROM system_options
WHERE module = 'auth';

-- 顯示刪除結果
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO deleted_count
    FROM system_options
    WHERE module IN ('user_management', 'material_application', 'auth');
    
    IF deleted_count = 0 THEN
        RAISE NOTICE '✅ 成功刪除所有指定模組的記錄';
    ELSE
        RAISE NOTICE '⚠️ 仍有 % 筆記錄未刪除', deleted_count;
    END IF;
END $$;
