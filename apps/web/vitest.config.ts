import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  test: {
    environment: 'node',
    // The static-analysis tool in scripts/ carries its own tests. They live
    // beside the tool rather than in src/ so the Tailwind content glob
    // (`./src/**\/*.{js,ts,jsx,tsx}`, scanned as raw text) does not see the
    // palette tables and start emitting utilities nothing uses.
    include: ['src/**/*.test.ts', 'scripts/**/*.test.mjs'],
  },
});
