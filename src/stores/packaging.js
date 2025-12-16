/**
 * Packaging Store
 * 包裝說明模板管理
 */
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { packagingService } from '@/api/services/packaging'

export const usePackagingStore = defineStore('packaging', () => {
  // State
  const templates = ref({})
  const packagingOptions = ref({})
  const loading = ref(false)

  // 類別預設值（備用，當 Supabase 載入失敗時使用）
  const categoryDefaults = {
    H: {
      productPackaging: ['塑膠袋', '產品標籤'],
      accessoriesContent: ['螺絲'],
      innerBox: ['印製ITEM NO.', '印製數量'],
      outerBox: ['瓦楞紙箱', '側嘜'],
    },
    S: {
      productPackaging: ['氣泡袋', 'PE/PP材質'],
      accessoriesContent: ['螺絲'],
      innerBox: ['印製ITEM NO.', '條碼'],
      outerBox: ['瓦楞紙箱', '易碎標誌'],
    },
    M: {
      productPackaging: ['彩盒包裝'],
      accessoriesContent: ['螺絲', '支架'],
      innerBox: ['印製ITEM NO.', '客戶Logo'],
      outerBox: ['瓦楞紙箱', '向上標誌'],
    },
  }

  // Actions
  /**
   * 載入所有包裝選項（從 Supabase）
   */
  async function loadPackagingOptions () {
    if (Object.keys(packagingOptions.value).length > 0) {
      return // 已經載入過
    }

    loading.value = true
    try {
      const grouped = await packagingService.getAllPackagingOptions()
      const options = {}

      for (const [categoryCode, data] of Object.entries(grouped)) {
        options[categoryCode] = data.options.map(opt => opt.code)
      }

      packagingOptions.value = options
    } catch (error) {
      console.error('載入包裝選項失敗', error)
      // 使用預設值
      packagingOptions.value = {
        productPackaging: ['塑膠袋', '氣泡袋', 'PE/PP材質', '彩盒包裝', '回收標誌', '產品標籤', '說明書'],
        accessoriesContent: ['螺絲', '支架', '蓋子/端蓋', '緩衝墊', '散裝'],
        accessories: ['供應商提供', '客戶提供', '標準配件', '選配配件'],
        innerBox: ['印製ITEM NO.', '印製數量', '條碼', '標籤', '客戶Logo'],
        outerBox: ['瓦楞紙箱', '側嘜', '客戶產品編號', '出貨嘜頭', '易碎標誌', '向上標誌'],
        transport: ['托盤/Pallet', '纏繞膜', '護角', '打包帶', 'EUDR文件'],
        container: ['20呎櫃', '40呎櫃', '40呎高櫃', '棧板出貨', '散裝裝櫃'],
        other: ['FSC認證', 'RoHS認證', 'REACH認證', 'ISO認證', '測試報告'],
      }
    } finally {
      loading.value = false
    }
  }

  /**
   * 載入模板（從 Supabase）
   */
  async function loadTemplate (category) {
    try {
      const defaults = await packagingService.getCategoryDefaults(category)
      return defaults || {}
    } catch (error) {
      console.error('載入模板失敗', error)
      return categoryDefaults[category] || {}
    }
  }

  /**
   * 取得模板（兼容舊接口）
   */
  function getTemplate (category) {
    return templates.value[category] || categoryDefaults[category] || {}
  }

  /**
   * 儲存模板（到 Supabase）
   */
  async function saveTemplate (category, templateData) {
    try {
      await packagingService.saveCategoryDefaults(category, templateData)
      // 同時更新本地快取
      templates.value[category] = templateData
    } catch (error) {
      console.error('儲存模板失敗', error)
      throw error
    }
  }

  /**
   * 取得預設選項（從 Supabase）
   */
  async function getDefaultOptions (category) {
    try {
      return await packagingService.getCategoryDefaults(category)
    } catch (error) {
      console.error('載入預設選項失敗', error)
      return categoryDefaults[category] || {}
    }
  }

  // 初始化：載入包裝選項
  loadPackagingOptions()

  return {
    // State
    templates,
    packagingOptions,
    categoryDefaults,
    loading,
    // Actions
    loadPackagingOptions,
    loadTemplate,
    getTemplate,
    saveTemplate,
    getDefaultOptions,
  }
})
