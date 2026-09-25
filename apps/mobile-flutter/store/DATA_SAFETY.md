# SecretMsg Google Play Data safety

> Provenance: re-derived from the current `secretmsg-private/api` Worker, D1
> schemas, Flutter `pubspec.yaml`, Android manifest, and current Flutter client
> code. This document must be re-verified against the code, merged Android
> manifest, provider configuration, live database, and release build before
> every release and Play submission. Code-derived claims are not a substitute
> for the current Play Console taxonomy or the final APK's merged permissions.

## Top-level Play form questions

### Does the app collect or share any of the required user data types?

**Yes.** The app collects account information, user IDs, messages, app
activity/interaction data, purchase history, supporter/donation data, and
device or other identifiers.
It shares data with infrastructure and payment, email, verification, and push
processors as described below. Some categories are optional depending on the
account and features used.

### Is all collected user data encrypted in transit?

**Yes, for the implemented application and processor paths.** The Flutter
client uses `https://api.secretmsg.net`; the Worker uses HTTPS when calling
Turnstile, Resend, Google APIs, and FCM. This does not mean all copies at rest
are universally erased or that local device storage is encrypted by the app;
the local token and device fingerprint use `flutter_secure_storage`, while
inbox, outbox, and gamification state use `SharedPreferences`.

### Can users request deletion of their data?

**Yes.** Settings → Delete my account calls `DELETE /api/account`. Once the
sequence completes, the primary D1 user row and session validity are deleted
and the request is immediate and irreversible for that D1 row. This is not a
universal erasure: IP-keyed rate limits, local mobile data, external processor
records, and encrypted backups may remain, as detailed below.

## Play data types

The “Shared” answers use a conservative processor-disclosure reading. Whether
developer-operated Cloudflare hosting is treated as a Play “sharing” transfer
is a Play-policy judgment call, but the processor facts are declared here
regardless.

### Personal info — name, email address, user IDs, and other personal information

- **Collected:** Yes.
- **Shared:** Yes. Cloudflare Workers/D1 receives the account and request data;
  Resend receives a real email and OTP for the legacy email-OTP path; the
  Cloudflare Turnstile verifier receives the challenge response and, when
  available, the raw connecting IP. Other processors may receive a user ID or
  token as part of their function.
- **Required or optional:** The handle and 4–6 digit PIN are the primary APK
  sign-in method and are required for the normal handle account. A real email
  is optional and is not required for the APK-only handle/PIN flow. Display
  name, avatar seed, bio, hidden words, notification and moderation settings,
  and supporter/donation information are optional depending on use.
- **Purpose:** Account creation, authentication, recovery, profile display,
  account management, moderation and safety preferences, supporter perks, and
  payment verification.
- **Where stored:** `api/schema.sql` and `db/schema.sql`, `users`:
  `id`, `username`, `display_name`, `email`, `avatar_seed`, `bio`, `pin_hash`,
  `backup_codes`, `backup_codes_used`, `auth_method`, `token_version`,
  `fcm_token`, `created_at`, and `updated_at`; `users.hidden_words`,
  `allow_hints`, `paused_until`, and `mod_sensitivity` for preferences. Real
  email OTP sessions are in `auth_sessions.email`, `auth_sessions.otp_code`,
  and `auth_sessions.expires_at`; the PIN and OTP values are stored as
  hashes. Handle signup stores the synthetic placeholder `<handle>@v2.secretmsg`
  in `users.email`; it is not a real mailbox. Purchase-linked records are in
  `purchases.user_id` and `purchases.purchase_token`.
- **Processors:** Cloudflare Workers/D1; Cloudflare Turnstile for signup, OTP
  requests, message sends, and reports; Resend for real-email OTP delivery;
  Google Play Developer API for purchase verification and acknowledgement;
  Firebase Cloud Messaging for push registration and delivery; Polar.sh for web
  supporter checkout and its webhook where that web flow is used.

