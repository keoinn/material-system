/**
 * Auth API Service - Supabase Implementation
 * 認證相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 登入
   */
  async login (email, password) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      throw error
    }

    // 儲存 session
    if (data.session) {
      localStorage.setItem('supabase.auth.token', data.session.access_token)
    }

    return {
      user: data.user,
      session: data.session,
    }
  },

  /**
   * 登出
   */
  async logout () {
    if (!isSupabaseAvailable()) {
      localStorage.removeItem('supabase.auth.token')
      return
    }

    const { error } = await supabase.auth.signOut()

    if (error) {
      throw error
    }

    localStorage.removeItem('supabase.auth.token')
  },

  /**
   * 取得當前使用者
   */
  async getCurrentUser () {
    if (!isSupabaseAvailable()) {
      return null
    }

    const { data: { user }, error } = await supabase.auth.getUser()

    if (error || !user) {
      return null
    }

    return user
  },

  /**
   * 取得當前 Session
   */
  async getSession () {
    if (!isSupabaseAvailable()) {
      return null
    }

    const { data: { session }, error } = await supabase.auth.getSession()

    if (error || !session) {
      return null
    }

    return session
  },

  /**
   * 註冊新使用者
   */
  async signUp (userData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase.auth.signUp({
      email: userData.email,
      password: userData.password,
      options: {
        data: {
          username: userData.username,
          role: userData.role || 'applicant',
        },
      },
    })

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 重設密碼
   */
  async resetPassword (email) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    })

    if (error) {
      throw error
    }
  },
}

