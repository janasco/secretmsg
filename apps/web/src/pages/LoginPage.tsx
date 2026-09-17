import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ApiClient, UserProfile } from '@/lib/api';
import { ArrowRight, Shield, Smartphone, Mail } from 'lucide-react';

interface LoginPageProps {
  onLoginSuccess: (user: UserProfile) => void;
}

type Mode = 'login' | 'signup' | 'recover' | 'pair' | 'otp';

export const LoginPage: React.FC<LoginPageProps> = ({ onLoginSuccess }) => {
  const navigate = useNavigate();
  const [mode, setMode] = useState<Mode>('login');
  const [handle, setHandle] = useState('');
  const [pin, setPin] = useState('');
  const [backupCode, setBackupCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [backupCodes, setBackupCodes] = useState<string[]>([]);
  const [signupHandle, setSignupHandle] = useState('');
  const [pairCode, setPairCode] = useState('');
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState('');
  const [otpSent, setOtpSent] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!handle || !pin || loading) return;
    setError(null);
    setLoading(true);
    try {
      const res = await ApiClient.authLogin(handle, pin);
      onLoginSuccess(res.user);
      navigate('/inbox');
    } catch (err: any) {
      setError(err.message || 'Invalid handle or PIN');
    } finally {
      setLoading(false);
    }
  };

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!pin || loading) return;
    setError(null);
    setLoading(true);
    try {
      const res = await ApiClient.authSignup(handle || undefined, pin);
      setBackupCodes(res.backupCodes);
      setSignupHandle(res.handle);
    } catch (err: any) {
      setError(err.message || 'Signup failed');
    } finally {
      setLoading(false);
    }
  };

  const handleRecover = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!handle || !backupCode || !pin || loading) return;
    setError(null);
    setLoading(true);
    try {
      const res = await ApiClient.authRecover(handle, backupCode, pin);
      onLoginSuccess({ id: '', username: res.user.username, display_name: res.user.username } as UserProfile);
      navigate('/inbox');
    } catch (err: any) {
      setError(err.message || 'Recovery failed');
    } finally {
      setLoading(false);
    }
  };

  const handlePair = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!pairCode || loading) return;
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

  const handleOtpRequest = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || loading) return;
    setError(null);
    setLoading(true);
    try {
      await ApiClient.requestOtp(email);
      setOtpSent(true);
    } catch (err: any) {
      setError(err.message || 'Failed to send code');
    } finally {
      setLoading(false);
    }
  };

  const handleOtpVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !otp || loading) return;
    setError(null);
    setLoading(true);
    try {
      const res = await ApiClient.verifyOtp(email, otp);
      onLoginSuccess(res.user);
      navigate('/inbox');
    } catch (err: any) {
      setError(err.message || 'Invalid or expired code');
    } finally {
      setLoading(false);
    }
  };

  const resetMode = (m: Mode) => {
    setMode(m);
    setError(null);
    setPin('');
    setBackupCode('');
    setPairCode('');
    setOtp('');
    setOtpSent(false);
  };

  // Show backup codes after signup
  if (backupCodes.length > 0) {
    return (
      <div className="min-h-[80vh] flex items-center justify-center px-4">
        <div className="w-full max-w-md space-y-6">
          <div className="text-center space-y-2">
            <Shield className="w-10 h-10 text-indigo-400 mx-auto" />
            <h1 className="text-2xl font-bold text-white">Save Your Backup Codes</h1>
            <p className="text-sm text-red-400 font-medium">These will NEVER be shown again. Save them somewhere safe.</p>
          </div>
          <div className="glass-panel p-6 rounded-2xl space-y-4">
            <p className="text-sm text-slate-300">Handle: <span className="font-bold text-white">{signupHandle}</span></p>
            <div className="grid grid-cols-2 gap-2">
              {backupCodes.map((code, i) => (
                <div key={i} className="bg-dark-900 rounded-lg p-2 text-center font-mono text-sm text-white font-bold">{code}</div>
              ))}
            </div>
            <button
              onClick={() => {
                navigator.clipboard.writeText(backupCodes.join('\n'));
              }}
              className="w-full py-2 rounded-lg text-sm font-medium bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
            >
              Copy All Codes
            </button>
            <button
              onClick={() => {
                onLoginSuccess({ id: '', username: signupHandle, display_name: signupHandle } as UserProfile);
                navigate('/inbox');
              }}
              className="w-full py-3 rounded-xl font-semibold text-sm bg-indigo-600 hover:bg-indigo-500 text-white transition-colors"
            >
              I've Saved My Codes
            </button>
          </div>
        </div>
      </div>
    );
  }

  const title = mode === 'login' ? 'Welcome Back' : mode === 'signup' ? 'Create Account' : mode === 'recover' ? 'Recover Account' : mode === 'pair' ? 'Pair a Browser' : 'Email Login';
  const subtitle = mode === 'login' ? 'Log in with your handle and PIN' : mode === 'signup' ? 'Choose a handle, set a PIN, save your codes' : mode === 'recover' ? 'Use a backup code to reset your PIN' : mode === 'pair' ? 'Enter the 8-character code from the app (view-only)' : 'Legacy email accounts: get a 6-digit code';

  return (
    <div className="min-h-[80vh] flex items-center justify-center px-4">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center space-y-2">
          <Shield className="w-10 h-10 text-indigo-400 mx-auto" />
          <h1 className="text-2xl font-bold text-white">{title}</h1>
          <p className="text-sm text-slate-400">{subtitle}</p>
        </div>

        <div className="glass-panel p-6 rounded-2xl space-y-4">
          {mode === 'recover' ? (
            <form onSubmit={handleRecover} className="space-y-3">
              <input type="text" placeholder="Handle" value={handle} onChange={e => setHandle(e.target.value)}
                className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
              <input type="text" placeholder="Backup Code (XXXX-XXXX)" value={backupCode} onChange={e => setBackupCode(e.target.value.toUpperCase())}
                className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm font-mono placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
              <input type="password" placeholder="New PIN (4-6 digits)" value={pin} onChange={e => setPin(e.target.value)} maxLength={6}
                className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
              <button type="submit" disabled={loading}
                className="w-full py-3 rounded-xl font-semibold text-sm bg-indigo-600 hover:bg-indigo-500 text-white transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
                {loading ? <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <>Recover Account <ArrowRight className="w-4 h-4" /></>}
              </button>
            </form>
          ) : mode === 'signup' ? (
            <form onSubmit={handleSignup} className="space-y-3">
              <input type="text" placeholder="Handle (optional, auto-generated if empty)" value={handle} onChange={e => setHandle(e.target.value)}
                className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
              <input type="password" placeholder="Set a PIN (4-6 digits)" value={pin} onChange={e => setPin(e.target.value)} maxLength={6}
                className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
              <button type="submit" disabled={loading}
                className="w-full py-3 rounded-xl font-semibold text-sm bg-indigo-600 hover:bg-indigo-500 text-white transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
                {loading ? <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <>Create Account <ArrowRight className="w-4 h-4" /></>}
              </button>
            </form>
          ) : mode === 'pair' ? (
            <form onSubmit={handlePair} className="space-y-3">
              <input type="text" placeholder="XXXX-XXXX" value={pairCode} onChange={e => setPairCode(e.target.value.toUpperCase())}
                className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm font-mono text-center tracking-widest placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
              <button type="submit" disabled={loading}
                className="w-full py-3 rounded-xl font-semibold text-sm bg-cyan-600 hover:bg-cyan-500 text-white transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
                {loading ? <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <><Smartphone className="w-4 h-4" /> Pair View-Only</>}
              </button>
              <p className="text-[11px] text-slate-500 text-center">Single-use, expires in 5 minutes. Paired browsers can read but not change anything.</p>
            </form>
          ) : mode === 'otp' ? (
            <div className="space-y-3">
              {!otpSent ? (
                <form onSubmit={handleOtpRequest} className="space-y-3">
                  <input type="email" placeholder="you@example.com" value={email} onChange={e => setEmail(e.target.value)}
                    className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
                  <button type="submit" disabled={loading}
                    className="w-full py-3 rounded-xl font-semibold text-sm bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
                    {loading ? <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <><Mail className="w-4 h-4" /> Send Login Code</>}
                  </button>
                </form>
              ) : (
                <form onSubmit={handleOtpVerify} className="space-y-3">
                  <p className="text-xs text-slate-400">Code sent to <span className="text-white font-medium">{email}</span></p>
                  <input type="text" placeholder="6-digit code" value={otp} onChange={e => setOtp(e.target.value)} maxLength={6} inputMode="numeric"
                    className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm font-mono text-center tracking-widest placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
                  <button type="submit" disabled={loading}
                    className="w-full py-3 rounded-xl font-semibold text-sm bg-indigo-600 hover:bg-indigo-500 text-white transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
                    {loading ? <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <>Verify & Log In <ArrowRight className="w-4 h-4" /></>}
                  </button>
                  <button type="button" onClick={() => setOtpSent(false)} className="w-full text-xs text-slate-400 hover:text-white">Use a different email</button>
                </form>
              )}
            </div>
          ) : (
            <form onSubmit={handleLogin} className="space-y-3">
              <input type="text" placeholder="Handle" value={handle} onChange={e => setHandle(e.target.value)}
                className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
              <input type="password" placeholder="PIN" value={pin} onChange={e => setPin(e.target.value)} maxLength={6}
                className="w-full px-4 py-3 rounded-xl bg-dark-900 border border-white/10 text-white text-sm placeholder-slate-500 focus:outline-none focus:border-indigo-500" />
              <button type="submit" disabled={loading}
                className="w-full py-3 rounded-xl font-semibold text-sm bg-indigo-600 hover:bg-indigo-500 text-white transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
                {loading ? <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <>Log In <ArrowRight className="w-4 h-4" /></>}
              </button>
            </form>
          )}

          {error && <p className="text-sm text-red-400">{error}</p>}
        </div>

        <div className="text-center space-y-2">
          {(mode === 'login' || mode === 'pair' || mode === 'otp') && (
            <div className="flex items-center justify-center gap-2 flex-wrap">
              <button onClick={() => resetMode('login')} className={`text-sm ${mode === 'login' ? 'text-white font-semibold' : 'text-slate-400 hover:text-slate-300'}`}>Handle + PIN</button>
              <span className="text-slate-600">·</span>
              <button onClick={() => resetMode('pair')} className={`text-sm ${mode === 'pair' ? 'text-white font-semibold' : 'text-slate-400 hover:text-slate-300'}`}>Pair code</button>
              <span className="text-slate-600">·</span>
              <button onClick={() => resetMode('otp')} className={`text-sm ${mode === 'otp' ? 'text-white font-semibold' : 'text-slate-400 hover:text-slate-300'}`}>Email code</button>
            </div>
          )}
          {mode === 'login' && (
            <>
              <button onClick={() => resetMode('signup')}
                className="text-sm text-indigo-400 hover:text-indigo-300">Create new account</button>
              <span className="text-slate-600 mx-2">|</span>
              <button onClick={() => resetMode('recover')}
                className="text-sm text-slate-400 hover:text-slate-300">Forgot PIN?</button>
            </>
          )}
          {(mode === 'signup' || mode === 'recover') && (
            <button onClick={() => resetMode('login')}
              className="text-sm text-indigo-400 hover:text-indigo-300">Back to login</button>
          )}
        </div>
      </div>
    </div>
  );
};
