import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { AlertTriangle, LogIn, ShieldCheck, Smartphone, Trash2 } from 'lucide-react';
import { PublicPage } from '@/components/PublicPage';
import { ApiClient, UnauthorizedError, UserProfile } from '@/lib/api';

interface DeleteAccountPageProps {
  user: UserProfile | null;
  setUser: React.Dispatch<React.SetStateAction<UserProfile | null>>;
  onLogout: () => void;
}

const deletedData = [
  'Your received messages, blocked-sender records, and reports involving you as either the reporter or recipient',
  'Your pairing codes, purchases, linked donations, and email-keyed one-time-code sessions',
  'The account-linked rate-limit rows that can be identified from your email, handle, or account ID',
  'Your account row, including your handle, email address, profile, and settings',
];

const deletionDisclosures = [
  'Deletion is immediate and irreversible. There is no restore or account recovery after confirmation.',
  'Deletion cannot retract copies you already exported, downloaded, saved, or shared elsewhere.',
  'Deletion does not erase provider-side records held by Google, Resend, Polar, or in Cloudflare backups.',
  'IP-keyed rate limits that cannot be mapped to your account are not explicitly purged and expire under their own retention periods.',
];

export const DeleteAccountPage: React.FC<DeleteAccountPageProps> = ({ user, setUser, onLogout }) => {
  const navigate = useNavigate();
  const [hasToken, setHasToken] = useState(() => Boolean(ApiClient.getToken()));
  const [isHydrating, setIsHydrating] = useState(hasToken && !user);
  const [hydrationError, setHydrationError] = useState<string | null>(null);
  const [hydrationAttempt, setHydrationAttempt] = useState(0);
  const [confirming, setConfirming] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  useEffect(() => {
    if (!hasToken || user) return;
    let active = true;
    setIsHydrating(true);
    setHydrationError(null);
    ApiClient.getMe()
      .then((profile) => {
        if (!active) return;
        setUser(profile);
        setIsHydrating(false);
      })
      .catch((error: unknown) => {
        if (!active) return;
        setIsHydrating(false);
        if (error instanceof UnauthorizedError) {
          ApiClient.removeToken();
          setHasToken(false);
          return;
        }
        setHydrationError('We could not load your profile. Check your connection and try again.');
      });
    return () => {
      active = false;
    };
  }, [hasToken, user, setUser, hydrationAttempt]);

  const handleDelete = async () => {
    setIsDeleting(true);
    setDeleteError(null);
    try {
      await ApiClient.deleteAccount();
      onLogout();
      navigate('/');
    } catch (error: unknown) {
      if (error instanceof UnauthorizedError) {
        onLogout();
        navigate('/login');
        return;
      }
      setDeleteError(error instanceof Error ? error.message : 'We could not delete your account. Please try again.');
      setIsDeleting(false);
    }
  };

  return (
    <PublicPage
      title="Delete Your Account"
      description="Permanently delete your SecretMsg account and the account data listed below. This page is public and does not require the app."
    >
      {hasToken && !user && isHydrating && (
        <div className="glass-panel rounded-2xl border border-white/10 p-8 text-center space-y-4" role="status">
          <div className="w-8 h-8 rounded-full border-2 border-indigo-500 border-t-transparent animate-spin mx-auto" />
          <p className="text-sm text-slate-300">Verifying your account session…</p>
        </div>
      )}

      {hasToken && !user && hydrationError && (
        <div className="glass-panel rounded-2xl border border-rose-500/30 bg-rose-950/20 p-6 sm:p-8 space-y-4" role="alert">
          <div className="flex items-center gap-2 text-rose-300 font-bold">
            <AlertTriangle className="w-5 h-5" />
            Profile unavailable
          </div>
          <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">{hydrationError}</p>
          <button
            onClick={() => setHydrationAttempt((attempt) => attempt + 1)}
            className="px-4 py-2 rounded-xl bg-white/10 hover:bg-white/15 text-white text-xs font-semibold border border-white/10 transition-colors"
          >
            Try Again
          </button>
        </div>
      )}

      {hasToken && user && ApiClient.isReadOnly() && (
        <div className="glass-panel rounded-2xl border border-amber-500/30 bg-amber-950/20 p-6 sm:p-8 space-y-4">
          <div className="flex items-center gap-2 text-amber-300 font-bold">
            <ShieldCheck className="w-5 h-5" />
            This browser is view-only
          </div>
          <p className="text-sm text-slate-300 leading-relaxed">
            The browser paired from the app can view @{user.username}, but it cannot make changes or delete the account. SecretMsg rejects deletion requests from this view-only session.
          </p>
          <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">
            To request deletion from the web, sign in with a full account session. Alternatively, delete the account in the SecretMsg app on a device where you are signed in.
          </p>
          <div className="flex flex-wrap gap-3 pt-1">
            <Link to="/login" className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold transition-colors">
              <LogIn className="w-4 h-4" />
              Full Account Login
            </Link>
            <Link to="/download" className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-white/10 hover:bg-white/15 text-white text-xs font-semibold border border-white/10 transition-colors">
              <Smartphone className="w-4 h-4" />
              Open in the App
            </Link>
          </div>
        </div>
      )}

      {hasToken && user && !ApiClient.isReadOnly() && (
        <div className="glass-panel rounded-2xl border border-rose-500/30 bg-rose-950/20 p-6 sm:p-8 space-y-5">
          <div className="space-y-1">
            <div className="flex items-center gap-2 text-rose-300 font-bold">
              <Trash2 className="w-5 h-5" />
              Delete @{user.username}
            </div>
            <p className="text-sm text-slate-300 leading-relaxed">
              You are signed in with a full account session for <strong className="text-white">@{user.username}</strong>. Review the deletion details below before continuing.
            </p>
          </div>

          {deleteError && (
            <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 text-xs text-rose-200" role="alert">
              {deleteError}
            </div>
          )}

          {confirming ? (
            <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 space-y-3">
              <p className="text-sm font-semibold text-rose-200">
                Final confirmation: permanently delete @{user.username} and all account data listed on this page?
              </p>
              <div className="flex flex-wrap items-center gap-2">
                <button
                  onClick={handleDelete}
                  disabled={isDeleting}
                  className="px-4 py-2 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-semibold transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isDeleting ? 'Deleting Account…' : 'Permanently Delete Account'}
                </button>
                <button
                  onClick={() => setConfirming(false)}
                  disabled={isDeleting}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-300 hover:text-white transition-colors disabled:opacity-50"
                >
                  Cancel
                </button>
              </div>
            </div>
          ) : (
            <button
              onClick={() => {
                setConfirming(true);
                setDeleteError(null);
              }}
              className="px-4 py-2 rounded-xl bg-rose-500/10 hover:bg-rose-500/20 text-rose-300 border border-rose-500/30 text-xs font-semibold transition-colors"
            >
              Continue to Final Confirmation
            </button>
          )}
        </div>
      )}

      {!hasToken && (
        <div className="glass-panel rounded-2xl border border-indigo-500/30 bg-indigo-950/20 p-6 sm:p-8 space-y-4">
          <div className="flex items-center gap-2 text-indigo-300 font-bold">
            <ShieldCheck className="w-5 h-5" />
            Sign in to verify ownership
          </div>
          <p className="text-sm text-slate-300 leading-relaxed">
            For your security, SecretMsg does not delete an account from a signed-out request. Sign in first so the request can be tied to a valid full account session.
          </p>
          <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">
            If you forgot your PIN, go to <Link to="/login" className="text-indigo-300 underline">Log In</Link>, choose <strong className="text-white">Forgot PIN?</strong>, and recover the account with a backup code. An account with neither its PIN nor a backup code cannot be self-recovered.
          </p>
          <Link to="/login" className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold transition-colors">
            <LogIn className="w-4 h-4" />
            Log In to Verify Ownership
          </Link>
        </div>
      )}

      <div className="glass-panel rounded-2xl border border-white/10 p-6 sm:p-8 mt-6 space-y-5 text-sm text-slate-300 leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white">What account deletion removes</h2>
          <ul className="list-disc list-inside space-y-2 text-xs sm:text-sm text-slate-400 pl-2">
            {deletedData.map((item) => <li key={item}>{item}</li>)}
          </ul>
        </section>
        <section className="space-y-3 border-t border-white/10 pt-5">
          <h2 className="text-lg font-bold text-white">Important deletion limits</h2>
          <ul className="list-disc list-inside space-y-2 text-xs sm:text-sm text-slate-400 pl-2">
            {deletionDisclosures.map((item) => <li key={item}>{item}</li>)}
          </ul>
        </section>
      </div>
    </PublicPage>
  );
};
