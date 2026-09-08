import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { ApiClient, UserProfile } from '../lib/api';
import { Mail, KeyRound, ArrowRight, ShieldCheck, Lock } from 'lucide-react';

interface LoginPageProps {
  onLoginSuccess: (user: UserProfile) => void;
}

export const LoginPage: React.FC<LoginPageProps> = ({ onLoginSuccess }) => {
  const navigate = useNavigate();
  const [step, setStep] = useState<'email' | 'otp'>('email');
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

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

  return (
    <div className="max-w-md mx-auto py-16 sm:py-24 px-4">
      <div className="glass-panel p-6 sm:p-8 rounded-2xl shadow-2xl space-y-6">
        <div className="text-center space-y-2">
          <div className="w-12 h-12 bg-indigo-500/10 border border-indigo-500/20 rounded-2xl flex items-center justify-center mx-auto text-indigo-400">
            <Lock className="w-6 h-6" />
          </div>
          <h2 className="text-2xl font-bold text-white tracking-tight">
            {step === 'email' ? 'Get Your Secret Link' : 'Enter One-Time Passcode'}
          </h2>
          <p className="text-xs text-slate-400">
            {step === 'email'
              ? 'Enter your email to log in or create your secretmsg.net link. No password required.'
              : `We sent a 6-digit login code to ${email}`}
          </p>
        </div>

        {error && (
          <div className="p-3.5 bg-rose-500/10 border border-rose-500/20 rounded-xl text-xs text-rose-300">
            {error}
          </div>
        )}

        {step === 'email' ? (
          <form onSubmit={handleRequestOtp} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-xs font-medium text-slate-300">Email Address</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-500 absolute left-3.5 top-3.5" />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  className="w-full bg-dark-900 border border-white/15 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-xl py-3 pl-10 pr-4 text-sm text-white placeholder-slate-500 outline-none"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading || !email.trim()}
              className="w-full py-3 px-4 rounded-xl font-semibold text-sm bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 text-white shadow-lg shadow-indigo-500/20 flex items-center justify-center space-x-2 transition-all disabled:opacity-50"
            >
              {loading ? (
                <span>Sending Code...</span>
              ) : (
                <>
                  <span>Continue with Email</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerifyOtp} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-xs font-medium text-slate-300">6-Digit Code</label>
              <div className="relative">
                <KeyRound className="w-4 h-4 text-slate-500 absolute left-3.5 top-3.5" />
                <input
                  type="text"
                  required
                  maxLength={6}
                  value={otp}
                  onChange={(e) => setOtp(e.target.value)}
                  placeholder="123456"
                  className="w-full bg-dark-900 border border-white/15 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-xl py-3 pl-10 pr-4 text-sm font-mono tracking-widest text-center text-white placeholder-slate-600 outline-none"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading || otp.length < 6}
              className="w-full py-3 px-4 rounded-xl font-semibold text-sm bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 text-white shadow-lg shadow-indigo-500/20 flex items-center justify-center space-x-2 transition-all disabled:opacity-50"
            >
              {loading ? <span>Verifying...</span> : <span>Verify & Open Inbox</span>}
            </button>

            <button
              type="button"
              onClick={() => {
                setStep('email');
                setError(null);
              }}
              className="w-full text-center text-xs text-slate-400 hover:text-white"
            >
              Change email address
            </button>
          </form>
        )}

        <div className="pt-2 border-t border-white/5 text-center text-[11px] text-slate-500">
          <span>By continuing, you agree to our </span>
          <Link to="/legal/terms" className="underline hover:text-slate-400">Terms</Link>
          <span> and </span>
          <Link to="/legal/privacy" className="underline hover:text-slate-400">Privacy Policy</Link>.
        </div>
      </div>
    </div>
  );
};
