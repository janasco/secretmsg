# SecretMsg Google Play Data safety

> Provenance: re-derived from the current `secretmsg-private/api` Worker, D1
> schemas, Flutter `pubspec.yaml`/`pubspec.lock`, Android manifest, the pinned
> `google_mobile_ads` package in the local pub cache, and current Flutter client
> code. This document must be re-verified against the code, merged Android
> manifest, provider configuration, **the AdMob console and Play Console
> account settings**, live database, and release build before every release and
> Play submission. Code-derived claims are not a substitute for the current Play
> Console taxonomy, the AdMob account configuration, or the final APK's merged
> permissions.
>
> **Line references in this annex are only as good as the code they cite.**
> The `lib/ads/` layer was under active development while this revision was
> written, so its `file:line` references were re-checked at the end of the
> pass. Re-check them before relying on any of them. Reference a symbol name
> where you can, not only a line.
>
> **Business-model change (v1.6.10+ / next Play submission).** SecretMsg moved
> from a no-ads model to an ad-supported model. Google AdMob (Google Mobile Ads
> SDK) now runs **in the Android app only** — a banner and a rewarded video. The
> website at `secretmsg.net` serves no ads. A one-time Play product,
> `remove_ads`, grants an ad-free experience. The four previous products
> (`verified_badge`, `viewer_hints`, `sender_hints`, `supporter_bundle`) are
> **retired**, and Polar has been **removed entirely** as a donations processor.
> Every "no ads" statement that stood in the previous revision of this annex is
> now false and has been replaced below.

## Top-level Play form questions

### Does the app collect or share any of the required user data types?

**Yes.** The app collects account information, user IDs, messages, app
activity/interaction data, purchase history, and device or other identifiers
including the **advertising identifier**, and it now processes **advertising**
data through Google AdMob.
It shares data with infrastructure and payment, email, verification, push, and
**advertising** processors as described below. Some categories are optional
depending on the account and features used, and all ad processing is optional
in the sense that a user who buys `remove_ads` is not shown ads.

### Is all collected user data encrypted in transit?

**Yes, for the implemented application and processor paths.** The Flutter
client uses `https://api.secretmsg.net`; the Worker uses HTTPS when calling
Turnstile, Resend, Google APIs, and FCM. The Google Mobile Ads SDK uses TLS for
ad requests, but that is Google's implementation and is not verifiable from
this repository — see "Cannot be determined from code". This does not mean all
copies at rest are universally erased or that local device storage is encrypted
by the app; the local token and device fingerprint use
`flutter_secure_storage`, while inbox, outbox, and gamification state use
`SharedPreferences`.

### Can users request deletion of their data?

**Yes, for SecretMsg's own data.** Settings → Delete my account calls
`DELETE /api/account`. Once the sequence completes, the primary D1 user row and
session validity are deleted and the request is immediate and irreversible for
that D1 row. This is not a universal erasure: IP-keyed rate limits, local
mobile data, external processor records, and encrypted backups may remain, as
detailed below.

**Ad-specific deletion caveat.** The in-app delete flow does not and cannot
delete anything Google holds about the advertising identifier. Resetting the
advertising identifier and adjusting the AdMob consent state are
**device/Google-side** actions the user must take in Android Settings → Privacy
→ Ads. There is no in-app control for this and none is claimed. The app must
not claim otherwise in its UI or in the Play listing.

## Advertising declaration (App content → Ads)

- **Contains ads:** **Yes.** Declare the app as containing ads. The banner and
  rewarded video are real ad surfaces, not house-ad placeholders.
- **Ad network:** Google AdMob / Google Mobile Ads SDK, reached through the
  Flutter plugin `google_mobile_ads` (`^9.1.0`, resolved to `9.1.0` in
  `pubspec.lock`).
- **Ad formats used:** banner and rewarded video. Interstitial, app-open,
  rewarded interstitial, and native ads are not part of the agreed scope; if
  the release build shows any of them, this declaration is wrong and must be
  re-derived. The banner is a fixed 50 dp slot (`kBannerHeight` in
  `lib/ads/ads_config.dart`) mounted inside the shell's `bottomNavigationBar`
  column, directly **above** the custom notch navigation bar
  (`lib/screens/app_shell.dart:105`).
- **AdMob identifiers are build-time inputs and no value is committed.** The
  manifest declares `com.google.android.gms.ads.APPLICATION_ID` as the
  `${admobAppId}` manifest placeholder, substituted by
  `android/app/build.gradle` from `-PadmobAppId` / `ADMOB_APP_ID`; the banner and
  rewarded ad unit ids reach Dart as `--dart-define` values read at
  `lib/ads/ads_config.dart:14-16`. The all-zero `ca-app-pub-0000000000000000`
  value is only a *fallback* used for debug and local builds. A release build
  that would carry a placeholder is **refused by Gradle** before any artifact is
  produced, and `MobileAdsPlatform.initialize` throws if the identifiers are
  still unset at runtime, so the SDK can never initialize with unusable ids.
  `scripts/build_release.sh` is the canonical invocation and feeds both layers
  from one set of environment variables. **The real IDs must be supplied at build
  time for an ad-supported submission, and they are operator facts of the
  console, not code facts.**
- **The ads kill-switch is fail-closed and currently unsatisfied.** Ads are
  gated on a public server flag read from `/api/config/ads`
  (`lib/api/config.dart:12`), cached for six hours in `SharedPreferences` under
  `ads_enabled` / `ads_enabled_fetched_at` (`lib/ads/ads_config.dart:8-10`,
  `lib/ads/ads_flags.dart`), and default to **off** when the server says
  nothing (`kAdsEnabledWithoutServerFlag = false`, `lib/ads/ads_config.dart:11`;
  resolver at `lib/ads/ads_flags.dart:73-88`). **That endpoint does not exist in
  the Worker at the time of this re-derivation, so the current build resolves to
  ads-off.** Serve can also be suppressed per screen. This is a useful safety
  property, and it also means a build can be technically "ad-enabled" while
  serving nothing — verify with real fill before trusting a zero-impression
  result in either direction.
- **Web:** the website shows no ads. Do not declare app ads for the website.
- **AdMob account, `ads.txt`, and consent configuration** are operator tasks
  recorded in [SUBMISSION.md](SUBMISSION.md); none of them can be verified from
  code.

## Play data types

The "Shared" answers use a conservative processor-disclosure reading. Whether
developer-operated Cloudflare hosting is treated as a Play "sharing" transfer
is a Play-policy judgment call, but the processor facts are declared here
regardless.

### Personal info — name, email address, user IDs, and other personal information

