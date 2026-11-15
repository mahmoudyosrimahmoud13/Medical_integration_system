/// <reference types="vitest" />
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

const apiTarget = process.env.VITE_PROXY_TARGET ?? 'http://localhost:8020';
// Addresses allowed to open the dev/preview server: this computer, Cloudflare quick tunnels
// (*.trycloudflare.com) and any of your own domains in VITE_ALLOWED_HOSTS (comma separated).
const allowedHosts = ['localhost', '.trycloudflare.com', ...(process.env.VITE_ALLOWED_HOSTS ?? '').split(',').map((h) => h.trim()).filter(Boolean)];
// /api and /Image go to the FastAPI backend, so there is no CORS setup to think about. The original
// address is kept (no changeOrigin), so image links point back through the tunnel, not to localhost.
const proxy = { '/api': { target: apiTarget }, '/Image': { target: apiTarget } };

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: { port: 5173, allowedHosts, proxy },
  preview: { port: 4173, allowedHosts, proxy },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    css: false,
    env: { VITE_API_BASE_URL: 'http://api.test' },
  },
});
