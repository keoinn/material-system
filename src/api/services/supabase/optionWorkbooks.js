/**
 * Option Workbooks API Service - Supabase Implementation
 * 選項活頁簿 API 服務（Supabase 實作）
 */
import { isSupabaseAvailable, supabase } from '../../supabase.js'

/**
 * Supabase 實作
 */
export default {
  /**
   * 取得所有活頁簿列表
   */
  async getWorkbooks (filters = {}) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    let query = supabase
      .from('option_workbooks')
      .select('*')

    // 應用篩選條件
    if (filters.is_active !== undefined) {
      query = query.eq('is_active', filters.is_active)
    }

    if (filters.workbook_key) {
      query = query.eq('workbook_key', filters.workbook_key)
    }

    // 排序
    query = query.order('created_at', { ascending: false })

    const { data, error } = await query

    if (error) {
      throw error
    }

    return data || []
  },

  /**
   * 取得單一活頁簿（含欄位定義和資料）
   */
  async getWorkbook (idOrKey, includeColumns = true, includeRows = true) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 判斷是 ID 還是 workbook_key
    const isNumeric = /^\d+$/.test(String(idOrKey))
    const queryField = isNumeric ? 'id' : 'workbook_key'

    // 構建查詢
    let selectFields = '*'
    if (includeColumns && includeRows) {
      selectFields = '*, option_workbook_columns(*), option_workbook_rows(*)'
    } else if (includeColumns) {
      selectFields = '*, option_workbook_columns(*)'
    } else if (includeRows) {
      selectFields = '*, option_workbook_rows(*)'
    }

    let query = supabase
      .from('option_workbooks')
      .select(selectFields)
      .eq(queryField, idOrKey)
      .maybeSingle()

    const { data, error } = await query

    if (error && error.code !== 'PGRST116') {
      throw error
    }

    if (!data) {
      return null
    }

    // 處理欄位定義排序
    if (includeColumns && data.option_workbook_columns) {
      data.columns = data.option_workbook_columns.sort((a, b) => {
        const orderA = a.display_order || 0
        const orderB = b.display_order || 0
        return orderA - orderB
      })
      delete data.option_workbook_columns
    }

    // 處理資料行排序
    if (includeRows && data.option_workbook_rows) {
      data.rows = data.option_workbook_rows.sort((a, b) => {
        const orderA = a.display_order || 0
        const orderB = b.display_order || 0
        return orderA - orderB
      })
      delete data.option_workbook_rows
    }

    return data
  },

  /**
   * 建立活頁簿
   */
  async createWorkbook (workbookData) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 獲取當前用戶
    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser) {
      throw new Error('用戶未登入')
    }

    const { columns, rows, ...workbookInfo } = workbookData

    // 建立活頁簿
    const { data: workbook, error: workbookError } = await supabase
      .from('option_workbooks')
      .insert({
        ...workbookInfo,
        created_by_id: authUser.id,
        updated_by_id: authUser.id,
      })
      .select()
      .single()

    if (workbookError) {
      throw workbookError
    }

    // 建立欄位定義
    if (columns && columns.length > 0) {
      const columnsToInsert = columns.map((col, index) => ({
        workbook_id: workbook.id,
        ...col,
        display_order: col.display_order !== undefined ? col.display_order : index,
      }))

      const { error: columnsError } = await supabase
        .from('option_workbook_columns')
        .insert(columnsToInsert)

      if (columnsError) {
        // 如果欄位建立失敗，刪除已建立的活頁簿
        await supabase.from('option_workbooks').delete().eq('id', workbook.id)
        throw columnsError
      }
    }

    // 建立資料行
    if (rows && rows.length > 0) {
      const rowsToInsert = rows.map((row, index) => ({
        workbook_id: workbook.id,
        row_key: row.row_key || row.key || '',
        row_label: row.row_label || row.label || '',
        row_data: row.row_data || row.data || {},
        display_order: row.display_order !== undefined ? row.display_order : index,
        is_active: row.is_active !== undefined ? row.is_active : true,
        created_by_id: authUser.id,
        updated_by_id: authUser.id,
      }))

      const { error: rowsError } = await supabase
        .from('option_workbook_rows')
        .insert(rowsToInsert)

      if (rowsError) {
        // 如果資料行建立失敗，刪除已建立的活頁簿和欄位
        await supabase.from('option_workbook_columns').delete().eq('workbook_id', workbook.id)
        await supabase.from('option_workbooks').delete().eq('id', workbook.id)
        throw rowsError
      }
    }

    // 重新載入完整資料
    return await this.getWorkbook(workbook.id, true, true)
  },

  /**
   * 更新活頁簿
   */
  async updateWorkbook (id, updates) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 獲取當前用戶
    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser) {
      throw new Error('用戶未登入')
    }

    const { columns, rows, ...workbookInfo } = updates

    // 更新活頁簿基本資訊
    const { data: workbook, error: workbookError } = await supabase
      .from('option_workbooks')
      .update({
        ...workbookInfo,
        updated_by_id: authUser.id,
      })
      .eq('id', id)
      .select()
      .single()

    if (workbookError) {
      throw workbookError
    }

    // 更新欄位定義（如果提供）
    if (columns !== undefined) {
      // 刪除舊欄位
      await supabase
        .from('option_workbook_columns')
        .delete()
        .eq('workbook_id', id)

      // 建立新欄位
      if (columns.length > 0) {
        const columnsToInsert = columns.map((col, index) => ({
          workbook_id: id,
          ...col,
          display_order: col.display_order !== undefined ? col.display_order : index,
        }))

        const { error: columnsError } = await supabase
          .from('option_workbook_columns')
          .insert(columnsToInsert)

        if (columnsError) {
          throw columnsError
        }
      }
    }

    // 更新資料行（如果提供）
    if (rows !== undefined) {
      // 刪除舊資料行
      await supabase
        .from('option_workbook_rows')
        .delete()
        .eq('workbook_id', id)

      // 建立新資料行
      if (rows.length > 0) {
        const rowsToInsert = rows.map((row, index) => ({
          workbook_id: id,
          row_key: row.row_key || row.key || '',
          row_label: row.row_label || row.label || '',
          row_data: row.row_data || row.data || {},
          display_order: row.display_order !== undefined ? row.display_order : index,
          is_active: row.is_active !== undefined ? row.is_active : true,
          created_by_id: authUser.id,
          updated_by_id: authUser.id,
        }))

        const { error: rowsError } = await supabase
          .from('option_workbook_rows')
          .insert(rowsToInsert)

        if (rowsError) {
          throw rowsError
        }
      }
    }

    // 重新載入完整資料
    return await this.getWorkbook(id, true, true)
  },

  /**
   * 刪除活頁簿
   */
  async deleteWorkbook (id) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    const { error } = await supabase
      .from('option_workbooks')
      .delete()
      .eq('id', id)

    if (error) {
      throw error
    }
  },

  /**
   * 取得活頁簿的選項列表（用於表單選項）
   * @param {string} workbookKey - 活頁簿鍵值
   * @param {string} optionColumnKey - 選項欄位 key（可選，已廢棄，改用 columns 中的 is_key 和 is_label）
   * @returns {Promise<Array>} 選項列表，格式：[{ value, label, title, ... }]
   */
  async getWorkbookOptions (workbookKey, optionColumnKey = null) {
    if (!isSupabaseAvailable()) {
      throw new Error('Supabase 客戶端未初始化')
    }

    // 取得活頁簿（包含欄位定義和資料）
    const workbook = await this.getWorkbook(workbookKey, true, true)

    if (!workbook || !workbook.rows || !workbook.columns) {
      return []
    }

    // 找到標記為 is_key 和 is_label 的欄位
    const keyColumn = workbook.columns.find(col => col.is_key === true)
    const labelColumn = workbook.columns.find(col => col.is_label === true)

    if (!keyColumn || !labelColumn) {
      console.warn(`活頁簿 ${workbookKey} 缺少 is_key 或 is_label 欄位`)
      return []
    }

    // 過濾啟用的資料行，並映射為選項格式
    return workbook.rows
      .filter(row => row.is_active !== false)
      .map(row => {
        // value 從 is_key 欄位取得（row_key 或 row_data[keyColumn.column_key]）
        let optionValue = row.row_key
        if (keyColumn.column_key !== 'row_key' && row.row_data && row.row_data[keyColumn.column_key] !== undefined) {
          optionValue = row.row_data[keyColumn.column_key]
        }

        // label 從 is_label 欄位取得（row_label 或 row_data[labelColumn.column_key]）
        let optionLabel = row.row_label
        if (labelColumn.column_key !== 'row_label' && row.row_data && row.row_data[labelColumn.column_key] !== undefined) {
          optionLabel = row.row_data[labelColumn.column_key]
        }

        return {
          value: optionValue,
          label: optionLabel,
          title: optionLabel, // 兼容性：SelectField 使用 title
          key: row.row_key,
          data: row.row_data,
        }
      })
  },
}
