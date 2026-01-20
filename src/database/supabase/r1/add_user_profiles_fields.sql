-- ============================================================================
-- 為 user_profiles 表添加 email 和 full_name 欄位
-- ============================================================================
-- 此腳本用於為現有的 user_profiles 表添加 email 和 full_name 欄位
-- 並從 auth.users 同步現有用戶的 email

-- 1. 添加 email 欄位
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS email VARCHAR(255);

-- 2. 添加 full_name 欄位
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS full_name VARCHAR(255);

-- 3. 創建索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_full_name ON user_profiles(full_name);

-- 4. 更新現有記錄的 email（從 auth.users 同步）
-- 注意：這需要管理員權限，因為需要訪問 auth.users 表
-- 如果無法執行，可以手動更新或通過 Supabase Dashboard 執行

-- 方法 1：使用 Supabase Dashboard 的 SQL Editor（推薦）
-- 執行以下 SQL（需要 service_role key）：
/*
UPDATE user_profiles up
SET email = au.email
FROM auth.users au
WHERE up.id = au.id AND (up.email IS NULL OR up.email != au.email);
*/

-- 方法 2：創建一個函數來同步 email（需要 SECURITY DEFINER）
CREATE OR REPLACE FUNCTION sync_user_profiles_email()
RETURNS void AS $$
BEGIN
  UPDATE user_profiles up
  SET email = au.email
  FROM auth.users au
  WHERE up.id = au.id AND (up.email IS NULL OR up.email != au.email);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 執行同步函數（需要管理員權限）
-- SELECT sync_user_profiles_email();

-- 5. 更新 handle_new_user 函數以包含 email 和 full_name
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, email, full_name, role, is_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
    NEW.email, -- 同步 email
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'), -- 同步 full_name
    COALESCE(NEW.raw_user_meta_data->>'role', 'applicant'),
    FALSE  -- 新註冊用戶預設未啟用，需等待管理員審核
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. 添加註釋
COMMENT ON COLUMN user_profiles.email IS 'Email（從 auth.users 同步）';
COMMENT ON COLUMN user_profiles.full_name IS '全名（從 auth.users raw_user_meta_data 同步）';
