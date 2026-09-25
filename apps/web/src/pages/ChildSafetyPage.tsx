import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { PublicPage } from '@/components/PublicPage';

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
          CSAE Reporting and Required Escalation
        </h3>
        <p className="text-slate-300 leading-relaxed">
          SecretMsg prohibits Child Sexual Abuse Material (CSAM) and child sexual exploitation or abuse (CSAE). A child, parent, guardian, or any other person may report CSAE directly to the <strong>National Center for Missing &amp; Exploited Children (NCMEC) CyberTipline</strong>. When SecretMsg obtains actual knowledge of CSAE, it will preserve relevant records and refer the matter to NCMEC and other competent authorities as required by law. The current service does not automatically detect CSAE or automatically submit reports, and SecretMsg does not claim a staffed 24-hour review team.
        </p>
      </div>

      <article className="space-y-10 text-slate-300 text-sm leading-relaxed border-t border-white/10 pt-8">
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">01</span> Our Commitment
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            SecretMsg is committed to protecting children and minors from exploitation, abuse, and harmful content. We strictly prohibit any use of the service to endanger, exploit, or abuse a minor. SecretMsg is not directed to children under 13. Users aged 13–17 may use the service only with parent or legal-guardian permission and in compliance with applicable law. The current application does not use an automated age-assurance or age-classification system, so users and guardians must comply with this requirement.
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
            <li><strong>Child Sexual Abuse Material (CSAM):</strong> Any content that sexually exploits or depicts a minor, including CSAM in any form.</li>
            <li><strong>Grooming &amp; Predatory Behavior:</strong> Any content that facilitates, encourages, or promotes child grooming, trafficking, sextortion, or another form of child exploitation or abuse.</li>
            <li><strong>Sexualization of Minors:</strong> Any content that sexualizes, demeans, exploits, or targets a minor.</li>
            <li><strong>Offline Contact:</strong> Any use of SecretMsg to facilitate harmful or exploitative offline contact with a minor.</li>
          </ul>
          <p className="text-slate-400 text-xs leading-relaxed mt-2">
            These prohibitions apply to all users regardless of age. Depending on the evidence and applicable law, violations may result in message removal, account restriction or termination, a recipient-specific sender block, preservation of relevant records, and referral to NCMEC or law enforcement. Reporting through the in-app control quarantines a message and records a report; it does not automatically reveal, globally block, or terminate the anonymous sender.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">03</span> Platform Design Protections
          </h2>
          <div className="space-y-3 text-xs sm:text-sm text-slate-400">
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">1. Text-Only Message API</strong>
              <p className="text-slate-300 leading-relaxed text-xs">
                The message API accepts text only. Anonymous senders cannot attach photos, videos, audio, or other media through SecretMsg. This reduces media-based child-exploitation pathways but does not make harmful text safe.
              </p>
            </div>
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">2. Actual Automated Safeguards</strong>
              <p className="text-slate-300 leading-relaxed text-xs">
                Message submission and abuse reporting use Cloudflare Turnstile, and recipients can configure hidden-word filters. In the standard setting, a matching message is quarantined for recipient review; in strict mode, it is rejected and quarantined. These are deterministic word checks, not automated machine-learning content classification. They do not understand context and cannot identify every instance of CSAE, grooming, self-harm, or other abuse.
              </p>
            </div>
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">3. Recipient Reporting and Blocking</strong>
              <p className="text-slate-300 leading-relaxed text-xs">
                A recipient can report a message, provide a reason, complete Turnstile verification, and review the report status. The report moves the message to quarantine. Blocking is a separate action that stores the message&apos;s app-generated sender-fingerprint hash in that recipient&apos;s block list and removes the message; it does not expose the sender&apos;s identity or create a network-wide IP block.
              </p>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">04</span> Reporting by a Child, Parent, or Guardian
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              Anyone may report a child-safety concern without using an account by emailing <a href="mailto:safety@secretmsg.net" className="text-rose-400 underline font-mono">safety@secretmsg.net</a> or <a href="mailto:abuse@secretmsg.net" className="text-rose-400 underline font-mono">abuse@secretmsg.net</a>. Please identify the SecretMsg link, relevant message ID or description, the nature of the concern, and a safe way to contact you. Do not send unnecessary information about a child. A recipient can also use the report control in the inbox. This policy is published at <strong className="text-white">secretmsg.net/p/child-safety-policy</strong>.
            </p>
            <ul className="list-disc list-inside space-y-1 text-slate-300 pl-2 text-xs sm:text-sm">
              <li>An in-app report stores the report reason and pending/resolved status and quarantines the message for review.</li>
              <li>Email reports provide a channel for concerns not attached to a recipient&apos;s inbox and for context from a parent or guardian.</li>
              <li>SecretMsg does not promise a staffed 24-hour response channel or immediate human review. If anyone may be in immediate danger, contact local emergency services first.</li>
            </ul>
            <p className="text-slate-400 text-xs leading-relaxed mt-2">
              Reports may be submitted even when the reporter is uncertain whether conduct meets a formal policy violation. Do not confront or meet a suspected offender; preserve relevant information and use the appropriate emergency, child-protection, or law-enforcement channel.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">05</span> CSAE Escalation Path
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              SecretMsg does not claim that its Turnstile or hidden-word filter detects CSAE. If a child, parent, guardian, or reporter identifies possible CSAM, report it directly to the <strong>National Center for Missing and Exploited Children (NCMEC) CyberTipline</strong> at <a href="https://report.cybertip.org" target="_blank" rel="noopener noreferrer" className="text-rose-400 underline">report.cybertip.org</a>, and also notify SecretMsg at <a href="mailto:safety@secretmsg.net" className="text-rose-400 underline font-mono">safety@secretmsg.net</a>. Where required, report to relevant state, federal, or international law-enforcement authorities.
            </p>
            <ul className="list-disc list-inside space-y-1.5 text-slate-300 pl-2 text-xs sm:text-sm">
              <li><strong>Immediate danger:</strong> Contact local emergency services. Notify SecretMsg when it is safe to do so.</li>
              <li><strong>Possible CSAE or CSAM:</strong> Use the NCMEC CyberTipline and notify the SecretMsg safety contact.</li>
              <li><strong>Other illegal or harmful conduct:</strong> Email the SecretMsg safety contact and, where appropriate, law enforcement.</li>
              <li><strong>SecretMsg escalation:</strong> When SecretMsg obtains actual knowledge of CSAE, it will preserve relevant records and refer the matter to NCMEC and other competent authorities as required by law.</li>
            </ul>
            <p className="text-slate-400 text-xs leading-relaxed mt-2">Neither an in-app report nor an email report is automatically classified or automatically submitted to an authority by the current application.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">06</span> Child Safety Point of Contact
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            The following channels are designated for child-safety reports, application-store or child-protection organization inquiries, and coordination with legal authorities:
          </p>
          <div className="glass-panel p-5 rounded-2xl border border-white/10 text-xs space-y-1">
            <strong className="text-white block font-semibold">SecretMsg Child Safety and Legal Contacts</strong>
            <span className="text-slate-300 block">Child safety, CSAE concerns, preservation, and escalation inquiries</span>
            <span className="text-slate-400 font-mono block">safety@secretmsg.net • abuse@secretmsg.net • legal@secretmsg.net</span>
            <p className="text-slate-400 text-[11px] pt-1">Do not include unnecessary child information. For possible CSAM, use the NCMEC CyberTipline directly as described above.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">07</span> Applicable Child-Protection Commitments
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            SecretMsg applies the following child-protection commitments to the extent required by applicable law, including:
          </p>
          <ul className="list-disc list-inside space-y-1 pl-2 text-slate-300 text-xs sm:text-sm">
            <li><strong>COPPA:</strong> Applicable obligations concerning online collection and use of children&apos;s personal information.</li>
            <li><strong>18 U.S.C. § 2258A:</strong> Applicable duties concerning reports of child sexual abuse material to NCMEC.</li>
            <li><strong>Regional law:</strong> Applicable child-protection, privacy, preservation, and emergency-disclosure requirements.</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">08</span> Contact Us &amp; Reporting Concerns
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm">
            A child, parent, guardian, or other concerned person may report a possible CSAE concern to SecretMsg at <a href="mailto:safety@secretmsg.net" className="text-rose-400 underline font-mono">safety@secretmsg.net</a> without creating an account. For possible CSAM, report directly to <a href="https://report.cybertip.org" target="_blank" rel="noopener noreferrer" className="text-rose-400 underline">NCMEC CyberTipline</a>. This published policy is available at <strong className="text-white">secretmsg.net/p/child-safety-policy</strong>.
          </p>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs mt-3">
            <div>
              <span className="font-bold text-white block">SecretMsg Child Safety Contact</span>
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
