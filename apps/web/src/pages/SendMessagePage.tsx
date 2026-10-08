import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { ApiClient, UserProfile } from '@/lib/api';
import { ComposeModal } from '@/components/ComposeModal';
import { BoxThemeShell } from '@/components/box/BoxThemeShell';
import { BoxApi } from '@/components/box/box-api';
import { DEFAULT_BOX_THEME, normalizeBoxTheme, type BoxTheme } from '@/components/box/box-theme';
import { AlertCircle, ArrowLeft } from 'lucide-react';

type PageState =
  | { kind: 'loading' }
  | { kind: 'error'; message: string }
  | { kind: 'tombstone'; handle: string }
  | { kind: 'ready'; recipient: UserProfile };

export const SendMessagePage: React.FC = () => {
  const { username } = useParams<{ username: string }>();
  const navigate = useNavigate();
  const [state, setState] = useState<PageState>({ kind: 'loading' });
  const [theme, setTheme] = useState<BoxTheme>(DEFAULT_BOX_THEME);

  useEffect(() => {
    if (!username) return;
    let alive = true;
    setState({ kind: 'loading' });
    setTheme(DEFAULT_BOX_THEME);

    const loadProfile = async (handle: string) => {
      try {
        const user = await ApiClient.getRecipientProfile(handle);
        if (alive) setState({ kind: 'ready', recipient: user });
      } catch (err) {
        if (alive) {
          setState({ kind: 'error', message: err instanceof Error ? err.message : 'User does not exist' });
        }
      }
    };

    (async () => {
      try {
        // The social theme endpoint also resolves retired handles, so a
        // printed sticker pointing at an old handle lands on the current box.
        const res = await BoxApi.getTheme(username);
        if (!alive) return;
        if (res.status === 'retired' && res.current) {
          navigate(`/${res.current}`, { replace: true });
          return;
        }
        if (res.status === 'tombstone') {
          setState({ kind: 'tombstone', handle: res.handle || username });
          return;
        }
        if (res.theme) setTheme(normalizeBoxTheme(res.theme));
        await loadProfile(res.status === 'active' && res.handle ? res.handle : username);
      } catch {
        // Older API without the social routes: fall back to the plain profile.
        await loadProfile(username);
      }
    })();

    return () => {
      alive = false;
    };
  }, [username, navigate]);

  if (state.kind === 'loading') {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-4">
        <div className="w-10 h-10 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
        <p className="text-xs text-slate-400">Loading recipient profile...</p>
      </div>
    );
  }

  if (state.kind === 'tombstone') {
    return (
      <BoxThemeShell theme={DEFAULT_BOX_THEME} handle={state.handle}>
        <div className="glass-panel p-8 rounded-2xl text-center space-y-4">
          <div className="w-12 h-12 bg-amber-500/10 border border-amber-500/20 rounded-full flex items-center justify-center mx-auto text-amber-400">
            <AlertCircle className="w-6 h-6" />
          </div>
          <h2 className="text-xl font-bold text-white">This box no longer exists</h2>
          <p className="text-xs text-slate-400 leading-relaxed">
            <span className="text-slate-200 font-mono">@{state.handle}</span> was deleted. The link is
            permanently retired, so it can never point at someone else&apos;s box.
          </p>
          <div className="pt-2">
            <Link
              to="/"
              className="inline-flex items-center justify-center space-x-2 py-2.5 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back to SecretMsg.net</span>
            </Link>
          </div>
        </div>
      </BoxThemeShell>
    );
  }

  if (state.kind === 'error') {
    return (
      <div className="max-w-md mx-auto my-16 px-4">
        <div className="glass-panel p-8 rounded-2xl text-center space-y-4">
          <div className="w-12 h-12 bg-rose-500/10 border border-rose-500/20 rounded-full flex items-center justify-center mx-auto text-rose-400">
            <AlertCircle className="w-6 h-6" />
          </div>
          <h2 className="text-xl font-bold text-white">Link Not Found</h2>
          <p className="text-xs text-slate-400">
            No active SecretMsg user was found with the handle{' '}
            <span className="text-slate-200 font-mono">@{username}</span>.
          </p>
          <div className="pt-2">
            <Link
              to="/"
              className="inline-flex items-center justify-center space-x-2 py-2.5 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back to SecretMsg.net</span>
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <BoxThemeShell theme={theme} handle={state.recipient.username}>
      <div className="mb-6 text-center">
        <p className="text-[11px] uppercase tracking-[0.2em] text-slate-400">Send an anonymous message to</p>
        <h1 className="display-2 box-accent-text mt-1">
          @{state.recipient.display_name || state.recipient.username}
        </h1>
        <p className="mt-2 text-xs text-slate-400">
          They will see your message, not your name.
        </p>
      </div>
      <ComposeModal recipient={state.recipient} />
    </BoxThemeShell>
  );
};
