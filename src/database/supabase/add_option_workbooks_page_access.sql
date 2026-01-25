-- ============================================================================
-- 為現有角色添加「選項活頁簿」頁面權限
-- 用途：為所有現有角色添加「選項活頁簿」頁面權限
-- 執行時間：在新增「選項活頁簿」功能後執行
-- ============================================================================

-- 為所有現有角色添加「選項活頁簿」頁面權限
-- 預設：系統管理員可以訪問，其他角色需要手動設定
INSERT INTO role_page_access (role_id, page_code, page_name, is_accessible)
SELECT 
  r.id,
  'option-workbooks',
  '選項活頁簿',
  CASE 
    WHEN r.role_code = 'admin' THEN TRUE  -- 系統管理員預設可以訪問
    ELSE FALSE  -- 其他角色預設不可訪問，需要手動設定
  END
FROM roles r
WHERE NOT EXISTS (
  SELECT 1 
  FROM role_page_access rpa 
  WHERE rpa.role_id = r.id 
  AND rpa.page_code = 'option-workbooks'
)
ON CONFLICT (role_id, page_code) DO NOTHING;

-- 如果希望所有角色都可以訪問，可以使用以下 SQL（取消註解）：
-- INSERT INTO role_page_access (role_id, page_code, page_name, is_accessible)
-- SELECT 
--   r.id,
--   'option-workbooks',
--   '選項活頁簿',
--   TRUE  -- 所有角色都可以訪問
-- FROM roles r
-- WHERE NOT EXISTS (
--   SELECT 1 
--   FROM role_page_access rpa 
--   WHERE rpa.role_id = r.id 
--   AND rpa.page_code = 'option-workbooks'
-- )
-- ON CONFLICT (role_id, page_code) DO NOTHING;
