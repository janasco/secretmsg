# Contributing to SecretMsg Client

Thank you for your interest in improving SecretMsg! We welcome contributions to our web frontend, mobile designs, and client tooling.

---

## Development Workflow

1. **Fork and Clone**:
   ```bash
   git clone https://github.com/janasco/secretmsg.git
   cd secretmsg
   ```
2. **Serve Public Prototype**:
   ```bash
   npx serve site/public
   ```
   Open `http://localhost:3000`. All screens are wired with local mock state and live browser storage.

---

## Design & Engineering Standards

- **Handle & Input Validation**: All board links and usernames must enforce a minimum length of 4 characters (`[a-zA-Z0-9_\-\.]{4,30}`) and pass through `SecretMsgSanitize` (`site/public/js/sanitize.js`).
- **Typography & Font Scaling**: All pages must use large, accessible text as standard (`text-base` for normal body copy, `text-sm` minimum for auxiliary metadata). Avoid micro-fonts.
- **Theme & Appearance Consistency**: Support the 3-choice appearance system (`dark`, `light`, `system` default) using `SecretMsgTheme` (`site/public/js/theme.js`). Ensure high contrast in both dark obsidian and light card styles.
- **Header Navigation Stability**: Keep header navigation minimal (2 primary links) to ensure zero layout breaks across viewport breakpoints. Auxiliary links belong in the footer columns.
- **Privacy by Default**: Never introduce client-side analytics, session replay trackers, third-party cookies, or invasive telemetry.
- **Commit Authorship**: Keep commits attributed to personal contributor identities without automated bot co-authors.

---

## Submitting Pull Requests

1. Create a feature branch: `git checkout -b feat/my-improvement`
2. Commit your changes: `git commit -m "feat: enhance sticker template exporter"`
3. Push to your fork: `git push origin feat/my-improvement`
4. Open a Pull Request against `main`.

