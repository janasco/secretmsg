import React from 'react';
import { ShieldCheck, Flag, LifeBuoy, Heart } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

export const SafetyPage: React.FC = () => {
  return (
    <PublicPage
      title="Safety Center & Crisis Help"
      description="Your emotional well-being and psychological safety are paramount. Discover our proactive moderation tools, reporting procedures, and immediate 24/7 crisis hotlines."
    >
      <div className="glass-panel rounded-2xl p-5 border border-sky-500/30 bg-sky-950/20 mb-10 space-y-3">
        <div className="flex items-center gap-2 text-sky-300 font-bold text-sm">
          <LifeBuoy className="w-5 h-5" />
          Need to talk to someone right now? You are not alone.
        </div>
        <p className="text-xs text-slate-300 leading-relaxed">
          If you or someone you know is feeling overwhelmed, hopeless, or experiencing suicidal thoughts, free confidential support is available 24/7:
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 pt-2">
          <div className="bg-white/5 rounded-xl p-3 border border-white/10 flex flex-col justify-between">
            <span className="text-xs font-bold text-white">988 Lifeline (USA & Canada)</span>
            <span className="text-[11px] text-slate-400 mt-1">Call or text <strong className="text-sky-300">988</strong> free & confidential anytime.</span>
          </div>
          <div className="bg-white/5 rounded-xl p-3 border border-white/10 flex flex-col justify-between">
            <span className="text-xs font-bold text-white">Crisis Text Line</span>
            <span className="text-[11px] text-slate-400 mt-1">Text <strong className="text-sky-300">HOME to 741741</strong> to connect with a counselor.</span>
          </div>
          <div className="bg-white/5 rounded-xl p-3 border border-white/10 flex flex-col justify-between">
            <span className="text-xs font-bold text-white">The Trevor Project</span>
            <span className="text-[11px] text-slate-400 mt-1">LGBTQ+ youth crisis lifeline: Call <strong className="text-sky-300">1-866-488-7386</strong>.</span>
          </div>
        </div>
      </div>

      <div className="space-y-8 border-t border-white/10 pt-8 text-sm">
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-emerald-400" />
            Our Built-In Protective Safeguards
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1 text-xs hover:border-emerald-500/40 transition-colors">
              <span className="font-bold text-white block">Automated Spam & Bot Filter</span>
              <span className="text-slate-400">Automated protection prevents spam attacks and bot flooding without intrusive tracking.</span>
            </div>
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1 text-xs hover:border-emerald-500/40 transition-colors">
              <span className="font-bold text-white block">One-Tap Message Reporting</span>
              <span className="text-slate-400">Every message in your inbox features an instant "Report" button that quarantines the message and logs abuse.</span>
            </div>
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1 text-xs hover:border-emerald-500/40 transition-colors">
              <span className="font-bold text-white block">Immediate Account Wipeout</span>
              <span className="text-slate-400">You have complete control to instantly wipe your entire account and all messages permanently at any second.</span>
            </div>
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1 text-xs hover:border-emerald-500/40 transition-colors">
              <span className="font-bold text-white block">Proactive Abuse Throttling</span>
              <span className="text-slate-400">Automated rate-limiting prevents harassment campaigns by locking out abusive senders.</span>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <Heart className="w-5 h-5 text-amber-400" />
            Advice for Teens & Parents
          </h2>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 space-y-2 text-xs text-slate-300 leading-relaxed">
            <p><strong className="text-white">Remember that feedback does not define you:</strong> Anonymous messages reflect the sender's thoughts, not your worth. If a message ever feels uncomfortable, delete or report it immediately.</p>
            <p><strong className="text-white">Never share sensitive personal info:</strong> Never post your home address, phone number, school location, or private credentials in your public link or reply stickers.</p>
            <p><strong className="text-white">Take breaks when needed:</strong> If social media or feedback starts feeling stressful, pause or delete your link. You have 100% control.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <Flag className="w-5 h-5 text-rose-400" />
            Urgent Abuse Assistance
          </h2>
          <p className="text-slate-400 text-xs leading-relaxed">
            If you encounter cyberbullying or illegal activity, report it directly to our moderation queue:
          </p>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
            <div>
              <span className="font-bold text-white block">Direct Abuse Escalation</span>
              <span className="text-slate-400 font-mono">abuse@secretmsg.net</span>
            </div>
            <a href="mailto:abuse@secretmsg.net" className="px-4 py-2 bg-rose-500 text-white font-semibold rounded-full hover:bg-rose-600 transition-colors text-center shrink-0">
              Contact Support
            </a>
          </div>
        </section>
      </div>
    </PublicPage>
  );
};