**APK/web authentication distinction:** The web client has `requestOtp` and
`verifyOtp` methods, but the current Flutter login, registration, and recovery
screens call handle/PIN, backup-code, and Turnstile flows instead. The legacy
real-email OTP flow is reachable on the web login page, not exposed in the
current Flutter APK UI. For the APK-only form, no real email is collected; a
handle account can use the synthetic placeholder.

### Financial info — purchase history

- **Collected:** Yes, when a user buys or restores a supporter perk.
- **Shared:** Yes. The client sends a Google Play purchase token and product ID
  to the API; the Worker sends the purchase token to Google Play Developer
  API for verification and acknowledgement. Cloudflare Workers/D1 receives the
  request and stores the resulting purchase record.
- **Required or optional:** Optional. Only users who purchase or restore a
  supporter perk provide purchase data. No card number, bank account, or
  payment-card details are collected by SecretMsg.
- **Purpose:** Verify purchase state, prevent replay across accounts, grant
  supporter perks, and acknowledge the purchase to Google Play.
- **Where stored:** `api/schema.sql` and `db/schema.sql`, `purchases`:
  `purchase_token`, `order_id`, `user_id`, `product_id`, `state`,
  `acknowledged_at`, and `created_at`; premium/perk state is in
  `users.is_premium`, `users.badge_title`, `users.has_verified_badge`,
  `users.has_viewer_hints`, and `users.has_sender_hints`.
- **Processors:** Google Play Developer API and Google Play Billing;
  Cloudflare Workers/D1. Google Play processes the purchase; SecretMsg does
  not receive card details.

### Supporter donations — purchase history and user-supplied donor content

- **Collected:** Yes, when someone supports the project through the Polar web
  donation flow. This is distinct from the Google Play purchase records above
  and is collected by the web flow, not by an in-app purchase. The in-app
  Google Pay donation endpoint is fail-closed and returns HTTP 501.
- **Shared:** Yes. Cloudflare Workers/D1 stores the donation record; Polar
  processes the checkout and returns a verified webhook. The Flutter app then
  reads donation records back through the public, unauthenticated
  `GET /api/supporters` endpoint, so a donor-supplied alias and note are served
  to any installed client.
- **Required or optional:** Optional and unrelated to using the messaging
  feature. No account is required to donate.
- **Purpose:** Display the public supporter wall, credit the donor, and grant
  supporter tiers.
- **Where stored:** `api/schema.sql` and `db/schema.sql`, `donations`:
  `user_id` (NULL when unlinked), `donor_alias` (defaults to
  "Anonymous Supporter"), `badge_tier`, `note` (optional free-text message),
  `amount_usd`, `is_anonymous`, `provider`, `reference_id`, and
  `created_at`. The public endpoint returns `alias` (capped at 60 characters),
  `tier`, `note` (capped at 200 characters), and `createdAt`.
- **Processors:** Polar for checkout and webhook delivery; Cloudflare
  Workers/D1 for storage and delivery to the app.
- **Play mapping note:** `amount_usd` is purchase history; the donor-supplied
  `note` is user-generated content. Neither is a Play "Purchase history" record
  created by an in-app purchase, so declare the Play purchase-history question
  for the Google Play products and disclose this separately.

### App activity — app interactions and in-app activity

- **Collected:** Yes. This category is collected even though there is no
  analytics SDK.
- **Shared:** Yes. Cloudflare Workers/D1 receives and stores or evaluates
  interaction data. Cloudflare infrastructure may also retain operational
  request logs.
- **Required or optional:** Optional and feature-dependent. Profile views,
  messages, replies, reports, pairing, and rate-limited actions are recorded
  when those features are used.
- **Purpose:** Abuse prevention, rate limiting, inbox moderation, ranking and
  profile statistics, pairing, and account security.
