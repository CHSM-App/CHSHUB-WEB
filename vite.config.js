import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath, URL } from 'node:url';

// The frontend is a standalone app: it talks to the backend only over HTTP.
// In dev, /api is proxied to the Express server so the browser sees one origin
// and no CORS or cookie-domain special cases are needed.
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  build: {
    // Vite 8 bundles with rolldown, which exposes chunking under
    // rolldownOptions rather than rollupOptions. Splitting the framework out
    // keeps the app chunk small and lets the vendor chunk stay cached across
    // deployments.
    rolldownOptions: {
      output: {
        advancedChunks: {
          groups: [
            { name: 'react', test: /node_modules[\\/](react|react-dom|react-router|react-router-dom)[\\/]/ },
            // jsPDF and html2canvas are only pulled in when someone exports, so
            // they get their own chunk instead of being folded into vendor —
            // otherwise every visitor downloads ~600 kB they will never use.
            { name: 'pdf-vendor', test: /node_modules[\\/](jspdf|html2canvas|canvg|core-js|raf|rgbcolor)[\\/]/ },
            // Same reasoning for the spreadsheet parser: only the Import Data
            // modal needs it, so it must not sit in the shared vendor chunk.
            { name: 'xlsx-vendor', test: /node_modules[\\/](xlsx|cfb|codepage|crc-32|adler-32)[\\/]/ },
            { name: 'vendor', test: /node_modules[\\/]/ },
          ],
        },
      },
    },
    chunkSizeWarningLimit: 700,
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: process.env.VITE_API_TARGET || 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.js',
    css: false,
  },
});
