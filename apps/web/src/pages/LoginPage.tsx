import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { ApiClient, UserProfile } from '../lib/api';
import { Mail, KeyRound, ArrowRight, Lock, Smartphone, Eye } from 'lucide-react';

interface LoginPageProps {
  onLoginSuccess: (user: UserProfile) => void;
}

type Mode = 'pair' | 'email';

export const LoginPage: React.FC<LoginPageProps> = ({ onLoginSuccess }) => {
  const navigate = useNavigate();
  const [mode, setMode] = useState<Mode>('pair');
  const [step, setStep] = useState<'email' | 'otp'>('email');
  const [pairCode, setPairCode] = useState('');
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const switchMode = (next: Mode) => {
    setMode(next);
    setError(null);
  };

  // Show the code the way the app does (XXXX-XXXX) while the user types. The
  // server normalizes confusable characters, so this only handles presentation.
  const onPairCodeChange = (raw: string) => {
    const clean = raw.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 8);
    setPairCode(clean.length > 4 ? clean.slice(0, 4) + '-' + clean.slice(4) : clean);
  };

  const handleRedeemPairCode = async (e: React.FormEvent) => {
    e.preventDefault();
    if (pairCode.replace(/-/g, '').length !== 8 || loading) return;

    setError(null);
    setLoading(true);
    try {
      const res = await ApiClient.redeemPairCode(pairCode);
      onLoginSuccess(res.user);
      navigate('/inbox');
    } catch (err: any) {
      setError(err.message || 'That code is invalid or has expired.');
    } finally {
      setLoading(false);
    }
  };

  const handleRequestOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || loading) return;

    setError(null);
    setLoading(true);
    try {
      await ApiClient.requestOtp(email.trim());
      setStep('otp');
    } catch (err: any) {
      setError(err.message || 'Failed to send OTP code');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!otp.trim() || loading) return;

    setError(null);
    setLoading(true);
    try {
      const res = await ApiClient.verifyOtp(email.trim(), otp.trim());
      onLoginSuccess(res.user);
      navigate('/inbox');
    } catch (err: any) {
      setError(err.message || 'Invalid or expired OTP code');
    } finally {
      setLoading(false);
    }
  };

  const heading =
    mode === 'pair'
      ? 'View Your Inbox'
      : step === 'email'
        ? 'Get Your Secret Link'
        : 'Enter One-Time Passcode';

  const subheading =
    mode === 'pair'
      ? 'Open the SecretMsg app, go to Settings then View on web, and type the code it shows.'
      : step === 'email'
        ? 'We will email you a one-time code. No password to leak, ever.'
        : 'We sent a 6-digit code to ' + email + '.';

  return (
    <div className="max-w-md mx-auto py-16 sm:py-24 px-4">
      <div className="glass-panel p-6 sm:p-8 rounded-2xl shadow-2xl space-y-6">
        <div className="text-center space-y-2">
          <div className="w-12 h-12 bg-indigo-500/10 border border-indigo-500/20 rounded-2xl flex items-center justify-center mx-auto text-indigo-400">
            {mode === 'pair' ? <Smartphone className="w-6 h-6" /> : <Lock className="w-6 h-6" />}
          </div>
          <h2 className="text-2xl font-bold text-white tracking-tight">{heading}</h2>
          <p className="text-xs text-slate-400">{subheading}</p>
        </div>

        {error && (
          <div className="text-xs text-rose-300 bg-rose-500/10 border border-rose-500/20 rounded-xl px-3 py-2 text-center">
            {error}
          </div>
        )}

        {mode === 'pair' ? (
          <form onSubmit={handleRedeemPairCode} className="space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="pair-code" className="text-xs font-semibold text-slate-300">
                Pairing code
              </label>
              <div className="relative">
                <KeyRound className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  id="pair-code"
                  value={pairCode}
                  onChange={(e) => onPairCodeChange(e.target.value)}
                  placeholder="XXXX-XXXX"
                  autoComplete="one-time-code"
                  autoCapitalize="characters"
                  spellCheck={false}
                  className="w-full bg-slate-900/60 border border-white/10 rounded-xl pl-9 pr-3 py-2.5 text-center text-lg font-mono tracking-widest text-white placeholder:text-slate-600 focus:outline-none focus:border-indigo-500/50"
                />
              </div>
              <p className="text-[11px] text-slate-500">
                Codes last 5 minutes and can only be used once.
              </p>
            </div>

            <button
              type="submit"
              disabled={loading || pairCode.replace(/-/g, '').length !== 8}
              className="w-full bg-indigo-500 hover:bg-indigo-400 disabled:opacity-40 disabled:cursor-not-allowed text-white font-bold py-2.5 rounded-xl flex items-center justify-center space-x-2 transition-colors"
            >
              <span>{loading ? 'Checking...' : 'View my inbox'}</span>
              {!loading && <ArrowRight className="w-4 h-4" />}
            </button>

            <div className="flex items-start space-x-2 text-[11px] text-slate-500 bg-white/[0.02] border border-white/5 rounded-xl px-3 py-2">
              <Eye className="w-3.5 h-3.5 mt-0.5 shrink-0 text-slate-400" />
              <span>
                Pairing gives this browser <strong className="text-slate-400">view-only</strong> access.
                Replies and settings stay in the app.
              </span>
            </div>
          </form>
        ) : step === 'email' ? (
          <form onSubmit={handleRequestOtp} className="space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="login-email" className="text-xs font-semibold text-slate-300">
                Email
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  id="login-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  className="w-full bg-slate-900/60 border border-white/10 rounded-xl pl-9 pr-3 py-2.5 text-sm text-white placeholder:text-slate-600 focus:outline-none focus:border-indigo-500/50"
                />
              </div>
            </div>
            <button
              type="submit"
              disabled={loading || !email.trim()}
              className="w-full bg-indigo-500 hover:bg-indigo-400 disabled:opacity-40 disabled:cursor-not-allowed text-white font-bold py-2.5 rounded-xl flex items-center justify-center space-x-2 transition-colors"
            >
              <span>{loading ? 'Sending...' : 'Send code'}</span>
              {!loading && <ArrowRight className="w-4 h-4" />}
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerifyOtp} className="space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="login-otp" className="text-xs font-semibold text-slate-300">
                6-digit code
              </label>
              <div className="relative">
                <KeyRound className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  id="login-otp"
                  inputMode="numeric"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/[^0-9]/g, '').slice(0, 6))}
                  placeholder="000000"
                  className="w-full bg-slate-900/60 border border-white/10 rounded-xl pl-9 pr-3 py-2.5 text-center text-lg font-mono tracking-widest text-white placeholder:text-slate-600 focus:outline-none focus:border-indigo-500/50"
                />
              </div>
            </div>
            <button
              type="submit"
              disabled={loading || otp.length !== 6}
              className="w-full bg-indigo-500 hover:bg-indigo-400 disabled:opacity-40 disabled:cursor-not-allowed text-white font-bold py-2.5 rounded-xl flex items-center justify-center space-x-2 transition-colors"
            >
              <span>{loading ? 'Verifying...' : 'Verify and continue'}</span>
              {!loading && <ArrowRight className="w-4 h-4" />}
            </button>
            <button
              type="button"
              onClick={() => { setStep('email'); setOtp(''); setError(null); }}
              className="w-full text-center text-xs text-slate-400 hover:text-white"
            >
              Change email address
            </button>
          </form>
        )}

        <div className="pt-2 border-t border-white/5 text-center">
          {mode === 'pair' ? (
            <button
              type="button"
              onClick={() => switchMode('email')}
              className="text-[11px] text-slate-400 hover:text-white underline"
            >
              Sign in with email instead
            </button>
          ) : (
            <button
              type="button"
              onClick={() => { switchMode('pair'); setStep('email'); setOtp(''); }}
              className="text-[11px] text-slate-400 hover:text-white underline"
            >
              Use a pairing code from the app
            </button>
          )}
        </div>

        <div className="pt-2 border-t border-white/5 text-center text-[11px] text-slate-500">
          <span>By continuing, you agree to our </span>
          <Link to="/p/terms" className="underline hover:text-slate-400">Terms</Link>
          <span> and </span>
          <Link to="/p/privacy" className="underline hover:text-slate-400">Privacy Policy</Link>.
        </div>
      </div>
    </div>
  );
};
