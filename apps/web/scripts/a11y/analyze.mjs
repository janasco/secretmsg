/**
 * The checks.
 *
 * Three findings, in the order they matter:
 *
 *  1. REMAP BYPASS - a colour utility whose *base* class has a light-mode
 *     remap, used in a form that remap does not cover. Overwhelmingly this is
 *     an opacity modifier: `.text-amber-200` and `.text-amber-200/90` are two
 *     different CSS class tokens, so a selector written for the first cannot
 *     match the second. The element then renders the dark-theme colour in light
 *     mode. This is the defect that actually shipped.
 *
 *  2. UNRE MAPPED SURFACE - a background or border colour with no remap rule
 *     in any theme state, so it cannot respond to the theme. Neutral families
 *     are defects (the entire light-mode system is built on remapping them);
 *     hue families are usually deliberate brand surfaces, and are reported with
 *     a verdict rather than mass-replaced.
 *
 *  3. CONTRAST - measured, not guessed. Foreground colour is composited over
 *     the real backdrop chain (nearest ancestor background, alpha flattened,
 *     page background last) for both themes, and compared against the WCAG 2.1
 *     threshold for that font size.
 */

import {
  activeStates,
  baseToken,
  classifyClass,
  familyKey,
  splitOpacity,
} from './classes.mjs';
import {
  composite,
  contrastRatio,
  meetsAA,
  parseColor,
  requiredRatio,
  toHex,
} from './color.mjs';
import { resolveEntryColour, varsForState } from './remap.mjs';

export const THEMES = ['light', 'dark'];

const FONT_SIZES = {
  'text-xs': 15,
  'text-sm': 17,
  'text-base': 19,
  'text-lg': 18,
  'text-xl': 20,
  'text-2xl': 24,
  'text-3xl': 30,
  'text-4xl': 36,
  'text-5xl': 48,
  'text-6xl': 60,
};

const BOLD_CLASSES = new Set(['font-bold', 'font-extrabold', 'font-black']);

/* ------------------------------------------------------------------ */
/* Resolution: raw class token -> effective colour in a theme state    */
/* ------------------------------------------------------------------ */

/**
 * Context a colour needs in order to be resolved for one element.
 *  sameElement - class tokens on the element itself (for `[class~=]` exclusions)
 *  ancestor    - class tokens on the element and its ancestors (for `.dark-island`)
 */
function remapApplies(entry, state, sameElement, ancestor) {
  if (!entry.states.includes(state)) return false;
  if (entry.scope.length > 0 && !entry.scope.every((s) => ancestor.has(s))) return false;
  if (entry.exclusions.length > 0 && entry.exclusions.some((x) => sameElement.has(x))) return false;
  return true;
}

/**
 * Resolve one colour utility to its effective colour in `state`.
 *
 * Returns { colour, alpha, source, entry } or { inactive: true } when the token
 * is gated to the other theme. `colour` may be translucent; the caller
 * composites it onto whatever is behind it.
 */
export function resolveColour(token, ctx, state, scope) {
  const info = classifyClass(token, ctx.palette);
  if (!info) return null;
  if (!activeStates(info.variants).includes(state)) return { inactive: true, token };

  const sameElement = scope?.sameElement ?? new Set();
  const ancestor = scope?.ancestor ?? sameElement;

  // Attribute-conditioned rules, e.g. `.light .bg-clip-text[class*="from-"]`.
  if (sameElement.has('bg-clip-text')) {
    for (const entry of ctx.table.byAttribute.get('class*:from-') ?? []) {
      if (remapApplies(entry, state, sameElement, ancestor)) {
        const colour = resolveEntryColour(entry, ctx.vars[state]);
        if (colour) return { colour, alpha: 1, source: 'remap', entry, token };
      }
    }
  }

  const exact = ctx.table.byToken.get(info.token) ?? [];
  const candidates = exact.filter((e) => remapApplies(e, state, sameElement, ancestor));
  if (candidates.length > 0) {
    for (const entry of candidates) {
      const colour = resolveEntryColour(entry, ctx.vars[state]);
      if (colour) return { colour, alpha: colour.a, source: 'remap', entry, token };
    }
  }

  // No remap: the raw Tailwind value, with the opacity modifier as alpha.
  const base = info.hex ? parseColor(info.hex, ctx.vars[state]) : parseColor(info.arbitrary, ctx.vars[state]);
  if (!base) return null;
  return { colour: { ...base, a: info.opacity }, alpha: info.opacity, source: 'palette', token, info };
}

