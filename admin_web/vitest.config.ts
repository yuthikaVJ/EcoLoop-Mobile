import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

// Tests live in tests/, one file per service, component and page (mirrors src/).
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
    include: ['tests/**/*.test.{ts,tsx}'],
    env: {
      VITE_API_BASE_URL: 'http://api.test',
      VITE_GOOGLE_CLIENT_ID: 'test-client-id',
    },
  },
});
