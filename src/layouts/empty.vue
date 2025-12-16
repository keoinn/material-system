<template>
  <v-app>
    <v-main class="pa-0">
      <router-view />
    </v-main>
  </v-app>
</template>

<script setup>
// 空的 layout，不包含 app-bar 和 footer
// 用於登入頁面等不需要導航欄的頁面
</script>

<style scoped lang="scss">
:deep(.v-main) {
  padding: 0 !important;
}
</style>