/** Opaque page background, derived from `<body>`'s class list in index.html. */
export function pageBackground(ctx, state) {
  for (const token of ctx.bodyClasses) {
    const info = classifyClass(token, ctx.palette);
    if (!info || info.prefix !== 'bg') continue;
    const r = resolveColour(token, ctx, state, { sameElement: new Set(ctx.bodyClasses), ancestor: new Set(ctx.bodyClasses) });
    if (r?.colour) return composite(r.colour, { r: 255, g: 255, b: 255, a: 1 }) ?? { ...r.colour, a: 1 };
  }
  return null;
}

/* ------------------------------------------------------------------ */
/* Rule 1 + 2: remap bypass and unremapped surfaces                    */
/* ------------------------------------------------------------------ */

function severityFor(info) {
  if (info.isForeground) return 'high';
  if (info.prefixGroup === 'border' || info.prefixGroup === 'divide') return 'medium';
  return 'low';
}

/**
 * Recorded judgements about surface colours that are deliberately not remapped.
 *
 * `index.css` states the policy in its own header comment: "Colored surfaces
 * (solid buttons, gradients, tinted chips) are untouched". So an unremapped hue
 * surface is the documented behaviour, not something to mass-replace, and
 * listing 387 occurrences of it would bury the handful of real problems in the
 * same report. These verdicts are written down with a reason rather than
 * inferred: a judgement with no recorded reason is indistinguishable from a bug
 * in the tool.
 */
const SURFACE_JUDGEMENTS = new Map([
  ['bg-white', {
    verdict: 'defect',
    reason: 'White button/panel in both themes. It reads as a raised surface on light paper and as a '
      + 'light island in dark mode, so dark-mode text under it resolves against white while the tokens '
      + 'around it resolve against dark. Either needs a remap or needs to be an explicit dark-island.',
  }],
  ['hover:bg-white', {
    verdict: 'defect',
    reason: 'Hover of `bg-white`. Same reasoning as bg-white, and on a dark surface it flips a light '
      + 'panel to another light panel with no contrast change at all.',
  }],
  ['hover:bg-slate-100', {
    verdict: 'by-design',
    reason: 'Hover tint on an element that is already `bg-white` in both themes. The hover darkens a '
      + 'surface that is light either way, so it needs no light-mode remap.',
  }],
  ['border-slate-200', {
    verdict: 'by-design',
    reason: 'Hairline on the DicePage die, which is `bg-white` in both themes by design.',
  }],
  ['bg-black/80', {
    verdict: 'by-design',
    reason: 'Modal scrim. Dark in both themes on purpose: a scrim is meant to darken whatever is behind it.',
  }],
  ['bg-black/85', { verdict: 'by-design', reason: 'Modal scrim. Same reasoning as bg-black/80.' }],
  ['bg-black/60', { verdict: 'by-design', reason: 'Modal scrim. Same reasoning as bg-black/80.' }],
  ['bg-black/30', { verdict: 'by-design', reason: 'Modal scrim. Same reasoning as bg-black/80.' }],
  ['bg-[#10131A]', {
    verdict: 'by-design',
    reason: 'Hardcoded near-black preview panel in SafetyToolsPage. It used to carry no theme '
      + 'awareness at all and measured 1.12:1 in light mode, because its text tokens are remapped '
      + 'for light paper while the panel itself stayed dark - the shipped defect class reached by a '
      + 'different door. It now carries `dark-island`, which re-asserts text-white, text-slate-300 '
      + 'and text-slate-400 to their dark values, so the panel is an intentional island rather than an '
      + 'accident. Keep it out of the light-mode remap table: that is what the island is for.',
  }],
  ['border-white', {
    verdict: 'by-design',
    reason: 'index.css explicitly excludes solid `.border-white` from the light-mode hairline remap '
      + 'because those rings sit on coloured buttons. Confirmed at every reported site.',
  }],
]);


