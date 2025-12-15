/**
 * Database Schema
 *
 * 定義系統所需的資料庫結構
 * 目前僅定義 schema，尚未實現實際功能
 */

/**
 * 申請資料表
 */
export const applicationsSchema = {
  // === 基本識別資訊 ===
  id: 'string', // 申請ID
  itemCode: 'string', // 料號（系統自動產生）

  // === 分類資訊 ===
  mainCategory: 'string', // 大類 (H, S, M, D, F, B, I, O)
  subCategory: 'string', // 中類
  specCategory: 'string', // 小類

  // === 物料基本資訊 ===
  itemNameCN: 'string', // 中文名稱
  itemNameEN: 'string', // 英文名稱
  material: 'string', // 基本材質
  surfaceFinish: 'string', // 表面處理

  // === 尺寸規格 ===
  dimensions: {
    length: 'number', // 長度 (mm)
    width: 'number', // 寬度 (mm)
    height: 'number', // 高度 (mm)
    weight: 'number', // 重量 (g)
  },

  // === 訂購資訊 ===
  moq: 'number', // 最小訂購量 (Minimum Order Quantity)
  unit: 'string', // 單位 (PCS, SET, PAIR, KG, etc.)

  // === 客戶資訊 ===
  customerRef: 'string', // 客戶參考貨號
  customerName: 'string', // 客戶名稱（建議新增）
  customerContact: 'string', // 客戶聯絡人（建議新增）
  customerEmail: 'string', // 客戶Email（建議新增）

  // === 供應商資訊 ===
  supplier: 'string', // 供應商代碼
  supplierName: 'string', // 供應商名稱（建議新增）
  supplierContact: 'string', // 供應商聯絡人（建議新增）
  supplierEmail: 'string', // 供應商Email（建議新增）
  supplierPhone: 'string', // 供應商電話（建議新增）

  // === 包裝說明 ===
  packaging: {
    // 1. 個別產品包裝
    productPackaging: {
      options: 'array', // 勾選的選項
      description: 'string', // 額外說明
    },
    // 2. 配件內容
    accessoriesContent: {
      options: 'array',
      description: 'string',
    },
    // 3. 配件
    accessories: {
      options: 'array',
      description: 'string',
    },
    // 4. 內盒
    innerBox: {
      options: 'array',
      description: 'string',
    },
    // 5. 外箱
    outerBox: {
      options: 'array',
      description: 'string',
    },
    // 6. 運輸與托盤要求
    transport: {
      options: 'array',
      description: 'string',
    },
    // 7. 裝櫃要求
    container: {
      options: 'array',
      description: 'string',
    },
    // 8. 其他說明
    other: {
      options: 'array',
      description: 'string',
    },
  },

  // === 附件與檔案 ===
  attachments: 'array', // 附件列表（建議新增）
  // attachments: [
  //   {
  //     id: 'string',
  //     fileName: 'string',
  //     fileType: 'string',
  //     fileSize: 'number',
  //     uploadDate: 'datetime',
  //     uploadedBy: 'string',
  //     fileUrl: 'string',
  //   }
  // ],

  // === 備註與說明 ===
  notes: 'string', // 備註（建議新增）
  internalNotes: 'string', // 內部備註（僅審核人員可見，建議新增）

  // === 申請流程資訊 ===
  submitDate: 'datetime', // 提交日期
  status: 'string', // PENDING|APPROVED|REJECTED
  applicant: 'string', // 申請人
  priority: 'string', // 優先級：HIGH|MEDIUM|LOW（建議新增）

  // === 審核資訊 ===
  approvalLevel: 'number', // 當前審核層級（建議新增）
  approvalStatus: 'string', // 審核狀態：PENDING|IN_REVIEW|APPROVED|REJECTED（建議新增）
  approvalDate: 'datetime', // 核准日期
  rejectDate: 'datetime', // 退回日期
  rejectReason: 'string', // 退回原因
  approver: 'string', // 審核人
  nextApprover: 'string', // 下一審核人（建議新增）

  // === 版本控制 ===
  version: 'number', // 資料版本號（建議新增）
  createdAt: 'datetime', // 建立時間（建議新增，與 submitDate 區分）
  updatedAt: 'datetime', // 最後更新時間（建議新增）
  updatedBy: 'string', // 最後更新人（建議新增）

  // === 成本資訊（未來擴展） ===
  unitPrice: 'number', // 單價（建議新增）
  cost: 'number', // 成本（建議新增）
  currency: 'string', // 幣別：TWD|USD|CNY（建議新增）

  // === 庫存資訊（未來擴展） ===
  safetyStock: 'number', // 安全庫存（建議新增）
  reorderPoint: 'number', // 再訂購點（建議新增）
  storageLocation: 'string', // 儲存位置（建議新增）

  // === 其他資訊 ===
  tags: 'array', // 標籤（建議新增）
  projectCode: 'string', // 專案代碼（建議新增）
  barcode: 'string', // 條碼（建議新增）
  qrCode: 'string', // QR Code（建議新增）
  estimatedDeliveryDate: 'date', // 預估交期（建議新增）
  leadTime: 'number', // 交期（天數）（建議新增）
}