- **Collected:** Yes.
- **Shared:** Yes. Cloudflare Workers/D1 receives the account and request data;
  Resend receives a real email and OTP for the legacy email-OTP path; the
  Cloudflare Turnstile verifier receives the challenge response and, when
  available, the raw connecting IP. Google AdMob receives the device's
  advertising identifier and IP-derived request data as part of an ad request,
  which it treats as a user identifier for ad selection and measurement. Other
  processors may receive a user ID or token as part of their function.
  **Polar has been removed and is no longer a processor.**
- **Required or optional:** The handle and 4–6 digit PIN are the primary APK
  sign-in method and are required for the normal handle account. A real email
  is optional and is not required for the APK-only handle/PIN flow. Display
  name, avatar seed, bio, hidden words, and notification and moderation
  settings are optional depending on use. The ad identifier is present only when
  the ad SDK initialises and an ad is requested, and a user who has bought
  `remove_ads` is not shown ads.
- **Purpose:** Account creation, authentication, recovery, profile display,
  account management, moderation and safety preferences, **ad serving and
  measurement**, and payment verification.
- **Where stored:** `api/schema.sql` and `db/schema.sql`, `users`:
  `id`, `username`, `display_name`, `email`, `avatar_seed`, `bio`, `pin_hash`,
  `backup_codes`, `backup_codes_used`, `auth_method`, `token_version`,
  `fcm_token`, `created_at`, and `updated_at`; `users.hidden_words`,
  `allow_hints`, `paused_until`, and `mod_sensitivity` for preferences. Real
  email OTP sessions are in `auth_sessions.email`, `auth_sessions.otp_code`,
  and `auth_sessions.expires_at`; the PIN and OTP values are stored as
  hashes. Handle signup stores the synthetic placeholder `<handle>@v2.secretmsg`
  in `users.email`; it is not a real mailbox. Purchase-linked records are in
  `purchases.user_id` and `purchases.purchase_token`. **AdMob holds no record
  in this database; nothing ad-related is written to D1.**
- **Processors:** Cloudflare Workers/D1; Cloudflare Turnstile for signup, OTP
  requests, message sends, and reports; Resend for real-email OTP delivery;
  Google Play Developer API for purchase verification and acknowledgement;
  Firebase Cloud Messaging for push registration and delivery; **Google AdMob /
  Google Mobile Ads for ad serving and measurement**. Polar is no longer
  listed because Polar is no longer used.

**APK/web authentication distinction:** The web client has `requestOtp` and
`verifyOtp` methods, but the current Flutter login, registration, and recovery
screens call handle/PIN, backup-code, and Turnstile flows instead. The legacy
real-email OTP flow is reachable on the web login page, not exposed in the
current Flutter APK UI. For the APK-only form, no real email is collected; a
handle account can use the synthetic placeholder.

### Financial info — purchase history

- **Collected:** Yes, when a user buys or restores the `remove_ads` one-time
  product.
- **Shared:** Yes. The client sends a Google Play purchase token and product ID
  to the API; the Worker sends the purchase token to Google Play Developer
  API for verification and acknowledgement. Cloudflare Workers/D1 receives the
  request and stores the resulting purchase record. Google Play processes the
  purchase; SecretMsg does not receive card details.
- **Required or optional:** Optional. Only users who purchase or restore
  `remove_ads` provide purchase data. No card number, bank account, or
  payment-card details are collected by SecretMsg. The purchase is a purchase
  of the removal of ads, not a donation.
- **Purpose:** Verify purchase state, prevent replay across accounts, **grant
  and persist the ad-free entitlement**, and acknowledge the purchase to Google
  Play.
- **Where stored:** `api/schema.sql` and `db/schema.sql`, `purchases`:
  `purchase_token`, `order_id`, `user_id`, `product_id`, `state`,
  `acknowledged_at`, and `created_at`. **The ad-free entitlement is currently
  read from the profile's `isPremium` flag** (`lib/ads/ads_service.dart:95`),
  which is the column the retired perk products wrote to, not a
  `remove_ads`-specific entitlement column. Neither `PLAY_PRODUCTS` nor the
  client's `BillingProducts` contains `remove_ads` yet — see "Known gaps".
- **Processors:** Google Play Developer API and Google Play Billing;
  Cloudflare Workers/D1. Google Play processes the purchase; SecretMsg does
  not receive card details.

### Supporter donations — removed

**This section previously described a Polar web donation flow and a
`donations` table. Both are retired and must not be declared on the Play form.**
There is no donations processor, no donor alias, no donor note, and no
supporter tiers. The only monetisation path in the app is the one-time
`remove_ads` product above.

Residual code observed at the time of this re-derivation, which must be removed
or confirmed dormant before the ad-supported build is submitted:

- `api/src/polar.ts` (Polar webhook signature verification) and the
  `POLAR_WEBHOOK_SECRET` binding in `api/src/db.ts`.
- `POST /api/webhook/polar` and `GET /api/supporters` in the Worker.
- The `donations` table in `api/schema.sql` and `db/schema.sql`, and the
  fail-closed `POST /api/donation/google-pay` (HTTP 501) endpoint.
- The `users.is_premium`, `users.badge_title`, `users.has_verified_badge`,
  `users.has_viewer_hints`, and `users.has_sender_hints` columns, which exist
  only to serve the retired perk products.

Until that removal lands, historical `donations` rows may still exist in
production D1. Existing rows are not a Play "collection" of new data, but they
should be deleted or the endpoint disabled so the declared practice matches the
shipped build.

### Advertising — ad requests, ad interaction, and measurement

This is the Play data type that the previous revision of this annex denied
existed. It now exists.

- **Collected:** Yes, when the ad SDK initialises and an ad is requested. The
  app requests a 50 dp banner (`lib/ads/ads_config.dart:13`) and a rewarded
  video; each request causes Google to process the device's advertising
  identifier and network information, and each rendered ad generates
  interaction events (impression, click, and the rewarded-video
  completion or dismissal the app uses to grant its reward). **The reward is a
  streak freeze** (`lib/ads/ads_service.dart:175`,
  `lib/ads/ads_config.dart:63-73`, capped at one by `kMaxStreakFreezes`), and it
  is recorded only as local ritual state in `SharedPreferences` via
  `lib/ritual/streak_store.dart` — never sent to Google and never written to D1.
- **Shared:** Yes. Google AdMob / Google Mobile Ads receives the ad request
  and the resulting interaction data. This is a **transfer to an independent
  third party**, disclosed conservatively. Google AdMob is an ad platform, and
  describing it as a GDPR "processor" is a characterization this annex does not
  make; it is disclosed as a third-party recipient.
