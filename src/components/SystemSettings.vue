<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>系統設定</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <!-- 編碼規則設定 -->
      <div class="form-section">
        <h3>編碼規則設定</h3>
        <v-row>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="codeFormat"
              bg-color="grey-lighten-4"
              label="編碼格式"
              readonly
              variant="outlined"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="localSettings.serialDigits"
              :items="serialDigitOptions"
              label="流水號位數"
              variant="outlined"
            />
          </v-col>
        </v-row>
      </div>

      <!-- 審核流程設定 -->
      <div class="form-section">
        <h3>審核流程設定</h3>
        <v-row>
          <v-col cols="12" md="6">
            <v-select
              v-model="localSettings.autoApprove"
              :items="booleanOptions"
              label="自動審核"
              variant="outlined"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="localSettings.emailNotify"
              :items="booleanOptions"
              label="Email通知"
              variant="outlined"
            />
          </v-col>
        </v-row>
      </div>

      <v-progress-linear
        v-if="loading"
        indeterminate
        color="primary"
        class="mb-4"
      />

      <div class="d-flex justify-center gap-4 mt-4">
        <v-btn
          color="primary"
          size="large"
          :loading="loading"
          :disabled="loading"
          @click="saveSettings"
        >
          儲存設定
        </v-btn>
        <v-btn
          color="warning"
          size="large"
          :loading="loading"
          :disabled="loading"
          @click="resetSettings"
        >
          恢復預設
        </v-btn>
      </div>
    </v-card-text>
  </v-card>
</template>

<script setup>
  import { onMounted, reactive, ref } from 'vue'
  import { useSwal } from '@/composables/useSwal'
  import { settingsService } from '@/api/services/settings'

  const swal = useSwal()

  const codeFormat = ref('{大類}{中類}.{小類}.{流水號}')
  const loading = ref(false)

  const localSettings = reactive({
    serialDigits: 5,
    autoApprove: false,
    emailNotify: true,
  })

  const serialDigitOptions = [
    { title: '4位數', value: 4 },
    { title: '5位數', value: 5 },
    { title: '6位數', value: 6 },
  ]

  const booleanOptions = [
    { title: '開啟', value: true },
    { title: '關閉', value: false },
  ]

  // 載入設定
  async function loadSettings () {
    loading.value = true
    try {
      const settings = await settingsService.getSettings()
      Object.assign(localSettings, {
        serialDigits: settings.serialDigits ?? 5,
        autoApprove: settings.autoApprove ?? false,
        emailNotify: settings.emailNotify ?? true,
      })
    } catch (error) {
      console.error('載入設定失敗', error)
      await swal.error('載入設定失敗', error.message || '無法取得系統設定')
    } finally {
      loading.value = false
    }
  }

  async function saveSettings () {
    loading.value = true
    try {
      await settingsService.updateSettings({
        serialDigits: localSettings.serialDigits,
        autoApprove: localSettings.autoApprove,
        emailNotify: localSettings.emailNotify,
      })
      await swal.success('設定已儲存成功！')
    } catch (error) {
      console.error('儲存設定失敗', error)
      await swal.error('儲存設定失敗', error.message || '儲存設定時發生錯誤')
    } finally {
      loading.value = false
    }
  }

  async function resetSettings () {
    const result = await swal.confirm('確定要恢復預設設定嗎？', '確認重置')
    if (result.isConfirmed) {
      loading.value = true
      try {
        // 恢復預設值
        const defaultSettings = {
          serialDigits: 5,
          autoApprove: false,
          emailNotify: true,
        }
        await settingsService.updateSettings(defaultSettings)
        Object.assign(localSettings, defaultSettings)
        await swal.success('已恢復預設設定！')
      } catch (error) {
        console.error('恢復預設設定失敗', error)
        await swal.error('恢復預設設定失敗', error.message || '恢復預設設定時發生錯誤')
      } finally {
        loading.value = false
      }
    }
  }

  // 組件掛載時載入設定
  onMounted(() => {
    loadSettings()
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.form-section {
  margin-bottom: 30px;
  padding: 25px;
  background: #f8f9fa;
  border-radius: 10px;

  h3 {
    color: #667eea;
    margin-bottom: 20px;
    font-size: 1.3em;
    border-bottom: 2px solid #667eea;
    padding-bottom: 10px;
  }
}

.gap-4 {
  gap: 16px;
}
</style>