/**
 * 編碼計數器表
 */
export const codeCounterSchema = {
  key: 'string', // 格式: {大類}{中類}.{小類} 例如: H01.C
  counter: 'number', // 當前計數值
  lastUsedDate: 'datetime', // 最後使用日期（建議新增）
  lastUsedBy: 'string', // 最後使用人（建議新增）
}

/**
 * 包裝模板表
 */
export const packagingTemplateSchema = {
  id: 'string', // 模板ID（建議新增）
  category: 'string', // 產品大類
  section: 'string', // 包裝類別
  defaultOptions: 'array', // 預設勾選的選項
  defaultDescription: 'string', // 預設說明文字
  isActive: 'boolean', // 是否啟用（建議新增）
  createdBy: 'string', // 建立人（建議新增）
  createdAt: 'datetime', // 建立時間（建議新增）
  updatedAt: 'datetime', // 更新時間（建議新增）
}

/**
 * 系統設定表
 */
export const systemSettingsSchema = {
  serialDigits: 'number', // 流水號位數 (4, 5, 6)
  serialStart: 'string', // 流水號起始值
  autoApprove: 'boolean', // 自動審核
  emailNotify: 'boolean', // Email通知
  approvalLevel: 'number', // 審核層級
}

/**
 * 使用者表
 */
export const userSchema = {
  id: 'string', // 使用者ID
  username: 'string', // 使用者名稱
  email: 'string', // Email
  password: 'string', // 密碼（加密後）
  role: 'string', // 角色 (admin, approver, applicant)
  department: 'string', // 部門
  position: 'string', // 職位（建議新增）
  phone: 'string', // 電話（建議新增）
  avatar: 'string', // 頭像URL（建議新增）
  isActive: 'boolean', // 是否啟用（建議新增）
  createdAt: 'datetime', // 建立時間
  updatedAt: 'datetime', // 更新時間（建議新增）
  lastLogin: 'datetime', // 最後登入時間
  lastLoginIp: 'string', // 最後登入IP（建議新增）
}

/**
 * 審核記錄表
 */
export const approvalLogSchema = {
  id: 'string', // 記錄ID
  applicationId: 'string', // 申請ID（關聯到 applications）
  action: 'string', // APPROVE|REJECT|SUBMIT|RETURN
  approver: 'string', // 審核人
  approverName: 'string', // 審核人名稱（建議新增）
  approverRole: 'string', // 審核人角色（建議新增）
  level: 'number', // 審核層級（建議新增）
  reason: 'string', // 原因/備註
  comment: 'string', // 審核意見（建議新增）
  timestamp: 'datetime', // 時間戳記
  ipAddress: 'string', // IP位址（建議新增，用於審計）
  userAgent: 'string', // 使用者代理（建議新增，用於審計）
}

/**
 * 匯出記錄表
 */
export const exportLogSchema = {
  id: 'string', // 記錄ID
  category: 'string', // 匯出類別
  status: 'string', // 匯出狀態：ALL|APPROVED|PENDING|REJECTED
  startDate: 'date', // 開始日期
  endDate: 'date', // 結束日期
  recordCount: 'number', // 記錄數量
  fileName: 'string', // 檔案名稱
  filePath: 'string', // 檔案路徑（建議新增）
  fileSize: 'number', // 檔案大小（bytes）（建議新增）
  format: 'string', // 檔案格式：CSV|XLSX|PDF（建議新增）
  exportedBy: 'string', // 匯出人
  exportedAt: 'datetime', // 匯出時間
  downloadCount: 'number', // 下載次數（建議新增）
}

/**
 * 附件表
 */
