# Agent skills (curated from ECC)

These ten skills are vendored from [ECC](https://github.com/affaan-m/ECC), MIT
licensed, Copyright (c) 2026 Affaan Mustafa. The licence text is in
[ECC-LICENSE](ECC-LICENSE). Upstream commit `e482e579415fde18357cafce70f177ae19fd7f03`.

## Why a subset

Upstream ships 292 skill directories and a plugin that registers hooks on
`tool.execute.before`, `tool.execute.after`, `shell.env` and `permission.ask`.
None of that is vendored here, on purpose. Two things were left out:

- **The plugin.** Its `permission.ask` hook auto-approves any `bash` command
  matching `^(npm test|npx vitest|npx jest|pytest|go test|cargo test)`. The
  pattern is anchored only at the start, so a chained command beginning with
  `npm test` would be auto-approved without asking. For a repository that holds
  an Android upload keystore, a service-account key and D1 credentials, giving
  away a bash approval prompt is not a trade worth making for the convenience.
- **The other 282 skills.** Most cover stacks this project does not use (Go, C++,
  Java, PHP, Rust, Spring, Postgres). Loading them all bloats the skill index
  with descriptions that never match. The ten kept here map to what SecretMsg
  actually is: a Flutter/Dart Android app, a React/TypeScript site, and a
  TypeScript Cloudflare Worker API.

Upstream's own `instructions` array is also not used. It points at ECC's
`AGENTS.md` and `CONTRIBUTING.md`, which would displace this repository's
conventions. The local `opencode.json` deliberately does not set
`instructions`.

## The ten

| Skill | Why here |
|---|---|
| `dart-flutter-patterns` | Flutter idioms for the Android app |
| `flutter-dart-code-review` | Review pass for Dart changes |
| `react-patterns` | The marketing site is React/TSX |
| `react-testing` | Vitest suite in `apps/web` |
| `react-performance` | Prerendering and bundle size matter here; the AdMob SDK added ~2.4 MB |
| `security-review` | Auth, OTP, message routing, backup handling |
| `security-scan` | Dependency and secret scanning |
| `tdd-workflow` | Complements the existing suite |
| `verification-loop` | The repo already gates on `scripts/verify.sh`; this is a second opinion, not a replacement |
| `api-design` | The Cloudflare Worker API |

## Refreshing or changing the set

Re-copy from upstream at a pinned commit, and re-read the plugin's hooks before
considering them. Do not vendor a skill without checking its frontmatter: opencode
silently filters out any `SKILL.md` lacking a `name` or `description`, so a
malformed copy looks like a successful install that never triggers.

These are agent instructions, not project dependencies. They do not affect the
build, the release gate, or anything that ships in the app.
