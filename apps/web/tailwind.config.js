/** @type {import('tailwindcss').Config} */
export default {
  // Scanned as raw text, not as modules: every file under src/ counts,
  // comments and Worker-only files included. A stray word that happens to be a
  // utility name ("inline" is the one that has bitten) adds a rule, changes the
  // stylesheet hash and rehashes the whole bundle for a rule nothing uses.
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        dark: {
          950: '#090a0f',
          900: '#0f111a',
          850: '#141824',
          800: '#1b2030',
          700: '#2b324a',
        },
        accent: {
          primary: '#6366f1', // Indigo
          glow: '#818cf8',
          gold: '#f59e0b',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
