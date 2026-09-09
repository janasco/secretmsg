import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Lock,
  ShieldCheck,
  Sparkles,
  Send,
  Share2,
  Heart,
  ArrowRight,
  Github,
  Dices
} from 'lucide-react';

interface LandingPageProps {
  onOpenDonation: () => void;
}

const SAMPLE_VIBES = [
  {
    category: 'Friendly & Hype',
    icon: '🌟',
    badge: 'Popular for Friends',
    quote: '"TBH, you always have the best energy and your style is unmatched. We definitely need to hang out more soon!"',
    color: 'from-amber-500/20 via-indigo-900/40 to-dark-900',
    border: 'border-amber-500/30',
  },
  {
    category: 'Low-key & Chill',
    icon: '☕',
    badge: 'Real Talk',
    quote: '"TBH, we don\'t talk as much as we used to, but I still think you\'re a super cool person."',
    color: 'from-cyan-500/20 via-indigo-900/40 to-dark-900',
    border: 'border-cyan-500/30',
  },
  {
    category: 'Sweet & Wholesome',
    icon: '💖',
    badge: 'Uplifting',
    quote: '"TBH, you\'re a wonderful person and you always know exactly how to make people smile."',
    color: 'from-rose-500/20 via-indigo-900/40 to-dark-900',
    border: 'border-rose-500/30',
  },
  {
    category: 'Crush & Secret Admirer',
    icon: '💘',
    badge: 'Confessions',
    quote: '"TBH, I\'ve had a crush on you for a while and your smile genuinely makes my whole day."',
    color: 'from-purple-500/20 via-pink-900/40 to-dark-900',
    border: 'border-pink-500/30',
  },
];

