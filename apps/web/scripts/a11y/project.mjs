/**
 * Project context: read the real files, build the remap table, the palette and
 * the theme-state variable maps.
 *
 * The theme states are read from index.html, not assumed. The inline script
 * there does `document.documentElement.classList.toggle("dark", dark)` and
 * `classList.toggle("light", !dark)` - exactly one of the two is on <html> at
 * any time - so "theme state" means a class on the root element, and a remap
 * rule is only ever active for one of those two.
 */

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { pathToFileURL } from 'node:url';

import { TAILWIND_PALETTE } from './palette.generated.mjs';
import {
  parseComponentRules,
  parseCssVars,
  parseRemapTable,
  varsForState,
} from './remap.mjs';
import { buildElementModel, findColourUtilities } from './scan.mjs';

export function listSourceFiles(srcDir) {
  const out = [];
  const walk = (dir) => {
    for (const entry of readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      const full = join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (/\.(ts|tsx)$/.test(entry.name) && !/\.d\.ts$/.test(entry.name)) out.push(full);
    }
  };
  walk(srcDir);
  return out;
}

function readFileOr(file, fallback = '') {
  try {
    return readFileSync(file, 'utf8');
  } catch {
    return fallback;
  }
}

/** Theme-state classes, from the inline bootstrap script in index.html. */
export function themeStatesFrom(html) {
  const states = new Set();
  for (const m of html.matchAll(/classList\.toggle\(\s*["'`]([a-zA-Z-]+)["'`]/g)) {
    states.add(m[1]);
  }
  return [...states].filter((s) => s === 'dark' || s === 'light');
}

export function bodyClassesFrom(html) {
  const m = /<body[^>]*class="([^"]*)"/.exec(html);
  return m ? m[1].split(/\s+/).filter(Boolean) : [];
}

/** Flatten tailwind.config.js `theme.extend.colors` into the palette shape. */
async function loadConfigColors(configPath) {
  try {
    const mod = await import(pathToFileURL(configPath).href);
    const colors = mod?.default?.theme?.extend?.colors ?? {};
    const flat = {};
    for (const [name, value] of Object.entries(colors)) {
      if (typeof value === 'string') flat[name] = value;
      else if (value && typeof value === 'object') flat[name] = { ...value };
    }
    return flat;
  } catch {
    return {};
  }
}

/**
 * Build the full analysis context for a web app directory.
 */
export async function buildContext(webRoot) {
  const css = readFileOr(join(webRoot, 'src/index.css'));
  const html = readFileOr(join(webRoot, 'index.html'));
  if (!css) throw new Error(`cannot read ${join(webRoot, 'src/index.css')}`);

  const states = themeStatesFrom(html);
  const table = parseRemapTable(css, states.length ? states : ['light', 'dark']);
  const varsBySelector = parseCssVars(css);

  const configColors = await loadConfigColors(join(webRoot, 'tailwind.config.js'));
  const palette = { ...TAILWIND_PALETTE, ...configColors };

  const vars = {};
  for (const state of ['light', 'dark']) vars[state] = varsForState(varsBySelector, state);

  return {
    webRoot,
    css,
    html,
    states,
    table,
    components: parseComponentRules(css),
    palette,
    vars,
    bodyClasses: bodyClassesFrom(html),
    darkMode: readFileOr(join(webRoot, 'tailwind.config.js')).match(/darkMode:\s*['"](\w+)['"]/)?.[1] ?? 'class',
  };
}

/** Scan every source file for colour utilities and build the element model. */
export function scanProject(ctx) {
  const srcDir = join(ctx.webRoot, 'src');
  const files = listSourceFiles(srcDir);
  const usages = [];
  let model = { nodes: [], roots: [] };
  for (const file of files) {
    const source = readFileSync(file, 'utf8');
    const rel = relative(ctx.webRoot, file);
    usages.push(...findColourUtilities(source, ctx.palette, rel));
    const built = buildElementModel(source);
    for (const node of built.nodes) {
      node.file = rel;
      model.nodes.push(node);
      if (node.parent) node.parent.children.push(node);
      else model.roots.push(node);
    }
  }
  return { usages, model, files };
}

export function projectSize(webRoot) {
  const srcDir = join(webRoot, 'src');
  try {
    return statSync(srcDir);
  } catch {
    return null;
  }
}
