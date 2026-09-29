# Privacy Policy for SecretMsg (`secretmsg.net`)

**Last Updated:** September 2026

> **This file is a convenience copy, not the canonical text.** The policy that is
> actually served, prerendered, and shown to users and Google Play reviewers is
> **`https://secretmsg.net/p/privacy/`**, generated from
> `apps/web/src/pages/PrivacyPage.tsx`. The Android app carries a parallel copy
> in `apps/mobile-flutter/lib/data/static_content.dart`. If this markdown and the
> shipped page ever disagree, **the shipped page is correct** — fix the page
> (in the React source) and mirror it here, never the other way round.
>
> Note the canonical URL is `/p/privacy/`, **not** `/privacy`. A bare `/privacy`
> matches the `/:username` route and returns the homepage shell.

At SecretMsg, privacy is not an afterthought or a marketing slogan — it is the foundational design constraint of the architecture. This policy explains what is collected, how it is used, and what is protected.

---

## 1. The Basics: How SecretMsg Works

- **Account Users** create a personalized link (such as `secretmsg.net/yourname`) and share it on Instagram Stories, WhatsApp, TikTok, X, or other channels to invite questions from anyone who has the link.
- **Message Senders** visit that page and submit an anonymous message or question directly, with no account and no login.
- **Public or Private Replies**: the Account User can reply privately through a secure one-time link, or publish an answer on their board and share it elsewhere.
- **Sender Anonymity**: SecretMsg does not ask for or store a sender's name, email address, or social-media handle, and cannot reveal one to the Account User.
- **Optional Sender Clues**: if both the sender and the Account User permit it, SecretMsg may show a broad platform type such as "Mobile / Android". It does not provide precise location or a unique sender identity.

---

## 2. Personal Information We Collect

### A. Information You Provide

- **Account Information**: the primary sign-in method is a handle and a 4–6 digit PIN. An account may also contain a display name, avatar selection, bio, safety settings, hashed PIN and backup-code values, and an account ID.
- **Legacy Email Login**: a real email address is optional and is used only with the legacy email-code login path. Handle/PIN accounts store the synthetic placeholder `<handle>@v2.secretmsg`; it is not a real mailbox and cannot receive email.
- **Questions & Messages**: message text, replies, recipient settings, message timestamps, delivery metadata, and report reasons.
- **Feedback & Support Correspondence**: information you choose to submit when contacting the support or trust & safety team.

### B. Automatically Collected

- **Device & Connection Data**: Cloudflare processes the raw connecting IP and other request data to serve the service. A User-Agent may be used to produce the broad platform clue above. SecretMsg does not collect precise location.
- **Security Verification**: Cloudflare Turnstile receives its challenge response and, when available, the raw connecting IP for account creation, email-code requests, message sends, and reports.
- **Ad Request Data (Android app only)**: when the Android app requests an ad from Google AdMob, Google's Mobile Ads SDK collects the information listed in section 3 — device advertising ID, IP address, device model and OS version, app version, screen resolution, language, and coarse location derived from IP. This happens on your device and in Google's systems. SecretMsg does not build a profile from it and does not join it to your messages or your account record. **This website requests no ads and loads no ad SDK.**
- **Local Storage**: the app and browser may store preferences, drafts, authentication state, cached inbox data, your ad-consent choice, and account-related data on your device. Authentication and the mobile sender value use secure storage where implemented.

### C. Device and Other Identifiers

- **Account ID**: a random SecretMsg account identifier used to operate the account and link account-linked records.
- **FCM Registration Token**: if you enable push notifications, the app may register an FCM token with your account so Google Firebase Cloud Messaging can deliver new-message notifications.
- **App-Generated Sender Value Hash**: the mobile app may generate and store a stable random value once per installation. It is **not** derived from hardware. The app sends the value so the server can store only its SHA-256 hash with a message and, if you block that sender, in your block list. The recipient cannot reverse the hash.
- **Hashed Rate-Limit Identifier**: D1 stores a bucket name plus a SHA-256-derived key based on an IP address, handle, email address, or account ID as applicable. Raw IPs are not stored in readable form in the D1 rate-limit table, but Cloudflare processes the raw IP to serve the request and Turnstile receives it when verification is requested.
- **Advertising ID (Android app only)**: the Google Mobile Ads SDK may read the device advertising ID, a resettable identifier assigned by Android for advertising purposes. This is the one identifier above that is an advertising ID. It is not sent to SecretMsg servers, not linked to your SecretMsg account, and is not a hardware serial number.

