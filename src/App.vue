<template>
  <v-app>
    <router-view />
  </v-app>
</template>

<script setup>
  //
</script>

<style lang="scss">
@import '@/styles/material-system.scss';
@import '@/styles/variables.scss';

// 全局樣式：必填欄位的紅色星號
.v-label__asterisk {
  color: #f44336 !important;
}

.v-label .v-label__asterisk {
  color: #f44336 !important;
}

.v-field-label .v-label__asterisk {
  color: #f44336 !important;
}

.v-field-label--floating .v-label__asterisk {
  color: #f44336 !important;
}

.v-field .v-field-label .v-label__asterisk {
  color: #f44336 !important;
}

.v-input .v-label__asterisk {
  color: #f44336 !important;
}
</style>
