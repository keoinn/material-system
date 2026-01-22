<template>
  <v-card>
    <v-card-title class="system-header">
      <h2>系統設定</h2>
    </v-card-title>

    <v-card-text class="pt-6">
      <div class="text-center py-12">
        <v-icon
          size="64"
          color="grey"
          class="mb-4"
        >
          mdi-tools
        </v-icon>
        <h3 class="text-h5 mb-2 text-grey">
          功能開發中
        </h3>
        <p class="text-body-1 text-grey-darken-1">
          此功能正在開發中，敬請期待
        </p>
      </div>
    </v-card-text>
  </v-card>
</template>

<script setup>
  // 功能開發中 - 暫時不需要任何邏輯
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';
</style>
