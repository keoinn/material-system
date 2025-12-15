/**
 * main.js
 *
 * Bootstraps Vuetify and other plugins then mounts the App`
 */

// Composables
import { createApp } from 'vue'

// Plugins
import { registerPlugins } from '@/plugins'

// Components
import App from './App.vue'

// Styles
import 'unfonts.css'
import 'sweetalert2/dist/sweetalert2.min.css'
import '@/styles/sweetalert.scss'

const app = createApp(App)

registerPlugins(app)

app.mount('#app')
