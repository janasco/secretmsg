import React from 'react';
import { Link } from 'react-router-dom';
import { ShieldCheck, Ban, Flag, EyeOff, Sliders, Heart, AlertTriangle, Scale } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

export const OnlineSafetyGuidePage: React.FC = () => {
  return (
    <PublicPage
      title="Our Guide to Online Safety"
      description="SecretMsg is built for authentic, uplifting connections with friends. Here is our complete guide on keeping your anonymous Q&A fun, protecting your personal privacy, and our formal procedures for law enforcement information requests."
    >
      <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-white/10 space-y-4 text-sm text-slate-300 leading-relaxed mb-10">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
          <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
            <Ban className="w-5 h-5 text-rose-400" />
            <strong className="text-white block font-semibold">1-Tap Block &amp; Remove</strong>
            <p className="text-slate-400 text-[11px] leading-relaxed">Remove uncomfortable messages immediately and forbid the sender from contacting you again.</p>
          </div>
          <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
            <AlertTriangle className="w-5 h-5 text-amber-400" />
            <strong className="text-white block font-semibold">See Something, Say Something</strong>
            <p className="text-slate-400 text-[11px] leading-relaxed">Help friends by reporting abusive behavior directly to our 24/7 team at safety@secretmsg.net.</p>
          </div>
          <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
            <Scale className="w-5 h-5 text-sky-400" />
            <strong className="text-white block font-semibold">Law Enforcement Protocols</strong>
            <p className="text-slate-400 text-[11px] leading-relaxed">Formal compliance pathways for statutory preservation, emergency disclosure, and warrants.</p>
          </div>
        </div>
      </div>

      <article className="space-y-10 text-slate-300 text-sm leading-relaxed border-t border-white/10 pt-8">
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">
            Staying Safe on SecretMsg: We're Here for You
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            We created SecretMsg as a place where you can foster authentic connections with friends, ask questions, reply in public or private, and get to be your true self. But attacking, intimidating, or being unkind is never okay. Stopping abuse is a team effort.
          </p>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              <strong className="text-white">Keeping Users Safe:</strong> Keeping our community safe is our number one priority. Our automated pre-delivery moderation filters messages for toxicity before they reach inboxes. Additionally, our dedicated safety team is available 24/7 at <a href="mailto:safety@secretmsg.net" className="text-emerald-400 underline font-mono">safety@secretmsg.net</a> to investigate reports and combat harassment.
            </p>
            <p>
              <strong className="text-white">See Something, Say Something:</strong> If you see a friend receiving abusive comments or see inappropriate prompts, speak up! Report the abuse directly within the app or email our safety team right away. We review every situation and take swift remedial action.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">
            What to Do If a Message Makes You Uncomfortable
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            While we do our best to filter out negativity, an unexpected message may occasionally leave you feeling uneasy or threatened. If that happens, take these steps immediately:
          </p>
          <div className="space-y-3 pt-1 text-xs sm:text-sm">
            <div className="glass-panel p-4 rounded-xl border border-white/10 flex items-start gap-3">
              <Ban className="w-5 h-5 text-rose-400 shrink-0 mt-0.5" />
              <div className="space-y-1">
                <strong className="text-white block">1. Block the Sender &amp; Delete the Message</strong>
                <p className="text-slate-400 text-xs leading-relaxed">Tap the Report icon on the message card and select "Block Sender". The message is instantly expunged from your board, and the sender cannot submit messages to your link again.</p>
              </div>
            </div>
            <div className="glass-panel p-4 rounded-xl border border-white/10 flex items-start gap-3">
              <Flag className="w-5 h-5 text-indigo-400 shrink-0 mt-0.5" />
              <div className="space-y-1">
                <strong className="text-white block">2. Report the Message to Team SecretMsg</strong>
                <p className="text-slate-400 text-xs leading-relaxed">Reporting the card alerts our moderation team to evaluate the sender's session for platform-wide throttling or bans.</p>
              </div>
            </div>
            <div className="glass-panel p-4 rounded-xl border border-white/10 flex items-start gap-3">
              <Heart className="w-5 h-5 text-sky-400 shrink-0 mt-0.5" />
              <div className="space-y-1">
                <strong className="text-white block">3. Access Support &amp; Crisis Resources</strong>
                <p className="text-slate-400 text-xs leading-relaxed">Visit our <Link to="/resources" className="text-sky-400 underline">Resources</Link> page for free, confidential mental health and anti-bullying hotlines available 24/7.</p>
              </div>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">
            Practical Tips for Staying Safe &amp; Protecting Privacy
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold flex items-center gap-1.5">
                <EyeOff className="w-4 h-4 text-emerald-400" />
                Protect Personal Information
              </strong>
              <p className="text-slate-400 leading-relaxed">Never share your home address, phone number, school location, or private contact details in public prompt cards or replies.</p>
            </div>
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold flex items-center gap-1.5">
                <Sliders className="w-4 h-4 text-indigo-400" />
                Think Before You Share
              </strong>
              <p className="text-slate-400 leading-relaxed">Pause and consider whether you are comfortable with everyone seeing what you publish to social media or your public board.</p>
            </div>
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold flex items-center gap-1.5">
                <Heart className="w-4 h-4 text-amber-400" />
                Be Kind &amp; Respectful
              </strong>
              <p className="text-slate-400 leading-relaxed">Remember there is a real human being reading your message. Keep the energy fun, kind, and uplifting.</p>
            </div>
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold flex items-center gap-1.5">
                <ShieldCheck className="w-4 h-4 text-rose-400" />
                Use Settings &amp; Safety Controls
              </strong>
              <p className="text-slate-400 leading-relaxed">Use our Safety Controls in Settings to pause your link, set keyword filters, or execute a 1-tap complete account wipeout at any time.</p>
            </div>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white">
            SecretMsg Procedures for Law Enforcement &amp; Information Requests
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            The safety of our users and community is paramount. SecretMsg cooperates fully with law enforcement agencies in accordance with applicable laws, constitutional standards, and statutory due process.
          </p>

          <div className="space-y-3 text-xs sm:text-sm text-slate-400">
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">Reporting Witnessed Illegal Activity</strong>
              <p className="text-slate-300 text-xs leading-relaxed">
                If you witness or receive content on SecretMsg that constitutes illegal or criminal activity, report it via the in-app Report function and email our safety team immediately at <a href="mailto:safety@secretmsg.net" className="text-emerald-400 underline font-mono">safety@secretmsg.net</a>. Our team evaluates reports, contacts relevant authorities when necessary, bans offending actors, and secures records.
              </p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">Information Release Standards &amp; Search Warrant Requirement</strong>
              <p className="text-slate-300 text-xs leading-relaxed">
                SecretMsg maintains limited user content data and discloses such data pursuant to proper legal process in accordance with <strong>18 U.S.C. &sect; 2703(a)</strong> and <em>United States v. Warshak</em>, 631 F.3d 266 (6th Cir. 2010). In order to produce the contents of communications, SecretMsg requires a valid search warrant issued upon a finding of probable cause by a court of competent jurisdiction.
              </p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">Preservation Requests (18 U.S.C. &sect; 2703(f))</strong>
              <p className="text-slate-300 text-xs leading-relaxed">
                SecretMsg will honor official preservation requests submitted by law enforcement to <a href="mailto:lawenforcement@secretmsg.net" className="text-emerald-400 underline font-mono">lawenforcement@secretmsg.net</a>. In accordance with 18 U.S.C. &sect; 2703(f), we will preserve temporarily available stored records for an active account for a period of up to 180 days pending issuance of a formal court order or warrant.
              </p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">Emergency Disclosure Requests (18 U.S.C. &sect;&sect; 2702(b)(8) &amp; 2702(c)(4))</strong>
              <p className="text-slate-300 text-xs leading-relaxed">
                Pursuant to 18 U.S.C. &sect;&sect; 2702(b)(8) and 2702(c)(4), SecretMsg is permitted to disclose information voluntarily to federal, state, or local government authorities when we believe in good faith that an emergency involving imminent danger of death or serious physical injury to any person requires disclosure without delay.
              </p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">User Consent Disclosures (18 U.S.C. &sect; 2703(c)(1)(C))</strong>
              <p className="text-slate-300 text-xs leading-relaxed">
                In accordance with 18 U.S.C. &sect; 2703(c)(1)(C), SecretMsg may disclose records based on verified user consent obtained by law enforcement, provided that sufficient corroborating information verifies the person providing consent is the verified creator of the account.
              </p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">Requirements for Law Enforcement Communications</strong>
              <p className="text-slate-300 text-xs leading-relaxed mb-2">
                SecretMsg accepts out-of-state legal process (subpoenas, court orders, search warrants, and emergency requests) without requiring domestication. All requests submitted by law enforcement must meet the following criteria:
              </p>
              <ul className="list-disc list-inside space-y-1 text-slate-400 text-xs pl-2">
                <li>Transmitted from an official government email domain to <a href="mailto:lawenforcement@secretmsg.net" className="text-emerald-400 underline font-mono">lawenforcement@secretmsg.net</a>.</li>
                <li>Include the subject line: <code className="text-slate-200 font-mono text-[11px] bg-white/10 px-1.5 py-0.5 rounded">"Request by Law Enforcement"</code>.</li>
                <li>Contain the officer's full name, title, badge/serial number, agency, and direct contact details.</li>
                <li>Identify the specific SecretMsg link (<code className="text-slate-300 font-mono text-[11px]">secretmsg.net/[handle]</code>) and include relevant screenshots or dates.</li>
                <li>Be drafted in the English language.</li>
              </ul>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">
            Contact Safety &amp; Trust Operations
          </h2>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs mt-3">
            <div>
              <span className="font-bold text-white block">Dedicated Safety &amp; Law Enforcement Contacts</span>
              <span className="text-slate-400 font-mono">safety@secretmsg.net &bull; lawenforcement@secretmsg.net</span>
            </div>
            <a href="mailto:safety@secretmsg.net" className="px-4 py-2 bg-emerald-600 text-white font-semibold rounded-full hover:bg-emerald-500 transition-colors text-center shrink-0">
              Contact Safety Team
            </a>
          </div>
        </section>
      </article>
    </PublicPage>
  );
};
