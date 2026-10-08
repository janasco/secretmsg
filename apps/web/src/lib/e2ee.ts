/**
 * NOT CRYPTOGRAPHICALLY REVIEWED. This module has not been reviewed by any
 * cryptographer and no third party has audited the protocol it implements.
 * Crypto bugs fail silently: a flaw here would not throw, it would simply
 * fail to protect. Do not describe the result as reviewed or as protection
 * against a malicious server. See
 * apps/mobile-flutter/lib/crypto/README.md for the unverified properties
 * (protocol design, key-exchange authenticity, forward secrecy, replay
 * resistance).
 *
 * Claim-link decryption for the browser.
 *
 * A blind-reply claim link carries the per-message content key in the URL
 * fragment:
 *
 *   https://secretmsg.net/reply/<token>#k=<base64url 32-byte key>
 *
 * Browsers never transmit fragments, so the server sees only the token. This
 * module reads the fragment locally and uses WebCrypto AES-256-GCM to decrypt
 * the stored envelopes. The key is never put in a request, a log line, or a
 * URL we build for an API call; `redactUrl` drops fragments for any logging.
 *
 * Honest limits: anyone holding the full link can read the thread; fragments
 * can leak via clipboard sync, screenshots, or a hostile client environment;
 * the browser cannot verify that the JavaScript it is running is the code a
 * reviewer saw (server compromise can change it).
 */

export const E2EE_PREFIX = 'enc:v1:';

/** AAD for the message body, matching the Dart client and the Worker. */
export const BODY_AAD = 'secretmsg-body-v1';

export interface EncryptedEnvelope {
  v: number;
  alg: string;
  iv: string;
  ct: string;
  wraps?: unknown[];
}

/** True when a stored string is an end-to-end encrypted envelope. */
export function isEncryptedContent(content: string): boolean {
  return typeof content === 'string' && content.startsWith(E2EE_PREFIX);
}

/** Unpadded base64url decode. Throws on malformed input. */
export function b64urlDecode(input: string): Uint8Array {
  if (!/^[A-Za-z0-9_-]*$/.test(input)) {
    throw new Error('Invalid base64url');
  }
  const normalized = input.replace(/-/g, '+').replace(/_/g, '/');
  const padded = normalized + '='.repeat((4 - (normalized.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** Unpadded base64url encode. */
export function b64urlEncode(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/**
 * Parses an `enc:v1:` storage string. Strict on purpose: a malformed envelope
 * must never be rendered as if it were plaintext.
 */
export function parseEnvelope(content: string): EncryptedEnvelope {
  if (!isEncryptedContent(content)) {
    throw new Error('Not an encrypted envelope');
  }
  const decoded = new TextDecoder().decode(
    b64urlDecode(content.slice(E2EE_PREFIX.length))
  );
  const parsed = JSON.parse(decoded) as unknown;
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('Malformed envelope');
  }
  const envelope = parsed as Record<string, unknown>;
  if (envelope.v !== 1 || envelope.alg !== 'A256GCM') {
    throw new Error('Unsupported envelope version or algorithm');
  }
  if (typeof envelope.iv !== 'string' || typeof envelope.ct !== 'string') {
    throw new Error('Malformed envelope fields');
  }
  if (b64urlDecode(envelope.iv).length !== 12) {
    throw new Error('Bad nonce length');
  }
  if (b64urlDecode(envelope.ct).length < 16) {
    throw new Error('Ciphertext shorter than its tag');
  }
  return envelope as unknown as EncryptedEnvelope;
}

/**
 * Extracts the 32-byte content key from a `#k=...` fragment (or a bare
 * fragment string). Returns null when absent or malformed. Query parameters
 * and the path are ignored: a link that put the key there was never valid.
 */
export function parseFragmentKey(hashOrUrl: string): Uint8Array | null {
  let fragment = '';
  if (hashOrUrl.startsWith('#')) {
    fragment = hashOrUrl.slice(1);
  } else {
    try {
      fragment = new URL(hashOrUrl).hash.slice(1);
    } catch {
      return null;
    }
  }
  if (!fragment) return null;
  const params = new URLSearchParams(fragment);
  const raw = params.get('k');
  if (!raw) return null;
  try {
    const bytes = b64urlDecode(raw);
    return bytes.length === 32 ? bytes : null;
  } catch {
    return null;
  }
}

/** True when the URL/fragment carries a valid key. */
export function hasKeyFragment(hashOrUrl: string): boolean {
  return parseFragmentKey(hashOrUrl) !== null;
}

/**
 * Decrypts an envelope with a raw 32-byte key using WebCrypto AES-256-GCM.
 * Throws on authentication failure; callers must render a failure state, not
 * the ciphertext.
 */
export async function decryptEnvelope(
  content: string | EncryptedEnvelope,
  key: Uint8Array
): Promise<string> {
  if (key.length !== 32) throw new Error('Content key must be 32 bytes');
  const envelope: EncryptedEnvelope =
    typeof content === 'string' ? parseEnvelope(content) : content;
  // Fresh copies pin the backing buffer to ArrayBuffer (not SharedArrayBuffer),
  // which is what BufferSource accepts under current TypeScript lib versions.
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    new Uint8Array(key),
    { name: 'AES-GCM' },
    false,
    ['decrypt']
  );
  const clear = await crypto.subtle.decrypt(
    {
      name: 'AES-GCM',
      iv: new Uint8Array(b64urlDecode(envelope.iv)),
      additionalData: new TextEncoder().encode(BODY_AAD),
      tagLength: 128,
    },
    cryptoKey,
    new Uint8Array(b64urlDecode(envelope.ct))
  );
  return new TextDecoder().decode(clear);
}

/** Removes the fragment from a URL so it can be logged without the key. */
export function redactUrl(url: string): string {
  try {
    const parsed = new URL(url);
    parsed.hash = '';
    return parsed.toString();
  } catch {
    const withoutHash = url.split('#')[0];
    return withoutHash || '<unparseable url>';
  }
}
