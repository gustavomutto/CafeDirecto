import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Configuración mínima. Para abrir desde el celular en la misma red wifi:
//   npm run dev -- --host
export default defineConfig({
  plugins: [react()],
  base: './',
  server: {
    host: '127.0.0.1',
    port: 5173,
    strictPort: true,
  },
});
