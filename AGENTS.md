# AGENTS.md — SecretMsg (public repo)

`secretmsg` is the public monorepo: the marketing/website front end and the
Flutter Android client. The Cloudflare Worker API, the admin CLI and the
production secrets live in the sibling private repo `/opt/secretmsg/secretmsg-private`.

## Git Commit Identity

Every commit in every repo under the janasco account is authored **and**
committed as `janasco <janasco@duck.com>`. Verified: 142 commits, one author, one
committer, zero `Co-authored-by` / `Signed-off-by` / machine-attribution trailers.

- Never add a `Co-authored-by` trailer or any other AI/machine attribution.
- Format is conventional commits: `type(scope): description`. Types seen in
  history: `build`, `chore`, `docs`, `feat`, `fix`. Scopes in use: `ads`,
  `android`, `download`, `mobile`, `store`, `web`.
- Bodies are long-form prose explaining *why*, with the verification that was
  actually done. That is the house style here, not an accident of history.

**Commit template.** A template exists at `/home/janasco/.gitmessage`, wired up
by `commit.template` in `/home/janasco/.gitconfig` (it lists the allowed types
and scopes). It is *not* in this repo's local config, and a session running as
root reads `/root/.gitconfig` — so `git config commit.template` returns nothing
and `git commit` will not open the template. Read it if you want the list:
`cat /home/janasco/.gitmessage`. The local `user.name`/`user.email` *are* set
in `.git/config`, so identity is correct even as root.

## Environment

- Repo root: `/opt/secretmsg/secretmsg`
- Commands run as **root** with `HOME=/root`.
- **Node is not on the default PATH.** `node`/`npm`/`npx` are symlinks in
  `/home/janasco/.local/bin` (→ `/home/janasco/.nodejs/bin/`). Prefix with
  `export PATH="/home/janasco/.local/bin:$PATH"`. Every script in `scripts/`
  does this for you; a bare `npx` in a fresh shell will fail.
- Flutter: `/opt/flutter/bin/flutter` (also not on the default PATH). Both
  build scripts resolve `PATH` → `$FLUTTER_BIN` → `/opt/flutter/bin/flutter`.
- Android SDK: `/opt/android-sdk` (build-tools 35.0.0 is what the keystore
  scripts put on PATH). `apps/mobile-flutter/android/local.properties` points
  `sdk.dir` and `flutter.sdk` at both.
- 4 CPUs, ~9.5 GB RAM. That number is the reason for the Gradle memory caps below.

## Key Paths

| Path | What |
|---|---|
| `apps/web` | React 18 + Vite + Tailwind SPA, prerendered to 239 HTML files |
| `apps/web/src/worker.ts` | Cloudflare Worker (static-assets binding `ASSETS`) |
| `apps/web/src/security-headers.ts` | The one security-header list, shared by `_headers` and the Worker |
| `apps/web/src/lib/appVersion.ts` | Published APK version, sizes, SHA-256 |
| `apps/web/public/downloads/` | Sideload APKs served at `secretmsg.net/downloads` |
| `apps/mobile-flutter` | Flutter Android client, package `net.secretmsg.android_app` |
| `apps/mobile-flutter/android/app/build.gradle` | Signing configs, AdMob guard, packaging |
| `apps/mobile-flutter/store/` | Play runbook: `SUBMISSION.md`, `RELEASE_NOTES.md`, `DATA_SAFETY.md` |
| `scripts/` | `verify.sh`, `build_release.sh`, `build_sideload.sh`, `deploy-frontend.sh`, two keystore setup scripts |
| `/opt/secretmsg/secretmsg-private` | Worker API, `admin/`, `.env.production` (all secrets) |
| `/opt/secretmsg/.secrets/` | Outside both repos: AdMob env, both keystores, archived release artifacts |

Read `apps/mobile-flutter/store/SUBMISSION.md` before any Play work and
`apps/mobile-flutter/README.md` before any signing work. They are the
authoritative runbooks and they are current.

## The Gate: `bash scripts/verify.sh`

**There is deliberately no CI. Do not add `.github/workflows`, do not add any
other CI config, and do not propose it as an improvement.** `scripts/verify.sh`
says why in its own header: GitHub Actions is not used, by decision, to avoid
GitHub Actions billing, and the script runs the equivalent checks locally so the
safety net survives that choice. There is no `.github` directory in either repo.

`scripts/verify.sh` is the single gate and it must be green before any commit.
It runs, and prints PASS/FAIL per check:

- **Web** — `tsc --noEmit`, `vitest run`, `npm run build` (which is `tsc` +
  `vite build` + prerender), blog link integrity via
  `node scripts/analyze-links.mjs --emitted`.
