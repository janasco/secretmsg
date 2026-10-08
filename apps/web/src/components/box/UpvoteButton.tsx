import React, { useCallback, useState } from 'react';
import { ArrowBigUp, Trash2 } from 'lucide-react';

const UPVOTES_KEY = 'sm_upvotes_v1';

/**
 * Viewer-local ranking. This is deliberate: an upvote is never sent to the
 * server in any form, never shown to the author or other members, and cannot
 * be aggregated into a public score. It is lost when the browser's site data
 * is cleared or the app is reinstalled — that is the documented trade, not a
 * bug. The Flutter client mirrors this with shared_preferences excluded from
 * Android auto-backup.
 */
function readUpvotes(): Record<string, number> {
  if (typeof localStorage === 'undefined') return {};
  try {
    const raw = localStorage.getItem(UPVOTES_KEY);
    if (!raw) return {};
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return {};
    const out: Record<string, number> = {};
    for (const [key, value] of Object.entries(parsed as Record<string, unknown>)) {
      if (typeof value === 'number' && Number.isFinite(value)) out[key] = value;
    }
    return out;
  } catch {
    return {};
  }
}

export function useLocalUpvotes() {
  const [upvotes, setUpvotes] = useState<Record<string, number>>(() => readUpvotes());

  const persist = useCallback((next: Record<string, number>) => {
    setUpvotes(next);
    try {
      if (typeof localStorage !== 'undefined') localStorage.setItem(UPVOTES_KEY, JSON.stringify(next));
    } catch {
      // Private mode / quota: the in-memory value still works this session.
    }
  }, []);

  const toggle = useCallback((messageId: string) => {
    const next = { ...upvotes };
    if (next[messageId]) delete next[messageId];
    else next[messageId] = Date.now();
    persist(next);
  }, [upvotes, persist]);

  const clear = useCallback(() => persist({}), [persist]);

  const isUpvoted = useCallback((messageId: string) => Boolean(upvotes[messageId]), [upvotes]);

  return { upvotes, toggle, clear, isUpvoted, count: Object.keys(upvotes).length };
}

/** Upvoted ahead of the rest, recency-ordered within each set. Stable. */
export function sortUpvotedFirst<T>(items: T[], keyOf: (item: T) => string, upvoted: Record<string, number>): T[] {
  return [...items].sort((a, b) => Number(Boolean(upvoted[keyOf(b)])) - Number(Boolean(upvoted[keyOf(a)])));
}

interface UpvoteButtonProps {
  messageId: string;
  isUpvoted: boolean;
  onToggle: (messageId: string) => void;
}

export const UpvoteButton: React.FC<UpvoteButtonProps> = ({ messageId, isUpvoted, onToggle }) => (
  <button
    type="button"
    onClick={() => onToggle(messageId)}
    aria-pressed={isUpvoted}
    aria-label={isUpvoted ? 'Remove your private upvote' : 'Upvote privately on this device'}
    title="Upvote privately — only you can see this"
    className={[
      'flex h-11 w-11 items-center justify-center rounded-xl border transition',
      'focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-400',
      isUpvoted ? 'border-indigo-400 bg-indigo-500/20 text-indigo-200' : 'border-white/10 bg-white/5 text-slate-400 hover:bg-white/10',
    ].join(' ')}
  >
    <ArrowBigUp className="h-5 w-5" />
  </button>
);

interface ClearRankingsProps {
  count: number;
  onClear: () => void;
}

export const ClearRankingsButton: React.FC<ClearRankingsProps> = ({ count, onClear }) => {
  const confirmClear = () => {
    if (typeof window !== 'undefined' && !window.confirm('Delete all private upvotes on this device? They cannot be recovered.')) return;
    onClear();
  };
  return (
    <button
      type="button"
      onClick={confirmClear}
      disabled={count === 0}
      className="inline-flex items-center gap-1.5 rounded-lg border border-white/10 px-2.5 py-1.5 text-[11px] text-slate-400 hover:bg-white/5 hover:text-slate-200 disabled:cursor-not-allowed disabled:opacity-40"
    >
      <Trash2 className="h-3.5 w-3.5" />
      Clear rankings ({count})
    </button>
  );
};
