import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import ViteRails from 'vite-plugin-rails'

export default defineConfig({
  plugins: [react(), ViteRails()],
  server: {
    cors: {
      origin: ['https://dev.soundfy.app', 'https://soundfy.app'],
      credentials: true
    },
    allowedHosts: ['assets.soundfy.app'],
    hmr: {
      protocol: 'wss',
      host: 'assets.soundfy.app',
      clientPort: 443
    }
  },
})
