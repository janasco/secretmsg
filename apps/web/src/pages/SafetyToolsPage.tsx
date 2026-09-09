import React from 'react';
import { ShieldCheck, Ban, EyeOff, Eye, Lock, Trash2, AlertTriangle, Fingerprint } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

export const SafetyToolsPage: React.FC = () => {
  return (
    <PublicPage
      title="Our Safety Tools & Controls"
      description="SecretMsg puts complete sovereignty over your inbox directly into your hands. Every account holder has access to real-time proactive safety controls designed to prevent abuse, enforce digital boundaries, and filter unwanted language down to specific emojis."
    >
      <div className="space-y-8 mb-14">
        <div className="glass-panel rounded-3xl p-6 sm:p-8 border border-white/10 space-y-5 relative overflow-hidden">
          <div className="flex items-start justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-2xl bg-amber-500/20 text-amber-400 flex items-center justify-center shrink-0">
                <AlertTriangle className="w-7 h-7" />
              </div>
              <div>
                <span className="text-xs font-bold uppercase tracking-wider text-amber-400">Boundary Setting</span>
                <h2 className="text-xl sm:text-2xl font-bold text-white">Pause Submissions (Quiet Mode)</h2>
              </div>
            </div>
            <span className="hidden sm:inline-flex items-center gap-1 text-xs font-semibold px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-300">
              <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse"></span>
              Live Control
            </span>
          </div>

          <p className="text-slate-300 text-base leading-relaxed">
            If you ever feel overwhelmed, need to study, or want to take a break from social media, you can freeze your SecretMsg link instantly. When your link is paused, no one can send you messages.
          </p>

          <div className="space-y-2">
            <label className="text-xs font-bold uppercase tracking-wider text-slate-400">Preset Pause Durations</label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
              <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center hover:border-amber-400/50 transition-colors">
                <span className="block text-sm font-bold text-white">1 Hour</span>
                <span className="text-[11px] text-slate-400">Quick Break</span>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center hover:border-amber-400/50 transition-colors">
                <span className="block text-sm font-bold text-white">6 Hours</span>
                <span className="text-[11px] text-slate-400">Study / Work</span>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center hover:border-amber-400/50 transition-colors">
                <span className="block text-sm font-bold text-white">24 Hours</span>
                <span className="text-[11px] text-slate-400">Full Detox</span>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center hover:border-amber-400/50 transition-colors">
                <span className="block text-sm font-bold text-white">Permanent</span>
                <span className="text-[11px] text-slate-400">Until Resumed</span>
              </div>
            </div>
          </div>

          <div className="bg-[#10131A] rounded-2xl p-4 border border-white/10 space-y-2">
            <span className="text-[11px] font-mono uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
              <Eye className="w-4 h-4 text-amber-400" />
              What Senders See When Your Board Is Paused
            </span>
            <div className="p-3.5 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center gap-3">
              <Lock className="w-6 h-6 text-amber-400" />
              <div className="text-xs sm:text-sm text-slate-300">
                <strong className="text-white block font-semibold">This Board Is Currently Paused</strong>
                The creator is taking a digital break. Submissions are temporarily paused and will resume automatically.
              </div>
            </div>
          </div>

          <div className="text-xs text-slate-400 pt-1">
            <span>Configurable in: <strong>Settings &rarr; Safety Controls &rarr; Pause Submissions</strong></span>
          </div>
        </div>

        <div className="glass-panel rounded-3xl p-6 sm:p-8 border border-white/10 space-y-5 relative overflow-hidden">
          <div className="flex items-start justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-2xl bg-purple-500/20 text-purple-400 flex items-center justify-center shrink-0">
                <EyeOff className="w-7 h-7" />
              </div>
              <div>
                <span className="text-xs font-bold uppercase tracking-wider text-purple-400">Content Moderation</span>
                <h2 className="text-xl sm:text-2xl font-bold text-white">Filtered Words, Phrases &amp; Emojis</h2>
              </div>
            </div>
            <span className="hidden sm:inline-flex items-center gap-1 text-xs font-semibold px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-300">
              Real-time Blocklist
            </span>
          </div>

          <p className="text-slate-300 text-base leading-relaxed">
            Create a personalized blocklist tailored to your personal boundaries. SecretMsg gives you granular control down to specific keywords, traumatic themes, negative slang, or even specific emojis.
          </p>

          <div className="space-y-2">
            <label className="text-xs font-bold uppercase tracking-wider text-slate-400">Example Blocklist Filters</label>
            <div className="flex flex-wrap gap-2">
              <span className="px-3 py-1.5 rounded-full bg-purple-500/15 border border-purple-500/30 text-purple-200 text-xs font-medium flex items-center gap-1.5">
                <span>&#x1F40D; snake</span>
                <Lock className="w-3.5 h-3.5 text-purple-400" />
              </span>
              <span className="px-3 py-1.5 rounded-full bg-purple-500/15 border border-purple-500/30 text-purple-200 text-xs font-medium flex items-center gap-1.5">
                <span>&#x1F921; clown</span>
                <Lock className="w-3.5 h-3.5 text-purple-400" />
              </span>
              <span className="px-3 py-1.5 rounded-full bg-purple-500/15 border border-purple-500/30 text-purple-200 text-xs font-medium flex items-center gap-1.5">
                <span>ugly</span>
                <Lock className="w-3.5 h-3.5 text-purple-400" />
              </span>
              <span className="px-3 py-1.5 rounded-full bg-purple-500/15 border border-purple-500/30 text-purple-200 text-xs font-medium flex items-center gap-1.5">
                <span>hate</span>
                <Lock className="w-3.5 h-3.5 text-purple-400" />
              </span>
              <span className="px-3 py-1.5 rounded-full bg-purple-500/15 border border-purple-500/30 text-purple-200 text-xs font-medium flex items-center gap-1.5">
                <span>spoilers</span>
                <Lock className="w-3.5 h-3.5 text-purple-400" />
              </span>
              <span className="px-3 py-1.5 rounded-full bg-white/5 border border-dashed border-white/20 text-slate-400 text-xs font-medium flex items-center gap-1">
                <span className="text-sm leading-none">+</span> Add any word or emoji
              </span>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs sm:text-sm">
            <div className="p-4 rounded-xl bg-white/5 border border-white/10 space-y-1.5">
              <span className="text-purple-400 font-bold flex items-center gap-1">
                <ShieldCheck className="w-4 h-4" />
                Shield 1: Compose Prevention
              </span>
              <p className="text-slate-300 text-xs leading-relaxed">
                If a sender attempts to submit a message containing any word from your list, the form blocks submission immediately with a friendly warning.
              </p>
            </div>
            <div className="p-4 rounded-xl bg-white/5 border border-white/10 space-y-1.5">
              <span className="text-purple-400 font-bold flex items-center gap-1">
                <Fingerprint className="w-4 h-4" />
                Shield 2: Inbox Quarantine
              </span>
              <p className="text-slate-300 text-xs leading-relaxed">
                Any borderline messages are routed to a separate Quarantine folder so they never appear in your main feed unless you choose to review them.
              </p>
            </div>
          </div>

          <div className="text-xs text-slate-400 pt-1">
            <span>Configurable in: <strong>Settings &rarr; Safety Controls &rarr; Filtered Words</strong></span>
          </div>
        </div>

        <div className="glass-panel rounded-3xl p-6 sm:p-8 border border-white/10 space-y-5 relative overflow-hidden">
          <div className="flex items-start justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-2xl bg-rose-500/20 text-rose-400 flex items-center justify-center shrink-0">
                <Ban className="w-7 h-7" />
              </div>
              <div>
                <span className="text-xs font-bold uppercase tracking-wider text-rose-400">Harassment Defense</span>
                <h2 className="text-xl sm:text-2xl font-bold text-white">Device-Level Sender Blocking</h2>
              </div>
            </div>
            <span className="hidden sm:inline-flex items-center gap-1 text-xs font-semibold px-3 py-1 rounded-full bg-rose-500/10 border border-rose-500/20 text-rose-300">
              Cryptographic Ban
            </span>
          </div>

          <p className="text-slate-300 text-base leading-relaxed">
            If someone sends you a message that violates your boundaries, you don't need to know who they are in real life to prevent them from ever contacting you again.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
            <div className="p-3.5 rounded-xl bg-white/5 border border-white/10 space-y-1">
              <span className="text-rose-400 font-bold block">Step 1: Tap Report / Block</span>
              <p className="text-slate-300 leading-relaxed">
                On any message detail card, tap <strong>Report / Block</strong> with a single tap.
              </p>
            </div>
            <div className="p-3.5 rounded-xl bg-white/5 border border-white/10 space-y-1">
              <span className="text-rose-400 font-bold block">Step 2: Instant Lockout</span>
              <p className="text-slate-300 leading-relaxed">
                The sender's unique device signature is added to your personal blocklist automatically.
              </p>
            </div>
            <div className="p-3.5 rounded-xl bg-white/5 border border-white/10 space-y-1">
              <span className="text-rose-400 font-bold block">Step 3: Manage in Settings</span>
              <p className="text-slate-300 leading-relaxed">
                Review blocked devices in Settings anytime with complete 1-tap unblock freedom.
              </p>
            </div>
          </div>

          <div className="text-xs text-slate-400 pt-1">
            <span>Configurable in: <strong>Settings &rarr; Safety Controls &rarr; Blocked Users</strong></span>
          </div>
        </div>
      </div>

      <article className="space-y-8 text-slate-300 text-base leading-relaxed border-t border-white/10 pt-10">
        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white">
            What, Who &amp; When: Complete Recipient Sovereignty
          </h2>
          <p className="text-slate-300 leading-relaxed">
            Together, these tools ensure that you—and only you—control the experience on your link:
          </p>
          <ul className="list-disc list-inside space-y-2 text-slate-300 pl-2">
            <li><strong>What you receive:</strong> Custom Filtered Words and AI moderation filters intercept offensive messages before you ever see them.</li>
            <li><strong>Who can participate:</strong> Device-level blocking locks out malicious or harassing senders permanently.</li>
            <li><strong>When your board is open:</strong> Pause your link on a schedule (1h, 6h, 24h) or indefinitely whenever you need peace of mind.</li>
          </ul>
        </section>

        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white">
            Instant Action &amp; Data Erasure Controls
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2">
              <strong className="text-white block font-bold text-base flex items-center gap-2">
                <Trash2 className="w-5 h-5 text-rose-400" />
                1-Tap Inbox Clean Slate
              </strong>
              <p className="text-slate-300 text-sm leading-relaxed">
                Start completely fresh anytime. With a single confirmation in Settings, permanently purge all stored messages from your inbox with zero residual server logs.
              </p>
            </div>
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2">
              <strong className="text-white block font-bold text-base flex items-center gap-2">
                <Trash2 className="w-5 h-5 text-purple-400" />
                Permanent Account Wipeout
              </strong>
              <p className="text-slate-300 text-sm leading-relaxed">
                Complete self-service deletion. Deleting your account deletes your username handle, stored questions, replies, and settings forever with immediate SQL cascading erase.
              </p>
            </div>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white">
            Human Support &amp; 24/7 Crisis Assistance
          </h2>
          <p className="text-slate-300 leading-relaxed">
            Technology works hand-in-hand with human care. If you ever experience harassment, threats, or emotional distress, we offer rapid response channels and direct integration with 24/7 crisis lifelines.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-3">
            <div className="bg-white/5 rounded-2xl p-5 border border-white/10 space-y-2">
              <span className="text-xs font-bold uppercase tracking-wider text-sky-400">Direct Human Escalation</span>
              <h4 className="text-base font-bold text-white">Trust &amp; Safety Team</h4>
              <p className="text-slate-300 text-sm leading-relaxed">
                Contact us directly with reports or inquiries:
              </p>
              <div className="text-xs font-mono text-slate-300 pt-1">
                safety@secretmsg.net &bull; abuse@secretmsg.net
              </div>
              <a href="mailto:safety@secretmsg.net" className="inline-block mt-2 px-4 py-2 bg-sky-600 text-white font-semibold rounded-full hover:bg-sky-500 transition-colors text-xs text-center">
                Email Safety Team
              </a>
            </div>

            <div className="bg-white/5 rounded-2xl p-5 border border-white/10 space-y-2">
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-400">Immediate 24/7 Support</span>
              <h4 className="text-base font-bold text-white">Crisis &amp; Mental Health Hotlines</h4>
              <p className="text-slate-300 text-sm leading-relaxed">
                Free, confidential, and available 24 hours a day, 7 days a week:
              </p>
              <div className="text-xs text-slate-300 space-y-1 pt-1">
                <div><strong>US &amp; Canada:</strong> Call or text <strong>988</strong></div>
                <div><strong>Crisis Text Line:</strong> Text <strong>HOME to 741741</strong></div>
                <div><strong>UK:</strong> Call <strong>111</strong> or text <strong>SHOUT to 85258</strong></div>
              </div>
              <a href="tel:988" className="inline-block mt-2 px-4 py-2 bg-emerald-600 text-white font-semibold rounded-full hover:bg-emerald-500 transition-colors text-xs text-center">
                Call 988 (US/CA)
              </a>
            </div>
          </div>
        </section>
      </article>
    </PublicPage>
  );
};
