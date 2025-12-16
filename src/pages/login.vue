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
                  v-model="username"
                  class="mb-4"
                  label="使用者名稱"
                  prepend-inner-icon="mdi-account"
                  :rules="[rules.required]"
                  variant="outlined"
                />

                <v-text-field
                  v-model="password"
                  class="mb-4"
                  label="密碼"
                  prepend-inner-icon="mdi-lock"
                  :rules="[rules.required]"
                  type="password"
                  variant="outlined"
                />

                <v-alert
                  v-if="errorMessage"
                  class="mb-4"
                  type="error"
                  variant="tonal"
                >
                  {{ errorMessage }}
                </v-alert>

                <v-btn
                  block
                  class="login-btn"
                  color="primary"
                  :loading="loading"
                  size="large"
                  type="submit"
                >
                  登入
                </v-btn>
              </v-form>

              <div class="mt-4 text-center">
                <small class="text-grey">
                  提示：可使用 admin 或 user 登入（開發模式）
                </small>
              </div>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script setup>
  import { ref } from 'vue'
  import { useRouter } from 'vue-router'
  import { useAuthStore } from '@/stores/auth'

  const router = useRouter()
  const authStore = useAuthStore()

  const username = ref('')
  const password = ref('')
  const loading = ref(false)
  const errorMessage = ref('')

  const rules = {
    required: value => !!value || '此欄位為必填',
  }

  async function handleLogin () {
    if (!username.value || !password.value) {
      errorMessage.value = '請輸入使用者名稱和密碼'
      return
    }

    loading.value = true
    errorMessage.value = ''

    try {
      const result = authStore.login(username.value, password.value)

      if (result.success) {
        router.push('/')
      } else {
        errorMessage.value = result.message || '登入失敗'
      }
    } catch (error) {
      errorMessage.value = '登入時發生錯誤'
      console.error('Login error:', error)
    } finally {
      loading.value = false
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