- **Where stored:** `users.views_count`, `users.received_count`, and
  `users.replies_count`; `rate_limits.id`, `rate_limits.count`,
  `rate_limits.window_start`, and `rate_limits.updated_at`; `messages.created_at`
  and `messages.reply_at`; `reports.created_at`; `pair_codes.created_at`,
  `pair_codes.expires_at`, and `pair_codes.consumed_at`; and `users.created_at`
  and `users.updated_at`. The Flutter client also stores local inbox cache,
  offline outbox, and gamification state under `SharedPreferences` keys in
  `lib/sync/cache.dart` and `lib/sync/outbox.dart`.
- **Processors:** Cloudflare Workers/D1 and Cloudflare operational logging.
  FCM receives unread count as part of a new-message push.

### Messages — other in-app messages

- **Collected:** Yes. The service accepts text messages, replies, report text,
  and moderation state. No photo, video, or audio attachment is accepted.
- **Shared:** Yes. Cloudflare Workers/D1 receives and stores message data;
  Cloudflare Turnstile receives the challenge response and raw connecting IP;
  FCM receives the recipient's FCM token, message ID, unread count, and a
  server-truncated message preview of up to 140 characters (plus an ellipsis
  when truncated). The full message body is not sent through FCM.
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

### Device or other IDs — device identifiers, user IDs, and FCM tokens

- **Collected:** Yes.
- **Shared:** Yes. Cloudflare Workers/D1 receives account IDs, FCM tokens,
  hashed sender fingerprints, and rate-limit keys. FCM receives the registered
  FCM token plus message push data. Turnstile receives the raw connecting IP
  when verification is requested.
- **Required or optional:** `users.id` is required for an account. FCM token
  registration is optional and occurs when push registration succeeds. The
  sender fingerprint and blocked-sender hash are optional feature data used
  for sender blocking. Rate-limit identifiers are collected as security data
  when protected endpoints are used.
- **Purpose:** Account identification, push delivery, anonymous sender
  blocking, abuse prevention, rate limiting, and session protection.
- **Where stored:** `users.id` and `users.fcm_token`; `messages.sender_fp_hash`;
  `blocked_senders.sender_fp_hash`; and `rate_limits.id`, whose format is
  `<bucket>:<sha256(identifier)>`. The hashed identifiers can be based on IP
  address, handle, email, or account ID. The raw app-generated device
  fingerprint is local in Flutter secure storage under the
  `secretmsg_device_fingerprint` key; the Worker stores only its SHA-256
  hash. `device_hint` values such as “Mobile / Android” are coarse platform
  labels, not unique identifiers, and are not the basis of this declaration.
- **Processors:** Cloudflare Workers/D1 and Cloudflare infrastructure;
  Firebase Cloud Messaging for FCM token registration and push delivery;
  Cloudflare Turnstile for raw-IP verification. A processor receives the
  hashed form stored in D1, not a raw device fingerprint.

### App info and performance — diagnostics and crash data

- **Collected:** No app analytics, crash, performance, attribution, ads, or
  attribution SDK is present. Firebase **Messaging** is present, but Firebase
  Analytics and Crashlytics are not. The code has no Sentry, Bugsnag,
  analytics, ads, or attribution SDK.
- **Shared:** Not applicable to an app-collected data type because no app
  analytics or crash dataset is collected. Cloudflare may hold operational
  logs, including `console.error` output from the Worker, independently of
  the app's SDK posture.
- **Required or optional:** Not applicable.
- **Purpose:** Not applicable to an app analytics/crash collection. Operational
  errors are used to diagnose service failures.
- **Where stored:** No analytics or crash dataset or SDK storage is
  identified in `pubspec.yaml` or the Flutter source. Operational logs are
  outside the application database and are not determinable from this
  repository.
- **Processors:** Cloudflare operational logging may be involved; no
  application analytics or crash processor is identified.

### Location

- **Collected:** No.
- **Shared:** Not applicable; no location data is collected.
- **Required or optional:** Not applicable.
- **Purpose:** Not applicable.
- **Where stored:** No location column or location API is identified in
  `api/schema.sql` or `db/schema.sql`.
