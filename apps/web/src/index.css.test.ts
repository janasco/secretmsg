import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

/**
 * The web app carries its palette twice: as semantic custom properties in
 * `src/index.css`, and as Tailwind theme values in `tailwind.config.js`.
 * Components read whichever suits them — most read the CSS variables through
 * `.glass-panel` and `body`, utility classes read the Tailwind scale.
 *
 * They have to agree. Nothing enforces that today, and when the palette was
 * last changed by hand the accent drifted between the two files: a component
 * using `accent-glow` was washed with one violet while a utility class nearby
 * was painted another. These assertions are the cheapest thing that catches it.
 */

const CSS = readFileSync(resolve(__dirname, 'index.css'), 'utf8');
const CONFIG = readFileSync(resolve(__dirname, '../tailwind.config.js'), 'utf8');

function darkVar(name: string): string {
  const darkBlock = CSS.split('.dark')[1] ?? '';
  const m = new RegExp(`^\\s*--${name}:\\s*([^;]+);`, 'm').exec(darkBlock);
  expect(m, `--${name} must exist in the dark block`).not.toBeNull();
  return m![1].trim();
}

describe('web palette', () => {
  it('keeps the Tailwind accent in step with the dark accent glow', () => {
    // The glow is the accent at low alpha, so its RGB must equal the Tailwind
    // accent's RGB. This is the pair that drifted when the palette was last
    // edited by hand.
    const glow = darkVar('accent-glow');
    const rgb = /rgba?\((\d+),\s*(\d+),\s*(\d+)/.exec(glow);
    expect(rgb, 'accent-glow must be an rgb colour').not.toBeNull();

    const configAccent = /primary:\s*'(#[0-9a-f]{6})'/i.exec(CONFIG);
    expect(configAccent, 'tailwind accent.primary must exist').not.toBeNull();
    const hex = configAccent![1].slice(1);
    const toInt = (s: string) => parseInt(s, 16);
    expect(
      [toInt(hex.slice(0, 2)), toInt(hex.slice(2, 4)), toInt(hex.slice(4, 6))],
      'tailwind accent.primary must match the RGB of --accent-glow',
    ).toEqual([Number(rgb![1]), Number(rgb![2]), Number(rgb![3])]);
  });

  it('uses a dark muted token that clears AA on the dark background', () => {
    // This is the defect the palette change was made to fix: --text-muted was
    // #94a3b8 on #090a0f, which is 4.30:1 — large text only — and the token is
    // used on body copy.
    const muted = darkVar('text-muted').replace('#', '');
    const bg = darkVar('bg-main').replace('#', '');

    const lin = (c: number) => {
      const v = c / 255;
      return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    };
    const lum = (hex: string) => {
      const r = lin(parseInt(hex.slice(0, 2), 16));
      const g = lin(parseInt(hex.slice(2, 4), 16));
      const b = lin(parseInt(hex.slice(4, 6), 16));
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    };
    const l1 = lum(muted);
    const l2 = lum(bg);
    const ratio = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);

    expect(ratio, `--text-muted ${muted} on --bg-main ${bg} is ${ratio.toFixed(2)}:1`).toBeGreaterThanOrEqual(4.5);
  });

  it('paints a single ambient wash, not two', () => {
    // Two opposing radial gradients read as a purple haze. The body should
    // carry one.
    const body = /body\s*\{([^}]*)\}/.exec(CSS);
    expect(body).not.toBeNull();
    const gradients = body![1].match(/radial-gradient/g) ?? [];
    expect(gradients.length, 'body should paint at most one radial gradient').toBeLessThanOrEqual(1);
  });

  it('keeps the Tailwind dark surface ramp tied to the CSS variables', () => {
    const ramp = /950:\s*'(#[0-9a-f]{6})',\s*900:\s*'(#[0-9a-f]{6})'/i.exec(CONFIG);
    expect(ramp, 'tailwind dark 950/900 must exist').not.toBeNull();
    expect(ramp![1].toLowerCase()).toBe(darkVar('bg-main').toLowerCase());
    // 900 is the raised-surface token; assert it is lighter than the canvas so
    // a card is always distinguishable from the page behind it.
    const canvas = ramp![1].slice(1);
    const raised = ramp![2].slice(1);
    expect(raised).not.toBe(canvas);
  });
});
