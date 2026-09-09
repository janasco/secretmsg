import React from 'react';
import { BadgeCheck } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

export const CookiesPage: React.FC = () => {
  return (
    <PublicPage
      title="Cookies & Local Storage Policy"
      description="SecretMsg is engineered without invasive trackers. We believe your online activity across other websites is none of our business."
    >
      <p className="text-xs text-slate-400 mb-6"><strong className="text-slate-300">Last Updated: September 2026</strong></p>

      <div className="glass-panel rounded-2xl p-5 border border-emerald-500/30 bg-emerald-950/20 mb-10 space-y-2 text-xs">
        <h3 className="font-bold text-sm text-emerald-300 flex items-center gap-1.5">
          <BadgeCheck className="w-5 h-5" />
          No Cookie Banners Needed — Here&apos;s Why
        </h3>
        <p className="text-slate-300 leading-relaxed">
          Under the EU ePrivacy Directive and GDPR guidelines, websites that utilize <strong>only strictly necessary, non-tracking cookies or local storage</strong> do not require intrusive, annoying consent banners. We only store the absolute minimum data required to keep the site functioning and defend against bots.
        </p>
      </div>

      <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-white/10 space-y-4 text-sm text-slate-300 leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">01</span> What Are Cookies and Local Storage?
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            Cookies are small text files placed on your device (computer, smartphone, or tablet) when you visit a website. They are commonly used to make websites work efficiently, remember your preferences, and maintain secure sessions. Local storage technologies (like HTML5 local storage) provide cookie-equivalent functionality directly within your browser, allowing fast, client-side persistence of your settings without transmitting unnecessary data on every network request.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">02</span> How We Use Cookies &amp; Local Storage
          </h2>
          <div className="space-y-3 text-xs sm:text-sm">
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <div className="flex justify-between items-center">
                <strong className="text-white text-sm">1. Preferences Storage</strong>
                <span className="text-[10px] px-2 py-0.5 rounded bg-white/10 text-slate-300 font-mono">LocalStorage</span>
              </div>
              <p className="text-slate-400">Stores whether you selected Dark Mode, Light Mode, or System Mode and your current active board identifier so the application renders in your preferred aesthetic and loads your link instantly without flickering.</p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <div className="flex justify-between items-center">
                <strong className="text-white text-sm">2. Human Verification Security Token</strong>
                <span className="text-[10px] px-2 py-0.5 rounded bg-white/10 text-slate-300 font-mono">Essential Security</span>
              </div>
              <p className="text-slate-400">Temporary security token used to verify that you are a real person and not an automated spam bot. Does not track your personal identity or activity across third-party websites.</p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <div className="flex justify-between items-center">
                <strong className="text-white text-sm">3. Authenticated Session Token</strong>
                <span className="text-[10px] px-2 py-0.5 rounded bg-white/10 text-slate-300 font-mono">Secure HttpOnly Cookie</span>
              </div>
              <p className="text-slate-400">Only present when you register and log into your board to access your private inbox. Kept encrypted, strictly restricted to secretmsg.net, and permanently discarded upon logout or account deletion.</p>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">03</span> What We NEVER Store or Use
          </h2>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 space-y-2 text-xs sm:text-sm text-slate-300">
            <p><strong>Zero Advertising Cookies:</strong> We do not partner with ad exchanges, data brokers, or retargeting networks.</p>
            <p><strong>Zero Cross-Site Tracking:</strong> We never fingerprint your hardware or monitor your browsing behavior outside of secretmsg.net.</p>
            <p><strong>Zero Commercial Analytics:</strong> No third-party marketing company receives session replay recordings or clickstream heatmaps.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">04</span> Your Choices &amp; Managing Browser Storage
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            You have full control over cookies and local storage. You can withdraw your consent, block, or clear cookies and site data at any time through your browser&apos;s settings (such as Chrome Settings &rarr; Privacy &amp; Security &rarr; Clear Browsing Data). Note that because we only use strictly necessary data, disabling all local storage may prevent you from remaining logged into your inbox or passing automated bot verification.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">05</span> GDPR &amp; International Compliance
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            This Cookie Policy complies with the General Data Protection Regulation (GDPR) and the EU ePrivacy Directive. Because we use strictly essential, non-tracking technologies for basic security and preferences, we do not require intrusive tracking consent banners while ensuring you have complete transparency and control. For questions, reach out to <a href="mailto:privacy@secretmsg.net" className="text-indigo-400 underline font-mono">privacy@secretmsg.net</a>.
          </p>
        </section>
      </div>
    </PublicPage>
  );
};
