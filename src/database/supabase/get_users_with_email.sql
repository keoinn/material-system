-- ============================================================================
-- RPC 函數：獲取使用者列表（包含 email）
-- ============================================================================
-- 此函數用於從 user_profiles 和 auth.users 獲取使用者資料，包含 email
-- 需要 SECURITY DEFINER 權限來訪問 auth.users

CREATE OR REPLACE FUNCTION public.get_users_with_email(
  p_role VARCHAR DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL,
  p_search VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  username VARCHAR,
  role VARCHAR,
  department VARCHAR,
  "position" VARCHAR,
  phone VARCHAR,
  avatar_url VARCHAR,
  is_active BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  last_login TIMESTAMP WITH TIME ZONE,
  last_login_ip VARCHAR,
  email VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    up.id,
    up.username,
    up.role,
    up.department,
    up.position,
    up.phone,
    up.avatar_url,
    up.is_active,
    up.created_at,
    up.updated_at,
    up.last_login,
    up.last_login_ip,
    au.email
  FROM public.user_profiles up
  LEFT JOIN auth.users au ON up.id = au.id
  WHERE 
    (p_role IS NULL OR up.role = p_role)
    AND (p_is_active IS NULL OR up.is_active = p_is_active)
    AND (p_search IS NULL OR up.username ILIKE '%' || p_search || '%' OR au.email ILIKE '%' || p_search || '%')
  ORDER BY up.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_users_with_email IS '獲取使用者列表（包含 email），需要 SECURITY DEFINER 權限來訪問 auth.users';

