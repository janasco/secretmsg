import React, { useEffect, useState } from 'react';
import { BadgeCheck, ShieldAlert } from 'lucide-react';
import { BoxApi, type VerifiedAttestation } from './box-api';

/**
 * Server-signed verified-sender badge.
 *
 * The badge is metadata that travels outside the encrypted payload; it is
 * rendered only after the Ed25519 signature verifies against the platform key
 * fetched over HTTPS. Any failure — unknown key id, bad signature, expired
 * attestation, network error — renders nothing at all (fail closed). Local
 * state is never a source of a badge.
 */

const keyCache = new Map<string, CryptoKey>();

function base64ToBytes(b64: string): ArrayBuffer {
  const bin = atob(b64.replace(/-/g, '+').replace(/_/g, '/'));
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer as ArrayBuffer;
}

function canonicalBody(a: VerifiedAttestation): string {
  // Must match canonicalAttestationBody() in api/src/social.ts byte for byte.
  return `sm-verified:v1|${a.message_id}|${a.claim_type}|${a.claim_text}|${a.verified_at}|${a.expires_at}|${a.key_id}`;
}

async function loadPublicKey(keyId: string): Promise<CryptoKey | null> {
  const cached = keyCache.get(keyId);
  if (cached) return cached;
  try {
    const res = await BoxApi.getVerifiedPublicKey();
    if (res.key_id !== keyId || !res.public_key) return null;
    const key = await crypto.subtle.importKey(
      'spki',
      base64ToBytes(res.public_key),
      { name: 'Ed25519' },
      false,
      ['verify'],
    );
    keyCache.set(keyId, key);
    return key;
  } catch {
    return null;
  }
}

async function verifyAttestation(a: VerifiedAttestation): Promise<boolean> {
  const key = await loadPublicKey(a.key_id);
  if (!key) return false;
  try {
    return await crypto.subtle.verify(
      { name: 'Ed25519' },
      key,
      base64ToBytes(a.signature),
      new TextEncoder().encode(canonicalBody(a)),
    );
  } catch {
    return false;
  }
}

type BadgeState =
  | { kind: 'hidden' }
  | { kind: 'valid'; attestation: VerifiedAttestation }
  | { kind: 'revoked'; attestation: VerifiedAttestation };

interface VerifiedBadgeProps {
  messageId: string;
}

export const VerifiedBadge: React.FC<VerifiedBadgeProps> = ({ messageId }) => {
  const [state, setState] = useState<BadgeState>({ kind: 'hidden' });

  useEffect(() => {
    let alive = true;
    setState({ kind: 'hidden' });
    BoxApi.getAttestation(messageId)
      .then(async (res) => {
        if (!alive || !res.attestation) return;
        const valid = await verifyAttestation(res.attestation);
        if (!alive || !valid) return;
        if (res.attestation.revoked) {
          setState({ kind: 'revoked', attestation: res.attestation });
          return;
        }
        if (res.attestation.expires_at * 1000 < Date.now()) return; // stale: show nothing
        setState({ kind: 'valid', attestation: res.attestation });
      })
      .catch(() => {
        // Fail closed: no badge on any error.
      });
    return () => { alive = false; };
  }, [messageId]);

  if (state.kind === 'hidden') return null;

  const a = state.attestation;
  const date = new Date(a.verified_at * 1000).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });

  if (state.kind === 'revoked') {
    return (
      <div className="inline-flex items-center gap-1.5 rounded-full border border-amber-500/30 bg-amber-500/10 px-2.5 py-1 text-[11px] text-amber-300">
        <ShieldAlert className="h-3.5 w-3.5" aria-hidden="true" />
        Verification revoked
      </div>
    );
  }

  return (
    <details className="group inline-block">
      <summary className="inline-flex cursor-pointer list-none items-center gap-1.5 rounded-full border border-sky-500/30 bg-sky-500/10 px-2.5 py-1 text-[11px] text-sky-300 marker:content-none">
        <BadgeCheck className="h-3.5 w-3.5" aria-hidden="true" />
        {a.claim_text}
        <span className="text-sky-400/70">· checked {date}</span>
      </summary>
      <p className="mt-1.5 max-w-xs rounded-lg border border-white/10 bg-black/40 p-2 text-[11px] leading-relaxed text-slate-400">
        SecretMsg checked this claim at send time. It does not tell you who the sender is. A verified
        claim is not a promise of good intent.
      </p>
    </details>
  );
};