- **Required or optional:** Optional. Ad serving is not required to use the
  messaging feature. A user who has bought `remove_ads` receives no ad requests
  and generates no ad interaction data. Ads are also suppressed when the remote
  kill-switch is off, when consent is unknown or unavailable, and on suppressed
  screens, so ad processing is conditional rather than unconditional.
- **Purpose:** Advertising or marketing — selecting and serving banner and
  rewarded-video ads, and measuring ad performance (impressions, clicks,
  completion). This is not app functionality and must not be declared as such.
- **Where stored:** No ad interaction data is written to the SecretMsg D1
  database. The only ad-related on-device state is the six-hour kill-switch
  cache (`ads_enabled`, `ads_enabled_fetched_at` in `SharedPreferences`), which
  stores a boolean, not ad interaction data.
- **Processors / recipients:** Google AdMob / Google Mobile Ads. Ad
  **mediation** partners are not named in this repository; if the AdMob account
  enables mediation or Ad Manager, additional ad partners become recipients and
  this section must be rewritten before submission.

### Personalisation, consent, and regional opt-out

- **Non-personalised by default:** ads are requested as **non-personalised**
  unless and until the user gives consent. This is implemented in the client:
  `AdsRequestPolicy.forConsent` sets `nonPersonalised` to true for every consent
  state other than `obtained`, and hard-codes X; the rewarded ad
  request passes `nonPersonalizedAds: request.policy.nonPersonalised`
  (`lib/ads/mobile_ads_platform.dart:103`). The ad request also sets an empty
  keyword list, so no content-derived targeting parameter is transmitted.
  Personalised ads must not be enabled without a recorded lawful basis.
- **EEA/UK:** consent is gathered through Google UMP before any ad is served.
  `ConsentInformation.instance.requestConsentInfoUpdate` is called with
  `ConsentRequestParameters(tagForUnderAgeOfConsent: false)`
  (`lib/ads/mobile_ads_platform.dart:34-40`), a consent form is shown when one
  is required (`lib/ads/mobile_ads_platform.dart:57-78`), and the resulting
  state is `obtained`, `notRequired`, `denied`, or `unavailable`. Serving is
  refused while the state is `unknown` or `unavailable`, so a consent failure
  results in no ad rather than a personalised ad
  (`canServeAds`, `lib/ads/ads_config.dart:47-61`). The UMP message text and the
  GDPR legal basis are configured in the AdMob console and are **not
  determinable from code**.
- **US state privacy laws:** the client calls
  `ConsentInformation.instance.canRequestAds()` after the consent flow
  (`lib/ads/mobile_ads_platform.dart:80-83`) and treats a negative result as
  `denied`, which suppresses ads. `getPrivacyOptionsRequirementStatus()` and
  `ConsentForm.showPrivacyOptionsForm()` exist in the pinned package and are
  **not** called in the client at the time of this re-derivation. Whether that
  is sufficient is a legal question this annex does not answer; if it is not,
  the US opt-out form must be surfaced and this section rewritten. Confirm with
  counsel rather than assuming.
- **Advertising identifier reset:** the advertising identifier can be reset by
  the user in Android Settings → Privacy → Ads, and on Android 13+ it is
  replaced by a resettable app-scoped identifier. This is stated in the app's
  privacy text so the Play declaration and the user-facing text agree.
- **Do not overstate:** SecretMsg does not and cannot guarantee that no
  personalisation occurs for a user who has consented, and it does not claim to
  do so in the listing or the app UI.

### App activity — app interactions and in-app activity

- **Collected:** Yes. This category is collected even though there is no
  analytics SDK, and it now also includes ad interaction events, which are
  declared separately under **Advertising** above so the two are not conflated.
- **Shared:** Yes. Cloudflare Workers/D1 receives and stores or evaluates
  interaction data. Cloudflare infrastructure may also retain operational
  request logs. Ad interaction events go to Google AdMob under the Advertising
  section, not to D1.
- **Required or optional:** Optional and feature-dependent. Profile views,
  messages, replies, reports, pairing, and rate-limited actions are recorded
  when those features are used. Ad interaction is recorded only when an ad is
  served.
- **Purpose:** Abuse prevention, rate limiting, inbox moderation, ranking and
  profile statistics, pairing, and account security. Ad-related purpose is
  declared under Advertising.
- **Where stored:** `users.views_count`, `users.received_count`, and
  `users.replies_count`; `rate_limits.id`, `rate_limits.count`,
  `rate_limits.window_start`, and `rate_limits.updated_at`; `messages.created_at`
  and `messages.reply_at`; `reports.created_at`; `pair_codes.created_at`,
  `pair_codes.expires_at`, and `pair_codes.consumed_at`; and `users.created_at`
  and `users.updated_at`. The Flutter client also stores local inbox cache,
  offline outbox, and gamification state under `SharedPreferences` keys in
  `lib/sync/cache.dart` and `lib/sync/outbox.dart`.
- **Processors:** Cloudflare Workers/D1 and Cloudflare operational logging.
  FCM receives unread count as part of a new-message push. Google AdMob receives
  ad interaction events as declared under Advertising.

### Messages — other in-app messages

- **Collected:** Yes. The service accepts text messages, replies, report text,
  and moderation state. No photo, video, or audio attachment is accepted.
- **Shared:** Yes. Cloudflare Workers/D1 receives and stores message data;
  Cloudflare Turnstile receives the challenge response and raw connecting IP;
  FCM receives the recipient's FCM token, message ID, unread count, and a
  server-truncated message preview of up to 140 characters (plus an ellipsis
  when truncated). The full message body is not sent through FCM.
  **Message content is not passed to Google AdMob and is not disclosed in any ad
  request.** No custom or additional ad-targeting parameters carrying message
  content, handles, or profile fields are set on ad requests. This must be
  re-checked whenever the ad code changes.
- **Required or optional:** A message is required to use the anonymous
  messaging feature, but collecting messages is optional for an account that
  only uses other features.
- **Purpose:** Delivery, inbox display, anonymous replies, filtering,
  moderation, abuse reporting, and push notification previews.
- **Where stored:** `api/schema.sql` and `db/schema.sql`, `messages`:
  `id`, `recipient_id`, `content`, `reply_token`, `client_msg_id`,
  `reply_content`, `reply_at`, `is_public_reply`, `parent_id`, `thread_id`,
  `is_pinned`, `is_read`, `device_hint`, `sender_fp_hash`, `quarantined`,
  `quarantine_reason`, and `created_at`; `blocked_senders.recipient_id`,
  `blocked_senders.sender_fp_hash`, and `blocked_senders.created_at`;
  `reports.message_id`, `reports.reason`, `reports.reporter_id`, and
  `reports.created_at`.