- **Android** — `flutter analyze`, `flutter test`.
- **API (secretmsg-private)** — `npm run api:test`, an esbuild bundle of
  `api/src/index.ts`, `node --check admin/manage.js`.

It takes 10+ minutes. Give it a generous timeout and read the whole output; a
green summary line over a red section does not exist, but a truncated log does.

## Constraints That Are Expensive to Undo

These are decisions that took real work to reach. A session that does not know
them will undo them by accident.

1. **No CI, ever (see above).** The cost saving is the reason. `scripts/verify.sh`
   is the replacement, and it is not optional.

2. **GitHub Releases carry release notes only.** Never attach an APK, an AAB or
   any binary. The APKs live on `secretmsg.net/downloads` and in Play; the AAB
   lives in `/opt/secretmsg/.secrets/release-artifacts/`. There is no `gh` CLI
   on this host — the runbook in `store/RELEASE_NOTES.md` creates releases
   through the REST API using `GITHUB_TOKEN` from
   `secretmsg-private/.env.production`.

3. **AdMob identifiers are build-time inputs and are never committed.** They
   come from `/opt/secretmsg/.secrets/admob.env` (mode 600, owned by janasco,
   outside both repos) and are exported before a build:
   `set -a; . /opt/secretmsg/.secrets/admob.env; set +a`.
   `apps/mobile-flutter/android/app/build.gradle` **throws a `GradleException`
   on any release build that would carry the placeholder app id**, and
   `scripts/build_release.sh` refuses a missing, malformed, or cross-account set
   before it starts. That refusal is the feature. A bare
   `flutter build appbundle --release` failing is the guard working — do not
   work around it by substituting a placeholder or by editing the guard.

4. **The Play upload key and the sideload key are separate, and the sideload key
   must never be rotated casually.** `android/key.properties` (alias `upload`,
   `/opt/secretmsg/.secrets/secretmsg-upload.jks`) only ever hands a bundle to
   Play App Signing, which re-signs it with Google's per-app key — so shipping
   it on a public artifact would publish a Play credential.
   `android/sideload-key.properties` (alias `sideload`,
   `/opt/secretmsg/.secrets/secretmsg-sideload.jks`) is the signature real users
   install, which makes its certificate a permanent public fact about the app.
   Rotation is not a security improvement: a new certificate cannot update an
   existing install, so it is a mass-uninstall event that orphans every sideloaded
   user in the field, with no in-place path back. Google offers a Play
   upload-key reset; nothing equivalent exists for a key we sign public artifacts
   with. Losing the sideload keystore ends the track — the only honest move is to
   stop publishing APKs. Both property files are gitignored, as are `*.jks`.