export const attachmentSchema = {
  id: 'string', // 附件ID
  applicationId: 'string', // 申請ID（關聯到 applications）
  fileName: 'string', // 檔案名稱
  originalFileName: 'string', // 原始檔案名稱
  fileType: 'string', // 檔案類型：image|document|drawing|other
  fileSize: 'number', // 檔案大小（bytes）
  mimeType: 'string', // MIME類型
  fileUrl: 'string', // 檔案URL
  thumbnailUrl: 'string', // 縮圖URL（圖片用）
  uploadedBy: 'string', // 上傳人
  uploadedAt: 'datetime', // 上傳時間
  description: 'string', // 檔案說明
}

/**
 * 供應商表
 */
export const supplierSchema = {
  id: 'string', // 供應商ID
  code: 'string', // 供應商代碼
  name: 'string', // 供應商名稱
  contactPerson: 'string', // 聯絡人
  email: 'string', // Email
  phone: 'string', // 電話
  address: 'string', // 地址
  country: 'string', // 國家
  isActive: 'boolean', // 是否啟用
  createdAt: 'datetime', // 建立時間
  updatedAt: 'datetime', // 更新時間
}

/**
 * 客戶表
 */
export const customerSchema = {
  id: 'string', // 客戶ID
  code: 'string', // 客戶代碼
  name: 'string', // 客戶名稱
  contactPerson: 'string', // 聯絡人
  email: 'string', // Email
  phone: 'string', // 電話
  address: 'string', // 地址
  country: 'string', // 國家
  isActive: 'boolean', // 是否啟用
  createdAt: 'datetime', // 建立時間
  updatedAt: 'datetime', // 更新時間
}

/**
 * 草稿表
 */
export const draftSchema = {
  id: 'string', // 草稿ID
  applicationData: 'object', // 申請資料（JSON格式）
  savedBy: 'string', // 儲存人
  savedAt: 'datetime', // 儲存時間
  lastModifiedAt: 'datetime', // 最後修改時間
}

// ============================================================================
// 系統選項定義 (System Options)
// ============================================================================
// 所有表單和下拉選單使用的選項定義
// ============================================================================

/**
 * 產品大類選項
 * 用於物料申請表單的產品大類選擇
 */
export const mainCategoryOptions = [
  { value: 'H', label: 'H - Handle (把手)', description: '各類把手、拉手、旋鈕' },
  { value: 'S', label: 'S - Slide (滑軌)', description: '抽屜滑軌、工業滑軌' },
  { value: 'M', label: 'M - Module/Assy (模組)', description: '組合件、系統模組' },
  { value: 'D', label: 'D - Decorative Hardware (裝飾五金)', description: '裝飾性配件' },
  { value: 'F', label: 'F - Functional Hardware (功能五金)', description: '功能性配件' },
  { value: 'B', label: 'B - Builders Hardware (建築五金)', description: '建築用五金' },
  { value: 'I', label: 'I - Industrial Parts Solution (工業零件)', description: '工業解決方案' },
  { value: 'O', label: 'O - Others (其他)', description: '未分類項目' },
]

/**
 * 產品中類選項
 * 根據大類動態產生，格式：{ [mainCategory]: { [code]: name } }
 */
export const subCategoryOptions = {
  H: {
    '00': '未分類',
    '01': 'Knob', // 旋鈕
    '02': 'Pull', // 拉手
    '03': 'Handle', // 把手
    '04': 'Bar Handle', // 橫桿把手
    '05': 'Cup Pull', // 杯型拉手
    '06': 'Ring Pull', // 環型拉手
  },
  S: {
    '00': '未分類',
    '01': 'Ball Bearing Slide', // 滾珠滑軌
    '02': 'Undermount Slide', // 底裝滑軌
    '03': 'Soft Close Slide', // 緩衝滑軌
    '04': 'Heavy Duty Slide', // 重載滑軌
  },
  M: {
    '00': '未分類',
    '01': 'Drawer System', // 抽屜系統
    '02': 'Pull-Out System', // 拉出系統
    '03': 'Organizer', // 收納系統
    '04': 'Basket System', // 籃架系統
  },
  D: {
    '00': '未分類',
    '01': 'Furniture Leg', // 家具腳
    '02': 'Decorative Handle', // 裝飾把手
    '03': 'Ornament', // 裝飾品
  },
  F: {
    '00': '未分類',
    '01': 'Hinge', // 鉸鏈
    '02': 'Caster', // 腳輪
    '03': 'Lock', // 鎖具
    '04': 'Catch', // 扣件
  },
  B: {
    '00': '未分類',
    '01': 'Door Hardware', // 門用五金
    '02': 'Window Hardware', // 窗用五金
    '03': 'Gate Hardware', // 門閘五金
  },
  I: {
    '00': '未分類',
    '01': 'Industrial Slide', // 工業滑軌
    '02': 'Heavy Duty Component', // 重載組件
    '03': 'Custom Solution', // 客製化解決方案
  },
  O: {
    '00': '未分類',
    '99': '其他',
  },
}