- **Processors:** Cloudflare Workers/D1, Cloudflare Turnstile, and Firebase
  Cloud Messaging for push previews. The sender is not asked for a name, but
  the server still stores `sender_fp_hash`, `client_msg_id`, `reply_token`,
  and conditionally `device_hint` along with the message.

### Device or other IDs — device identifiers, advertising ID, user IDs, and FCM tokens

- **Collected:** Yes. This now includes the **advertising identifier**, which
  the previous revision of this annex did not have to declare.
- **Shared:** Yes. Cloudflare Workers/D1 receives account IDs, FCM tokens,
  hashed sender fingerprints, and rate-limit keys. FCM receives the registered
  FCM token plus message push data. Turnstile receives the raw connecting IP
  when verification is requested. **Google AdMob / Google Mobile Ads receives
  the device's advertising identifier on each ad request and returns the ad
  selected for that identifier; that identifier is used by Google for ad
  selection, frequency capping, and measurement, and may be used across its own
  advertising properties.**
- **Required or optional:** `users.id` is required for an account. FCM token
  registration is optional and occurs when push registration succeeds. The
  sender fingerprint and blocked-sender hash are optional feature data used
  for sender blocking. Rate-limit identifiers are collected as security data
  when protected endpoints are used. **The advertising identifier is optional
  and ad-dependent: it is processed only when the ad SDK initialises and an ad
  is requested, and not at all for a user who has bought `remove_ads`.** A user
  can also reset or limit it in Android Settings → Privacy → Ads, and on
  Android 13+ the OS may substitute a resettable app-scoped identifier.
- **Purpose:** Account identification, push delivery, anonymous sender
  blocking, abuse prevention, rate limiting, and session protection; plus, for
  the advertising identifier, **ad serving and measurement** (ad selection,
  capping, frequency control, impression/click measurement, and fraud
  prevention).
- **Where stored:** `users.id` and `users.fcm_token`; `messages.sender_fp_hash`;
  `blocked_senders.sender_fp_hash`; and `rate_limits.id`, whose format is
  `<bucket>:<sha256(identifier)>`. The hashed identifiers can be based on IP
  address, handle, email, or account ID. The raw app-generated device
  fingerprint is local in Flutter secure storage under the
  `secretmsg_device_fingerprint` key; the Worker stores only its SHA-256
  hash. `device_hint` values such as "Mobile / Android" are coarse platform
  labels, not unique identifiers, and are not the basis of this declaration.
  **The advertising identifier is never written to the SecretMsg D1 database
  and is not derived from `secretmsg_device_fingerprint`.** It is read and
  transmitted by the Google Mobile Ads SDK, not by SecretMsg code.
- **Processors:** Cloudflare Workers/D1 and Cloudflare infrastructure;
  Firebase Cloud Messaging for FCM token registration and push delivery;
  Cloudflare Turnstile for raw-IP verification; **Google AdMob / Google Mobile
  Ads for the advertising identifier.** A processor receives the hashed form
  stored in D1, not a raw device fingerprint.

### App info and performance — diagnostics and crash data

**This section previously asserted that no analytics, ads, crash reporter, or
attribution SDK was present. The "no ads SDK" half of that is no longer true
and has been corrected below. The no-analytics, no-crash-reporter,
no-attribution findings were re-verified and remain true.**

- **Collected:** No app analytics, crash, performance, or attribution SDK is
  present. Firebase **Messaging** is present, but Firebase Analytics and
  Crashlytics are not. The code has no Sentry, Bugsnag, analytics, or
  attribution SDK. **An ads SDK is now present: `google_mobile_ads`
  `9.1.0`, resolved in `pubspec.lock` and declared at `pubspec.yaml:53`.**
- **Shared:** Not applicable to an app-collected diagnostics/crash type,
  because no app analytics or crash dataset is collected. Cloudflare may hold
  operational logs, including `console.error` output from the Worker,
  independently of the app's SDK posture. **The Google Mobile Ads SDK does
  process its own diagnostics for ad delivery** — SDK version, device and OS
  attributes, network conditions, and ad-request outcomes — and passes them to
  Google. That is a Google-controlled dataset, not a SecretMsg crash dataset,
  and it is disclosed as advertising/ad-serving processing rather than claimed
  as "no data".
- **Required or optional:** Not applicable for a SecretMsg diagnostics dataset.
  Ad-SDK diagnostics are inherent to requesting an ad and are therefore
  ad-dependent, not optional within a session in which an ad is requested.
- **Purpose:** Not applicable to a SecretMsg analytics/crash collection;
  operational errors are used to diagnose service failures. For the ad SDK,
  the purpose is ad delivery reliability and measurement.
- **Where stored:** No SecretMsg analytics or crash dataset or SDK storage is
  identified in `pubspec.yaml` or the Flutter source. Operational logs are
  outside the application database and are not determinable from this
  repository. Ad-SDK diagnostics are held by Google.
- **Processors:** Cloudflare operational logging may be involved; no
  application analytics or crash processor is identified. Google AdMob is a
  recipient of ad-SDK diagnostics.

### Location

- **Collected:** No **by SecretMsg**. The app does not request location
  permission and no location API is used.
- **Shared:** Not applicable for SecretMsg collection. **Caution: Google
  AdMob can derive an approximate location from the request IP address when
  "location" ad targeting is enabled in the AdMob account. That is a
  console setting, not a code fact.** If IP-derived approximate location is
  enabled, it must be declared in the Play form as approximate location
  collected and shared by a processor. Confirm the AdMob console setting
  before submitting and, if enabled, either disable it or declare it.
- **Required or optional:** Not applicable for SecretMsg collection.
- **Purpose:** Not applicable for SecretMsg collection.
- **Where stored:** No location column or location API is identified in
  `api/schema.sql` or `db/schema.sql`. Approximate location derived by Google
  is not stored by SecretMsg.
- **Processors:** None identified in the app code for SecretMsg data. Google
  AdMob may derive approximate location from the request IP; see above.

### Health and fitness

- **Collected:** No.
- **Shared:** Not applicable; no health or fitness data is collected.
- **Required or optional:** Not applicable.
- **Purpose:** Not applicable.
- **Where stored:** No health or fitness fields are present in
  `api/schema.sql` or `db/schema.sql`.
- **Processors:** None identified in the app code.

### Photos and videos

- **Collected:** No by the SecretMsg service. The app can save a
  user-generated sticker to the device gallery through `gal`; it does not
  read or upload the user's existing photos or videos through the service.
- **Shared:** Not applicable for server collection. The operating system and
  the user's selected local gallery destination handle the local save.
- **Required or optional:** Optional and only for saving a generated sticker.
- **Purpose:** Local sticker export.
- **Where stored:** No photo or video column is present in the D1 schemas;
  local gallery storage is outside the D1 database.
