# SecretMsg v2.0 Redesign Guide — "Your inbox, on your home screen"

**Status:** approved, Phase 1 in progress · **Target:** v1.4 → v1.5 → v2.0
**Audience:** contributors to `apps/mobile-flutter` (Flutter) and `secretmsg-private/api` (edge API)

## 0. Why

NGL-style links are forgettable. Retention comes from **ritual + social
obligation + presence on the phone**. v2.0 turns SecretMsg from "a link you
forget" into a **daily ritual** (Duolingo streaks × Snapchat urgency), while
looking and feeling like a flagship Android app — never a shrunken website.

North-star metric: **day-7 retention** of new board owners.
Supporting metrics: daily check-in rate, Daily Drop completion, push opt-in
rate, story-share rate, streak length distribution.

## 1. Design principles (non-negotiable)

1. **Never a webpage.** No WebView content visible to users, no website
   footer in-app, no copy that sends users to a browser. The Turnstile
   WebView stays (real-origin token) but is always 0 px / offscreen behind a
   native "Checking you're human…" state.
2. **Thumb-first.** Primary action (Send) in the thumb zone (center FAB);
   inbox reachable in one tap from anywhere; back always lands on inbox.
3. **One motion language.** Shared-element inbox→message transitions,
   physics dice, celebration + haptics on rank-ups. Every new screen reuses
   `lib/widgets/motion.dart` (to be created) — no bespoke animations.
4. **Obsidian system.** `AppColors` + `AppTheme` are the only styling source.
   No new colors without updating `theme.dart`.
5. **Offline-graceful.** Daily Drop, streaks, and reminders all work with no
   network (local-first, server-enhanced later).

## 2. Pillar 1 — Daily ritual engine

### 2.1 Daily Drop (the reason to open the app)

- One prompt card per calendar day, picked deterministically from the local
  template pool: `index = dayNumberSinceEpoch % pool.length` (no backend
  needed for v1.4; server-driven pools come in v2.0).
- Card shows a **live countdown** to midnight local time ("expires in 4h 12m").
  Unanswered Drops vanish — scarcity drives opens.
- Answering = pre-filled composer addressed to your own board link flow
  (share it out) **or** a private journal-style answer stored on-device.
  v1.4: answering marks the Drop done and fires the streak check-in.
- Files: `lib/ritual/daily_drop.dart` (pure pick/expiry logic, unit-tested),
  `lib/screens/daily_drop_screen.dart`, `lib/widgets/drop_countdown.dart`.

### 2.2 Streaks with teeth (extends `lib/gamification/streaks.dart`)

Current rule (keep): any authenticated refresh = check-in; consecutive
calendar days grow the count; a miss resets to 1; calendar-day math only.

v1.4 additions:
- **Streak freeze**: each user holds 1 freeze (earned back every 7-day streak).
  A missed day consumes the freeze instead of resetting (count pauses, day
  not counted). Pure function `applyFreeze({storedCount, freezes})`.
- **Streak repair (supporter perk)**: within 48 h of a break, supporters may
  restore the previous count once per 30 days. Gated client-side by
  `is_premium`; enforced server-side in v2.0.
- **Streak UI**: flame + count in the inbox header; "freeze saved you" and
  "repair available" states; all strings in one place (`streaks.dart`).

### 2.3 Vibe check-in

Five-second mood tap (😭😐🙂🤩🔥) on first inbox open per day. Unlocks that
day's bonus templates. Stored on-device (`SharedPreferences`-level simple
store, NOT secure storage — moods are not credentials). v1.4: local only.

### 2.4 Notification schedule (local-first)

| # | Trigger | Title/body | Payload route |
|---|---------|-----------|---------------|
| 1 | 9:00 local, if Drop unanswered | "Today's Drop is live 🔥" / "{prompt}" | `/drop` |
| 2 | 20:00 local, if Drop unanswered | "4 hours left on today's Drop ⏳" | `/drop` |
| 3 | 21:30 local, if no check-in today | "Keep your {n}-day streak alive 🔥" | `/inbox` |
| 4 | On rank-up (in-app event) | "You hit {tier}! 🏆" + celebration | `/inbox` |

Rules: never more than 2 pushes/day; all reminders auto-cancel when the
underlying action completes; quiet hours 22:00–08:00 respected; every type
has a Settings toggle (default ON for 1–3, ON for 4).