Except for that advertising ID, none of these values is a hardware identifier. SecretMsg does not use a first-party analytics SDK and does not run session replay, heatmaps, or clickstream tracking. The Android app does include Google's advertising SDK, which section 3 explains in full.

**Push-preview limit:** for a new message, FCM receives the registered FCM token, a random message ID, the unread-message count, and a message preview truncated by SecretMsg to **140 characters**, with an ellipsis added when truncated. The full message body is never sent through FCM.

---

## 3. Advertising in the Android App

SecretMsg is funded by advertising and by one optional in-app purchase. This section says plainly what that involves, because a project that asks you to trust it with anonymous messages has to be exact about this part.

- **Where ads appear**: ads are served by **Google AdMob**, using the Google Mobile Ads SDK, **in the Android app only** — as a banner and as an optional rewarded video. **This website serves no ads.** `secretmsg.net` loads no Mobile Ads SDK, no ad exchange, and no ad script, so no ad code runs in your browser on desktop or mobile.
- **What an ad request contains**: the request is assembled by Google on your device and includes the device advertising ID, IP address, device model and OS version, app and SDK version, screen size, language, and a coarse location inferred from the IP address. It does **not** include your SecretMsg handle, your display name, your messages, your replies, your contacts, or the identity of anyone who sent you a message. SecretMsg does not join advertising data to message content or to your account record.
- **Identifiers and opting out**: the device advertising ID is a resettable identifier assigned by Android for advertising. You can reset it or limit its use to non-personalised ads in Android Settings, under Privacy → Ads (the exact path varies by device and Android version). Google provides a system-level opt-out, and Google's certified ad-settings page is at `adssettings.google.com`.
- **Personalised versus non-personalised ads**: in the EEA, the UK, and Switzerland, personalised ads are only served if you consent. Without consent, or if you opt out, Google serves non-personalised ads selected without using your advertising ID or your prior activity. Outside those regions the app asks for consent where required, and you can always change your choice in the app's settings.
- **European consent**: where the GDPR, the UK GDPR, or the ePrivacy Directive requires it, the Android app shows a consent management platform before any ad is requested. If you decline, ads are non-personalised or suppressed. Consent can be withdrawn at any time in the app, and withdrawing it stops personalised ads from then on.
- **US state privacy rights**: if you live in a US state with a comprehensive privacy law — including California, Virginia, Colorado, Connecticut, Utah, and others — you may have the right to opt out of the sale or sharing of your personal information, to opt out of targeted advertising, to limit the use of sensitive personal information, and to know what categories were disclosed. Google serves as the ad partner and handles those rights in its own systems; you can exercise them through Google My Ad Center or Ads Settings, or email `privacy@secretmsg.net` and the request will be routed. The Android app also presents an **"Ad privacy options"** entry in Settings, which opens Google's privacy options form so you can change an advertising choice you have already made — withdraw consent, or exercise a US state opt-out, depending on where you are. **It appears only when that choice is actually available to you.**
- **Removing ads**: a single one-time Google Play purchase, `remove_ads`, disables ads in the Android app for your account. It is not a subscription. Purchased ads-free status is stored on your SecretMsg account, so it follows you rather than living on one device.
- **What ads do not mean here**: serving an ad does not give an advertiser, SecretMsg, or Google access to your inbox. Message content, sender identity, and the fact that you use SecretMsg are not disclosed for ad targeting. SecretMsg does not use Firebase Analytics, Crashlytics, session replay, or any first-party analytics SDK, and does not run ad code on this website. The anonymity guarantees in section 1 are unchanged by advertising.

---

## 4. What We Will NEVER Do

- We **never sell, rent, license, or monetize** your personal information, messages, or emails to advertisers or third-party data brokers. Ad revenue is generated by Google selling ad placements, not by us selling your data.
- We **never disclose a sender's name or account** to the recipient, because we do not ask for one, and we **never pass message content to the ad network**.
- We **never run advertising pixels, ad tags, or ad code on this website**, and we do not do cross-site behavioral advertising: SecretMsg does not follow you around other sites or apps.
- We **do not use a first-party analytics SDK** — no Firebase Analytics, no Crashlytics, no session replay, no heatmaps.

---

## 5. How We Use Your Information