function judgementFor(info) {
  const recorded = SURFACE_JUDGEMENTS.get(info.token);
  if (recorded) return recorded;

  if (['from', 'via', 'to'].includes(info.prefix)) {
    return {
      verdict: 'by-design',
      reason: 'Gradient stop. index.css leaves brand gradients alone and deepens only the bg-clip-text '
        + 'headline gradient, so this is theme-independent by intent.',
    };
  }
  if (info.arbitrary && /^#/.test(info.arbitrary)) {
    return {
      verdict: 'defect',
      reason: `Hardcoded literal ${info.arbitrary}. A raw hex value has no theme awareness at all, so `
        + 'anything rendered on it keeps the same colour in both themes while its text tokens flip. '
        + 'Treat as a defect unless there is a recorded reason to leave it.',
    };
  }
  if (!info.isNeutral) {
    return {
      verdict: 'by-design',
      reason: 'Hue surface. index.css states coloured surfaces are deliberately not remapped, so this '
        + 'cannot respond to the theme and is not meant to.',
    };
  }
  return {
    verdict: 'defect',
    reason: 'Neutral surface token with no remap. The whole light-mode system is built on remapping '
      + 'the neutral family, so this one is the odd one out.',
  };
}

/**
 * Remapped tokens that are the same utility as `info` with a different alpha:
 * same prefix, same colour, same variants. This is how `bg-white/[0.04]` is
 * related to the remapped `bg-white/5`.
 */
function mappedSiblings(info, ctx) {
  const variants = info.variants.join(':');
  const colour = familyKey(info).split(':').pop();
  const out = [];
  for (const token of ctx.table.byToken.keys()) {
    const cut = token.lastIndexOf(':');
    const head = token.slice(0, cut + 1);
    const tail = token.slice(cut + 1);
    if (head !== (variants === '' ? '' : `${variants}:`)) continue;
    const parts = splitOpacity(tail);
    if (parts.base !== colour || parts.modifier == null) continue;
    out.push(token);
  }
  return out.sort();
}

/**
 * Analyse every colour utility occurrence.
 *
 * @param usages  output of findColourUtilities
 * @param ctx     project context
 */
export function analyseUsages(usages, ctx) {
  const bypasses = [];
  const siblingGaps = [];
  const unremapped = [];
  const byDesign = [];
  const seen = new Set();

  for (const usage of usages) {
    const info = usage;
    const base = baseToken(info);
    const exactCovered = ctx.table.byToken.has(info.token);
    const baseCovered = ctx.table.byToken.has(base);
    const states = activeStates(info.variants);

    // --- Rule 1: the opacity modifier opted the element out of the remap. ---
    if (!exactCovered && base !== info.token && baseCovered && states.includes('light')) {
      const entry = ctx.table.byToken.get(base).find((e) => e.states.includes('light'));
      push(bypasses, {
        rule: 'remap-bypass',
        severity: severityFor(info),
        file: usage.file,
        line: usage.line,
        token: info.token,
        base,
        property: info.prefix,
        detail:
          `"${info.token}" is a different CSS class token from "${base}", which has a light-mode remap at `
          + `src/index.css:${entry.line}. The remap selector cannot match the opacity-modified form, so `
          + 'this element renders its dark-theme colour in light mode.',
        remapLine: entry.line,
        remapSelector: entry.selector.trim(),
      });
      continue;
    }

    // --- Sibling gap: same utility, an alpha the remap table never lists. ---
    if (!exactCovered && info.modifier && states.includes('light')) {
      const siblings = mappedSiblings(info, ctx);
      if (siblings.length > 0) {
        push(siblingGaps, {
          rule: 'remap-sibling-gap',
          severity: severityFor(info),
          file: usage.file,
          line: usage.line,
          token: info.token,
          base,
          property: info.prefix,
          detail:
            `The remap table maps "${siblings.join('", "')}" for this utility but not this alpha, so light `
            + 'mode renders the dark-theme value. Lower severity than a bypass: there is no base rule to '
            + 'opt out of, only an unlisted neighbour.',
          siblings,
        });
        continue;
      }
    }

    // --- Rule 2: a surface colour with no remap at all. ---
    if (info.isSurface && !exactCovered) {
      const { verdict, reason } = judgementFor(info);
      // A surface judged static by design is not a finding. It is the documented
      // behaviour of this stylesheet, reported as an inventory so the count is
      // visible and reviewable, but kept out of the failing set - otherwise the
      // gate would fail on 500 instances of the intended design and the
      // baseline would grow every time a button was added.
      const target = verdict === 'by-design' ? byDesign : unremapped;
      push(target, {
        rule: 'unremapped-surface',
        severity: verdict === 'defect' ? (info.isNeutral ? 'medium' : 'low') : 'low',
        verdict,
        reason,
        file: usage.file,
        line: usage.line,
        token: info.token,
        base,
        property: info.prefix,
        family: info.family,
      });
    }
  }

  function push(list, finding) {
    const id = `${finding.rule}|${finding.file}:${finding.line}|${finding.token}`;
    if (seen.has(id)) return;
    seen.add(id);
    finding.id = id;
    list.push(finding);
  }

  return { bypasses, siblingGaps, unremapped, byDesign };
}

