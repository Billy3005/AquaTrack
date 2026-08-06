import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

// The console talks to the FastAPI backend at /api/v1/admin. In dev we proxy
// instead of pointing the browser straight at the API — same-origin requests
// keep the app free of CORS surprises when it is later served from the API host.
//
// VITE_API_TARGET picks the backend. Read it from a .env file as well as the
// shell, because `VITE_API_TARGET=... npm run dev` is bash syntax that silently
// does nothing in PowerShell — you get the localhost default and a screen full
// of ECONNREFUSED. Put the value in aquatrack_admin/.env.local instead (already
// gitignored) and plain `npm run dev` works on every shell.
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const proxy = {
    '/api': {
      target: env.VITE_API_TARGET || 'http://localhost:8000',
      changeOrigin: true,
      // The Railway host routes on SNI/Host; without this the edge answers
      // "Application not found" instead of reaching the app.
      secure: true,
    },
  };

  return {
    plugins: [react()],
    // `server` and `preview` are separate config sections in Vite — preview does
    // NOT inherit server.proxy, so `npm run preview` used to 404 on every /api
    // call. Both get the same proxy here.
    server: { port: 5173, proxy },
    preview: { port: 4173, proxy },
    build: {
      outDir: 'dist',
      sourcemap: true,
    },
  };
});
