# First Play Console submission

Everything needed to get `net.secretmsg.android_app` onto Play, in order.
Blockers first, because four of them will stop a submission dead.

---

## 1. Blockers

### 1.1 targetSdk is 34 — Play will reject this

Flutter 3.24.5 defaults to `targetSdkVersion 34`, confirmed in the built
manifest. Play requires new apps to target a recent API level (35 for
submissions from Aug 2025, and it advances every August). 34 is below the floor.

Fix in `android/app/build.gradle` — replace the Flutter default:

```gradle
    defaultConfig {
        applicationId = "net.secretmsg.android_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 35          // was flutter.targetSdkVersion (34)
        ...
    }

    android {
        compileSdk = 35         // must be >= targetSdk
```

Check the current requirement in the Console before picking the number, then
rebuild and re-test — a targetSdk bump changes real runtime behaviour
(notification permission, foreground service rules, intent filtering).

### 1.2 A reviewer cannot sign in

Sign-in is an emailed one-time code. A Play reviewer has no access to your
mailbox, so they cannot get past the login screen, and "we couldn't access the
app" is one of the most common rejection reasons.

Under **App content → App access**, choose *All or some functionality is
restricted* and supply working credentials. You need one of:

- a demo account whose OTP is fixed and does not expire, or
- a bypass code the API accepts for one nominated demo address, or
- a pairing code path documented for the reviewer (note that codes expire in
  5 minutes, so this only works if you also relax the TTL for that account).

None of these exist yet. This needs building before submission.

### 1.3 "Blocked Senders" is advertised but not implemented

There is no blocks table and no block endpoint in the API — the schema holds
`users`, `messages`, `auth_sessions`, `reports`, `donations`, `rate_limits`,
`pair_codes` and `purchases`, and nothing handles blocking.

The feature is nonetheless named in the README, in the settings UI, and in
`LEGAL/TERMS_OF_SERVICE.md` ("You may block abusive sender devices"). Shipping
a store listing or Terms that promise a safety control which does not work is a
policy and consumer-protection problem, and Play's user-generated content
expectations lean on blocking specifically.

Either build it or strike the claim from the Terms and the UI before shipping.
The store copy in `listing/full_description.txt` already omits it deliberately.

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
2. Fix targetSdk, rebuild, retest
3. Resolve the reviewer sign-in problem
4. Decide on Blocked Senders: build it or remove the claim
5. Add the web account-deletion page
6. Generate the keystore, fill in `key.properties`
7. Create the app, upload an internal-testing build
8. Fill in the listing with the assets and copy in this directory
9. Complete App content, Data safety and the content rating
10. Create the in-app products, link the service account, test a purchase
11. Promote to production