/* ------------------------------------------------------------------ */
/* Rule 3: contrast                                                    */
/* ------------------------------------------------------------------ */

/** Does this utility paint a background colour? `classifyClass` has already
 *  established that the payload is a colour, so this is only about the prefix. */
function isBackgroundUtility(info) {
  return info != null && info.prefix === 'bg';
}

function isGradientUtility(info) {
  return info != null && ['from', 'via', 'to'].includes(info.prefix);
}

function tokensOf(node, palette) {
  const out = [];
  for (const literal of node.classes) {
    for (const token of literal.value.split(/[\s"'`,]+/)) {
      if (!token) continue;
      out.push({ token, info: classifyClass(token, palette) });
    }
  }
  return out;
}

/**
 * Layers painted by a component class rather than a Tailwind utility.
 *
 * `.glass-panel` is this site's card surface and it is defined in index.css, not
 * as a `bg-*` utility. Without resolving it, a card looks transparent and every
 * text run inside a modal inherits the black scrim behind it - which produced
 * dozens of phantom "black on black" findings before this existed.
 */
function componentLayersOf(node, ctx, state) {
  const layers = [];
  for (const literal of node.classes) {
    for (const token of literal.value.split(/[\s"'`,]+/)) {
      const rule = ctx.components.get(token);
      if (!rule) continue;
      const background = rule.props.background ?? rule.props['background-color'];
      if (!background) continue;
      const colour = parseColor(background.value, ctx.vars[state]);
      if (colour) layers.push({ class: token, colour, remap: true });
    }
  }
  return layers;
}

function hasComponentClass(node, ctx) {
  for (const literal of node.classes) {
    for (const token of literal.value.split(/[\s"'`,]+/)) {
      if (ctx.components.has(token)) return true;
    }
  }
  return false;
}

function fontSizeFor(node, palette) {
  const chain = [];
  for (let cur = node; cur; cur = cur.parent) chain.push(cur);
  for (const el of chain) {
    let size = null;
    let bold = false;
    for (const { token } of tokensOf(el, palette)) {
      if (FONT_SIZES[token]) size = FONT_SIZES[token];
      const arbitrary = /^text-\[(\d+(?:\.\d+)?)px\]$/.exec(token);
      if (arbitrary) size = Number(arbitrary[1]);
      if (BOLD_CLASSES.has(token)) bold = true;
    }
    // index.css flattens both arbitrary small sizes and text-xs/sm/base.
    if (size != null && size <= 13) size = 13;
    if (size != null) return { size, bold };
  }
  return { size: 17, bold: false };
}

/**
 * Is this element an icon/graphic rather than a text run?
 *
 * Lucide icons are sized with a `w-N h-N` pair and contain no text node. They
 * are held to WCAG 1.4.11 (3:1 non-text contrast), not 1.4.3, so folding them
 * into the same table would both overstate the failures and bury the real ones.
 */
function isGraphicBox(node, palette) {
  const tokens = tokensOf(node, palette).map((t) => t.token);
  const sized = tokens.some((t) => /^(w|h|size)-\d/.test(t));
  if (!sized) return false;
  return !node.children.some((child) => child.children.length > 0
    || (child.classes.length > 0 && child.classes[0].value.trim() !== ''));
}

const INTERACTION_VARIANTS = new Set([
  'hover', 'focus', 'focus-visible', 'focus-within', 'active', 'group-hover', 'group-focus', 'disabled',
]);

/**
 * Which measured tier a foreground token belongs to.
 *
 * `selection:` utilities style the ::selection pseudo-element, which is not
 * text content and has its own (unmeasured) requirement; treating it as a text
 * run produced pure noise on the body element.
 */
function tierFor(variants, graphic) {
  if (variants.includes('selection')) return 'skip';
  if (graphic) return 'non-text';
  if (variants.some((v) => INTERACTION_VARIANTS.has(v))) return 'text-interaction';
  return 'text';
}

/** Does this utility only paint in an interaction or selection state? */
function isStateLayer(info) {
  if (!info) return true;
  if (info.variants.includes('selection')) return true;
  return info.variants.some((v) => INTERACTION_VARIANTS.has(v));
}

/**
 * Cascade bucket for one foreground utility.
 *
 * Two things stop utilities from competing:
 *
 *  - `text-slate-300` and `hover:text-dark-900` both set `color`, but the
 *    second only applies while the pointer is over the element. Letting them
 *    compete made the *resting* colour look like a failure whenever the hover
 *    colour won on variant count.
 *  - `selection:text-white` targets `::selection` and competes with nothing.
 *
 * What is left - `text-amber-800` alongside `dark:text-amber-200/90` - genuinely
 * is a cascade, and is resolved by `cascadeWinner`.
 */
function cascadeKey(info) {
  if (info.variants.includes('selection')) return 'color::selection';
  if (info.variants.some((v) => INTERACTION_VARIANTS.has(v))) return `${info.prefix}:interaction`;
  return `${info.prefix}:resting`;
}

/**
 * Which of several utilities in one cascade bucket actually applies.
 *
 * Tailwind emits a variant as `.dark .dark\:text-amber-200\/90`, which beats the
 * bare `.text-amber-800` on specificity, so in dark mode only the variant
 * paints. Measuring both reported the overridden `text-amber-800` at 2.22:1 on
 * a surface where the user actually sees 11.5:1 - a whole class of invented
 * defect.
 *
 * Two same-specificity utilities of one property on a single element (two bare
 * `text-*` classes) genuinely are ambiguous, and that is reported rather than
 * guessed at.
 */
function cascadeWinner(foregrounds, state) {
  const active = foregrounds.filter(({ info }) => activeStates(info.variants).includes(state));
  if (active.length === 0) return null;
  if (active.length === 1) return { winner: active[0], ambiguous: false };
  const maxVariants = Math.max(...active.map(({ info }) => info.variants.length));
  const top = active.filter(({ info }) => info.variants.length === maxVariants);
  if (top.length === 1) return { winner: top[0], ambiguous: false };
  return { winner: top[top.length - 1], ambiguous: true };
}

function surfaceKind(node, palette, ancestryTokens) {
  if (ancestryTokens.has('dark-island')) return 'dark-island';
  const tag = `${node.tag} ${node.attrText}`;
  if (/fixed/.test(tag) && /inset-0/.test(tag)) return 'modal-scrim';
  const own = tokensOf(node, palette).map((t) => t.info).filter(Boolean);
  if (own.some((i) => isGradientUtility(i))) return 'gradient';
  const bg = own.find((i) => isBackgroundUtility(i));
  if (bg && bg.modifier && Number(String(bg.modifier).replace(/\D/g, '')) <= 40 && bg.family && !bg.isNeutral) {
    return 'tinted-banner';
  }
  if (/glass-panel/.test(node.attrText)) return 'glass-card';
  if (bg && bg.isNeutral) return 'card';
  return 'surface';
}

function scopeOf(node, ctx) {
  const sameElement = new Set();
  for (const { token } of tokensOf(node, ctx.palette)) sameElement.add(token);
  const ancestor = new Set(sameElement);
  for (let cur = node.parent; cur; cur = cur.parent) {
    for (const { token } of tokensOf(cur, ctx.palette)) ancestor.add(token);
  }
  return { sameElement, ancestor };
}

/**
 * Resolve the opaque colour behind an element, compositing every translucent
 * layer between it and the page in order.
 *
 * `layers` is the human-readable chain, so any reported number can be traced
 * back to the exact classes that produced it.
 */
function backdropFor(node, ctx, state, activeVariants = null) {
  const layers = [];
  let gradient = false;

  for (let cur = node; cur; cur = cur.parent) {
    layers.push(...componentLayersOf(cur, ctx, state));
    const entries = tokensOf(cur, ctx.palette);
    const scope = scopeOf(cur, ctx);

    if (entries.some(({ info }) => info?.prefix === 'bg' && String(info.arbitrary ?? '').startsWith('gradient'))) {
      gradient = true;
    }
    for (const { token, info } of entries) {
      if (!isGradientUtility(info) && !isBackgroundUtility(info)) continue;
      // A hover/focus/selection background is not the resting surface. Counting
      // it produced findings like "white text on the white a button turns on
      // hover". It is re-admitted only for a foreground that is itself in that
      // state, so `focus:not-sr-only:bg-indigo-600` pairs with
      // `focus:not-sr-only:text-white` instead of with the page.
      if (isStateLayer(info)) {
        const sameState = activeVariants != null
          && info.variants.length > 0
          && info.variants.every((v) => activeVariants.includes(v));
        if (!sameState) continue;
      }
      const r = resolveColour(token, ctx, state, scope);
      if (r?.colour) layers.push({ class: token, colour: r.colour, remap: r.source === 'remap' });
    }
  }

  const page = pageBackground(ctx, state);
  if (page) layers.push({ class: 'body', colour: page });

  // Composite back-to-front: page first, then outermost ancestor, then inward.
  let acc = page ? { ...page, a: 1 } : { r: 255, g: 255, b: 255, a: 1 };
  for (let i = layers.length - 1; i >= 0; i -= 1) {
    const out = composite(layers[i].colour, acc);
    if (out) acc = out.a >= 1 ? out : { ...out, a: 1 };
  }
  return { colour: acc, layers: layers.slice().reverse(), gradient };
}

/** Surface colour a text run sits on: the nearest ancestor that actually paints. */
function textBackdrop(node, ctx, state, activeVariants = null) {
  for (let cur = node; cur; cur = cur.parent) {
    const infos = tokensOf(cur, ctx.palette).map((t) => t.info).filter(Boolean);
    const paints = infos.some((i) => isBackgroundUtility(i))
      || infos.some(isGradientUtility)
      || hasComponentClass(cur, ctx);
    if (paints) return backdropFor(cur, ctx, state, activeVariants);
  }
  return backdropFor(node, ctx, state, activeVariants);
}

/**
 * Measure every foreground run against its backdrop in both themes.
 *
 * Findings carry a `tier` (text / text-interaction / non-text) and a
 * `confidence`. `measured` means the foreground and every backdrop layer
 * resolved in both themes; `partial` means one theme could not be resolved and
 * is reported as such rather than quietly dropped.
 */
export function analyseContrast(model, ctx) {
  const results = [];
  const unresolved = [];

  for (const node of model.nodes) {
    // `--explain file:line` asks for every measurement at a location, including
    // the ones that pass. Without that you can prove a defect but not prove a
    // fix, which is the half that matters when reviewing a change.
    if (ctx.explainLines && ctx.explainLines.size > 0
      && !ctx.explainLines.has(`${node.file}:${node.line}`)) continue;
    const foregrounds = tokensOf(node, ctx.palette).filter(({ info }) => info?.isForeground);
    if (foregrounds.length === 0) continue;

    const graphic = isGraphicBox(node, ctx.palette);
    const kind = surfaceKind(node, ctx.palette, scopeOf(node, ctx).ancestor);
    const { size, bold } = fontSizeFor(node, ctx.palette);
    const required = graphic ? 3 : requiredRatio(size, bold);
    const ambiguousBranch = node.classes.some((c) => c.conditional);

    // Utilities in different cascade buckets never compete; only a real
    // cascade inside one bucket is resolved.
    const byBucket = new Map();
    for (const entry of foregrounds) {
      const key = cascadeKey(entry.info);
      if (!byBucket.has(key)) byBucket.set(key, []);
      byBucket.get(key).push(entry);
    }

    for (const group of byBucket.values()) {
      const tier = tierFor(group[0].info.variants, graphic);
      if (tier === 'skip') continue;

      const perTheme = {};
      let resolvedAny = 0;
      let cascadeAmbiguous = false;
      for (const state of THEMES) {
        const cascade = cascadeWinner(group, state);
        if (!cascade) {
          perTheme[state] = { active: false };
          continue;
        }
        if (cascade.ambiguous) cascadeAmbiguous = true;
        const { token, info } = cascade.winner;
        const r = resolveColour(token, ctx, state, scopeOf(node, ctx));
        if (!r || r.inactive) {
          perTheme[state] = { active: false };
          continue;
        }
        const bd = textBackdrop(node, ctx, state, info.variants);
        if (!bd?.colour) {
          perTheme[state] = { active: true, unresolved: 'backdrop' };
          continue;
        }
        const fg = composite(r.colour, bd.colour);
        if (!fg) {
          perTheme[state] = { active: true, unresolved: 'foreground' };
          continue;
        }
        const ratio = contrastRatio(fg, bd.colour);
        perTheme[state] = {
          active: true,
          fg: toHex(fg),
          fgSource: r.source,
          winner: token,
          bg: toHex(bd.colour),
          bgLayers: bd.layers.map((l) => l.class),
          gradient: bd.gradient,
          ratio,
          required,
          pass: meetsAA(ratio, required),
        };
        if (ratio != null) resolvedAny += 1;
      }

      if (resolvedAny === 0) {
        unresolved.push({
          file: node.file,
          line: node.line,
          token: group[0].token,
          reason: 'foreground and/or backdrop colour could not be resolved',
        });
        continue;
      }

      const failing = THEMES.filter((s) => perTheme[s].active && perTheme[s].pass === false);
      const confidence = resolvedAny === THEMES.length ? 'measured' : 'partial';
      const explained = ctx.explainLines?.has(`${node.file}:${node.line}`) ?? false;
      if (!explained
        && failing.length === 0 && confidence === 'measured'
        && !ambiguousBranch && !cascadeAmbiguous) continue;

      const token = group[0].token;
      results.push({
        rule: 'contrast',
        tier: ambiguousBranch ? `${tier}/branch-ambiguous` : tier,
        severity: failing.length === 2 ? 'high' : 'medium',
        verdict: failing.length === 0 ? 'partial-only' : 'failing',
        file: node.file,
        line: node.line,
        token,
        property: group[0].info.prefix,
        surface: kind,
        fontSize: size,
        bold,
        required,
        confidence: cascadeAmbiguous ? 'ambiguous-overlap' : confidence,
        themes: perTheme,
        id: `contrast|${node.file}:${node.line}|${token}|${kind}`,
      });
    }
  }

  return { results, unresolved };
}

/** Deduplicate repeated pairings so the report stays readable. */
export function summariseContrast(results, limit = 40, tier = null) {
  const scoped = tier ? results.filter((r) => r.tier === tier) : results;
  const groups = new Map();
  for (const r of scoped) {
    const key = [
      r.token,
      r.surface,
      r.tier,
      r.themes.light?.bg ?? r.themes.dark?.bg ?? '?',
      r.themes.light?.ratio ?? '-',
      r.themes.dark?.ratio ?? '-',
      r.required,
      r.fontSize,
    ].join('|');
    if (!groups.has(key)) groups.set(key, { ...r, count: 0, locations: [] });
    const g = groups.get(key);
    g.count += 1;
    if (g.locations.length < 6) g.locations.push(`${r.file}:${r.line}`);
  }
  const list = [...groups.values()];
  list.sort((a, b) => {
    const ar = Math.min(a.themes.light?.ratio ?? 99, a.themes.dark?.ratio ?? 99);
    const br = Math.min(b.themes.light?.ratio ?? 99, b.themes.dark?.ratio ?? 99);
    return ar - br || b.count - a.count;
  });
  return { total: scoped.length, groups: list.slice(0, limit), truncated: Math.max(0, list.length - limit) };
}

export { varsForState };
