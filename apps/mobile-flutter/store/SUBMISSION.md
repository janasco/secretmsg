# SecretMsg Play submission and release runbook

**Last verified:** 2026-09-26

This is the canonical checklist and release runbook for submitting `net.secretmsg.android_app` to Google Play. Data-safety answers remain in the controlled annex: [DATA_SAFETY.md](DATA_SAFETY.md).

**Business-model change.** SecretMsg is now ad-supported: Google AdMob serves a banner and a rewarded video **in the Android app only**, the website shows no ads, and a single one-time product `remove_ads` grants an ad-free experience. The four previous products are retired and Polar is removed. The Ads declaration is now "contains ads: yes", and the target-audience declaration is critical rather than advisable.

## Open blockers

- [ ] **The `remove_ads` purchase cannot complete — all three Play credentials are missing.** This is the one defect that makes a shipped feature fail for a paying user, and it is not something a rebuild fixes.

  `GOOGLE_PLAY_SA_KEY`, `GOOGLE_PLAY_SA_EMAIL` and `GOOGLE_PLAY_PACKAGE_NAME` are all absent from the Worker. They are empty in `.env.production` and are not in the Cloudflare secret store (verified 2026-10-05: 7 secrets, none of them Google). `getGoogleAccessToken` therefore returns null at `api/src/billing.ts:40` and `POST /api/billing/google/verify` answers **502 "Could not reach the purchase verifier."** A user who paid would be charged with nothing granted, and Play auto-refunds unacknowledged purchases after three days.

  It is invisible today only because `ADS_ENABLED=false`, so no ads are served and nobody needs `remove_ads`. **Do not enable ads before this is fixed.**

  **Status 2026-10-06: the API half is resolved; only the Play Console grant remains.**

  The failure changed, which is the useful signal:

  | | Error |
  |---|---|
  | 10-05 | `403 — Google Play Android Developer API has not been used in project 687972125646 before or it is disabled` |
  | 10-06 | `403 — The caller does not have permission` (`PERMISSION_DENIED`) |

  The first error is about API enablement and the second is about authorisation, so the API is now enabled for the project that owns the service account and that condition is closed. Confirmed stable across two runs rather than read from a single response.

  **What remains is one Play Console action.** Invite this account under
  **Play Console → Users and permissions → Invite new users**:

  ```
  firebase-adminsdk-fbsvc@secretmsg-7cbf8.iam.gserviceaccount.com
  ```

  Grant it app access to `net.secretmsg.android_app` plus financial data and
  order management — `purchases.products.get` needs the financial-data
  permission and `acknowledge` needs order management. Without the grant every
  call returns `PERMISSION_DENIED` regardless of what Google Cloud allows, which
  is exactly what is happening now.

  `secretmsgnet` was deleted from Google Cloud on 10-06. That was the unused
  project, not the Firebase one: `secretmsg-7cbf8` was verified still live
  immediately afterwards — its service account exchanges a token and the FCM
  endpoint answers correctly — which matters because `google-services.json` is
  compiled into shipped APKs and cannot be redirected without a new build.

  **Status 2026-10-05: both were attempted and the API one is still failing, for a specific and fixable reason.** A token exchange with the service account succeeds, and the Play API call now returns a different failure than before — but still a 403:

  ```
  Google Play Android Developer API has not been used in project 687972125646
  before or it is disabled.
  ```

  **Enabled in the wrong project.** `687972125646` is the project number of `secretmsg-7cbf8`, which is where this service account lives — its `client_email` is `firebase-adminsdk-fbsvc@secretmsg-7cbf8.iam.gserviceaccount.com`, and its `project_id` field reads `secretmsg-7cbf8`. If the API was enabled in a different Google Cloud project than that one, the service account's project still reports it as disabled and nothing changes. The API has to be enabled **in the project that owns the service account**, which is `secretmsg-7cbf8` / `687972125646`.

  Retried after a wait to rule out propagation delay — the error was identical, so this is not eventual consistency.

  Two ways forward, and they are equivalent in effort:
  - **Enable it in `secretmsg-7cbf8`.** Use the URL above, or pick project `secretmsg-7cbf8` in the console's API library and enable *Google Play Android Developer API* there.
  - **Or create a Play service account in whichever project was enabled**, and use that account's email and key instead. Cleaner if a dedicated Play project was created on purpose — one credential per service, and it is the better practice anyway.

  Separately: the Play Console permission is independent of the Cloud API. Even with the API enabled, the account must be present in **Play Console → Users and permissions**. Both conditions have to hold; enabling the API alone will still 403.

  Then provision the three secrets. `GOOGLE_PLAY_PACKAGE_NAME` is not actually secret and is `net.secretmsg.android_app` (from `android/app/build.gradle:148`):

  ```bash
  cd /opt/secretmsg/secretmsg-private/api
  set -a; . ../.env.production; set +a
  node /opt/secretmsg/node_modules/wrangler/bin/wrangler.js secret put GOOGLE_PLAY_PACKAGE_NAME
  node /opt/secretmsg/node_modules/wrangler/bin/wrangler.js secret put GOOGLE_PLAY_SA_EMAIL
  node /opt/secretmsg/node_modules/wrangler/bin/wrangler.js secret put GOOGLE_PLAY_SA_KEY
  ```

  **Reuse the existing Firebase service account or create a dedicated one?** Reusing `firebase-adminsdk-fbsvc@secretmsg-7cbf8.iam.gserviceaccount.com` is one console step fewer, because its key is already on disk at `.firebase-service-account.json`. A dedicated account is the better practice — one credential per service — and is what I would pick if the extra five minutes are available. Either way the account needs the Play Console grant from step 2. Do not commit any key; both paths keep it out of the repository.

  Verified after provisioning: complete a real purchase in an internal-test build and confirm the entitlement lands, rather than trusting that a 200 from the endpoint means the grant happened. **The purchase flow has never been exercised end to end.**
