import React from 'react';
import { Link } from 'react-router-dom';
import { Users, Repeat, ShieldCheck, Sliders, Reply, Lock, Dices } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

const valueColors = {
  real: { icon: 'bg-emerald-500/10 text-emerald-400' },
  kind: { icon: 'bg-rose-500/10 text-rose-400' },
  you: { icon: 'bg-purple-500/10 text-purple-400' },
};

export const AboutPage: React.FC = () => {
  return (
    <PublicPage
      title="Truth Without the Friction of Identity"
      description="When communication requires constant self-editing, important truths go unsaid. SecretMsg is built to remove the social barriers, hierarchy, and surveillance that keep people from being genuinely honest."
    >
      {/* Why we built */}
      <div className="glass-panel p-6 sm:p-8 rounded-3xl border border-white/10 mb-10 relative overflow-hidden">
        <div className="absolute -right-8 -bottom-8 w-40 h-40 bg-gradient-to-br from-purple-500/20 to-indigo-500/10 rounded-full blur-3xl pointer-events-none" />
        <h2 className="text-xl sm:text-2xl font-bold text-white mb-3 flex items-center gap-2">
          <Users className="w-6 h-6 text-purple-400" />
          Why We Built SecretMsg
        </h2>
        <div className="space-y-3 text-slate-300 text-sm leading-relaxed">
          <p className="text-white font-semibold">
            Modern digital tools turned communication into a performative stage. At <span className="text-purple-400">secretmsg.net</span>, we are giving people their authentic voice back.
          </p>
          <p>
            In typical social networks and workplace channels, every statement is permanently attached to your profile, weighed against social risk, or parsed by algorithms. The result is silent conformity: valuable workplace feedback goes withheld, heartfelt sentiments to old friends remain unsent, and sincere questions stay unasked.
          </p>
          <p>
            We created SecretMsg to prove that anonymous messaging can be a mature, high-trust utility rather than a reckless gimmick. By combining strict cryptographic privacy with recipient sovereignty and intelligent moderation, we enable purposeful honesty that strengthens human connection.
          </p>
        </div>
      </div>

      {/* Use cases */}
      <div className="space-y-6 mb-12">
        <div className="text-center sm:text-left">
          <span className="text-xs font-bold uppercase tracking-wider text-indigo-400 block mb-1">Purposeful Anonymity</span>
          <h2 className="text-2xl font-black text-white tracking-tight">Real-World Moments Where Candor Matters</h2>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2">
            <div className="w-10 h-10 rounded-xl bg-sky-500/10 text-sky-400 flex items-center justify-center">
              <Users className="w-5 h-5" />
            </div>
            <h3 className="text-base font-bold text-white">Workplace & Peer Candor</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Deliver constructive, honest feedback to teammates, founders, or mentors without navigating office politics or fearing career friction.
            </p>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2">
            <div className="w-10 h-10 rounded-xl bg-purple-500/10 text-purple-400 flex items-center justify-center">
              <Repeat className="w-5 h-5" />
            </div>
            <h3 className="text-base font-bold text-white">Low-Pressure Reconnections</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Reach out across time to someone you've drifted from or share a warm sentiment without the pressure or permanence of an official direct message.
            </p>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2">
            <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <Lock className="w-5 h-5" />
            </div>
            <h3 className="text-base font-bold text-white">True Privacy by Design</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Ask burning questions, express honest feelings, and speak openly with zero IP tracking, zero profile mining, and zero ad surveillance.
            </p>
          </div>
        </div>
      </div>

      {/* Architecture */}
      <div className="space-y-6 mb-12">
        <div className="text-center sm:text-left">
          <span className="text-xs font-bold uppercase tracking-wider text-indigo-400 block mb-1">Our Architecture</span>
          <h2 className="text-2xl font-black text-white tracking-tight">Engineering Trust into Every Message</h2>
        </div>

        <div className="glass-panel p-6 sm:p-7 rounded-2xl border border-white/10 space-y-3 text-sm text-slate-300 leading-relaxed">
          <p>
            Unlike legacy platforms that treat privacy as a marketing slogan or monetize conflict with fake notification paywalls, SecretMsg is engineered from the ground up around <strong>dignity, control, and verifiable safety</strong>.
          </p>
          <p>
            We believe communication should empower honest connections rather than compromise peace of mind. Every mechanism we design is built to protect the recipient's well-being while giving senders a secure, low-friction channel to share what is real.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 hover:border-purple-500/40 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-purple-500/10 text-purple-400 flex items-center justify-center">
              <Sliders className="w-5 h-5" />
            </div>
            <h3 className="text-base font-bold text-white">Recipient Sovereignty</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              You are always in total control of your inbox. Filter custom words, mute trolls, pause your link anytime, or wipe your data with one tap.
            </p>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 hover:border-indigo-500/40 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-indigo-500/10 text-indigo-400 flex items-center justify-center">
              <Reply className="w-5 h-5" />
            </div>
            <h3 className="text-base font-bold text-white">Double-Blind Replies</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Reply directly to an anonymous question without revealing who sent it. Keep the conversation going privately and organically.
            </p>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 hover:border-emerald-500/40 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <h3 className="text-base font-bold text-white">Zero Tracking & Privacy</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              No invasive advertising trackers, no cross-site profiling, and no selling your personal information. Clean, straightforward, and private.
            </p>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 hover:border-amber-500/40 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center">
              <Dices className="w-5 h-5" />
            </div>
            <h3 className="text-base font-bold text-white">Creative Roulette & Themes</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Explore 14,000+ curated prompts across friendship, vibes, dating, and hot takes, or roll the interactive 3D Dice Roulette when you need inspiration.
            </p>
          </div>
        </div>
      </div>

      {/* Values */}
      <div className="space-y-6 mb-12">
        <div className="text-center sm:text-left">
          <span className="text-xs font-bold uppercase tracking-wider text-purple-400 block mb-1">Our DNA</span>
          <h2 className="text-2xl font-black text-white tracking-tight">Our Grounding Values</h2>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 text-center sm:text-left">
            <div className={`w-10 h-10 rounded-xl ${valueColors.real.icon} flex items-center justify-center mx-auto sm:mx-0`}>
              <ShieldCheck className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-white text-base">Be REAL</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Share what's authentic. Sincerity builds trust. True connections start when people feel safe speaking honestly without judgment.
            </p>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 text-center sm:text-left">
            <div className={`w-10 h-10 rounded-xl ${valueColors.kind.icon} flex items-center justify-center mx-auto sm:mx-0`}>
              <Users className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-white text-base">Be KIND</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Lift each other up. Use your words to celebrate friends, offer warmth, and spread positivity. Bullying and harassment have zero place here.
            </p>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 text-center sm:text-left">
            <div className={`w-10 h-10 rounded-xl ${valueColors.you.icon} flex items-center justify-center mx-auto sm:mx-0`}>
              <Repeat className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-white text-base">Be YOU</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Authentic self-expression is a human right. Show up as your true self and encourage the same in the people around you.
            </p>
          </div>
        </div>
      </div>

      <div className="text-center">
        <Link
          to="/"
          className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white text-dark-900 font-bold text-sm hover:bg-slate-100 transition-colors shadow-lg"
        >
          Get your own anonymous board
        </Link>
        <p className="text-slate-500 text-xs mt-4">© 2026 SecretMsg. Deepening authentic connections, safely.</p>
      </div>
    </PublicPage>
  );
};