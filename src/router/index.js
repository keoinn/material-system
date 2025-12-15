/**
 * router/index.ts
 *
 * Automatic routes for `./src/pages/*.vue`
 */

import { setupLayouts } from 'virtual:generated-layouts'
// Composables
import { createRouter, createWebHistory } from 'vue-router/auto'
import { routes } from 'vue-router/auto-routes'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: setupLayouts(routes),
})

// Workaround for https://github.com/vitejs/vite/issues/11804
router.onError((err, to) => {
  if (err?.message?.includes?.('Failed to fetch dynamically imported module')) {
    if (localStorage.getItem('vuetify:dynamic-reload')) {
      console.error('Dynamic import error, reloading page did not fix it', err)
    } else {
      console.log('Reloading page to fix dynamic import error')
      localStorage.setItem('vuetify:dynamic-reload', 'true')
      location.assign(to.fullPath)
    }
  } else {
    console.error(err)
  }
})

router.isReady().then(() => {
  localStorage.removeItem('vuetify:dynamic-reload')
})

// 路由守衛
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  // 檢查認證狀態
  const isAuthenticated = authStore.checkAuth()

  // 如果前往登入頁面且已登入，重導向到首頁
  if (to.path === '/login' && isAuthenticated) {
    next('/')
    return
  }

  // 如果需要認證的頁面但未登入，重導向到登入頁面
  // 確保清除任何殘留的認證狀態
  if (to.path !== '/login' && !isAuthenticated) {
    // 確保清除狀態
    if (authStore.user || authStore.isAuthenticated) {
      authStore.logout()
    }
    next('/login')
    return
  }

  // 如果已登入但用戶資料為空，清除認證狀態
  if (isAuthenticated && !authStore.currentUser) {
    authStore.logout()
    next('/login')
    return
  }

  next()
})

export default router
