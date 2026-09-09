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

Signing is read from `android/key.properties` (see `key.properties.example`).
Without that file the release build falls back to the debug key, which Play
rejects — so a build meant for upload must be made on a machine that has it.

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
