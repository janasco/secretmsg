/**
 * Blog content: structured blocks rendered by PostPage.
 * To publish: append a BlogPost (newest first) — no backend needed.
 * URLs: /blog (index), /post/:slug (article).
 */

export interface BlogSection {
  heading?: string;
  body: string[];
  quote?: string;
}

export interface BlogPost {
  slug: string;
  title: string;
  excerpt: string;
  date: string; // ISO yyyy-mm-dd
  readMinutes: number;
  tags: string[];
  sections: BlogSection[];
}

export const BLOG_POSTS: BlogPost[] = [
  {
    slug: 'welcome-to-secretmsg',
    title: 'Welcome to SecretMsg: Honest Messages, Zero Tracking',
    excerpt:
      'Why we built an anonymous messaging platform that refuses to track you — and how your first secret link works.',
    date: '2026-09-01',
    readMinutes: 4,
    tags: ['Launch', 'Privacy'],
    sections: [
      {
        body: [
          'Every social app promises connection, then monetizes your attention: trackers, ad profiles, engagement scores. SecretMsg starts from the opposite premise — a message can be meaningful precisely because nobody knows who sent it.',
          'Post your link to your story. Friends, crushes, and followers send candid TBHs, confessions, and feedback. You read them in a private inbox. No accounts for senders, no IP logs, no ad networks. Ever.',
        ],
      },
      {
        heading: 'How your first link works',
        body: [
          'Create an inbox and you get a link like secretmsg.net/alex. Share it anywhere — Instagram, Snapchat, TikTok. Anyone with the link can send you a message in seconds, with optional vibe templates when they do not know what to write.',
          'Replies are double-blind: you can answer a message without ever learning who sent it, and they can read your answer through a private link. Blocked senders simply stop delivering — silently, without drama.',
        ],
      },
      {
        heading: 'Free, open source, yours',
        body: [
          'The client is open source under MIT. The server stores messages with zero sender identifiers and purges everything the moment you delete your account. If you outgrow the defaults, supporters unlock perks like badges, hints, and custom usernames.',
        ],
        quote: 'Authentic thoughts. Positive vibes. 100% anonymous.',
      },
    ],
  },
  {
    slug: 'zero-tracking-architecture',
    title: 'What "Zero Tracking" Actually Means Here',
    excerpt:
      'A tour of what we store, what we never touch, and why anonymous can still be safe.',
    date: '2026-09-05',
    readMinutes: 6,
    tags: ['Privacy', 'Engineering'],
    sections: [
      {
        body: [
          '"We respect your privacy" is the most abused sentence in tech. So here is the concrete version: what hits our disks, what never does, and what happens when you press delete.',
        ],
      },
      {
        heading: 'What we never store',
        body: [
          'Sender IP addresses are never written to the database. Tracking cookies are never set. Device fingerprints are hashed with SHA-256 before comparison, so the raw value cannot be reversed or linked to a person. There is no ad SDK, no analytics beacon, no third-party script watching your inbox.',
        ],
      },
      {
        heading: 'What we must store (and why)',
        body: [
          'Your messages and replies — that is the product. Your handle, PIN hash, and preferences. Rate-limit counters that expire within hours. Push tokens only if you install the Android app and allow notifications. That is the complete list.',
          'Spam screening (Cloudflare Turnstile) sees a challenge token per send, exactly like any login form. It does not follow you around.',
        ],
      },
      {
        heading: 'Delete means delete',
        body: [
          'DELETE /api/account cascades messages, reports, pairing codes, purchases, donations links, rate counters, and the user row in one pass. There is no soft-delete flag, no "deactivated" purgatory, no 30-day retention window. Our privacy policy and our schema agree with each other.',
        ],
        quote: 'The most private data is the data that was never collected.',
      },
    ],
  },
  {
    slug: 'get-better-tbhs',
    title: 'How to Get TBHs Worth Reading',
    excerpt:
      'The prompt is the message: story stickers, vibe templates, and timing that triple reply quality.',
    date: '2026-09-09',
    readMinutes: 5,
    tags: ['Guide', 'Tips'],
    sections: [
      {
        body: [
          'Blank boxes get blank answers. The boards with the best inboxes all do the same three things: they ask a specific question, they make sending effortless, and they post when followers are awake.',
        ],
      },
      {
        heading: '1. Ask one specific question',
        body: [
          '"Send me something" gets you "hi". "TBH, what should I start doing?" gets you paragraphs. Use the Daily Drop mindset: one sharp prompt beats ten vague ones. The sticker studio can bake your question right into the story card.',
        ],
      },
      {
        heading: '2. Lower the effort to zero',
        body: [
          'Most senders stall on a blinking cursor. Vibe templates (hype, chill, wholesome, confessions) give them a starting sentence to react to — and every template is one tap to send. Keep your board unpaused and your filters sane so nothing bounces.',
        ],
      },
      {
        heading: '3. Post when they are scrolling',
        body: [
          'Evenings outperform mornings by a wide margin. Post your sticker between 7–10pm, leave it up for a few hours, and check your inbox before bed — then reply double-blind so senders come back tomorrow.',
        ],
        quote: 'Specific prompts get paragraphs. Vague prompts get "hi".',
      },
    ],
  },
  {
    slug: 'stay-safe-anonymous',
    title: 'Staying Safe While Staying Anonymous',
    excerpt:
      'Filters, pauses, blocks, reports, and streaks of common sense: the full safety toolkit.',
    date: '2026-09-13',
    readMinutes: 5,
    tags: ['Safety', 'Guide'],
    sections: [
      {
        body: [
          'Anonymity protects honesty — and occasionally shields people being unkind. SecretMsg is built so recipients hold every lever. Here is each control and when to reach for it.',
        ],
      },
      {
        heading: 'Word filters catch it first',
        body: [
          'Add words or phrases once and matching messages never reach your inbox — standard mode holds them in your filtered tray for review, strict mode rejects them at send time. Tune strictness per season of your life, not once forever.',
        ],
      },
      {
        heading: 'Pause is a superpower',
        body: [
          'Overwhelmed, busy, or just offline for the weekend? Pause for 30 minutes or a week, or indefinitely. Senders see a calm "taking a break" note instead of a void. Nothing is lost; delivery simply waits.',
        ],
      },
      {
        heading: 'Block fingerprints, not people',
        body: [
          'Blocking stores only a hash of the sender device — you will never know who it was, which is the point. Reports go further: our team reviews quarantined abuse, and repeat offenders lose the platform.',
        ],
        quote: 'You hold every lever: filter, pause, block, report — in that order.',
      },
    ],
  },
];

export const getPost = (slug: string): BlogPost | undefined =>
  BLOG_POSTS.find((p) => p.slug === slug.toLowerCase());

export const formatPostDate = (iso: string): string => {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });
};
