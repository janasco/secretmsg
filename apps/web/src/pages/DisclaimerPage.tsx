import React from 'react';
import { PublicPage } from '../components/PublicPage';

export const DisclaimerPage: React.FC = () => {
  return (
    <PublicPage
      title="Disclaimer & Limitation of Liability"
      description="Operational disclosures, warranty disclaimers, and user content limitations for SecretMsg."
    >
      <p className="text-xs text-slate-400 mb-6"><strong className="text-slate-300">Last Updated: September 2026</strong></p>

      <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-white/10 space-y-4 text-sm text-slate-300 leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">01</span> Non-Commercial Personal Project Status
          </h2>
          <div className="glass-panel p-4 rounded-2xl border border-white/10 space-y-2 text-xs text-slate-300">
            <p>
              <strong>SecretMsg is an independent, non-commercial open-source project</strong> engineered and maintained by the <strong className="text-white">SecretMsg Team</strong> for creative, social, and educational purposes.
            </p>
            <ul className="list-disc list-inside space-y-1 text-slate-400">
              <li>It is NOT an enterprise corporation, venture-backed conglomerate, or commercial publisher.</li>
              <li>All server hosting, database storage, and domain renewals are maintained through voluntary user contributions.</li>
            </ul>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">02</span> &ldquo;As-Is&rdquo; &amp; &ldquo;As-Available&rdquo; Warranty Exclusion
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs">
            THE SERVICE, CONTENT, AND UNDERLYING SOFTWARE ARE PROVIDED ON AN &ldquo;AS-IS&rdquo; BASIS WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, OR UNINTERRUPTED ERROR-FREE OPERATION. WE DO NOT GUARANTEE 100% CONTINUOUS SERVICE AVAILABILITY OR PREVENTION OF OCCASIONAL SERVICE INTERRUPTIONS.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">03</span> User-Generated Content &amp; Conduit Rule
          </h2>
          <p className="text-slate-400 leading-relaxed">
            SecretMsg functions solely as an automated technical conduit facilitating message transmission between consenting participants. SecretMsg does not pre-screen, verify, endorse, or assume responsibility for opinions, statements, or claims transmitted by anonymous message senders. Each user assumes full responsibility for messages they transmit.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">04</span> DMCA &amp; Copyright Takedown Procedure
          </h2>
          <p className="text-slate-400 leading-relaxed">
            If you believe material hosted on or accessible via SecretMsg infringes upon your copyright or intellectual property rights, submit a takedown request containing:
          </p>
          <ul className="list-disc list-inside space-y-1 pl-4 text-slate-400 text-xs border-l border-white/10">
            <li>Identification of the copyrighted work claimed to have been infringed.</li>
            <li>Specific URL or screenshot of the infringing material on SecretMsg.</li>
            <li>Your contact information (name, email address, physical address).</li>
            <li>A statement of good faith belief that the disputed use is unauthorized.</li>
          </ul>
          <div className="mt-2 text-xs">
            <span className="text-slate-400">Send DMCA notices to: </span>
            <a href="mailto:dmca@secretmsg.net" className="text-white font-semibold underline">dmca@secretmsg.net</a>
          </div>
        </section>
      </div>
    </PublicPage>
  );
};
