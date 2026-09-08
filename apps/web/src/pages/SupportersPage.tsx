import React, { useEffect, useState } from 'react';
import { 
  Heart, 
  ShieldCheck, 
  Coffee, 
  Lock, 
  Calendar,
  CheckCircle2,
  Filter,
  Users
} from 'lucide-react';
import { ApiClient, SupportersData } from '../lib/api';

interface SupportersPageProps {
  onOpenDonation: () => void;
}

const TIER_COLORS: Record<string, { bg: string; text: string; border: string; icon: string }> = {
  'Golden Guardian': {
    bg: 'bg-amber-500/10',
    text: 'text-amber-300',
    border: 'border-amber-500/30',
    icon: '🌟',
  },
  'Silver Patron': {
    bg: 'bg-cyan-500/10',
    text: 'text-cyan-300',
    border: 'border-cyan-500/30',
    icon: '🥈',
  },
  'Coffee Backer': {
    bg: 'bg-indigo-500/10',
    text: 'text-indigo-300',
    border: 'border-indigo-500/30',
    icon: '☕',
  },
  'Bronze Supporter': {
    bg: 'bg-rose-500/10',
    text: 'text-rose-300',
    border: 'border-rose-500/30',
    icon: '🥉',
  },
};

function formatRelativeTime(dateString: string): string {
  try {
    const date = new Date(dateString);
    const now = new Date();
    const diffHours = Math.round((now.getTime() - date.getTime()) / (1000 * 60 * 60));
    if (diffHours < 1) return 'Just now';
    if (diffHours === 1) return '1 hour ago';
    if (diffHours < 24) return `${diffHours} hours ago`;
    const diffDays = Math.round(diffHours / 24);
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 30) return `${diffDays} days ago`;
    return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
  } catch {
    return 'Recently';
  }
}

