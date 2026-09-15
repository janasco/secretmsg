# First Play Console submission

Everything needed to get `net.secretmsg.android_app` onto Play, in order.
Blockers first, because four of them will stop a submission dead.

---

## 1. Blockers

### 1.1 targetSdk floor — resolved by the Flutter 3.47 upgrade

Flutter 3.47 defaults to `compileSdkVersion 36`, which tracks past Play's
target-API floor (35 for submissions since Aug 2025; it advances every
August). `android/app/build.gradle` intentionally follows
`flutter.compileSdkVersion` / `flutter.targetSdkVersion`, so no pin is
needed. Still check the Console for the current number before each release —
a floor bump changes real runtime behaviour and needs a rebuild + retest.

### 1.2 Reviewer sign-in — solved with a provisioned account

Sign-in is handle + PIN (Auth V2), so no mailbox access is needed at all.
Before submission, create a dedicated reviewer account and hand over the
credentials under **App content → App access** (*All or some functionality
is restricted*):

1. Sign up handle `playreviewer` (or similar) with a known PIN.
2. Save its 10 backup codes somewhere safe — they are the recovery path if
   the reviewer locks the account.
3. Seed the inbox with a few tame messages and one reply so every tab has
   content.

Pairing codes expire in 5 minutes and are not suitable for reviewers.

### 1.3 Sender blocking — shipped

Was a blocker (advertised, not implemented). Now done: `blocked_senders`
table, `POST /api/inbox/:id/block`, block sender buttons in the inbox, and
Blocked Senders management in Settings (app) and on web. Terms, README, and
store copy are consistent.

### 1.4 Account deletion needs a web URL

Play requires apps with account creation to offer deletion **both** in-app and
from a publicly reachable page that does not require the app. In-app exists
(Settings → Delete my account). The web page does not — add one under
`secretmsg.net` and give the URL in **App content → Data safety**.

---

## 2. One-time setup

1. **Play Console account** — one-off 25 USD registration, plus identity
   verification, which can take days. Start this first.
2. **Upload keystore** — generate and back it up; see
   `android/key.properties.example`. Losing it means never updating the app.
3. **Create the app** in the Console: name, default language, app-not-game,
   free.
4. **App signing** — accept Play App Signing. Your upload key signs the
   bundle; Google re-signs for distribution.

---

## 3. Store listing assets

| Asset | Requirement | Status |
|---|---|---|
| App icon | 512×512 PNG, no transparency | **Generated** → `store/play-icon-512.png` |
| Feature graphic | 1024×500 PNG | **Generated** → `store/play-feature-1024x500.png` |
| Phone screenshots | 2–8, min 320px, 16:9 or 9:16 | **You must capture these** |
| Tablet screenshots | optional | — |
| Title / short / full description | 30 / 80 / 4000 chars | **Drafted** → `listing/` |

Screenshots need a running device or emulator, which is why they are not here.
Good candidates: the inbox, the composer, Filtered Words in settings, the dice
roulette, and the pairing code dialog.

The launcher icons in `android/app/src/main/res/mipmap-*` were regenerated from
the brand mark and now include adaptive foreground/background layers plus a
monochrome layer for themed icons — they are no longer the stock Flutter logo.

---

## 4. App content declarations

Work through **App content** in the Console. For this app:

- **Privacy policy:** `https://secretmsg.net/p/privacy`
- **Ads:** no ads.
- **App access:** restricted — see blocker 1.2.
- **Content rating:** complete the IARC questionnaire. Answer honestly that the
  app hosts unmoderated user-to-user communication and allows users to exchange
  freely-typed messages. Expect Teen or higher; anonymous messaging rates
  strictly.
- **Target audience:** do **not** select any under-13 age band. Anonymous
  messaging aimed at children triggers Families policy requirements this app
  does not meet.
- **Data safety:** answers prepared in `DATA_SAFETY.md`.
- **Child safety standards:** required for social apps. You need a published
  child safety policy (exists: `secretmsg.net/p/child-safety-policy`), an
  in-app way to report CSAE, and a contact address for child-safety concerns.
- **Government apps / financial features / health:** no to all.
- **News app:** no.

---

## 5. In-app products

Create four **one-time** managed products. The ids must match
`PLAY_PRODUCTS` in the API and `BillingProducts` in the app **exactly**, or
verification rejects every purchase:

| Product ID | Grants |
|---|---|
| `verified_badge` | Verified badge |
| `viewer_hints` | Viewer hints |
| `sender_hints` | Sender hints |
| `supporter_bundle` | All three |

Server-side verification also needs a Google Cloud service account with the
Play Developer API enabled, linked under **Users and permissions**, with its
JSON key in `.env.production` as `GOOGLE_PLAY_SA_EMAIL` and
`GOOGLE_PLAY_SA_KEY`, plus `GOOGLE_PLAY_PACKAGE_NAME`. Until those are set the
verify endpoint fails closed with a 503, which is the intended behaviour.

Purchases cannot be tested until a build is live on a track and your account is
added as a licence tester.

---

## 6. Build and upload

```
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Keep `build/symbols` for every release or crash traces will be unreadable.

Upload to **Internal testing** first. It reaches testers in minutes, and it is
the only way to exercise Play Billing end to end. Promote to closed, then open
or production once purchases and sign-in have been verified on a real device.

First review of a brand-new developer account commonly takes several days.

---

## 7. Order of operations

1. Play Console account and identity verification (slowest — start now)
2. Confirm the current target-API floor, rebuild, retest
3. Provision the reviewer handle + PIN account
4. Add the web account-deletion page (§1.4, still open)
5. Generate the keystore, fill in `key.properties`
6. Create the app, upload an internal-testing build
7. Fill in the listing with the assets and copy in this directory
8. Complete App content, Data safety and the content rating
9. Create the in-app products, link the service account, test a purchase
10. Promote to production

---

## 8. Release runbook (every version)

1. Bump `version:` in `pubspec.yaml` (`1.2.0+3` → name+code; code must rise).
2. `flutter analyze` clean, `flutter test` green.
3. `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`
   — archive `build/symbols` with the version number or crash traces die with it.
4. Upload to **Internal testing**, verify on a real device: signup, PIN login,
   send with bot check, reply, pairing code, purchase sandbox.
5. Smoke the API the build talks to: `/api/health`, one public profile lookup.
6. Promote closed → open/production in stages; watch for the first review wave
   (brand-new developer accounts commonly wait several days).