- **Providing the Services**: to authenticate accounts, deliver messages and replies, maintain private inboxes, publish user-chosen public answers, generate story sticker cards, and send optional push notifications.
- **Platform Safety & Abuse Prevention**: to apply recipient-configured hidden-word filters, quarantine or reject messages, operate recipient-specific sender blocks, store reports, and enforce rate limits.
- **Customer Support**: to answer questions, resolve account issues, and respond to safety inquiries.
- **Advertising**: to request ads from Google AdMob in the Android app, and to honour the ad-consent choice and any opt-out signal you have expressed, as described in section 3.
- **Payments & Support**: to verify the Google Play `remove_ads` purchase and record the resulting ad-free entitlement on your account.
- **Legal Compliance**: to comply with legal obligations, enforce our terms, preserve relevant records, and cooperate with law enforcement when required by law.

---

## 6. Automated Safety & Content Moderation

SecretMsg uses a send-time Cloudflare Turnstile check and recipient-configured hidden-word filtering. In the standard setting, a matching message is quarantined for the recipient's review; in strict mode, it is rejected and quarantined.

The filter is rules-based. It does not use automated machine-learning classification, does not understand context, and **cannot be represented as a comprehensive detector of CSAM, grooming, or other abuse**. Recipients can report or block a message: reporting quarantines it and records the report reason; blocking stores the sender-fingerprint hash in that recipient's block list and removes the message.

---

## 7. How Information Is Shared

- **Public Social Sharing by Users**: when an Account User posts a response publicly, the question and answer become visible on their public Q&A thread and wherever they share it on social media.
- **Service Processors**:
  - **Cloudflare** — hosts the API and may process request content, headers, and the raw connecting IP. Cloudflare D1 stores account, message, report, purchase, and security records. Cloudflare Turnstile receives the challenge response and raw connecting IP when verification is requested. The operator backup process may upload an encrypted D1 export to Cloudflare R2.
  - **Resend** — only when the legacy email-code path is used, receives the real email address and the six-digit login code for delivery. The current handle/PIN path stores a synthetic placeholder and sends no login email.
  - **Google Play Billing** — when the ad-free purchase is verified, SecretMsg sends the purchase token and product ID to Google. Google returns purchase state and an order ID when available. Play processes payment details; SecretMsg does not receive or store card details.
  - **Google Firebase Cloud Messaging** — receives the registered FCM token, a random message ID, the unread count, and the server-truncated 140-character preview described above. Full message bodies are not sent through FCM.
  - **Google AdMob (Android app only)** — both our advertising partner and a processor of ad-request data. Its SDK runs in the Android app and receives the device advertising ID, IP address, device and OS details, app version, and coarse IP-derived location, as set out in section 3. It does **not** receive your message content, replies, handle, or display name. Google acts as an independent controller for its own advertising purposes and its own systems, which are outside our control. `secretmsg.net` does not load this SDK. AdMob may return aggregated, non-identifying impression and revenue statistics to the app so we can measure whether ads are worth keeping. A verified `remove_ads` purchase stops ad requests entirely.
- **Compliance & Safety**: relevant information may be disclosed where we believe in good faith it is necessary to comply with valid legal process, prevent imminent harm, enforce our terms, or protect users. Records may also be preserved for a valid legal process.

---

## 8. Your Rights & Choices (GDPR & CCPA)

Depending on your location, you may have rights to access, correct, export, restrict, object to, or request deletion of personal information. Display name, avatar, and safety settings can be updated directly in the app; contact us for other access, correction, or export requests.

- **Access & Portability**: request details about data associated with your account and a copy of eligible account data.
- **Correction**: update profile and safety fields directly; contact us for other stored account information.
- **Deletion**: request deletion through the in-app control or the public deletion page.
- **Object & Restrict**: object to processing based on legitimate interests, including advertising, and ask us to restrict a use of your data.
- **Consent Withdrawal**: where we rely on consent, including for personalised ads in the EEA and the UK, withdraw it at any time in the app without affecting processing carried out before withdrawal. Declining consent leaves you on non-personalised ads rather than locking you out.
- **US State Opt-Outs**: California and other US state residents may opt out of the sale or sharing of personal information, opt out of targeted advertising, limit the use of sensitive personal information, and request deletion. Google handles these rights for ad data through `adssettings.google.com` and My Ad Center, and the app presents an **"Ad privacy options"** control in Settings that opens Google's privacy options form, shown only when the SDK reports a choice is available. Email `privacy@secretmsg.net` to reach us instead. SecretMsg does not knowingly sell or share the personal information of users under 16.
- **Ad-Free Access**: a one-time `remove_ads` purchase in the Android app stops ad requests being made by the app. There is no subscription to cancel and no recurring charge.

### Self-Service Account Deletion

Open **Settings → Delete Account**, or use the public page at `secretmsg.net/delete-account`. A full signed-in session is required.

