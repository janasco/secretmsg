/**
 * NOT CRYPTOGRAPHICALLY REVIEWED. The code under test implements an unaudited
 * protocol; passing these tests does not make it secure.
 *
 * Tests for the browser-side claim-link decryption. Node 22 provides
 * WebCrypto in the test environment, so this exercises the real primitives
 * without a browser.
 *
 * These tests prove format and failure behaviour, not security. The protocol
 * behind them is NOT CRYPTOGRAPHICALLY REVIEWED (see e2ee.ts).
 */

import { describe, expect, it } from 'vitest';

import {
  BODY_AAD,
  E2EE_PREFIX,
  b64urlDecode,
  b64urlEncode,
  decryptEnvelope,
  hasKeyFragment,
  isEncryptedContent,
  parseEnvelope,
  parseFragmentKey,
  redactUrl,
} from '@/lib/e2ee';

const KEY = Uint8Array.from({ length: 32 }, (_, i) => i);
const OTHER_KEY = new Uint8Array(32).fill(0xff);
const NONCE = Uint8Array.from({ length: 12 }, (_, i) => 0xa0 + i);

/** Builds an envelope exactly the way the Dart client would. */
async function makeEnvelope(plaintext: string, key: Uint8Array): Promise<string> {
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    new Uint8Array(key),
    { name: 'AES-GCM' },
    false,
    ['encrypt']
  );
  const ct = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: new Uint8Array(NONCE),
      additionalData: new TextEncoder().encode(BODY_AAD),
      tagLength: 128,
    },
    cryptoKey,
    new TextEncoder().encode(plaintext)
  );
  const json = {
    v: 1,
    alg: 'A256GCM',
    iv: b64urlEncode(NONCE),
    ct: b64urlEncode(new Uint8Array(ct)),
  };
  return `${E2EE_PREFIX}${b64urlEncode(new TextEncoder().encode(JSON.stringify(json)))}`;
}

describe('decryptEnvelope', () => {
  it('round-trips an envelope with the fragment key', async () => {
    const envelope = await makeEnvelope('claim-link secret', KEY);
    expect(await decryptEnvelope(envelope, KEY)).toBe('claim-link secret');
  });

  it('rejects the wrong key without returning ciphertext', async () => {
    const envelope = await makeEnvelope('claim-link secret', KEY);
    await expect(decryptEnvelope(envelope, OTHER_KEY)).rejects.toThrow();
  });

  it('rejects a tampered ciphertext', async () => {
    const envelope = await makeEnvelope('claim-link secret', KEY);
    const parsed = parseEnvelope(envelope);
    const ct = b64urlDecode(parsed.ct);
    ct[0] ^= 0x01;
    const tampered = `${E2EE_PREFIX}${b64urlEncode(
      new TextEncoder().encode(
        JSON.stringify({ ...parsed, ct: b64urlEncode(ct) })
      )
    )}`;
    await expect(decryptEnvelope(tampered, KEY)).rejects.toThrow();
  });
});

describe('envelope parsing', () => {
  it('detects the prefix only', () => {
    expect(isEncryptedContent('plain text')).toBe(false);
    expect(isEncryptedContent(`${E2EE_PREFIX}abc`)).toBe(true);
  });

  it('rejects plaintext, bad base64, and bad versions', async () => {
    expect(() => parseEnvelope('plain text')).toThrow();
    expect(() => parseEnvelope(`${E2EE_PREFIX}!!!`)).toThrow();
    const envelope = await makeEnvelope('x', KEY);
    const parsed = parseEnvelope(envelope);
    const badVersion = `${E2EE_PREFIX}${b64urlEncode(
      new TextEncoder().encode(JSON.stringify({ ...parsed, v: 2 }))
    )}`;
    expect(() => parseEnvelope(badVersion)).toThrow();
    const shortIv = `${E2EE_PREFIX}${b64urlEncode(
      new TextEncoder().encode(JSON.stringify({ ...parsed, iv: 'AAAA' }))
    )}`;
    expect(() => parseEnvelope(shortIv)).toThrow();
  });
});

describe('fragment key parsing', () => {
  it('reads a full claim link', () => {
    const link = `https://secretmsg.net/reply/rep_abc#k=${b64urlEncode(KEY)}`;
    expect(parseFragmentKey(link)).toEqual(KEY);
    expect(hasKeyFragment(link)).toBe(true);
  });

  it('reads a bare fragment with sibling parameters', () => {
    const fragment = `#x=1&k=${b64urlEncode(KEY)}&y=2`;
    expect(parseFragmentKey(fragment)).toEqual(KEY);
  });

  it('never honours a key in the query or path', () => {
    const b64 = b64urlEncode(KEY);
    expect(parseFragmentKey(`https://secretmsg.net/reply/t?k=${b64}`)).toBeNull();
    expect(parseFragmentKey(`https://secretmsg.net/reply/${b64}`)).toBeNull();
  });

  it('rejects absent, malformed, and wrong-size keys', () => {
    expect(parseFragmentKey('https://secretmsg.net/reply/t')).toBeNull();
    expect(parseFragmentKey('https://secretmsg.net/reply/t#')).toBeNull();
    expect(parseFragmentKey('https://secretmsg.net/reply/t#k=')).toBeNull();
    expect(parseFragmentKey('https://secretmsg.net/reply/t#k=AAAA')).toBeNull();
    expect(
      parseFragmentKey(`https://secretmsg.net/reply/t#k=${b64urlEncode(new Uint8Array(16))}`)
    ).toBeNull();
  });

  it('redacts fragments for logging', () => {
    const link = `https://secretmsg.net/reply/rep_abc#k=${b64urlEncode(KEY)}`;
    const redacted = redactUrl(link);
    expect(redacted).toBe('https://secretmsg.net/reply/rep_abc');
    expect(redacted).not.toContain(b64urlEncode(KEY));
  });
});
