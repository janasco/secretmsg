# SecretMsg for Android

Flutter client for SecretMsg. Application id `net.secretmsg.android_app`.
Current version **1.6.10** (`versionCode 25`) in `pubspec.yaml`.

The published sideload build is enumerated in
`apps/web/src/lib/appVersion.ts` (`APK_VERSION = 'v1.6.10'`), which is the
single source of truth for the version, sizes and SHA-256 checksums that
`DownloadPage` and `LandingPage` both read, so the download page cannot drift
from the artifacts.

| File | Size | Notes |
|---|---|---|
| `secretmsg-android-v1.6.10-arm64.apk` | 13.1 MB | 64-bit, recommended for most phones |
| `secretmsg-android-v1.6.10-arm32.apk` | 12.7 MB | 32-bit, older phones |
| `secretmsg-android-v1.6.10-x64.apk` | 13.3 MB | x86 64-bit, emulators and Chromebooks |

Per-ABI APKs are shipped because Cloudflare Workers static assets reject any
single file over 25 MiB. v1.6.8 and v1.6.9 are still on disk under
`apps/web/public/downloads/` (20–24 MB each) and remain downloadable, but they
are not the current build.

## Running

```
flutter pub get
flutter run
```

## Tests

```
flutter test        # 162 tests
flutter analyze     # lints, clean
```

The analyzer runs in **strict language mode** (`analysis_options.yaml` sets
`strict-casts`, `strict-inference` and `strict-raw-types`, nested correctly
under `analyzer: language:`). Do not move them to the top level — current
analyzers no longer accept the top-level form and emit `unsupported_option`
warnings. The file also turns off `constant_identifier_names`, because the
uppercase module-constant tables in `lib/data/static_content.dart` are
intentional.

Three accessibility checks run in the gate alongside the tests, all plain Dart
in `tool/a11y/` (no Flutter toolchain needed, so they finish in under a second
against a ten-minute gate):

| Check | What it finds |
|---|---|
| `dart run tool/a11y/test/detector_test.dart` | The detector's own self-test |
| `dart run tool/a11y/lint.dart` | Theme-blind colour literals — hardcoded dark values that render as light-on-light — and the full contrast matrix for both themes |
| `dart run tool/a11y/regen_baseline.dart --check` | Fails if a palette value moved without regenerating the recorded pairings in `tool/a11y/a11y_baseline.json` |

`flutter analyze` cannot see this class of defect, because nothing about the
offending code is ill-typed. A hardcoded dark gradient in both themes once
shipped with light-mode text on it at 1.06:1 contrast; these checks are what
catch it.

## Advertising

The app serves **ads**: a Google AdMob banner and an optional rewarded video.
The website serves none. A single one-time Google Play purchase, `remove_ads`,
permanently removes ads for the account on every device — it is not a
subscription. Four earlier products (`verified_badge`, `viewer_hints`,
`sender_hints`, `supporter_bundle`) are retired; `remove_ads` is the only entry
in the API's `PLAY_PRODUCTS` map, and the other client-side product constants in
`lib/api/billing.dart` remain only so historical purchases still resolve.

- **Consent**: personalised ads require consent in the EEA, the UK and
  Switzerland. Declining leaves you on non-personalised ads rather than locking
  you out (`AdsRequestPolicy.forConsent` in `lib/ads/ads_config.dart`).
- **Ad privacy options**: **Settings → Support & legal → Ad privacy options**
  opens Google's privacy options form. It is rendered only when the SDK reports
  that a choice is actually available to the user (`_required` in
  `settings_screen.dart`), so it is absent for users with no choice to make.
- **Kill-switch**: `ADS_ENABLED` on the API Worker, public at
  `/api/config/ads`, is currently **off**, so no ads are being served in
  production even though the SDK and ad units ship in the build. The client
  fails closed: `canServeAds` requires the remote flag, a resolved consent
  state, SDK readiness and a non-ad-free account, and
  `kAdsEnabledWithoutServerFlag` is `false`, so a missing, errored or stale
  flag (6-hour max age) means no ads.
