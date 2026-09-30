import { describe, expect, it } from 'vitest';
import {
  PRESETS,
  hashSeed,
  rememberRecent,
  rollPrompt,
  starterPresets,
} from './prompts';
import { stripPictographs } from './render';
import { PROMPT_MAX } from './constants';
import { STICKER_STYLES } from './design';

describe('rollPrompt', () => {
  it('is deterministic for a given seed', () => {
    const a = rollPrompt(1234);
    const b = rollPrompt(1234);
    expect(a.prompt).toBe(b.prompt);
    expect(a.seed).toBe(1234);
  });

  it('produces different prompts across seeds', () => {
    const seen = new Set<string>();
    for (let i = 0; i < 60; i++) seen.add(rollPrompt(i).prompt);
    // A combinatoric generator should not collapse to a handful of strings.
    expect(seen.size).toBeGreaterThan(15);
  });

  it('never leaves the placeholder in the output', () => {
    for (let i = 0; i < 200; i++) {
      expect(rollPrompt(i).prompt).not.toContain('%s');
    }
  });

  it('reports the subject so the avoid list can be fed back in', () => {
    // The avoid list filters subjects, not finished prompts. Returning the
    // subject is what makes that possible.
    const { subject } = rollPrompt(11);
    expect(typeof subject).toBe('string');
    expect(subject.length).toBeGreaterThan(0);
  });

  it('avoids a subject that is on the avoid list', () => {
    const first = rollPrompt(7);
    const second = rollPrompt(7, [first.subject]);
    expect(second.subject).not.toBe(first.subject);
  });

  it('respects the character budget the card can set', () => {
    for (let i = 0; i < 300; i++) {
      expect(rollPrompt(i).prompt.length).toBeLessThanOrEqual(PROMPT_MAX);
    }
  });

  it('still returns something when every subject is excluded', () => {
    // The pool is finite; exhausting it must degrade, not return nothing.
    const all = Array.from({ length: 40 }, (_, i) => rollPrompt(i).subject);
    const { prompt } = rollPrompt(99, all);
    expect(prompt.length).toBeGreaterThan(0);
    expect(prompt).not.toContain('%s');
  });
});

describe('hashSeed', () => {
  it('is stable and non-negative', () => {
    expect(hashSeed('lumen')).toBe(hashSeed('lumen'));
    expect(hashSeed('lumen')).toBeGreaterThanOrEqual(0);
  });

  it('separates different inputs', () => {
    expect(hashSeed('a')).not.toBe(hashSeed('b'));
  });
});

describe('rememberRecent', () => {
  it('moves a repeat to the end rather than duplicating it', () => {
    expect(rememberRecent(['x', 'y'], 'x')).toEqual(['y', 'x']);
  });

  it('caps the history', () => {
    let history: string[] = [];
    for (let i = 0; i < 20; i++) history = rememberRecent(history, `p${i}`, 5);
    expect(history.length).toBe(5);
    expect(history[history.length - 1]).toBe('p19');
  });
});

describe('presets', () => {
  it('are unique and within budget', () => {
    const ids = new Set(PRESETS.map((p) => p.id));
    expect(ids.size).toBe(PRESETS.length);
    for (const p of PRESETS) expect(p.prompt.length).toBeLessThanOrEqual(PROMPT_MAX);
  });

  it('starterPresets returns the requested count without repeats', () => {
    const starters = starterPresets(6);
    expect(starters.length).toBe(6);
    expect(new Set(starters.map((s) => s.id)).size).toBe(6);
  });
});

describe('stripPictographs', () => {
  it('removes emoji and tidies the leftover space', () => {
    expect(stripPictographs('send me a message 💬🔥')).toBe('send me a message');
  });

  it('leaves plain text alone', () => {
    expect(stripPictographs('send me a message')).toBe('send me a message');
  });

  it('handles input that is only emoji', () => {
    expect(stripPictographs('🔥🔥')).toBe('');
  });
});

describe('catalogue', () => {
  it('ships 32 designs', () => {
    expect(STICKER_STYLES).toHaveLength(32);
  });

  it('gives every design a unique id and typeface', () => {
    expect(new Set(STICKER_STYLES.map((s) => s.id)).size).toBe(32);
    expect(new Set(STICKER_STYLES.map((s) => s.font.family)).size).toBe(32);
  });

  it('covers every archetype and every decor at least once', () => {
    expect(new Set(STICKER_STYLES.map((s) => s.archetype)).size).toBe(8);
    expect(new Set(STICKER_STYLES.map((s) => s.decor)).size).toBe(8);
  });

  it('pairs each ink colour with a legible foreground on its accent', () => {
    // A palette whose onAccent matches its accent produces an invisible button.
    for (const s of STICKER_STYLES) {
      expect(s.palette.accent.toLowerCase()).not.toBe(s.palette.onAccent.toLowerCase());
      expect(s.palette.bg.length).toBeGreaterThan(0);
    }
  });
});
