import React, { useEffect, useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { ViewOnlyNote } from '@/components/ViewOnlyBanner';
import { ApiClient, UnauthorizedError, UserProfile, BlockedSender, getShareUrl } from '@/lib/api';
import { tierMeta, rankTierOf, rankDetailOf } from '@/lib/rank';
import { getInitialTheme, applyAppTheme, getResolvedTheme, ThemeMode, ResolvedTheme } from '@/lib/theme';
import { ShieldAlert, Trash2, Heart, Check, Copy, KeyRound, Pause, Play, EyeOff, Smartphone, Palette, ShieldCheck, Share2 } from 'lucide-react';

interface SettingsPageProps {
  user: UserProfile | null;
  setUser?: (user: UserProfile) => void;
  onLogout: () => void;
  onOpenSupport: () => void;
}

export const SettingsPage: React.FC<SettingsPageProps> = ({ user, setUser, onLogout, onOpenSupport }) => {
  const isReadOnly = ApiClient.isReadOnly();
  const navigate = useNavigate();
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [copiedLink, setCopiedLink] = useState(false);
  const [usernameInput, setUsernameInput] = useState('');
  const [claiming, setClaiming] = useState(false);
  const [claimError, setClaimError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [toastError, setToastError] = useState(false);

  // Safety preferences (from GET /api/me)
  const [paused, setPaused] = useState(false);
  const [hiddenWordsInput, setHiddenWordsInput] = useState('');
  const [savingSafety, setSavingSafety] = useState(false);
  // Pairing
  const [pairCode, setPairCode] = useState<string | null>(null);
  const [pairExpiry, setPairExpiry] = useState<number | null>(null);
  const [creatingPair, setCreatingPair] = useState(false);
  // Appearance (default: follow the OS; explicit choice stored per-device)
  const [theme, setTheme] = useState<ThemeMode>(() => getInitialTheme());
  const [resolved, setResolved] = useState<ResolvedTheme>(() => getResolvedTheme());
  // Security (PIN + backup codes)
  const [curPin, setCurPin] = useState('');
  const [newPin, setNewPin] = useState('');
  const [changingPin, setChangingPin] = useState(false);
  const [refreshPin, setRefreshPin] = useState('');
  const [refreshingCodes, setRefreshingCodes] = useState(false);
  const [freshCodes, setFreshCodes] = useState<string[]>([]);
  // Blocked senders
  const [blocked, setBlocked] = useState<BlockedSender[]>([]);

  const showToast = (msg: string, isErr = false) => {
    setToast(msg);
    setToastError(isErr);
    setTimeout(() => setToast(null), 4000);
  };

  useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }
    ApiClient.getMe()
      .then((me) => {
        setUser?.(me);
        setPaused(!!me.is_paused || (typeof me.paused_until === 'number' && me.paused_until === -1));
        setHiddenWordsInput((me.hidden_words || []).join(', '));
      })
      .catch((err) => {
        if (err instanceof UnauthorizedError) {
          onLogout();
          navigate('/login');
        }
      });
    ApiClient.getBlockedSenders().then(setBlocked).catch(() => {});
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!user) navigate('/login');
  }, [user, navigate]);

  if (!user) return null;

  const publicLink = getShareUrl(user.username);
  const slugUnlocked = user.custom_slug_unlocked === 1;

  const handleClaimUsername = async () => {
    const name = usernameInput.trim().toLowerCase().replace(/^@/, '');
    if (!/^[a-z0-9_.-]{4,30}$/.test(name)) {
      setClaimError('Use 4-30 lowercase letters, numbers, dashes, underscores, or dots.');
      return;
    }
    setClaiming(true);
    setClaimError(null);
    try {
      const updated = await ApiClient.setUsername(name);
      setUsernameInput('');
      setUser?.(updated);
      showToast(`Your custom link is live: ${getShareUrl(updated.username)}`);
    } catch (err: any) {
      if (err instanceof UnauthorizedError) {
        onLogout();
        navigate('/login');
        return;
      }
      setClaimError(err.message || 'Could not claim username.');
    } finally {
      setClaiming(false);
    }
  };

  const handleShareRank = async () => {
    const meta = tierMeta(rankTierOf(user));
    const text = `I'm ${meta.emoji} ${meta.name} on SecretMsg — ask me anything anonymously: ${publicLink}`;
    try {
      const nav = navigator as Navigator & { share?: (data: { title: string; text: string; url: string }) => Promise<void> };
      if (nav.share) {
        await nav.share({ title: 'SecretMsg', text, url: publicLink });
        return;
      }
      throw new Error('no-share');
    } catch {
      try {
        await navigator.clipboard.writeText(text);
        showToast('Rank share text copied — paste it to your story.');
      } catch {
        showToast('Could not share right now.', true);
      }
    }
  };

  const handleDeleteAccount = async () => {
    setIsDeleting(true);
    try {
      await ApiClient.deleteAccount();
      onLogout();
      navigate('/');
    } catch (err: any) {
      if (err instanceof UnauthorizedError) {
        onLogout();
        navigate('/login');
        return;
      }
      showToast(err.message || 'Failed to delete account', true);
      setIsDeleting(false);
    }
  };

  const handleSaveSafety = async () => {
    setSavingSafety(true);
    try {
      const words = hiddenWordsInput.split(',').map((w) => w.trim()).filter(Boolean).slice(0, 50);
      await ApiClient.updateSafety({ paused_until: paused ? -1 : null, hidden_words: words });
      const me = await ApiClient.getMe();
      setUser?.(me);
      showToast(paused ? 'Board paused. Visitors see a paused notice.' : 'Board active. Safety filters saved.');
    } catch (err: any) {
      if (err instanceof UnauthorizedError) {
        onLogout();
        navigate('/login');
        return;
      }
      showToast(err.message || 'Could not save safety settings', true);
    } finally {
      setSavingSafety(false);
    }
  };

  const handleCreatePair = async () => {
    setCreatingPair(true);
    try {
      const res = await ApiClient.createPairCode();
      setPairCode(res.code);
      setPairExpiry(res.expires_at);
      showToast('Pairing code created. It expires in 5 minutes.');
    } catch (err: any) {
      showToast(err.message || 'Could not create pairing code', true);
    } finally {
      setCreatingPair(false);
    }
  };

  const handleTheme = (mode: ThemeMode) => {
    setTheme(mode);
    setResolved(applyAppTheme(mode));
  };

  const handleChangePin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!/^\d{4,6}$/.test(newPin)) {
      showToast('New PIN must be 4-6 digits', true);
      return;
    }
    setChangingPin(true);
    try {
      await ApiClient.authChangePin(curPin, newPin);
      setCurPin('');
      setNewPin('');
      showToast('PIN changed.');
    } catch (err: any) {
      showToast(err.message || 'Could not change PIN', true);
    } finally {
      setChangingPin(false);
    }
  };

  const handleRefreshCodes = async (e: React.FormEvent) => {
    e.preventDefault();
    setRefreshingCodes(true);
    try {
      const codes = await ApiClient.authRefreshBackupCodes(refreshPin);
      setFreshCodes(codes);
      setRefreshPin('');
      showToast('New backup codes issued. Old ones are revoked.');
    } catch (err: any) {
      showToast(err.message || 'Could not refresh backup codes', true);
    } finally {
      setRefreshingCodes(false);
    }
  };

  const handleUnblock = async (hash: string) => {
    try {
      await ApiClient.unblockSender(hash);
      setBlocked((prev) => prev.filter((b) => b.sender_fp_hash !== hash));
      showToast('Sender unblocked.');
    } catch (err: any) {
      showToast(err.message || 'Could not unblock sender', true);
    }
  };

  return (
    <div className="max-w-2xl mx-auto py-8 sm:py-12 px-4 space-y-8">
      <div className="space-y-1">
        <h2 className="text-2xl font-bold text-white">Account Settings</h2>
        <p className="text-xs text-slate-400">Manage your SecretMsg handle, privacy options, and data.</p>
      </div>

      {toast && (
        <div className={`p-3 rounded-xl text-xs border ${toastError ? 'bg-rose-500/10 border-rose-500/30 text-rose-300' : 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300'}`}>
          {toast}
        </div>
      )}

      {/* Profile Overview */}
      <div className="glass-panel p-6 rounded-2xl space-y-4">
        <div className="flex items-center space-x-4">
          <div className="w-14 h-14 rounded-full bg-gradient-to-tr from-indigo-500 to-amber-500 p-0.5 shadow-md">
            <div className="w-full h-full bg-dark-900 rounded-full flex items-center justify-center text-xl font-bold text-white uppercase">
              {user.display_name.slice(0, 2)}
            </div>
          </div>
          <div className="space-y-0.5">
            <div className="flex items-center space-x-2">
              <h3 className="text-base font-bold text-white">{user.display_name}</h3>
              {user.is_premium === 1 && (
                <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                  {user.badge_title || 'Supporter'}
                </span>
              )}
              {(() => {
                const meta = tierMeta(rankTierOf(user));
                return (
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-indigo-500/15 text-indigo-300 border border-indigo-500/30">
                    {meta.emoji} {meta.name}
                  </span>
                );
              })()}
            </div>
            <p className="text-xs text-slate-400 font-mono">@{user.username}</p>
          </div>
        </div>

        <div className="pt-2 flex items-center space-x-2">
          <input
            type="text"
            readOnly
            value={publicLink}
            className="flex-1 bg-dark-900 border border-white/10 rounded-xl px-3.5 py-2 text-xs font-mono text-indigo-300 select-all outline-none"
          />
          <button
            onClick={() => {
              navigator.clipboard.writeText(publicLink);
              setCopiedLink(true);
              setTimeout(() => setCopiedLink(false), 2000);
            }}
            className="p-2 bg-white/10 hover:bg-white/15 text-white rounded-xl border border-white/10 transition-colors"
          >
            {copiedLink ? <Check className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Rank progress (server-computed activity tier) */}
      {(() => {
        const detail = rankDetailOf(user);
        const meta = tierMeta(rankTierOf(user));
        const pct = detail && typeof detail.progress === 'number'
          ? Math.min(100, Math.max(0, detail.progress * 100))
          : null;
        const toNext = detail && typeof detail.nextScore === 'number' && typeof detail.score === 'number'
          ? Math.max(0, detail.nextScore - detail.score)
          : null;
        return (
          <div className="glass-panel p-6 rounded-2xl space-y-3">
            <div className="flex items-center space-x-2.5">
              <div className="w-9 h-9 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-lg">
                {meta.emoji}
              </div>
              <div className="flex-1">
                <h4 className="text-sm font-bold text-white">Rank: {detail?.name || meta.name}</h4>
                <p className="text-xs text-slate-400">
                  {typeof detail?.score === 'number'
                    ? `${detail.score} activity points (messages + 2× replies${user.is_premium === 1 ? ', supporter bonus' : ''})`
                    : 'Activity rank from messages and replies'}
                </p>
              </div>
              <button
                onClick={handleShareRank}
                title="Share your rank"
                className="p-2 bg-white/10 hover:bg-white/15 text-white rounded-xl border border-white/10 transition-colors"
              >
                <Share2 className="w-4 h-4" />
              </button>
            </div>
            {pct !== null && (
              <div className="space-y-1.5">
                <div className="h-1.5 rounded-full bg-white/10 overflow-hidden">
                  <div className="h-full rounded-full bg-indigo-500 transition-all" style={{ width: `${pct}%` }} />
                </div>
                <p className="text-[11px] text-slate-500">
                  {toNext !== null && detail?.nextName ? `${toNext} points to ${detail.nextName}` : 'Max rank reached.'}
                </p>
              </div>
            )}
          </div>
        );
      })()}

      {/* Safety: pause + hidden words */}
      <div className="glass-panel p-6 rounded-2xl space-y-4">
        <div className="flex items-center space-x-2.5">
          <div className="w-9 h-9 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400">
            <ShieldCheck className="w-4 h-4" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-white">Safety & Privacy</h4>
            <p className="text-xs text-slate-400">Pause your board or filter unwanted words server-side.</p>
          </div>
        </div>
        {isReadOnly ? (
          <ViewOnlyNote>Safety settings can only be changed in the app.</ViewOnlyNote>
        ) : (
          <div className="space-y-3">
            <label className="flex items-center justify-between gap-3 text-xs text-slate-300 bg-dark-900 border border-white/10 rounded-xl px-3.5 py-3 cursor-pointer">
              <span className="flex items-center gap-2">
                {paused ? <Pause className="w-4 h-4 text-amber-400" /> : <Play className="w-4 h-4 text-emerald-400" />}
                {paused ? 'Board paused (visitors cannot submit)' : 'Board active (accepting messages)'}
              </span>
              <input type="checkbox" checked={paused} onChange={(e) => setPaused(e.target.checked)} className="rounded border-white/20 bg-dark-950 text-indigo-600" />
            </label>
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-300 flex items-center gap-1.5">
                <EyeOff className="w-3.5 h-3.5" /> Hidden words (comma-separated, up to 50)
              </label>
              <textarea
                value={hiddenWordsInput}
                onChange={(e) => setHiddenWordsInput(e.target.value)}
                rows={2}
                placeholder="e.g. spam, hate, slur"
                className="w-full bg-dark-900 border border-white/10 rounded-xl px-3.5 py-2.5 text-xs text-white placeholder-slate-500 outline-none focus:border-indigo-500/50 resize-none"
              />
              <p className="text-[11px] text-slate-500">Messages containing these words are rejected server-side.</p>
            </div>
            <button
              onClick={handleSaveSafety}
              disabled={savingSafety}
              className="py-2 px-4 rounded-lg text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white transition-colors disabled:opacity-50"
            >
              {savingSafety ? 'Saving…' : 'Save Safety Settings'}
            </button>
          </div>
        )}
      </div>

      {/* Appearance */}
      <div className="glass-panel p-6 rounded-2xl space-y-3">
        <div className="flex items-center space-x-2.5">
          <div className="w-9 h-9 rounded-xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center text-purple-300">
            <Palette className="w-4 h-4" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-white">Appearance</h4>
            <p className="text-xs text-slate-400">
              System follows your OS{theme === 'system' ? ` (now ${resolved})` : ''} · stored on this device only.
            </p>
          </div>
        </div>
        <div className="flex gap-2">
          {(['system', 'dark', 'light'] as ThemeMode[]).map((m) => (
            <button
              key={m}
              onClick={() => handleTheme(m)}
              className={`flex-1 py-2 rounded-lg text-xs font-semibold border transition-colors capitalize ${theme === m ? 'bg-white/15 text-white border-white/30' : 'bg-dark-900 text-slate-400 border-white/10 hover:text-white'}`}
            >
              {m === 'system' ? `System (${resolved})` : m}
            </button>
          ))}
        </div>
      </div>

      {/* Pairing */}
      <div className="glass-panel p-6 rounded-2xl space-y-3">
        <div className="flex items-center space-x-2.5">
          <div className="w-9 h-9 rounded-xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center text-cyan-300">
            <Smartphone className="w-4 h-4" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-white">Pair a Browser</h4>
            <p className="text-xs text-slate-400">Show a 5-minute code the website can redeem for view-only access.</p>
          </div>
        </div>
        {isReadOnly ? (
          <ViewOnlyNote>Pairing codes are created in the app.</ViewOnlyNote>
        ) : (
          <div className="space-y-2">
            <button
              onClick={handleCreatePair}
              disabled={creatingPair}
              className="py-2 px-4 rounded-lg text-xs font-semibold bg-cyan-600/20 hover:bg-cyan-600/30 text-cyan-200 border border-cyan-500/30 transition-colors disabled:opacity-50"
            >
              {creatingPair ? 'Creating…' : 'Create Pairing Code'}
            </button>
            {pairCode && (
              <div className="bg-dark-900 border border-cyan-500/20 rounded-xl p-3 text-center space-y-1">
                <p className="font-mono text-xl font-bold tracking-widest text-white">{pairCode}</p>
                {pairExpiry && <p className="text-[11px] text-slate-400">Expires {new Date(pairExpiry * 1000).toLocaleTimeString()}</p>}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Security: PIN + backup codes */}
      <div className="glass-panel p-6 rounded-2xl space-y-4">
        <div className="flex items-center space-x-2.5">
          <div className="w-9 h-9 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-300">
            <KeyRound className="w-4 h-4" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-white">PIN & Backup Codes</h4>
            <p className="text-xs text-slate-400">Handle accounts only. Email-OTP accounts skip this section.</p>
          </div>
        </div>
        {isReadOnly ? (
          <ViewOnlyNote>PIN changes happen in the app.</ViewOnlyNote>
        ) : (
          <div className="space-y-4">
            <form onSubmit={handleChangePin} className="flex flex-col sm:flex-row gap-2">
              <input type="password" placeholder="Current PIN" value={curPin} onChange={(e) => setCurPin(e.target.value)} maxLength={6} className="flex-1 bg-dark-900 border border-white/10 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500 outline-none focus:border-indigo-500/50" />
              <input type="password" placeholder="New PIN (4-6 digits)" value={newPin} onChange={(e) => setNewPin(e.target.value)} maxLength={6} className="flex-1 bg-dark-900 border border-white/10 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500 outline-none focus:border-indigo-500/50" />
              <button type="submit" disabled={changingPin} className="py-2 px-4 rounded-lg text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white disabled:opacity-50">
                {changingPin ? '…' : 'Change PIN'}
              </button>
            </form>
            <form onSubmit={handleRefreshCodes} className="flex flex-col sm:flex-row gap-2">
              <input type="password" placeholder="Confirm PIN to refresh codes" value={refreshPin} onChange={(e) => setRefreshPin(e.target.value)} maxLength={6} className="flex-1 bg-dark-900 border border-white/10 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500 outline-none focus:border-indigo-500/50" />
              <button type="submit" disabled={refreshingCodes} className="py-2 px-4 rounded-lg text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 disabled:opacity-50">
                {refreshingCodes ? '…' : 'Refresh Codes'}
              </button>
            </form>
            {freshCodes.length > 0 && (
              <div className="grid grid-cols-2 gap-2">
                {freshCodes.map((c, i) => (
                  <div key={i} className="bg-dark-900 rounded-lg p-2 text-center font-mono text-xs text-white font-bold border border-white/10">{c}</div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Blocked senders */}
      <div className="glass-panel p-6 rounded-2xl space-y-3">
        <h4 className="text-sm font-bold text-white">Blocked Senders ({blocked.length})</h4>
        <p className="text-xs text-slate-400">Anonymous device fingerprints. Only hashes are stored — senders stay anonymous.</p>
        {blocked.length === 0 ? (
          <p className="text-xs text-slate-500">No blocked senders. Block from any message in your inbox.</p>
        ) : (
          <div className="space-y-2">
            {blocked.map((b) => (
              <div key={b.sender_fp_hash} className="flex items-center justify-between gap-2 bg-dark-900 border border-white/10 rounded-xl px-3 py-2">
                <span className="font-mono text-[11px] text-slate-400 truncate">…{b.sender_fp_hash.slice(-12)}</span>
                {isReadOnly ? (
                  <span className="text-[11px] text-slate-500">View-only</span>
                ) : (
                  <button onClick={() => handleUnblock(b.sender_fp_hash)} className="text-[11px] font-semibold text-indigo-300 hover:text-white">Unblock</button>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Ad-Free Status */}
      <div className="glass-panel p-6 rounded-2xl space-y-4 border-amber-500/20">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2.5">
            <div className="w-9 h-9 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400">
              <Heart className="w-4 h-4 fill-amber-400" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-white">Ad-Free Status</h4>
              <p className="text-xs text-slate-400">
                {user.is_premium === 1 ? 'Ads Removed' : 'Ads Shown in the App'}
              </p>
            </div>
          </div>

          {isReadOnly ? (
            <ViewOnlyNote>The ad-free purchase is made in the app.</ViewOnlyNote>
          ) : (
            <button
              onClick={onOpenSupport}
              className="py-2 px-3 rounded-lg text-xs font-semibold bg-amber-500/10 hover:bg-amber-500/20 text-amber-300 border border-amber-500/20 transition-colors"
            >
              How to Support
            </button>
          )}
        </div>

        {slugUnlocked && (
          <div className="pt-2 border-t border-white/10 space-y-3">
            <div className="flex items-center space-x-2.5">
              <div className="w-8 h-8 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400">
                <KeyRound className="w-4 h-4" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">Claim your custom username</h4>
                <p className="text-xs text-slate-400">
                  Unlocked on your account. Replace the random handle with a clean name — no numbers required.
                </p>
              </div>
            </div>
            {isReadOnly ? (
              <ViewOnlyNote>Username changes happen in the app.</ViewOnlyNote>
            ) : (
              <div className="flex items-center space-x-2">
                <input
                  type="text"
                  value={usernameInput}
                  onChange={(e) => setUsernameInput(e.target.value)}
                  placeholder={`${user.username}`}
                  disabled={claiming}
                  className="flex-1 bg-dark-900 border border-white/10 rounded-xl px-3.5 py-2 text-xs font-mono text-white placeholder-slate-500 outline-none focus:border-indigo-500/50"
                />
                <button
                  onClick={handleClaimUsername}
                  disabled={claiming}
                  className="py-2 px-4 rounded-lg text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white transition-colors disabled:opacity-50"
                >
                  {claiming ? 'Claiming…' : 'Claim'}
                </button>
              </div>
            )}
            {claimError && <p className="text-xs text-rose-400">{claimError}</p>}
          </div>
        )}
      </div>

      {/* Danger Zone: Permanent Account Deletion */}
      <div className="glass-panel p-6 rounded-2xl space-y-4 border-rose-500/30">
        <div className="space-y-1">
          <h4 className="text-sm font-bold text-rose-400 flex items-center space-x-2">
            <ShieldAlert className="w-4 h-4" />
            <span>Danger Zone (GDPR / CCPA Data Erasure)</span>
          </h4>
          <p className="text-xs text-slate-400">
            Deleting your account will permanently wipe your profile and delete all received messages from secure storage. This action is instantaneous and cannot be reversed.
          </p>
        </div>

        {confirmDelete ? (
          <div className="p-4 bg-rose-500/10 border border-rose-500/20 rounded-xl space-y-3">
            <p className="text-xs font-semibold text-rose-300">
              Are you completely sure? All your secret messages and username will be permanently destroyed.
            </p>
            <div className="flex items-center space-x-2">
              <button
                onClick={handleDeleteAccount}
                disabled={isDeleting}
                className="py-2 px-4 rounded-lg text-xs font-semibold bg-rose-600 hover:bg-rose-500 text-white transition-colors"
              >
                {isDeleting ? 'Erasing data...' : 'Yes, Permanently Delete Everything'}
              </button>
              <button
                onClick={() => setConfirmDelete(false)}
                className="py-2 px-3 rounded-lg text-xs text-slate-400 hover:text-white"
              >
                Cancel
              </button>
            </div>
          </div>
        ) : isReadOnly ? (
          <ViewOnlyNote>
            This paired browser is view-only and cannot delete your account. Use the app on a device where you are signed in, or <Link to="/delete-account" className="text-indigo-300 underline">sign in with a full account session</Link> on the web.
          </ViewOnlyNote>
        ) : (
          <button
            onClick={() => setConfirmDelete(true)}
            className="py-2 px-4 rounded-xl text-xs font-semibold bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 flex items-center space-x-1.5 transition-colors"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span>Delete My Account & Messages</span>
          </button>
        )}
      </div>

      {/* Legal & Project Information */}
      <div className="pt-4 border-t border-white/10 flex flex-wrap gap-4 text-xs text-slate-500">
        <Link to="/p/terms" className="hover:text-slate-400">Terms of Service</Link>
        <Link to="/p/privacy" className="hover:text-slate-400">Privacy Policy</Link>
        <Link to="/p/disclaimer" className="hover:text-slate-400">Personal Project Disclaimer</Link>
        <Link to="/delete-account" className="hover:text-slate-400">Delete Account</Link>
      </div>
    </div>
  );
};
