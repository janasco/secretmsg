import React from 'react';
import { PublicPage } from '../components/PublicPage';

export const ApproachToSafetyPage: React.FC = () => {
  return (
    <PublicPage
      eyebrow="Our Commitment • Proactive Digital Safeguards"
      title="Our Approach to Safety"
      description="At SecretMsg, safety is our highest priority. We created SecretMsg as a vibrant anonymous Q&A platform where you can foster authentic, meaningful connections with friends, ask fun questions, reply in public or private, and keep the conversation going — all within a community rooted in kindness and respect."
    >
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-10">
        <div className="glass-panel rounded-2xl p-5 border border-white/10 space-y-2 hover:border-emerald-500/40 transition-colors">
          <span className="text-lg"><span>🛡️</span></span>
          <h3 className="font-bold text-sm text-white">Automated First Line of Defense</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            State-of-the-art automated moderation scans every incoming question before delivery, filtering toxic language, hate speech, and predatory content.
          </p>
        </div>
        <div className="glass-panel rounded-2xl p-5 border border-white/10 space-y-2 hover:border-emerald-500/40 transition-colors">
          <span className="text-lg"><span>🧑‍💻</span></span>
          <h3 className="font-bold text-sm text-white">24/7 Human Trust & Safety Team</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            Our community operations team monitors user reports, escalations, and support requests around the clock to ensure safety and quick action.
          </p>
        </div>
        <div className="glass-panel rounded-2xl p-5 border border-white/10 space-y-2 hover:border-amber-500/40 transition-colors">
          <span className="text-lg"><span>🎛️</span></span>
          <h3 className="font-bold text-sm text-white">Recipient Sovereignty</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            Pause your link at any time, filter custom keywords, block unwanted senders in 1 tap, or wipe your entire inbox in an instant.
          </p>
        </div>
        <div className="glass-panel rounded-2xl p-5 border border-white/10 space-y-2 hover:border-rose-500/40 transition-colors">
          <span className="text-lg"><span>🚩</span></span>
          <h3 className="font-bold text-sm text-white">Swift In-App Reporting</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            Reporting an uncomfortable message instantly purges it from your board and flags the sender's anonymous session for review and throttling.
          </p>
        </div>
      </div>

      <article className="space-y-10 text-slate-300 text-sm leading-relaxed border-t border-white/10 pt-8">
        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">01</span> Cultivating Kindness in Anonymous Q&A
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            Anonymity can empower people to share candid compliments, wholesome confessions, and creative questions that they might feel too hesitant to say aloud. However, an open door must always have an ironclad shield.
          </p>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            SecretMsg has engineered an extensive ecosystem of security controls, safety infrastructure, clear community guidelines, and proactive policies that make us a leading voice for user protection in anonymous communication. You are always in control of your link, your board, and your conversations.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">02</span> Advanced Content Moderation Architecture
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            We take cases of bullying, hate, or violence with extreme seriousness. SecretMsg utilizes a multi-layered moderation pipeline combining automated machine intelligence with experienced human oversight:
          </p>
          <div className="space-y-3 text-xs sm:text-sm text-slate-400 pt-2">
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">1. Deep-Learning Automated Pre-Delivery Filter</strong>
              <p className="text-slate-300 leading-relaxed text-xs">
                Before any message hits a user's inbox, automated deep-learning algorithms analyze the text. Our models understand context, nuances of modern internet slang, and semantic emoji combinations to detect abusive intent, self-harm language, harassment, or predatory behavior. Messages flagged as harmful are intercepted and blocked before delivery.
              </p>
            </div>
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">2. 24/7 Human Community Review</strong>
              <p className="text-slate-300 leading-relaxed text-xs">
                Automated systems are accompanied by real-world human experience. Our specialized Trust & Safety team reviews escalations, investigates ambiguous reports, and acts swiftly against bad actors.
              </p>
            </div>
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">3. Balanced Expression and Safety</strong>
              <p className="text-slate-300 leading-relaxed text-xs">
                Content moderation is a careful balance between user expression and community protection. Our rules ensure SecretMsg remains a safe, uplifting space where genuine curiosity thrives free from harassment or intimidation.
              </p>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">03</span> How In-App Reporting & Blocking Works
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              When you receive a message on SecretMsg that you find inappropriate, offensive, or harmful, you can report it directly within your inbox in seconds:
            </p>
            <ul className="list-disc list-inside space-y-1.5 text-slate-300 pl-2 text-xs sm:text-sm">
              <li><strong>Tap Report:</strong> Click or tap the Report button (<span className="text-amber-400 font-bold">⚠</span>) on any message card.</li>
              <li><strong>Immediate Quarantine:</strong> The message is instantly deleted from your active board and queued for administrative review.</li>
              <li><strong>1-Tap Sender Block:</strong> Select "Block User" to prevent that sender's anonymous session from ever sending you another message.</li>
              <li><strong>Contextual Assessment:</strong> Our team reviews reported content against our Community Guidelines and Terms of Service, taking punitive action up to permanent network bans.</li>
            </ul>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">04</span> Safety Frequently Asked Questions
          </h2>
          <div className="space-y-3 text-xs sm:text-sm">
            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1.5">
              <h3 className="font-bold text-white text-xs sm:text-sm flex items-center gap-2">
                <span className="text-indigo-400">Q:</span> What is and isn't allowed on SecretMsg?
              </h3>
              <p className="text-slate-300 text-xs leading-relaxed">
                Our Community Guidelines and Terms of Service define all prohibited behavior. In general, SecretMsg is an uplifting place to have fun, ask questions, share compliments, and create authentic Q&A threads with friends. Cyberbullying, hate speech, threats, sexual harassment, and predatory behavior are strictly prohibited.
              </p>
            </div>

            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1.5">
              <h3 className="font-bold text-white text-xs sm:text-sm flex items-center gap-2">
                <span className="text-indigo-400">Q:</span> Can I block anonymous message senders?
              </h3>
              <p className="text-slate-300 text-xs leading-relaxed">
                Yes. Whenever you view a message, you can tap the Report button (⚠) and select "Block sender". The message will be purged from your inbox and that sender will be forbidden from sending messages to your link.
              </p>
            </div>

            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1.5">
              <h3 className="font-bold text-white text-xs sm:text-sm flex items-center gap-2">
                <span className="text-indigo-400">Q:</span> I received an emergency message; what should I do?
              </h3>
              <p className="text-slate-300 text-xs leading-relaxed">
                If a message suggests that you or someone else may be in imminent physical danger or crisis, please contact local emergency services or law enforcement immediately. Once emergency responders are engaged, please notify our safety team at <a href="mailto:safety@secretmsg.net" className="text-rose-400 underline font-mono">safety@secretmsg.net</a> so we can take immediate protective action.
              </p>
            </div>

            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1.5">
              <h3 className="font-bold text-white text-xs sm:text-sm flex items-center gap-2">
                <span className="text-indigo-400">Q:</span> I received a concerning message; how do I get help?
              </h3>
              <p className="text-slate-300 text-xs leading-relaxed">
                If the message is concerning but not an immediate physical emergency, reach out to our team at <a href="mailto:safety@secretmsg.net" className="text-indigo-400 underline font-mono">safety@secretmsg.net</a>. A member of our team will review the issue and assist you with guidance and technical controls.
              </p>
            </div>

            <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-1.5">
              <h3 className="font-bold text-white text-xs sm:text-sm flex items-center gap-2">
                <span className="text-indigo-400">Q:</span> Where can I find crisis and mental health resources?
              </h3>
              <p className="text-slate-300 text-xs leading-relaxed">
                Visit our dedicated Safety & Crisis Resources page for direct hotlines, text lines, and confidential support services for mental health, anti-bullying, and crisis intervention.
              </p>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white mt-8 mb-3 flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">05</span> We Are Here to Help
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm">
            No concern is too small. If you ever have a question about our safety tools or need assistance with your link:
          </p>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs mt-3">
            <div>
              <span className="font-bold text-white block">Trust & Safety Community Help</span>
              <span className="text-slate-400 font-mono">safety@secretmsg.net • support@secretmsg.net</span>
            </div>
            <a href="mailto:safety@secretmsg.net" className="px-4 py-2 bg-indigo-600 text-white font-semibold rounded-full hover:bg-indigo-500 transition-colors text-center shrink-0">
              Contact Safety Team
            </a>
          </div>
        </section>
      </article>
    </PublicPage>
  );
};
