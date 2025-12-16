<route lang="yaml">
meta:
  layout: default
</route>

<template>
  <v-container>
    <v-card>
      <v-card-title class="d-flex align-center">
        <v-icon class="mr-2">mdi-database-check</v-icon>
        Supabase 連線測試
      </v-card-title>

      <v-card-text>
        <!-- 環境變數狀態 -->
        <v-card class="mb-4" variant="outlined">
          <v-card-title class="text-subtitle-1">環境變數狀態</v-card-title>
          <v-card-text>
            <v-list density="compact">
              <v-list-item>
                <v-list-item-title>後端類型</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip
                    :color="backendType === 'supabase' ? 'success' : 'warning'"
                    size="small"
                  >
                    {{ backendType || '未設定' }}
                  </v-chip>
                </v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>Supabase URL</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip
                    :color="hasSupabaseUrl ? 'success' : 'error'"
                    size="small"
                  >
                    {{ hasSupabaseUrl ? '已設定' : '未設定' }}
                  </v-chip>
                  <span v-if="hasSupabaseUrl" class="ml-2 text-caption text-grey">
                    {{ maskedSupabaseUrl }}
                  </span>
                </v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>Supabase Anon Key</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip
                    :color="hasSupabaseKey ? 'success' : 'error'"
                    size="small"
                  >
                    {{ hasSupabaseKey ? '已設定' : '未設定' }}
                  </v-chip>
                </v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title>Storage Bucket</v-list-item-title>
                <v-list-item-subtitle>
                  {{ storageBucket || 'attachments (預設)' }}
                </v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </v-card-text>
        </v-card>

        <!-- 連線狀態 -->
        <v-alert
          v-if="connectionStatus"
          class="mb-4"
          closable
          :icon="connectionStatus.icon"
          :type="connectionStatus.type"
          @click:close="connectionStatus = null"
        >
          <div class="font-weight-bold">{{ connectionStatus.title }}</div>
          <div>{{ connectionStatus.message }}</div>
        </v-alert>

        <!-- 測試按鈕 -->
        <div class="d-flex flex-wrap gap-2 mb-4">
          <v-btn
            color="primary"
            :loading="loading"
            prepend-icon="mdi-connection"
            @click="testConnection"
          >
            測試連線
          </v-btn>

          <v-btn
            color="info"
            :disabled="!isAvailable"
            :loading="queryLoading"
            prepend-icon="mdi-database-search"
            @click="testQuery"
          >
            測試查詢
          </v-btn>

          <v-btn
            color="success"
            :disabled="!isAvailable"
            :loading="authLoading"
            prepend-icon="mdi-account-check"
            @click="testAuth"
          >
            測試認證
          </v-btn>

          <v-btn
            color="warning"
            :disabled="!isAvailable"
            :loading="tableLoading"
            prepend-icon="mdi-table-search"
            @click="listTables"
          >
            列出資料表
          </v-btn>

          <v-btn
            color="purple"
            :disabled="!isAvailable"
            :loading="storageLoading"
            prepend-icon="mdi-folder-search"
            @click="testStorage"
          >
            測試 Storage
          </v-btn>

          <v-btn
            color="error"
            prepend-icon="mdi-refresh"
            variant="outlined"
            @click="clearResults"
          >
            清除結果
          </v-btn>
        </div>

        <!-- 測試結果 -->
        <v-card v-if="testResults" variant="outlined">
          <v-card-title class="d-flex align-center justify-space-between">
            <span>測試結果</span>
            <v-chip
              :color="testResults.success ? 'success' : 'error'"
              size="small"
            >
              {{ testResults.success ? '成功' : '失敗' }}
            </v-chip>
          </v-card-title>
          <v-card-text>
            <v-tabs v-model="activeTab">
              <v-tab value="result">結果</v-tab>
              <v-tab value="raw">原始資料</v-tab>
            </v-tabs>

            <v-window v-model="activeTab" class="mt-4">
              <v-window-item value="result">
                <div v-if="testResults.success">
                  <v-alert class="mb-4" type="success" variant="tonal">
                    測試成功！
                  </v-alert>
                  <v-list v-if="testResults.data">
                    <v-list-item
                      v-for="(value, key) in testResults.data"
                      :key="key"
                    >
                      <v-list-item-title>{{ key }}</v-list-item-title>
                      <v-list-item-subtitle>
                        {{ typeof value === 'object' ? JSON.stringify(value) : value }}
                      </v-list-item-subtitle>
                    </v-list-item>
                  </v-list>
                </div>
                <div v-else>
                  <v-alert class="mb-4" type="error" variant="tonal">
                    <div class="font-weight-bold">錯誤訊息：</div>
                    <div>{{ testResults.error || testResults.message }}</div>
                    <div v-if="testResults.code" class="mt-2 text-caption">
                      錯誤代碼：{{ testResults.code }}
                    </div>
                    <div v-if="testResults.hint" class="mt-2 text-caption">
                      提示：{{ testResults.hint }}
                    </div>
                  </v-alert>
                </div>
              </v-window-item>

              <v-window-item value="raw">
                <pre class="pa-4 bg-grey-lighten-4 rounded">{{ JSON.stringify(testResults, null, 2) }}</pre>
              </v-window-item>
            </v-window>
          </v-card-text>
        </v-card>

        <!-- 使用說明 -->
        <v-card class="mt-4" variant="outlined">
          <v-card-title class="text-subtitle-1">使用說明</v-card-title>
          <v-card-text>
            <ol class="usage-list">
              <li>確認環境變數已正確設定（檢查上方狀態）</li>
              <li>點擊「測試連線」檢查 Supabase 客戶端是否正常初始化</li>
              <li>點擊「測試查詢」測試資料庫查詢功能（需要 product_categories 表）</li>
              <li>點擊「測試認證」測試 Supabase Auth 功能</li>
              <li>點擊「列出資料表」查看可用的資料表</li>
              <li>點擊「測試 Storage」測試 Storage 功能</li>
            </ol>
          </v-card-text>
        </v-card>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script setup>
  import { computed, onMounted, ref } from 'vue'
  import { getBackendType } from '@/api/client.js'
  import { isSupabaseAvailable, STORAGE_BUCKET, supabase } from '@/api/supabase.js'
  import { useSwal } from '@/composables/useSwal.js'

  const swal = useSwal()

  const loading = ref(false)
  const queryLoading = ref(false)
  const authLoading = ref(false)
  const tableLoading = ref(false)
  const storageLoading = ref(false)
  const connectionStatus = ref(null)
  const testResults = ref(null)
  const activeTab = ref('result')

  const backendType = computed(() => import.meta.env.VITE_API_BACKEND || 'supabase')
  const hasSupabaseUrl = computed(() => !!import.meta.env.VITE_SUPABASE_URL)
  const hasSupabaseKey = computed(() => !!import.meta.env.VITE_SUPABASE_ANON_KEY)
  const storageBucket = computed(() => import.meta.env.VITE_SUPABASE_STORAGE_BUCKET || STORAGE_BUCKET)
  const isAvailable = computed(() => isSupabaseAvailable())

  const maskedSupabaseUrl = computed(() => {
    const url = import.meta.env.VITE_SUPABASE_URL
    if (!url) return ''
    try {
      const urlObj = new URL(url)
      return `${urlObj.protocol}//${urlObj.hostname}/...`
    } catch {
      return url.slice(0, 30) + '...'
    }
  })

  onMounted(() => {
    // 自動檢查連線狀態
    checkInitialStatus()
  })

  function checkInitialStatus () {
    if (!isAvailable.value) {
      connectionStatus.value = {
        type: 'warning',
        icon: 'mdi-alert',
        title: 'Supabase 未初始化',
        message: '請檢查環境變數設定',
      }
    }
  }

  async function testConnection () {
    loading.value = true
    connectionStatus.value = null
    testResults.value = null

    try {
      if (!isAvailable.value) {
        throw new Error('Supabase 客戶端未初始化')
      }

      // 測試基本連線（嘗試查詢一個簡單的表）
      const { data, error } = await supabase
        .from('product_categories')
        .select('count')
        .limit(1)

      if (error) {
        // 如果 product_categories 不存在，嘗試其他方式測試連線
        if (error.code === 'PGRST116' || error.message.includes('relation') || error.message.includes('does not exist')) {
          // 表不存在，但連線是成功的
          connectionStatus.value = {
            type: 'success',
            icon: 'mdi-check-circle',
            title: '連線成功',
            message: 'Supabase 連線正常，但 product_categories 表可能不存在',
          }
          testResults.value = {
            success: true,
            message: '連線成功，但資料表不存在',
            data: {
              backendType: backendType.value,
              supabaseUrl: maskedSupabaseUrl.value,
              storageBucket: storageBucket.value,
            },
            warning: error.message,
          }
        } else {
          throw error
        }
      } else {
        connectionStatus.value = {
          type: 'success',
          icon: 'mdi-check-circle',
          title: '連線成功',
          message: 'Supabase 連線正常，可以正常查詢資料',
        }
        testResults.value = {
          success: true,
          message: '連線測試成功',
          data: {
            backendType: backendType.value,
            supabaseUrl: maskedSupabaseUrl.value,
            storageBucket: storageBucket.value,
            queryResult: data,
          },
        }
      }
    } catch (error) {
      connectionStatus.value = {
        type: 'error',
        icon: 'mdi-alert-circle',
        title: '連線失敗',
        message: error.message || '無法連接到 Supabase',
      }
      testResults.value = {
        success: false,
        error: error.message,
        code: error.code,
        hint: error.hint,
      }
    } finally {
      loading.value = false
    }
  }

  async function testQuery () {
    queryLoading.value = true
    testResults.value = null

    try {
      if (!isAvailable.value) {
        throw new Error('Supabase 客戶端未初始化')
      }

      const { data, error } = await supabase
        .from('product_categories')
        .select('*')
        .limit(5)

      if (error) {
        throw error
      }

      testResults.value = {
        success: true,
        message: `成功查詢到 ${data.length} 筆資料`,
        data: {
          count: data.length,
          records: data,
        },
      }

      await swal.success(`成功查詢到 ${data.length} 筆資料`)
    } catch (error) {
      testResults.value = {
        success: false,
        error: error.message,
        code: error.code,
        hint: error.hint,
      }
      await swal.error(`查詢失敗：${error.message}`)
    } finally {
      queryLoading.value = false
    }
  }

  async function testAuth () {
    authLoading.value = true
    testResults.value = null

    try {
      if (!isAvailable.value) {
        throw new Error('Supabase 客戶端未初始化')
      }

      const { data: { session }, error: sessionError } = await supabase.auth.getSession()

      if (sessionError) {
        throw sessionError
      }

      const { data: { user }, error: userError } = await supabase.auth.getUser()

      if (userError && userError.message !== 'Invalid Refresh Token: Refresh Token Not Found') {
        throw userError
      }

      testResults.value = {
        success: true,
        message: '認證功能正常',
        data: {
          hasSession: !!session,
          hasUser: !!user,
          userId: user?.id || null,
          userEmail: user?.email || null,
          sessionExpiresAt: session?.expires_at || null,
        },
      }

      await swal.info(user ? `當前使用者：${user.email || user.id}` : '目前沒有登入的使用者')
    } catch (error) {
      testResults.value = {
        success: false,
        error: error.message,
        code: error.code,
        hint: error.hint,
      }
      await swal.error(`認證測試失敗：${error.message}`)
    } finally {
      authLoading.value = false
    }
  }

  async function listTables () {
    tableLoading.value = true
    testResults.value = null

    try {
      if (!isAvailable.value) {
        throw new Error('Supabase 客戶端未初始化')
      }

      // 嘗試查詢幾個常見的表
      const tables = [
        'product_categories',
        'suppliers',
        'applications',
        'packaging_categories',
        'packaging_options',
        'user_profiles',
        'system_settings',
      ]

      const results = {}
      const errors = {}

      for (const table of tables) {
        try {
          const { data, error } = await supabase
            .from(table)
            .select('count')
            .limit(1)

          if (error) {
            errors[table] = error.message
          } else {
            results[table] = '存在'
          }
        } catch (error) {
          errors[table] = error.message
        }
      }

      testResults.value = {
        success: true,
        message: '資料表檢查完成',
        data: {
          existingTables: Object.keys(results),
          missingTables: Object.keys(errors),
          details: {
            existing: results,
            errors: errors,
          },
        },
      }

      await swal.success(`找到 ${Object.keys(results).length} 個資料表`)
    } catch (error) {
      testResults.value = {
        success: false,
        error: error.message,
        code: error.code,
      }
      await swal.error(`檢查失敗：${error.message}`)
    } finally {
      tableLoading.value = false
    }
  }

  async function testStorage () {
    storageLoading.value = true
    testResults.value = null

    try {
      if (!isAvailable.value) {
        throw new Error('Supabase 客戶端未初始化')
      }

      // 測試列出 Storage bucket
      const { data, error } = await supabase.storage
        .from(STORAGE_BUCKET)
        .list('', {
          limit: 10,
        })

      if (error) {
        // 如果 bucket 不存在，這是正常的（需要先建立）
        if (error.message.includes('not found') || error.message.includes('不存在')) {
          testResults.value = {
            success: true,
            message: 'Storage 功能正常，但 bucket 尚未建立',
            data: {
              bucket: STORAGE_BUCKET,
              note: '請在 Supabase Dashboard 中建立此 bucket',
            },
            warning: error.message,
          }
          await swal.warning(`Storage bucket "${STORAGE_BUCKET}" 尚未建立`)
        } else {
          throw error
        }
      } else {
        testResults.value = {
          success: true,
          message: `Storage 功能正常，找到 ${data.length} 個檔案/資料夾`,
          data: {
            bucket: STORAGE_BUCKET,
            fileCount: data.length,
            files: data,
          },
        }
        await swal.success(`Storage 功能正常`)
      }
    } catch (error) {
      testResults.value = {
        success: false,
        error: error.message,
        code: error.code,
        hint: error.hint,
      }
      await swal.error(`Storage 測試失敗：${error.message}`)
    } finally {
      storageLoading.value = false
    }
  }

  function clearResults () {
    testResults.value = null
    connectionStatus.value = null
  }
</script>

<style scoped lang="scss">
.gap-2 {
  gap: 8px;
}

pre {
  font-size: 12px;
  overflow-x: auto;
  max-height: 500px;
}

.usage-list {
  padding-left: 24px;
  margin-left: 16px;

  li {
    margin-bottom: 8px;
    line-height: 1.6;
  }
}
</style>
