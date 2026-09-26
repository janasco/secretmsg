# Play Store release notes

Play Console's **Release notes** field is capped at **500 characters**. Each entry
below is already trimmed to fit, ready to paste.

Derived from git history: each version's entry is the user-visible change set for
that version, taken from the commits between the previous release and this one.
Commits that only touch the website, the API, or release tooling are excluded
unless they changed app behaviour.

**v1.6.10 is the version in the current upload bundle**
(`/opt/secretmsg/.secrets/release-artifacts/v1.6.10/secretmsg-v1.6.10-upload.aab`,
versionCode 25). It is not yet uploaded to Play. Its entry covers the
business-model change — the app is now ad-supported, with a one-time
`remove_ads` purchase — together with the Play Billing library upgrade. v1.6.9
was prepared but never uploaded, so its entry is kept for reference only.

---

## v1.6.10 — current, ready to upload (491 chars)

Ads, and a one-off way to remove them.

• Ad-supported now: a small banner, plus a short optional video that can earn
  a streak freeze.
• One one-off purchase — remove ads — removes them for good. No subscription.
• Ads are in the Android app only. The website has none.
• Senders are still never asked who they are, and your data is still not sold.
  Messages are not used for ads.
• Updated to the current Google Play Billing library (8.0.0); purchase
  unlocking and restore re-verified.

## v1.6.9 — superseded, never uploaded (493 chars)

Privacy, stability and accessibility pass.

• Deleting your account now also wipes local data: cached inbox, queued
messages, streaks and progress.
• Backup codes and sticker images no longer leave temporary files behind.
• Fixed crashes and stale state from rapid navigation and closing dialogs.
• Dice prompts load off the UI thread, so the screen opens instantly.
• Accessibility: labelled controls, larger tap targets, better contrast.
• Removed an unnecessary restricted alarm permission.

---

## Historical versions

These shipped before the Play release. Kept for reference and changelog parity.

### v1.6.8 — 2026-09-21 (430 chars)
Inbox pagination, Play Store assets and client fixes.

• The inbox now loads more messages as you scroll instead of showing a fixed
list.
• Smoother filtered-tray browsing with the same paging.
• Fixed queued messages being dropped when you were offline.
• Fixed a dice timer that could keep running after leaving the screen.
• Supporters list now shows real data only.
• Added Play Store feature graphic and submission checklist.

### v1.6.7 — 2026-09-18 (346 chars)
Security and abuse-prevention hardening.

• Signup, sending a message, and reporting now require a human bot check.
• Stronger rate limits across sign-in, sending and reporting.
• One-time backup codes are now single-use and stored as salted hashes.
• Sign-in sessions can be revoked centrally.
• New: public web page to request account deletion.

### v1.6.6 — 2026-09-18 (310 chars)
Performance and stability.

• Faster startup: theme, reminders, push and sync now initialise together.
• Your inbox loads in one round trip instead of several.
• Profile and rank data cached locally between launches.
• Signing out now clears cached data properly.
• Avatars are cached so they appear instantly.

### v1.6.5 — 2026-09-18 (175 chars)
Light mode polish.

• Comprehensive light-theme sweep across every screen.
• Improved contrast behind the human-verification panel.
• More consistent spacing and card styling.

### v1.6.4 — 2026-09-18 (165 chars)
Sticker Studio fixes.

• Sticker editor respects screen cutouts and system bars.
• Layout stays correct across screen sizes.
• Better spacing around the save action.

### v1.6.3 — 2026-09-18 (183 chars)
Verification and layout fixes.

• Human-verification panel now matches the app theme.
• Fixed card layout and spacing issues in the inbox.
• Improved spacing after successful actions.

### v1.6.2 — 2026-09-18 (162 chars)
Composer improvements.

• Human verification is now visible and clearly explained.
• Better message-inspiration suggestions.
• Set your display name during setup.

### v1.6.1 — 2026-09-17 (117 chars)
Composer fixes.

• Fixed the human-verification widget being invisible.
• Fixed text overflow in message inspiration.

### v1.6.0 — 2026-09-17 (222 chars)
Offline support.

• Messages you write while offline are queued and sent automatically when
you reconnect.
• Your inbox is cached for instant, offline viewing.
• New sync status row shows when messages are waiting to send.

