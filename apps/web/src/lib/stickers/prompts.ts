/**
 * Sticker Studio — prompt suggestions.
 *
 * The problem this solves: someone opening the studio often does not know what
 * to write. Presets cover the common cases, and `rollPrompt` covers the rest by
 * combining frames with subjects so the result is a sentence that actually makes
 * sense on a card, rather than random words stuck together.
 *
 * Everything is pure and seeded, so a given seed always produces the same
 * prompt. That is what makes the roll testable and lets a visitor share a
 * specific card by seed.
 */

export interface Preset {
  id: string;
  label: string;
  prompt: string;
}

/** Curated openers. Deliberately phrased as something a sender would answer. */
export const PRESETS: Preset[] = [
  { id: 'tbh', label: 'Honest TBH', prompt: 'send me anonymous tbh messages' },
  { id: 'confess', label: 'Confessions', prompt: 'confess something you have never told anyone' },
  { id: 'crush', label: 'Secret crush', prompt: 'who has a secret crush on me? be honest' },
  { id: 'vibe', label: 'Vibe check', prompt: 'what vibe do I genuinely give off?' },
  { id: 'ama', label: 'Ask me anything', prompt: 'ask me anything. answers are anonymous too' },
  { id: 'hype', label: 'Free hype', prompt: 'drop honest hype about me. no cap' },
  { id: 'roast', label: 'Roast me', prompt: 'roast me. i can take it' },
  { id: 'compliment', label: 'Compliments', prompt: 'give me a compliment i will remember' },
  { id: 'firstimpression', label: 'First impression', prompt: 'what was your first impression of me?' },
  { id: 'hidden', label: 'Overheard', prompt: 'what have you overheard me say about myself?' },
  { id: 'advice', label: 'Advice wanted', prompt: 'give me advice i did not ask for' },
  { id: 'secret', label: 'Secret keeper', prompt: 'tell me a secret you have been keeping' },
];

/* -------------------------------------------------------------- the roll */

interface Frame {
  /** %s is replaced by the subject phrase. */
  text: string;
  weight: number;
}

const FRAMES: Frame[] = [
  { text: 'send me anonymous %s', weight: 5 },
  { text: 'anonymous %s wanted', weight: 4 },
  { text: 'who else has %s?', weight: 3 },
  { text: 'tell me %s. i promise anonymity', weight: 4 },
  { text: 'honestly, %s?', weight: 3 },
  { text: 'drop %s in my inbox', weight: 3 },
  { text: 'i need %s. be brutal', weight: 2 },
  { text: 'no filter: %s', weight: 2 },
  { text: 'one honest %s, please', weight: 2 },
  { text: 'what is %s that i will not admit?', weight: 2 },
];

/** Subject phrases. All are noun phrases so they slot into any frame. */
const SUBJECTS = [
  'tbh messages',
  'confessions',
  'compliments',
  'roasts',
  'honest opinions',
  'the truth about me',
  'secret crushes',
  'questions about me',
  'advice about my life',
  'things you have noticed about me',
  'first impressions',
  'vibe checks',
  'unpopular opinions about me',
  'what I am bad at',
  'what I am good at',
  'the stories behind my photos',
  'what you would change about my hair',
  'whether I seem funny',
  'things I overthink',
  'how I come across on a first date',
];

/** Small trailing flourishes, applied sparingly. */
const TAILS = ['', '', '', '', ' 💬', ' 👀', ' ⚡', ' 🤫', ' 🌟', ' 🔥'];

/** Deterministic 32-bit PRNG. mulberry32 — small, fast, good enough here. */
function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pick<T>(rng: () => number, items: T[], weights?: number[]): T {
  if (!weights) return items[Math.floor(rng() * items.length)];
  const total = weights.reduce((a, b) => a + b, 0);
  let r = rng() * total;
  for (let i = 0; i < items.length; i++) {
    r -= weights[i];
    if (r <= 0) return items[i];
  }
  return items[items.length - 1];
}

/** Stable string hash, so a seed can be a word as well as a number. */
export function hashSeed(input: string): number {
  let h = 2166136261;
  for (let i = 0; i < input.length; i++) {
    h ^= input.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

/**
 * Produce one prompt. Same seed in, same prompt out.
 *
 * `avoidRecent` holds *subjects*, not finished prompts — the two are different
 * lengths, so comparing a prompt against the subject list never matches and the
 * avoid list silently does nothing. Callers should pass the `subject` this
 * function returned last time, which `rememberRecent` is designed for.
 */
export function rollPrompt(
  seed?: number,
  avoidRecent: string[] = [],
): { prompt: string; subject: string; seed: number } {
  const s = seed ?? Math.floor(Math.random() * 0xffffffff);
  const rng = mulberry32(s);

  const pool = SUBJECTS.filter((sub) => !avoidRecent.includes(sub));
  const subject = pick(rng, pool.length ? pool : SUBJECTS);
  const frame = pick(rng, FRAMES, FRAMES.map((f) => f.weight));
  const tail = pick(rng, TAILS);

  return { prompt: frame.text.replace('%s', subject) + tail, subject, seed: s };
}

/** Keep a short memory so successive rolls do not repeat themselves. */
export function rememberRecent(history: string[], prompt: string, limit = 5): string[] {
  const next = history.filter((p) => p !== prompt);
  next.push(prompt);
  return next.slice(-limit);
}

/** Seed suggestions, so a fresh visitor sees variety rather than one card. */
export function starterPresets(count = 6, seed = 0x5ec): Preset[] {
  const rng = mulberry32(seed);
  const pool = [...PRESETS];
  const out: Preset[] = [];
  for (let i = 0; i < count && pool.length; i++) {
    const idx = Math.floor(rng() * pool.length);
    out.push(pool.splice(idx, 1)[0]);
  }
  return out;
}
