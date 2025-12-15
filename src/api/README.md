# API 層說明

## 結構

```
src/api/
├── client.js              # Axios 客戶端配置
├── supabase.js           # Supabase 客戶端配置（包含 Storage）
├── index.js              # 統一匯出
└── services/             # API 服務層
    ├── index.js          # 服務統一匯出
    ├── backend-selector.js # 後端選擇器（可選，目前未使用）
    ├── applications.js    # 申請相關 API（統一介面）
    ├── auth.js           # 認證相關 API（統一介面）
    ├── categories.js     # 分類相關 API（統一介面）
    ├── packaging.js      # 包裝相關 API（統一介面）
    ├── suppliers.js      # 供應商相關 API（統一介面）
    ├── attachments.js    # 附件相關 API（統一介面）
    ├── settings.js       # 設定相關 API（統一介面）
    ├── axios/            # Axios 實作
    │   ├── applications.js
    │   ├── auth.js
    │   ├── categories.js
    │   ├── packaging.js
    │   ├── suppliers.js
    │   ├── attachments.js
    │   └── settings.js
    └── supabase/         # Supabase 實作
        ├── applications.js
        ├── auth.js
        ├── categories.js
        ├── packaging.js
        ├── suppliers.js
        ├── attachments.js
        └── settings.js
```

## 架構說明

每個服務都分為三個部分：

1. **統一介面層**（例如：`services/applications.js`）
   - 根據環境變數自動選擇使用 Axios 或 Supabase 實作
   - 提供統一的 API 介面
   - 業務邏輯層無需關心後端實作細節

2. **Axios 實作層**（`services/axios/`）
   - 使用 REST API 呼叫後端服務
   - 適用於傳統 RESTful API 架構

3. **Supabase 實作層**（`services/supabase/`）
   - 直接操作 Supabase 資料庫
   - 使用 Supabase Storage 處理檔案上傳
   - 適用於 Supabase 後端架構

## 環境變數設定

在 `.env` 檔案中設定：

```env
# 選擇後端：'supabase' 或 'axios'
VITE_API_BACKEND=supabase

# Supabase 設定
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_SUPABASE_STORAGE_BUCKET=attachments

# Axios REST API 設定（當 VITE_API_BACKEND=axios 時使用）
VITE_API_BASE_URL=http://localhost:3001/api
VITE_API_TIMEOUT=10000
```

## 使用方式

### 在 Store 中使用

```javascript
import { applicationsService } from '@/api/services/applications.js'

export const useApplicationsStore = defineStore('applications', () => {
  async function loadApplications() {
    try {
      const data = await applicationsService.getApplications()
      applications.value = data
    } catch (error) {
      console.error('載入失敗', error)
    }
  }
})
```

### 在 Component 中使用

```javascript
import { attachmentsService } from '@/api'

async function handleFileUpload(file) {
  try {
    const attachment = await attachmentsService.uploadAttachment(
      applicationId.value,
      file,
      { description: '產品圖片' }
    )
    console.log('上傳成功', attachment)
  } catch (error) {
    console.error('上傳失敗', error)
  }
}
```

### Storage 操作

```javascript
import { storageService, STORAGE_BUCKET } from '@/api/supabase.js'

// 上傳檔案
const { data, error } = await storageService.uploadFile(
  file,
  `applications/${applicationId}/${fileName}`,
  { contentType: 'image/jpeg' }
)

// 取得公開 URL
const publicUrl = storageService.getPublicUrl(filePath)

// 取得簽名 URL（私有檔案）
const signedUrl = await storageService.getSignedUrl(filePath, 3600)
```

## 後端切換

系統會根據 `VITE_API_BACKEND` 環境變數自動選擇使用 Supabase 或 Axios：

- `VITE_API_BACKEND=supabase`：使用 Supabase Client 直接操作資料庫
- `VITE_API_BACKEND=axios`：使用 Axios 呼叫 REST API

所有服務函數都會自動處理後端切換，無需修改業務邏輯。