### v1.5.0 — 2026-09-17 (244 chars)
Major feature release.

• Filtered Words: messages matching your blocklist are held for review.
• Prompt roulette: thousands of conversation starters.
• Sticker Studio: build a shareable story sticker.
• Moderation tray to review held messages.

### v1.4.8 — 2026-09-17 (135 chars)
Session fixes.

• You stay signed in after signing up or recovering an account.
• Fixed bottom navigation alignment on notched screens.

### v1.4.7 — 2026-09-17 (60 chars)
New sliding navigation bar with an animated notch indicator.

### v1.4.6 — 2026-09-17 (147 chars)
Profile polish.

• Generated avatars for every profile.
• Themed Daily Drop prompts.
• Brighter app icon for light mode.
• Improved share link row.

### v1.4.5 — 2026-09-17 (70 chars)
Full theme support: follow your system setting, or pick light or dark.

### v1.4.4 — 2026-09-17 (77 chars)
In-app update prompts, visible app version, and a sign-out confirmation step.

### v1.4.3 — 2026-09-17 (93 chars)
Automatic handle generation, a backup-code gate before losing access, and the
new brand icon.

### v1.4.2 — 2026-09-17 (102 chars)
Handles generated for you at signup, smoother recipient lookup, and more helpful
placeholder examples.

### v1.4.1 — 2026-09-17 (52 chars)
New welcome onboarding and first-run download setup.

### v1.4.0 — 2026-09-17 (90 chars)
Reminders and daily ritual engine, plus push notification support, with
per-ABI downloads.

### v1.3.0 — 2026-09-17 (67 chars)
Single source of truth for app version metadata across web and app.

### v1.2.0 — 2026-09-11 (59 chars)
Randomly generated usernames and optional custom usernames.

### v1.1.0 — 2026-09-10 (29 chars)
First public Android release.

---

## Writing notes for the next release

1. Bump `version:` in `apps/mobile-flutter/pubspec.yaml` (the `+N` is the
   versionCode and must increase).
2. Build the bundle, then archive it and its symbols.
3. Add an entry above the current version, newest first.
4. Keep the entry under 500 characters. Count it:
   ```bash
   awk 'BEGIN{RS=""}{n=length($0); if(n>0) print n}' <<<"$NOTES"
   ```
5. Write for someone who reads it on their phone in the Play listing: what
   changed for them, not what changed in the code. Lead with the most valuable
   change, and put privacy and stability fixes ahead of cosmetic tweaks.
6. Tag and publish the GitHub release (see below).

## GitHub releases

Every shipped version has a GitHub release in `janasco/secretmsg` carrying these
notes as its body. **No binaries are attached** — the APKs and AAB are
deliberately not published there, to keep the repository lean and to avoid
storing multi-megabyte artifacts. The Android artifacts stay on
`secretmsg.net/downloads` and in Play.

To publish a new one, after the release is built and the version is committed:

```bash
cd /opt/secretmsg/secretmsg
git tag -a v1.7.0 -m "v1.7.0"          # on the release commit
git push origin main --follow-tags
```

Then create the release. There is no `gh` CLI on this host, so use the REST API
with the token already present in `.env.production` as `GITHUB_TOKEN`:

```bash
set -a; source /opt/secretmsg/secretmsg-private/.env.production; set +a
python3 - <<'PY'
import json, os, urllib.request
notes = open("apps/mobile-flutter/store/RELEASE_NOTES.md").read()
body = notes.split("## v1.7.0")[1].split("---")[0].strip()
payload = {"tag_name": "v1.7.0", "name": "v1.7.0", "body": body,
           "draft": False, "prerelease": False}
req = urllib.request.Request(
    "https://api.github.com/repos/janasco/secretmsg/releases",
    data=json.dumps(payload).encode(), method="POST",
    headers={"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
             "Accept": "application/vnd.github+json",
             "Content-Type": "application/json"})
print(json.loads(urllib.request.urlopen(req).read())["html_url"])
PY
```

## No CI on GitHub

This project does not use GitHub Actions, by decision, to avoid Actions
billing. Neither repo contains a `.github/workflows` directory. The checks that
used to run there — Flutter analyze and tests, web typecheck and tests, the blog
link check, and the API test suite — run locally instead:

```bash
bash scripts/verify.sh
```

Do not re-add workflow files.

