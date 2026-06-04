/**
 * plugins/index.js
 *
 * Automatically included in `./src/main.js`
 */

import router from '@/router'
import pinia from '@/stores'
// Plugins
import vuetify from './vuetify'
import VueExcelEditor from 'vue3-excel-editor'

export function registerPlugins (app) {
  app
    .use(vuetify)
    .use(pinia)
    .use(router)
    .use(VueExcelEditor)
}
