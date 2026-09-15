/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string;
  readonly VITE_PUBLIC_URL?: string;
  readonly VITE_USE_MOCK?: string;
  readonly VITE_TURNSTILE_SITE_KEY?: string;
  readonly VITE_DONATION_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
