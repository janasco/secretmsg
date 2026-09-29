/**
 * Source scanning: find Tailwind colour utilities in `src/**\/*.{ts,tsx}`
 * with accurate file:line, and build a nesting-aware element model for the
 * contrast pass.
 *
 * Deliberately string-literal-driven rather than AST-driven. Tailwind itself
 * scans this codebase as raw text (`content: ['./src/**\/*.{js,ts,jsx,tsx}']`,
 * no `extract` plugins configured), so class tokens live inside string
 * literals, conditional expressions and template literals. Reading the literals
 * is both simpler and *more* faithful to what the compiler will emit than
 * parsing a module would be.
 *
 * Comments are blanked first, with offsets preserved, so a class name in a
 * prose comment cannot become a finding.
 */

import { classifyClass, splitVariants } from './classes.mjs';
import { lineAt } from './remap.mjs';

/** Replace JS comments with spaces, preserving every offset and newline. */
export function blankJsComments(source) {
  let out = '';
  let i = 0;
  const n = source.length;
  while (i < n) {
    const ch = source[i];
    const next = source[i + 1];
    if (ch === '"' || ch === "'" || ch === '`') {
      const end = skipString(source, i);
      out += source.slice(i, end);
      i = end;
      continue;
    }
    if (ch === '/' && next === '/') {
      const end = source.indexOf('\n', i);
      const stop = end === -1 ? n : end;
      out += ' '.repeat(stop - i);
      i = stop;
      continue;
    }
    if (ch === '/' && next === '*') {
      const end = source.indexOf('*/', i + 2);
      const stop = end === -1 ? n : end + 2;
      for (let j = i; j < stop; j += 1) out += source[j] === '\n' ? '\n' : ' ';
      i = stop;
      continue;
    }
    out += ch;
    i += 1;
  }
  return out;
}

/** Index just past the closing quote of the string literal starting at `i`. */
function skipString(src, i) {
  const quote = src[i];
  let j = i + 1;
  while (j < src.length) {
    const ch = src[j];
    if (ch === '\\') {
      j += 2;
      continue;
    }
    if (quote === '`' && ch === '$' && src[j + 1] === '{') {
      let depth = 1;
      j += 2;
      while (j < src.length && depth > 0) {
        if (src[j] === '{') depth += 1;
        else if (src[j] === '}') depth -= 1;
        else if (src[j] === '"' || src[j] === "'" || src[j] === '`') j = skipString(src, j) - 1;
        j += 1;
      }
      continue;
    }
    if (ch === quote) return j + 1;
    if (quote !== '`' && (ch === '\n')) return j; // unterminated; bail at EOL
    j += 1;
  }
  return src.length;
}

/**
 * Every colour utility occurrence, with file:line.
 *
 * `where` records the literal the token came from so a report can quote the
 * surrounding context.
 */