Implementation: `flutter_local_notifications` + exact-allowance permission
flow on Android 12+ (`SCHEDULE_EXACT_ALARM` rationale screen) and
`POST_NOTIFICATIONS` runtime permission on Android 13+.
Service: `lib/ritual/reminders.dart` (schedule/cancel/query), initialized in
`main()` before `runApp`. Timezone-safe: reschedule on every cold start
(simple + robust, no boot receiver needed for v1.4).

## 3. Pillar 2 — Android superpowers

### 3.1 Remote push (FCM) — v1.4b, needs Firebase console steps

- Deps: `firebase_core` + `firebase_messaging`. Requires the human to create
  the Firebase project, register `net.secretmsg.android_app`, and commit
  `android/app/google-services.json` (git-ignored) + apply the
  `com.google.gms.google-services` plugin.
- Backend contract (to be built in `secretmsg-private/api`):
  `POST /api/push/register {fcm_token}` (auth) and server sends
  `message:new` data pushes. Client maps them to `MessagingStyle`
  notifications **with inline Direct Reply** (reply posts to
  `POST /api/inbox/:id/reply` from the background handler).
- Until FCM lands, local notification #3 plus a **reply action on the
  in-app message card** cover the loop.

### 3.2 Home-screen widget (v1.5)

Glanceable inbox count + today's Drop prompt via `home_widget` plugin +
`HomeWidgetProvider` (Kotlin). Tapping deep-links (`/inbox`, `/drop`).

### 3.3 App shortcuts (v1.5)

`quick_actions`: New Message, My Link / QR, Today's Drop. Static shortcuts
in `AndroidManifest.xml` + dynamic "last board" shortcut.

### 3.4 Expressive polish (v1.5)

Dynamic color opt-in, edge-to-edge (already themed), predictive back,
per-app language, in-app review prompt after rank-up (`in_app_review`),
notification channels per type with proper importance levels.

## 4. Pillar 3 — Social obligation loops

- **Story-first sharing** (v1.5): one-tap export sized for IG/Snap/TikTok
  stories with the board link baked into the sticker. Every share is an ad
  and pulls the sender back to check replies.
- **Squad challenges** (v2.0): weekly prompt pools + leaderboards; needs
  `challenge_id` on messages (API change — spec in v2.0 planning).
- **Rank seasons** (v2.0): monthly reset, exclusive season badges, season
  history on profile. Server-enforced.

## 5. Pillar 4 — Signature craft

- Shared-element inbox→detail, spring dice, celebration overlay
  (`celebration.dart` + haptics + optional sound toggle).
- Boot splash → session check → inbox, no marketing detour for signed-in
  users (keep `LandingScreen` for signed-out + shared-link fallback only).
- Settings split into sections (currently 1100+ lines): Account, Ritual &
  Notifications, Privacy & Safety, About.

## 6. Phase plan

- **Phase 1 → v1.4 (now)**: reminders service + permission flow, Daily Drop
  engine + screen + countdown, streak freeze/repair, vibe check-in,
  notification settings toggles. FCM code scaffolded; server push follows
  once Firebase console steps are done.
- **Phase 2 → v1.5**: widget, shortcuts, expressive polish, story export,
  in-app review.
- **Phase 3 → v2.0**: squads, seasons (with API changes), server-driven
  Drop pools.

## 7. File map (Phase 1)

```
lib/ritual/daily_drop.dart       pure pick/expiry logic + tests
lib/ritual/reminders.dart        schedule/cancel/query local notifications
lib/ritual/vibe.dart             mood store (simple KV, not secure storage)
lib/ritual/streak_store.dart     persisted streak+freeze state (extends streaks.dart logic)
lib/screens/daily_drop_screen.dart
lib/widgets/drop_countdown.dart
lib/screens/settings_notifications.dart  (toggles UI, extracted from settings_screen)
test/daily_drop_test.dart
test/reminders_test.dart         (pure parts: schedule computation)
```

## 8. Definition of done (Phase 1)

- [ ] Cold start reschedules all reminders; unit tests green
- [ ] Drop card + countdown correct across midnight/DST (tests)
- [ ] Freeze consumes instead of reset; repair gated + tested
- [ ] ≤2 pushes/day enforced; toggles work; quiet hours respected
- [ ] `flutter analyze` clean, release APK built, dogfooded 3 days
