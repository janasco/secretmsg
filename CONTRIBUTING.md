# Contributing to SecretMsg

Thank you for your interest in improving SecretMsg! We welcome contributions to the web platform, the Flutter Android app, and client tooling.

---

## Repository Layout

| Path | What it is |
|---|---|
| `apps/web` | React 18 + Vite + Tailwind CSS SPA served from `secretmsg.net` (public boards + account hub, single host), prerendered to 239 static pages |
| `apps/mobile-flutter` | Native Flutter Android client (the primary mobile app) |
| `scripts/` | `verify.sh` (the gate), `build_release.sh`, `build_sideload.sh`, `deploy-frontend.sh`, keystore setup scripts |
| `LEGAL/` | Terms of Service, Privacy Policy, Disclaimer — **a convenience copy only** |

The backend API lives in a separate private repository. Client apps talk to it over REST at `https://api.secretmsg.net`.

> **The `LEGAL/` markdown is not the canonical text.** The policy users and Play
> reviewers actually see is the prerendered page: `/p/privacy/`, `/p/terms/`,
> `/p/cookies/`, `/p/disclaimer/`, authored in
> `apps/web/src/pages/PrivacyPage.tsx` and siblings, with a parallel copy for
> the Android app in `apps/mobile-flutter/lib/data/static_content.dart`. If
> `LEGAL/*.md` and the shipped page disagree, **the page is right** — and the
> page is what needs correcting, in a change to the React source.
>
> Relatedly, the canonical legal URLs are under `/p/`. A bare `/privacy` or
> `/terms` matches the `/:username` route and returns the homepage shell, so
> never link to one in code or documentation.

---

## The Gate

```bash
bash scripts/verify.sh
```

**Run this before every commit.** It is the only enforcement point in this
project: there is deliberately **no CI and no `.github` directory**, by decision,
to avoid GitHub Actions billing, and this script runs the equivalent checks
locally so the safety net survives that choice. Please do not add a workflow or
propose one as an improvement.

It runs 15 named checks, prints PASS/FAIL per check, and takes 10+ minutes —
give it a generous timeout and read the whole output, because a truncated log
looks like a green summary over a red section.

| Area | Checks |
|---|---|
| Web | `tsc --noEmit`, `vitest run` (110 tests), `npm run build` + prerender, blog link integrity, a11y colour scan |
| Android | `flutter analyze`, `flutter test` (162 tests), three `tool/a11y` checks |
| API (private repo) | `npm run api:test` (48 tests), esbuild bundle, `node --check` on the admin CLI |
| Files | ownership reconcile, then an assertion that every tracked file is owned by `janasco` |

Two things to expect and not fight:

- **Running the gate dirties generated files.** The web build re-stamps
  `apps/web/public/sitemap.xml`, `feed.xml`, `robots.txt` and `blog-index.json`
  with new `lastmod` values derived from source mtimes, and the prerender step
  rewrites the tracked post JSON. `git status` showing only those files modified
  afterwards is expected, not a change to commit.
- **Ownership.** Everything runs as root, so anything you create is
  `root:root` and the human operator then cannot edit it in their own editor.
  Run `chown -R janasco:janasco <path>` on files you create. The gate also
  reconciles and asserts this, because the build's output undoes a one-off
  `chown` on every run.

---

## Development Workflow

### Web (`apps/web`)

```bash
npm install          # workspace root; apps/web is a workspace member
npm run dev          # Vite dev server (default http://localhost:5173)
npm run build        # tsc + vite build + prerender — run this before opening a PR
npm run preview      # serve the production build locally
```

`npm run typecheck` and `npm test` exist only in `apps/web/package.json`, so run
those from `apps/web` (or `npm --prefix apps/web run typecheck` from the root):

```bash
npm --prefix apps/web run typecheck
npm --prefix apps/web test
npm --prefix apps/web run a11y   # colour-remap bypass + contrast
```

- The app calls the production API by default. Override with `VITE_API_URL` (plus `VITE_PUBLIC_URL`) to target another environment.
- A mock API mode exists for offline UI work in `apps/web/src/lib/mockApi.ts`, enabled with `VITE_USE_MOCK=true`.
- There is no `VITE_DONATION_URL` and no donation checkout any more; Polar.sh and the tiered supporter perks have been removed. Funding is advertising in the Android app plus one one-time `remove_ads` purchase.
- Code changes go through TypeScript: keep `npm run build` (which runs `tsc`) clean.

### Flutter Android app (`apps/mobile-flutter`)

```bash
cd apps/mobile-flutter
flutter pub get
flutter run                        # debug on a device/emulator
flutter test                       # 162 unit/widget tests
flutter analyze                    # lints — must stay clean
```

Run `flutter test` and `flutter analyze` before opening a PR. See
`apps/mobile-flutter/README.md` for release signing and build flags.

**Do not try to produce a release artifact with a bare `flutter build apk
--release` or `flutter build appbundle --release`.** Both are expected to fail:
AdMob identifiers are build-time inputs that are never committed, and the
Gradle build throws on any release build that would carry the placeholder app
id. That refusal is a deliberate guard — do not work around it with a
placeholder or by editing `build.gradle`. Use `scripts/build_release.sh` and
`scripts/build_sideload.sh`, which validate the identifiers first.

---

## Design & Engineering Standards

- **Handle & input validation**: board links and usernames must match `^[a-z0-9_.-]{4,30}$` — lowercase letters, digits, underscore, hyphen and dot, 4 to 30 characters. All compose input is sanitized client-side; the API re-sanitizes server-side and enforces the recipient's filtered words.
- **Typography & font scaling**: use large, accessible text as standard (`text-base` for body copy, `text-sm` minimum for auxiliary metadata). Avoid micro-fonts.
- **Theme & appearance consistency**: support the 3-choice appearance system (`light`, `dark`, `system` default) via `apps/web/src/lib/theme.ts`, with high contrast in both dark and light styles. **Do not hardcode a colour literal** in either client. The gate runs two accessibility scanners that nothing else can see — `apps/mobile-flutter/tool/a11y` (theme-blind literals and the contrast matrix) and `apps/web/scripts/a11y-color.mjs` (Tailwind colour utilities whose base class is remapped for light mode but whose opacity-modified form is not, e.g. `text-amber-200/90` silently opting out of a remap defined for `text-amber-200`). `flutter analyze` cannot see either class of bug, because nothing about that code is ill-typed.
- **Privacy by default**: never introduce client-side analytics, session replay trackers, third-party cookies, or telemetry. This is a product guarantee — the platform ships no analytics or crash reporters, and PRs must not change that. Firebase is present in the Android app for Cloud Messaging only (`firebase_core`, `firebase_messaging`); adding `firebase_analytics` would break this guarantee.
- **No secrets in the client**: never place API tokens, webhook secrets, AdMob identifiers, or billing keys in client code or bundles. They are build-time inputs or they live only in the private repo's secret store.
- **Paired sessions are read-only**: any new write endpoint must reject `scope: 'read'` sessions with `403`. Safety actions like reporting are the deliberate exception.
- **Safety UX**: write controls shown for signed-in owners must have a clear read-only equivalent for paired sessions — never render a control that will fail with `403`.

---

## Submitting Pull Requests

1. Create a feature branch: `git checkout -b feat/my-improvement`
2. Run `bash scripts/verify.sh` and confirm it is green.
3. Commit your changes with a conventional-commit subject (`type(scope): description`); long-form prose in the body explaining *why* is the house style here.
4. Push to your fork: `git push origin feat/my-improvement`
5. Open a Pull Request against `main`.

There is no CI to run these checks for you, so step 2 is on you.


---