- [x] **Stale Android artifacts — done, 1.7.0 built and deployed.** `pubspec.yaml` is `1.7.0+26`, superseding the `1.6.10+25` that was already published. Both tracks were rebuilt on 2026-10-01 from source that includes the redesign: the AAB with AdMob env sourced, and the three sideload APKs. `apps/web/src/lib/appVersion.ts` carries sizes and SHA-256s **recomputed from the new bytes** — and that check earned its place, catching a mistyped x64 hash (`cdcdf3` for `cdc19d`) that no amount of proofreading would have found. The AAB is archived with its symbols under `.secrets/release-artifacts/v1.7.0/`.

  Verified rather than assumed, at each layer: `versionName="1.7.0"` / `versionCode="26"` from the merged manifest; AdMob id `ca-app-pub-1165824705893364~7180472622` present with **zero** placeholder occurrences; all three APKs signed `CN=SecretMsg Sideload`; the track asymmetry holding exactly (`url_play` in the AAB and no `url_sideload`, the reverse in each APK); the update feed reporting `1.7.0`; and the live `arm64` APK downloaded from `secretmsg.net` hashing to the advertised checksum end to end.

  One accepted and recorded exception: the AAB was built at `08:38` and `lib/theme.dart` changed at `11:03` when three unused display tokens were added. By the mtime rule it is stale; `strings ... | grep -c display1` returns 0, so the tree-shaker removed them and behaviour is identical. Recorded in [RELEASE_NOTES.md](RELEASE_NOTES.md) with the reasoning and the condition that closes it.
