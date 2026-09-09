import React from 'react';
import { Link } from 'react-router-dom';
import { Ban, Flag, AlertTriangle, Mail } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

export const CommunityGuidelinesPage: React.FC = () => {
  return (
    <PublicPage
      title="Our Community Guidelines"
      description="SecretMsg is the place to play Q&A games with your followers, connect with real-world friends, ask fun questions, reply in public or private, and be your fullest, most authentic self. To keep this community vibrant and safe, we have set up these essential guidelines."
    >
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-10 text-xs">
        <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
          <div className="w-7 h-7 rounded-lg bg-emerald-500/20 text-emerald-400 flex items-center justify-center font-black mb-2">1</div>
          <strong className="text-white block font-semibold text-sm">Be REAL</strong>
          <p className="text-slate-400 text-xs leading-relaxed">
            Provide accurate handle information. Authenticity creates trust. Dishonest registration violates our Terms of Service.
          </p>
        </div>
        <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
          <div className="w-7 h-7 rounded-lg bg-indigo-500/20 text-indigo-400 flex items-center justify-center font-black mb-2">2</div>
          <strong className="text-white block font-semibold text-sm">Be YOU</strong>
          <p className="text-slate-400 text-xs leading-relaxed">
            Own your unique voice. We never ask for external social media passwords; your accounts and security are always protected.
          </p>
        </div>
        <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
          <div className="w-7 h-7 rounded-lg bg-amber-500/20 text-amber-400 flex items-center justify-center font-black mb-2">3</div>
          <strong className="text-white block font-semibold text-sm">Have Fun!</strong>
          <p className="text-slate-400 text-xs leading-relaxed">
            Strengthen friendships with curiosity and kindness. Remember: your fun should never come at the expense of someone else's peace of mind.
          </p>
        </div>
      </div>

      <article className="space-y-10 text-slate-300 text-sm leading-relaxed border-t border-white/10 pt-8">
        <section className="space-y-3">
          <div className="inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-rose-400 bg-rose-950/40 px-2.5 py-1 rounded border border-rose-500/30">
            <Ban className="w-3.5 h-3.5" />
            Strictly Prohibited on SecretMsg
          </div>
          <h2 className="text-xl font-bold text-white">
            Bullying, Harassment, Bigotry, Violence &amp; Threats
          </h2>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 text-xs sm:text-sm">
            <h3 className="font-bold text-white flex items-center gap-2">
              <Ban className="w-4 h-4 text-rose-400" />
              Bullying and Harassment
            </h3>
            <ul className="list-disc list-inside space-y-1.5 text-slate-300 pl-2 text-xs">
              <li>Don't submit anything that could be viewed as bullying, abuse, defamation, stalking, or targeted hate toward other users.</li>
              <li>Don't spread rumors, slander, or malicious gossip intended to humiliate or harm anyone.</li>
              <li>Avoid hurtful, derogatory terms, name-calling, body-shaming, or insults targeting someone's vulnerabilities.</li>
            </ul>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 text-xs sm:text-sm">
            <h3 className="font-bold text-white flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-amber-400" />
              Bigotry &amp; Hate Speech
            </h3>
            <ul className="list-disc list-inside space-y-1.5 text-slate-300 pl-2 text-xs">
              <li>Don't use hate speech or discriminate based on race, age, ethnicity, national origin, religion, gender identity, sexual orientation, or disability.</li>
              <li>Don't use offensive stereotypes, racial slurs, or insensitive jokes targeting protected identity groups.</li>
              <li>Don't make anyone feel unwelcome, degraded, or unsafe in the SecretMsg community.</li>
            </ul>
          </div>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 text-xs sm:text-sm">
            <h3 className="font-bold text-white flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-rose-400" />
              Violence, Harm &amp; Threats
            </h3>
            <ul className="list-disc list-inside space-y-1.5 text-slate-300 pl-2 text-xs">
              <li>Don't threaten, predict, or celebrate physical violence toward others.</li>
              <li>Don't promote or encourage suicide, self-harm, eating disorders, or any harmful self-destructive behavior.</li>
              <li>Don't share graphic depictions of violence or actionable strategies to assist violent acts.</li>
              <li>Don't make death threats, cybersecurity threats, ransomware demands, or cruelty to animals.</li>
              <li>Don't promote, engage in, recruit for, or spread violent extremism or terrorism.</li>
            </ul>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">
            Spam, Trolling, Misinformation &amp; Promotion
          </h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1.5">
              <strong className="text-white block font-semibold flex items-center gap-1.5">
                <Mail className="w-4 h-4 text-sky-400" />
                Spam &amp; Flooding
              </strong>
              <p className="text-slate-400 leading-relaxed">
                Don't submit repetitive messages, run automated bots, or flood a user's inbox with copy-pasted nonsense.
              </p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1.5">
              <strong className="text-white block font-semibold flex items-center gap-1.5">
                <Ban className="w-4 h-4 text-purple-400" />
                Trolling &amp; Hostility
              </strong>
              <p className="text-slate-400 leading-relaxed">
                Don't use SecretMsg solely to instigate conflict, bait hostile arguments, or embarrass other people.
              </p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1.5">
              <strong className="text-white block font-semibold flex items-center gap-1.5">
                <Flag className="w-4 h-4 text-rose-400" />
                Misinformation &amp; Impersonation
              </strong>
              <p className="text-slate-400 leading-relaxed">
                Don't impersonate other persons, spread knowingly fraudulent rumors, or interfere with civic or election processes.
              </p>
            </div>

            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1.5">
              <strong className="text-white block font-semibold flex items-center gap-1.5">
                <AlertTriangle className="w-4 h-4 text-amber-400" />
                Commercial Promotion
              </strong>
              <p className="text-slate-400 leading-relaxed">
                Don't post pyramid schemes, chain letters, commercial ads, or claim false partnerships or endorsements with SecretMsg.
              </p>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-bold text-white">
            Sexual Content &amp; Minor Protection
          </h2>

          <div className="glass-panel p-5 rounded-2xl border border-white/10 space-y-2 text-xs sm:text-sm">
            <ul className="list-disc list-inside space-y-2 text-slate-300 pl-2 text-xs">
              <li><strong>Sexual Harassment:</strong> Never describe graphic sexual acts without explicit consent, or threaten anyone with coercion, extortion, or revenge material.</li>
              <li><strong>Soliciting Sex:</strong> Don't pressure anyone to engage in sexual conduct or use SecretMsg as a vehicle for commercial solicitation.</li>
              <li><strong>Sexualization of Minors:</strong> Strictly zero tolerance. Engaging in sexual conversations with minors, or posting any child sexual abuse material (CSAM), results in immediate termination and mandatory law enforcement reporting.</li>
            </ul>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white">
            What If You See Someone Violate These Guidelines?
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            While our automated pre-delivery moderation intercepts the vast majority of objectionable content, no filter is 100% infallible. Here is how you can take action:
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">1. Report the Message</strong>
              <p className="text-slate-400 text-xs leading-relaxed">
                Tap the Report icon on the message card to instantly remove it from your board and flag the sender for moderation review.
              </p>
            </div>
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">2. Block the Sender</strong>
              <p className="text-slate-400 text-xs leading-relaxed">
                Choose "Block User" in the report dialog to permanently prevent that anonymous sender from contacting your link again.
              </p>
            </div>
            <div className="glass-panel p-4 rounded-xl border border-white/10 space-y-1">
              <strong className="text-white block font-semibold">3. Get Help &amp; Support</strong>
              <p className="text-slate-400 text-xs leading-relaxed">
                Visit our <Link to="/resources" className="text-indigo-400 underline">Resources</Link> page for free, confidential mental health and anti-bullying helplines.
              </p>
            </div>
          </div>

          <div className="glass-panel p-4 rounded-xl border border-white/10 bg-white/5 space-y-2 text-xs">
            <strong className="text-white block font-semibold">Enforcement &amp; Legal Escalation</strong>
            <p className="text-slate-300 leading-relaxed">
              Messages that violate these Community Guidelines may be removed at our sole discretion. Users who repeatedly or severely violate these rules face permanent bans. Any observed criminal activity is escalated directly to the appropriate law enforcement authorities.
            </p>
          </div>
        </section>

        <div className="glass-panel rounded-2xl p-5 border border-indigo-500/30 bg-indigo-950/20 text-center space-y-2">
          <h3 className="font-bold text-sm text-indigo-300">The SecretMsg Golden Rule</h3>
          <p className="text-slate-300 text-xs max-w-lg mx-auto leading-relaxed">
            SecretMsg is meant to be a fun, creative, and safe bridge between friends. Always be respectful, protect each other, and treat others the way you wish to be treated.
          </p>
        </div>
      </article>
    </PublicPage>
  );
};
