# SecretMsg for Android

Flutter client for SecretMsg. Application id `net.secretmsg.android_app`.

## Running

```
flutter pub get
flutter run
```

## Tests

```
flutter test
flutter analyze
```

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

```
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols
```

`--obfuscate` strips Dart symbol names from the snapshot and takes roughly
470 KB off the download. It also makes crash traces unreadable on their own:
**keep the `build/symbols` directory for every release you ship**, or you will
not be able to symbolicate a stack trace from it.

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
that a user who silently migrates is a user who has to reinstall. Two things then
need a deliberate decision rather than a default:

- **The update feed stops being track-agnostic.** `GET /api/app-version` in the
  private repo (`api/src/index.ts`) returns one `url` for every client, currently
  `https://secretmsg.net/download`. That is correct only while Play is not
  publicly distributed; a Play-installed user who is behind will be sent to a page
  offering an APK their device cannot install over the Play copy. Resolving it
  needs per-track URLs plus a client that knows which track it is on — a product
  decision, not a build fix.
- **Which track the download page leads with.** Keep both (recommended) rather
  than replacing the APK, so existing download links and the SHA-256 in
  `apps/web/src/lib/appVersion.ts` keep resolving.

Retiring the sideload track, if it ever comes to that, means *stopping publishing
APKs* and saying so on the page — never re-signing or re-issuing an already
published version under a new certificate, which breaks every install that exists.

### A note on size

The `.aab` on disk is far larger than what anyone downloads. It carries native
libraries for three ABIs plus a deobfuscation map, and Play delivers only the
one ABI a device needs. Judge size by a single-ABI APK, not by the bundle:

```
flutter build apk --release --target-platform=android-arm64
```

The per-ABI APKs on the website also carry a hard ceiling: Cloudflare Workers
static assets reject any single file over 25 MiB. They stay under it because
`android/app/build.gradle` sets `jniLibs.useLegacyPackaging = true`, which
deflates `libflutter.so` and `libapp.so` instead of storing them uncompressed
for direct mmap. Those two libraries are 21.5 MB of a 26.6 MB x86_64 APK, so
deflating them roughly halves every download. The cost is one extraction step
when the app is installed; the installed footprint is unchanged.

Over half of that is the Flutter engine (`libflutter.so`), which is a fixed
cost. The next largest piece is `libapp.so`, the compiled Dart.

## Assets

`assets/roulette_prompts.json` holds the 9,000 dice prompts. They live in an
asset rather than in Dart source because compiled string constants land in the
AOT snapshot of every ABI and stay resident from launch, for a screen most
people never open. `RouletteData.load()` reads it lazily and caches it.

The asset stores only the six real categories. "All Vibes" is rebuilt at
runtime as their concatenation; it used to be shipped as a second verbatim copy
of all 9,000 prompts.
