/**
 * Parser for the theme remap table in `src/index.css`.
 *
 * The site is styled dark-first. `index.css` carries a block of `.light ...`
 * rules that re-point individual *utility class tokens* at light-mode values,
 * plus `.light .dark-island ...` rules that re-assert the dark values inside
 * intentionally-dark islands. The important structural fact, and the one that
 * the defect this tool exists for turns on, is that these are **class-token
 * selectors**: `.light .text-amber-200` does not match `.text-amber-200/90`,
 * because that is a different token. So the remap table is modelled here as a
 * set of exact class tokens, not as a set of colour families.
 */

import { parseColor } from './color.mjs';

/** Blank out comments while preserving every byte offset and newline. */
export function blankComments(css) {
  let out = '';
  let i = 0;
  while (i < css.length) {
    if (css[i] === '/' && css[i + 1] === '*') {
      const end = css.indexOf('*/', i + 2);
      const stop = end === -1 ? css.length : end + 2;
      for (let j = i; j < stop; j += 1) out += css[j] === '\n' ? '\n' : ' ';
      i = stop;
    } else if (css[i] === '/' && css[i + 1] === '/') {
      const end = css.indexOf('\n', i);
      const stop = end === -1 ? css.length : end;
      for (let j = i; j < stop; j += 1) out += ' ';
      i = stop;
    } else {
      out += css[i];
      i += 1;
    }
  }
  return out;
}

/** 1-based line number of a character offset. */
export function lineAt(source, offset) {
  let line = 1;
  for (let i = 0; i < offset && i < source.length; i += 1) if (source[i] === '\n') line += 1;
  return line;
}

