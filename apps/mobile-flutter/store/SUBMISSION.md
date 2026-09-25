# SecretMsg Play submission and release runbook

**Last verified:** 2026-09-25

This is the canonical checklist and release runbook for submitting `net.secretmsg.android_app` to Google Play. Data-safety answers remain in the controlled annex: [DATA_SAFETY.md](DATA_SAFETY.md).

## Open blockers

- [ ] **Play Console enrollment and app creation:** complete account registration and identity verification, then create the app with default language, app-not-game, free distribution, and package `net.secretmsg.android_app`. The application ID is defined at `android/app/build.gradle:40`.
- [ ] **Upload keystore:** generate, configure, back up, and use the release upload key. `android/key.properties` is gitignored; without it, Gradle falls back to the debug signing key at `android/app/build.gradle:49-63`.
- [ ] **Reviewer access:** the dedicated handle `playreview` is **provisioned and verified** in production D1 (display name "Play Review Demo", non-supporter, synthetic `email` placeholder, 10 backup codes, 4 seeded messages plus 1 quarantined moderation sample, rank "Newcomer"). Login was confirmed working against the live API. Remaining step: store its PIN and backup codes in the password manager and enter the exact credentials in **App content → App access**. Never put the PIN or backup codes in this repository.
- [x] **Public account deletion:** `https://secretmsg.net/delete-account` is **shipped and verified live** (HTTP 200, listed in `sitemap.xml`, linked from the privacy policy, FAQ, terms, safety tools, footer, and the in-app Settings screen). It is publicly reachable without installing the app, explains the recovery path for a forgotten PIN, and discloses what deletion does not reach. Enter this URL in **Data safety**.
- [ ] **Phone screenshots:** still pending; the operator is capturing them on their own phone. Capture at least four portrait screenshots at 1080×1920 or larger, using inbox, Daily Drop, Dice Prompt Roulette, and Sticker Studio as the subjects.
- [ ] **Closed testing and pre-launch review:** for a personal developer account created after 2023-11-13, keep at least 12 testers opted in continuously for 14 days, then apply for production access. Recruiting 20 or more provides headroom against dropouts; 20 is not the Play minimum. Review and fix findings in the pre-launch report before production.
- [ ] **Billing service account:** create and grant the Google Play API service account, then provision `GOOGLE_PLAY_SA_EMAIL` and the private key as `GOOGLE_PLAY_SA_KEY` in the production API secret store. Verify `GOOGLE_PLAY_PACKAGE_NAME=net.secretmsg.android_app` is present without printing any secret. The API fails closed with HTTP 503 when any of these values is absent (`/opt/secretmsg/secretmsg-private/api/src/index.ts:857-860`).

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
8. Create the four one-time managed products, provision the billing service account, and add a licence tester before testing purchases.
9. Start internal testing, then closed testing. For a new personal account, satisfy the closed-test requirement, review the pre-launch report, and apply for production access.

## Store listing assets

Only these two generated graphic files are canonical for this submission:

| Asset | Play requirement | Canonical file | Status |
|---|---|---|---|
| App icon | 512×512, 32-bit PNG/JPEG with no alpha | `store/play-icon-512.png` | Ready; verified 512×512 RGB PNG |
| Feature graphic | 1024×500, 32-bit PNG/JPEG with no alpha | `store/play-feature-1024x500.png` | Ready; verified 1024×500 RGB PNG |
| Phone screenshots | At least 2; use at least 4 at 1080×1920 or larger in portrait | Operator capture from a phone | Pending: inbox, Daily Drop, Dice Prompt Roulette, Sticker Studio |
| Tablet screenshots | Decision: opt out of tablet listing; do not prepare 7-inch or 10-inch screenshots | — | Opt-out selected |

Confirm that captured screenshots show the actual app, contain no unsupported promotional claims, and use only real product UI. Do not substitute launcher assets or web icons for the canonical Play files above.

## Listing copy

The canonical listing copy is maintained separately under `store/listing/`:

- `store/listing/title.txt`
- `store/listing/short_description.txt`
- `store/listing/full_description.txt`

Review the files immediately before uploading them. Play limits are 30 characters for the title, 80 for the short description, and 4000 for the full description. Select the Social category and relevant tags.

## App content declarations

