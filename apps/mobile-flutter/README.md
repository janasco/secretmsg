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
> package as different apps. A user who sideloads SecretMsg can therefore never
> move onto the Play version without uninstalling first, which deletes their
> local data. This is the unavoidable cost of publishing a build signed with a
> key you control, and it is a product decision, not something a build flag can
> fix. Ship the sideload APKs only if users are meant to stay off Play.

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