/** Split a comma-separated list at bracket/paren depth zero. */
function splitTopLevel(text, sep) {
  const parts = [];
  let depth = 0;
  let current = '';
  for (const ch of text) {
    if (ch === '(' || ch === '[') depth += 1;
    else if (ch === ')' || ch === ']') depth -= 1;
    if (ch === sep && depth === 0) {
      parts.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  parts.push(current);
  return parts.map((p) => p.trim()).filter(Boolean);
}

/** Every `{...}` block in the stylesheet, as { selector, body, selectorLine }. */
export function parseBlocks(css) {
  const src = blankComments(css);
  const blocks = [];
  let depth = 0;
  let start = -1;
  for (let i = 0; i < src.length; i += 1) {
    const ch = src[i];
    if (ch === '{') {
      if (depth === 0) start = i;
      depth += 1;
    } else if (ch === '}') {
      depth -= 1;
      if (depth === 0 && start !== -1) {
        const selector = src.slice(prevBoundary(src, start) + 1, start).trim();
        blocks.push({
          selector,
          body: src.slice(start + 1, i),
          line: lineAt(src, start),
        });
        start = -1;
      }
    }
  }
  return blocks;
}

function prevBoundary(src, index) {
  for (let i = index - 1; i >= 0; i -= 1) {
    if (src[i] === '}' || src[i] === ';') return i;
  }
  return -1;
}

/** `prop: value` declarations inside a block body. */
export function parseDeclarations(body, bodyOffsetInSource) {
  const decls = [];
  for (const chunk of splitTopLevel(body, ';')) {
    const colon = chunk.indexOf(':');
    if (colon <= 0) continue;
    decls.push({
      property: chunk.slice(0, colon).trim().toLowerCase(),
      value: chunk.slice(colon + 1).trim(),
      offset: bodyOffsetInSource + 1,
    });
  }
  return decls;
}

/** Custom-property blocks keyed by their declaring selector, e.g. `:root`, `.dark`. */
export function parseCssVars(css) {
  const src = blankComments(css);
  const out = new Map();
  for (const block of parseBlocks(src)) {
    const vars = {};
    for (const decl of parseDeclarations(block.body)) {
      if (!decl.property.startsWith('--')) continue;
      vars[decl.property] = decl.value;
    }
    if (Object.keys(vars).length === 0) continue;
    const key = block.selector.trim();
    out.set(key, { ...(out.get(key) ?? {}), ...vars });
  }
  return out;
}

/**
 * Resolve the CSS custom properties visible in a given theme state.
 *
 * `:root` is the base; `.dark` / `.light` (or whatever states exist) layer on
 * top. Returns null for a state with no declared variables, which callers must
 * treat as "unknown", never as "inherits the light values".
 */
export function varsForState(varsBySelector, state) {
  const merged = {};
  let seen = false;
  for (const [selector, vars] of varsBySelector) {
    const isBase = selector === ':root' || selector === 'html';
    const matches = isBase || selector === `.${state}`;
    if (!matches) continue;
    Object.assign(merged, vars);
    seen = true;
  }
  return seen ? merged : null;
}

/** Undo CSS identifier escaping: `bg-white\/10` -> `bg-white/10`. */
export function unescapeCssIdent(raw) {
  return raw.replace(/\\(.)/g, '$1');
}

function readClassTokens(selector) {
  const classes = [];
  const attributes = [];
  const pseudos = [];
  let i = 0;
  while (i < selector.length) {
    const ch = selector[i];
    if (ch === '\\') {
      i += 2;
      continue;
    }
    if (ch === '.') {
      let j = i + 1;
      let raw = '';
      while (j < selector.length) {
        const c = selector[j];
        if (c === '\\') {
          raw += c + selector[j + 1];
          j += 2;
          continue;
        }
        if (/[-\w]/.test(c)) {
          raw += c;
          j += 1;
          continue;
        }
        break;
      }
      classes.push({ name: unescapeCssIdent(raw), index: i });
      i = j;
      continue;
    }
    if (ch === '[') {
      const end = selector.indexOf(']', i);
      attributes.push(selector.slice(i, end === -1 ? selector.length : end + 1));
      i = end === -1 ? selector.length : end + 1;
      continue;
    }
    if (ch === ':') {
      let j = i + 1;
      while (j < selector.length && /[-\w]/.test(selector[j])) j += 1;
      const name = selector.slice(i + 1, j);
      if (selector[j] === '(') {
        let depth = 0;
        let k = j;
        for (; k < selector.length; k += 1) {
          if (selector[k] === '(') depth += 1;
          else if (selector[k] === ')') {
            depth -= 1;
            if (depth === 0) break;
          }
        }
        pseudos.push({ name, arg: selector.slice(j + 1, k) });
        i = k + 1;
      } else {
        pseudos.push({ name, arg: null });
        i = j;
      }
      continue;
    }
    i += 1;
  }
  return { classes, attributes, pseudos };
}

/** `[class~="bg-indigo-500"]` tokens inside a `:where()` exclusion list. */
function exclusionTokens(pseudo) {
  if (!pseudo.arg) return [];
  return [...pseudo.arg.matchAll(/\[class~="([^"]+)"\]/g)].map((m) => m[1]);
}

/**
 * Build the remap table.
 *
 * @param css      contents of index.css
 * @param states   theme-state class names (from index.html + var blocks)
 * @returns { entries, byToken, byAttribute, states }
 */
export function parseRemapTable(css, states) {
  const stateSet = new Set(states);
  const entries = [];
  for (const block of parseBlocks(css)) {
    for (const selector of splitTopLevel(block.selector, ',')) {
      const { classes, attributes, pseudos } = readClassTokens(selector);
      if (classes.length === 0) continue;
      const subject = classes[classes.length - 1];
      const ancestors = classes.slice(0, -1);
      const selectorStates = ancestors.filter((c) => stateSet.has(c.name)).map((c) => c.name);
      if (selectorStates.length === 0) continue;
      const scope = ancestors
        .filter((c) => !stateSet.has(c.name))
        .map((c) => c.name);

      const decls = parseDeclarations(block.body).filter((d) => /^(-webkit-)?(color|background-color|border-color|background-image|text-decoration-color|outline-color|fill|stroke)$/.test(d.property));
      if (decls.length === 0) continue;

      const exclusions = pseudos.flatMap(exclusionTokens);
      for (const decl of decls) {
        entries.push({
          subject: subject.name,
          states: selectorStates,
          scope,
          pseudos: pseudos.map((p) => p.name).filter((p) => p !== 'where' && p !== 'is' && p !== 'not'),
          attributes,
          exclusions,
          // Cascade order. `.light .dark-island .text-slate-300` must beat
          // `.light .text-slate-300`, and it only does because it is three
          // classes deep instead of two. Taking whichever rule happened to be
          // parsed first meant `dark-island` silently did nothing. Ties break on
          // source order, which is how the browser breaks them too.
          specificity: classSpecificity(selector),
          property: decl.property,
          value: decl.value,
          line: block.line,
          selector: selector,
        });
      }
    }
  }

  const byToken = new Map();
  const byAttribute = new Map();
  for (const entry of entries) {
    if (!byToken.has(entry.subject)) byToken.set(entry.subject, []);
    byToken.get(entry.subject).push(entry);
    for (const attr of entry.attributes) {
      const m = /^\[([\w-]*)\^?=["']?([^"'\]]*)["']?\]$/.exec(attr);
      if (!m) continue;
      const key = `${m[1]}:${m[2]}`;
      if (!byAttribute.has(key)) byAttribute.set(key, []);
      byAttribute.get(key).push(entry);
    }
  }
  byToken.forEach((list) => list.sort((a, b) => b.specificity - a.specificity || b.line - a.line));
  byAttribute.forEach((list) => list.sort((a, b) => b.specificity - a.specificity || b.line - a.line));

  return { entries, byToken, byAttribute, states: [...stateSet] };
}

/**
 * Class-and-pseudo-class specificity of a selector, with `:where()` zeroed.
 *
 * `:where()` contributes nothing, *including* everything nested inside it, so
 * `:where(:not([class~="bg-indigo-500"]))` is worth exactly 0. That is not a
 * detail: index.css relies on it. Its header comment says the exclusion lists
 * "use :where() so these rules stay at (0,2,0)" and the `.dark-island`
 * re-assertions at (0,3,0) therefore win. Counting the nested `[class~=]`
 * selectors instead would put the exclusions at (0,24,0), make them beat the
 * island, and silently break every `dark-island` in the app.
 *
 * This is not a general CSS specificity implementation and does not need to be.
 * It only orders the remap table's own selectors against each other, which are
 * all class selectors plus functional pseudo-classes.
 */
function classSpecificity(selector) {
  const flattened = zeroWhere(selector);
  let score = 0;
  for (const m of flattened.matchAll(/\.[-\w\\]+|::?[-w]+/g)) {
    if (m[0] === ':not') continue;
    score += 1;
  }
  return score;
}

/** Replace every `:where(...)`, including nested parentheses, with spaces. */
function zeroWhere(selector) {
  let out = '';
  let i = 0;
  while (i < selector.length) {
    if (selector.startsWith(':where(', i)) {
      let depth = 0;
      let j = i + ':where('.length - 1;
      for (; j < selector.length; j += 1) {
        if (selector[j] === '(') depth += 1;
        else if (selector[j] === ')') {
          depth -= 1;
          if (depth === 0) break;
        }
      }
      for (let k = i; k <= j && k < selector.length; k += 1) out += selector[k] === '\n' ? '\n' : ' ';
      i = j + 1;
      continue;
    }
    out += selector[i];
    i += 1;
  }
  return out;
}

/** Convenience: every class token the table has an opinion about. */
export function remappedTokens(table) {
  return new Set(table.byToken.keys());
}

/**
 * Component classes defined in the stylesheet itself - `.glass-panel` above all.
 *
 * These paint surfaces without being Tailwind utilities, so the contrast pass
 * would otherwise treat a glass card as transparent and inherit the modal
 * scrim behind it. That mistake alone produced dozens of phantom "black on
 * black" findings before this parser existed.
 */
export function parseComponentRules(css) {
  const src = blankComments(css);
  const out = new Map();
  for (const block of parseBlocks(src)) {
    const { classes, pseudos } = readClassTokens(block.selector);
    if (classes.length !== 1 || pseudos.length > 0) continue;
    const declarations = parseDeclarations(block.body).filter((d) => (
      /^(background|background-color|border|border-color|color|outline-color)$/.test(d.property)
    ));
    if (declarations.length === 0) continue;
    const props = {};
    for (const d of declarations) props[d.property] = { value: d.value, line: block.line };
    out.set(classes[0].name, { className: classes[0].name, line: block.line, props });
  }
  return out;
}

/** Resolve a declaration's value to a colour, following `var(--token)`. */
export function resolveEntryColour(entry, vars) {
  const raw = entry.value;
  if (/gradient|var\(--[^)]*,/.test(raw)) return null;
  const direct = parseColor(raw, vars);
  if (direct) return direct;
  const fallback = /var\(\s*(--[\w-]+)\s*,/.exec(raw);
  if (fallback && vars) return parseColor(vars[fallback[1]], vars);
  return null;
}