- **Processors:** None identified in the app code.

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
- **Shared:** Not applicable; no web-browsing dataset is collected.
- **Required or optional:** Not applicable.
- **Purpose:** Not applicable.
- **Where stored:** No browsing-history column is present in the D1 schemas.
  The WebView/Turnstile request itself is operational request data, not a
  retained browsing-history store in the application code.
- **Processors:** Cloudflare may process the request infrastructure; no
  browsing-history processor is identified.

## Known gaps and honest disclosures

1. **Cloudflare scope and Play sharing judgment:** The Worker runs on
   Cloudflare, uses Cloudflare D1, and uses Cloudflare Turnstile. Cloudflare
   receives request content and raw network information, including the raw
   connecting IP used for rate limiting and explicitly sent as Turnstile
   `remoteip`. Cloudflare R2 is used by the operator backup command, not as an
   application runtime binding in `api/wrangler.toml`. Whether developer-
   operated Cloudflare hosting is Play “sharing” is a policy judgment; the
   processor facts are disclosed conservatively above.
2. **Other processors:** Resend receives a real email and six-digit OTP only
   when the legacy email-OTP request succeeds. Google Play receives purchase
   tokens. FCM receives the FCM token and the push payload containing message
   ID, unread count, and a 140-character preview. Polar is used for web
   supporter checkout/webhook flows; the current Google Pay API endpoint is
   fail-closed and returns unavailable.
3. **Identifiers and raw IP:** “IP addresses are not stored readable” is only
   locally true in the D1 rate-limit table. D1 stores SHA-256-derived rate-
   limit IDs, but Cloudflare receives the raw IP as infrastructure and the
   Turnstile verifier is explicitly sent the raw connecting IP.
4. **Authentication:** Email is not the only sign-in method and is not
   required. The current primary auth is handle plus a 4–6 digit PIN, with
   backup-code recovery. Real email is optional legacy email OTP and is not
   exposed in the current Flutter APK login UI. Handle signup stores a
   synthetic `<handle>@v2.secretmsg` placeholder.
5. **Message metadata:** Senders are not asked for a name, but the app stores
   `sender_fp_hash`, `client_msg_id`, `reply_token`, and conditionally
   `device_hint`; the coarse `device_hint` is not a unique ID.
6. **Runtime and build permissions:** The app requests notification permission
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
   than an `android.permission.BILLING` permission. The merged manifest and
   final APK must be checked again at each release because source-manifest
   inspection alone is not the final merged permission set.
7. **Local data:** As of v1.6.9 the in-app delete flow does attempt a full
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
   Data already exported, saved, or shared by the user is unaffected.
8. **Deletion behavior:** `DELETE /api/account` explicitly deletes received
   messages, blocked senders, reports where the user is recipient and reports
   where the user is reporter, pair codes, purchases, linked donations,
   email-keyed OTP sessions, selected user-derived rate-limit rows, and then
   the user row. It is not a schema-cascade operation and the sequential
   statements are not transactional; a failure can leave partial deletion.
   IP-keyed rate-limit rows are not mapped to the account and can survive.
   Token invalidation is immediate after the user row is gone because
   protected requests re-check that row and its token version, but this is not
   universal erasure.
9. **Backups:** The operator backup command exports D1 to a local plaintext
   SQL file, encrypts a copy with AES-256-CBC, and uploads the encrypted file
   to R2. The script does not delete the local plaintext export. The code
   does not establish a post-deletion purge for encrypted D1/R2 backups.
10. **Retention:** Pairing codes expire after 5 minutes, but rows are actually
    pruned by the nightly cron: consumed rows after 24 hours and expired rows
    on the next scheduled run. OTPs expire after 15 minutes, but expired
    `auth_sessions` rows are pruned by the nightly cron rather than at the
    exact expiry second. Messages persist until the recipient deletes them or
    the account is deleted. Rate-limit rows are logically windowed and rows
    older than approximately 2 hours are pruned by the nightly cron.
