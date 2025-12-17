<route lang="yaml">
meta:
  layout: empty
</route>

<template>
  <div class="register-wrapper">
    <v-container class="register-container" fluid>
      <v-row align="center" class="fill-height" justify="center">
        <v-col cols="12" lg="5" md="6" sm="8">
          <v-card class="register-card" elevation="8">
            <div class="register-header">
              <h1>註冊帳號</h1>
              <div class="subtitle">物料編碼申請管理系統</div>
            </div>

            <v-card-text>
              <v-form ref="formRef" v-model="valid" @submit.prevent="handleRegister">
                <v-text-field
                  v-model="form.email"
                  class="mb-4"
                  label="Email *"
                  prepend-inner-icon="mdi-email"
                  :rules="[rules.required, rules.email]"
                  required
                  variant="outlined"
                  autocomplete="email"
                  type="email"
                />

                <v-text-field
                  v-model="form.username"
                  class="mb-4"
                  label="姓名 *"
                  prepend-inner-icon="mdi-account"
                  :rules="[rules.required, rules.username]"
                  required
                  variant="outlined"
                  autocomplete="username"
                />

                <v-text-field
                  v-model="form.password"
                  class="mb-4"
                  label="密碼 *"
                  prepend-inner-icon="mdi-lock"
                  :rules="[rules.required, rules.password]"
                  required
                  type="password"
                  variant="outlined"
                  autocomplete="new-password"
                />

                <v-text-field
                  v-model="form.confirmPassword"
                  class="mb-4"
                  label="確認密碼 *"
                  prepend-inner-icon="mdi-lock-check"
                  :rules="[rules.required, rules.confirmPassword]"
                  required
                  type="password"
                  variant="outlined"
                  autocomplete="new-password"
                />

                <v-text-field
                  v-model="form.department"
                  class="mb-4"
                  label="部門"
                  prepend-inner-icon="mdi-office-building"
                  variant="outlined"
                />

                <v-text-field
                  v-model="form.phone"
                  class="mb-4"
                  label="電話"
                  prepend-inner-icon="mdi-phone"
                  variant="outlined"
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

                <v-alert
                  v-if="successMessage"
                  class="mb-4"
                  type="success"
                  variant="tonal"
                >
                  {{ successMessage }}
                </v-alert>

                <v-btn
                  block
                  class="register-btn"
                  color="primary"
                  :disabled="loading || !valid"
                  :loading="loading"
                  size="large"
                  type="submit"
                >
                  註冊
                </v-btn>
              </v-form>

              <div class="mt-4 text-center">
                <v-btn
                  color="primary"
                  variant="text"
                  @click="router.push('/login')"
                >
                  <v-icon class="mr-2">mdi-arrow-left</v-icon>
                  返回登入
                </v-btn>
              </div>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script setup>
  import { computed, onMounted, reactive, ref } from 'vue'
  import { useRouter } from 'vue-router'
  import { useAuthStore } from '@/stores/auth'

  const router = useRouter()
  const authStore = useAuthStore()

  const formRef = ref(null)
  const valid = ref(false)
  const loading = computed(() => authStore.loading)
  const errorMessage = ref('')
  const successMessage = ref('')

  const form = reactive({
    email: '',
    username: '',
    password: '',
    confirmPassword: '',
    department: '',
    phone: '',
  })

  const rules = {
    required: value => !!value || '此欄位為必填',
    email: value => {
      if (!value) return true
      const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      return pattern.test(value) || '請輸入有效的 Email 格式'
    },
    username: value => {
      if (!value) return true
      if (value.length < 2) return '姓名至少需要 2 個字元'
      if (value.length > 50) return '姓名不能超過 50 個字元'
      // 允許中文、英文、數字和常見符號
      const pattern = /^[\u4e00-\u9fa5a-zA-Z0-9_\s\-\.]+$/
      return pattern.test(value) || '姓名只能包含中文、英文字母、數字和常見符號'
    },
    password: value => {
      if (!value) return true
      if (value.length < 6) return '密碼至少需要 6 個字元'
      return true
    },
    confirmPassword: value => {
      if (!value) return true
      return value === form.password || '密碼不一致'
    },
  }

  async function handleRegister () {
    const { valid: isValid } = await formRef.value.validate()
    if (!isValid) {
      return
    }

    errorMessage.value = ''
    successMessage.value = ''

    try {
      const result = await authStore.register({
        email: form.email,
        username: form.username,
        password: form.password,
        department: form.department || null,
        phone: form.phone || null,
      })

      if (result.success) {
        successMessage.value = '註冊成功！請等待管理員審核啟用後即可登入。'
        // 清空表單
        Object.assign(form, {
          email: '',
          username: '',
          password: '',
          confirmPassword: '',
          department: '',
          phone: '',
        })
        formRef.value?.resetValidation()
        // 3 秒後跳轉到登入頁面
        setTimeout(() => {
          router.push('/login')
        }, 3000)
      } else {
        errorMessage.value = result.message || '註冊失敗'
      }
    } catch (error) {
      errorMessage.value = error.message || '註冊時發生錯誤'
      console.error('Register error:', error)
    }
  }

  // 處理必填欄位的紅色星號
  function styleRequiredAsterisks () {
    // 使用 nextTick 確保 DOM 已渲染
    setTimeout(() => {
      const labels = document.querySelectorAll('.v-field-label')
      for (const label of labels) {
        if (label.textContent && label.textContent.includes('*')) {
          // 創建一個 span 來包裹星號
          const text = label.textContent.trim()
          const asteriskIndex = text.indexOf('*')
          if (asteriskIndex !== -1) {
            const beforeAsterisk = text.slice(0, asteriskIndex)
            const asterisk = text.slice(asteriskIndex)
            // 清空 label 內容
            label.innerHTML = ''
            // 添加文字部分
            if (beforeAsterisk) {
              label.append(document.createTextNode(beforeAsterisk))
            }
            // 添加紅色星號
            const asteriskSpan = document.createElement('span')
            asteriskSpan.textContent = asterisk
            asteriskSpan.style.color = '#f44336'
            asteriskSpan.style.fontWeight = 'bold'
            label.append(asteriskSpan)
          }
        }
      }
    }, 200)
  }

  onMounted(() => {
    styleRequiredAsterisks()
    // 當表單驗證狀態改變時，重新處理星號樣式
    const formElement = formRef.value?.$el
    if (formElement) {
      const observer = new MutationObserver(() => {
        styleRequiredAsterisks()
      })
      observer.observe(formElement, {
        childList: true,
        subtree: true,
      })
    }
  })
</script>

<style scoped lang="scss">
.register-wrapper {
  min-height: 100vh;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.register-container {
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

.register-card {
  border-radius: 20px;
  overflow: hidden;
  width: 100%;
  max-width: 600px;
  margin: 0 auto;
}

.register-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 30px;
  text-align: center;

  h1 {
    font-size: 2em;
    margin-bottom: 10px;
    font-weight: bold;
  }

  .subtitle {
    font-size: 1em;
    opacity: 0.9;
  }
}

.register-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  color: white !important;
  font-weight: bold;
  height: 48px;
}

// 必填欄位的紅色星號
:deep(.v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label--floating .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field .v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-input .v-label__asterisk) {
  color: #f44336 !important;
}
</style>

