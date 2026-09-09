import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

export const ChildSafetyPage: React.FC = () => {
  return (
    <PublicPage
      eyebrow="Zero Tolerance • Protecting Minors Online"
      title="Child Safety Policy"
      description="Effective Date: June 22, 2026 • Updated September 2026"
    >
      <div className="glass-panel rounded-2xl p-5 border border-rose-500/30 bg-rose-950/20 mb-10 space-y-2 text-xs">
        <h3 className="font-bold text-sm text-rose-300 flex items-center gap-1.5">
          <AlertTriangle className="w-5 h-5" />
          Mandatory Law Enforcement & NCMEC Escalation
        </h3>
        <p className="text-slate-300 leading-relaxed">
          Any attempt to transmit, solicit, promote, or store Child Sexual Abuse Material (CSAM) or engage in the exploitation of minors results in immediate account termination, network-wide blocks, and mandatory reporting to the <strong>National Center for Missing & Exploited Children (NCMEC)</strong> via the CyberTipline and relevant international law enforcement agencies pursuant to 18 U.S.C. § 2258A.
        </p>
      </div>

      <article className="space-y-10 text-slate-300 text-sm leading-relaxed border-t border-white/10 pt-8">
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">01</span> Our Commitment
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            SecretMsg is committed to the safety of all users, and particularly to protecting children and minors from exploitation, abuse, and harmful content. We strictly prohibit any use of our platform to endanger, exploit, or abuse minors in any way.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">02</span> Prohibited Content and Conduct
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm">
            SecretMsg strictly prohibits the following on its platform without exception:
          </p>
          <ul className="list-disc list-inside space-y-2 text-xs sm:text-sm text-slate-300 pl-2">
            <li><strong>Child Sexual Abuse Material (CSAM):</strong> Any content that sexually exploits or abuses minors, including CSAM in any form.</li>
            <li><strong>Grooming & Predatory Behavior:</strong> Any content that facilitates, encourages, or promotes child grooming, predatory behavior, trafficking, sextortion, or any other form of child exploitation or abuse.</li>
            <li><strong>Sexualization of Minors:</strong> Any content that sexualizes, demeans, or targets minors.</li>
            <li><strong>Offline Meeting Facilitation:</strong> Any use of SecretMsg to facilitate offline contact with a minor for exploitative or abusive purposes.</li>
          </ul>
          <p className="text-slate-400 text-xs leading-relaxed mt-2">
            These prohibitions apply to all users regardless of age. Violations result in immediate removal of the content, termination of the offending account, permanent IP and network blocking, and reporting to the appropriate authorities as required by law.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">03</span> Platform Design Protections
          </h2>
          <div className="space-y-3 text-xs sm:text-sm text-slate-400">
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">1. Text-Only Architecture (No Media Files)</strong>
              <p className="text-slate-300 leading-relaxed text-xs">
                SecretMsg does not permit anonymous senders to attach photos, videos, audio recordings, or any other media files through the platform. All messages sent to users are strictly text-only. This fundamental design choice deliberately eliminates image-based exploitation vectors and safeguards our community against unsolicited illicit media.
              </p>
            </div>
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">2. Pre-Delivery Automated Content Moderation</strong>
              <p className="text-slate-300 leading-relaxed text-xs">
                All messages submitted to SecretMsg links are scanned through automated content moderation safeguards prior to delivery. Messages identified as violating our policies — including any text referencing CSAM, sexual harassment, predatory grooming patterns, or self-harm encouragement — are quarantined and rejected before they can ever reach the recipient's inbox.
              </p>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">04</span> In-App Reporting Mechanism
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              Users can report any message they receive that they believe violates this Child Safety Policy or our Community Guidelines directly within their inbox with a single tap. When a message is reported:
            </p>
            <ul className="list-disc list-inside space-y-1 text-slate-300 pl-2 text-xs sm:text-sm">
              <li>The reported message is immediately and permanently removed from the user's account and inbox.</li>
              <li>The sender's anonymous session is flagged for automated moderation review and network throttling.</li>
              <li>Users or guardians requesting expedited manual review may email our specialized safety team directly at <a href="mailto:safety@secretmsg.net" className="text-rose-400 underline font-mono">safety@secretmsg.net</a>.</li>
            </ul>
            <p className="text-slate-400 text-xs leading-relaxed mt-2">
              We encourage all users — as well as parents and legal guardians of minor users — to report any content or conduct that causes concern, even if uncertain whether it rises to the level of a formal policy violation.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">05</span> How We Address CSAM & NCMEC Coordination
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              SecretMsg enforces comprehensive protocols to eradicate Child Sexual Abuse Material:
            </p>
            <ul className="list-disc list-inside space-y-1.5 text-slate-300 pl-2 text-xs sm:text-sm">
              <li><strong>Automated Scanning:</strong> All messages are automatically scanned prior to delivery. Flagged content containing or soliciting child abuse material is blocked and purged instantaneously.</li>
              <li><strong>Immediate Removal & Termination:</strong> Upon obtaining actual knowledge of CSAM or child exploitation on our platform — whether through automated detection, user reporting, or law enforcement notification — SecretMsg takes immediate action to permanently remove the content and terminate associated accounts.</li>
              <li><strong>Mandatory NCMEC CyberTipline Reporting:</strong> SecretMsg reports all confirmed instances of CSAM to the <strong>National Center for Missing and Exploited Children (NCMEC)</strong> via the CyberTipline at <a href="https://report.cybertip.org" target="_blank" rel="noopener noreferrer" className="text-rose-400 underline">report.cybertip.org</a>, as mandated by <strong>18 U.S.C. § 2258A</strong>, and cooperates fully with NCMEC, state/federal law enforcement, and international authorities.</li>
            </ul>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">06</span> Child Safety Point of Contact
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            SecretMsg has designated a dedicated Child Safety Point of Contact to receive notifications from platform partners, application stores, and child protection organizations regarding Child Sexual Abuse and Exploitation (CSAE) matters, and to coordinate with law enforcement:
          </p>
          <div className="glass-panel p-5 rounded-2xl border border-white/10 text-xs space-y-1">
            <strong className="text-white block font-semibold">Child Safety & Legal Operations Officer</strong>
            <span className="text-slate-300 block">SecretMsg Trust & Safety Operations</span>
            <span className="text-slate-400 font-mono block">safety@secretmsg.net • legal@secretmsg.net</span>
            <p className="text-slate-400 text-[11px] pt-1">
              This point of contact is authorized to speak to SecretMsg's enforcement and review procedures and take immediate remedial action.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">07</span> Compliance with Applicable Law
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            SecretMsg complies with all applicable child protection laws and regulations, including:
          </p>
          <ul className="list-disc list-inside space-y-1 pl-2 text-slate-300 text-xs sm:text-sm">
            <li><strong>COPPA:</strong> The Children's Online Privacy Protection Act.</li>
            <li><strong>18 U.S.C. § 2258A:</strong> Mandatory federal reporting of child sexual abuse material to NCMEC.</li>
            <li><strong>State & International Legislation:</strong> All applicable regional, federal, and international frameworks governing minor safety and digital privacy online.</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">08</span> Contact Us & Reporting Concerns
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm">
            If you have questions regarding this policy, wish to report an urgent minor safety concern, or need to connect directly with our child protection team:
          </p>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs mt-3">
            <div>
              <span className="font-bold text-white block">SecretMsg Child Safety & Trust Team</span>
              <span className="text-slate-400 font-mono">safety@secretmsg.net • abuse@secretmsg.net</span>
            </div>
            <a href="mailto:safety@secretmsg.net" className="px-4 py-2 bg-rose-500 text-white font-semibold rounded-full hover:bg-rose-600 transition-colors text-center shrink-0">
              Report Safety Concern
            </a>
          </div>
        </section>
      </article>
    </PublicPage>
  );
};
