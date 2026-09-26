import React from 'react';
import { Link } from 'react-router-dom';
import { Eye, Ban, Minus, ShieldCheck } from 'lucide-react';
import { PublicPage } from '@/components/PublicPage';

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
          <p className="text-xs text-slate-400 leading-relaxed">We do not ask senders for a name or account. A mobile-app sender value is stored only as a SHA-256 hash with a message and, when blocked, in that recipient&apos;s block list; it cannot be reversed into an identity.</p>
        </div>
        <div className="glass-panel rounded-2xl p-4 flex flex-col gap-2 border border-white/10">
          <Ban className="w-6 h-6 text-sky-400" />
          <h3 className="font-bold text-sm text-white">No Data Selling</h3>
          <p className="text-xs text-slate-400 leading-relaxed">We never sell, trade, or license your personal information or your messages. The Android app serves ads through Google AdMob; this website serves no ads at all.</p>
        </div>
        <div className="glass-panel rounded-2xl p-4 flex flex-col gap-2 border border-white/10">
          <Minus className="w-6 h-6 text-rose-400" />
          <h3 className="font-bold text-sm text-white">Account Deletion</h3>
          <p className="text-xs text-slate-400 leading-relaxed">A successful deletion request removes the primary D1 account record, handle, profile, and received messages. It is not universal erasure; the limits below apply.</p>
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
            <li><strong className="text-slate-200">Public or Private Replies:</strong> The Account User can reply privately through a secure one-time link or publish an answer on their board and share it elsewhere.</li>
            <li><strong className="text-slate-200">Sender Anonymity:</strong> SecretMsg does not ask for or store the sender&apos;s name, email address, or social-media handle, and cannot reveal a name or handle to the Account User.</li>
            <li><strong className="text-slate-200">Optional Sender Clues:</strong> If both the sender and Account User permit it, SecretMsg may show a broad platform type such as “Mobile / Android.” It does not provide a precise location or a unique sender identity.</li>
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
                <li><strong className="text-slate-200">Account Information:</strong> The primary sign-in method is a handle and a 4–6 digit PIN. An account may also contain a display name, avatar selection, bio, safety settings, hashed PIN and backup-code values, and an account ID.</li>
                <li><strong className="text-slate-200">Legacy Email Login:</strong> A real email address is optional and is used only with the legacy email-code login path. Handle/PIN accounts store the synthetic placeholder <code className="text-slate-200 font-mono text-xs">&lt;handle&gt;@v2.secretmsg</code>; it is not a real mailbox and cannot receive email.</li>
                <li><strong className="text-slate-200">Questions &amp; Messages:</strong> Message text, replies, recipient settings, message timestamps, delivery metadata, and report reasons submitted to Account Users.</li>
                <li><strong className="text-slate-200">Feedback &amp; Support Correspondence:</strong> Information you choose to submit when contacting our support or trust &amp; safety team.</li>
              </ul>
            </div>
            <div>
              <h3 className="font-semibold text-white">B. Automatically Collected Information</h3>
              <ul className="list-disc list-inside space-y-1.5 text-slate-400 mt-1">
                <li><strong className="text-slate-200">Device &amp; Connection Data:</strong> Cloudflare processes the raw connecting IP and other request data to serve the service. We may use a User-Agent to produce the broad platform clue described above. We do not collect precise location through SecretMsg.</li>
                <li><strong className="text-slate-200">Security Verification:</strong> Cloudflare Turnstile receives its challenge response and, when available, the raw connecting IP for account creation, email-code requests, message sends, and reports.</li>
                <li><strong className="text-slate-200">Ad Request Data (Android App Only):</strong> When the Android app requests an ad from Google AdMob, Google&apos;s Mobile Ads SDK collects the information listed in section 03, including the device advertising ID, IP address, device model and OS version, app version, screen resolution, language, and coarse location derived from IP. This happens on your device and in Google&apos;s systems; SecretMsg does not build a profile from it and does not join it to your messages or your account record. This website requests no ads and loads no ad SDK.</li>
                <li><strong className="text-slate-200">Local Storage Technologies:</strong> The app and browser may store preferences, drafts, authentication state, cached inbox data, your ad-consent choice, and account-related data on your device. Authentication and the mobile sender value use secure storage where implemented.</li>
              </ul>
            </div>
            <div>
              <h3 className="font-semibold text-white">C. Device and Other Identifiers</h3>
              <ul className="list-disc list-inside space-y-1.5 text-slate-400 mt-1">
                <li><strong className="text-slate-200">Account ID:</strong> A random SecretMsg account identifier used to operate the account and link account-linked records.</li>
                <li><strong className="text-slate-200">FCM Registration Token:</strong> If you enable push notifications, the app may register an FCM token with your account so Google Firebase Cloud Messaging can deliver new-message notifications.</li>
                <li><strong className="text-slate-200">App-Generated Sender Value Hash:</strong> The mobile app may generate and store a stable random value once per installation. It is not derived from hardware. The app sends the value so the server can store only its SHA-256 hash with a message and, if you block that sender, in your block list. The recipient cannot reverse the hash.</li>
                <li><strong className="text-slate-200">Hashed Rate-Limit Identifier:</strong> D1 stores a bucket name plus a SHA-256-derived key based on an IP address, handle, email address, or account ID as applicable. Raw IP addresses are not stored in readable form in the D1 rate-limit table, but Cloudflare processes the raw IP to serve the request and Turnstile receives it when verification is requested.</li>
                <li><strong className="text-slate-200">Advertising ID (Android App Only):</strong> The Google Mobile Ads SDK may read the device advertising ID, a resettable identifier assigned by Android for advertising purposes. This is the one identifier in the list that is an advertising ID. It is not sent to SecretMsg servers, it is not linked to your SecretMsg account, and it is not a hardware serial number. It is described further in section 03.</li>
              </ul>
              <p className="text-slate-400 mt-2">Except for the advertising ID above, none of these values is a hardware identifier. SecretMsg does not use a first-party analytics SDK and does not run session replay, heatmaps, or clickstream tracking. The Android app does include Google&apos;s advertising SDK, which section 03 explains in full.</p>
              <p className="text-slate-400 mt-1"><strong className="text-slate-200">Push-preview limit:</strong> For a new message, FCM receives the registered FCM token, a random message ID, the unread-message count, and a message preview truncated by SecretMsg to 140 characters, with an ellipsis added when truncated. The full message body is never sent through FCM.</p>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">03</span> Advertising in the Android App
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            SecretMsg is funded by advertising and by one optional in-app purchase. This section says plainly what that involves, because a project that asks you to trust it with anonymous messages has to be exact about this part.
          </p>
          <div className="space-y-3 text-xs sm:text-sm text-slate-400">
            <p><strong className="text-white">Where ads appear:</strong> Ads are served by Google AdMob, using the Google Mobile Ads SDK, in the <strong className="text-white">Android app only</strong> — as a banner and as an optional rewarded video. <strong className="text-white">This website serves no ads.</strong> secretmsg.net loads no Google Mobile Ads SDK, no ad exchange, and no ad script, so no ad code runs in your browser when you use the site on desktop or mobile.</p>
            <p><strong className="text-white">What an ad request contains:</strong> The request is assembled by Google on your device and includes the device advertising ID, IP address, device model and OS version, app and SDK version, screen size, language, and a coarse location inferred from the IP address. It does not include your SecretMsg handle, your display name, your messages, your replies, your contacts, or the identity of anyone who sent you a message. SecretMsg does not join advertising data to message content or to your account record.</p>
            <p><strong className="text-white">Identifiers and opting out:</strong> The device advertising ID is a resettable identifier assigned by Android for advertising. You can reset it or limit its use to non-personalised ads in Android Settings, under Privacy &rarr; Ads (the exact path varies by device and Android version). Google provides a system-level opt-out for advertising, and Google&apos;s certified ad-settings page is available at <code className="text-slate-200 font-mono text-xs">adssettings.google.com</code>.</p>
            <p><strong className="text-white">Personalised versus non-personalised ads:</strong> In the EEA, the UK, and Switzerland, personalised ads are only served if you consent. Without consent, or if you opt out, Google serves non-personalised ads, which are selected without using your advertising ID or your prior activity. Outside those regions the app asks for consent where required, and you can always change your choice in the app&apos;s settings.</p>
            <p><strong className="text-white">European consent:</strong> Where the GDPR, the UK GDPR, or the ePrivacy Directive requires it, the Android app shows a consent management platform before any ad is requested. If you decline, ads are non-personalised or suppressed. Consent can be withdrawn at any time in the app, and withdrawing it stops personalised ads from then on.</p>
            <p><strong className="text-white">US state privacy rights:</strong> If you live in a US state with a comprehensive privacy law — including California, Virginia, Colorado, Connecticut, Utah, and others — you may have the right to opt out of the sale or sharing of your personal information, to opt out of targeted advertising, to limit the use of sensitive personal information, and to know what categories of personal information were disclosed. Google serves as the ad partner and handles those rights in its own systems. You can exercise them through the Google My Ad Center or Ads Settings links above, and you can also email us at <a href="mailto:privacy@secretmsg.net" className="text-indigo-400 underline font-mono">privacy@secretmsg.net</a> and we will route the request. The Android app also presents an <strong className="text-white">&ldquo;Ad privacy options&rdquo;</strong> entry in Settings, which opens Google&rsquo;s privacy options form so you can change an advertising choice you already made &mdash; withdraw consent, or exercise a US state opt-out, depending on where you are. It appears only when that choice is actually available to you.</p>
            <p><strong className="text-white">Removing ads:</strong> A single one-time Google Play purchase, <code className="text-slate-200 font-mono text-xs">remove_ads</code>, disables ads in the Android app for your account. It is not a subscription. Purchased ads-free status is stored on your SecretMsg account, so it follows you rather than living on one device.</p>
            <p><strong className="text-white">What ads do not mean here:</strong> Serving an ad does not give an advertiser, us, or Google access to your inbox. Message content, sender identity, and the fact that you use SecretMsg are not disclosed for ad targeting. We do not use Firebase Analytics, Crashlytics, session replay, or any first-party analytics SDK, and we do not run ad code on this website. The anonymity guarantees in section 01 are unchanged by advertising.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">04</span> What We Will NEVER Do
          </h2>
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10 space-y-2 text-xs sm:text-sm text-slate-300">
            <p>We <strong className="text-white">never sell, rent, license, or monetize</strong> your personal information, messages, or emails to advertisers or third-party data brokers. Ad revenue is generated by Google selling ad placements, not by us selling your data.</p>
            <p>We <strong className="text-white">never disclose a sender&apos;s name or account</strong> to the recipient because we do not ask for one, and we <strong className="text-white">never pass message content to the ad network</strong>.</p>
            <p>We <strong className="text-white">never run advertising pixels, ad tags, or ad code on this website</strong>, and we do not do cross-site behavioral advertising: SecretMsg does not follow you around other sites or apps.</p>
            <p>We <strong className="text-white">do not use a first-party analytics SDK</strong> — no Firebase Analytics, no Crashlytics, no session replay, no heatmaps.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">05</span> How We Use Your Information
          </h2>
          <ul className="list-disc list-inside space-y-1.5 text-xs sm:text-sm text-slate-400">
            <li><strong className="text-slate-200">Providing the Services:</strong> To authenticate accounts, deliver messages and replies, maintain private inboxes, publish user-chosen public answers, generate story sticker cards, and send optional push notifications.</li>
            <li><strong className="text-slate-200">Platform Safety &amp; Abuse Prevention:</strong> To apply recipient-configured hidden-word filters, quarantine or reject messages, operate recipient-specific sender blocks, store reports, and enforce rate limits.</li>
            <li><strong className="text-slate-200">Customer Support:</strong> To answer questions, resolve account issues, and respond to safety inquiries.</li>
            <li><strong className="text-slate-200">Advertising:</strong> To request ads from Google AdMob in the Android app and to honour the ad-consent choice and any opt-out signal you have expressed, as described in section 03.</li>
            <li><strong className="text-slate-200">Payments &amp; Support:</strong> To verify the Google Play <code className="text-slate-200 font-mono text-xs">remove_ads</code> purchase and to record the resulting ad-free entitlement on your account.</li>
            <li><strong className="text-slate-200">Legal Compliance:</strong> To comply with legal obligations, enforce our terms, preserve relevant records, and cooperate with law enforcement when required by law.</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">06</span> Automated Safety &amp; Content Moderation
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            SecretMsg uses a send-time Cloudflare Turnstile check and recipient-configured hidden-word filtering. In the standard setting, a matching message is quarantined for the recipient&apos;s review; in strict mode, it is rejected and quarantined. The filter is rules-based and does not use automated machine-learning classification, does not understand context, and cannot be represented as a comprehensive detector of CSAM, grooming, or other abuse. Recipients can report or block a message; reporting quarantines it and records the report reason, while blocking stores the sender-fingerprint hash in that recipient&apos;s block list and removes the message.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">07</span> How Information Is Shared
          </h2>
          <div className="space-y-2 text-xs sm:text-sm text-slate-400">
            <p><strong className="text-white">Public Social Sharing by Users:</strong> When an Account User chooses to post a response publicly, the question and answer become visible on their public Q&amp;A thread and wherever they share it on social media.</p>
            <p className="font-semibold text-white">Service Processors:</p>
            <ul className="list-disc list-inside space-y-1.5 pl-2">
              <li><strong className="text-slate-200">Cloudflare:</strong> Cloudflare hosts the API and may process request content, headers, and the raw connecting IP. Cloudflare D1 stores account, message, report, purchase, and security records. Cloudflare Turnstile receives the challenge response and raw connecting IP when verification is requested. The operator backup process may upload an encrypted D1 export to Cloudflare R2.</li>
              <li><strong className="text-slate-200">Resend:</strong> Only when the legacy email-code path is used, Resend receives the real email address and the six-digit login code for delivery. The current handle/PIN path stores a synthetic placeholder instead and does not send a login email.</li>
              <li><strong className="text-slate-200">Google Play Billing:</strong> When the ad-free purchase is verified, SecretMsg sends the Google Play purchase token and product ID to Google. Google returns purchase state and an order ID when available. Play processes payment details; SecretMsg does not receive or store card details.</li>
              <li><strong className="text-slate-200">Google Firebase Cloud Messaging:</strong> FCM receives the registered FCM token, a random message ID, the unread count, and the server-truncated 140-character preview described above. Full message bodies are not sent through FCM.</li>
              <li><strong className="text-slate-200">Google AdMob (Android app only):</strong> Google AdMob is both our advertising partner and a processor of ad-request data. Its Google Mobile Ads SDK runs in the Android app and receives the device advertising ID, IP address, device and OS details, app version, and coarse location derived from IP, as set out in section 03. It does not receive your message content, replies, handle, or display name. Google acts as an independent controller for its own advertising purposes and its own systems, which are outside our control; Google&apos;s own policies and consent flows govern that processing. secretmsg.net does not load this SDK. AdMob may return aggregated, non-identifying impression and revenue statistics to the app so we can measure whether ads are worth keeping. You can opt out as described in section 03, and a verified <code className="text-slate-200 font-mono text-xs">remove_ads</code> purchase stops ad requests entirely.</li>
            </ul>
            <p><strong className="text-white">Compliance &amp; Safety:</strong> We may disclose relevant information when we believe in good faith that it is necessary to comply with valid legal process, prevent imminent harm, enforce our terms, or protect users. We may also preserve relevant records for a valid legal process.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">08</span> Your Rights &amp; Choices (GDPR &amp; CCPA)
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            Depending on your location, you may have rights to access, correct, export, restrict, object to, or request deletion of personal information. You may update your display name, avatar, and safety settings directly in the app. Contact us for other access, correction, or export requests.
          </p>
          <ul className="list-disc list-inside space-y-1.5 text-xs sm:text-sm text-slate-400 pl-2">
            <li><strong className="text-slate-200">Access &amp; Portability:</strong> You may request details about data associated with your account and a copy of eligible account data.</li>
            <li><strong className="text-slate-200">Correction:</strong> You can update profile and safety fields directly; contact us to correct other stored account information.</li>
            <li><strong className="text-slate-200">Deletion:</strong> You may request deletion of your account through the in-app control or the public deletion page.</li>
            <li><strong className="text-slate-200">Object &amp; Restrict:</strong> You may object to processing based on legitimate interests, including advertising, and ask us to restrict a use of your data.</li>
            <li><strong className="text-slate-200">Consent Withdrawal:</strong> Where we rely on consent, including for personalised ads in the EEA and the UK, you may withdraw it at any time in the app without affecting processing carried out before withdrawal. Declining consent leaves you on non-personalised ads rather than locking you out.</li>
            <li><strong className="text-slate-200">US State Opt-Outs:</strong> California and other US state residents may opt out of the sale or sharing of personal information, opt out of targeted advertising, limit the use of sensitive personal information, and request deletion. Google handles these rights for ad data through <code className="text-slate-200 font-mono text-xs">adssettings.google.com</code> and My Ad Center, and the app presents an &ldquo;Ad privacy options&rdquo; control in Settings that opens Google&rsquo;s privacy options form, shown only when the SDK reports that a choice is available to you. Email <a href="mailto:privacy@secretmsg.net" className="text-indigo-400 underline font-mono">privacy@secretmsg.net</a> to reach us instead. We do not knowingly sell or share the personal information of users under 16.</li>
            <li><strong className="text-slate-200">Ad-Free Access:</strong> A one-time <code className="text-slate-200 font-mono text-xs">remove_ads</code> purchase in the Android app stops ad requests being made by the app. There is no subscription to cancel and no recurring charge.</li>
          </ul>
          <div className="glass-panel p-4 rounded-2xl border border-rose-500/20 bg-rose-500/5 text-xs text-slate-300 space-y-1.5 mt-2">
            <p className="font-semibold text-rose-300 flex items-center gap-1.5">
              <ShieldCheck className="w-4 h-4" />
              Self-Service Account Deletion
            </p>
            <p className="text-slate-400">
              Open <strong className="text-white">Settings &rarr; Delete Account</strong> or use our public <Link to="/delete-account" className="text-indigo-300 underline">Delete Account</Link> page at <code className="text-slate-200 font-mono text-xs">secretmsg.net/delete-account</code>. A full signed-in session is required.
            </p>
            <p className="text-slate-400">
              After a successful request, SecretMsg deletes the received messages, blocked-sender records, reports involving the account as recipient or reporter, pairing codes, purchase records including the ad-free entitlement, email-keyed one-time-code sessions, identifiable account-derived rate-limit rows, and finally the primary D1 account row. The row includes the handle, profile, PIN hash, FCM token, and stored email field. For a handle/PIN account, deleting the email field removes the synthetic <code className="text-slate-200 font-mono text-xs">&lt;handle&gt;@v2.secretmsg</code> placeholder; no deletion message is sent because it is not a mailbox. For a legacy account, the real email is removed from the D1 account row, but provider-side copies are outside this operation.
            </p>
            <p className="font-semibold text-rose-300">Deletion limits:</p>
            <ul className="list-disc list-inside space-y-1 pl-2">
              <li>IP-keyed rate-limit rows that cannot be mapped to the account are not explicitly purged and remain under their retention window and scheduled cleanup.</li>
              <li>Copies you exported, downloaded, saved, posted elsewhere, or shared with another service cannot be retracted.</li>
              <li>Records held independently by Google Play, Google AdMob, Resend, Cloudflare, or other providers are not erased by the SecretMsg endpoint. Ad-related data held by Google is removed or limited through Google&apos;s own settings and opt-out tools, which we cannot purge on your behalf.</li>
              <li>Encrypted D1 backups in Cloudflare R2 are not subject to a verified post-deletion purge in the current backup process.</li>
              <li>The server-side deletion steps are sequential rather than transactional. If a request fails, part of the sequence may remain until deletion is retried or support assists.</li>
            </ul>
            <p className="text-slate-400">The mobile app attempts to clear its local account data after the server request, but local cleanup is separate from the server transaction. Account deletion is irreversible and the account cannot be restored.</p>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">09</span> Do Not Track Signals
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            We do not track you across third-party websites or apps for advertising, and we run no ad code on this website, so a browser &ldquo;Do Not Track&rdquo; signal changes nothing about how secretmsg.net treats you. We also do not respond to a Do Not Track signal from your browser as an advertising opt-out inside the Android app, because the app&apos;s ads are requested by Google&apos;s SDK on your device. Use the controls in section 03 to change ad personalisation: reset or restrict your advertising ID in Android Settings, use Google&apos;s ad settings, decline consent in the app, or buy ad-free access once.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">10</span> Children&apos;s Privacy
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            SecretMsg is not directed to children under 13, or to a higher minimum age where local law requires it. Users aged 13–17 may use the service only with parent or legal-guardian permission and in compliance with applicable law. We do not knowingly collect personal information from an under-13 user. Because the Android app requests ads, the consent and opt-out controls described in section 03 apply to users of any age, and we do not knowingly serve personalised ads without consent. If we learn that an under-13 user submitted personal information, or that a child used the app, a parent or guardian may contact us at <a href="mailto:safety@secretmsg.net" className="text-indigo-400 underline font-mono">safety@secretmsg.net</a> to request review and deletion. Our child-safety reporting and escalation policy is published at <Link to="/p/child-safety-policy" className="text-indigo-400 underline">secretmsg.net/p/child-safety-policy</Link>.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">11</span> Data Retention &amp; Security Practices
          </h2>
          <ul className="list-disc list-inside space-y-1.5 text-xs sm:text-sm text-slate-400">
            <li><strong className="text-slate-200">Pairing Codes:</strong> A code is usable for approximately 5 minutes. Expired rows are removed by the next scheduled cleanup; consumed rows remain for at least 24 hours and are removed by the first scheduled cleanup after that threshold.</li>
            <li><strong className="text-slate-200">Email Login Codes:</strong> A legacy email code is valid for 15 minutes. Its hashed session row is rejected after expiry and removed by the next scheduled cleanup, so physical row deletion is not guaranteed at the exact expiry second.</li>
            <li><strong className="text-slate-200">Rate Limits:</strong> A rate-limit counter stops counting after its applicable window, which is currently between 1 minute and 1 hour. Rows whose window began more than 2 hours earlier are removed by the nightly cleanup.</li>
            <li><strong className="text-slate-200">Messages and Reports:</strong> Messages remain until the recipient or Account User deletes them or the Account User deletes the account. Reports remain pending or resolved in D1 until account deletion; separate legal-preservation requirements may apply.</li>
            <li><strong className="text-slate-200">Accounts and Push Tokens:</strong> Account records remain while the account is active. FCM tokens remain until push is unregistered, a stale token is cleared, or the account is deleted.</li>
            <li><strong className="text-slate-200">Ad-Free Entitlement:</strong> The record of your <code className="text-slate-200 font-mono text-xs">remove_ads</code> purchase is kept with your account so the app can stay ad-free; it is removed when the account is deleted. Google keeps its own copy of the purchase under Google Play&apos;s retention rules.</li>
            <li><strong className="text-slate-200">Ad and Consent Data:</strong> We keep no behavioural advertising profile and no first-party ad analytics. Your ad-consent choice is stored on your device so the app remembers it, and Google retains its own ad-request and measurement data under Google&apos;s policies, outside our control. You can clear the stored choice by clearing app data or reinstalling, and you can ask Google to delete or limit its ad data as described in section 03.</li>
          </ul>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm mt-2">
            Processor retention and legal-preservation periods are controlled independently by the relevant provider and law and may be longer. We use HTTPS for implemented application and processor paths and apply authentication, hashed credentials, access-aware endpoints, rate limits, and other reasonable technical and administrative safeguards.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="text-slate-500 font-mono text-xs">12</span> Inquiries &amp; Data Protection Contact
          </h2>
          <p className="text-slate-400 leading-relaxed text-xs sm:text-sm">
            If you have questions regarding this Privacy Policy, our data practices, or wish to exercise a legal privacy right, contact us at:
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
