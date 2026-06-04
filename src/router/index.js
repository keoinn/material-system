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

// 不需要認證的頁面路徑
const publicPaths = ['/login', '/register', '/testing']

// 路由守衛
router.beforeEach(async (to, from, next) => {
  try {
    const authStore = useAuthStore()

    // 檢查是否為公開頁面
    const isPublicPath = publicPaths.some(path => to.path.startsWith(path))

    // 如果是公開頁面，直接允許訪問
    if (isPublicPath) {
      next()
      return
    }

    let isAuthenticated = false
    try {
      await authStore.waitForAuthReady()
      isAuthenticated = await authStore.checkAuth()
    } catch (error) {
      console.error('認證檢查失敗', error)
      isAuthenticated = false
      if (authStore.loading) {
        authStore.loading = false
      }
    }

    // 如果前往登入頁面且已登入，重導向到首頁
    if (to.path === '/login' && isAuthenticated) {
      next('/')
      return
    }

    // 如果需要認證的頁面但未登入，重導向到登入頁面
    if (!isPublicPath && !isAuthenticated) {
      // 確保清除狀態（不阻塞路由）
      Promise.resolve().then(async () => {
        try {
          if (authStore.user || authStore.isAuthenticated) {
            await authStore.logout()
          }
        } catch (error) {
          console.error('登出失敗', error)
        }
      })
      next('/login')
      return
    }

    // 如果已登入但用戶資料為空，清除認證狀態
    if (isAuthenticated && !authStore.currentUser) {
      // 不阻塞路由，異步清除狀態
      Promise.resolve().then(async () => {
        try {
          await authStore.logout()
        } catch (error) {
          console.error('登出失敗', error)
        }
      })
      next('/login')
      return
    }

    next()
  } catch (error) {
    console.error('路由守衛錯誤', error)
    // 發生錯誤時，重導向到登入頁面
    next('/login')
  }
})

export default router