export const SupportersPage: React.FC<SupportersPageProps> = ({ onOpenDonation }) => {
  const [data, setData] = useState<SupportersData | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedTier, setSelectedTier] = useState<string>('all');

  useEffect(() => {
    let isMounted = true;
    setLoading(true);

    ApiClient.getSupporters()
      .then((res) => {
        if (isMounted) setData(res);
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, []);

  const supporters = data?.supporters || [];
  const filtered = selectedTier === 'all' 
    ? supporters 
    : supporters.filter((s: { tier: string }) => s.tier.toLowerCase() === selectedTier.toLowerCase());

  return (
    <div className="max-w-5xl mx-auto py-12 sm:py-16 px-4 space-y-12 animate-in fade-in duration-200">
      {/* Page Header */}
      <div className="text-center space-y-4 max-w-2xl mx-auto">
        <div className="inline-flex items-center space-x-2 px-3.5 py-1.5 rounded-full text-xs font-medium bg-amber-500/10 text-amber-300 border border-amber-500/20 shadow-sm">
          <Heart className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
          <span>Community Wall of Supporters</span>
        </div>

        <h1 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white leading-tight">
          Thank You to Our{' '}
          <span className="bg-gradient-to-r from-amber-300 via-amber-400 to-indigo-400 bg-clip-text text-transparent">
            Anonymous Donors
          </span>
        </h1>

        <p className="text-sm sm:text-base text-slate-400 leading-relaxed">
          SecretMsg is a 100% free, independent project funded entirely by our community.
          To protect every supporter’s confidentiality, donors are listed anonymously or by their chosen alias.
          Zero personal data, emails, or banking details are ever made public.
        </p>

        <div className="pt-2">
          <button
            onClick={onOpenDonation}
            className="inline-flex items-center space-x-2 py-3 px-6 rounded-xl font-semibold text-sm bg-gradient-to-r from-amber-500 via-amber-400 to-amber-500 hover:opacity-95 text-dark-950 shadow-xl shadow-amber-500/20 transition-all active:scale-95"
          >
            <Coffee className="w-4 h-4" />
            <span>Donate & Join the Wall</span>
          </button>
        </div>
      </div>

      {/* Metrics & Sustainability Bar */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="glass-panel p-5 rounded-2xl space-y-1 border-white/10">
          <div className="flex items-center space-x-2 text-indigo-400 text-xs font-semibold">
            <Users className="w-4 h-4" />
            <span>Total Backers</span>
          </div>
          <p className="text-2xl font-bold text-white">
            {loading ? '...' : (data?.stats.totalSupporters || 4)}
          </p>
          <p className="text-[11px] text-slate-400">Generous souls keeping the service online</p>
        </div>

        <div className="glass-panel p-5 rounded-2xl space-y-1 border-emerald-500/20">
          <div className="flex items-center space-x-2 text-emerald-400 text-xs font-semibold">
            <CheckCircle2 className="w-4 h-4" />
            <span>Server Hosting Goal</span>
          </div>
          <div className="flex items-baseline space-x-2">
            <p className="text-2xl font-bold text-emerald-300">
              {data?.stats.monthlyServerGoalPercent || 100}%
            </p>
            <span className="text-xs text-emerald-400/80 font-medium">Funded for {data?.stats.currentMonth || 'Current Month'}</span>
          </div>
          <div className="w-full bg-dark-900 h-2 rounded-full overflow-hidden mt-1">
            <div 
              className="bg-gradient-to-r from-emerald-500 to-teal-400 h-full rounded-full" 
              style={{ width: `${Math.min(100, data?.stats.monthlyServerGoalPercent || 100)}%` }}
            ></div>
          </div>
        </div>

        <div className="glass-panel p-5 rounded-2xl space-y-1 border-white/10">
          <div className="flex items-center space-x-2 text-amber-400 text-xs font-semibold">
            <ShieldCheck className="w-4 h-4" />
            <span>Strict Privacy Shield</span>
          </div>
          <p className="text-2xl font-bold text-white">100% Confidential</p>
          <p className="text-[11px] text-slate-400">Zero emails, card tokens, or IP logs published</p>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-white/10 pb-4">
        <div className="flex items-center space-x-2">
          <Filter className="w-4 h-4 text-slate-400" />
          <span className="text-xs font-semibold text-slate-300">Filter Tier:</span>
        </div>

        <div className="flex flex-wrap gap-2 text-xs">
          {[
            { id: 'all', label: 'All Donors' },
            { id: 'Golden Guardian', label: '🌟 Guardians' },
            { id: 'Silver Patron', label: '🥈 Patrons' },
            { id: 'Coffee Backer', label: '☕ Coffee Backers' },
            { id: 'Bronze Supporter', label: '🥉 Supporters' },
          ].map((tier) => (
            <button
              key={tier.id}
              onClick={() => setSelectedTier(tier.id)}
              className={`px-3 py-1.5 rounded-xl font-medium transition-all ${
                selectedTier === tier.id
                  ? 'bg-amber-500/20 text-amber-200 border border-amber-500/40 shadow-sm'
                  : 'bg-dark-900/60 text-slate-400 hover:text-white border border-white/5'
              }`}
            >
              {tier.label}
            </button>
          ))}
        </div>
      </div>

      {/* Supporters Grid */}
      {loading ? (
        <div className="flex flex-col items-center justify-center py-16 space-y-3">
          <div className="w-8 h-8 border-2 border-amber-500 border-t-transparent rounded-full animate-spin"></div>
          <p className="text-xs text-slate-400">Loading supporters wall...</p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 glass-panel rounded-2xl p-8 space-y-3">
          <Heart className="w-8 h-8 text-slate-500 mx-auto" />
          <h3 className="text-base font-semibold text-white">No supporters found in this tier yet</h3>
          <p className="text-xs text-slate-400">Be the first to claim this supporter rank!</p>
          <button
            onClick={onOpenDonation}
            className="text-xs text-amber-400 hover:underline font-medium"
          >
            Become a supporter →
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {filtered.map((supporter) => {
            const tierStyle = TIER_COLORS[supporter.tier] || {
              bg: 'bg-white/10',
              text: 'text-slate-300',
              border: 'border-white/10',
              icon: '💖',
            };

            return (
              <div
                key={supporter.id}
                className="glass-panel p-5 rounded-2xl border-white/10 hover:border-amber-500/30 transition-all space-y-3 group"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-amber-500/40 to-indigo-500/40 border border-white/10 flex items-center justify-center text-sm font-bold text-white shadow-inner">
                      {tierStyle.icon}
                    </div>
                    <div>
                      <div className="flex items-center space-x-1.5">
                        <h4 className="text-sm font-bold text-white group-hover:text-amber-200 transition-colors">
                          {supporter.alias}
                        </h4>
                        <Lock className="w-3 h-3 text-slate-500" title="Identity Protected" />
                      </div>
                      <span className="text-[11px] text-slate-500 font-mono flex items-center space-x-1">
                        <Calendar className="w-3 h-3" />
                        <span>{formatRelativeTime(supporter.createdAt)}</span>
                      </span>
                    </div>
                  </div>

                  <span className={`px-2.5 py-1 rounded-full text-[11px] font-semibold border ${tierStyle.bg} ${tierStyle.text} ${tierStyle.border}`}>
                    {supporter.tier}
                  </span>
                </div>

                {/* Uplifting Note / Cheering Quote */}
                {supporter.note && (
                  <div className="bg-dark-900/80 border border-white/5 p-3 rounded-xl">
                    <p className="text-xs text-slate-300 leading-relaxed italic">
                      "{supporter.note}"
                    </p>
                  </div>
                )}

                <div className="flex items-center justify-between text-[10px] text-slate-500 pt-1 border-t border-white/5">
                  <span className="flex items-center space-x-1 text-emerald-400/80">
                    <CheckCircle2 className="w-3 h-3" />
                    <span>Verified Anonymous Contribution</span>
                  </span>
                  <span className="font-mono text-slate-600">ID: {supporter.id.slice(0, 8)}</span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Privacy Policy Callout */}
      <div className="glass-panel p-6 rounded-2xl border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4 text-center sm:text-left">
        <div className="space-y-1">
          <h4 className="text-sm font-bold text-white flex items-center justify-center sm:justify-start space-x-2">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>Our Donor Privacy Commitment</span>
          </h4>
          <p className="text-xs text-slate-400 max-w-2xl">
            We believe people who donate to support open tools deserve maximum privacy. We do not store donor bank details, full legal names, or emails on public infrastructure.
          </p>
        </div>
        <button
          onClick={onOpenDonation}
          className="shrink-0 py-2 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
        >
          Support the Project
        </button>
      </div>
    </div>
  );
};
