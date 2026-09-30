# Design prototypes — archive

Review artifacts, kept for reference. **None of this is in production** and
nothing here is imported by either client.

## What this is

Static HTML/CSS/JS mockups built to settle the visual direction before any
real component was rewritten:

| File | What it is |
|---|---|
| `index.html` | Web screens — landing, vibe picker, board/compose, inbox, download, settings, token table |
| `mobile.html` | 390x780 device frames for the Flutter surface: inbox, dice roulette, profile/safety |
| `studio.html` | Sticker Studio, eight designs, live canvas export |
| `stickers.js` | The eight sticker designs and their canvas draw functions |
| `tokens.css` | The proposed design tokens — type scale, spacing, radii, dark and light palettes |
| `base.css` | Shell, controls, cards, nav, mobile frame |
| `screens.css` | Per-screen composition |

## The direction it proposes

Three things, against the indigo-on-dark template that shipped:

1. **Depth instead of glow.** One low-opacity corner wash rather than two
   radial gradients on `body`, and three distinct surface tiers so hierarchy
   comes from spacing rather than an equal-elevation card grid.
2. **A real type scale.** Negative tracking that increases with size
   (`-0.035em` at display). Most of what separates "designed" from "defaulted".
3. **A restrained accent.** One accent hue for primary actions; rose, amber and
   emerald reserved for state, so colour carries meaning.

Every text colour clears WCAG AA (4.5:1) against all three surfaces it is used
on. The shipped `text-muted` sat at 4.30:1 — large text only — which is why
the prototype's muted token is `#7a8290` at 4.88:1.

## Status against the real app

**Not applied.** As of the commit that added this archive, `apps/web` and
`apps/mobile-flutter` still carry the original palette:

| | Prototype | Shipped |
|---|---|---|
| Accent | `#8b7cff` | `#6366f1` |
| Dark bg | `#08090d` | `#090a0f` |
| Dark surface | `#0f1116` | `rgba(15,17,26,.85)` |
| Muted text | `#7a8290` | `#94a3b8` |

The Sticker Studio was rebuilt to 32 designs from this direction, but on the
existing Tailwind palette — its surrounding page is the old look.

Applying this properly means editing the tokens in `apps/web/src/index.css`,
`apps/web/tailwind.config.js` and `apps/mobile-flutter/lib/theme.dart`,
regenerating the a11y baseline, then rewriting screens one at a time behind
the gate. It is not a drop-in.

## Two bugs this mockup caught

Recorded because both were invisible to static review and only showed up when
the pages were rendered:

- `--t-display: 700 clamp(...)` packed a font weight and a size into one
  token, so `font-size: var(--t-display)` was an invalid declaration that CSS
  silently dropped. Every heading rendered at body size.
- The mobile nav measured 803px at a 390px viewport, and grid children
  default to `min-width: auto`, so containers overflowed their column while
  the page looked fine in a desktop screenshot.