- **Processors:** Operating system gallery/storage provider only; no SecretMsg
  photo processor was identified.

### Audio files

- **Collected:** No by the service. Audio playback is a client feature; no
  user audio is accepted or stored by the message API.
- **Shared:** Not applicable for server collection.
- **Required or optional:** Not applicable.
- **Purpose:** Not applicable to user data collection.
- **Where stored:** No audio column is present in the D1 schemas.
- **Processors:** None identified for user audio.

### Files and documents

- **Collected:** No by the service. Text message content and public-page
  content are messages/content, not uploaded files or documents.
- **Shared:** Not applicable for server collection.
- **Required or optional:** Not applicable.
- **Purpose:** Not applicable.
- **Where stored:** No file or document column is present in the D1 schemas.
- **Processors:** None identified for uploaded files.

### Calendar

- **Collected:** No.
- **Shared:** Not applicable; no calendar data is collected.
- **Required or optional:** Not applicable.
- **Purpose:** Not applicable.
- **Where stored:** No calendar column or calendar API is identified.
- **Processors:** None identified in the app code.

### Contacts

- **Collected:** No.
- **Shared:** Not applicable; no contacts are collected.
- **Required or optional:** Not applicable.
- **Purpose:** Not applicable.
- **Where stored:** No contacts column or contacts API is identified.
- **Processors:** None identified in the app code.

### Web browsing

- **Collected:** No browsing history or web-search history is collected by the
  service.
- **Shared:** Not applicable for a SecretMsg browsing-history dataset.
  **Caution: the app renders the public website in a `webview_flutter` WebView.
  Anything that website loads executes inside the app process.** If the site
  ever loads an ad tag, analytics tag, or any other third-party script, that
  code runs inside the Android app and can affect the Play declaration even
  though the "website shows no ads" statement is about the browser. Re-check
  the site's script tags whenever the web app changes; the pairing view and any
  public board link opened in-app are the exposure.
- **Required or optional:** Not applicable.
- **Purpose:** Not applicable.
- **Where stored:** No browsing-history column is present in the D1 schemas.
  The WebView/Turnstile request itself is operational request data, not a
  retained browsing-history store in the application code.
- **Processors:** Cloudflare may process the request infrastructure; no
  browsing-history processor is identified. Third-party scripts loaded by the
  in-app WebView, if any, are determined by the website, not by this repository.

## Children and age treatment

**This is the most policy-sensitive consequence of adding ads. With ads
present, the age treatment that the ad SDK applies is a legal declaration, not
a preference.**

Recorded posture:

1. **The app is not child-directed and must not be declared child-directed.**
   SecretMsg is an anonymous messaging app for a general audience. It hosts
   unrestricted user-generated communication. The target-audience selection in
   Play Console must **exclude every under-13 band**, and the app must not
   request Families designation.
2. **The ad SDK must not be told the request is child-directed.** The client
   hard-codes `childDirected: false` on every ad request
   (`lib/ads/ads_config.dart:35`), so no ad request is tagged as
   child-directed. The SDK-level request configuration sets
   `RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg,
   ageRestrictedTreatment: AgeRestrictedTreatment.unspecified)` and does **not**
   set `tagForChildDirectedTreatment` at all
   (`lib/ads/mobile_ads_platform.dart:17-22`).
   In `google_mobile_ads` `9.1.0`, `tagForChildDirectedTreatment` and
   `tagForUnderAgeOfConsent` are **deprecated** in favour of
   `RequestConfiguration.ageRestrictedTreatment`, whose values are
   `AgeRestrictedTreatment.unspecified`, `.child`, and `.teen`
   (`lib/src/request_configuration.dart` in the pinned package). The client uses
   `.unspecified`, and `AgeRestrictedTreatment.child` is never used anywhere in
   the client. **Honest caveat on the record:** `.unspecified` means "no
   age-restricted signal asserted", not "explicitly teen". If the operator's
   position is that the audience is 13+, `.teen` is the deliberate value and is
   the better declaration; the current code leaves it unspecified. Decide this
   explicitly rather than inheriting the default, and keep it consistent with
   the AdMob console and the target-audience form.
3. **The ad SDK must not be told the user is under the age of consent.** UMP is
   requested with `tagForUnderAgeOfConsent: false`
   (`lib/ads/mobile_ads_platform.dart:35`) and the ad request policy hard-codes
   `underAgeOfConsent: false` (`lib/ads/ads_config.dart:36`). Any user who is in
   fact under the applicable age of consent is a case SecretMsg does not target
   and does not knowingly admit; see the target-audience constraint above.
4. **Ad content rating is set in code to PG.** The client sets
   `MaxAdContentRating.pg` (`lib/ads/mobile_ads_platform.dart:19`). This is a
   **ceiling on what the SDK may return**, and it must be compatible with the
   IARC result for the app. If the IARC questionnaire returns a rating higher
   than PG, either the code ceiling or the questionnaire answer is wrong and one
   must change deliberately — a mismatch here is a policy problem, not a
   cosmetic one. The AdMob console also has its own ad-content-rating setting;
   both must agree.
5. **Ads must be disabled for anyone who buys `remove_ads`, and the entitlement
   must be enforced before an ad is requested** — not merely hidden.
   `canServeAds` returns false when `adFree` is true
   (`lib/ads/ads_config.dart:54`), `applyProfile` tears the banner down when the
   entitlement appears (`lib/ads/ads_service.dart:93-103`), and
   `AdsService.init` short-circuits before the SDK is used at all for an
   entitled profile (`lib/ads/ads_service.dart:105-117`). **However, the
   entitlement currently reads `profile?.isPremium == 1`**
   (`lib/ads/ads_service.dart:95`) — the column written by the retired perk
   products, not a `remove_ads`-specific field. Until `remove_ads` is wired up
   and the entitlement source is explicit, "ad-free" is inherited from a
   legacy flag whose meaning is about to change. Verify this after the billing
   change lands.
6. **Do not use the child-directed or under-consent flags to soften policy.**
   Those flags change ad treatment and legal posture; they are not a
   configuration convenience.

## Known gaps and honest disclosures

