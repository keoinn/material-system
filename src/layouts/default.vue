<template>
  <v-app>
    <!-- 只有在已登入且不是 Guest 時才顯示 toolbar -->
    <v-app-bar
      v-if="authStore.isLoggedIn && authStore.currentUser && authStore.currentUser.username !== 'Guest'"
      color="primary"
      elevation="2"
      prominent
    >
      <v-app-bar-title>
        <div class="d-flex align-center">
          <v-icon class="mr-2">mdi-package-variant</v-icon>
          <span>物料編碼申請管理系統</span>
          <v-chip
            class="ml-2"
            color="white"
            size="small"
            text-color="primary"
          >
            V3.6
          </v-chip>
        </div>
      </v-app-bar-title>

      <v-spacer />

      <v-menu>
        <template #activator="{ props }">
          <v-btn
            icon
            v-bind="props"
          >
            <v-icon>mdi-account-circle</v-icon>
          </v-btn>
        </template>
        <v-list>
          <v-list-item>
            <v-list-item-title>
              {{ authStore.currentUser?.username }}
            </v-list-item-title>
            <v-list-item-subtitle>
              {{ getRoleText(authStore.currentUser?.role) }}
            </v-list-item-subtitle>
          </v-list-item>
          <v-divider />
          <v-list-item @click="handleLogout">
            <v-list-item-title>登出</v-list-item-title>
            <template #prepend>
              <v-icon>mdi-logout</v-icon>
            </template>
          </v-list-item>
        </v-list>
      </v-menu>
    </v-app-bar>

    <v-main>
      <router-view />
    </v-main>

    <!-- 只有在已登入時才顯示 footer -->
    <AppFooter v-if="authStore.isLoggedIn && authStore.currentUser && authStore.currentUser.username !== 'Guest'" />
  </v-app>
</template>

<script setup>
  import { useRouter } from 'vue-router'
  import AppFooter from '@/components/AppFooter.vue'
  import { useAuthStore } from '@/stores/auth'

  const router = useRouter()
  const authStore = useAuthStore()

  /**
   * 將角色代碼轉換為中文顯示
   */
  function getRoleText (role) {
    const roleMap = {
      admin: '系統管理員',
      approver: '審核人員',
      applicant: '申請人員',
    }
    return roleMap[role] || role || '未知'
  }

  function handleLogout () {
    authStore.logout()
    router.push('/login')
  }
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';
</style>
