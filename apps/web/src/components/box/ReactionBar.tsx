import React, { useEffect, useState } from 'react';
import { BoxApi, decodeReactionPayload, REACTION_EMOJI, sealReactionPayload, type ReactionEmojiId } from './box-api';

interface ReactionBarProps {
  messageId: string;
  /** Group feed posts use the group-scoped route; 1:1 messages use the message route. */
  variant?: 'message' | 'group_post';
  groupId?: string;
  disabled?: boolean;
  disabledReason?: string;
}

/**
 * Fixed six-emoji reaction bar. One reaction per person per message: tapping
 * the same emoji removes it, tapping another switches it. There are no
 * downvotes and no counts are displayed anywhere — a pile-on has nothing to
 * aim at. Every write is optimistic and rolled back on failure so an offline
 * outbox replay stays idempotent (the server upserts on message+person).
 */
export const ReactionBar: React.FC<ReactionBarProps> = ({
  messageId,
  variant = 'message',
  groupId,
  disabled = false,
  disabledReason,
}) => {
  const [mine, setMine] = useState<ReactionEmojiId | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    if (variant !== 'message' || disabled) {
      setLoaded(true);
      return () => { alive = false; };
    }
    BoxApi.listMessageReactions(messageId)
      .then((res) => {
        if (!alive) return;
        const own = res.reactions.find((r) => r.mine);
        setMine(own ? decodeReactionPayload(own.payload) : null);
      })
      .catch(() => {
        // Reading reactions is not essential; the bar still works for writes.
      })
      .finally(() => {
        if (alive) setLoaded(true);
      });
    return () => { alive = false; };
  }, [messageId, variant, disabled]);

  const choose = async (id: ReactionEmojiId) => {
    if (busy || disabled) return;
    const next = mine === id ? null : id;
    const previous = mine;
    setMine(next);
    setBusy(true);
    setError(null);
    try {
      const payload = next === null ? null : sealReactionPayload(next);
      if (variant === 'group_post' && groupId) {
        await BoxApi.putPostReaction(groupId, messageId, payload);
      } else {
        await BoxApi.putMessageReaction(messageId, payload);
      }
      if (typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function') {
        navigator.vibrate(10);
      }
    } catch (err) {
      setMine(previous);
      setError(err instanceof Error ? err.message : 'Could not save that reaction.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="space-y-1" data-testid="reaction-bar" data-loaded={loaded}>
      <div role="group" aria-label="Reactions" className="flex items-center gap-1.5">
        {REACTION_EMOJI.map((emoji) => {
          const selected = mine === emoji.id;
          return (
            <button
              key={emoji.id}
              type="button"
              onClick={() => choose(emoji.id)}
              aria-label={emoji.label}
              aria-pressed={selected}
              title={emoji.label}
              disabled={disabled || busy}
              className={[
                // 44x44 dp minimum hit target.
                'flex h-11 w-11 items-center justify-center rounded-xl border text-lg transition',
                'focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-400',
                selected
                  // Selection is not conveyed by color alone: border weight,
                  // scale, and aria-pressed all change together.
                  ? 'border-indigo-400 bg-indigo-500/20 scale-110 shadow'
                  : 'border-white/10 bg-white/5 hover:bg-white/10',
                (disabled || busy) ? 'cursor-not-allowed opacity-60' : 'cursor-pointer',
              ].join(' ')}
            >
              <span aria-hidden="true">{emoji.glyph}</span>
              {selected && <span className="sr-only">(selected)</span>}
            </button>
          );
        })}
      </div>
      <p className="text-[11px] text-slate-500">
        {disabled
          ? disabledReason || 'Reactions are turned off for this box.'
          : 'One reaction per person. No public counts, and no downvotes anywhere.'}
      </p>
      {error && <p className="text-[11px] text-rose-400">{error}</p>}
    </div>
  );
};
