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
        // Kept in step with the semantic tokens in src/index.css: the accent
        // and the 950/900 pair are asserted to match by index.css.test.ts, so
        // the two files cannot drift apart silently.
        dark: {
          950: '#08090d',
          900: '#0f1116',
          850: '#161922',
          800: '#1e222d',
          700: '#2b3242',
        },
        accent: {
          primary: '#8b7cff',
          glow: '#ada2ff',
          gold: '#fbbf24',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
