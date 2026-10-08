/**
 * Typed access to the /api/social/* routes for the web client.
 *
 * Kept out of lib/api.ts deliberately (that file is shared and owned by the
 * core client); everything here targets the social feature set only.
 */

import { API_BASE_URL } from '@/lib/config';
import { ApiClient } from '@/lib/api';
import type { BoxTheme } from './box-theme';

export interface BoxThemeResponse {
  status: 'active' | 'retired' | 'tombstone';
  handle?: string;
  current?: string | null;
  theme?: Partial<BoxTheme>;
  error?: string;
}

export interface ReactionRow {
  id: string;
  payload: string;
  payload_version: number;
  created_at: number;
  updated_at: number;
  mine: boolean;
}

export interface VerifiedAttestation {
  v: 1;
  message_id: string;
  claim_type: 'org' | 'age18';
  claim_text: string;
  verified_at: number;
  expires_at: number;
  key_id: string;
  signature: string;
}

export interface VerifiedAttestationResponse {
  verified: boolean;
  attestation: (VerifiedAttestation & { revoked?: boolean }) | null;
  note?: string;
}

interface PublicKeyResponse {
  algorithm: string;
  key_id: string;
  public_key: string;
  canonical: string;
}

async function requestJson<T>(path: string, init?: RequestInit, auth = false): Promise<T> {
  const headers: Record<string, string> = { ...(init?.headers as Record<string, string> | undefined) };
  if (init?.body) headers['Content-Type'] = 'application/json';
  if (auth) {
    const token = ApiClient.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
  }
  const res = await fetch(`${API_BASE_URL}${path}`, { ...init, headers });
  let data: Record<string, unknown> = {};
  try {
    data = (await res.json()) as Record<string, unknown>;
  } catch {
    data = {};
  }
  if (!res.ok) {
    const message = typeof data.error === 'string' ? data.error : `Request failed (${res.status})`;
    throw new Error(message);
  }
  return data as T;
}

/**
 * The fixed six-emoji set, mirrored from GET /api/social/emoji. IDs are the
 * only thing that travels; official clients render glyphs from this allowlist
 * and degrade unknown payloads to a neutral placeholder.
 */
export const REACTION_EMOJI = [
  { id: 'heart', glyph: '❤️', label: 'React with heart' },
  { id: 'laugh', glyph: '😂', label: 'React with laugh' },
  { id: 'wow', glyph: '😮', label: 'React with wow' },
  { id: 'sad', glyph: '😢', label: 'React with sad' },
  { id: 'clap', glyph: '👏', label: 'React with clap' },
  { id: 'fire', glyph: '🔥', label: 'React with fire' },
] as const;

export type ReactionEmojiId = (typeof REACTION_EMOJI)[number]['id'];

/**
 * Interim sealing for a reaction payload.
 *
 * The 1.8 spec seals the emoji under the thread's key material so the server
 * stores ciphertext and cannot tell which emoji was chosen. The end-to-end
 * envelope (docs/design/001) is not shipped in this repo yet, so this builds a
 * base64 JSON envelope with the same shape the sealed one will have. The
 * server treats every payload as opaque either way; swapping this function for
 * the real seal does not change the API.
 */
export function sealReactionPayload(emoji: ReactionEmojiId): string {
  const json = JSON.stringify({ v: 1, e: emoji });
  return btoa(json);
}

/**
 * Best-effort decode for rendering. Returns null for anything not on the
 * fixed allowlist, which is what the "neutral placeholder" rule requires —
 * never sender-controlled text or an image.
 */
export function decodeReactionPayload(payload: string): ReactionEmojiId | null {
  try {
    const filter = typeof atob === 'function' ? atob : null;
    if (!filter) return null;
    const raw = JSON.parse(filter(payload)) as { v?: unknown; e?: unknown };
    if (raw.v !== 1 || typeof raw.e !== 'string') return null;
    const ids = REACTION_EMOJI.map((e) => e.id) as readonly string[];
    return ids.includes(raw.e) ? (raw.e as ReactionEmojiId) : null;
  } catch {
    return null;
  }
}

export const BoxApi = {
  getTheme(handle: string): Promise<BoxThemeResponse> {
    return requestJson<BoxThemeResponse>(`/api/social/box/${encodeURIComponent(handle)}/theme`);
  },

  listMessageReactions(messageId: string): Promise<{ reactions: ReactionRow[] }> {
    return requestJson(`/api/social/message/${encodeURIComponent(messageId)}/reactions`, undefined, true);
  },

  putMessageReaction(messageId: string, payload: string | null): Promise<{ success: boolean }> {
    return requestJson(
      `/api/social/message/${encodeURIComponent(messageId)}/reaction`,
      { method: 'PUT', body: JSON.stringify(payload === null ? { remove: true } : { payload }) },
      true,
    );
  },

  putPostReaction(groupId: string, postId: string, payload: string | null): Promise<{ success: boolean }> {
    return requestJson(
      `/api/social/groups/${encodeURIComponent(groupId)}/posts/${encodeURIComponent(postId)}/reaction`,
      { method: 'PUT', body: JSON.stringify(payload === null ? { remove: true } : { payload }) },
      true,
    );
  },

  report(body: {
    target_kind: 'box' | 'group_post' | 'member_box' | 'reaction' | 'group';
    target_id: string;
    reason: string;
    audience?: 'platform' | 'owner';
    consent?: boolean;
    disclosed_payload?: string;
  }): Promise<{ success: boolean; message?: string }> {
    // No auth header required for box reports; harmless when a token exists.
    return requestJson('/api/social/report', { method: 'POST', body: JSON.stringify(body) }, true);
  },

  getAttestation(messageId: string): Promise<VerifiedAttestationResponse> {
    return requestJson(`/api/social/verified/attestation/${encodeURIComponent(messageId)}`, undefined, true);
  },

  getVerifiedPublicKey(): Promise<PublicKeyResponse> {
    return requestJson<PublicKeyResponse>('/api/social/verified/public-key');
  },
};
