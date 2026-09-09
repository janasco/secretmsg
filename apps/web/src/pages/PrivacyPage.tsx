import React from 'react';
import { Eye, Ban, Minus, ShieldCheck } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

export const PrivacyPage: React.FC = () => {
  return (
    <PublicPage
      title="Privacy Policy"
      description="At SecretMsg, privacy is not an afterthought or marketing slogan—it is the foundational design constraint of our entire architecture."
    >
      <p className="text-xs text-slate-400 mb-6"><strong className="text-slate-300">Last Updated: September 2026</strong></p>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-10">
        <div className="glass-panel rounded-2xl p-4 flex flex-col gap-2 border border-white/10">
          <Eye className="w-6 h-6 text-emerald-400" />
          <h3 className="font-bold text-sm text-white">No Sender Identity</h3>
          <p className="text-xs text-slate-400 leading-relaxed">When sending an anonymous message, zero personal identifiers or accounts are tied to your text.</p>
        </div>
        <div className="glass-panel rounded-2xl p-4 flex flex-col gap-2 border border-white/10">
          <Ban className="w-6 h-6 text-sky-400" />
          <h3 className="font-bold text-sm text-white">Zero Data Brokers</h3>
          <p className="text-xs text-slate-400 leading-relaxed">We never sell, trade, or monetize user data. No Facebook or Google tracking pixels exist on our platform.</p>
        </div>
        <div className="glass-panel rounded-2xl p-4 flex flex-col gap-2 border border-white/10">
          <Minus className="w-6 h-6 text-rose-400" />
          <h3 className="font-bold text-sm text-white">1-Tap Total Erasure</h3>
          <p className="text-xs text-slate-400 leading-relaxed">Account deletion permanently wipes out your email, handle, and every single message in the database instantly.</p>
        </div>
      </div>

      <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-white/10 space-y-4 text-sm text-slate-300 leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">01</span> The Basics: How SecretMsg Works
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            SecretMsg allows users to receive questions and messages through social media and direct links:
          </p>
          <ul className="list-disc list-inside space-y-2 text-xs sm:text-sm text-slate-400 pl-2">
            <li><strong className="text-slate-200">Account Users:</strong> Users create a personalized link (such as <code className="text-slate-200 font-mono text-xs">secretmsg.net/yourname</code>) and share it on Instagram Stories, WhatsApp, TikTok, X, or other channels to invite questions from anyone who has access to the link.</li>
            <li><strong className="text-slate-200">Message Senders:</strong> When a person clicks the link, they visit a page where they can submit an anonymous message or question directly to the Account User without creating an account or logging in.</li>
            <li><strong className="text-slate-200">Public or Private Replies:</strong> The Account User has the choice to publish their answers publicly (to their board, threads, or social media stories) or reply privately to the sender via a secure one-time link.</li>
            <li><strong className="text-slate-200">Sender Anonymity:</strong> SecretMsg does not store the name or social media handles of the Message Sender and cannot reveal this identity to the Account User or anyone else.</li>
            <li><strong className="text-slate-200">Optional Sender Clues:</strong> If permitted by the sender, SecretMsg may share high-level non-identifying hints (such as broad device type or approximate geographic region) with the Account User.</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">02</span> Personal Information We Collect
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            We collect information depending on how you interact with our platform:
          </p>
          <div className="space-y-3 pl-4 border-l border-white/10 text-xs sm:text-sm">
            <div>
              <h3 className="font-semibold text-white">A. Information You Provide to Us</h3>
              <ul className="list-disc list-inside space-y-1.5 text-slate-400 mt-1">
                <li><strong className="text-slate-200">Account Information:</strong> When you register a board, you provide a username/slug, display name, and password or email address used strictly to authenticate your login.</li>
                <li><strong className="text-slate-200">Questions &amp; Messages:</strong> Text and prompt answers submitted to Account Users through our composer.</li>
                <li><strong className="text-slate-200">Feedback &amp; Support Correspondence:</strong> Information you submit when contacting our support or trust &amp; safety team.</li>
              </ul>
            </div>
            <div>
              <h3 className="font-semibold text-white">B. Automatically Collected Information</h3>
              <ul className="list-disc list-inside space-y-1.5 text-slate-400 mt-1">
                <li><strong className="text-slate-200">Device &amp; Connection Data:</strong> Operating system, browser type, general location (such as city or region for non-identifying sender hints if enabled), and security verification tokens.</li>
                <li><strong className="text-slate-200">Local Storage Technologies:</strong> We use modern browser local storage (HTML5) to remember your preferences (such as Dark or Light theme mode, local drafts, and active board credentials) directly on your device.</li>
              </ul>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">03</span> What We Will NEVER Do
          </h2>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 space-y-2 text-xs sm:text-sm text-slate-300">
            <p>We <strong className="text-white">never sell, rent, license, or monetize</strong> your personal information, messages, or emails to advertisers or third-party data brokers.</p>
            <p>We <strong className="text-white">never disclose the sender's identity</strong> to the recipient.</p>
            <p>We <strong className="text-white">never use retargeting pixels</strong>, invasive tracking beacons, or cross-site advertising trackers.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">04</span> How We Use Your Information
          </h2>
          <ul className="list-disc list-inside space-y-1.5 text-xs sm:text-sm text-slate-400">
            <li><strong className="text-slate-200">Providing the Services:</strong> To deliver messages, maintain private inboxes, publish public Q&amp;A threads, and generate story sticker cards.</li>
            <li><strong className="text-slate-200">Platform Safety &amp; Moderation:</strong> To investigate, detect, and block abusive, harassing, hateful, or illegal messages and protect community members.</li>
            <li><strong className="text-slate-200">Customer Support:</strong> To answer your questions, resolve account issues, and respond to safety inquiries.</li>
            <li><strong className="text-slate-200">Legal Compliance:</strong> To comply with legal obligations, enforce our terms, and cooperate with law enforcement when required by law.</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">05</span> Automated Safety &amp; Content Moderation
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            To protect user safety, SecretMsg utilizes automated content moderation filters and algorithms designed to screen incoming messages. These filters detect and block harmful language, cyberbullying, predatory behavior, threats, and illegal material before it reaches recipients' inboxes. Recipients also retain full authority to report or block any message with a single tap.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">06</span> How Information Is Shared
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p><strong className="text-white">Public Social Sharing by Users:</strong> When an Account User chooses to post a response publicly, the question text and their answer become visible on their public Q&amp;A thread and wherever they share it on social media.</p>
            <p><strong className="text-white">Trusted Service Providers:</strong> We work with essential service providers who assist in operating our platform, including secure server hosting, database storage, and transactional email verification. These providers are bound by strict confidentiality and data protection standards.</p>
            <p><strong className="text-white">Compliance &amp; Safety:</strong> We may disclose information if we believe in good faith that such action is necessary to comply with legal requests, prevent physical harm or financial loss, or protect the safety and integrity of our users.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">07</span> Your Rights &amp; Choices (GDPR &amp; CCPA)
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            Regardless of your location, you have strong rights regarding your personal information:
          </p>
          <ul className="list-disc list-inside space-y-1.5 text-xs sm:text-sm text-slate-400 pl-2">
            <li><strong className="text-slate-200">Access &amp; Portability:</strong> You may request details about the data associated with your account.</li>
            <li><strong className="text-slate-200">Correction:</strong> You can update your display name and password directly from your dashboard settings.</li>
            <li><strong className="text-slate-200">Instant Complete Erasure:</strong> You have the right to permanently delete your data at any time.</li>
          </ul>
          <div className="glass-panel p-4 rounded-2xl border border-rose-500/20 bg-rose-500/5 text-xs text-slate-300 space-y-1.5 mt-2">
            <p className="font-semibold text-rose-300 flex items-center gap-1.5">
              <ShieldCheck className="w-4 h-4" />
              Self-Service 1-Tap Account Wipeout
            </p>
            <p className="text-slate-400">
              Open <strong className="text-white">Settings &rarr; Delete Account</strong> at any time. When confirmed, our systems immediately and permanently wipe your account, custom handle, email address, and all received messages forever. This deletion is permanent and cannot be reversed.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">08</span> Do Not Track Signals
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            Because we do not track our users across third-party websites or serve targeted behavioral advertising, our privacy practices remain consistent whether or not your browser transmits a &ldquo;Do Not Track&rdquo; signal.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">09</span> Children&apos;s Privacy
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            Our Services are not directed to children under 13 years of age (or the minimum legal age in your jurisdiction). We do not knowingly collect personal information from children. If we learn that personal information has been collected from a child under 13 without verified parental consent, we will promptly delete that information. Parents or guardians may contact us at <a href="mailto:safety@secretmsg.net" className="text-indigo-400 underline font-mono">safety@secretmsg.net</a>.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">10</span> Data Retention &amp; Security Practices
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            We retain your information only for as long as necessary to fulfill the purposes outlined in this policy or until you request deletion. We implement reasonable technical, administrative, and physical safeguards designed to protect personal data against unauthorized access, loss, alteration, or misuse.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">11</span> Inquiries &amp; Data Protection Contact
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            If you have questions regarding this Privacy Policy, our data practices, or wish to exercise your legal privacy rights, contact us at:
          </p>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
            <div>
              <span className="font-bold text-white block">SecretMsg Privacy &amp; Data Protection</span>
              <span className="text-slate-400 font-mono">privacy@secretmsg.net &bull; support@secretmsg.net</span>
            </div>
            <a href="mailto:privacy@secretmsg.net" className="px-4 py-2 bg-white text-dark-900 font-semibold rounded-full hover:bg-slate-100 transition-colors text-center shrink-0">
              Contact Privacy Team
            </a>
          </div>
        </section>
      </div>
    </PublicPage>
  );
};