- **Privacy policy:** `https://secretmsg.net/p/privacy`. The policy source is `apps/web/src/pages/PrivacyPage.tsx`, and the route is recognized by the app at `apps/mobile-flutter/lib/main.dart:63-82` and tested at `apps/mobile-flutter/test/deep_link_router_test.dart:16-35`. Verify the public page before submission.
- **Contact details:** website `https://secretmsg.net`; use `privacy@secretmsg.net` for privacy and `safety@secretmsg.net` for child-safety and abuse concerns. These addresses appear in the published policy sources.
- **Ads:** no ads.
- **App access:** declare that all or some functionality is restricted. Provision the `playreview` account, seed it, and enter its exact handle and PIN in Play Console. The app supports handle/PIN authentication at `/opt/secretmsg/secretmsg-private/api/src/index.ts:362-440`. Keep the PIN and backup codes only in the password manager, never in this document.
- **Content rating:** complete the IARC questionnaire honestly. SecretMsg hosts unrestricted user-generated communication, including anonymous user-to-user messages, so the answers will not support an Everyone rating. Anonymous communication rates strictly; expect Teen or higher, subject to the questionnaire result.
- **Target audience:** do not select an under-13 audience or age band. Review the Families-policy consequences before submitting the target-audience and content-rating forms.
- **Child safety standards:** provide the published child-safety policy at `https://secretmsg.net/p/child-safety-policy`, backed by `apps/web/src/pages/ChildSafetyPage.tsx`; identify `safety@secretmsg.net` as the child-safety contact. The app provides an in-app message-report action in `apps/mobile-flutter/lib/screens/inbox_screen.dart:1141-1228` and routes the policy URL at `apps/mobile-flutter/lib/main.dart:63-82`.
- **Data safety:** use the separate controlled annex, [DATA_SAFETY.md](DATA_SAFETY.md). For account deletion, the public URL is `https://secretmsg.net/delete-account` (shipped and verified); in-app deletion remains available from Settings.
- **Other declarations:** answer Government apps, Financial features, and Health as not applicable; this is not a News app.

## In-app products

Create four one-time managed products. The identifiers must match `PLAY_PRODUCTS` in `/opt/secretmsg/secretmsg-private/api/src/billing.ts:8-13` and `BillingProducts` in `apps/mobile-flutter/lib/api/billing.dart:10-21` exactly.

| Product ID | Type | Grants |
|---|---|---|
| `verified_badge` | One-time managed product | Verified badge |
| `viewer_hints` | One-time managed product | Viewer hints |
| `sender_hints` | One-time managed product | Sender hints |
| `supporter_bundle` | One-time managed product | All three |

Confirm every identifier in both source locations again whenever billing code changes. The client sends the purchase token to the API, which verifies it with Google before granting a perk (`apps/mobile-flutter/lib/api/billing.dart:80-148`).

## Billing service-account requirements

1. Enable the Google Play Android Developer API in the relevant Google Cloud project.
2. Create a dedicated service account and grant it access to the Play app with the financial/purchase permissions required to verify and acknowledge one-time product purchases.
3. Link or invite the service-account user in **Play Console → Users and permissions** according to Google Play's service-account setup instructions.
4. Store the service-account email as `GOOGLE_PLAY_SA_EMAIL`, its private key as `GOOGLE_PLAY_SA_KEY`, and the app package as `GOOGLE_PLAY_PACKAGE_NAME=net.secretmsg.android_app` in the production API secret store. Never commit, print, or paste the JSON key.
5. Add the tester's Google account as a **licence tester**. Add the app to the tester's Library → installed apps before testing billing.
6. Upload the app to a test track before testing; purchases cannot complete against a local build.
7. Test each of the four product IDs, including a restore/verification retry, and confirm the API does not return 503, 502, or 402 unexpectedly. The environment names are declared at `/opt/secretmsg/secretmsg-private/api/src/db.ts:22-38`; missing values intentionally fail closed at `/opt/secretmsg/secretmsg-private/api/src/index.ts:857-860`.

## Build and upload procedure

Run from `apps/mobile-flutter/`.

1. Confirm the current app version and increment it in `pubspec.yaml`. The verified baseline is `1.6.9+24` at `apps/mobile-flutter/pubspec.yaml:17`; always increase the build number (`+N`) for every Play upload.
2. Confirm `minSdk` remains 24 as defined at `android/app/build.gradle:43`, and re-check Google Play's current target-API requirement before each release. The source does not pin API 36: `compileSdk` and `targetSdk` resolve from `flutter.compileSdkVersion` and `flutter.targetSdkVersion` at `android/app/build.gradle:25` and `android/app/build.gradle:44`. Rebuild and retest if Play raises its floor.
3. Run:

   ```bash
   flutter analyze
   flutter test
   ```