- **Identifiers**: `kAdMobAppId`, `kBannerAdUnitId` and `kRewardedAdUnitId` are
  `String.fromEnvironment` build-time inputs read from
  `/opt/secretmsg/.secrets/admob.env` and are **never committed**. See
  `scripts/build_release.sh` for the canonical invocation. The app id uses the
  `ca-app-pub-…~…` tilde form and the ad units use the `…/…` slash form; all
  three must come from one AdMob account, which `adIdsSharePublisher` enforces
  so a cross-account paste produces a build that silently serves no ads.

## The gate

```bash
bash scripts/verify.sh
```

From the repository root. This is the **only** enforcement point for the project
— there is deliberately no CI and no `.github` directory, by decision, to avoid
GitHub Actions billing, and this script runs the equivalent checks locally so
the safety net survives that choice. It runs 15 named checks and takes 10+
minutes. For this app that means `flutter analyze`, `flutter test` (162 tests) and
the three `tool/a11y` checks; the rest cover the web client, the private API, and
file ownership. It must be green before any commit.

> **Ownership.** Everything runs as root, so files a build or an editor creates
> land owned by `root:root` and the human operator then cannot edit them. After
> creating files by hand, `chown -R janasco:janasco` them. The gate reconciles
> ownership of all git-tracked files in both repos and then asserts it, because
> the web build's prerender step rewrites hundreds of tracked files on every run
> and undoes a one-off `chown`.

## Release builds

There are two release artifacts and they are signed with two different keys.
Keeping them apart is the whole point of this section, so read it before
producing either one.

| Artifact | Key | Configured by | Built by |
| --- | --- | --- | --- |
| Play upload `.aab` | **upload** key | `scripts/setup-upload-keystore.sh` → `android/key.properties` | `scripts/build_release.sh aab` |
| Public sideload APKs | **sideload** key | `scripts/setup-sideload-keystore.sh` → `android/sideload-key.properties` | `scripts/build_sideload.sh` |

The upload key never signs a public artifact. Its only job is to hand a bundle
to Google Play App Signing, which re-signs it with a per-app key Google manages,
so shipping an APK signed with it would publish a Play credential to anyone who
downloads it.

The sideload key is the signature users actually install, which makes its
certificate a permanent, public fact about the app. It is therefore a real key
that is backed up, not a throwaway: v1.6.8 and v1.6.9 were published signed with
the **debug** key, which anyone can forge and which no Play-installed copy of
SecretMsg can ever be upgraded onto.

The two are separated by exactly one flag, `-PsideloadSigning=true`, which only
`scripts/build_sideload.sh` passes. Omit it and the release build signs with the
upload key exactly as it always did, so the Play path is unaffected. Gradle
refuses `-PsideloadSigning=true` when `android/sideload-key.properties` is
missing rather than quietly falling back to the debug key.

That one flag also tells the app which track it is on, by appending
`--dart-define=SECRETMSG_DISTRIBUTION_TRACK=sideload` (or `=play` without it) to
the `dart-defines` the Flutter CLI already passes. A build that knows its own
track can ask the update feed for that track's download page instead of assuming
one page serves everybody. Deliberately derived rather than declared separately:
a second flag is a second thing to forget, and a track that disagrees with the
signing key is the failure that produces an uninstall nobody can undo. See "Two
tracks that never merge" below for the default and the reasoning.

Both key files are gitignored, as are the keystores themselves. Passwords live
in `secretmsg-private/.env.production` and are never echoed or passed on a
command line.

> **Consequence to be aware of:** Android treats differently-signed builds of one
> package as different apps, so the two tracks can never converge and a user who
> sideloads SecretMsg can never move onto the Play version without uninstalling
> first, which deletes their local data. This is the unavoidable cost of
> publishing a build signed with a key you control, and it is a product decision,
> not something a build flag can fix. Ship the sideload APKs only if users are
> meant to stay off Play. The next section is the long form of that decision.

Signing for the upload artifact is read from `android/key.properties` (see
`key.properties.example`). Without that file the release build falls back to the
debug key, which Play rejects — so a build meant for upload must be made on a
machine that has it.

Build the upload bundle with the script, not with a bare `flutter build`:

```bash
set -a; . /opt/secretmsg/.secrets/admob.env; set +a
scripts/build_release.sh aab --obfuscate --split-debug-info=build/symbols
```

