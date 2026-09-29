#!/usr/bin/env node
/**
 * a11y-color - static theme/contrast analysis for the SecretMsg web app.
 *
 *   node scripts/a11y-color.mjs [options]
 *
 * The defect this exists for: `src/index.css` re-points individual *utility
 * class tokens* for light mode (`.light .text-amber-200 { color: #b45309 }`).
 * A Tailwind opacity modifier makes a *different* class token
 * (`.text-amber-200/90`), which such a selector cannot match. The element then
 * renders the dark-theme colour in light mode. That is invisible to a grep for
 * `text-amber-200`, which is exactly how it shipped.
 *
 * Exit codes
 *   0  clean, or clean relative to the recorded baseline
 *   1  findings matched the failing mode
 *   2  the tool itself failed (bad flags, unreadable project)
 *
 * Failing mode (default: `bypass`, the shipped defect class)
 *   --fail-on <list>   comma-separated rule ids, or `none`
 *   A11Y_FAIL_ON=<list>                     env equivalent, lower precedence
 *   --strict            shorthand for `--fail-on bypass,sibling-gap,unremapped-surface,contrast`
 *   --baseline <file>   known findings that do not fail the run (default below)
 *   --update-baseline   rewrite the baseline with everything found this run
 *   --format text|json  human output (default) or machine output
 *   --explain src/pages/X.tsx:12[,...]
 *                      measure every foreground at those lines, pass or fail.
 *                      A fix cannot be verified otherwise: the point where it
 *                      worked is the point where the tool stops reporting.
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { analyseContrast, analyseUsages, pageBackground, summariseContrast } from './a11y/analyze.mjs';
import { toHex } from './a11y/color.mjs';
import { buildContext, scanProject } from './a11y/project.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const DEFAULT_BASELINE = join(HERE, 'a11y/baseline.json');
const DEFAULT_FAIL_ON = 'bypass';

const RULE_IDS = ['bypass', 'sibling-gap', 'unremapped-surface', 'contrast'];
const RULE_LABEL = {
  bypass: 'remap bypass (opacity-modified colour opts out of the light-mode remap)',
  'sibling-gap': 'remap sibling gap (alpha the remap table does not list)',
  'unremapped-surface': 'unremapped surface colour',
  contrast: 'measured WCAG AA contrast failure',
};

function parseArgs(argv) {
  const opts = {
    failOn: process.env.A11Y_FAIL_ON || DEFAULT_FAIL_ON,
    format: 'text',
    baseline: DEFAULT_BASELINE,
    updateBaseline: false,
    strict: false,
    maxContrast: 40,
    explain: [],
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--fail-on') opts.failOn = argv[++i] ?? '';
    else if (arg.startsWith('--fail-on=')) opts.failOn = arg.slice('--fail-on='.length);
    else if (arg === '--strict') opts.strict = true;
    else if (arg === '--format') opts.format = argv[++i] ?? 'text';
    else if (arg.startsWith('--format=')) opts.format = arg.slice('--format='.length);
    else if (arg === '--baseline') opts.baseline = resolve(argv[++i] ?? DEFAULT_BASELINE);
    else if (arg.startsWith('--baseline=')) opts.baseline = resolve(arg.slice('--baseline='.length));
    else if (arg === '--update-baseline') opts.updateBaseline = true;
    else if (arg === '--max-contrast') opts.maxContrast = Number(argv[++i] ?? 40);
    else if (arg === '--explain') opts.explain.push(...(argv[++i] ?? '').split(','));
    else if (arg.startsWith('--explain=')) opts.explain.push(...arg.slice('--explain='.length).split(','));
    else if (arg === '--help' || arg === '-h') opts.help = true;
    else throw new Error(`unknown flag: ${arg}`);
  }
  if (opts.strict) opts.failOn = RULE_IDS.join(',');
  return opts;
}

function loadBaseline(path) {
  if (!existsSync(path)) return { version: 1, findings: [] };
  try {
    const parsed = JSON.parse(readFileSync(path, 'utf8'));
    if (!Array.isArray(parsed.findings)) throw new Error('findings must be an array');
    return parsed;
  } catch (err) {
    throw new Error(`baseline ${path} is unreadable: ${err.message}`);
  }
}

const C = {
  reset: '\x1b[0m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  green: '\x1b[32m',
  cyan: '\x1b[36m',
  bold: '\x1b[1m',
};

function useColour(stream) {
  return stream.isTTY && !process.env.NO_COLOR;
}

async function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (err) {
    process.stderr.write(`a11y-color: ${err.message}\n`);
    return 2;
  }
  if (opts.help) {
    process.stdout.write(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('*/')[0].replace(/^\/\*\*?\n?/, '').replace(/^ \* ?/gm, ''));
    return 0;
  }

  const webRoot = process.env.A11Y_WEB_ROOT
    ? resolve(process.env.A11Y_WEB_ROOT)
    : resolve(HERE, '..');

  let ctx;
  let scan;
  try {
    ctx = await buildContext(webRoot);
    // --explain takes repo-relative `src/...:line`; normalise either spelling.
    ctx.explainLines = new Set(opts.explain.map((s) => String(s).trim()
      .replace(/^apps\/web\//, '')
      .replace(/^src\/pages\//, 'src/pages/')).filter(Boolean));
    scan = scanProject(ctx);
  } catch (err) {
    process.stderr.write(`a11y-color: ${err.message}\n`);
    return 2;
  }

  const { bypasses, siblingGaps, unremapped, byDesign } = analyseUsages(scan.usages, ctx);
  const contrast = analyseContrast(scan.model, ctx);
  const contrastSummary = summariseContrast(contrast.results, opts.maxContrast);

  const byRule = {
    bypass: bypasses,
    'sibling-gap': siblingGaps,
    'unremapped-surface': unremapped,
    contrast: contrast.results,
  };
  const failuresByRule = {};
  for (const rule of RULE_IDS) failuresByRule[rule] = byRule[rule].length;

  const baseline = opts.updateBaseline
    ? { version: 1, findings: [] }
    : loadBaseline(opts.baseline);
  const knownIds = new Map(baseline.findings.map((f) => [f.id, f]));
  const allFindings = [...bypasses, ...siblingGaps, ...unremapped, ...contrast.results];
  for (const f of allFindings) {
    f.known = knownIds.has(f.id);
  }
  const newFindings = allFindings.filter((f) => !f.known);

  const failRules = opts.failOn === 'none' || opts.failOn === ''
    ? new Set()
    : new Set(opts.failOn.split(',').map((s) => s.trim()).filter(Boolean));
  for (const rule of failRules) {
    if (!RULE_IDS.includes(rule)) {
      process.stderr.write(`a11y-color: unknown rule "${rule}" (known: ${RULE_IDS.join(', ')})\n`);
      return 2;
    }
  }
  const triggered = newFindings.filter((f) => failRules.has(
    f.rule === 'remap-bypass' ? 'bypass'
      : f.rule === 'remap-sibling-gap' ? 'sibling-gap'
        : f.rule === 'unremapped-surface' ? 'unremapped-surface' : 'contrast',
  ));

  if (opts.updateBaseline) {
    const merged = new Map(baseline.findings.map((f) => [f.id, f]));
    for (const f of allFindings) merged.set(f.id, { id: f.id, note: f.note ?? 'recorded pre-existing, see note' });
    const payload = {
      version: 1,
      tool: 'scripts/a11y-color.mjs',
      webRoot: 'apps/web',
      note:
        'Findings already present when this tool was introduced. They do not fail the default gate; '
        + 'remove an entry to make that finding fail again. Do not add entries casually - the point is '
        + 'that the gate catches the *next* one.',
      findings: [...merged.values()].sort((a, b) => a.id.localeCompare(b.id)),
    };
    writeFileSync(opts.baseline, `${JSON.stringify(payload, null, 2)}\n`);
    process.stdout.write(`baseline written: ${opts.baseline} (${payload.findings.length} entries)\n`);
  }

  const page = {
    light: toHex(pageBackground(ctx, 'light')),
    dark: toHex(pageBackground(ctx, 'dark')),
  };

  if (opts.format === 'json') {
    process.stdout.write(`${JSON.stringify({
      webRoot,
      states: ctx.states,
      darkMode: ctx.darkMode,
      pageBackground: page,
      remapTableSize: ctx.table.entries.length,
      failingMode: opts.failOn,
      explain: [...(ctx.explainLines ?? [])],
      counts: failuresByRule,
      new: newFindings.length,
      findings: {
        bypasses,
        siblingGaps,
        unremapped,
        byDesign,
        contrast: contrastSummary,
        unresolvedContrast: contrast.unresolved.length,
      },
      exit: triggered.length > 0 ? 1 : 0,
    }, null, 2)}\n`);
    return triggered.length > 0 ? 1 : 0;
  }

  return renderText({
    opts, ctx, scan, page, byRule, newFindings, triggered, contrastSummary, contrast, baseline,
    byDesign,
  });
}

function pad(s, n) {
  return String(s).padEnd(n);
}

function renderText(data) {
  const {
    opts, ctx, scan, page, byRule, newFindings, triggered, contrastSummary, contrast, baseline,
    byDesign,
  } = data;
  const colour = useColour(process.stdout);
  const c = (code, s) => (colour ? `${code}${s}${C.reset}` : s);
  const out = [];
  const say = (s = '') => out.push(s);

  say(c(C.bold, 'a11y-color') + c(C.dim, `  ${opts.format === 'text' ? '' : ''}${scan.files.length} files, ${ctx.table.entries.length} remap rules, ${scan.usages.length} colour utilities`));
  say(c(C.dim, `  theme states from index.html: ${ctx.states.join(', ')}   darkMode: ${ctx.darkMode}`));
  say(c(C.dim, `  page background: light ${page.light}  dark ${page.dark}`));
  say(c(C.dim, `  baseline: ${opts.baseline} (${baseline.findings.length} recorded findings, not failing)`));
  say();

  let sectionNo = 0;
  const section = (title) => {
    sectionNo += 1;
    say(c(C.bold, `${sectionNo}. ${title}`));
  };

  // --- 1. remap bypass ---
  section('REMAP BYPASS');
  if (byRule.bypass.length === 0) {
    say(c(C.green, '   none'));
  } else {
    say(c(C.dim, '   a colour utility whose base class is remapped, used in a form the remap cannot match'));
    for (const f of byRule.bypass) {
      const mark = f.known ? c(C.dim, 'known ') : c(C.red, 'NEW   ');
      say(`   ${mark}${c(C.bold, f.token)}  ${f.file}:${f.line}`);
      say(`         base class "${f.base}" remapped at src/index.css:${f.remapLine} -> ${f.remapSelector.trim()}`);
      say(c(C.dim, `         ${f.detail}`));
    }
  }
  say();

  section('REMAP SIBLING GAP');
  if (byRule.siblingGapCount === undefined && byRule['sibling-gap'].length === 0) say(c(C.green, '   none'));
  else {
    say(c(C.dim, '   the remap table lists other alphas for this utility but not this one'));
    for (const f of byRule['sibling-gap']) {
      const mark = f.known ? c(C.dim, 'known ') : c(C.yellow, 'NEW   ');
      say(`   ${mark}${c(C.bold, f.token)}  ${f.file}:${f.line}   ${c(C.dim, `also mapped: ${f.siblings.join(', ')}`)}`);
    }
  }
  say();

  section('UNRE MAPPED SURFACE COLOURS');
  if (byRule['unremapped-surface'].length === 0 && byDesign.length === 0) {
    say(c(C.green, '   none'));
  } else {
    say(c(C.dim, `   ${byDesign.length} further occurrences are surfaces with no remap that index.css states are`));
    say(c(C.dim, '   deliberately theme-independent (solid buttons, tinted chips, gradient stops). Those are an'));
    say(c(C.dim, '   inventory, not findings, and do not fail the gate.'));
    const groups = new Map();
    for (const f of [...byRule['unremapped-surface'], ...data.byDesign]) {
      const g = groups.get(f.token) ?? { ...f, count: 0, locations: [] };
      g.count += 1;
      if (g.locations.length < 4) g.locations.push(`${f.file}:${f.line}`);
      groups.set(f.token, g);
    }
    const byVerdict = new Map();
    for (const g of groups.values()) {
      if (!byVerdict.has(g.verdict)) byVerdict.set(g.verdict, []);
      byVerdict.get(g.verdict).push(g);
    }
    const order = [
      ['defect', C.red, 'cannot follow the theme - judgement: should be remapped'],
      ['review', C.yellow, 'no light-mode remap - judgement: needs a look'],
      ['by-design', C.dim, 'no light-mode remap - judgement: static by design'],
    ];
    for (const [verdict, code, label] of order) {
      const all = (byVerdict.get(verdict) ?? []).sort((a, b) => b.count - a.count);
      if (all.length === 0) continue;
      const uses = all.reduce((n, g) => n + g.count, 0);
      // by-design is the documented behaviour for hue surfaces and is by far the
      // largest bucket. Printing all of it would bury the two tokens that
      // actually need a decision, so the head is shown and the tail is one
      // pointer to the JSON.
      const list = verdict === 'by-design' ? all.slice(0, 6) : all;
      say(`   ${c(C.bold, String(all.length))} distinct utilities, ${uses} uses - ${label}`);
      for (const g of list) {
        const mark = g.known ? c(C.dim, 'known ') : (verdict === 'by-design' ? c(C.dim, '      ') : code);
        say(`   ${mark}${pad(c(C.bold, g.token), 30)} ${pad(String(g.count), 3)}x  ${c(C.dim, g.locations.join(', '))}${g.count > 4 ? ` +${g.count - 4}` : ''}`);
        if (g.reason && verdict !== 'by-design') say(c(C.dim, `         ${g.reason}`));
      }
      if (all.length > list.length) {
        say(c(C.dim, `         ... ${all.length - list.length} more, all ${verdict}. Full list: --format json`));
      }
    }
  }
  say();

  section('CONTRAST (WCAG 2.1, measured)');
  const tierCount = (suffix) => contrast.results.filter((r) => r.tier === `text${suffix}`).length;
  say(c(C.dim, `   ${tierCount('')} text runs below AA in at least one theme; `
    + `${tierCount('/branch-ambiguous')} more on classNames chosen by a ternary (not reported as findings); `
    + `${contrast.results.filter((r) => r.tier === 'text-interaction').length} hover/focus-state; `
    + `${contrast.results.filter((r) => r.tier === 'non-text').length} non-text (icons, 3:1); `
    + `${contrast.unresolved.length} unresolvable statically`));
  for (const [tier, heading] of [
    ['text', 'TEXT (1.4.3, resting state)'],
    ['text-interaction', 'TEXT (1.4.3, hover/focus state)'],
    ['non-text', 'NON-TEXT (1.4.11, icons/graphics, 3:1)'],
    ['text/branch-ambiguous', 'TEXT (1.4.3) on ternary classNames - arithmetic on branches that never render together'],
  ]) {
    const summary = summariseContrast(contrast.results, opts.maxContrast, tier);
    if (summary.groups.length === 0) continue;
    say(`   ${c(C.bold, heading)}`);
    say(c(C.dim, '     ratio  light    dark     need  size   surface        token                       where'));
    for (const g of summary.groups) {
      const l = g.themes.light;
      const d = g.themes.dark;
      const cell = (x) => (x?.active && x.pass === false ? c(C.red, `${x.ratio}`.padStart(6)) : c(C.dim, `${x?.ratio ?? 'n/a'}`.padStart(6)));
      say(`     ${cell(l)}  ${cell(d)}  ${pad(g.required, 5)} ${pad(`${g.fontSize}px${g.bold ? 'b' : ''}`, 6)} ${pad(g.surface, 13)} ${pad(c(C.bold, g.token), 28)} ${c(C.dim, `${g.locations[0]}${g.count > 1 ? ` (x${g.count})` : ''}`)}`);
    }
    if (summary.truncated) say(c(C.dim, `     ... ${summary.truncated} further distinct pairings (see --format json)`));
  }
  if (contrastSummary.groups.length === 0) say(c(C.green, '   no measured failures'));
  say();

  say(c(C.bold, 'FAILING MODE'));
  say(`   --fail-on ${opts.failOn}${opts.strict ? ' (strict)' : '  [default]'}`);
  for (const rule of RULE_IDS) {
    const on = opts.failOn.split(',').map((s) => s.trim()).includes(rule);
    say(`   ${on ? c(C.yellow, 'fail ') : c(C.dim, '     ')}on ${pad(rule, 20)} ${pad(String(byRule[rule].length), 4)} findings   ${c(C.dim, RULE_LABEL[rule])}`);
  }
  say();
  if (newFindings.length === 0) {
    say(c(C.green, `   ${allCount(byRule)} findings, all recorded in the baseline - gate is satisfied.`));
  } else if (triggered.length === 0) {
    say(c(C.yellow, `   ${newFindings.length} new finding(s), none in the failing mode.`));
    for (const f of newFindings.slice(0, 20)) say(`      ${f.id}`);
  } else {
    say(c(C.red, `   ${triggered.length} NEW finding(s) in the failing mode:`));
    for (const f of triggered) say(`      ${f.id}`);
  }
  say();

  process.stdout.write(`${out.join('\n')}\n`);
  return triggered.length > 0 ? 1 : 0;
}

function allCount(byRule) {
  return RULE_IDS.reduce((n, r) => n + byRule[r].length, 0);
}

main().then((code) => {
  process.exitCode = code;
});
