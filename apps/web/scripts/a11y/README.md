# a11y-color — theme/contrast static analysis

**Why this exists.** `src/index.css` adapts the site to light mode by re-pointing
individual *Tailwind class tokens*: `.light .text-amber-200 { color: #b45309 }`.
A Tailwind opacity modifier produces a **different class token** — `.text-amber-200/90`
— which such a selector cannot match. The element then renders the dark-theme
colour on light paper.

That shipped. `ViewOnlyBanner` measured **1.10:1 in light mode, 11.50:1 in dark**:
perfectly legible in the theme nobody reported, invisible in the other. A
repo-wide grep for `text-amber-200` finds the remap table entry and stops,
which is exactly why it survived. The opacity modifier had quietly opted that
element out of the site's own colour system.

No other check in this project can see that class of bug. This one can.

## Run it

```bash
cd apps/web
npm run a11y            # human report, fails the gate on a NEW remap bypass
npm run a11y:strict     # also fail on sibling gaps, unremapped surfaces, contrast
node scripts/a11y-color.mjs --format json          # machine-readable
node scripts/a11y-color.mjs --fail-on none          # never fail, report only
node scripts/a11y-color.mjs --update-baseline       # re-record known findings
```

Runs in **~4 seconds** over 63 files. The gate (`scripts/verify.sh`) invokes it
as its own named check, `a11y colour remap bypasses + contrast`.

| flag | default | meaning |
|---|---|---|
| `--fail-on <list>` | `bypass` | comma-separated rule ids, or `none` |
| `--strict` | off | shorthand for all four rules |
| `--format text\|json` | `text` | |
| `--baseline <file>` | `scripts/a11y/baseline.json` | findings that do not fail |
| `--update-baseline` | off | rewrite the baseline with this run's findings |
| `--max-contrast N` | 40 | rows per contrast tier |

`A11Y_FAIL_ON` is the env equivalent of `--fail-on` (flag wins).

Exit codes: `0` clean or within baseline, `1` findings matched the failing mode,
`2` the tool itself failed.

## The four rules

1. **`bypass` — the shipped defect class.** A colour utility whose *base* class
   has a `.light` remap, used in a form that remap cannot cover. Almost always
   an opacity modifier. Reports the base class, the exact bypassing class, the
   `src/index.css` line of the rule it evades, and `file:line` of the use.
   **This is the default failing mode** — it is the bug that actually shipped.

2. **`sibling-gap`** — the same utility at an alpha the remap table never lists.
   There is no base rule to opt out of, only an unlisted neighbour. Lower
   severity, and reported as such.

3. **`unremapped-surface`** — a background, border or gradient stop with no remap
   in any theme state, so it cannot follow the theme. Judged, not blanket-listed;
   see below.

4. **`contrast`** — measured WCAG 2.1, in both themes, against the real composed
   backdrop. See below.

## Judgements are recorded, not inferred

`index.css` states the policy in its own header: *"Colored surfaces (solid
buttons, gradients, tinted chips) are untouched"*. So an unremapped **hue**
surface is the documented design, not a finding — there are 511 of them, and
listing every one would bury the three tokens that need a decision.

Those 511 are reported as an **inventory** (count, head, `--format json` for the
rest) and cannot fail the gate. The judgement table lives in `analyze.mjs` as
`SURFACE_JUDGEMENTS`, keyed by class token, each entry carrying a written reason.
A verdict with no recorded reason is indistinguishable from a bug in the tool.

Judged `defect` today: `bg-white` and `hover:bg-white` (a light island in dark
mode, so dark-mode text under them resolves against white while the tokens
around them resolve against dark). Judged `by-design`: the modal scrims
(`bg-black/*`), solid `border-white` on coloured buttons, `hover:bg-slate-100` on
an already-white button, gradient stops, and `bg-[#10131A]` (fixed — see below).

## What the contrast engine actually resolves

For every foreground utility in the source, in both themes:

- **Foreground colour**, through the cascade. `text-X dark:text-Y` is resolved
  per theme — the variant wins in dark on specificity, so only one of the two is
  measured. This matters: measuring both reported `ViewOnlyBanner`'s overridden
  `text-amber-800` at 2.22:1 on a surface where the user sees 11.5:1.
- **Remap application**, honouring (a) the `[class~="…"]` exclusion lists in
  `index.css`, (b) `dark-island` scoping, and (c) selector specificity, with
  `:where()` correctly zeroed — including everything nested inside it. The
  stylesheet depends on that: the exclusion lists are wrapped in `:where()`
  specifically so the `.dark-island` re-assertions at `(0,3,0)` beat them.