1. **The ad SDK and ad surfaces are in the client, but no real AdMob identifier
   has been supplied yet and ads are currently switched off.**
   `pubspec.yaml:53` declares `google_mobile_ads: ^9.1.0`, `pubspec.lock`
   resolves `9.1.0`, and the client has a complete ad layer under `lib/ads/`
   (`ads_config.dart`, `ads_flags.dart`, `ads_platform.dart`,
   `mobile_ads_platform.dart`, `ads_service.dart`, `ads_banner.dart`) plus the
   banner mounted at `lib/screens/app_shell.dart:105`. No AdMob identifier is
   committed; all three are build-time inputs, and the build refuses to produce
   a release artifact without them. As of this re-derivation they have not been
   supplied, so no ad-supported artifact exists, and the `ADS_ENABLED="false"`
   kill-switch keeps ad code paths inert in the meantime. **The declarations in
   this annex describe the agreed and partly implemented target state. They
   become accurate for a Play submission only once the real AdMob ids are
   supplied at build time, the kill-switch is turned on, and the merged manifest
   of the uploaded AAB is re-inspected.** Re-derive this annex against that AAB.
2. **The AdMob account configuration is not verifiable here.** The real
   application id and ad unit ids, `ads.txt` authorization, mediation partners,
   EEA/UK consent message, US state opt-out configuration, console ad content
   rating, console-side child-directed and under-age-of-consent flags, and
   whether IP-derived approximate-location targeting is enabled are all account
   settings. None of them appear in this repository.
3. **Mediation and extra ad partners are unknown.** If AdMob mediation or Ad
   Manager is enabled, additional ad networks become independent recipients and
   the Advertising, Personal info, and Device or other IDs sections all need to
   be expanded. Nothing in the repository indicates which is the case.
4. **`remove_ads` is not yet in the code.** The Worker's `PLAY_PRODUCTS` map
   still contains `verified_badge`, `viewer_hints`, `sender_hints`, and
   `supporter_bundle` (`/opt/secretmsg/secretmsg-private/api/src/billing.ts:8-12`),
   and the client's `BillingProducts` class still lists the same four
   (`apps/mobile-flutter/lib/api/billing.dart:10-21`). Neither side has
   `remove_ads`. The ad-free entitlement is currently read from
   `users.is_premium` via the profile payload (`lib/ads/ads_service.dart:95`),
   so ad suppression is presently keyed to a legacy perk flag. The Financial
   info section above describes the required end state, not the current code.
5. **Polar removal is not yet reflected in the Worker.** `api/src/polar.ts`,
   `POLAR_WEBHOOK_SECRET` in `api/src/db.ts`, `POST /api/webhook/polar`,
   `GET /api/supporters`, the `donations` table in both schemas, the
   fail-closed `POST /api/donation/google-pay`, and the perk columns
   (`is_premium`, `badge_title`, `has_verified_badge`, `has_viewer_hints`,
   `has_sender_hints`) all still exist. See "Supporter donations — removed".
6. **The US privacy-options form is not surfaced.** The client gates ads on
   `ConsentInformation.instance.canRequestAds()` but does not call
   `getPrivacyOptionsRequirementStatus()` or
   `ConsentForm.showPrivacyOptionsForm()`. Whether the resulting behaviour
   satisfies US state opt-out requirements is a legal question this annex flags
   rather than answers.

7. **The rewarded-ad reward is a streak freeze, capped at one.** The client
   exposes `AdsService.showRewardedForStreakFreeze`
   (`lib/ads/ads_service.dart:175`) and gates the offer on
   `canOfferStreakFreezeByAd`, which requires ads to be enabled, a streak of at
   least one day, and fewer than `kMaxStreakFreezes = 1` freeze already held
   (`lib/ads/ads_config.dart:12`, `lib/ads/ads_config.dart:63-73`). The grant
   lands in the local ritual state owned by `lib/ritual/streak_store.dart`.
   This matters for the declaration because the reward is **local device state,
   not a server-side grant**: a streak freeze is not a Play purchase, is not
   stored in D1, and is not restored on a new device. A user who clears app
   data loses it. Do not describe the freeze as something stored in the
   account.
8. **The in-app "no ads" strings are still in the client.** The in-app privacy
   copy states there is no advertising SDK and no advertising ID (see
   `lib/data/static_content.dart` and `lib/screens/supporters_screen.dart`).
   Those strings are now false and must be corrected in the client before the
   ad-supported build ships. Until they are, the app's own text contradicts this
   annex and the Play declaration. This annex does not describe client copy.
9. **Cloudflare scope and Play sharing judgment:** the Worker runs on
   Cloudflare, uses Cloudflare D1, and uses Cloudflare Turnstile. Cloudflare
   receives request content and raw network information, including the raw
   connecting IP used for rate limiting and explicitly sent as Turnstile
   `remoteip`. Cloudflare R2 is used by the operator backup command, not as an
   application runtime binding in `api/wrangler.toml`. Whether developer-
   operated Cloudflare hosting is Play "sharing" is a policy judgment; the
   processor facts are disclosed conservatively above.
10. **Other processors:** Resend receives a real email and six-digit OTP only
   when the legacy email-OTP request succeeds. Google Play receives purchase
   tokens. FCM receives the FCM token and the push payload containing message
   ID, unread count, and a 140-character preview. **Google AdMob receives the
   advertising identifier and IP-derived request data on every ad request plus
   ad interaction events; the donation processor is gone.**
11. **Identifiers and raw IP:** "IP addresses are not stored readable" is only
    locally true in the D1 rate-limit table. D1 stores SHA-256-derived rate-
    limit IDs, but Cloudflare receives the raw IP as infrastructure and the
    Turnstile verifier is explicitly sent the raw connecting IP. AdMob
    separately receives the request IP as part of an ad request.
12. **Authentication:** email is not the only sign-in method and is not
    required. The current primary auth is handle plus a 4–6 digit PIN, with
    backup-code recovery. Real email is optional legacy email OTP and is not
    exposed in the current Flutter APK login UI. Handle signup stores a
    synthetic `<handle>@v2.secretmsg` placeholder.
13. **Message metadata:** senders are not asked for a name, but the app stores
    `sender_fp_hash`, `client_msg_id`, `reply_token`, and conditionally
    `device_hint`; the coarse `device_hint` is not a unique ID.