4. Build the only supported release bundle command:

   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```

5. Archive `build/symbols` under the exact release version. Losing the matching symbol files makes production stack traces unreadable.
6. Verify the signing certificate with Android SDK build tools before upload. `apksigner verify --print-certs` operates on an APK signed by the upload key; use a same-key diagnostic APK and verify that its certificate matches the backed-up upload certificate. Verify the AAB's JAR signature separately with `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`.
7. Confirm `android/app/build.gradle:49-63` found `android/key.properties`; otherwise the AAB is debug-signed and is not upload-ready.
8. Upload `build/app/outputs/bundle/release/app-release.aab` to **Internal testing** first. Confirm Play App Signing enrolment, then install from Play rather than sideloading.
9. Exercise sign-up, handle/PIN login, sending with the bot check, receiving and replying, pairing, blocking/reporting, account deletion, update prompting, and all four Play Billing products on a real device.
10. A brand-new developer account or app may take several days to review. Follow the Play Console's displayed review state rather than assuming a fixed duration.

## Order of operations

1. Complete Play Console enrollment and identity verification; create the app.
2. Generate and back up the upload keystore; configure `android/key.properties`.
3. Capture and validate phone screenshots; keep the selected tablet opt-out.
4. Upload the obfuscated AAB to internal testing and enrol in Play App Signing.
5. Enter the canonical listing copy and assets.
6. Complete privacy, app access, content rating, target audience, child safety, and Data safety declarations; verify the public deletion URL before submission.
7. Provision the reviewer account `playreview`, seed it, and enter its credentials in Play Console.
8. Create the four products, provision the billing service account, and add a licence tester.
9. Validate internal testing, including sign-in, safety flows, deletion, update feed, and billing.
10. Promote to closed testing. For a qualifying new personal account, maintain 12 testers continuously for 14 days; use 20+ testers for operational headroom.
11. Review the pre-launch report, fix crashes or policy issues, and apply for production access.
12. Publish production after approval. Google does not offer a percentage selector for the first production release; for subsequent updates, roll out at 20%, monitor, then increase to 100%.

## Per-release runbook

Repeat this section for every version.

1. Confirm the current target-API floor in Play Console and verify the installed Flutter SDK resolves above it; the source does not hardcode a target API.
2. Increment the version name as appropriate and always increase the build number in `pubspec.yaml`.
3. Bump `android_latest` in the public `/api/app-version` feed to the new release version and deploy that feed with the release. The feed currently exposes `android_latest` at `/opt/secretmsg/secretmsg-private/api/src/index.ts:79-87`; the Flutter app checks it on cold start and when requested from Settings and prompts when its installed version is behind (`apps/mobile-flutter/lib/ritual/update_check.dart:43-61`). Do not publish the AAB while leaving the feed stale.
4. Re-check the Play policy declarations, privacy and child-safety pages, Data safety annex, and public account-deletion URL.
5. Run `flutter analyze` and `flutter test`; resolve all failures before building.
6. Build with the canonical obfuscated command:

   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```

7. Archive `build/symbols` with the exact version and build number. Never reuse another release's symbol directory.
8. Verify the upload certificate and AAB signature, then confirm the release used `android/key.properties` rather than the debug fallback.
9. Upload to internal testing. Smoke-test `/api/health`, one public profile lookup, sign-up, PIN login, send/receive, bot check, reply, pairing, blocking/reporting, account deletion, update prompting, and billing.
10. For a new qualifying personal account, complete the closed test and pre-launch-report review before requesting production access.
11. Promote through the required tracks. For subsequent production updates, use a 20% staged rollout, monitor crashes, purchases, and ANRs, then increase to 100% only after the holdback is healthy.
12. After rollout, confirm older installed versions receive the expected update prompt and retain the matching symbol archive.

## Controlled annex

The Play Data safety form is maintained separately in [DATA_SAFETY.md](DATA_SAFETY.md). Do not copy or inline its answers here; update the annex when backend data practices change, then reconcile the Console declaration from that controlled source.