export const LandingPage: React.FC<LandingPageProps> = ({ onOpenDonation }) => {
  const [selectedVibeIndex, setSelectedVibeIndex] = useState(0);

  return (
    <div className="space-y-24 py-10 sm:py-20 max-w-5xl mx-auto px-4">
      {/* Hero Section */}
      <div className="text-center space-y-6 max-w-3xl mx-auto">
        <div className="inline-flex items-center space-x-2 px-3.5 py-1.5 rounded-full text-xs font-medium bg-indigo-500/10 text-indigo-300 border border-indigo-500/20 shadow-sm animate-pulse">
          <Sparkles className="w-3.5 h-3.5 text-amber-400" />
          <span>The Open Source NGL & TBH Alternative • True Anonymity</span>
        </div>

        <h1 className="text-4xl sm:text-6xl font-extrabold tracking-tight text-white leading-[1.15]">
          Authentic thoughts. Positive vibes.{' '}
          <span className="bg-gradient-to-r from-indigo-400 via-amber-300 to-amber-500 bg-clip-text text-transparent">
            100% Anonymous.
          </span>
        </h1>

        <p className="text-base sm:text-lg text-slate-400 max-w-2xl mx-auto leading-relaxed">
          Post your customized story sticker to Instagram or Snapchat. Receive candid, uplifting TBH statements, confessions, and honest feedback from friends, crushes, and followers without tracking.
        </p>

        <div className="pt-4 flex flex-col sm:flex-row items-center justify-center gap-3">
          <Link
            to="/login"
            className="w-full sm:w-auto py-3.5 px-7 rounded-xl font-semibold text-sm bg-gradient-to-r from-indigo-600 via-indigo-500 to-indigo-600 hover:opacity-95 text-white shadow-xl shadow-indigo-500/25 flex items-center justify-center space-x-2 transition-all"
          >
            <span>Get Your Free Secret Link</span>
            <ArrowRight className="w-4 h-4" />
          </Link>

          <button
            onClick={onOpenDonation}
            className="w-full sm:w-auto py-3.5 px-6 rounded-xl font-medium text-sm bg-dark-900/90 hover:bg-dark-800 text-amber-300 border border-amber-500/20 flex items-center justify-center space-x-2 transition-colors"
          >
            <Heart className="w-4 h-4 text-amber-400 fill-amber-400" />
            <span>Support Project & Get Badge</span>
          </button>
        </div>
      </div>

      {/* Interactive TBH / NGL Vibe Preview Showcase */}
      <div className="glass-panel p-6 sm:p-8 rounded-3xl border-indigo-500/30 space-y-6 relative overflow-hidden">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-white/10 pb-5">
          <div className="space-y-1">
            <div className="flex items-center space-x-2 text-indigo-400 text-xs font-bold uppercase tracking-wider">
              <Sparkles className="w-4 h-4" />
              <span>Trending Social Media Format</span>
            </div>
            <h2 className="text-2xl font-bold text-white">Choose Your Vibe or Shuffle</h2>
            <p className="text-xs sm:text-sm text-slate-400">
              Senders don't have to struggle with writer's block. One tap loads curated candid messages.
            </p>
          </div>

          {/* Tab Selector */}
          <div className="flex flex-wrap gap-2">
            {SAMPLE_VIBES.map((vibe, idx) => (
              <button
                key={vibe.category}
                onClick={() => setSelectedVibeIndex(idx)}
                className={`py-2 px-3 rounded-xl text-xs font-semibold transition-all flex items-center space-x-1.5 ${
                  selectedVibeIndex === idx
                    ? 'bg-indigo-600 text-white shadow-md shadow-indigo-500/30 scale-105'
                    : 'bg-dark-900/70 text-slate-400 hover:text-white border border-white/5'
                }`}
              >
                <span>{vibe.icon}</span>
                <span>{vibe.category}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Live Vibe Sample Card */}
        <div className={`p-6 sm:p-8 rounded-2xl bg-gradient-to-br ${SAMPLE_VIBES[selectedVibeIndex].color} border ${SAMPLE_VIBES[selectedVibeIndex].border} shadow-2xl transition-all duration-300`}>
          <div className="flex items-center justify-between mb-4">
            <span className="px-3 py-1 rounded-full text-[11px] font-semibold bg-white/10 text-white backdrop-blur-md">
              {SAMPLE_VIBES[selectedVibeIndex].badge}
            </span>
            <span className="text-xs text-slate-400 font-mono flex items-center space-x-1">
              <Lock className="w-3.5 h-3.5 text-indigo-400" />
              <span>Anonymous Sender</span>
            </span>
          </div>

          <p className="text-base sm:text-xl font-medium text-white leading-relaxed italic">
            {SAMPLE_VIBES[selectedVibeIndex].quote}
          </p>

          <div className="mt-6 pt-4 border-t border-white/10 flex flex-wrap items-center justify-between text-xs text-slate-300 gap-2">
            <div className="flex items-center space-x-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              <span>Delivered via <span className="font-mono text-white">secretmsg.net/alex</span></span>
            </div>
            <div className="flex items-center space-x-2 text-indigo-300">
              <Dices className="w-3.5 h-3.5" />
              <span>Click shuffle in-app for more templates</span>
            </div>
          </div>
        </div>
      </div>

      {/* How it Works (Instagram & Snapchat Story flow) */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="glass-panel p-6 rounded-2xl space-y-3 glass-card-hover">
          <div className="w-10 h-10 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400">
            <Share2 className="w-5 h-5" />
          </div>
          <h3 className="text-base font-bold text-white">1. Post Story Sticker</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            Generate your NGL/TBH styled sticker card and attach your link to your Instagram, Snapchat, or TikTok story.
          </p>
        </div>

        <div className="glass-panel p-6 rounded-2xl space-y-3 glass-card-hover border-indigo-500/30">
          <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400">
            <Send className="w-5 h-5" />
          </div>
          <h3 className="text-base font-bold text-white">2. Receive TBH Vibes</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            Followers pick from hype, low-key, wholesome, or confession templates—or write their own completely anonymously.
          </p>
        </div>

        <div className="glass-panel p-6 rounded-2xl space-y-3 glass-card-hover">
          <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <h3 className="text-base font-bold text-white">3. Zero Tracker Guarantee</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            Protected by Cloudflare D1 and Turnstile. No sketchy paywalls to reveal identities, no ad profiling, pure privacy.
          </p>
        </div>
      </div>

      {/* Open Source & Transparency Banner */}
      <div className="glass-panel p-8 rounded-2xl border-white/10 flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="space-y-2 text-center md:text-left">
          <div className="flex items-center justify-center md:justify-start space-x-2 text-indigo-400 text-xs font-semibold uppercase tracking-wider">
            <Github className="w-4 h-4" />
            <span>Open Source & Transparent</span>
          </div>
          <h3 className="text-xl font-bold text-white">Built for Privacy, Not for Profit</h3>
          <p className="text-xs sm:text-sm text-slate-400 max-w-xl">
            SecretMsg is an open-source personal project created by janasco. No hidden trackers, no ad networks, no data selling. Hosted securely on Cloudflare Edge.
          </p>
        </div>
        <div className="flex items-center space-x-3 shrink-0">
          <a
            href="https://github.com/janasco"
            target="_blank"
            rel="noopener noreferrer"
            className="py-2.5 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors flex items-center space-x-2"
          >
            <Github className="w-4 h-4" />
            <span>View on GitHub</span>
          </a>
        </div>
      </div>

      {/* Footer */}
      <footer className="pt-12 border-t border-white/10 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-4">
        <div className="flex items-center space-x-2">
          <span>© 2026 secretmsg.net</span>
          <span>•</span>
          <span>Personal Project by janasco</span>
        </div>
        <div className="flex flex-wrap items-center space-x-4">
          <Link to="/supporters" className="text-amber-400 hover:text-amber-300 font-medium transition-colors">Supporters Wall</Link>
          <Link to="/legal/terms" className="hover:text-slate-300 transition-colors">Terms of Service</Link>
          <Link to="/legal/privacy" className="hover:text-slate-300 transition-colors">Privacy Policy</Link>
          <Link to="/legal/disclaimer" className="hover:text-slate-300 transition-colors">Disclaimer</Link>
        </div>
      </footer>
    </div>
  );
};