14. **Runtime and build permissions:** the app requests notification permission
    through Settings on Android 13+ (`POST_NOTIFICATIONS`). The main manifest
    declares `INTERNET`, `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, and
    `RECEIVE_BOOT_COMPLETED`; exact alarms and boot completion support local
    reminders and their restoration. `USE_EXACT_ALARM` is **not** declared — it
    was removed before v1.6.9 and is absent from the merged v1.6.9 release
    manifest. The final merged APK also includes plugin-inherited permissions for
    the current dependencies, including `WAKE_LOCK`, `VIBRATE`,
    `ACCESS_NETWORK_STATE`, and the `com.google.android.c2dm.permission.RECEIVE`
    group; in-app billing is contributed as the
    `com.google.android.play.billingclient.version` `<uses-library>` entry rather
    than an `android.permission.BILLING` permission. The manifest now also
    carries the `com.google.android.gms.ads.APPLICATION_ID` `<meta-data>`
    (`android/app/src/main/AndroidManifest.xml`), whose value is still the
    all-zero placeholder. **With the ads SDK added, re-inspect the merged
    manifest for the advertising-ID permission
    (`com.google.android.gms.permission.AD_ID`), which the Google Mobile Ads
    SDK contributes and which Play surfaces prominently.** The Flutter plugin's
    own manifest declares only `INTERNET`, so `AD_ID` is expected to arrive
    transitively from `play-services-ads`; confirm that in the merged manifest
    of the uploaded AAB rather than assuming it. The merged manifest and final
    APK must be checked again at each release because source-manifest
    inspection alone is not the final merged permission set.
15. **Local data:** as of v1.6.9 the in-app delete flow does attempt a full
    local wipe: `ApiClient.deleteAccount` calls `AccountDataWipe.wipeAllLocalAccountData`
    after the server request succeeds, which clears the auth token, cached
    profile, and `secretmsg_device_fingerprint` from `flutter_secure_storage`,
    the inbox and moderation-tray caches (`cache_inbox_v1`, `cache_tray_v1`),
    the offline outbox (`outbox_ops_v1`), streak, Daily Drop, and vibe state,
    and the scheduled reminder notifications and preferences. This supersedes
    the earlier position that the delete UI performed no local cleanup. The
    honest caveats are unchanged: the wipe is best-effort and per-subsystem —
    a failure in any step is swallowed, recorded in `debugPrint`, and the
    navigation proceeds regardless, so it is not guaranteed complete; it runs
    **after** the server response, so an aborted or failed server call skips
    it entirely; and the public web deletion page at
    `https://secretmsg.net/delete-account` cannot reach device storage at all.
    **The wipe must also cover any locally stored ad-consent and
    ad-eligibility state, and it still will not reach the advertising
    identifier.** As of this re-derivation it does not: `lib/api/local_data_wipe.dart:39-54`
    clears session, inbox cache, outbox, streak, Daily Drop, vibe, and reminder
    state, but **not** the ad kill-switch cache `ads_enabled` /
    `ads_enabled_fetched_at`, even though `AdsFlagCache.clear` exists
    (`lib/ads/ads_flags.dart:46-52`). Those are a boolean and a timestamp, not
    personal data, so the omission is minor — but the wipe must not be described
    as clearing ad state until it does. The streak wipe does clear ad-earned
    streak freezes, which is consistent with the freeze being local-only. Data
    already exported, saved, or shared by the user is unaffected.
16. **Deletion behavior:** `DELETE /api/account` explicitly deletes received
    messages, blocked senders, reports where the user is recipient and reports
    where the user is reporter, pair codes, purchases, linked donations,
    email-keyed OTP sessions, selected user-derived rate-limit rows, and then
    the user row. It is not a schema-cascade operation and the sequential
    statements are not transactional; a failure can leave partial deletion.
    IP-keyed rate-limit rows are not mapped to the account and can survive.
    Token invalidation is immediate after the user row is gone because
    protected requests re-check that row and its token version, but this is not
    universal erasure, and it does not extend to Google AdMob.
17. **Backups:** the operator backup command exports D1 to a local plaintext
    SQL file, encrypts a copy with AES-256-CBC, and uploads the encrypted file
    to R2. The script does not delete the local plaintext export. The code
    does not establish a post-deletion purge for encrypted D1/R2 backups.
18. **Retention:** pairing codes expire after 5 minutes, but rows are actually
    pruned by the nightly cron: consumed rows after 24 hours and expired rows
    on the next scheduled run. OTPs expire after 15 minutes, but expired
    `auth_sessions` rows are pruned by the nightly cron rather than at the
    exact expiry second. Messages persist until the recipient deletes them or
    the account is deleted. Rate-limit rows are logically windowed and rows
    older than approximately 2 hours are pruned by the nightly cron.
19. **Analytics/crash posture:** Firebase Messaging is present; Firebase
    Analytics and Crashlytics are not. There is no Sentry, Bugsnag, analytics,
    or attribution SDK. **An ads SDK is now present and must no longer be listed
    among the absent SDKs.** Worker `console.error` calls mean Cloudflare may
    hold operational logs.
20. **Current dependency list:** the direct Flutter dependencies currently
    declared in `pubspec.yaml` are `http`, `webview_flutter`,
    `webview_flutter_android`, `flutter_secure_storage`, `share_plus`,
    `path_provider`, `url_launcher`, `in_app_purchase`,
    `flutter_local_notifications`, `firebase_core`, `firebase_messaging`,
    `timezone`, `flutter_timezone`, `package_info_plus`, `multiavatar_plus`,
    `flutter_svg`, `qr_flutter`, `audioplayers`, `connectivity_plus`, `gal`,
    `shared_preferences`, and **`google_mobile_ads`**. This is not an SDK
    analytics declaration; the list is included to prevent the previous stale
    dependency inventory from being reused.
21. **Play "Sensitive info" category is undeclared:** this annex has no
    Sensitive info section. The service has no dedicated field for health,
    financial, sexual, political, religious, or biometric data, and no
    structure requests it. The open question is the free-text content itself:
    anonymous messages, blind replies, public Q&A posts, bios, and display
    names are unrestricted user text and may incidentally contain any such
    topic. Play treats data as sensitive when the app *specifically* collects
    it, and SecretMsg does not, so the defensible answer is "No" — but that is
    a judgment call on a UGC messaging app, not a code fact. The removal of
    donation notes narrows the free-text surface slightly but does not change
    the analysis. Decide it explicitly in the Console rather than leaving the
    category unanswered.

## Cannot be determined from code

- Every AdMob account setting: the real AdMob application ID and ad unit IDs
  (the repository holds all-zero placeholders), `ads.txt` authorization,
  mediation partners, the EEA/UK UMP message, US state opt-out configuration,
  the console ad content rating, the console-side child-directed and
  under-age-of-consent flags, and whether IP-derived approximate-location
  targeting is enabled.
- Whether the code's `MaxAdContentRating.pg` ceiling is compatible with the
  final IARC result, and whether the operator will set
  `AgeRestrictedTreatment.teen` or leave it `unspecified`. Both are decisions,
  not facts in the repository.
- Whether honouring `canRequestAds()` alone satisfies US state opt-out
  requirements, and whether a privacy-options form must be surfaced.
- Which identifiers the Google Mobile Ads SDK actually transmits in the shipped
  build, at which frequency, and whether the release build was configured for
  non-personalised ad requests by default. The SDK's behaviour is Google's and
  is not derivable from this repository.
