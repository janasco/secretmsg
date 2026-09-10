# Contributing to SecretMsg

Thank you for your interest in improving SecretMsg! We welcome contributions to the web platform, the Flutter Android app, and client tooling.

---

## Repository Layout

| Path | What it is |
|---|---|
| `apps/web` | React 18 + Vite + Tailwind CSS SPA serving both `secretmsg.net` (public) and `app.secretmsg.net` (account hub) |
| `apps/mobile-flutter` | Native Flutter Android client (the primary mobile app) |
| `site/public`, `apps/mobile-android` | Legacy static prototype and its old Capacitor wrapper — kept for reference, no longer deployed |
| `LEGAL/` | Terms of Service, Privacy Policy, Disclaimer |

The backend API lives in a separate private repository. Client apps talk to it over REST at `https://api.secretmsg.net`.

---

## Development Workflow

### Web (`apps/web`)

```bash
npm install          # workspace root; apps/web is a workspace member
npm run dev          # Vite dev server (default http://localhost:5173)
npm run build        # tsc + vite build — run this before opening a PR
npm run preview      # serve the production build locally
```

- The app calls the production API by default. Override with `VITE_API_URL` (plus `VITE_PUBLIC_URL`, `VITE_ACCOUNT_APP_URL`) to target another environment.
- A mock API mode exists for offline UI work in `apps/web/src/lib/mockApi.ts`.
- Code changes go through TypeScript: keep `npm run build` (which runs `tsc`) clean.

### Flutter Android app (`apps/mobile-flutter`)

```bash
cd apps/mobile-flutter
flutter pub get
flutter run                        # debug on a device/emulator
flutter test                       # unit tests
flutter analyze                    # lints — must stay clean
flutter build apk --release        # sanity-build a release APK
```

Run `flutter test` and `flutter analyze` before opening a PR. See `apps/mobile-flutter/README.md` for release signing and build flags.

---

## Design & Engineering Standards

- **Handle & input validation**: board links and usernames are at least 4 characters (`[a-zA-Z0-9_\-.]{4,30}`). All compose input is sanitized client-side; the API re-sanitizes server-side and enforces the recipient's filtered words.
- **Typography & font scaling**: use large, accessible text as standard (`text-base` for body copy, `text-sm` minimum for auxiliary metadata). Avoid micro-fonts.
- **Theme & appearance consistency**: support the 3-choice appearance system (`light`, `dark`, `system` default) via `apps/web/src/lib/theme.ts`, with high contrast in both dark and light styles.
- **Privacy by default**: never introduce client-side analytics, session replay trackers, third-party cookies, or telemetry. This is a product guarantee — the platform ships no analytics or crash reporters, and PRs must not change that.
- **No secrets in the client**: never place API tokens, webhook secrets, or billing keys in client code or bundles. Secrets live only in the private repo's encrypted secret store.
- **Paired sessions are read-only**: any new write endpoint must reject `scope: 'read'` sessions with `403`. Safety actions like reporting are the deliberate exception.
- **Safety UX**: write controls shown for signed-in owners must have a clear read-only equivalent for paired sessions — never render a control that will fail with `403`.

---

## Submitting Pull Requests

1. Create a feature branch: `git checkout -b feat/my-improvement`
2. Commit your changes: `git commit -m "feat: enhance sticker template exporter"`
3. Push to your fork: `git push origin feat/my-improvement`
4. Open a Pull Request against `main`.

Keep commits attributed to personal contributor identities.
