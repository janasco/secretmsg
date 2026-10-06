# Play Store listing — upload-ready

Everything here maps one-to-one onto a field in **Play Console → Main store
listing**. Filenames are prefixed in upload order.

| File | Play Console field | Limit | Status |
|---|---|---|---|
| `01-APP-ICON-512x512.png` | App icon | 512×512 | ✅ ready |
| `02-FEATURE-GRAPHIC-1024x500.png` | Feature graphic | 1024×500 | ✅ ready |
| `03-TITLE.txt` | App name | 30 chars | ✅ 25 |
| `04-SHORT-DESCRIPTION.txt` | Short description | 80 chars | ✅ 79 |
| `05-FULL-DESCRIPTION.txt` | Full description | 4000 chars | ✅ 2452 |
| `06-PHONE-SCREENSHOT-*.png` | Phone screenshots | 2–8, ≥320px | ❌ **missing** |

## Verified formats

Both images were read at the byte level rather than assumed, because Play
rejects some combinations silently:

- **App icon** — 512×512, colour type 2 (RGB), 8-bit. Play permits alpha on the
  icon; this has none, which is fine.
- **Feature graphic** — 1024×500, colour type 2 (RGB), 8-bit, **no alpha**.
  This is the one Play is strict about: it must be JPEG or 24-bit PNG without
  transparency. It qualifies.

## What is still missing: the phone screenshots

`listing/phone/` is empty. These are the only blocking asset, and they cannot be
produced on the build machine — they need the app running on a device.

Capture guide with the full shot list, framing rules and capture settings is in
[../SCREENSHOTS.md](../SCREENSHOTS.md). Two things from it worth knowing before
you start:

- **Capture in the ad-free state.** Not because Play forbids ads in screenshots
  — it does not — but because an ad is a third party's creative that changes
  without notice and can carry text that conflicts with the content rating or
  the listing's own framing. A shot with a live ad is also a shot that will not
  reproduce.
- **Do not composite or retouch an ad in**, and do not crop out a banner that is
  genuinely present to make a shot look cleaner. The listing says the app is
  ad-supported; the screenshots must not contradict it in either direction.

Suggested subjects, from the same guide: inbox, Daily Drop, prompt roulette, and
the Sticker Studio.

## Copy changes made 2026-10-06

Two edits, both because the app moved after the copy was written on 2026-09-25:

- The studio line said "Story stickers to share a question or an answer". It now
  names the real capability — 32 designs, each in its own typeface, exporting a
  1080×1920 PNG. That is a stronger selling point than the version it replaces
  and it is accurate to the rebuilt studio.
- "View on the web" said pairing let a browser "read your inbox". Pairing now
  also unlocks the prompt roulette and the Sticker Studio, so the section says
  so. Reading remains view-only; the edit adds the tools without overstating
  what a paired browser may do.