After a successful request, SecretMsg deletes the received messages, blocked-sender records, reports involving the account as recipient or reporter, pairing codes, purchase records including the ad-free entitlement, email-keyed one-time-code sessions, identifiable account-derived rate-limit rows, and finally the primary D1 account row — which includes the handle, profile, PIN hash, FCM token, and stored email field. For a handle/PIN account, deleting the email field removes the synthetic `<handle>@v2.secretmsg` placeholder; no deletion message is sent because it is not a mailbox. For a legacy account, the real email is removed from the D1 account row, but provider-side copies are outside this operation.

**Deletion limits** — this is **not** universal erasure:

- IP-keyed rate-limit rows that cannot be mapped to the account are not explicitly purged and remain under their retention window and scheduled cleanup.
- Copies you exported, downloaded, saved, posted elsewhere, or shared with another service cannot be retracted.
- Records held independently by Google Play, Google AdMob, Resend, Cloudflare, or other providers are not erased by the SecretMsg endpoint. Ad-related data held by Google is removed or limited through Google's own settings and opt-out tools, which we cannot purge on your behalf.
- Encrypted D1 backups in Cloudflare R2 are not subject to a verified post-deletion purge in the current backup process.
- The server-side deletion steps are sequential rather than transactional. If a request fails, part of the sequence may remain until deletion is retried or support assists.

The mobile app attempts to clear its local account data after the server request, but local cleanup is separate from the server transaction. **Account deletion is irreversible and the account cannot be restored.**

---

## 9. Do Not Track Signals

SecretMsg does not track you across third-party websites or apps for advertising, and runs no ad code on this website, so a browser "Do Not Track" signal changes nothing about how `secretmsg.net` treats you.

A Do Not Track signal from your browser is also **not** treated as an advertising opt-out inside the Android app, because the app's ads are requested by Google's SDK on your device. To change ad personalisation: reset or restrict your advertising ID in Android Settings, use Google's ad settings, decline consent in the app, or buy ad-free access once.

---

## 10. Children's Privacy

SecretMsg is not directed to children under 13, or to a higher minimum age where local law requires it. Users aged 13–17 may use the service only with parent or legal-guardian permission and in compliance with applicable law. SecretMsg does not knowingly collect personal information from an under-13 user.

Because the Android app requests ads, the consent and opt-out controls in section 3 apply to users of any age, and personalised ads are not knowingly served without consent. If an under-13 user submitted personal information, or a child used the app, a parent or guardian may contact **`safety@secretmsg.net`** to request review and deletion. The child-safety reporting and escalation policy is published at `secretmsg.net/p/child-safety-policy`.

---

## 11. Data Retention & Security Practices

- **Pairing Codes**: usable for approximately 5 minutes. Expired rows are removed by the next scheduled cleanup; consumed rows remain for at least 24 hours and are removed by the first scheduled cleanup after that threshold.
- **Email Login Codes**: a legacy email code is valid for 15 minutes. Its hashed session row is rejected after expiry and removed by the next scheduled cleanup, so physical row deletion is not guaranteed at the exact expiry second.
- **Rate Limits**: a counter stops counting after its applicable window, currently between 1 minute and 1 hour. Rows whose window began more than 2 hours earlier are removed by the nightly cleanup.
- **Messages and Reports**: messages remain until the recipient or Account User deletes them, or the Account User deletes the account. Reports remain pending or resolved in D1 until account deletion; separate legal-preservation requirements may apply.
- **Accounts and Push Tokens**: account records remain while the account is active. FCM tokens remain until push is unregistered, a stale token is cleared, or the account is deleted.
- **Ad-Free Entitlement**: the record of a `remove_ads` purchase is kept with the account so the app can stay ad-free; it is removed when the account is deleted. Google keeps its own copy of the purchase under Google Play's retention rules.
- **Ad and Consent Data**: SecretMsg keeps no behavioural advertising profile and no first-party ad analytics. The ad-consent choice is stored on your device so the app remembers it, and Google retains its own ad-request and measurement data under Google's policies, outside our control. Clearing app data or reinstalling clears the stored choice.

Processor retention and legal-preservation periods are controlled independently by the relevant provider and law and may be longer. SecretMsg uses HTTPS for implemented application and processor paths and applies authentication, hashed credentials, access-aware endpoints, rate limits, and other reasonable technical and administrative safeguards.

---

## 12. Inquiries & Data Protection Contact

**SecretMsg Privacy & Data Protection** — `privacy@secretmsg.net` · `support@secretmsg.net`

For abuse, harassment, or content removal, contact `abuse@secretmsg.net`.