5. **The two Android tracks never merge.** Android identifies an app by package
   name **and** signing certificate, so the Play build and the sideload APKs are
   different apps to the OS despite both claiming `net.secretmsg.android_app`.
   There is no upgrade path in either direction
   (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`); the only remedy is uninstall-first,
   which deletes the data directory. v1.6.8 and v1.6.9 shipped on the *debug*
   key and are the worked example of what a key change costs.
   A single flag, `-PsideloadSigning=true`, carries the whole distinction: it
   reroutes signing to the sideload key, deflates the native libs
   (`jniLibs.useLegacyPackaging`), and appends
   `--dart-define=SECRETMSG_DISTRIBUTION_TRACK=sideload` so the app knows its own
   track. Only `scripts/build_sideload.sh` passes it. Never pass that
   `--dart-define` by hand — a track that disagrees with the signing key is
   exactly the failure the derivation exists to prevent. Compile-time default is
   `play`, deliberately: a build that cannot prove it is a sideload build behaves
   as a Play build.

6. **Everything runs as root, so chown what you create.** Files an agent writes
   land owned by `root:root`, and the human operator then cannot edit them in
   their own editor. After creating files, run
   `chown -R janasco:janasco <path>`. This has already bitten: several hundred
   files were left root-owned and uneditable. At the time of writing, 234
   git-tracked files in this repo are still root-owned — that count is the
   measure of the problem, not a target.

## Commands

```bash
# The gate. Must be green before any commit. 10+ minutes.
bash scripts/verify.sh

# Play upload AAB. AdMob env first, or the build refuses.
set -a; . /opt/secretmsg/.secrets/admob.env; set +a
scripts/build_release.sh aab --obfuscate --split-debug-info=build/symbols

# Sideload APKs (per-ABI, sideload key). Same AdMob env requirement.
scripts/build_sideload.sh

# Frontend deploy. Copies apps/web/dist to /tmp/fe-dist and runs wrangler
# against a generated config. Sources secretmsg-private/.env.production.
bash scripts/deploy-frontend.sh

# Validate AdMob identifiers without building anything.
scripts/build_release.sh --check-only
```

Notes that cost time to rediscover:

- `scripts/build_release.sh` accepts `aab` or `apk` and forwards any further
  arguments to `flutter build`, so `--obfuscate --split-debug-info=build/symbols`
  is passed straight through. **Keep `build/symbols` for every release you
  ship** — without it a production stack trace from an obfuscated build cannot
  be symbolicated.
- `scripts/build_release.sh` / `build_sideload.sh` default `GRADLE_OPTS` to
  `-Xmx1G -XX:MaxMetaspaceSize=512m`. `GRADLE_OPTS` does **not** size the Gradle
  daemon — that is `org.gradle.jvmargs` in
  `apps/mobile-flutter/android/gradle.properties`, which is committed at
  `-Xmx4G -XX:MaxMetaspaceSize=2G`. On a ~9.5 GB host a long release build at
  the committed value runs the daemon, the Kotlin daemon and the AOT compiler
  together, so **lower `org.gradle.jvmargs` to the same
  `-Xmx1G -XX:MaxMetaspaceSize=512m` before starting a long Android build, and
  restore `-Xmx4G -XX:MaxMetaspaceSize=2G` afterwards.** A build that gets
  killed never reaches the restore and leaves the caps in a committed file, so
  check `git diff apps/mobile-flutter/android/gradle.properties` before you
  commit anything after an Android build.
- An AAB build takes over 20 minutes. Do not start one speculatively.
- `scripts/deploy-frontend.sh` sets `run_worker_first = false` in the generated
  wrangler config. That is the whole reason for the header gotcha below; do not
  flip it to "fix" a routing problem.

## Release Artifacts and How to Verify Them

| Artifact | Build output | Published / archived as |
|---|---|---|
| Play upload AAB | `apps/mobile-flutter/build/app/outputs/bundle/release/app-release.aab` | `/opt/secretmsg/.secrets/release-artifacts/<version>/secretmsg-v<version>-upload.aab` + `symbols/` |
| Sideload APKs (×3) | `apps/mobile-flutter/build/app/outputs/flutter-apk/app-{arm64-v8a,armeabi-v7a,x86_64}-release.apk` | `apps/web/public/downloads/secretmsg-android-v<version>-{arm32,arm64,x64}.apk` |
| Deobfuscation symbols | `apps/mobile-flutter/build/symbols/` | `release-artifacts/<version>/symbols/` |

Current state: version `1.6.10+25` (`apps/mobile-flutter/pubspec.yaml`),
`APK_VERSION = 'v1.6.10'` in `apps/web/src/lib/appVersion.ts`, AAB archived but
**not yet uploaded to Play**.

Verification worth doing rather than assuming:

- **Hashes.** `apps/web/src/lib/appVersion.ts` carries a SHA-256 per APK
  recomputed from the bytes. `sha256sum apps/web/public/downloads/*.apk` must
  match it, or DownloadPage and LandingPage are advertising a checksum that is
  wrong. Recompute from the file; never carry the value over from the previous
  release.
- **Which key signed what.** `apksigner verify --print-certs` on each APK (must
  be the sideload key, never debug, never upload) and
  `jarsigner -verify -verbose -certs` on the AAB. The build scripts print the
  exact command.
- **Which track each artifact really is.** `url_play` present / `url_sideload`
  absent in the Play AAB, and the reverse in the sideload APKs. The
  `-PsideloadSigning` flag becomes a compile-time constant, so the Dart compiler
  constant-folds the track switch and tree-shakes the arm it cannot take — the
  two artifacts differ in exactly the way the design predicts and nowhere else.
  That asymmetry is the strongest available evidence the signing flag, the
  dart-define and the client logic are all wired correctly.
- **Size ceiling.** Cloudflare Workers static assets reject any single file over
  25 MiB, which is why the site ships per-ABI APKs and why the sideload path
  deflates `libflutter.so`/`libapp.so`. Check every APK before publishing. The
  Play AAB is ~61 MB and is never served by us, so the ceiling does not apply to
  it.

**Staleness is real and it has happened here.** An AAB was once staged for Play
upload three hours behind source, containing none of the work that had landed in
the meantime — and the sideload APKs were stale the same way. Worse, two
*different* builds would both have claimed to be `1.6.10`, so a user reporting
"1.6.10 is broken" could not be told which one they were running. A stale
artifact that still looks current is more dangerous than an obviously old one.

Detect it before trusting any artifact:

```bash
# When did the app source last change?
git log -1 --format='%h %ci %s' -- apps/mobile-flutter/lib/

# When was each artifact actually built?
stat -c '%y %n' apps/mobile-flutter/build/app/outputs/bundle/release/app-release.aab
stat -c '%y %n' /opt/secretmsg/.secrets/release-artifacts/*/secretmsg-v*-upload.aab
stat -c '%y %n' apps/web/public/downloads/secretmsg-android-v*-*.apk
```

If any artifact's mtime predates the last commit that touched
`apps/mobile-flutter/lib/`, it is stale: rebuild it. Also check that the version
in `pubspec.yaml`, the version in `appVersion.ts`, the version in the archived
artifact filename and the version in the download filenames all agree, and that
the archived `symbols/` came from the *same* build as the AAB next to them.

## Known Gotchas

- **The asset layer answers before the Worker runs.** `deploy-frontend.sh`
  deploys with `run_worker_first = false`, so static assets and the 239
  prerendered pages are served by the Workers static-assets binding and the
  Worker never executes for them. The Worker only sees `/inbox`, `/settings`,
  `/:username`, `/reply/:token`, 404s, redirects and the CSP report endpoint
  (and `/downloads/*`, which `isAssetRequest` classifies as an asset, so the
  APKs are served by the asset layer too). **Headers set in `worker.ts` do not
  apply to the 239 prerendered pages.** What covers them is
  `apps/web/dist/_headers`, generated by `apps/web/scripts/prerender.mjs` from
  the `SECURITY_HEADERS` list in `apps/web/src/security-headers.ts`. Both paths
  read that one list, so edit it there and nowhere else. Corollary: a header
  that "works on /settings but not on /blog" is not a bug, it is this.
- **Tailwind's content glob scans raw text.** `apps/web/tailwind.config.js`
  globs `./src/**/*.{js,ts,jsx,tsx}` and matches every file as plain text —
  comments and Worker-only files included, not parsed as modules. A stray word
  in a prose comment that happens to be a utility name (`inline` is the one that
  has bitten) adds a rule, changes the stylesheet hash and rehashes the whole
  bundle for a rule nothing uses. If a build produces a diff in an asset hash
  for no visible reason, grep the comments for the utility name before
  investigating anything else.
- **Running the gate dirties `apps/web/public/sitemap.xml`.** `npm run build`
  runs `scripts/blog.mjs`, which regenerates `public/sitemap.xml` with `lastmod`
  values derived from source file mtimes — so any file you touched since the
  last commit re-stamps it. The same script also rewrites `public/feed.xml`,
  `public/robots.txt` and `public/blog-index.json`.
  **`lastmod`-only churn is not a change to commit, but a change in the post
  COUNT is.** Blog posts publish on a schedule (`published` always ships,
  `scheduled` ships once due in UTC, `draft` never), so a post that has become
  due appears in `public/posts/` and in `sitemap.xml` together on the next
  build. Committing one without the other leaves the two artifacts disagreeing,
  and `route-policy.test.ts` asserts they agree — because that mismatch is a
  real defect, while time passing is not.
  If you revert one of them with `git checkout`, revert both.
- **Security headers are report-only, on purpose.** The CSP is
  `Content-Security-Policy-Report-Only`, and there is deliberately no enforcing
  policy and no HSTS. The API fails closed, so an enforcing policy with a wrong
  `connect-src` or `frame-src` takes down signup, OTP, send and report in one
  change. Do not promote it to enforcing without reading the promotion criteria
  in `apps/web/src/security-headers.ts` first, and do not add
  `'unsafe-inline'` to `script-src`: it silences exactly the reports the policy
  exists to produce. A test in `route-policy.test.ts` recomputes the theme-script
  digest from `index.html`, so a drifting theme script fails the gate.
- **A bare `flutter build appbundle --release` fails on purpose**, and so does
  `flutter build apk --release` without `-PsideloadSigning=true` if you meant the
  sideload track. Both are the guards in `build.gradle` working. Use the scripts.
- **Line-number references in `store/SUBMISSION.md` drift** as `build.gradle`
  grows; they have been wrong before. Resolve the reference yourself before
  relying on it.
- **`.opencode/skills/` is a curated subset, not a mirror.** Ten skills were
  vendored from ECC on purpose; the upstream plugin was deliberately rejected
  because its `permission.ask` hook auto-approves anything matching
  `^(npm test|npx vitest|...)`, and the pattern is only anchored at the start.
  Do not re-vendor it, and read `.opencode/README.md` before touching that
  directory.
