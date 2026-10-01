# Agent skills (curated from ECC)

These seventeen skills are vendored from [ECC](https://github.com/affaan-m/ECC),
MIT licensed, Copyright (c) 2026 Affaan Mustafa. The licence text is in
[ECC-LICENSE](ECC-LICENSE).

**Two upstream pins, recorded rather than averaged.** The original ten came from
`e482e579415fde18357cafce70f177ae19fd7f03`. The seven added for the interface
redesign came from `c70874fae9eb0e5ad0365beb7e2955899fd1d30f`, which is upstream
several months later. They are not the same revision of the upstream tree, so a
future "refresh from the pin" has to say which set it means rather than assuming
one hash covers both.

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

## The seven added for the redesign

| Skill | Why here |
|---|---|
| `accessibility` | The gate enforces contrast; this is the reasoning behind it |
| `frontend-a11y` | Focus order, semantics, and the remap table in `index.css` |
| `design-system` | Tokens, scales and component APIs — the layer the redesign is building |
| `frontend-design-direction` | Choosing and defending a direction, which is what the prototype settled |
| `loop-design-check` | Reviewing an agent loop for spinning or gaming its own verifier |
| `motion-foundations` | Easing, duration and the `prefers-reduced-motion` contract |
| `liquid-glass-design` | The `.glass-panel` and `.dark-island` surfaces are this technique |

Deliberately not vendored: `frontend-patterns` overlaps `react-patterns`, and the
remaining ~1,020 upstream skills cover stacks this repository does not contain.

## Refreshing or changing the set

Re-copy from upstream at a pinned commit, and re-read the plugin's hooks before
considering them. Do not vendor a skill without checking its frontmatter: opencode
silently filters out any `SKILL.md` lacking a `name` or `description`, so a
malformed copy looks like a successful install that never triggers.

These are agent instructions, not project dependencies. They do not affect the
build, the release gate, or anything that ships in the app.