export function findColourUtilities(source, palette, file) {
  const blanked = blankJsComments(source);
  const found = [];
  let i = 0;
  while (i < blanked.length) {
    const ch = blanked[i];
    if (ch !== '"' && ch !== "'" && ch !== '`') {
      i += 1;
      continue;
    }
    const end = skipString(blanked, i);
    const content = source.slice(i + 1, end - 1);
    let cursor = i + 1;
    for (const token of content.split(/[\s"'`,]+/)) {
      if (!token) continue;
      const tokenStart = cursor;
      cursor += token.length + 1;
      const info = classifyClass(token, palette);
      if (!info) continue;
      found.push({
        ...info,
        file,
        line: lineAt(source, tokenStart),
        column: tokenStart - (lineAt(source, tokenStart) === 1 ? 0 : source.lastIndexOf('\n', tokenStart - 1) + 1) + 1,
        offset: tokenStart,
      });
    }
    i = end;
  }
  return found;
}

/* ------------------------------------------------------------------ */
/* Nesting-aware element model                                          */
/* ------------------------------------------------------------------ */

/** Characters after which a `<` can only be JSX, not a comparison operator. */
const JSX_PRECEDERS = new Set(['(', '{', '>', '[', '=', ',', ':', ';', '?', '!', '&', '|', '}', '+', '\n', '']);

function canOpenJsx(source, index) {
  let j = index - 1;
  while (j >= 0 && /\s/.test(source[j])) j -= 1;
  if (j < 0) return true;
  const ch = source[j];
  if (JSX_PRECEDERS.has(ch)) return true;
  const tail = source.slice(Math.max(0, j - 6), j + 1);
  return /\breturn$/.test(tail) || /[=({[?:&|,]$/.test(tail);
}

/**
 * A flat, nesting-aware list of JSX elements with their className literals.
 *
 * This is a scanner, not a parser: it understands tag boundaries, string
 * literals and brace depth, which is enough for element containment in
 * idiomatic JSX. It does not evaluate expressions, so a className chosen by a
 * ternary contributes *all* of its branches rather than one. That is recorded
 * on the node (`alternatives`) and the contrast pass reports it as
 * lower-confidence rather than pretending it picked a branch.
 */
export function buildElementModel(source) {
  const blanked = blankJsComments(source);
  const roots = [];
  const stack = [];
  const all = [];
  let i = 0;

  const push = (node) => {
    node.parent = stack.length ? stack[stack.length - 1] : null;
    node.depth = stack.length;
    if (node.parent) node.parent.children.push(node);
    else roots.push(node);
    all.push(node);
  };

  while (i < blanked.length) {
    const ch = blanked[i];
    if (ch === '"' || ch === "'" || ch === '`') {
      i = skipString(blanked, i);
      continue;
    }
    // Closing tag: pop back to the matching open element. Checked before the
    // "could this be JSX?" guard, because the character before a close tag is
    // usually the last letter of the text it wraps - `...</Link>` after
    // "Full Account Login" - and that is not a JSX-legal position for an
    // opening tag. Guarding here silently skipped most close tags and turned
    // the ancestor chain into a flat list of every element in the file.
    if (ch === '<' && blanked[i + 1] === '/') {
      const closeMatch = /^<\/\s*([A-Za-z][\w.-]*)?\s*>/.exec(blanked.slice(i, i + 80));
      if (closeMatch) {
        const name = closeMatch[1] ?? 'Fragment';
        for (let k = stack.length - 1; k >= 0; k -= 1) {
          if (stack[k].tag === name) {
            stack.length = k;
            break;
          }
        }
        i += closeMatch[0].length;
        continue;
      }
    }
    if (ch !== '<' || !canOpenJsx(blanked, i)) {
      i += 1;
      continue;
    }
    // Fragment shorthand.
    if (blanked[i + 1] === '>') {
      push({
        tag: 'Fragment',
        line: lineAt(source, i),
        offset: i,
        attrText: '',
        classes: [],
        styleColours: [],
        children: [],
        selfClosing: false,
      });
      stack.push(all[all.length - 1]);
      i += 2;
      continue;
    }
    const nameMatch = /^<([A-Za-z][\w.-]*)/.exec(blanked.slice(i, i + 80));
    if (!nameMatch) {
      i += 1;
      continue;
    }
    const tag = nameMatch[1];
    const attrStart = i + nameMatch[0].length;
    let j = attrStart;
    let depth = 0;
    let selfClosing = false;
    while (j < blanked.length) {
      const c = blanked[j];
      if (c === '"' || c === "'" || c === '`') {
        j = skipString(blanked, j);
        continue;
      }
      if (c === '{') depth += 1;
      else if (c === '}') depth -= 1;
      else if (c === '>' && depth === 0) {
        selfClosing = blanked[j - 1] === '/';
        break;
      }
      j += 1;
    }
    if (j >= blanked.length) break;

    const attrText = source.slice(attrStart, selfClosing ? j - 1 : j);
    const node = {
      tag,
      line: lineAt(source, i),
      offset: i,
      attrText,
      classes: classLiterals(source, attrStart, selfClosing ? j - 1 : j),
      styleColours: styleColours(source, attrStart, selfClosing ? j - 1 : j),
      selfClosing,
      children: [],
      parent: null,
      depth: 0,
    };
    push(node);
    if (!selfClosing) stack.push(node);
    i = j + 1;
  }
  return { roots, nodes: all };
}

function classLiterals(source, start, end) {
  const out = [];
  let i = start;
  while (i < end) {
    const ch = source[i];
    if (ch === '"' || ch === "'" || ch === '`') {
      const literalEnd = skipString(source, i);
      const value = source.slice(i + 1, Math.min(literalEnd - 1, end));
      if (/\s/.test(value) || /^(bg|text|border|from|via|to|fill|ring|divide|placeholder)-/.test(value)) {
        out.push({ value, offset: i, conditional: /\$\{|\?/.test(value) });
      }
      i = Math.min(literalEnd, end);
      continue;
    }
    i += 1;
  }
  return out;
}

const COLOUR_LITERAL = /#[0-9a-fA-F]{3,8}\b|rgba?\([^)]*\)/g;

function styleColours(source, start, end) {
  const attrText = source.slice(start, end);
  if (!/style\s*=/.test(attrText)) return [];
  const styleStart = start + attrText.indexOf('style');
  const window = source.slice(styleStart, Math.min(styleStart + 400, end));
  return [...window.matchAll(COLOUR_LITERAL)].map((m) => ({
    value: m[0],
    offset: styleStart + m.index,
    line: lineAt(source, styleStart + m.index),
  }));
}

/** Human-readable site-relative path for reporting. */
export function relative(file, root) {
  return file.startsWith(`${root}/`) ? file.slice(root.length + 1) : file;
}

export { splitVariants };
