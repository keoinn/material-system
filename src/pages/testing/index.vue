<route lang="yaml">
meta:
  layout: default
</route>

<template>
  <v-container>
    <!-- 未驗證時顯示密碼輸入 -->
    <v-card v-if="!testingStore.isAuthenticated" class="mx-auto" max-width="500">
      <v-card-title class="d-flex align-center">
        <v-icon class="mr-2">mdi-shield-lock</v-icon>
        測試平台入口
      </v-card-title>

      <v-card-text>
        <v-alert
          v-if="errorMessage"
          class="mb-4"
          closable
          type="error"
          variant="tonal"
          @click:close="errorMessage = ''"
        >
          {{ errorMessage }}
        </v-alert>

        <v-form @submit.prevent="verifyPassword">
          <v-text-field
            v-model="password"
            autofocus
            :disabled="loading"
            :error="!!errorMessage"
            label="請輸入密碼"
            prepend-inner-icon="mdi-lock"
            type="password"
            @keyup.enter="verifyPassword"
          />

          <v-btn
            block
            color="primary"
            :loading="loading"
            prepend-icon="mdi-login"
            type="submit"
          >
            驗證
          </v-btn>
        </v-form>
      </v-card-text>
    </v-card>

    <!-- 驗證成功後顯示測試功能面板 -->
    <div v-else>
      <v-card>
        <v-card-title class="d-flex align-center">
          <v-icon class="mr-2">mdi-test-tube</v-icon>
          測試平台
        </v-card-title>

        <v-card-text>
          <v-alert
            v-if="testingStore.showSuccessAlert"
            class="mb-4"
            closable
            type="success"
            variant="tonal"
            @click:close="testingStore.hideSuccessAlert"
          >
            <v-icon class="mr-2">mdi-check-circle</v-icon>
            驗證成功！歡迎使用測試平台
          </v-alert>

          <v-row>
            <!-- Supabase 測試 -->
            <v-col cols="12" lg="4" md="6">
              <v-card
                class="test-card"
                hover
                variant="outlined"
                @click="navigateTo('/testing/supabase')"
              >
                <v-card-title class="d-flex align-center">
                  <v-icon class="mr-2" color="primary">mdi-database-check</v-icon>
                  Supabase 測試
                </v-card-title>
                <v-card-text>
                  <p class="text-body-2 text-grey">
                    測試 Supabase 連線、查詢、認證和 Storage 功能
                  </p>
                </v-card-text>
                <v-card-actions>
                  <v-btn
                    color="primary"
                    prepend-icon="mdi-arrow-right"
                    variant="text"
                    @click.stop="navigateTo('/testing/supabase')"
                  >
                    前往測試
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-col>

            <!-- 預留其他測試功能卡片 -->
            <v-col cols="12" lg="4" md="6">
              <v-card
                class="test-card"
                disabled
                variant="outlined"
              >
                <v-card-title class="d-flex align-center">
                  <v-icon class="mr-2" color="grey">mdi-cog</v-icon>
                  更多測試功能
                </v-card-title>
                <v-card-text>
                  <p class="text-body-2 text-grey">
                    更多測試功能即將推出
                  </p>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>

          <v-divider class="my-4" />

          <div class="d-flex justify-end">
            <v-btn
              color="error"
              prepend-icon="mdi-logout"
              variant="outlined"
              @click="logout"
            >
              登出測試平台
            </v-btn>
          </div>
        </v-card-text>
      </v-card>
    </div>
  </v-container>
</template>

<script setup>
  import { onMounted, ref } from 'vue'
  import { useRouter } from 'vue-router'
  import { useTestingStore } from '@/stores/testing'

  const router = useRouter()
  const testingStore = useTestingStore()

  const password = ref('')
  const loading = ref(false)
  const errorMessage = ref('')

  onMounted(() => {
    // 檢查是否有已驗證的狀態（store 會自動處理）
    testingStore.checkAuth()
  })

  async function verifyPassword () {
    if (!password.value.trim()) {
      errorMessage.value = '請輸入密碼'
      return
    }

    loading.value = true
    errorMessage.value = ''

    // 模擬驗證延遲
    await new Promise(resolve => setTimeout(resolve, 300))

    const result = testingStore.login(password.value)

    if (result.success) {
      password.value = ''
    } else {
      errorMessage.value = result.message || '密碼錯誤，請重新輸入'
      password.value = ''
    }

    loading.value = false
  }

  function navigateTo (path) {
    router.push(path)
  }

  function logout () {
    testingStore.logout()
    password.value = ''
    errorMessage.value = ''
  }
</script>

<style scoped lang="scss">
.test-card {
  cursor: pointer;
  transition: all 0.3s ease;

  &:hover:not(.v-card--disabled) {
    transform: translateY(-4px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }
}
</style>
