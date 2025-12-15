/**
 * Packaging Store
 * 包裝說明模板管理
 */
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const usePackagingStore = defineStore('packaging', () => {
  // State
  const templates = ref({})

  // 預設包裝選項
  const packagingOptions = {
    productPackaging: [
      '塑膠袋',
      '氣泡袋',
      'PE/PP材質',
      '回收標誌',
      '產品標籤',
      '說明書',
    ],
    accessoriesContent: [
      '螺絲',
      '支架',
      '蓋子/端蓋',
      '緩衝墊',
      '散裝',
    ],
    accessories: [
      '供應商提供',
      '客戶提供',
      '標準配件',
      '選配配件',
    ],
    innerBox: [
      '印製ITEM NO.',
      '印製數量',
      '條碼',
      '標籤',
      '客戶Logo',
    ],
    outerBox: [
      '瓦楞紙箱',
      '側嘜',
      '客戶產品編號',
      '出貨嘜頭',
      '易碎標誌',
    ],
    transport: [
      '托盤/Pallet',
      '纏繞膜',
      '護角',
      '打包帶',
      'EUDR文件',
    ],
    container: [
      '20呎櫃',
      '40呎櫃',
      '40呎高櫃',
      '棧板出貨',
      '散裝裝櫃',
    ],
    other: [
      'FSC認證',
      'RoHS認證',
      'REACH認證',
      'ISO認證',
      '測試報告',
    ],
  }

  // 類別預設值
  const categoryDefaults = {
    H: {
      productPackaging: ['塑膠袋', '產品標籤'],
      accessoriesContent: ['螺絲'],
      innerBox: ['印製ITEM NO.', '印製數量'],
      outerBox: ['瓦楞紙箱', '側嘜'],
    },
    S: {
      productPackaging: ['氣泡袋', 'PE/PP材質'],
      accessoriesContent: ['螺絲', '說明書'],
      innerBox: ['印製ITEM NO.', '條碼'],
      outerBox: ['瓦楞紙箱', '易碎標誌'],
    },
    M: {
      productPackaging: ['彩盒包裝'],
      accessoriesContent: ['螺絲', '支架', '說明書'],
      innerBox: ['印製ITEM NO.', '客戶Logo'],
      outerBox: ['瓦楞紙箱', '向上標誌'],
    },
  }

  // Actions
  function loadTemplates () {
    try {
      const stored = localStorage.getItem('packagingTemplates_v35')
      if (stored) {
        templates.value = JSON.parse(stored)
      }
    } catch (error) {
      console.error('載入包裝模板失敗', error)
    }
  }

  function saveTemplates () {
    try {
      localStorage.setItem('packagingTemplates_v35', JSON.stringify(templates.value))
    } catch (error) {
      console.error('儲存包裝模板失敗', error)
    }
  }

  function getTemplate (category) {
    return templates.value[category] || categoryDefaults[category] || {}
  }

  function saveTemplate (category, templateData) {
    templates.value[category] = templateData
    saveTemplates()
  }

  function getDefaultOptions (category) {
    return categoryDefaults[category] || {}
  }

  // 初始化
  loadTemplates()

  return {
    // State
    templates,
    packagingOptions,
    categoryDefaults,
    // Actions
    loadTemplates,
    saveTemplates,
    getTemplate,
    saveTemplate,
    getDefaultOptions,
  }
})
