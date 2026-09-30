import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Lock, Smartphone, ArrowRight, KeyRound } from 'lucide-react';
import { ApiClient, UnauthorizedError } from '@/lib/api';

/**
 * Gate for the account-only tools (`/dice`, `/sticker-studio`).
 *
 * A session is required. Both tools are pure client-side — neither calls the
 * API — so gating them on a paired read-only session does not conflict with
 * the API's rule that a paired browser may read but never write: there is
 * nothing here to write with.
 *
 * Two things this is honest about, and they matter:
 *
 * 1. The token lives in localStorage, so this is a product gate, not a
 *    security boundary. Someone who wants the tool can read the bundled JS and
 *    lift the check. What it does guarantee is that the tool is not advertised,
 *    not indexed, and not reachable by accident — which is what the route
 *    policy changes in the same commit actually enforce.
 * 2. It checks for a *present* token, then confirms it against the API. A stale
 *    localStorage entry from an expired session would otherwise render the tool
 *    and fail later on first use, which is a confusing failure rather than a
 *    clean re-pair prompt.
 */

interface RequireSessionProps {
  /** Shown in the lock screen so the visitor knows what they are unlocking. */
  tool: string;
  /** One line on what the tool is, for the locked state. */
  blurb: string;
  children: React.ReactNode;
}

type State = 'checking' | 'granted' | 'locked';

export const RequireSession: React.FC<RequireSessionProps> = ({ tool, blurb, children }) => {
  const [state, setState] = useState<State>('checking');
  // Bumped by the lock screen once a pairing code has been redeemed, so the
  // effect below re-runs against the session that redemption just stored.
  const [generation, setGeneration] = useState(0);

  useEffect(() => {
    let cancelled = false;
    setState('checking');

    const token = ApiClient.getToken();
    if (!token) {
      setState('locked');
      return;
    }

    // Confirm the token is still live before handing over the tool.
    //
    // `getMe` throws UnauthorizedError on 401 but does not clear the stored
    // session itself, so a stale token would otherwise sit in localStorage and
    // be offered as "signed in" on the next visit. Clear it here.
    void ApiClient.getMe()
      .then(() => {
        if (!cancelled) setState('granted');
      })
      .catch((err: unknown) => {
        if (err instanceof UnauthorizedError) ApiClient.removeToken();
        if (!cancelled) setState('locked');
      });

    return () => {
      cancelled = true;
    };
  }, [generation]);

  if (state === 'granted') return <>{children}</>;
  if (state === 'checking') {
    // Deliberately near-empty and theme-neutral. Rendering the tool's own
    // chrome here would flash it at a visitor who is about to be refused.
    return (
      <div className="flex items-center justify-center py-24" role="status" aria-live="polite">
        <span className="text-sm text-slate-500">Checking your session…</span>
      </div>
    );
  }

  return (
    <Locked tool={tool} blurb={blurb} onPaired={() => setGeneration((n) => n + 1)} />
  );
};

const Locked: React.FC<{
  tool: string;
  blurb: string;
  onPaired: () => void;
}> = ({ tool, blurb, onPaired }) => {
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = code.trim();
    if (!trimmed) return;
    setBusy(true);
    setError(null);
    try {
      await ApiClient.redeemPairCode(trimmed);
      onPaired();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'That code is invalid or has expired.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="max-w-lg mx-auto px-4 py-12 sm:py-16">
      {/* The gate sits outside PublicPage, so it has to supply the way back that
          every other page gets from that wrapper. Left-aligned and on its own
          line: centred above a centred lock icon it collided with it. */}
      <Link
        to="/"
        className="inline-flex items-center gap-2 text-xs text-slate-400 hover:text-white transition-colors mb-8"
      >
        <span className="text-base leading-none">←</span>
        Back to secretmsg.net
      </Link>

      <div className="text-center">
        <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-300 mb-6">
          <Lock className="w-6 h-6" />
        </div>

        <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-white mb-3">{tool}</h1>
        <p className="text-sm text-slate-400 leading-relaxed mb-8">{blurb}</p>
      </div>

      <div className="rounded-2xl border border-white/10 bg-white/5 p-5 text-left">
        <div className="flex items-center gap-2 mb-3">
          <Smartphone className="w-4 h-4 text-indigo-300" />
          <h2 className="text-sm font-semibold text-slate-200">Pair this browser</h2>
        </div>
        <p className="text-xs text-slate-400 leading-relaxed mb-4">
          Open SecretMsg on your phone, go to{' '}
          <span className="text-slate-300">Settings → Pair a browser</span>, and enter the
          8-character code it shows. The code works once and expires after five minutes.
        </p>

        <form onSubmit={submit} className="space-y-3">
          <label htmlFor="pair-code" className="sr-only">
            Pairing code
          </label>
          <div className="flex items-center gap-2">
            <KeyRound className="w-4 h-4 text-slate-500 shrink-0" />
            <input
              id="pair-code"
              type="text"
              inputMode="text"
              autoComplete="one-time-code"
              maxLength={8}
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              placeholder="ABCD1234"
              className="flex-1 rounded-lg bg-dark-900 border border-white/15 focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 px-3 py-2 text-sm tracking-widest text-white outline-none"
            />
          </div>
          {error && (
            <p role="alert" className="text-xs text-rose-300">
              {error}
            </p>
          )}
          <button
            type="submit"
            disabled={busy || code.trim().length === 0}
            className="w-full inline-flex items-center justify-center gap-2 rounded-lg bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 transition-colors px-4 py-2.5 text-sm font-semibold text-white"
          >
            {busy ? 'Pairing…' : 'Unlock'}
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>
      </div>

      <p className="text-xs text-slate-500 mt-6">
        Already signed in elsewhere?{' '}
        <Link to="/login" className="text-indigo-300 hover:text-indigo-200 transition-colors">
          Log in with your handle
        </Link>
      </p>
    </div>
  );
};
