import React, { useEffect, useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { ViewOnlyNote } from '../components/ViewOnlyBanner';
import { ApiClient, UnauthorizedError, UserProfile, getShareUrl } from '../lib/api';
import { ShieldAlert, Trash2, Heart, Check, Copy, KeyRound } from 'lucide-react';

interface SettingsPageProps {
  user: UserProfile | null;
  setUser?: (user: UserProfile) => void;
  onLogout: () => void;
  onOpenDonation: () => void;
}

export const SettingsPage: React.FC<SettingsPageProps> = ({ user, setUser, onLogout, onOpenDonation }) => {
  // A browser paired from the app holds a read-only token; every write 403s.
  const isReadOnly = ApiClient.isReadOnly();
  const navigate = useNavigate();
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [copiedLink, setCopiedLink] = useState(false);
  const [usernameInput, setUsernameInput] = useState('');
  const [claiming, setClaiming] = useState(false);
  const [claimError, setClaimError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) {
      navigate('/login');
    }
  }, [user, navigate]);

  if (!user) return null;

  const publicLink = getShareUrl(user.username);
  const slugUnlocked = user.custom_slug_unlocked === 1;

  const handleClaimUsername = async () => {
    const name = usernameInput.trim().toLowerCase().replace(/^@/, '');
    if (!/^[a-z0-9_\-\.]{4,30}$/.test(name)) {
      setClaimError('Use 4-30 lowercase letters, numbers, dashes, underscores, or dots.');
      return;
    }
    setClaiming(true);
    setClaimError(null);
    try {
      const updated = await ApiClient.setUsername(name);
      setUsernameInput('');
      setUser?.(updated);
      alert(`Your custom link is live: ${getShareUrl(updated.username)}`);
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

  const handleDeleteAccount = async () => {
    setIsDeleting(true);
    try {
      await ApiClient.deleteAccount();
      alert('Your account and all received messages have been permanently deleted.');
      onLogout();
      navigate('/');
    } catch (err: any) {
      if (err instanceof UnauthorizedError) {
        onLogout();
        navigate('/login');
        return;
      }
      alert(err.message || 'Failed to delete account');
      setIsDeleting(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto py-8 sm:py-12 px-4 space-y-8">
      <div className="space-y-1">
        <h2 className="text-2xl font-bold text-white">Account Settings</h2>
        <p className="text-xs text-slate-400">Manage your SecretMsg handle, privacy options, and data.</p>
      </div>

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

      {/* Supporter Tier & Perks */}
      <div className="glass-panel p-6 rounded-2xl space-y-4 border-amber-500/20">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2.5">
            <div className="w-9 h-9 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400">
              <Heart className="w-4 h-4 fill-amber-400" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-white">Supporter Status</h4>
              <p className="text-xs text-slate-400">
                {user.is_premium === 1 ? 'Active Supporter Tier' : 'Free Standard Tier'}
              </p>
            </div>
          </div>

          {isReadOnly ? (
            <ViewOnlyNote>Purchases happen in the app.</ViewOnlyNote>
          ) : (
            <button
              onClick={onOpenDonation}
              className="py-2 px-3 rounded-lg text-xs font-semibold bg-amber-500/10 hover:bg-amber-500/20 text-amber-300 border border-amber-500/20 transition-colors"
            >
              {user.is_premium === 1 ? 'Supporter Perks' : 'Upgrade & Support'}
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
                  Your supporter perk. Replace the random handle with a clean name — no numbers required.
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
            Deleting your account is only possible from the app, on the device you signed in with.
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
      </div>
    </div>
  );
};