/**
 * 產品小類選項
 * 根據大類動態產生，格式：{ [mainCategory]: { [code]: name } }
 */
export const specCategoryOptions = {
  H: {
    A: 'Aluminum', // 鋁
    B: 'Brass', // 黃銅
    C: 'Chrome', // 鍍鉻
    S: 'Stainless Steel', // 不鏽鋼
    Z: 'Zinc Alloy', // 鋅合金
  },
  S: {
    B: 'Ball Bearing', // 滾珠軸承
    S: 'Soft Close', // 緩衝關閉
    F: 'Full Extension', // 全開式
    P: 'Partial Extension', // 部分開啟
  },
  M: {
    D: 'Drawer', // 抽屜
    P: 'Pull-Out', // 拉出
    O: 'Organizer', // 收納
    B: 'Basket', // 籃架
  },
  D: {
    L: 'Leg', // 腳
    H: 'Handle', // 把手
    O: 'Ornament', // 裝飾
  },
  F: {
    H: 'Hinge', // 鉸鏈
    C: 'Caster', // 腳輪
    L: 'Lock', // 鎖具
    T: 'Catch', // 扣件
  },
  B: {
    D: 'Door', // 門
    W: 'Window', // 窗
    G: 'Gate', // 門閘
  },
  I: {
    S: 'Slide', // 滑軌
    H: 'Heavy Duty', // 重載
    C: 'Custom', // 客製化
  },
  O: {
    X: '其他',
  },
}

/**
 * 供應商選項
 * 用於物料申請表單的供應商選擇
 */
export const supplierOptions = [
  { value: 'SUP001', label: '供應商A' },
  { value: 'SUP002', label: '供應商B' },
  { value: 'SUP003', label: '供應商C' },
  // 可擴展更多供應商
]

/**
 * 基本材質選項
 * 用於物料申請表單的材質選擇
 */
export const materialOptions = [
  { value: 'Steel', label: 'Steel', description: '鋼材' },
  { value: 'Stainless Steel', label: 'Stainless Steel', description: '不鏽鋼' },
  { value: 'Brass', label: 'Brass', description: '黃銅' },
  { value: 'Zinc Alloy (Zamak)', label: 'Zinc Alloy (Zamak)', description: '鋅合金' },
  { value: 'Aluminum', label: 'Aluminum', description: '鋁' },
  { value: 'Plastic', label: 'Plastic', description: '塑膠' },
  { value: 'Wood', label: 'Wood', description: '木材' },
  { value: 'Others', label: 'Others', description: '其他' },
]

/**
 * 表面處理選項
 * 用於物料申請表單的表面處理選擇
 */
export const surfaceFinishOptions = [
  { value: 'Chrome Plated', label: 'Chrome Plated', description: '鍍鉻' },
  { value: 'Nickel Plated', label: 'Nickel Plated', description: '鍍鎳' },
  { value: 'Zinc Plated', label: 'Zinc Plated', description: '鍍鋅' },
  { value: 'Powder Coating', label: 'Powder Coating', description: '粉體塗裝' },
  { value: 'Anodized', label: 'Anodized', description: '陽極處理' },
  { value: 'Natural', label: 'Natural', description: '原色/自然' },
]

/**
 * 單位選項
 * 用於物料申請表單的單位選擇
 */
