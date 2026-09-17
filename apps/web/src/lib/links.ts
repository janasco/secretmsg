/**
 * Anonymous device fingerprint + public URL helpers.
 * Split out of api.ts so the client stays under the 400-line quality gate.
 * Single-host app: account routes (/login, /inbox, /settings) live on the
 * same public host — there is no separate account subdomain.
 */

import { PUBLIC_BASE_URL } from '@/lib/config';

/**
 * Stable anonymous device fingerprint, persisted per-browser. The server keeps
 * only its SHA-256, so recipients never see the raw value; it exists solely so
 * a blocked device cannot keep submitting. Generated once and reused forever.
 */
export function getDeviceFingerprint(): string {
  const KEY = 'secretmsg_device_fingerprint';
  let fp = localStorage.getItem(KEY);
  if (fp) return fp;
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const maxValid = 256 - (256 % chars.length);
  const out: string[] = Array.from({ length: 32 }, () => '');
  for (let i = 0; i < 32; i++) {
    const b = new Uint8Array(1);
    let v: number;
    do {
      crypto.getRandomValues(b);
      v = b[0];
    } while (v >= maxValid);
    out[i] = chars[v % chars.length];
  }
  fp = out.join('');
  localStorage.setItem(KEY, fp);
  return fp;
}

/**
 * Returns the public submission link that recipients share with visitors.
 */
export function getShareUrl(username: string): string {
  return `${PUBLIC_BASE_URL}/${encodeURIComponent(username)}`;
}
