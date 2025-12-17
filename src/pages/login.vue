<route lang="yaml">
meta:
  layout: empty
</route>

<template>
  <div class="login-wrapper">
    <v-container class="login-container" fluid>
      <v-row align="center" class="fill-height" justify="center">
        <v-col cols="12" lg="4" md="6" sm="8">
          <v-card class="login-card" elevation="8">
            <div class="login-header">
              <h1>物料編碼申請管理系統</h1>
              <div class="version">V3.6 - Vue3 版本</div>
            </div>

            <v-card-text>
              <v-form @submit.prevent="handleLogin">
                <v-text-field
                  v-model="identifier"
                  class="mb-4"
                  label="Email 或使用者名稱"
                  prepend-inner-icon="mdi-account"
                  :rules="[rules.required]"
                  variant="outlined"
                  autocomplete="username"
                />

                <v-text-field
                  v-model="password"
                  class="mb-4"
                  label="密碼"
                  prepend-inner-icon="mdi-lock"
                  :rules="[rules.required]"
                  type="password"
                  variant="outlined"
                  autocomplete="current-password"
                  @keyup.enter="handleLogin"
                />

                <v-alert
                  v-if="errorMessage"
                  class="mb-4"
                  type="error"
                  variant="tonal"
                  closable
                  @click:close="errorMessage = ''"
                >
                  {{ errorMessage }}
                </v-alert>

                <v-btn
                  block
                  class="login-btn"
                  color="primary"
                  :disabled="loading"
                  :loading="loading"
                  size="large"
                  type="submit"
                >
                  登入
                </v-btn>
              </v-form>

              <div class="mt-4 text-center">
                <small class="text-grey">
                  提示：請使用 Email 或使用者名稱登入
                </small>
                <div class="mt-2">
                  <v-btn
                    color="primary"
                    size="small"
                    variant="text"
                    @click="router.push('/register')"
                  >
                    還沒有帳號？立即註冊
                  </v-btn>
                </div>
              </div>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script setup>
  import { computed, ref } from 'vue'
  import { useRouter } from 'vue-router'
  import { useAuthStore } from '@/stores/auth'

  const router = useRouter()
  const authStore = useAuthStore()

  const identifier = ref('')
  const password = ref('')
  const errorMessage = ref('')

  const loading = computed(() => authStore.loading)

  const rules = {
    required: value => !!value || '此欄位為必填',
  }

  async function handleLogin () {
    if (!identifier.value || !password.value) {
      errorMessage.value = '請輸入 Email/使用者名稱和密碼'
      return
    }

    errorMessage.value = ''

    try {
      const result = await authStore.login(identifier.value, password.value)

      if (result.success) {
        // 等待一下確保狀態已更新
        await new Promise(resolve => setTimeout(resolve, 100))
        router.push('/')
      } else {
        errorMessage.value = result.message || '登入失敗'
      }
    } catch (error) {
      errorMessage.value = error.message || '登入時發生錯誤'
      console.error('Login error:', error)
    }
  }
</script>

<style scoped lang="scss">
.login-wrapper {
  min-height: 100vh;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.login-container {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;

  :deep(.v-row) {
    margin: 0;
    width: 100%;
    height: 100%;
  }

  :deep(.v-col) {
    padding: 0;
    display: flex;
    align-items: center;
    justify-content: center;
  }
}

.login-card {
  border-radius: 20px;
  overflow: hidden;
  width: 100%;
  max-width: 500px;
  margin: 0 auto;
}

.login-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 30px;
  text-align: center;

  h1 {
    font-size: 2em;
    margin-bottom: 10px;
    font-weight: bold;
  }

  .version {
    font-size: 1em;
    opacity: 0.9;
  }
}

.login-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  color: white !important;
  font-weight: bold;
  height: 48px;
}
</style>