export const unitOptions = [
  { value: 'PCS', label: 'PCS', description: '個/件 (Pieces)' },
  { value: 'SET', label: 'SET', description: '組/套 (Set)' },
  { value: 'PAIR', label: 'PAIR', description: '對/雙 (Pair)' },
  { value: 'KG', label: 'KG', description: '公斤 (Kilogram)' },
  { value: 'G', label: 'G', description: '公克 (Gram)' },
  { value: 'M', label: 'M', description: '公尺 (Meter)' },
  { value: 'CM', label: 'CM', description: '公分 (Centimeter)' },
  { value: 'MM', label: 'MM', description: '公釐 (Millimeter)' },
  { value: 'M²', label: 'M²', description: '平方公尺 (Square Meter)' },
  { value: 'M³', label: 'M³', description: '立方公尺 (Cubic Meter)' },
  { value: 'L', label: 'L', description: '公升 (Liter)' },
  { value: 'ML', label: 'ML', description: '毫升 (Milliliter)' },
]

/**
 * 包裝選項定義
 * 用於包裝說明表單的選項
 */
export const packagingOptions = {
  // 1. 個別產品包裝選項
  productPackaging: [
    { value: '塑膠袋', label: '塑膠袋', description: 'PE/PP塑膠袋包裝' },
    { value: '氣泡袋', label: '氣泡袋', description: '氣泡袋保護包裝' },
    { value: 'PE/PP材質', label: 'PE/PP材質', description: 'PE或PP材質包裝' },
    { value: '彩盒包裝', label: '彩盒包裝', description: '彩色印刷紙盒包裝' },
    { value: '回收標誌', label: '回收標誌', description: '印刷回收標誌' },
    { value: '產品標籤', label: '產品標籤', description: '產品標籤貼紙' },
    { value: '說明書', label: '說明書', description: '產品說明書' },
  ],

  // 2. 配件內容選項
  accessoriesContent: [
    { value: '螺絲', label: '螺絲', description: '安裝用螺絲' },
    { value: '支架', label: '支架', description: '安裝支架' },
    { value: '蓋子/端蓋', label: '蓋子/端蓋', description: '端蓋或蓋子' },
    { value: '緩衝墊', label: '緩衝墊', description: '緩衝保護墊' },
    { value: '散裝', label: '散裝', description: '散裝配件' },
  ],

  // 3. 配件選項
  accessories: [
    { value: '供應商提供', label: '供應商提供', description: '由供應商提供' },
    { value: '客戶提供', label: '客戶提供', description: '由客戶提供' },
    { value: '標準配件', label: '標準配件', description: '標準配置配件' },
    { value: '選配配件', label: '選配配件', description: '選購配件' },
  ],

  // 4. 內盒選項
  innerBox: [
    { value: '印製ITEM NO.', label: '印製ITEM NO.', description: '內盒印製料號' },
    { value: '印製數量', label: '印製數量', description: '內盒印製數量' },
    { value: '條碼', label: '條碼', description: '內盒貼條碼' },
    { value: '標籤', label: '標籤', description: '內盒貼標籤' },
    { value: '客戶Logo', label: '客戶Logo', description: '內盒印製客戶Logo' },
  ],

  // 5. 外箱選項
  outerBox: [
    { value: '瓦楞紙箱', label: '瓦楞紙箱', description: '瓦楞紙箱包裝' },
    { value: '側嘜', label: '側嘜', description: '外箱側面標籤' },
    { value: '客戶產品編號', label: '客戶產品編號', description: '印製客戶產品編號' },
    { value: '出貨嘜頭', label: '出貨嘜頭', description: '出貨標記' },
    { value: '易碎標誌', label: '易碎標誌', description: '易碎物品標誌' },
    { value: '向上標誌', label: '向上標誌', description: '向上箭頭標誌' },
  ],

  // 6. 運輸與托盤要求選項
  transport: [
    { value: '托盤/Pallet', label: '托盤/Pallet', description: '使用托盤' },
    { value: '纏繞膜', label: '纏繞膜', description: '使用纏繞膜保護' },
    { value: '護角', label: '護角', description: '使用護角保護' },
    { value: '打包帶', label: '打包帶', description: '使用打包帶固定' },
    { value: 'EUDR文件', label: 'EUDR文件', description: '提供EUDR文件' },
  ],

  // 7. 裝櫃要求選項
  container: [
    { value: '20呎櫃', label: '20呎櫃', description: '20呎貨櫃' },
    { value: '40呎櫃', label: '40呎櫃', description: '40呎貨櫃' },
    { value: '40呎高櫃', label: '40呎高櫃', description: '40呎高櫃' },
    { value: '棧板出貨', label: '棧板出貨', description: '使用棧板出貨' },
    { value: '散裝裝櫃', label: '散裝裝櫃', description: '散裝方式裝櫃' },
  ],

  // 8. 其他說明選項
  other: [
    { value: 'FSC認證', label: 'FSC認證', description: 'FSC森林認證' },
    { value: 'RoHS認證', label: 'RoHS認證', description: 'RoHS環保認證' },
    { value: 'REACH認證', label: 'REACH認證', description: 'REACH化學品認證' },
    { value: 'ISO認證', label: 'ISO認證', description: 'ISO品質認證' },
    { value: '測試報告', label: '測試報告', description: '提供測試報告' },
  ],
}

