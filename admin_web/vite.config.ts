import { configDefaults, defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],

  // Google sign-in only works on origins registered for the OAuth client,
  // so keep the dev server on a fixed port.
  server: { port: 5173, strictPort: true },

  test: {
    exclude: [...configDefaults.exclude, 'e2e/**'],
    environment: 'jsdom',
    setupFiles: './src/setupTests.ts',
    globals: true,
  },
});