- [ ] **Play Console enrollment and app creation:** complete account registration and identity verification, then create the app with default language, app-not-game, free distribution, and package `net.secretmsg.android_app`. The application ID is defined at `android/app/build.gradle:148`.
- [x] **Upload keystore — verified in use, closed.** `android/key.properties` exists with `keyAlias=upload` and `storeFile` pointing at `/opt/secretmsg/.secrets/secretmsg-upload.jks`, so Gradle is not falling back to the debug key. Confirmed against the actual artifact rather than the configuration: `jarsigner -verify -verbose -certs` on `/opt/secretmsg/.secrets/release-artifacts/v1.7.0/secretmsg-v1.7.0-upload.aab` reports `CN=SecretMsg`, which is the upload certificate. The sideload APKs report `CN=SecretMsg Sideload`, so the two keys are genuinely distinct and each artifact carries the right one. Backups of both keystores live under `/opt/secretmsg/.secrets/`. The distinction matters because the upload key only ever hands a bundle to Play App Signing, which re-signs it — shipping it on a public artifact would publish a Play credential.
- [ ] **Reviewer access:** the dedicated handle `playreview` is **provisioned and verified** in production D1 (display name "Play Review Demo", no purchase history, synthetic `email` placeholder, 10 backup codes, 4 seeded messages plus 1 quarantined moderation sample, rank "Newcomer"). Login was confirmed working against the live API. Remaining step: store its PIN and backup codes in the password manager and enter the exact credentials in **App content → App access**. Never put the PIN or backup codes in this repository.
- [x] **Public account deletion:** `https://secretmsg.net/delete-account` is **shipped and verified live** (HTTP 200, listed in `sitemap.xml`, linked from the privacy policy, FAQ, terms, safety tools, footer, and the in-app Settings screen). It is publicly reachable without installing the app, explains the recovery path for a forgotten PIN, and discloses what deletion does not reach. Enter this URL in **Data safety**. Verification notes: the trailing-slash form `https://secretmsg.net/delete-account/` is canonical and returns 200; the non-slash form returns a 307 to it, which Play follows, so either form is safe to paste. This is the one submission-critical page that is **not** server-prerendered — `https://secretmsg.net/delete-account/` returns a meta-only shell whose `#root` contains only a `<noscript>` fallback, and the real instructions arrive in the lazy `DeleteAccountPage-*.js` chunk. It renders correctly in any JavaScript-capable browser (Play's crawler included), but confirm it visually once before submitting rather than trusting the 200 alone.
- [ ] **Phone screenshots:** still pending; the operator is capturing them on their own phone. Capture at least four portrait screenshots at 1080×1920 or larger, using inbox, Daily Drop, Dice Prompt Roulette, and Sticker Studio as the subjects.
- [ ] **Closed testing and pre-launch review:** for a personal developer account created after 2023-11-13, keep at least 12 testers opted in continuously for 14 days, then apply for production access. Recruiting 20 or more provides headroom against dropouts; 20 is not the Play minimum. Review and fix findings in the pre-launch report before production.
- [x] **Billing service account — consolidated into the `remove_ads` blocker above.** This item and the credentials item near the top of this list described the same work: create/grant a Play API service account and provision `GOOGLE_PLAY_SA_EMAIL` / `GOOGLE_PLAY_SA_KEY` / `GOOGLE_PLAY_PACKAGE_NAME`. Two entries for one blocker invites one of them being done and the other left open. The full steps, the two console actions that were confirmed necessary by testing, and the reason it matters are recorded in the item above. Kept here as a pointer rather than deleted, so a reader working down this list in order does not think it was dropped.

  Worth preserving from the original entry, because it is a useful detail: the API fails closed with HTTP 503 when any of these values is absent (`api/src/index.ts:867-869`). `wrangler.toml` still lists all three under "Secrets to be configured via `wrangler secret put`", and `.env.production` carries the two key names with **empty** values — so the only authoritative check is `wrangler secret list`. That is exactly how this was caught.
- [x] **AdMob account, application and ad units — verified present in the built artifact, closed.** The item asked for the account to be created, the app registered, and exactly two ad units made. All three were confirmed by reading the shipped bundle rather than the configuration that claims to set them. `strings` on `base/lib/*/libapp.so` inside the archived `secretmsg-v1.7.0-upload.aab` returns:

  ```
  app id    ca-app-pub-1165824705893364~7180472622
  unit      ca-app-pub-1165824705893364/7304595707
  unit      ca-app-pub-1165824705893364/9224267752
  placeholder occurrences: 0
  ```

  **Exactly two ad units, matching the two declared formats** — a banner and a rewarded video. No interstitial, app-open, rewarded-interstitial or native unit is present, which is what the Ads declaration depends on. `ads.txt` and `app-ads.txt` carry the matching publisher id `pub-1165824705893364`.

  The part this cannot close, and which stays with item 2 in the annex: confirming in the **AdMob console** that the app reports as *authorised* and that no mediation partners are enabled. Those are account facts with no representation in this repository. An unrecognised seller line is a common cause of zero ad fill, and zero fill is also what a correctly-configured app shows while `ADS_ENABLED=false` — so a zero-impression result proves nothing in either direction until the flag is on.
- [x] **`ads.txt` / app-ads.txt:** both files are published from the site root — `apps/web/public/ads.txt` and `apps/web/public/app-ads.txt` — and served publicly at `https://secretmsg.net/ads.txt` and `https://secretmsg.net/app-ads.txt`. They are public by design, must never contain secrets, and must not be kept in `.env`: ad networks and mobile ad SDKs fetch them unauthenticated. **Both carry the real publisher ID `pub-1165824705893364`, and `app-ads.txt` carries the store id `net.secretmsg.android_app`.** Verified by reading the files; an earlier revision of this runbook said they still held the `pub-0000000000000000` placeholder, which is no longer true. The remaining AdMob-console task is to confirm the app reports as **authorised** there — an unrecognised seller line is a common cause of zero ad fill, and nothing in the repository can assert it.
- [ ] **Ad consent configuration:** in the AdMob console, set the EEA/UK consent message (or confirm the SDK's default UMP behaviour is the intended one), set the **US states** opt-out behaviour, set the **ad content rating** to match the IARC result below, and confirm that neither **child-directed treatment** nor **under-age-of-consent treatment** is enabled. None of these are visible in the app source and all of them are part of the legal posture recorded in [DATA_SAFETY.md](DATA_SAFETY.md).
- [x] **Age-treatment setting in the client — verified, closed.** `RequestConfiguration` sets `ageRestrictedTreatment: AgeRestrictedTreatment.teen` at `lib/ads/mobile_ads_platform.dart:27`. Not `child`, and not left at an unset default. This is a deliberate value, read from the call site rather than inferred from a default, which is what the item asked for. It must stay non-child for the target-audience answer (13+) and the AdMob configuration to agree with each other.
- [ ] **`remove_ads` must exist on both sides before submission:** the Play product and the code must agree exactly. **Both code sides now agree**: `PLAY_PRODUCTS` in `/opt/secretmsg/secretmsg-private/api/src/billing.ts:8-10` contains only `remove_ads`, mapping it to `{ badge: true, viewer: true, sender: true, tier: 'Supporter' }`, and the client's `BillingProducts` class lists `removeAds = 'remove_ads'` (`apps/mobile-flutter/lib/api/billing.dart:17`). What remains is the **Play Console** side: the `remove_ads` product must actually exist there, be active, and be published to the same track as the build being submitted. The two sides cannot be verified from the repository — confirm in the console that the product resolves for a test account, because shipping a Play product the API does not recognise means the purchase is rejected, while shipping the API change before the Play product exists means the client cannot resolve the product details. This remains a hard blocker, not a follow-up.
- [x] **Retire the four previous products and remove Polar.** The four previous products are retired and must be deactivated or made unavailable in Play Console. **The Worker side of this is done**: `api/src/polar.ts`, the `POLAR_WEBHOOK_SECRET` binding, and `POST /api/webhook/polar` were deleted in `1a42731`, and the `donations` table has since been dropped from both schema files with its production rows purged. Two things that earlier drafts of this runbook listed as residual are **not** Polar paths and must be kept: `GET /api/supporters` now counts `remove_ads` entitlements, and `POST /api/donation/google-pay` is a 410 tombstone that grants nothing. `PLAY_PRODUCTS` in `api/src/billing.ts` carries only `remove_ads`, which grants the supporter-tier flags, so the `is_premium` / `badge_title` / `has_verified_badge` / `has_viewer_hints` / `has_sender_hints` columns are live and must not be removed as "leftovers". The one remaining item is Play Console work (deactivating the four products) plus deleting the inert `POLAR_*` secrets from the Cloudflare secret store.
- [x] **Client privacy and supporter copy — already corrected.** An earlier revision of this runbook said the in-app copy still asserted "no advertising SDK", "no advertising ID" and "zero ad trackers", and listed it as a blocker. **Those strings no longer exist in `lib/`.** Verified by grep across `lib/data/static_content.dart`, `lib/screens/supporters_screen.dart` and the rest of the client: `static_content.dart:359` describes AdMob accurately ("this Android app shows ads through Google AdMob, as a banner and as an optional rewarded video... Ads are non-personalised unless you consent to personalised ads"), and `:341` correctly says SecretMsg itself collects no advertising identifier while AdMob handles the Android advertising ID. Nothing to change. Left here as a checked item rather than deleted, because the claim was wrong and the next reader should see it was checked rather than skipped.
- [ ] **Fill in the Play update URL before the listing goes public (blocks public release, not submission).** The *mechanism* now exists and the client already uses it: `GET /api/app-version` carries `url_sideload` next to the legacy `url`, and the app asks the feed only for its own track's URL. What is missing is the value. The feed deliberately **omits** `url_play` rather than stubbing it, because there is no Play listing to point at yet and a placeholder would be a broken link that something would eventually open. Consequently a Play-track build that is behind shows no update prompt at all until `url_play` exists — safe, but silent. The moment the listing goes public, add `url_play: '<the real listing URL>'` to the feed object in `/opt/secretmsg/secretmsg-private/api/src/index.ts` and deploy it; no rebuild and no new client is needed, the shipped Play build picks it up on its next feed poll. `api/test/app-version.test.mjs` asserts the key is currently absent, so forgetting is a failing test rather than a silent gap. See the per-release runbook step 3 and `apps/mobile-flutter/README.md` ("Two tracks that never merge").

## One-time setup

1. Enroll the developer account, complete identity verification, and create the Play app for `net.secretmsg.android_app`.
2. Generate the upload keystore from a secure release directory with this exact command:

   ```bash
   keytool -genkeypair -v -keystore secretmsg-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias secretmsg-upload
   ```

3. Back up `secretmsg-upload.jks`, its PIN/password material, and the certificate fingerprint in the release password manager and an independent encrypted backup. Create gitignored `android/key.properties` with `storeFile`, `storePassword`, `keyAlias=secretmsg-upload`, and `keyPassword`; `storeFile` must be an absolute path.
4. Enroll the app in **Play App Signing** on the first upload. The upload key signs the bundle and Google signs the distributed app with the app-signing key.
5. Back up the upload key anyway. With Play App Signing enrolled, Google Play supports requesting an upload-key reset if the upload key is lost or compromised. That recovery does not apply to a separately managed app-signing key; losing such a key is a different incident and should be escalated to Google immediately. Prefer the default Google-generated app-signing key unless there is a specific reason to manage one directly.
6. Provision the `playreview` reviewer account, save its PIN and backup codes only in the password manager, and seed representative content so the restricted app can be reviewed. Do not use expiring pairing codes as reviewer credentials.
7. Add the canonical assets, listing copy, and declarations in the sections below.
8. Create the single one-time managed product `remove_ads`, provision the billing service account, and add a licence tester before testing purchases.
9. Start internal testing, then closed testing. For a new personal account, satisfy the closed-test requirement, review the pre-launch report, and apply for production access.

## Store listing assets

Only these two generated graphic files are canonical for this submission:

| Asset | Play requirement | Canonical file | Status |
|---|---|---|---|
| App icon | 512×512, 32-bit PNG/JPEG with no alpha | `store/play-icon-512.png` | Ready; verified 512×512 RGB PNG |
| Feature graphic | 1024×500, 32-bit PNG/JPEG with no alpha | `store/play-feature-1024x500.png` | Ready; verified 1024×500 RGB PNG |
| Phone screenshots | At least 2; use at least 4 at 1080×1920 or larger in portrait | Operator capture from a phone | Pending: inbox, Daily Drop, Dice Prompt Roulette, Sticker Studio |
| Tablet screenshots | Decision: opt out of tablet listing; do not prepare 7-inch or 10-inch screenshots | — | Opt-out selected |

Confirm that captured screenshots show the actual app, contain no unsupported promotional claims, and use only real product UI. Do not substitute launcher assets or web icons for the canonical Play files above. The app now serves a banner and a rewarded prompt, so read the ad policy in [SCREENSHOTS.md](SCREENSHOTS.md) before the capture run.

## Listing copy

The canonical listing copy is maintained separately under `store/listing/`:

- `store/listing/title.txt`
- `store/listing/short_description.txt`
- `store/listing/full_description.txt`

Review the files immediately before uploading them. Play limits are 30 characters for the title, 80 for the short description, and 4000 for the full description. Select the Social category and relevant tags.

The full description states that the app is ad-supported and that a one-time purchase removes the ads. It must not claim there are no ads, no ad partners, or no advertising identifiers, and it must not describe donation tiers or cosmetic perk products — those are retired. The sender-anonymity and no-data-sale claims in the same file are still accurate and must stay.

Release notes for every shipped version are in `store/RELEASE_NOTES.md`, each entry already trimmed to Play's 500-character limit. Paste the entry for the version being uploaded.

## App content declarations

- **Privacy policy:** `https://secretmsg.net/p/privacy`. The policy source is `apps/web/src/pages/PrivacyPage.tsx`, and the route is recognized by the app at `apps/mobile-flutter/lib/main.dart:69-88` and tested at `apps/mobile-flutter/test/deep_link_router_test.dart:16-35`. Verify the public page before submission.
- **Contact details:** website `https://secretmsg.net`; use `privacy@secretmsg.net` for privacy and `safety@secretmsg.net` for child-safety and abuse concerns. These addresses appear in the published policy sources.
- **Ads:** **this app contains ads.** SecretMsg is ad-supported. Google AdMob / Google Mobile Ads serves a **banner** and a **rewarded video** in the Android app only. The website at `secretmsg.net` shows no ads. Answer **Yes** to "Does your app contain ads?" in Play Console. Completing this section requires, in the AdMob console: the AdMob application ID and the two ad unit IDs, `ads.txt` authorised at the developer's domain, the EEA/UK consent message, the US-states opt-out configuration, the ad content rating matching the IARC result, and confirmation that neither child-directed nor under-age-of-consent treatment is enabled. The Play **Data safety** form must then declare the advertising identifier, the Advertising data type, and the advertising-or-marketing purpose — see [DATA_SAFETY.md](DATA_SAFETY.md). The in-app delete flow does not and cannot delete the advertising identifier; users reset it in Android Settings → Privacy → Ads, and the app must not claim otherwise.
- **App access:** declare that all or some functionality is restricted. Provision the `playreview` account, seed it, and enter its exact handle and PIN in Play Console. The app supports handle/PIN authentication at `/opt/secretmsg/secretmsg-private/api/src/index.ts:410-446`. Keep the PIN and backup codes only in the password manager, never in this document.
- **Content rating:** complete the IARC questionnaire honestly. SecretMsg hosts unrestricted user-generated communication, including anonymous user-to-user messages, so the answers will not support an Everyone rating. Anonymous communication rates strictly; expect Teen or higher, subject to the questionnaire result. **The AdMob ad content rating must be set to match the questionnaire result** — a mismatch is a misconfiguration the SDK will not fix for you.
- **Target audience:** do not select an under-13 audience or age band. Review the Families-policy consequences before submitting the target-audience and content-rating forms. **This is now critical rather than merely advisable, because the app serves ads.** Selecting any under-13 band would place the app in Play's Families program and conflict with the ad SDK's age treatment and with the AdMob child-directed setting, and it is a policy violation risk rather than a formality. Confirm the selection contains no under-13 band immediately before submitting; do not rely on an earlier saved form.
- **Child-directed and under-13 safeguards (must all be true at submission):** the app is **not** child-directed and does not request child-directed treatment for ad requests; the app does **not** request under-age-of-consent treatment for ad requests; the AdMob account is not configured for child-directed treatment; the target-audience selection excludes every under-13 band; and no ad is served to a user who has bought `remove_ads`. Each of these is a separate declaration, and they must not contradict each other. The full wording is recorded in the **Children and age treatment** section of [DATA_SAFETY.md](DATA_SAFETY.md).
- **Child safety standards:** provide the published child-safety policy at `https://secretmsg.net/p/child-safety-policy`, backed by `apps/web/src/pages/ChildSafetyPage.tsx`; identify `safety@secretmsg.net` as the child-safety contact. The app provides an in-app message-report action in `apps/mobile-flutter/lib/screens/inbox_screen.dart:1141-1229` and routes the policy URL at `apps/mobile-flutter/lib/main.dart:69-88`.
- **Data safety:** use the separate controlled annex, [DATA_SAFETY.md](DATA_SAFETY.md). For account deletion, the public URL is `https://secretmsg.net/delete-account` (shipped and verified); in-app deletion remains available from Settings.
- **Other declarations:** answer Government apps, Financial features, and Health as not applicable; this is not a News app.

## In-app products

Create **one** one-time managed product. The identifier must match `PLAY_PRODUCTS` in `/opt/secretmsg/secretmsg-private/api/src/billing.ts:8-12` and `BillingProducts` in `apps/mobile-flutter/lib/api/billing.dart:10-21` exactly.

| Product ID | Type | Grants |
|---|---|---|
| `remove_ads` | One-time managed product | Ad-free experience — the banner and rewarded video are not served, and no ad is requested |

The previous four products are **retired** and must not be created, reactivated, or left purchasable:

| Retired Product ID | Former grant | Disposition |
|---|---|---|
| `verified_badge` | Verified badge | Retire; deactivate in Play Console |
| `viewer_hints` | Viewer hints | Retire; deactivate in Play Console |
| `sender_hints` | Sender hints | Retire; deactivate in Play Console |
| `supporter_bundle` | All three | Retire; deactivate in Play Console |

Notes on the new product:

- `remove_ads` is a **purchase, not a donation**. There is no donations processor, no donor alias, no donor note, and no supporter tiers. Polar is removed entirely.
- The entitlement must be derived from the verified `remove_ads` purchase row, and it must be enforced **before** an ad is requested — not merely by hiding the ad slot. A user who pays for ad-free and still sees an ad is a refund-worthy defect and a declaration breach.
- The Play product must be created **before** the client is built and tested, because product details are resolved from Play by ID and an unrecognised ID cannot be purchased.
- Confirm the identifier in both source locations again whenever billing code changes, and confirm the two locations agree with each other and with this table. The client sends the purchase token to the API, which verifies it with Google before granting the entitlement (`apps/mobile-flutter/lib/api/billing.dart:80-152`).

## Billing service-account requirements

1. Enable the Google Play Android Developer API in the relevant Google Cloud project.
2. Create a dedicated service account and grant it access to the Play app with the financial/purchase permissions required to verify and acknowledge one-time product purchases.
3. Link or invite the service-account user in **Play Console → Users and permissions** according to Google Play's service-account setup instructions.
4. Store the service-account email as `GOOGLE_PLAY_SA_EMAIL`, its private key as `GOOGLE_PLAY_SA_KEY`, and the app package as `GOOGLE_PLAY_PACKAGE_NAME=net.secretmsg.android_app` in the production API secret store. Never commit, print, or paste the JSON key.
5. Add the tester's Google account as a **licence tester**. Add the app to the tester's Library → installed apps before testing billing.
6. Upload the app to a test track before testing; purchases cannot complete against a local build.
7. Test the `remove_ads` product ID, including a restore/verification retry, and confirm the API does not return 503, 502, or 402 unexpectedly. Then confirm the entitlement actually suppresses ad requests on a device signed into the purchasing account. The environment names are declared at `/opt/secretmsg/secretmsg-private/api/src/db.ts:20-33`; missing values intentionally fail closed at `/opt/secretmsg/secretmsg-private/api/src/index.ts:867-869`.

## Build and upload procedure

Run from `apps/mobile-flutter/`.

1. Confirm the current app version and increment it in `pubspec.yaml`. The version in the current upload bundle is `1.6.10+25` at `apps/mobile-flutter/pubspec.yaml:17`; always increase the build number (`+N`) for every Play upload.
2. Confirm `minSdk` remains 24 as defined at `android/app/build.gradle:151`, and re-check Google Play's current target-API requirement before each release. The source does not pin API 36: `compileSdk` and `targetSdk` resolve from `flutter.compileSdkVersion` and `flutter.targetSdkVersion` at `android/app/build.gradle:147` and `android/app/build.gradle:152`. The ads plugin's own build declares `minSdk 24`, so the existing floor is compatible. Rebuild and retest if Play raises its floor.
3. Confirm `com.google.android.gms.ads.APPLICATION_ID` is present in the **merged** manifest for the release build, and that only the banner and rewarded ad unit IDs are referenced in the client. The source manifest alone is not sufficient evidence.
4. Run:

   ```bash
   flutter analyze
   flutter test
   ```

5. Build the only supported release bundle command. The AdMob identifiers must
   be exported first; the script feeds the same values to the manifest and to
   Dart, and the build refuses to run without a complete set:

   ```bash
   export ADMOB_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX
   export ADMOB_BANNER_AD_UNIT_ID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
   export ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
   scripts/build_release.sh aab --obfuscate --split-debug-info=build/symbols
   ```

   A bare `flutter build appbundle --release` will fail on purpose. That is the
   guard working, not a broken build.

6. Archive `build/symbols` under the exact release version. Losing the matching symbol files makes production stack traces unreadable.
7. Verify the signing certificate with Android SDK build tools before upload. `apksigner verify --print-certs` operates on an APK signed by the upload key; use a same-key diagnostic APK and verify that its certificate matches the backed-up upload certificate. Verify the AAB's JAR signature separately with `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`.
8. Confirm `android/app/build.gradle:189-197` found `android/key.properties`; otherwise the AAB is debug-signed and is not upload-ready.
9. Upload `build/app/outputs/bundle/release/app-release.aab` to **Internal testing** first. Confirm Play App Signing enrolment, then install from Play rather than sideloading.
10. Exercise sign-up, handle/PIN login, sending with the bot check, receiving and replying, pairing, blocking/reporting, account deletion, update prompting, and the `remove_ads` purchase on a real device. Separately confirm that the banner renders, the rewarded video plays and grants its reward, and that buying `remove_ads` stops both.
11. A brand-new developer account or app may take several days to review. Follow the Play Console's displayed review state rather than assuming a fixed duration.

## Order of operations

1. Complete Play Console enrollment and identity verification; create the app.
2. Generate and back up the upload keystore; configure `android/key.properties`.
3. Set up the AdMob account: register the Android app, record the application ID, create the banner and rewarded ad units, authorise the seller in `ads.txt`, and complete the consent, ad-content-rating, and age-treatment configuration.
4. Capture and validate phone screenshots; keep the selected tablet opt-out. Decide deliberately whether listing shots show ads; see [SCREENSHOTS.md](SCREENSHOTS.md).
5. Upload the obfuscated AAB to internal testing and enrol in Play App Signing. Confirm the merged manifest carries the AdMob application ID.
6. Enter the canonical listing copy and assets.
7. Complete privacy, app access, **ads**, content rating, target audience, child safety, and Data safety declarations; verify the public deletion URL before submission. Re-read the target-audience form immediately before submitting and confirm no under-13 band is selected.
8. Provision the reviewer account `playreview`, seed it, and enter its credentials in Play Console.
9. Create the single `remove_ads` product, deactivate the four retired products, provision the billing service account, and add a licence tester.
10. Validate internal testing, including sign-in, safety flows, deletion, update feed, ad rendering, the rewarded prompt, the ad-free entitlement, and billing.
11. Promote to closed testing. For a qualifying new personal account, maintain 12 testers continuously for 14 days; use 20+ testers for operational headroom.
12. Review the pre-launch report, fix crashes or policy issues, and apply for production access.
13. Publish production after approval. Google does not offer a percentage selector for the first production release; for subsequent updates, roll out at 20%, monitor, then increase to 100%.

## Per-release runbook

Repeat this section for every version.

1. Confirm the current target-API floor in Play Console and verify the installed Flutter SDK resolves above it; the source does not hardcode a target API.
2. Increment the version name as appropriate and always increase the build number in `pubspec.yaml`.
3. Bump `android_latest` in the public `/api/app-version` feed to the new release version and deploy that feed with the release. The feed currently exposes `android_latest` at `/opt/secretmsg/secretmsg-private/api/src/index.ts:106-113`; the Flutter app checks it on cold start and when requested from Settings and prompts when its installed version is behind (`apps/mobile-flutter/lib/ritual/update_check.dart`). Do not publish the AAB while leaving the feed stale. The feed is **track-aware**: it keeps the legacy single `url` (`https://secretmsg.net/download`, read by every client released before per-track URLs existed, so it must keep pointing there), adds `url_sideload` for the same destination, and **omits `url_play`** because Play is not published and no listing URL exists to name. The client picks the field matching its own track, which it knows at compile time from the same `-PsideloadSigning=true` flag that chose its signing key (`apps/mobile-flutter/android/app/build.gradle` → `lib/distribution/track.dart`); the "Update" button then opens only that track's URL (`apps/mobile-flutter/lib/widgets/update_dialog.dart`). A Play build finds no `url_play` and therefore shows no update prompt, which is why this step is a **blocker for public release**: add `url_play` here, in the same change that makes the listing public, or Play-track users are never told a new version exists. Sideload releases need no change beyond the version bump. The signing and key-rotation background is in `apps/mobile-flutter/README.md` ("Two tracks that never merge"); read it before changing anything about how the AAB is signed.
4. Re-check the Play policy declarations, the **ads** declaration, privacy and child-safety pages, Data safety annex, AdMob console configuration, and public account-deletion URL. Confirm the target-audience form still excludes every under-13 band and that the app still requests no child-directed or under-age-of-consent ad treatment.
5. Run `flutter analyze` and `flutter test`; resolve all failures before building.
6. Build with the canonical obfuscated command, exporting the AdMob identifiers
   first:

   ```bash
   export ADMOB_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX
   export ADMOB_BANNER_AD_UNIT_ID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
   export ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
   scripts/build_release.sh aab --obfuscate --split-debug-info=build/symbols
   ```

7. Archive `build/symbols` with the exact version and build number. Never reuse another release's symbol directory.
8. Verify the upload certificate and AAB signature, then confirm the release used `android/key.properties` rather than the debug fallback.
9. Upload to internal testing. Smoke-test `/api/health`, one public profile lookup, sign-up, PIN login, send/receive, bot check, reply, pairing, blocking/reporting, account deletion, update prompting, ad rendering, the rewarded prompt, the `remove_ads` entitlement, and billing.
10. For a new qualifying personal account, complete the closed test and pre-launch-report review before requesting production access.
11. Promote through the required tracks. For subsequent production updates, use a 20% staged rollout, monitor crashes, ANRs, **ad fill and impression errors**, and purchases, then increase to 100% only after the holdback is healthy.
12. After rollout, confirm older installed versions receive the expected update prompt and retain the matching symbol archive.

## Controlled annex

The Play Data safety form is maintained separately in [DATA_SAFETY.md](DATA_SAFETY.md). Do not copy or inline its answers here; update the annex when backend data practices change, then reconcile the Console declaration from that controlled source.

Screenshot policy for the ad-supported build, including whether listing shots may show an ad, is in [SCREENSHOTS.md](SCREENSHOTS.md).