- **Backdrop**, as a composited chain: every background between the element and
  `<body>`, alpha-flattened in order, ending at the page background derived from
  `<body>`'s class list in `index.html`. `.glass-panel` — the site's actual card
  surface — is resolved from `index.css` as a component class, not a utility.
- **Threshold**, from the font size and weight, after applying the size
  overrides in `index.css` (which flattens `text-xs`/`sm`/`base` and both
  arbitrary small sizes).

Findings are tiered, and the tiers are not interchangeable:

| tier | criterion |
|---|---|
| `text` | WCAG 1.4.3, resting state |
| `text-interaction` | 1.4.3, hover/focus state, paired with the matching state background |
| `non-text` | WCAG 1.4.11, icons and graphics, 3:1 |
| `text/branch-ambiguous` | className built by a ternary — **not findings**, see limits |
| `selection:*` | `::selection` pseudo-element — not measured |

## Honest limits

Static analysis of a utility-class codebase cannot see everything, and a tool
that implies otherwise gets trusted with the parts it is wrong about.

- **Ternary classNames are not resolved.** `className={cond ? 'a' : 'b'}` puts
  both branches on one element, so the backdrop is a combination that never
  renders. These are reported in a separate `branch-ambiguous` tier and are
  never findings. Roughly 44 occurrences.
- **No expression evaluation.** `className={clsx(base, isX && 'text-y')}` is read
  for what it contains, not for which branch is live.
- **Gradients are approximated by their stops**, not interpolated. A headline
  gradient is judged on its endpoints, which is the pessimistic end of the range.
- **`body`'s two `radial-gradient` washes are not composited.** They are a 12%
  indigo and a 6% amber wash on a large radius. The effect on any measured pair
  is far below the precision of any ratio here, but it is a real omission.
- **Blog body copy is out of scope.** `.blog-body` is build-generated HTML in
  `public/`, not TSX, so the 247 contrast findings cover only the React app. The
  blog's own light-mode rules in `index.css` are unmeasured.
- **Prerendered HTML is unmeasured.** What ships is 239 prerendered files; this
  reads the 63 source files they are generated from. The two can only diverge if
  prerendering diverges from the source, which is a different tool's problem.
- **`z-index` and stacking contexts are ignored.** A backdrop is taken from DOM
  ancestry, which is right for this codebase and wrong in general.
- **Nothing is resolved for `:visited`, forced-colors, or `prefers-contrast`.**
- **Font size is inferred from the class chain**, not computed. A `rem` override
  on an ancestor the tool cannot see would be missed.

247 contrast findings remain, all recorded in the baseline. They are real
measurements of real shortfalls — mostly muted text on tinted surfaces in one
theme — and they are the site's existing debt, not new regressions. The gate
fails on the *next* bypass, not on today's backlog.

## Layout

| file | role |
|---|---|
| `a11y-color.mjs` | CLI, failing mode, baseline, text/JSON rendering |
| `a11y/project.mjs` | reads index.css / index.html / tailwind.config.js, scans src |
| `a11y/remap.mjs` | CSS parser: remap table, component classes, vars, specificity |
| `a11y/classes.mjs` | class-token classification (the palette is the authority) |
| `a11y/scan.mjs` | source scanning, nesting-aware JSX element model |
| `a11y/analyze.mjs` | the four rules, the contrast engine, judgement table |
| `a11y/color.mjs` | colour maths: parse, composite, WCAG 2.1 |
| `a11y/palette.generated.mjs` | generated from the installed tailwindcss |
| `a11y/a11y-color.test.mjs` | 31 tests, run by `npm test` |
| `a11y/baseline.json` | findings a human decided to live with |

No dependencies. The colour maths is ~150 lines and cheaper to audit by reading
than a dependency would be, and the gate has to work on a machine with an empty
npm cache.

The tests live in `scripts/` rather than `src/` on purpose: Tailwind's content
glob scans `./src/**` as raw text, and the palette tables would start
contributing utilities nothing uses.

## The acceptance test

`a11y-color.test.mjs` runs the detector over a synthetic TSX snippet containing
`text-amber-200/90` and asserts it is flagged as a bypass at the right
`file:line`, with a control asserting the plain `text-amber-200` is **not**
flagged. It runs against the real `src/index.css` remap table.

The real line in `ViewOnlyBanner.tsx` is already fixed, and is not reintroduced
to make the test pass — a test that only holds while a known-bad class is in the
tree is not a test. One test scans all of `src/` and asserts there are **zero**
remap bypasses, so the next one fails the suite rather than shipping.