/**
 * 申請狀態選項
 * 用於申請狀態的選擇和篩選
 */
export const applicationStatusOptions = [
  { value: 'PENDING', label: '待審核', description: '等待審核中', color: 'warning' },
  { value: 'APPROVED', label: '已核准', description: '已通過審核', color: 'success' },
  { value: 'REJECTED', label: '已退回', description: '已退回修改', color: 'error' },
  { value: 'ALL', label: '全部', description: '所有狀態', color: 'grey' },
]

/**
 * 優先級選項
 * 用於申請優先級的選擇
 */
export const priorityOptions = [
  { value: 'HIGH', label: '高', description: '高優先級', color: 'error' },
  { value: 'MEDIUM', label: '中', description: '中優先級', color: 'warning' },
  { value: 'LOW', label: '低', description: '低優先級', color: 'info' },
]

/**
 * 審核動作選項
 * 用於審核記錄的動作類型
 */
export const approvalActionOptions = [
  { value: 'SUBMIT', label: '提交', description: '提交申請' },
  { value: 'APPROVE', label: '核准', description: '核准申請' },
  { value: 'REJECT', label: '退回', description: '退回申請' },
  { value: 'RETURN', label: '退回修改', description: '退回修改' },
]

/**
 * 使用者角色選項
 * 用於使用者管理的角色選擇
 */
export const userRoleOptions = [
  { value: 'admin', label: '系統管理員', description: '擁有所有權限' },
  { value: 'approver', label: '審核人員', description: '可審核申請' },
  { value: 'applicant', label: '申請人員', description: '可提交申請' },
]

/**
 * 系統設定選項
 */

// 流水號位數選項
export const serialDigitsOptions = [
  { value: 4, label: '4位數', description: '0001-9999' },
  { value: 5, label: '5位數', description: '00001-99999' },
  { value: 6, label: '6位數', description: '000001-999999' },
]

// 布林值選項（開啟/關閉）
export const booleanOptions = [
  { value: true, label: '開啟', description: '啟用此功能' },
  { value: false, label: '關閉', description: '停用此功能' },
]

// 審核層級選項
export const approvalLevelOptions = [
  { value: 1, label: '單層審核', description: '只需一層審核' },
  { value: 2, label: '雙層審核', description: '需要兩層審核' },
  { value: 3, label: '三層審核', description: '需要三層審核' },
]

/**
 * 匯出格式選項
 * 用於Excel匯出功能的格式選擇
 */
export const exportFormatOptions = [
  { value: 'CSV', label: 'CSV', description: '逗號分隔值檔案' },
  { value: 'XLSX', label: 'Excel', description: 'Excel檔案格式' },
  { value: 'PDF', label: 'PDF', description: 'PDF檔案格式' },
]

/**
 * 幣別選項
 * 用於成本資訊的幣別選擇
 */
export const currencyOptions = [
  { value: 'TWD', label: 'TWD', description: '新台幣', symbol: 'NT$' },
  { value: 'USD', label: 'USD', description: '美元', symbol: '$' },
  { value: 'CNY', label: 'CNY', description: '人民幣', symbol: '¥' },
  { value: 'EUR', label: 'EUR', description: '歐元', symbol: '€' },
  { value: 'JPY', label: 'JPY', description: '日圓', symbol: '¥' },
]

/**
 * 檔案類型選項
 * 用於附件管理的檔案類型分類
 */
export const fileTypeOptions = [
  { value: 'image', label: '圖片', description: '圖片檔案', extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'] },
  { value: 'document', label: '文件', description: '文件檔案', extensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'] },
  { value: 'drawing', label: '圖面', description: '工程圖面', extensions: ['dwg', 'dxf', 'pdf'] },
  { value: 'other', label: '其他', description: '其他類型檔案', extensions: [] },
]

/**
 * 類別預設包裝選項
 * 各產品大類的預設包裝選項
 */
export const categoryDefaultPackagingOptions = {
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