A bare `flutter build appbundle --release` **fails on purpose**: the AdMob
identifiers are build-time inputs that are never committed, and
`android/app/build.gradle` throws a `GradleException` on any release build that
would carry the placeholder app id. `scripts/build_release.sh` refuses a
missing, malformed, or cross-account identifier set before it starts. That
refusal is the feature — do not work around it by substituting a placeholder or
by editing the guard. `scripts/build_release.sh --check-only` validates the
identifiers without building anything.

`--obfuscate` strips Dart symbol names from the snapshot, and it also makes
crash traces unreadable on their own: **keep the `build/symbols` directory for
every release you ship**, or you will not be able to symbolicate a stack trace
from it. A build that skips it produces a snapshot nobody can debug in the
field, so pass it on every release.

### Two tracks that never merge

That warning is not a temporary rough edge, so it is worth stating exactly what it
means in practice. Android identifies an app by its package name **and** its
signing certificate, so the Play build (re-signed by Google Play App Signing) and
the sideload build (signed by `secretmsg-sideload.jks`) are two different apps to
the operating system even though both claim `net.secretmsg.android_app`. There is
no upgrade path across that line in either direction and there never will be:
Android refuses to install one over the other (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`)
and the only offered remedy is "uninstall first", which deletes the app's data
directory.

What a user actually loses is the device-local state — Daily Drop history,
check-in streaks, scheduled reminders, the cached inbox, the ad-free flag and the
saved sign-in (`lib/ritual/drop_store.dart`, `lib/ritual/streak_store.dart`,
`lib/ritual/reminders.dart`, `lib/sync/cache.dart`, `lib/ads/ads_flags.dart`).
The account, its messages, ranks, badges and verified purchases are server-side
and return on the next sign-in, which is what makes an accidental switch
survivable rather than fatal. `apps/web/src/pages/DownloadPage.tsx` tells
installers this in the same terms; keep the two in step.

The sideload key is a long-lived, load-bearing artifact for that reason, and it
needs a stricter regime than the upload key:

- **Back it up** the way the upload key is backed up: keystore, alias, both
  passwords and the certificate SHA-256 into the release password manager and an
  independent encrypted copy. The passwords belong in
  `secretmsg-private/.env.production`; the keystore itself never leaves the
  machine that holds it.
- **Never rotate it casually.** A new certificate cannot update an existing
  install either, so rotation is not a security improvement here — it is a mass
  uninstall event that orphans every sideloaded user in the field with no
  in-place path back. Rotate only to respond to an actual compromise, and accept
  the orphaning when you do.
- **Losing it ends the track.** Google Play supports requesting an upload-key
  reset; nothing equivalent exists for a key we sign public artifacts with. If the
  keystore or its passwords are gone, every future sideload release is a different
  app and the only honest move is to stop publishing APKs.
- v1.6.8 and v1.6.9 are the worked example of what a key change costs: they
  shipped on the debug key, so a v1.6.10 install cannot be layered over them and
  those users must uninstall first. The download page carries that warning
  because nothing in the old build can warn them for us.

**If Play reaches stable public release.** The default is to keep publishing
sideload APKs: Play is not available in every market, some users will not have a
Google account, and the sideload build is the distribution channel the website
already owns. Treat the two as parallel tracks rather than a migration, and expect
that a user who silently migrates is a user who has to reinstall. One of the two
decisions that were pending here is now built; the other is not.

- **The update feed is track-aware (done).** The client knows which track it is
  on at compile time, and asks the feed for that track's URL only.
  `android/app/build.gradle` derives it from the flag that already selects the
  signing key: whenever `-PsideloadSigning=true` is set it appends
  `--dart-define=SECRETMSG_DISTRIBUTION_TRACK=sideload` to the `dart-defines`
  the Flutter CLI already passes, and the same block rewrites the value to
  `play` when the flag is absent, so the key and the track are the same switch
  and cannot drift. `lib/distribution/track.dart` reads it; there is no second
  build flag to keep in step.

  **The compile-time default is the Play track**, and that is deliberate.
  `-PsideloadSigning` is an opt-in, so an absent flag already means "this is the
  Play upload path" at the signing layer; the track default says the same thing
  about the same artifact rather than contradicting it. The failure modes are
  also lopsided. A Play build that mislabels itself as sideload asks for the
  sideload page and hands a Play user an APK their device refuses to install
  over the Play copy — a silent misconfiguration that surfaces as a failed
  install on a stranger's phone. A Play build that correctly asks for `url_play`
  before one exists simply gets no update prompt: degraded, harmless, fixed by
  editing one line of the feed. So an app that cannot prove it is a sideload
  build behaves as a Play build.

  `GET /api/app-version` in the private repo (`api/src/index.ts`) now carries
  `url_sideload` alongside the legacy `url`, which is kept forever because every
  client released before this change reads only that key and it must keep
  resolving to the download page. The selection itself is
  `updateUrlForTrack` in `lib/ritual/update_check.dart`, and its fallback rules
  are deliberately asymmetric:

  - Sideload prefers `url_sideload`, falls back to the legacy `url`, then to a
    hard-coded `https://secretmsg.net/download`. That fallback is only safe
    because `url` *is* the sideload page; if `url` is ever repointed, the
    fallback must be deleted rather than kept "for compatibility".
  - Play never falls back to `url`, because `url` is the sideload page and
    falling back to it is the exact bug these fields exist to remove. It takes
    `url_play` or nothing, and "nothing" means the client stays silent.

  **Still open:** `url_play` is deliberately **absent** from the feed rather than
  stubbed, because Play is not published and there is no listing URL to name. An
  absent key is an unambiguous "no destination we can honour"; a placeholder
  would be a broken link that something would eventually open. Add `url_play`
  in the same change that makes the listing public — nothing needs rebuilding
  and no new client ships, the existing Play build picks it up on its next feed
  poll. Until then no Play-track user is redirected anywhere, because a Play
  build that finds no `url_play` shows no update prompt. There is still no
  decision recorded here about *which* Play listing URL to publish: that is the
  operator's to make at publication time.
- **Which track the download page leads with.** Keep both (recommended) rather
  than replacing the APK, so existing download links and the SHA-256 in
  `apps/web/src/lib/appVersion.ts` keep resolving. Still open.

Retiring the sideload track, if it ever comes to that, means *stopping publishing
APKs* and saying so on the page — never re-signing or re-issuing an already
published version under a new certificate, which breaks every install that exists.

### A note on size

The `.aab` on disk is far larger than what anyone downloads. It carries native
libraries for three ABIs plus a deobfuscation map, and Play delivers only the
one ABI a device needs. Judge size by a single-ABI APK, not by the bundle — and
build it with `scripts/build_sideload.sh`, because a bare
`flutter build apk --release` produces the *Play* track (no `-PsideloadSigning`,
native libs stored uncompressed) and would tell you nothing about the published
APK.

The per-ABI APKs on the website also carry a hard ceiling: Cloudflare Workers
static assets reject any single file over 25 MiB. They stay under it because
`android/app/build.gradle` sets `jniLibs.useLegacyPackaging = sideloadSigningRequested`,
which deflates `libflutter.so` and `libapp.so` instead of storing them
uncompressed for direct mmap.

Measured from the actual v1.6.10 artifacts (2026-09-29):

| APK | On disk | Uncompressed | `libapp.so` + `libflutter.so` stored |
|---|---|---|---|
| `x64` | 13.3 MB | 30.4 MiB | 8.5 MiB (from 20.6 MiB raw) |
| `arm64` | 13.1 MB | 28.9 MiB | 8.3 MiB (from 19.1 MiB raw) |
| `arm32` | 12.7 MB | 26.7 MiB | 7.9 MiB (from 16.9 MiB raw) |

So deflating the native libraries is worth roughly 12 MiB per download — a
little over half the on-disk size. For contrast, the v1.6.9 x64 APK still in
`apps/web/public/downloads/` stores those same two libraries uncompressed and is
23.0 MiB on disk against 13.3 MiB for v1.6.10.

The cost is one extraction step when the app is installed; the installed
footprint is unchanged. Over half of the remaining payload is the Flutter engine
(`libflutter.so`), which is a fixed cost. The next largest piece is `libapp.so`,
the compiled Dart.

## Assets

`assets/roulette_prompts.json` holds the 9,000 dice prompts. They live in an
asset rather than in Dart source because compiled string constants land in the
AOT snapshot of every ABI and stay resident from launch, for a screen most
people never open. `RouletteData.load()` reads it lazily and caches it.

The asset stores only the six real categories. "All Vibes" is rebuilt at
runtime as their concatenation; it used to be shipped as a second verbatim copy
of all 9,000 prompts.