- Google's retention, deletion, and consent-withdrawal behaviour for the
  advertising identifier and ad interaction data, including whether a deletion
  request propagates from an Android advertising-ID reset.
- Whether the final client sets `ageRestrictedTreatment` deliberately or leaves
  it defaulted. The pinned package exposes the API and the client currently
  sets `AgeRestrictedTreatment.unspecified`; whether that is the right
  declaration is a decision recorded in the Children section above.
- Exact retention periods and deletion schedules for Cloudflare Workers, D1,
  R2, Turnstile, Resend, FCM, Google Play, and Google AdMob, including whether
  any provider honors a deletion request or keeps independent records.
- The actual production D1/R2 backup schedule, whether the R2 backup command is
  enabled in production, and whether any backup or provider copy is purged
  after account deletion.
- The exact Google Play taxonomy bucket for a hashed IP, hashed handle, hashed
  email, or hashed account identifier, and whether Play expects the
  **advertising ID** to be declared under "Device or other IDs" or under
  "App info and performance". Declare it in the bucket the current Console form
  actually shows, and declare it once — not in two sections.
- Whether Google Play counts developer-operated Cloudflare hosting as a
  "sharing" transfer, as opposed to a processor or service-provider
  relationship, and whether Play treats AdMob as a "sharing" transfer or a
  third-party "processing" transfer. The facts are disclosed conservatively
  above either way.
- The exact permissions in the final merged release APK after plugin manifest
  merging, including whether `com.google.android.gms.permission.AD_ID` is
  present, beyond the source manifest and dependency inspection described
  above.
- The live contents of production D1, including old rows, migrations not
  reflected in the schema files, historical accounts, historical `donations`
  rows, historical backups, and any data created outside the current code paths.
- Whether a particular processor receives a particular field in a particular
  failed, retried, legacy, or web-only request path beyond the processor calls
  visible in the current source.

## Corrections from the previous draft

- Changed "Device or other IDs — Not collected" to collected, covering the
  account ID, FCM token, hashed sender fingerprint, blocked-sender hash, and
  hashed rate-limit identifiers; clarified that `device_hint` is only a coarse
  platform label.
- Changed all collected data types from "Shared: no" to conservative processor
  disclosures, including Cloudflare, Resend, Google Play, FCM, and relevant web
  payment flows; added the Cloudflare-sharing judgment caveat.
- Corrected email from "only sign-in method" and "required" to optional legacy
  email OTP, while documenting the synthetic handle placeholder and the
  handle-plus-PIN primary flow.
- Corrected the "no runtime permissions" claim and documented notification,
  exact-alarm, boot, internet, and plugin-inherited permission facts.
- Replaced the stale dependency list with the current `pubspec.yaml` set.
- Kept the no-analytics/no-crash-reporter conclusion, but distinguished
  Firebase Messaging from Firebase Analytics/Crashlytics and disclosed
  possible Cloudflare operational logs.
- Corrected the claim that senders are represented only by message text;
  documented `sender_fp_hash`, `client_msg_id`, `reply_token`, and conditional
  `device_hint`.
- Replaced the vague/cascade deletion claim with the handler's actual explicit,
  sequential, non-transactional deletion list and token behavior.
- Narrowed "all data wiped permanently" to the primary D1 account flow and
  disclosed surviving local data, IP-keyed rate limits, processor records, and
  backup/export copies.
- Corrected the "IP addresses are not stored readable" claim to distinguish
  D1's hashed rate-limit IDs from raw IP access by Cloudflare and Turnstile.
- Added the missing App activity/app interactions category, including counters,
  rate limits, and message/report/pair timestamps.
- Added the exact retention behavior for pairing codes, OTPs, messages, and
  rate-limit rows, including nightly pruning rather than exact-second expiry.
- Added the dependencies and local-storage disclosures needed to distinguish
  the current APK from the older draft.
- **Reversed the "no ads SDK" finding in App info and performance.** Google
  Mobile Ads via `google_mobile_ads` `9.1.0` is now a dependency and the client
  has a full ad layer under `lib/ads/`. The no-analytics, no-crash-reporter, and
  no-attribution findings were re-verified against `pubspec.yaml`/
  `pubspec.lock` and are unchanged.
- **Added a new Advertising data type** covering ad requests, the advertising
  identifier as a shared identifier, ad interaction events, and the
  advertising-or-marketing purpose. Purpose is no longer described as app
  functionality. Grounded in the client ad layer: a 50 dp banner and a rewarded
  video, an empty keyword list, and a non-personalised-by-default request
  policy.
- **Extended Device or other IDs to the advertising identifier**, with the
  ad-serving and measurement purpose, the reset path in Android settings, and
  the fact that it is neither stored in D1 nor derived from
  `secretmsg_device_fingerprint`.
- **Added Personalisation, consent, and regional opt-out** recording the UMP
  call, the non-personalised-by-default policy, the `canRequestAds()` gate, and
  the fact that the US privacy-options form is not surfaced.
- **Added a Children and age treatment section.** This is a new section and it
  is the reason this annex is versioned as strictly as it is: with ads present,
  the age treatment applied to ad requests is a legal declaration. The app is
  not child-directed, no under-13 target audience may be selected,
  `childDirected` and `underAgeOfConsent` are hard-coded false on every ad
  request, UMP is requested with `tagForUnderAgeOfConsent: false`, and
  `AgeRestrictedTreatment.child` is never used. The section also records the
  code's PG ad-content-rating ceiling, the `.unspecified` age treatment and the
  decision it leaves open, and the ad-free suppression path.
- **Added an Advertising declaration section** for App content → Ads,
  including the Android-only scope, the banner and rewarded formats, the
  website's no-ads position, the fail-closed remote kill-switch, and the fact
  that every AdMob identifier in the repository is still a placeholder.
- **Removed Polar from every processor list** and **replaced the supporter-
  donations data-type section** with the single `remove_ads` purchase and the
  ad-free entitlement. Residual Polar and `donations` code in the Worker is
  listed as a known gap rather than declared as current practice.
- **Added a deletion caveat** stating that the in-app delete flow does not and
  cannot delete the advertising identifier or any Google-held ad data, and that
  the app must not claim otherwise. The new local ad state
  (`ads_enabled`, `ads_enabled_fetched_at`) also has to join the
  `AccountDataWipe` inventory.
- **Added WebView exposure** — third-party scripts loaded by the public website
  execute inside the app process — and made it a standing re-check item.
- **Added the location caveat** that AdMob can derive approximate location from
  the request IP when that console setting is enabled.
- **Corrected the permission inventory** to require an explicit merged-manifest
  check for `com.google.android.gms.permission.AD_ID` after the ads SDK is added.
