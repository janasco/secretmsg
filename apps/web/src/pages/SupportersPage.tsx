import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Heart,
  ShieldCheck,
  Lock,
  CheckCircle2,
  Users,
  Smartphone,
  Ban,
  CreditCard,
  ScrollText
} from 'lucide-react';
import { ApiClient, SupportersData } from '@/lib/api';

interface SupportersPageProps {
  onOpenSupport: () => void;
}

const FACTS = [
  {
    icon: Smartphone,
    title: 'Ads pay for the app',
    desc: 'Google AdMob serves a banner and an optional rewarded video in the Android app. That revenue covers hosting. It is the whole model.',
  },
  {
    icon: Ban,
    title: 'The website has none',
    desc: 'secretmsg.net loads no ad network code at all. No banner, no rewarded video, no ad script, nothing to dismiss.',
  },
  {
    icon: CreditCard,
    title: 'One purchase, not a subscription',
    desc: '“Remove Ads” is a single Google Play in-app purchase. It does not renew, there is no plan to cancel, and your ad-free status attaches to your SecretMsg account.',
  },
];

export const SupportersPage: React.FC<SupportersPageProps> = ({ onOpenSupport }) => {
  const [data, setData] = useState<SupportersData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [loadKey, setLoadKey] = useState(0);

  useEffect(() => {
    let isMounted = true;
    setLoading(true);
    setError(false);
    setData(null);

    ApiClient.getSupporters()
      .then((res) => {
        if (isMounted) setData(res);
      })
      .catch(() => {
        if (isMounted) setError(true);
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [loadKey]);

  const stats = data?.stats;
  const goalPercent = Math.min(100, Math.max(0, stats?.monthlyServerGoalPercent ?? 0));

  return (
    <div className="max-w-5xl mx-auto py-12 sm:py-16 px-4 space-y-12 animate-in fade-in duration-200">
      <div className="text-center space-y-4 max-w-2xl mx-auto">
        <div className="inline-flex items-center space-x-2 px-3.5 py-1.5 rounded-full text-xs font-medium bg-amber-500/10 text-amber-300 border border-amber-500/20 shadow-sm">
          <Heart className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
          <span>How SecretMsg Is Paid For</span>
        </div>

        <h1 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white leading-tight">
          Ads in the App,{' '}
          <span className="bg-gradient-to-r from-amber-300 via-amber-400 to-indigo-400 bg-clip-text text-transparent">
            No Ads on the Web
          </span>
        </h1>

        <p className="text-sm sm:text-base text-slate-400 leading-relaxed">
          There is no donation button and no web checkout. The Android app serves ads through Google
          AdMob, and one in-app purchase removes them for good. This website is free and ad-free, and
          will stay that way.
        </p>

        <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3">
          <button
            onClick={onOpenSupport}
            className="inline-flex items-center space-x-2 py-3 px-6 rounded-xl font-semibold text-sm bg-gradient-to-r from-amber-500 via-amber-400 to-amber-500 hover:opacity-95 text-dark-950 shadow-xl shadow-amber-500/20 transition-all active:scale-95"
          >
            <Heart className="w-4 h-4" />
            <span>How to Support the Project</span>
          </button>
          <Link
            to="/download"
            className="inline-flex items-center space-x-2 py-3 px-6 rounded-xl font-medium text-sm bg-dark-900/90 hover:bg-dark-800 text-indigo-300 border border-indigo-500/20 transition-colors"
          >
            <Smartphone className="w-4 h-4" />
            <span>Get the Android App</span>
          </Link>
        </div>
      </div>

      {error && (
        <div className="text-center py-8 glass-panel rounded-2xl p-6 space-y-2" role="alert">
          <p className="text-xs text-slate-400">Support totals are unavailable right now.</p>
          <button
            onClick={() => setLoadKey((key) => key + 1)}
            className="py-2 px-4 rounded-lg text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
          >
            Try again
          </button>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="glass-panel p-5 rounded-2xl space-y-1 border-white/10">
          <div className="flex items-center space-x-2 text-indigo-400 text-xs font-semibold">
            <Users className="w-4 h-4" />
            <span>Ad-Free Accounts</span>
          </div>
          <p className="text-2xl font-bold text-white">
            {loading ? '...' : error ? '—' : (stats?.totalSupporters ?? 0)}
          </p>
          <p className="text-[11px] text-slate-400">People who removed the ads with a one-time purchase</p>
        </div>

        <div className="glass-panel p-5 rounded-2xl space-y-1 border-emerald-500/20">
          <div className="flex items-center space-x-2 text-emerald-400 text-xs font-semibold">
            <CheckCircle2 className="w-4 h-4" />
            <span>Server Hosting Goal</span>
          </div>
          <div className="flex items-baseline space-x-2">
            <p className="text-2xl font-bold text-emerald-300">
              {error ? '—' : `${stats?.monthlyServerGoalPercent ?? 0}%`}
            </p>
            <span className="text-xs text-emerald-400/80 font-medium">
              {error ? 'Funding status unavailable' : `Funded for ${stats?.currentMonth || 'the current month'}`}
            </span>
          </div>
          <div className="w-full bg-dark-900 h-2 rounded-full overflow-hidden mt-1">
            <div
              className="bg-gradient-to-r from-emerald-500 to-teal-400 h-full rounded-full"
              style={{ width: `${error ? 0 : goalPercent}%` }}
            ></div>
          </div>
        </div>

        <div className="glass-panel p-5 rounded-2xl space-y-1 border-white/10">
          <div className="flex items-center space-x-2 text-amber-400 text-xs font-semibold">
            <ShieldCheck className="w-4 h-4" />
            <span>No Donor Records</span>
          </div>
          <p className="text-2xl font-bold text-white">Count Only</p>
          <p className="text-[11px] text-slate-400">We publish a number, never a name, alias, or supporter list</p>
        </div>
      </div>

      <div className="space-y-2.5">
        {FACTS.map(({ icon: Icon, title, desc }) => (
          <div
            key={title}
            className="glass-panel p-5 rounded-2xl border-white/10 space-y-1.5 hover:border-amber-500/30 transition-colors"
          >
            <div className="flex items-center space-x-2.5">
              <div className="w-9 h-9 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400 shrink-0">
                <Icon className="w-4 h-4" />
              </div>
              <h3 className="text-sm font-bold text-white">{title}</h3>
            </div>
            <p className="text-xs text-slate-400 leading-relaxed">{desc}</p>
          </div>
        ))}
      </div>

      <div className="glass-panel p-6 rounded-2xl border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4 text-center sm:text-left">
        <div className="space-y-1">
          <h4 className="text-sm font-bold text-white flex items-center justify-center sm:justify-start space-x-2">
            <Lock className="w-4 h-4 text-emerald-400" />
            <span>What Ads Do and Do Not Reach</span>
          </h4>
          <p className="text-xs text-slate-400 max-w-2xl">
            Ad requests are made by Google&apos;s ad SDK on your device. Message content, sender
            identity, and your SecretMsg account are never attached to an ad request. Read the
            details, including advertising identifiers and your opt-out rights, in the privacy policy.
          </p>
        </div>
        <Link
          to="/p/privacy"
          className="shrink-0 py-2 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors flex items-center space-x-1.5"
        >
          <ScrollText className="w-3.5 h-3.5 text-indigo-300" />
          <span>Read the Policy</span>
        </Link>
      </div>
    </div>
  );
};
