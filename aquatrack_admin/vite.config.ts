import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The console talks to the FastAPI backend at /api/v1/admin. In dev we proxy
// instead of pointing the browser straight at :8000 — same-origin requests keep
// the app free of CORS surprises when it is later served from the API host.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: process.env.VITE_API_TARGET || 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
});
