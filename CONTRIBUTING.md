# Contributing to SecretMsg Client

Thank you for your interest in improving SecretMsg! We welcome contributions to our web frontend, mobile designs, and client tooling.

---

## Development Workflow

1. **Fork and Clone**:
   ```bash
   git clone https://github.com/your-username/secretmsg.git
   cd secretmsg
   ```
2. **Install Dependencies**:
   ```bash
   npm install
   ```
3. **Run with Offline Mock Mode**:
   Create `apps/web/.env` with:
   ```ini
   VITE_USE_MOCK="true"
   ```
   Start the Vite dev server:
   ```bash
   npm run dev
   ```
   This gives you instant mock messages, full inbox interaction, and prompt tests without needing access to any backend server.

---

## Code Quality Standards

- **TypeScript**: Strive for type safety across components and utilities.
- **Tailwind CSS**: Use predefined design tokens and avoid inline color hacks.
- **Privacy First**: Never introduce client-side analytics, session replay trackers, or third-party cookies.
- **Author Identity**: Keep commit authorship attributed to yourself without automated bot labels.

---

## Submitting Pull Requests

1. Create a feature branch: `git checkout -b feat/my-improvement`
2. Commit your changes: `git commit -m "feat: add animated prompt switcher"`
3. Push to your fork: `git push origin feat/my-improvement`
4. Open a Pull Request against `main`.
