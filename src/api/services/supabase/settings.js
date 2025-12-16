/**
 * Settings API Service - Supabase Implementation
 * 系統設定相關 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有系統設定
   */
  async getSettings () {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('system_settings')
      .select('*')
      .order('setting_key', { ascending: true })

    if (error) {
      throw error
    }

    // 轉換為物件格式
    const settings = {}
    for (const item of data) {
      let value = item.setting_value

      // 根據類型轉換值
      switch (item.setting_type) {
        case 'number': {
          value = Number(value)
          break
        }
        case 'boolean': {
          value = value === 'true' || value === true
          break
        }
        case 'json': {
          try {
            value = JSON.parse(value)
          } catch {
            value = value
          }
          break
        }
        default: {
          value = value
        }
      }

      settings[item.setting_key] = value
    }

    return settings
  },

  /**
   * 取得單一設定值
   */
  async getSetting (key) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { data, error } = await supabase
      .from('system_settings')
      .select('setting_value, setting_type')
      .eq('setting_key', key)
      .single()

    if (error) {
      throw error
    }

    if (!data) {
      return null
    }

    // 根據類型轉換值
    let value = data.setting_value
    switch (data.setting_type) {
      case 'number': {
        value = Number(value)
        break
      }
      case 'boolean': {
        value = value === 'true' || value === true
        break
      }
      case 'json': {
        try {
          value = JSON.parse(value)
        } catch {
          value = value
        }
        break
      }
    }

    return value
  },

  /**
   * 更新設定值
   */
  async updateSetting (key, value, type = null) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷類型
    let settingType = type
    if (!settingType) {
      if (typeof value === 'number') {
        settingType = 'number'
      } else if (typeof value === 'boolean') {
        settingType = 'boolean'
      } else if (typeof value === 'object') {
        settingType = 'json'
        value = JSON.stringify(value)
      } else {
        settingType = 'string'
      }
    } else if (settingType === 'json') {
      value = JSON.stringify(value)
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const updatedById = user?.id

    const { data, error } = await supabase
      .from('system_settings')
      .upsert({
        setting_key: key,
        setting_value: String(value),
        setting_type: settingType,
        updated_by_id: updatedById,
      }, {
        onConflict: 'setting_key',
      })
      .select()
      .single()

    if (error) {
      throw error
    }

    return data
  },

  /**
   * 批量更新設定
   */
  async updateSettings (settings) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得當前使用者 ID
    const { data: { user } } = await supabase.auth.getUser()
    const updatedById = user?.id

    // 準備批量更新資料
    const updates = Object.entries(settings).map(([key, value]) => {
      let settingType = 'string'
      let settingValue = value

      if (typeof value === 'number') {
        settingType = 'number'
      } else if (typeof value === 'boolean') {
        settingType = 'boolean'
      } else if (typeof value === 'object') {
        settingType = 'json'
        settingValue = JSON.stringify(value)
      }

      return {
        setting_key: key,
        setting_value: String(settingValue),
        setting_type: settingType,
        updated_by_id: updatedById,
      }
    })

    const { data, error } = await supabase
      .from('system_settings')
      .upsert(updates, {
        onConflict: 'setting_key',
      })
      .select()

    if (error) {
      throw error
    }

    return data || []
  },
}