11. **Analytics/crash posture:** Firebase Messaging is present; Firebase
    Analytics and Crashlytics are not. There is no Sentry, Bugsnag,
    analytics, ads, or attribution SDK. Worker `console.error` calls mean
    Cloudflare may hold operational logs.
12. **Current dependency list:** The direct Flutter dependencies currently
    declared in `pubspec.yaml` are `http`, `webview_flutter`,
    `webview_flutter_android`, `flutter_secure_storage`, `share_plus`,
    `path_provider`, `url_launcher`, `in_app_purchase`,
    `flutter_local_notifications`, `firebase_core`, `firebase_messaging`,
    `timezone`, `flutter_timezone`, `package_info_plus`, `multiavatar_plus`,
    `flutter_svg`, `qr_flutter`, `audioplayers`, `connectivity_plus`, `gal`,
    and `shared_preferences`. This is not an SDK analytics declaration; the
    list is included to prevent the previous stale dependency inventory from
    being reused.
13. **Play "Sensitive info" category is undeclared:** this annex has no
    Sensitive info section. The service has no dedicated field for health,
    financial, sexual, political, religious, or biometric data, and no
    structure requests it. The open question is the free-text content itself:
    anonymous messages, blind replies, public Q&A posts, bios, display names,
    and donation notes are unrestricted user text and may incidentally contain
    any such topic. Play treats data as sensitive when the app *specifically*
    collects it, and SecretMsg does not, so the defensible answer is "No" — but
    that is a judgment call on a UGC messaging app, not a code fact. Decide it
    explicitly in the Console rather than leaving the category unanswered.

## Cannot be determined from code

- Exact retention periods and deletion schedules for Cloudflare Workers, D1,
  R2, Turnstile, Resend, FCM, Google Play, and Polar, including whether any
  provider honors a deletion request or keeps independent records.
- The actual production D1/R2 backup schedule, whether the R2 backup command is
  enabled in production, and whether any backup or provider copy is purged
  after account deletion.
- The exact Google Play taxonomy bucket for a hashed IP, hashed handle, hashed
  email, or hashed account identifier.
- Whether Google Play counts developer-operated Cloudflare hosting as a
  “sharing” transfer, as opposed to a processor or service-provider
  relationship.
- The exact permissions in the final merged release APK after plugin manifest
  merging, beyond the source manifest and dependency inspection described
  above.
- The live contents of production D1, including old rows, migrations not
  reflected in the schema files, historical accounts, historical backups, and
  any data created outside the current code paths.
- Whether a particular processor receives a particular field in a particular
  failed, retried, legacy, or web-only request path beyond the processor calls
  visible in the current source.

## Corrections from the previous draft

- Changed “Device or other IDs — Not collected” to collected, covering the
  account ID, FCM token, hashed sender fingerprint, blocked-sender hash, and
  hashed rate-limit identifiers; clarified that `device_hint` is only a coarse
  platform label.
- Changed all collected data types from “Shared: no” to conservative processor
  disclosures, including Cloudflare, Resend, Google Play, FCM, and relevant web
  payment flows; added the Cloudflare-sharing judgment caveat.
- Corrected email from “only sign-in method” and “required” to optional legacy
  email OTP, while documenting the synthetic handle placeholder and the
  handle-plus-PIN primary flow.
- Corrected the “no runtime permissions” claim and documented notification,
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
- Narrowed “all data wiped permanently” to the primary D1 account flow and
  disclosed surviving local data, IP-keyed rate limits, processor records, and
  backup/export copies.
- Corrected the “IP addresses are not stored readable” claim to distinguish
  D1's hashed rate-limit IDs from raw IP access by Cloudflare and Turnstile.
- Added the missing App activity/app interactions category, including counters,
  rate limits, and message/report/pair timestamps.
- Added the exact retention behavior for pairing codes, OTPs, messages, and
  rate-limit rows, including nightly pruning rather than exact-second expiry.
- Added the dependencies and local-storage disclosures needed to distinguish
  the current APK from the older draft.
