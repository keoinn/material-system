/**
 * Users API Service - Supabase Implementation
 * 使用者管理相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有使用者列表
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getUsers (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 準備 RPC 函數參數
    const params = {}
    if (filters.role) {
      params.p_role = filters.role
    }
    if (filters.is_active !== undefined && filters.is_active !== null) {
      // 確保是 boolean 類型
      params.p_is_active = typeof filters.is_active === 'string'
        ? filters.is_active === 'true' || filters.is_active === '1'
        : Boolean(filters.is_active)
    }
    if (filters.search) {
      params.p_search = filters.search
    }

    // 使用 RPC 函數獲取使用者列表（包含 email）
    const { data, error } = await supabase.rpc('get_users_with_email', params)

    if (error) {
      // 如果 RPC 函數不存在，回退到直接查詢 user_profiles
      console.warn('RPC 函數 get_users_with_email 不存在，使用直接查詢', error)
      return this.getUsersFallback(filters)
    }

    return data || []
  },

  /**
   * 回退方法：直接查詢 user_profiles（不包含 email）
   * @param {object} filters - 篩選條件
   * @returns {Promise<Array>}
   */
  async getUsersFallback (filters = {}) {
    let query = supabase
      .from('user_profiles')
      .select('*')
      .order('created_at', { ascending: false })

    // 應用篩選條件
    if (filters.role) {
      query = query.eq('role', filters.role)
    }

    if (filters.is_active !== undefined && filters.is_active !== null) {
      const isActive = typeof filters.is_active === 'string'
        ? filters.is_active === 'true' || filters.is_active === '1'
        : Boolean(filters.is_active)
      query = query.eq('is_active', isActive)
    }

    if (filters.search) {
      query = query.ilike('username', `%${filters.search}%`)
    }

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得單一使用者
   * @param {string} id - 使用者 ID
   * @returns {Promise<Object>}
   */
  async getUser (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 使用 RPC 函數獲取所有使用者，然後過濾出指定 ID
    const { data, error } = await supabase.rpc('get_users_with_email', {})

    if (error) {
      // 如果 RPC 函數不存在，回退到直接查詢
      console.warn('RPC 函數 get_users_with_email 不存在，使用直接查詢', error)
      const { data: profileData, error: profileError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', id)
        .single()

      if (profileError) {
        throw profileError
      }

      return profileData
    }

    // 從結果中找出指定 ID 的使用者
    const user = (data || []).find(u => u.id === id)
    return user || null
  },

  /**
   * 建立使用者（包含 auth.users 和 user_profiles）
   * @param {object} userData - 使用者資料
   * @returns {Promise<Object>}
   */
  async createUser (userData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 使用 signUp 創建用戶（需要管理員權限或通過 RPC 函數）
    // 注意：這會發送確認郵件，如果需要立即啟用，需要通過後端 API
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: userData.email,
      password: userData.password,
      options: {
        data: {
          username: userData.username,
          role: userData.role || 'applicant',
        },
        email_redirect_to: undefined, // 不需要重定向
      },
    })

    if (authError) {
      throw authError
    }

    if (!authData.user) {
      throw new Error('創建用戶失敗')
    }

    // 更新 user_profiles（trigger 會自動創建，但我們需要更新額外欄位）
    // 確保 is_active 是 boolean 類型
    const isActive = userData.is_active !== undefined
      ? (typeof userData.is_active === 'string'
          ? userData.is_active === 'true' || userData.is_active === '1'
          : Boolean(userData.is_active))
      : true

    const { data: profile, error: profileError } = await supabase
      .from('user_profiles')
      .update({
        username: userData.username,
        role: userData.role || 'applicant',
        department: userData.department || null,
        position: userData.position || null,
        phone: userData.phone || null,
        is_active: isActive,
      })
      .eq('id', authData.user.id)
      .select()
      .single()

    if (profileError) {
      // 如果更新失敗，嘗試直接插入
      const { data: newProfile, error: insertError } = await supabase
        .from('user_profiles')
        .insert({
          id: authData.user.id,
          username: userData.username,
          role: userData.role || 'applicant',
          department: userData.department || null,
          position: userData.position || null,
          phone: userData.phone || null,
          is_active: isActive,
        })
        .select()
        .single()

      if (insertError) {
        throw insertError
      }

      return {
        ...newProfile,
        email: userData.email,
      }
    }

    return {
      ...profile,
      email: userData.email,
    }
  },

  /**
   * 更新使用者資料
   * @param {string} id - 使用者 ID
   * @param {object} updates - 更新資料
   * @returns {Promise<Object>}
   */
  async updateUser (id, updates) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 1. 更新 user_profiles
    const profileUpdates = {}
    if (updates.username !== undefined) profileUpdates.username = updates.username
    if (updates.role !== undefined) profileUpdates.role = updates.role
    if (updates.department !== undefined) profileUpdates.department = updates.department || null
    if (updates.position !== undefined) profileUpdates.position = updates.position || null
    if (updates.phone !== undefined) profileUpdates.phone = updates.phone || null
    if (updates.avatar_url !== undefined) profileUpdates.avatar_url = updates.avatar_url || null
    // 確保 is_active 是 boolean 類型
    if (updates.is_active !== undefined) {
      // 轉換為 boolean：如果是字符串 "true"/"false"，轉換為 boolean
      if (typeof updates.is_active === 'string') {
        profileUpdates.is_active = updates.is_active === 'true' || updates.is_active === '1'
      } else {
        profileUpdates.is_active = Boolean(updates.is_active)
      }
    }

    const { data: profile, error: profileError } = await supabase
      .from('user_profiles')
      .update(profileUpdates)
      .eq('id', id)
      .select()
      .single()

    if (profileError) {
      throw profileError
    }

    // 注意：前端無法直接更新 auth.users 的 email 或 password
    // 需要通過後端 API 或 Supabase Edge Function
    // 這裡只更新 user_profiles
    return profile
  },

  /**
   * 刪除使用者
   * @param {string} id - 使用者 ID
   * @returns {Promise<void>}
   */
  async deleteUser (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 注意：前端無法直接刪除 auth.users
    // 這裡只標記為停用（is_active = false）而不是真正刪除
    // 如果需要真正刪除，需要通過後端 API 或 Supabase Edge Function
    const { error } = await supabase
      .from('user_profiles')
      .update({ is_active: false })
      .eq('id', id)

    if (error) {
      throw error
    }

    // 如果需要真正刪除，可以調用 RPC 函數或後端 API
    // 這裡只做標記刪除
  },

  /**
   * 啟用/停用使用者
   * @param {string} id - 使用者 ID
   * @param {boolean} isActive - 是否啟用
   * @returns {Promise<Object>}
   */
  async toggleUserActive (id, isActive) {
    return this.updateUser(id, { is_active: isActive })
  },
}

