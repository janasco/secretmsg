import React from 'react';
import { Link } from 'react-router-dom';
import { ShieldCheck } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

export const TermsPage: React.FC = () => {
  return (
    <PublicPage
      title="Terms of Service"
      description="Please read these Terms of Service carefully before utilizing SecretMsg. By accessing our services, you agree to be bound by this agreement."
    >
      <p className="text-xs text-slate-400 mb-6"><strong className="text-slate-300">Last Updated: September 2026</strong></p>

      <div className="glass-panel rounded-2xl p-5 border border-rose-500/30 bg-rose-950/20 mb-10 flex flex-col sm:flex-row gap-4 items-start">
        <div className="w-10 h-10 rounded-full bg-rose-500/20 text-rose-400 flex items-center justify-center shrink-0">
          <ShieldCheck className="w-5 h-5" />
        </div>
        <div className="space-y-1 text-xs">
          <h3 className="text-sm font-bold text-rose-300">Strict Anti-Harassment &amp; Zero Tolerance Policy</h3>
          <p className="text-slate-300 leading-relaxed">
            SecretMsg is built for fun, candid, and uplifting communication. We have an unyielding <strong>zero-tolerance policy</strong> for hate speech, cyberbullying, sexual harassment, threats of self-harm, or extortion. Malicious actors are subject to permanent IP blocks and law enforcement referral.
          </p>
        </div>
      </div>

      <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-white/10 space-y-4 text-sm text-slate-300 leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">01</span> Interpretation &amp; Definitions
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm">
            The words with capitalized initial letters have meanings defined under the following conditions. The following definitions have the same meaning regardless of whether they appear in singular or in plural:
          </p>
          <ul className="list-disc list-inside space-y-2 text-xs sm:text-sm text-slate-400 pl-2">
            <li><strong className="text-slate-200">Company:</strong> (referred to as &ldquo;the Company&rdquo;, &ldquo;We&rdquo;, &ldquo;Us&rdquo; or &ldquo;Our&rdquo;) refers to SecretMsg.</li>
            <li><strong className="text-slate-200">Service:</strong> Refers to the SecretMsg web application, mobile interfaces, and services accessible via <code className="text-slate-200 font-mono text-xs">secretmsg.net</code>.</li>
            <li><strong className="text-slate-200">Account:</strong> A unique account created for You to access our Service, claim a handle, and maintain a private message board.</li>
            <li><strong className="text-slate-200">Account User:</strong> The registered individual who creates a link and manages questions and replies on their board.</li>
            <li><strong className="text-slate-200">Message Sender:</strong> Any person who visits an Account User&apos;s link to submit a question, comment, or anonymous note.</li>
            <li><strong className="text-slate-200">Content:</strong> Text, images, stickers, responses, or other information posted, uploaded, or transmitted by You or Message Senders.</li>
            <li><strong className="text-slate-200">Device:</strong> Any device that can access the Service, including a computer, cellphone, or digital tablet.</li>
            <li><strong className="text-slate-200">Feedback:</strong> Any feedback, suggestions, ideas, or innovations regarding attributes, features, or performance of the Service sent by You.</li>
            <li><strong className="text-slate-200">In-app Purchases / Supporter Contributions:</strong> Optional purchases of virtual items, supporter badges, or feature unlocks made through the Service.</li>
            <li><strong className="text-slate-200">Third-Party Social Media Service:</strong> External networks (such as Instagram, TikTok, WhatsApp, Snapchat, or X) where users share their SecretMsg links or export Q&amp;A stickers.</li>
            <li><strong className="text-slate-200">You:</strong> The individual accessing or using the Service, or the entity on behalf of which such individual is accessing or using the Service.</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">02</span> Acknowledgment &amp; Eligibility
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              These Terms and Conditions govern the use of this Service and form the binding agreement between You and the Company. They set out the rights and obligations of all visitors, users, and others who access or use SecretMsg.
            </p>
            <p>
              By accessing or using the Service, You agree to be bound by these Terms. If You disagree with any part of these Terms, You may not access the Service.
            </p>
            <p>
              <strong className="text-white">Age Requirement:</strong> You represent that You are at least 18 years of age, or if You are between 13 and 17, that You possess the consent of a parent or legal guardian to access and use the Service in compliance with applicable law. The Service is not intended for or directed to individuals under 13 years of age.
            </p>
            <p>
              Your access to and use of the Service is also conditioned on Your acceptance of and compliance with our <Link to="/p/privacy" className="text-indigo-400 underline">Privacy Policy</Link> and <Link to="/p/cookies" className="text-indigo-400 underline">Cookies Policy</Link>.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">03</span> User Accounts &amp; Handle Guidelines
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              When You create an account with Us, You must provide accurate, complete, and current information. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of Your account.
            </p>
            <p>
              You are responsible for safeguarding the password You use to access the Service and for any activities or actions under Your password. You agree not to disclose Your password to any third party and must notify Us immediately upon becoming aware of any breach of security or unauthorized use of Your account.
            </p>
            <p>
              <strong className="text-white">Handle &amp; Username Restrictions:</strong> You may not use as a username or URL slug the name of another person or entity with the intent to impersonate them, a name or trademark subject to any third-party rights without proper authorization, or a name that is offensive, vulgar, or obscene. We reserve the right to reclaim, suspend, or reassign usernames at our sole discretion.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">04</span> Content: Rights, Licenses &amp; Public Replies
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              <strong className="text-white">Your Right to Post:</strong> Our Service allows You to receive anonymous messages and post responses. You are solely responsible for the Content You post, including its legality, reliability, and appropriateness.
            </p>
            <p>
              <strong className="text-white">License Granted to SecretMsg:</strong> By posting Content to the Service (including public replies, questions, or shared thread answers), You grant Us a non-exclusive, worldwide, royalty-free license to use, reproduce, modify, publicly display, and distribute such Content on and through the Service solely for operating, promoting, and improving the platform. You retain all Your ownership rights in Your Content.
            </p>
            <p>
              <strong className="text-white">Public Q&amp;A &amp; Social Stickers:</strong> You understand that when You choose to mark an answer as public or export a Q&amp;A card to social media, that Content becomes publicly accessible. You represent and warrant that the posting of Your Content does not violate the intellectual property, privacy, or publicity rights of any third party.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">05</span> Content Restrictions &amp; Acceptable Use
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm">
            The Company is not responsible for the content posted by users or anonymous senders. You expressly agree that You will not post, upload, transmit, or distribute any Content that is:
          </p>
          <ul className="list-disc list-inside space-y-1.5 pl-4 text-slate-300 border-l border-white/10 text-xs sm:text-sm">
            <li><strong>Unlawful or Promoting Unlawful Activity:</strong> Criminal acts, illicit substances, self-harm, suicide encouragement, or extortion.</li>
            <li><strong>Hate Speech &amp; Cyberbullying:</strong> Defamatory, discriminatory, harassing, or mean-spirited attacks targeting race, ethnicity, religion, disability, sexual orientation, or gender.</li>
            <li><strong>Predatory or Exploitative:</strong> Child sexual abuse material (CSAM), non-consensual intimate imagery, or child endangerment (reported immediately to NCMEC and law enforcement).</li>
            <li><strong>Spam &amp; Commercial Solicitation:</strong> Unauthorized advertising, pyramid schemes, chain letters, gambling, lottery promotions, or automated mass bots.</li>
            <li><strong>Viruses &amp; Malicious Software:</strong> Code designed to disrupt, damage, or compromise the operation of any software, hardware, or network.</li>
            <li><strong>Infringing Proprietary Rights:</strong> Violations of patent, trademark, trade secret, copyright, or right of publicity.</li>
            <li><strong>Impersonation &amp; Privacy Invasions:</strong> Impersonating any individual or entity (including the Company) or doxxing private personal data (phone numbers, physical addresses, identification).</li>
            <li><strong>False Information:</strong> Misleading, deceptive, or fraudulent representations intended to manipulate or defraud users.</li>
          </ul>
          <p className="text-slate-400 text-xs mt-2">
            The Company reserves the right, but not the obligation, to determine whether Content complies with these Terms, and to format, edit, refuse, or remove Content at any time. As SecretMsg facilitates anonymous feedback, You agree to use the Service at Your own risk.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">06</span> Content Backups
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            Although regular backups of Content are performed, the Company does not guarantee there will be no loss or corruption of data. Corrupt backup points may occur due to network events or system changes. You acknowledge that the Company has no liability related to the integrity of Content or the failure to successfully restore Content. You are encouraged to maintain independent copies of important Content.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">07</span> Copyright Policy &amp; DMCA Takedown Procedure
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              We respect the intellectual property rights of others. If You believe that Content on the Service infringes Your copyright, You may submit a written notice to our designated Copyright Agent at <a href="mailto:legal@secretmsg.net" className="text-indigo-400 underline font-mono">legal@secretmsg.net</a> pursuant to the Digital Millennium Copyright Act (DMCA) (17 U.S.C. &sect; 512(c)(3)) with the following:
            </p>
            <ul className="list-disc list-inside space-y-1 text-xs text-slate-400 pl-2">
              <li>An electronic or physical signature of the person authorized to act on behalf of the copyright owner.</li>
              <li>A description of the copyrighted work claimed to have been infringed, including where the work exists.</li>
              <li>The specific URL or location on the Service where the allegedly infringing material is located.</li>
              <li>Your physical address, telephone number, and email address.</li>
              <li>A statement that You have a good faith belief that the disputed use is not authorized by the copyright owner, its agent, or the law.</li>
              <li>A statement made under penalty of perjury that the information in Your notice is accurate and that You are authorized to act.</li>
            </ul>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">08</span> Feedback Provided by You
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            You assign all rights, title, and interest in any Feedback You provide to the Company. If such assignment is ineffective, You grant the Company an exclusive, perpetual, irrevocable, royalty-free, worldwide license to use, reproduce, disclose, sub-license, distribute, and exploit such Feedback without restriction or compensation.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">09</span> In-App Purchases, Billing &amp; Subscriptions
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p>
              The Service may offer optional In-App Purchases, virtual items, or supporter badges. All billing and transaction processing are handled by authorized payment processors or application stores.
            </p>
            <p>
              In-App Purchases are consumed within the Service and cannot be cancelled or redeemed for cash once initiated. If an item fails to deliver due to technical error, contact us at <a href="mailto:support@secretmsg.net" className="text-indigo-400 underline font-mono">support@secretmsg.net</a> for investigation and prompt resolution or refund authorization.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">10</span> Links to Other Websites &amp; Third-Party Platforms
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            Our Service may contain links to third-party websites or services that are not owned or controlled by the Company (including Instagram, WhatsApp, TikTok, and X). We assume no responsibility for the content, privacy policies, or practices of any third-party websites. You acknowledge that the Company shall not be liable for any damage or loss caused by reliance on external services.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">11</span> Termination &amp; 1-Tap Wipeout
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            We may terminate or suspend Your Account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if You breach these Terms. You may also terminate Your account at any time using the self-service <strong className="text-white">Delete Account</strong> option in Settings, which permanently removes Your board, username, and stored messages.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">12</span> Limitation of Liability
          </h2>
          <div className="space-y-2 text-xs text-slate-400 leading-relaxed">
            <p>
              Notwithstanding any damages that You might incur, the entire liability of the Company and any of its suppliers under any provision of these Terms, and Your exclusive remedy for all of the foregoing, shall be limited to the amount actually paid by You through the Service, or <strong className="text-white">100 USD</strong> if You have not purchased anything through the Service.
            </p>
            <p>
              To the maximum extent permitted by applicable law, in no event shall the Company or its suppliers be liable for any special, incidental, indirect, or consequential damages whatsoever (including loss of profits, loss of data, business interruption, personal injury, or loss of privacy) arising out of or related to the use of or inability to use the Service.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">13</span> &ldquo;AS IS&rdquo; and &ldquo;AS AVAILABLE&rdquo; Disclaimer
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm leading-relaxed">
            The Service is provided to You <strong className="text-white">&ldquo;AS IS&rdquo; AND &ldquo;AS AVAILABLE&rdquo;</strong> with all faults and defects without warranty of any kind. To the maximum extent permitted under applicable law, the Company expressly disclaims all warranties, whether express, implied, statutory, or otherwise, including merchantability, fitness for a particular purpose, title, non-infringement, and warranties arising out of course of dealing or usage. We make no warranty that the Service will meet Your requirements, operate uninterrupted, or be error-free.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">14</span> Governing Law, Disputes &amp; Jurisdiction
          </h2>
          <div className="space-y-2 text-xs text-slate-400 leading-relaxed">
            <p>
              The laws of the State of California, United States, excluding conflicts of law rules, shall govern these Terms and Your use of the Service.
            </p>
            <p>
              <strong className="text-white">Informal Resolution:</strong> If You have any concern or dispute about the Service, You agree to first attempt to resolve the dispute informally by contacting the Company at <a href="mailto:support@secretmsg.net" className="text-indigo-400 underline font-mono">support@secretmsg.net</a>.
            </p>
            <p>
              <strong className="text-white">For European Union (EU) Users:</strong> If You are an EU consumer, You benefit from any mandatory provisions of the law of the country in which You reside.
            </p>
            <p>
              <strong className="text-white">United States Legal Compliance:</strong> You represent and warrant that (i) You are not located in a country subject to U.S. government embargo, or designated as a &ldquo;terrorist supporting&rdquo; country, and (ii) You are not listed on any U.S. government list of prohibited or restricted parties.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">15</span> Severability, Waiver &amp; Changes to Terms
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400 leading-relaxed">
            <p>
              <strong className="text-white">Severability &amp; Waiver:</strong> If any provision of these Terms is held to be invalid or unenforceable, such provision will be interpreted to accomplish its objectives to the greatest extent possible, and remaining provisions continue in full force. Failure to exercise a right does not waive future enforcement.
            </p>
            <p>
              <strong className="text-white">Changes to These Terms:</strong> We reserve the right to modify or replace these Terms at any time. If a revision is material, We will make reasonable efforts to provide at least 30 days&apos; notice prior to new terms taking effect. By continuing to use the Service after revisions become effective, You agree to be bound by the revised terms.
            </p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">16</span> Contact Information
          </h2>
          <p className="text-slate-400 text-xs sm:text-sm">
            If You have questions about these Terms and Conditions or wish to report violations, reach out to our team:
          </p>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs mt-3">
            <div>
              <span className="font-bold text-white block">Trust, Legal &amp; Safety Operations</span>
              <span className="text-slate-400 font-mono">support@secretmsg.net &bull; legal@secretmsg.net &bull; abuse@secretmsg.net</span>
            </div>
            <a href="mailto:legal@secretmsg.net" className="px-4 py-2 bg-white text-dark-900 font-semibold rounded-full hover:bg-slate-100 transition-colors text-center shrink-0">
              Email Legal Team
            </a>
          </div>
        </section>
      </div>
    </PublicPage>
  );
};
