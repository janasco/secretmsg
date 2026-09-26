# SecretMsg Play submission and release runbook

**Last verified:** 2026-09-26

This is the canonical checklist and release runbook for submitting `net.secretmsg.android_app` to Google Play. Data-safety answers remain in the controlled annex: [DATA_SAFETY.md](DATA_SAFETY.md).

**Business-model change.** SecretMsg is now ad-supported: Google AdMob serves a banner and a rewarded video **in the Android app only**, the website shows no ads, and a single one-time product `remove_ads` grants an ad-free experience. The four previous products are retired and Polar is removed. The Ads declaration is now "contains ads: yes", and the target-audience declaration is critical rather than advisable.

## Open blockers

- [ ] **Play Console enrollment and app creation:** complete account registration and identity verification, then create the app with default language, app-not-game, free distribution, and package `net.secretmsg.android_app`. The application ID is defined at `android/app/build.gradle:40`.
- [ ] **Upload keystore:** generate, configure, back up, and use the release upload key. `android/key.properties` is gitignored; without it, Gradle falls back to the debug signing key at `android/app/build.gradle:49-63`.
- [ ] **Reviewer access:** the dedicated handle `playreview` is **provisioned and verified** in production D1 (display name "Play Review Demo", no purchase history, synthetic `email` placeholder, 10 backup codes, 4 seeded messages plus 1 quarantined moderation sample, rank "Newcomer"). Login was confirmed working against the live API. Remaining step: store its PIN and backup codes in the password manager and enter the exact credentials in **App content → App access**. Never put the PIN or backup codes in this repository.
- [x] **Public account deletion:** `https://secretmsg.net/delete-account` is **shipped and verified live** (HTTP 200, listed in `sitemap.xml`, linked from the privacy policy, FAQ, terms, safety tools, footer, and the in-app Settings screen). It is publicly reachable without installing the app, explains the recovery path for a forgotten PIN, and discloses what deletion does not reach. Enter this URL in **Data safety**. Verification notes: the trailing-slash form `https://secretmsg.net/delete-account/` is canonical and returns 200; the non-slash form returns a 307 to it, which Play follows, so either form is safe to paste. This is the one submission-critical page that is **not** server-prerendered — `https://secretmsg.net/delete-account/` returns a meta-only shell whose `#root` contains only a `<noscript>` fallback, and the real instructions arrive in the lazy `DeleteAccountPage-*.js` chunk. It renders correctly in any JavaScript-capable browser (Play's crawler included), but confirm it visually once before submitting rather than trusting the 200 alone.
- [ ] **Phone screenshots:** still pending; the operator is capturing them on their own phone. Capture at least four portrait screenshots at 1080×1920 or larger, using inbox, Daily Drop, Dice Prompt Roulette, and Sticker Studio as the subjects.
- [ ] **Closed testing and pre-launch review:** for a personal developer account created after 2023-11-13, keep at least 12 testers opted in continuously for 14 days, then apply for production access. Recruiting 20 or more provides headroom against dropouts; 20 is not the Play minimum. Review and fix findings in the pre-launch report before production.
- [ ] **Billing service account:** create and grant the Google Play API service account, then provision `GOOGLE_PLAY_SA_EMAIL` and the private key as `GOOGLE_PLAY_SA_KEY` in the production API secret store. Verify `GOOGLE_PLAY_PACKAGE_NAME=net.secretmsg.android_app` is present without printing any secret. The API fails closed with HTTP 503 when any of these values is absent (`/opt/secretmsg/secretmsg-private/api/src/index.ts:867-869`). Note that `wrangler.toml` still lists all three under "Secrets to be configured via `wrangler secret put`", and `.env.production` carries the two key names with **empty** values, so the only authoritative check is `npx wrangler secret list`.
- [ ] **AdMob account, application, and ad units:** create the AdMob account, register the Android app for package `net.secretmsg.android_app`, and record the generated **AdMob application ID**. Then create exactly two ad units: one **banner** and one **rewarded video**. Do not create or use interstitial, app-open, rewarded-interstitial, or native ad units; adding one requires re-deriving the Ads declaration and the data-safety annex. No AdMob identifier is committed to the repository: supply all three at build time via `ADMOB_APP_ID`, `ADMOB_BANNER_AD_UNIT_ID`, and `ADMOB_REWARDED_AD_UNIT_ID`, and build with `scripts/build_release.sh aab`. The application ID is injected into the source manifest as the `${admobAppId}` placeholder, and a release build carrying a placeholder is refused by Gradle, so the uploaded AAB either has the real id or does not exist. Confirm it in the merged manifest of the uploaded AAB.
- [ ] **`ads.txt` / app-ads.txt:** both files are now published from the site root — `apps/web/public/ads.txt` and `apps/web/public/app-ads.txt` — and are served publicly at `https://secretmsg.net/ads.txt` and `https://secretmsg.net/app-ads.txt`. They are public by design, must never contain secrets, and must not be kept in `.env`: ad networks and mobile ad SDKs fetch them unauthenticated. Both currently carry the **placeholder** seller ID `pub-0000000000000000`; substitute the real AdMob publisher ID (the same value in both files), redeploy the frontend, then confirm in the AdMob console that the app reports as **authorised**. An unrecognised seller line is a common cause of zero ad fill and must be resolved before the ad-supported release is judged working. This is an AdMob-console and web-property task; nothing in the Flutter app can assert it.
- [ ] **Ad consent configuration:** in the AdMob console, set the EEA/UK consent message (or confirm the SDK's default UMP behaviour is the intended one), set the **US states** opt-out behaviour, set the **ad content rating** to match the IARC result below, and confirm that neither **child-directed treatment** nor **under-age-of-consent treatment** is enabled. None of these are visible in the app source and all of them are part of the legal posture recorded in [DATA_SAFETY.md](DATA_SAFETY.md).
- [ ] **Age-treatment setting in the client:** verify the app explicitly sets `RequestConfiguration.ageRestrictedTreatment` to a non-child value and does not request child-directed or under-age-of-consent treatment. In `google_mobile_ads` `9.1.0` the classic `tagForChildDirectedTreatment` and `tagForUnderAgeOfConsent` parameters are **deprecated** in favour of `ageRestrictedTreatment` (`AgeRestrictedTreatment.child` / `.teen` / `.unspecified`). `AgeRestrictedTreatment.child` must never be used. A default that was never set deliberately is not the same as a deliberate value; read the call site, do not assume.
- [ ] **`remove_ads` must exist on both sides before submission:** the Play product and the code must agree exactly. As of the last verification the Worker's `PLAY_PRODUCTS` map still lists only `verified_badge`, `viewer_hints`, `sender_hints`, and `supporter_bundle` (`/opt/secretmsg/secretmsg-private/api/src/billing.ts:8-12`), and the client's `BillingProducts` class still lists the same four (`apps/mobile-flutter/lib/api/billing.dart:10-21`). Neither side has `remove_ads`. Shipping a Play product the API does not recognise means the purchase is rejected; shipping the API change before the Play product exists means the client cannot resolve the product details. This is a hard blocker, not a follow-up.
- [ ] **Retire the four previous products and remove Polar:** the four previous products are retired and must be deactivated or made unavailable in Play Console. Polar is removed as a donations processor; the residual Worker code (`api/src/polar.ts`, `POLAR_WEBHOOK_SECRET` at `/opt/secretmsg/secretmsg-private/api/src/db.ts:26`, `POST /api/webhook/polar`, `GET /api/supporters`, the `donations` table in both schemas, and the fail-closed `POST /api/donation/google-pay`) was still present at the last verification. The listing, the privacy policy, and the data-safety annex all now describe an app with **no** donations path, so the code must catch up or the declarations will not match the shipped build.
- [ ] **Client privacy and supporter copy is stale:** the in-app copy still asserts there is no advertising SDK, no advertising ID, and no ad trackers, and the supporter screen still says the project is "zero ad trackers" (`apps/mobile-flutter/lib/data/static_content.dart`, `apps/mobile-flutter/lib/screens/supporters_screen.dart`). Those statements are now false and must be corrected in the client, together with the website privacy policy, before the ad-supported build ships. The Data safety form and this runbook already declare the opposite.

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
2. Confirm `minSdk` remains 24 as defined at `android/app/build.gradle:43`, and re-check Google Play's current target-API requirement before each release. The source does not pin API 36: `compileSdk` and `targetSdk` resolve from `flutter.compileSdkVersion` and `flutter.targetSdkVersion` at `android/app/build.gradle:25` and `android/app/build.gradle:44`. The ads plugin's own build declares `minSdk 24`, so the existing floor is compatible. Rebuild and retest if Play raises its floor.
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
8. Confirm `android/app/build.gradle:49-63` found `android/key.properties`; otherwise the AAB is debug-signed and is not upload-ready.
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
3. Bump `android_latest` in the public `/api/app-version` feed to the new release version and deploy that feed with the release. The feed currently exposes `android_latest` at `/opt/secretmsg/secretmsg-private/api/src/index.ts:85-89`; the Flutter app checks it on cold start and when requested from Settings and prompts when its installed version is behind (`apps/mobile-flutter/lib/ritual/update_check.dart:45-66`). Do not publish the AAB while leaving the feed stale.
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
