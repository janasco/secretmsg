# Play Store phone screenshots — Bento Keynote Grid

Four screenshots at **1080×1920**, generated 2026-10-08 from the captures in
`/opt/secretmsg/temp/screenshots-tmp`.

| File | Slide | Headline | Stage |
|---|---|---|---|
| `01-phone.png` | The inbox | Ask anything. / **Stay anonymous** | Secret Inbox |
| `02-phone.png` | Sending | Anyone can send. / **Nobody knows who** | Send a message |
| `03-phone.png` | Control | Reply on / **your own terms** | My Profile |
| `04-phone.png` | Privacy | Zero tracking. / **Nothing sold, ever** | Private by design |

Play accepts 2–8 phone screenshots; these are four. Upload in filename order —
Play displays them left to right in the listing, and the deck is written so
each slide stands alone.

## How they were made, and what that means for changing them

The style is **Bento Keynote Grid** from the
[`app-store-screenshots`](https://github.com/ParthJadhav/app-store-screenshots)
skill, which is installed at `/tmp/opencode/.agents/skills/`. Its spec is at
`style-prompts/15-bento-keynote-grid.md` and the deck implements it directly in
`/tmp/opencode/bento/deck.html`, rendered with Playwright.

**A note on that choice.** The skill's own deliverable is an interactive Next.js
editor for dragging tiles around. That is the right tool for iterating on a deck
by hand; it is the wrong one for a reproducible export from an agent, so the
spec was implemented straight and rendered deterministically instead. What is
preserved is the style itself — the grid, the palette, the type scale, the
one-brand-tile and one-gradient-phrase rules. What is not present is the
editor's UI. `deck.html` is the source of truth and is editable.

The spec's reference canvas is 1320×2868 and it ships its own scaling formula
(`col(n) = cW·(56+(n−1)·104)/1320`), so the grid is derived at cW=1080 rather
than eyeballed: margin 45.8, gutter 32.7, radius 49.1, headline 108–123px,
phone 867–916px. Play's 1080×1920 is a shorter aspect than the 2.17 reference,
so the vertical arrangement is re-flowed — slides whose stage is short take a
second tile row, which the style permits (4–9 tiles per slide).

## Two deviations, stated rather than hidden

**1. Only one slide meets the spec's phone-visibility floor.** The spec asks the
phone to occupy ≥68% of canvas height. Measured:

| Slide | Phone visible | vs floor |
|---|---|---|
| 01 | 1321px = **68.8%** | ✅ meets it |
| 02 | 1166px = 60.7% | below |
| 03 | 1037px = 54.0% | below |
| 04 | 1145px = 59.6% | below |

This is a property of the source captures, not the layout. They are 20:9 phone
screenshots whose content ends between 52% and 68% of the frame — the inbox is
empty, the profile screen ends after its challenges header. The spec also
requires the cut to fall in a gap between UI rows, and those two constraints
conflict here: reaching 68% means cutting through UI. The clean cut was kept and
the shorter stage compensated with a second tile row.

**2. The crops are measured, not eyeballed.** Each source was decoded and
scanned for rows that are uniform across the width, then each crop end was
verified by re-reading the cropped PNG and confirming no ink in the bottom rows:

```
s07 (inbox)     CLEAN  — no ink in the bottom 60 rows
s09 (sending)   CLEAN  — no ink in the bottom 60 rows
s08 (profile)   35 clear rows
s02 (privacy)   58 clear rows
```

Worth recording because the first attempt got this wrong twice: cropping at the
*end* of a detected gap puts the cut where content resumes — `s08` was cropped
at 1297 and cut straight through "Conversation Mode". And the stage height was
first computed without the phone frame's own 13px padding, which clipped 26px
off every crop and sliced the word "anytime." in half. Both were caught by
measuring the rendered output rather than trusting the arithmetic.

## If you want to change them

The captions are the easiest thing to change and the highest-leverage — a
headline is most of what a thumbnail communicates. Edit
`/tmp/opencode/bento/deck.html`, then:

```bash
cd /tmp/opencode/bento && node render.js
```

That rewrites `out/s1..s4.png`. Copy them over this directory in order.

To add a slide you need a source screenshot whose content runs past 68% with a
clean row gap at that point; the inbox capture here is the one that does.
