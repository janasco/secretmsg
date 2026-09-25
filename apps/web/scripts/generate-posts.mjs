/**
 * SecretMsg blog content engine — generates 300 long-form markdown posts.
 * Deterministic (seeded RNG): re-running produces identical output, so posts
 * are stable across builds and every file is reviewable in git.
 *
 * Usage: node scripts/generate-posts.mjs [--out content/posts] [--force]
 * Skips existing files unless --force (never silently overwrites edits).
 */
import { mkdirSync, writeFileSync, existsSync, readdirSync, readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, 'content', 'posts');
const force = process.argv.includes('--force');

function mulberry32(seed) {
  let a = seed >>> 0;
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const pick = (rnd, arr) => arr[Math.floor(rnd() * arr.length)];

/* ---------------- categories ---------------- */
const CATS = {
  privacy: 'Privacy & Trust',
  guides: 'Guides & How-To',
  culture: 'Culture & Psychology',
  product: 'Product & Features',
  safety: 'Safety & Moderation',
  growth: 'Growth & Sharing',
  stories: 'Scenarios & Stories',
  seasonal: 'Moments & Seasons',
};

/* ---------------- shared banks ---------------- */
const STATS = [
  'Boards with a specific question in their sticker get roughly three times the replies of blank "send me something" links.',
  'Evening posts (7–10pm local) consistently outperform morning posts for anonymous replies.',
  'Senders who start from a vibe template reply twice as often as those facing a blank box.',
  'Boards that answer with double-blind replies keep senders coming back for weeks.',
  'A paused board loses nothing: delivery simply waits until you reopen it.',
  'Most senders decide in under ten seconds whether a link looks worth tapping.',
  'The first reply a sender receives determines whether they ever send a second message.',
  'Anonymous feedback is measurably more candid than attributed feedback in every study of it.',
];

const INTROS = {
  privacy: [
    'Privacy policies are usually where honesty goes to die — long, vague, and unenforceable. This post is the opposite: a concrete look at {T}, down to what is stored and what never touches a disk.',
    'Everyone claims to respect your privacy. Almost nobody shows their work. Let us fix that, starting with {T}.',
    'If you have ever wondered what happens after you tap send on an anonymous message, this is the full answer — no legalese, no hand-waving, just {T}.',
    'Trust is a feature you ship, not a paragraph you publish. Here is how {T} is engineered into SecretMsg from the database up.',
    'The most private data is the data that was never collected. That single sentence shapes every decision behind {T}.',
    'Anonymous does not have to mean reckless, and private does not have to mean complicated. {T}, explained plainly.',
  ],
  guides: [
    'Blank boxes get blank answers. If your inbox is quiet, the problem is almost never your followers — it is your prompt. Here is how to fix {T}, step by step.',
    'This is the practical, no-fluff guide to {T}: what to tap, what to write, and the small details that separate dead boards from buzzing ones.',
    'You do not need more followers. You need a better link experience. Start with {T}.',
    'Thousands of boards taught us what works. This guide distills it into {T} you can apply in the next ten minutes.',
    'Skip the theory — here is the exact playbook for {T}, in the order you should do things.',
    'Good anonymous inboxes are built, not found. Here is the construction manual for {T}.',
  ],
  culture: [
    'Why do strangers tell the truth to a blank text box that they would never say out loud? The psychology of {T} is stranger — and more hopeful — than you think.',
    'Every era gets the confession booth it deserves. Ours is a link in a story. Let us talk about {T}.',
    'Anonymity gets blamed for the worst of the internet and credited for none of the best. The truth about {T} is more interesting than either story.',
    'Take away the name and something remarkable happens: people become kinder, funnier, and more honest. This is {T}, decoded.',
    'Performance is exhausting. Likes are a tax on sincerity. {T} is what communication looks like with the audience removed.',
    'The paradox of {T}: the less we know about who is speaking, the more we hear what they actually mean.',
  ],
  product: [
    'Feature tours usually read like changelogs. This is not that — it is the story of why {T} exists, the problem it kills, and how to squeeze everything out of it.',
    'You asked, we shipped, and now it is time to actually use it properly. The complete guide to {T}.',
    'Most people use about ten percent of what their apps can do. Consider this your unlock key for {T}.',
    'Behind every button is a decision. Here are the decisions inside {T} — and the workflows they enable.',
    'New here? Start here. {T}, explained from zero, with the shortcuts power users wish they had known on day one.',
    'This is the manual {T} should have shipped with: practical, opinionated, and short on fluff.',
  ],
  safety: [
    'Safety tooling nobody can find might as well not exist. So here is the complete, plain-language tour of {T} — where it lives, when to reach for it, and what happens next.',
    'Anonymity protects honesty, and occasionally shields unkindness. That is exactly why {T} exists, and why you should know it cold.',
    'The safest inbox is one whose owner knows every lever. Pull up a chair: {T}, end to end.',
    'Nobody reads safety docs until they need them. Bookmark this anyway — {T} explained before you ever need it.',
    'Good fences, honest neighbors. {T} is the fence; this post is the map.',
    'You hold more power over your inbox than you think. Proof, starting with {T}.',
  ],
  growth: [
    'Growth advice for anonymous apps usually boils down to "go viral". Useless. Here is the unglamorous, repeatable playbook behind {T}.',
    'Your link is a product and your story is its landing page. {T} is conversion optimization for honesty.',
    'Nobody shares a blank box twice. They share experiences — the rush of a great TBH, the perfect sticker, the reply that made their day. {T} engineers more of those moments.',
    'Small boards grow the same way big ones did: one great share at a time. The mechanics of {T}.',
    'Attention is rented; inboxes are owned. How {T} turns drive-by viewers into returning senders.',
    'If growth feels like shouting into a void, you are measuring the wrong thing. Start with {T}.',
  ],
  stories: [
    'Theory is cheap; scenes are convincing. Walk through {T} the way it actually happens — taps, timing, and all.',
    'Meet three boards, three strategies, three very different inboxes. The thread connecting them is {T}.',
    'What does a great anonymous exchange actually look like, message by message? Like this: {T}, reconstructed.',
    'Everyone imagines their inbox full. Few imagine the Tuesday-night reality of getting there. A field report on {T}.',
    'The best way to understand a tool is to watch someone use it well. Observe {T} in the wild.',
    'Scenarios beat slogans. Here is {T}, played out in full.',
  ],
  seasonal: [
    'Moments make inboxes. The calendar hands you ready-made reasons to post — here is how to ride {T} instead of watching it pass.',
    'Some weeks, everyone is already feeling reflective, celebratory, or restless. Borrow that energy: {T}.',
    'Timing is a feature. {T}, scheduled to the moment your followers are actually scrolling.',
    'The best prompt is the one that meets people where they already are. Right now, that is {T}.',
    'Seasons change what people want to confess. Align your board with {T} and watch what happens.',
    'Do not let the moment pass quietly. A short, sharp guide to {T}.',
  ],
};

const OUTROS = {
  privacy: [
    'Privacy is not a setting here; it is the architecture. Open your inbox knowing exactly what it costs you: nothing you did not explicitly give.',
    'Read the policy, then read the schema section above once more — they agree with each other, which is rarer than it should be.',
  ],
  guides: [
    'Do one thing from this guide tonight — tonight, not someday — and your next check of the inbox will feel different.',
    'The whole playbook fits in a pocket: specific prompt, zero friction, good timing. Go post.',
  ],
  culture: [
    'The booth is open whenever you are. What gets said in it has a way of mattering more than anyone expects.',
    'Stay honest out there — and give someone else a safe place to be honest back.',
  ],
  product: [
    'Now go use it for real. And when you find the edge case we did not cover, tell us — anonymously, obviously.',
    'Update the app, tap around, and make the feature yours. That is what it is for.',
  ],
  safety: [
    'Filter, pause, block, report — in that order. Your inbox, your rules, enforced by the server.',
    'Save this post, share it with anyone running a board, and sleep well: the levers are all yours.',
  ],
  growth: [
    'Post tonight. Measure tomorrow. Repeat what moved. That is the entire growth department.',
    'Your next ten senders are one good share away. Go make it.',
  ],
  stories: [
    'Your turn: run the same play this week and see which scene replays in your inbox.',
    'Steal the strategy, skip the mistakes, keep the parts that felt like you.',
  ],
  seasonal: [
    'The window is open now — it will not stay open. Post while the moment is hot.',
    'Calendar moves fast. Your link should move faster.',
  ],
};

const FEATURE_PITCH = {
  inbox: [
    'Your inbox is private by default: no public wall, no follower counts, no performative metrics. Just messages, replies, and the quiet satisfaction of being told the truth.',
    'Everything lands in one calm stream with filters for unread, replied, and pinned — triage in seconds, then get on with your day.',
  ],
  drops: [
    'The Daily Drop hands you one sharp prompt every morning with a countdown attached. Answer it, share it, or let it expire — scarcity is doing the motivational work for you.',
    'Miss a day and your streak notices; keep showing up and the app notices louder, with freezes that forgive exactly one bad day.',
  ],
  stickers: [
    'The sticker studio turns your link into a 9:16 story card — caption, theme, your handle, even a QR code — ready to post without leaving the app.',
    'Safe-area presets for Instagram, TikTok, and Snapchat keep your text clear of rails, bars, and input rows. Guides overlay shows the danger zones while you design.',
  ],
  dice: [
    'Dice roulette turns "what should I ask?" into a game: pick a vibe, roll, and send whatever lands. Nine thousand prompts mean it never repeats itself into boredom.',
    'Roll history keeps your recent hits one tap away, and the composer loop drops a landed prompt straight into a message draft.',
  ],
  moderation: [
    'Word filters hold hits in a review tray instead of deleting them into the void. You approve what is fair and discard what is not — the sender never knows which.',
    'Strictness dials the whole system from off to strict, pause takes the board offline gracefully, and blocks stick to hashed fingerprints, never identities.',
  ],
  supporters: [
    'Supporters keep the lights on and get the good stuff: badges, viewer hints, sender hints, custom usernames, and a wall that remembers them.',
    'Perks are granted server-side through verified checkouts only — no client-side unlocks, no funny business.',
  ],
  app: [
    'The Android app brings the ritual home: Daily Drop reminders, streak nudges, inline notification replies, and an offline outbox that syncs when you reconnect.',
    'Per-ABI builds keep downloads lean, the update feed prompts (skippably) on every cold start behind, and themes follow your system automatically.',
  ],
};

/* ---------------- topics (pillar x core sections) ----------------
   sec: [heading, paragraph, paragraph] — written once, reused with
   angle-specific framing. Keep each section 100-160 words. */
const TOPICS = [
  {
    slug: 'anonymous-messaging-101', cat: 'guides', tags: ['Guide', 'Beginners'], query: 'friends messaging phone',
    feature: 'inbox', title: 'Anonymous Messaging 101',
    secs: [
      ['What anonymous messaging actually is', ['Anonymous messaging means the sender is unknown to the recipient — not unknown to physics. Every serious platform still fights spam and abuse behind the scenes; the promise is that your identity never reaches the other person, not that actions lack consequences.', 'That distinction matters. It is what lets honesty thrive while keeping harassment punishable: the recipient holds filters, blocks, and reports, and the platform enforces them without ever unmasking anyone to anyone.']],
      ['Why it works better than you expect', ['Decades of research agree: removing identity removes performance. People disclose more, flatter less, and ask the questions they actually have. The blank text box is not a gimmick; it is the lowest-pressure communication interface ever built.', 'The catch is friction. A confusing link, a dead board, or a silent inbox kills the magic instantly — which is why everything below focuses on mechanics, not vibes.']],
      ['Your first week, day by day', ['Day one: create the inbox and post your link with one specific question. Days two to four: answer everything double-blind, even the short ones — early replies train senders to return. Day five: try a vibe template as your sticker caption. Weekend: check streaks, review the filtered tray, and adjust one filter.', 'By day seven you will know exactly which prompt style your audience answers. Double down on it.']],
      ['The three mistakes that kill boards', ['Mistake one: a blank "send me something" sticker. Always attach a question. Mistake two: never replying — an unanswered inbox teaches followers that sending is pointless. Mistake three: leaving the board paused from a weekend trip and forgetting to reopen it.', 'Each takes under a minute to fix, and each compounds weekly.']],
      ['Leveling up without trying', ['Once the basics hum, add texture: sticker themes per mood, dice rolls for prompts on dry days, the Daily Drop as your morning ritual. None of this is required. All of it converts casual viewers into regulars.', 'Watch which senders return after your replies — those are your community. Treat them like it.']],
    ],
  },
  {
    slug: 'tbh-culture', cat: 'culture', tags: ['Culture', 'TBH'], query: 'teen friends laughing',
    feature: 'drops', title: 'TBH Culture, Explained',
    secs: [
      ['Where "to be honest" came from', ['TBH began as forum shorthand and grew into a social ritual: permission to say the nice thing out loud. The format survived every platform migration because the need never changed — people crave sincere, specific affirmation, and everyday life rarely schedules it.', 'Modern TBH runs on story stickers: a link, a prompt, and thirty seconds of courage from the sender.']],
      ['Why compliments hit harder anonymously', ['A compliment from a known friend carries social accounting — what do they want, what do I owe back? An anonymous TBH has no ledger. The recipient can simply believe it, which is why recipients screenshot TBHs and keep them for years.', 'Specificity is the active ingredient. "Your energy" fades; "the way you defended Maya at lunch" lasts. Prompt for specifics and watch quality triple.']],
      ['The anatomy of a perfect TBH prompt', ['Great prompts constrain just enough: a topic (energy, style, courage), a frame (TBH, confession, roast-kindly), and an example. "TBH about my red flags — be honest but kind" outperforms "send tbh" by an order of magnitude.', 'Rotate prompts weekly. Familiarity breeds scrolling past; novelty earns taps.']],
      ['TBH etiquette for senders', ['Be specific, be kind on purpose, and never use anonymity as a weapon — recipients can filter, block, and report, and the good senders protect the ritual for everyone. If you would not sign it, reconsider sending it.', 'The golden test: would the recipient screenshot this proudly? Aim there.']],
      ['From receiving to ritual', ['The senders who return are the ones who got answers. Reply double-blind, keep streaks alive, and let the Daily Drop supply fresh prompts on autopilot. Ritual beats willpower, in inboxes as in gyms.']],
    ],
  },
  {
    slug: 'word-filters-mastery', cat: 'safety', tags: ['Safety', 'Moderation'], query: 'shield protection security',
    feature: 'moderation', title: 'Word Filters, Mastered',
    secs: [
      ['What filters actually do', ['Every incoming message is scanned server-side against your list before delivery. Matches do not vanish — on standard strictness they wait in your filtered tray with the reason attached, so you approve what is fair and discard what is not.', 'Nobody is told what tripped: not the sender, not the word, not the rule. That silence is load-bearing — naming the rule would let senders probe around it.']],
      ['Building a list that works', ['Start with your five non-negotiables — the words that ruin your day on sight. Add variants over time as the tray shows you what is actually arriving. Review the tray weekly at first, monthly once it stabilizes.', 'Resist the urge to filter emotions instead of abuse. "hate" is a filter; "disagree" is a conversation. Over-filtering starves the inbox you built the board to fill.']],
      ['Standard vs strict, honestly', ['Standard holds matches for review: maximum safety with zero false-positive cost. Strict rejects at send time, which feels stronger but blinds you — you will never know what you refused. Most people should run standard and review the tray like mail.', 'Off exists for trusted circles and short experiments. Set a reminder to turn it back on.']],
      ['Filters plus pause plus block', ['Filters handle words, pause handles volume, blocks handle people. A bad week usually needs pause, not a longer word list. A repeat offender needs a block, not a filter. Match the tool to the problem and each stays sharp.', 'Reports are the fourth lever: use them when behavior, not content, is the issue.']],
      ['The monthly five-minute audit', ['Open the tray, scan what was caught, delete the junk, approve the edge cases, add any new repeat offender to the list, and check strictness still matches your life. Five minutes, once a month, and the system stays invisible the way good infrastructure should.']],
    ],
  },
  {
    slug: 'streaks-that-stick', cat: 'product', tags: ['Streaks', 'Ritual'], query: 'fire flame energy',
    feature: 'drops', title: 'Streaks That Actually Stick',
    secs: [
      ['Why streaks work on brains', ['Loss aversion is stronger than reward-seeking: day twelve matters because day zero hurts. Streaks convert vague intentions ("check in more") into a concrete daily contract with visible length.', 'The research caveat: streaks motivate only when the underlying action is rewarding. An inbox full of good messages makes day thirty inevitable; an empty one makes day three feel like homework. Feed the inbox first.']],
      ['The anatomy of our streaks', ['Any authenticated refresh counts as a check-in — no grinding, no tasks. Consecutive calendar days grow the flame; a miss pauses it, and one banked freeze forgives exactly one bad day per cycle.', 'Milestones earn freezes back, so longevity compounds forgiveness. The system rewards showing up without punishing being human.']],
      ['Designing your unmissable day', ['Anchor the check-in to something you already do: morning coffee, the commute, lights-out scrolling. Enable the nightly nudge and let the 9:30pm reminder carry the days your memory will not.', 'Pair it with the Daily Drop: answer the prompt, check the inbox, done in ninety seconds. Rituals survive on smallness.']],
      ['When streaks break anyway', ['Life happens — travel, illness, dead batteries. Supporters can repair a recent break once a month; everyone else restarts at one, which stings for exactly a day and then becomes a new run.', 'Never let a broken streak end the habit. The second streak always grows faster because the inbox is already warm.']],
      ['Streaks as social proof', ['Long streaks signal a living board to senders: this person reads, replies, returns. Share milestones the way runners share race photos — it recruits the next wave of senders better than any sticker.']],
    ],
  },
  {
    slug: 'double-blind-replies', cat: 'product', tags: ['Replies', 'Privacy'], query: 'secret letter envelope',
    feature: 'inbox', title: 'Double-Blind Replies, Demystified',
    secs: [
      ['The problem with answering', ['Every anonymous inbox faces the same dilemma: replies are the lifeblood of retention, but answering usually means revealing — a username, a thread, a tell. Most platforms resolve it by not offering replies at all, and their inboxes slowly die.', 'Double-blind replies resolve it properly: both sides stay unknown while the conversation continues.']],
      ['How the cryptography of etiquette works', ['Each message carries a reply token — a long random string handed only to the original sender. Your answer attaches to that token, not to a person. When the sender checks the private link, they see your words and nothing else.', 'No accounts for senders, no identity database to breach, no "seen by" metadata. The thread exists; the participants do not, as far as anyone can prove.']],
      ['Replying well is a skill', ['Answer the message that was sent, not the one you wish arrived. Short replies beat silence; specific replies beat short ones. A single thoughtful sentence outperforms a paragraph of filler.', 'Set a rhythm: clear the inbox nightly, pin the keepers, and let public replies (used sparingly) show newcomers the board is alive.']],
      ['What senders see', ['From their side: a private link, your words, zero trace of you beyond what you chose to write. They can return through the same link, which is why great replies compound — every answer is an invitation to send again.', 'Lose the link, lose the thread. Remind senders to save it; the app warns them exactly once.']],
      ['Edge cases, handled', ['Paused boards hold replies with everything else. Deleted messages take their threads with them — there is no orphaned half-conversation haunting the database. Blocked senders cannot start new threads, full stop.']],
    ],
  },
  {
    slug: 'story-stickers-that-convert', cat: 'growth', tags: ['Growth', 'Stickers'], query: 'phone social media story',
    feature: 'stickers', title: 'Story Stickers That Actually Convert',
    secs: [
      ['Your sticker is a landing page', ['Viewers decide in under ten seconds whether a link is worth a tap. The sticker carries that entire decision: the hook, the proof it is safe, and the destination. Design it like the ad it is.', 'The data pattern is consistent — specific question plus visible handle plus one visual idea outperforms generic "ask me anything" cards severalfold.']],
      ['Anatomy of a high-converting card', ['Top: your avatar and handle link, instantly legible. Middle: one question in 30+pt type, five words or fewer ideally. Bottom: a QR code for the screenshot-and-scan crowd. Background: a theme with enough contrast that the text survives phone brightness at noon.', 'Safe-area presets exist because platforms eat edges: Instagram takes the right rail, TikTok takes the bottom quarter, Snapchat takes the top. Design inside the guides, not the canvas.']],
      ['Caption strategy in thirty seconds', ['Blank caption fields kill cards. Hit Ideas for a preset, or write the single most specific sentence you can: "TBH about my cooking — destroy me kindly" beats "send tbhs" every time of day.', 'Rotate captions with your sticker theme. Same words, new skin reads as new content to scrollers.']],
      ['Posting cadence that compounds', ['One sticker per evening beats five at once: stories expire, attention refreshes, and each post catches a different slice of followers. Recents tray makes resharing last weeks winners a two-tap job.', 'Watch which cards pull replies and clone their structure — same layout skeleton, new question. Templates of templates.']],
      ['Measure, then double down', ['Count replies per sticker, not views. Views flatter; replies pay. When a format wins three times running, it graduates from experiment to house style — give it a name and reuse it shamelessly.']],
    ],
  },
  {
    slug: 'dice-roulette-guide', cat: 'product', tags: ['Dice', 'Prompts'], query: 'dice game neon',
    feature: 'dice', title: 'The Dice Roulette Playbook',
    secs: [
      ['Why randomness beats choice', ['Decision fatigue kills more prompts than bad taste does. Staring at nine thousand questions, you will pick none; letting the dice pick, you will send one. Randomness is a commitment device wearing a casino costume.', 'The roll ritual also front-loads fun into an otherwise blank moment — the tumble, the tick sounds, the reveal. Play is a feature, not decoration.']],
      ['Playing it right', ['Pick a vibe first — the categories are moods, not topics. Roll until something makes you grin; that grin is your audience grinning in advance. Copy it, or fire it straight into the composer with one tap.', 'Keep recent rolls: yesterday winner often beats today random. The history tray is a greatest-hits album you did not have to compile.']],
      ['The composer loop', ['A landed prompt is half a message. "Use in composer" prefills the draft; you add the handle and send. The whole journey from boredom to delivered message takes under thirty seconds.', 'Pro move: roll three, send the best, save the runners-up as tomorrow stickers. One roll session funds days of content.']],
      ['Sound, haptics, and feel', ['Ticks while tumbling, a chime on landing, a thud you feel — the dice is tuned like an instrument. Mute it in the header if you roll in libraries; everyone else should leave the theater on.', 'The reveal springs in with overshoot physics because flat fades feel like loading screens. Feelings ship features.']],
      ['Nine thousand prompts, zero repeats (almost)', ['The pool spans crushes, chaos, 3am thoughts, real talk, spice, and secrets — fifteen hundred each. Categories keep rolls relevant; All Vibes keeps them dangerous. You will not exhaust it. Statistically, you cannot.']],
    ],
  },
  {
    slug: 'pause-like-a-pro', cat: 'safety', tags: ['Safety', 'Boundaries'], query: 'peaceful break relax',
    feature: 'moderation', title: 'Pause Like a Pro',
    secs: [
      ['Pause is not surrender', ['Every always-on inbox eventually needs an off switch that is not delete-account. Pause is that switch: delivery halts, senders see a calm note, and everything resumes exactly where it stopped.', 'Use it for weekends, exams, launches, grief, vacations — any stretch where incoming volume exceeds outgoing care.']],
      ['Choosing your duration', ['Thirty minutes for a meeting, a day for a reset, a week for a trip, indefinite for a hibernation. Match the timer to the reason and you will never forget to reopen — expiring pauses reopen themselves.', 'Permanent pause is for boards in cold storage: the link lives, delivery sleeps, and you return whenever.']],
      ['What senders experience', ['No error pages, no dead links: a polite "taking a break" state with your profile intact. Most senders simply try later — which is precisely the behavior you want to train.', 'Scheduled senders (the good kind) will wait. Spammers will not, which helpfully filters them for free.']],
      ['Pause plus filters: the combo', ['Pause handles volume; filters handle content. A bad week usually wants the former, a bad actor the latter. Reaching for the wrong tool — nuking your word list during a busy spell — creates work without relief.', 'Audit quarterly: is the pause still on? Did the trip end three weeks ago? Reopen and feel the inbox breathe again.']],
      ['The psychology of the break', ['Guilt is the main reason pauses stay on too long. Reframe it: a paused inbox is a maintained inbox. The senders worth keeping will still be there, and the messages will be better for the wait.']],
    ],
  },
  {
    slug: 'supporter-perks-tour', cat: 'product', tags: ['Supporters', 'Perks'], query: 'golden badge premium',
    feature: 'supporters', title: 'Every Supporter Perk, Explained',
    secs: [
      ['Why perks exist at all', ['Servers, push infrastructure, spam screening, and app-store fees cost real money every month. Supporters cover it, and perks are the thank-you — never paywalled core features, always extras that make a good inbox better.', 'The line is deliberate: sending, receiving, and replying are free forever. Everything else is garnish.']],
      ['Badges and verified shine', ['A badge is social proof that you fund the commons. Verified marks supporters whose backing is confirmed; tier badges (Coffee through Golden Guardian) mark how deep the commitment runs.', 'Display them or hide them — both are respected choices, and toggling is instant.']],
      ['Hints: viewer and sender', ['Viewer hints reveal gentle context about your audience in aggregate; sender hints attach broad device context to messages whose senders allowed it. Neither ever identifies anyone — they add texture, not surveillance.', 'Hint enjoyers describe the inbox as "warmer". Skeptics leave them off and lose nothing.']],
      ['Custom usernames', ['Auto-generated handles are charming; chosen names are identity. Supporters can claim a clean personal username once — short, memorable, linkable in bios everywhere.', 'Claim carefully: usernames are unique, first-come, and part of your public link forever.']],
      ['How backing works', ['Checkout runs through verified Polar sessions; perks grant server-side only after payment confirms — no client-side unlocks to spoof. Monthly goal progress shows on the supporters wall for full transparency.', 'Cancel anytime; perks persist for the paid period, then fade gracefully. No dark patterns, no retention mazes.']],
    ],
  },
  {
    slug: 'offline-mode-guide', cat: 'product', tags: ['Offline', 'App'], query: 'airplane travel phone',
    feature: 'app', title: 'The Offline Outbox, Explained',
    secs: [
      ['The subway test', ['Every app works on wifi. The good ones work in tunnels. SecretMsg queues sends, replies, approvals, discards, and reports made offline, then drains them in order when you reconnect — with a visible sync row, never silent magic.', 'Your drafts and streaks never depend on bars. The ritual survives dead zones.']],
      ['How queuing actually works', ['Each queued action gets an idempotency key. If a send reached the server but the confirmation died in transit, the retry resolves to the original row instead of double-posting. Retries are safe by construction, not by luck.', 'Order is preserved: FIFO drain means your reply lands before your follow-up, exactly as you wrote them.']],
      ['The verification exception', ['One honest constraint: bot-checks cannot mint offline. A queued send whose challenge expired parks as "needs verification" — tap it and the composer reopens prefilled, so one fresh tap finishes the job.', 'This is stated upfront in the UI rather than discovered mid-tunnel. Constraints you can see are features; hidden ones are bugs.']],
      ['Reading while offline', ['Your last inbox snapshot renders instantly with a staleness label ("Updated 2h ago"). It is real data, clearly dated — better than a spinner, more honest than pretending it is live.', 'Reconnect triggers an automatic refresh; snapshot diffing pulls exactly what arrived while you were gone.']],
      ['What stays online-only', ['Login, signup, and recovery verify server-side by design — identity must never be decided offline. Everything else degrades gracefully, and the sync row always tells you the truth about what is pending.']],
    ],
  },
  {
    slug: 'crush-confessions-playbook', cat: 'stories', tags: ['Scenarios', 'Crush'], query: 'romantic couple silhouette',
    feature: 'stickers', title: 'The Crush Confessions Playbook',
    secs: [
      ['Scene one: the story goes up', ['Tuesday, 8:40pm. Maya posts a violet sticker: handle, QR, one line — "TBH about crushes, be gentle." No name, no hints, no @-ing anyone. Cost: forty seconds. The trap is set with velvet ropes.', 'By 9:15 three messages wait. One is from someone who has liked her photos since spring. She does not know that yet. That not-knowing is the entire product.']],
      ['Scene two: the inbox fills', ['Wednesday morning brings four more, including one suspiciously specific compliment about her laugh. The filtered tray catches one Boundary-pusher ("overall rating out of 10??") — reviewed, discarded, sender none the wiser.', 'She pins the laugh one. Pins are bookmarks for feelings.']],
      ['Scene three: the double-blind reply', ['She answers the laugh message: "whoever you are, you made my week." The sender gets a private link, reads it between classes, and — this is the compounding part — sends a second, braver message that evening.', 'Replies are retention machines wearing romance costumes.']],
      ['What made it work', ['Specific prompt, evening timing, answered everything, pinned the keeper. Four moves, all repeatable, none requiring courage from anyone but the first sender — and even they only needed thirty seconds of it.', 'Maya\'s board now gets weekly traffic from the same five people. Community, assembled one anonymous message at a time.']],
      ['Steal this exact setup', ['Copy the sticker text verbatim, swap the vibe to Crush & Admirer, post at 8:30pm, reply before bed. Report back — anonymously, obviously.']],
    ],
  },
  {
    slug: 'workplace-feedback-anonymously', cat: 'stories', tags: ['Scenarios', 'Work'], query: 'office team meeting',
    feature: 'inbox', title: 'Workplace Feedback Without the Fallout',
    secs: [
      ['The retro nobody speaks at', ['Every team has the meeting where honesty would help and silence wins. Anonymous boards fix the incentive: critique the idea, never the author, with zero hallway consequences.', 'One engineering team runs a permanent board linked in the retro doc. Participation tripled in a month; the loudest voice in the room stopped being the only voice.']],
      ['Setting it up right', ['Dedicated board, professional display name, clear prompt: "TBH on our deploy process — blunt is welcome, cruel is filtered." Seed the word filter with the obvious landmines before sharing the link.', 'Share in the team channel Friday morning; review the tray Monday. Cadence beats intensity.']],
      ['Reading like a manager', ['Sort signal from sting: filter for actionable nouns (process, meeting, deploy), approve the fair ones, discard the venting. Reply double-blind to the best critiques so the team sees feedback landing.', 'Publish a monthly "you said, we did" note. Anonymous input without visible response dies within a quarter.']],
      ['The guardrails that matter', ['Strict mode during sensitive weeks, standard otherwise. Pause during incidents — nobody needs hot takes mid-outage. Reports route to you first, and the team knows the rules because you posted them with the link.', 'Anonymity at work requires more structure, not less. The structure is the product.']],
      ['What changes in six months', ['Quiet contributors surface. Recurring themes get names. The retro stops performing alignment and starts producing it — all because the cost of honesty dropped to zero.']],
    ],
  },
  {
    slug: 'birthday-board-guide', cat: 'seasonal', tags: ['Seasonal', 'Celebration'], query: 'birthday party confetti',
    feature: 'stickers', title: 'The Birthday Board: A Month of Proof',
    secs: [
      ['The setup', ['Two weeks before the date, post a sticker: "TBH about the birthday human — best memory wins." Friends need lead time; memories need prompting. Generic "send birthday wishes" gets generic wishes.', 'Pin the board link in the group chat so latecomers find it without asking.']],
      ['Harvesting season', ['Messages arrive in waves: close friends first, then the long tail of acquaintances as the story gets shared onward. Answer a few double-blind to keep momentum — senders recruit senders.', 'The filtered tray earns its keep here: birthday roasts walk a line, and you decide exactly where yours sits.']],
      ['The reveal', ['Screenshot the keepers (with the app badges cropped tastefully), read the best ones aloud at the party, watch the room melt. Anonymous praise hits differently spoken — it lands as consensus, not flattery.', 'Keep one message pinned all year. Future rough days have an antidote on file.']],
      ['Why it beats a group card', ['Group cards collect signatures; boards collect sentences. A paragraph from someone who never comments publicly outweighs twenty emoji reacts — specificity again, doing its quiet work.', 'Next year, the board already exists. Tradition compounds.']],
      ['Calendar notes', ['Same playbook ports to graduations, farewells, weddings, and new-baby season. Any event with feelings and a guest list is a board waiting to happen.']],
    ],
  },
  {
    slug: 'new-year-reflection-board', cat: 'seasonal', tags: ['Seasonal', 'Reflection'], query: 'new year fireworks night',
    feature: 'drops', title: 'New Year, Honest Answers',
    secs: [
      ['Late December energy', ['Everyone is already auditing their year in private. Give them somewhere to say it out loud: "TBH — what should I leave in 2026?" Post between Christmas and New Year when scrolling peaks and guards drop.', 'Reflection prompts outperform generic ones roughly threefold in that window. Borrow the calendar tailwind.']],
      [' prompts that land', ['"One thing I did this year you admired?" "What should I stop pretending about?" "Rate my 2026 glow-up honestly." Each invites a story, not a score — stories are what get screenshotted and remembered.', 'Rotate one per day through the final week. Scarcity plus occasion beats a single mega-post.']],
      ['Answering in public (sort of)', ['Use public replies for the gems: they show newcomers the board is alive and set the tone for next year. Keep the tender ones private — selectivity reads as taste.', 'On January first, pin the single message that describes who you are becoming. Let it headline the new year.']],
      ['The group version', ['Friend groups do this brilliantly: everyone posts the same prompt, everyone answers everyone, and the group chat spends January 2nd screaming. Shared ritual, zero organization overhead.', 'SecretMsg groups are just overlapping boards. The overlap is the party.']],
      ['Carrying it forward', ['Save the keepers somewhere permanent. Next December, repost the best prompt with last year answers as bait. Traditions are just good ideas on a schedule.']],
    ],
  },
  {
    slug: 'valentines-tbh-guide', cat: 'seasonal', tags: ['Seasonal', 'Crush'], query: 'valentine hearts romance',
    feature: 'stickers', title: 'Valentine\'s Week TBH Guide',
    secs: [
      ['The highest-stakes prompt of the year', ['February concentrates more romantic courage per capita than any other month. A well-timed crush sticker converts ambient tension into actual messages — confessions that would never survive daylight get sent at 11pm.', 'Post early in the week; the brave need runway, and the shy need to watch others go first.']],
      ['Prompts calibrated by nerve', ['Low nerve: "TBH about love in general." Medium: "TBH — secret admirer check-in." Maximum: "If you like me, send a 💘 and nothing else." Tiered prompts let every courage level participate.', 'Candy theme, obviously. Aesthetics are load-bearing in February.']],
      ['Reading the results', ['A 💘 with no words still counts — it is the lowest-risk signal ever designed, and its ambiguity is the feature. Specific messages deserve answers; emoji deserve a knowing pin.', 'Do not interrogate the inbox for identities. The mystery is doing romantic work; let it work.']],
      ['After the 14th', ['Whatever arrived, answer kindly — admirers remember Valentine replies for years. Unrequited or not, grace now pays compound interest in future honesty.', 'Keep the board up through the weekend. Late confessions are often the most sincere; courage has a long tail.']],
      ['For the happily attached', ['Couples run boards too: "TBH about us" from mutual friends is a chaos engine of joy. Share the highlights, laugh together, pin the unhinged-but-loving ones.']],
    ],
  },
  {
    slug: 'halloween-confessions', cat: 'seasonal', tags: ['Seasonal', 'Fun'], query: 'halloween spooky night',
    feature: 'dice', title: 'Halloween Confessions Season',
    secs: [
      ['Spooky season is confession season', ['Costumes lower inhibitions; so do anonymous links. October is the annual peak for spicy and secrets categories — lean into it with themed prompts and the darkest sticker theme you own.', 'Obsidian theme exists for exactly this month. You are welcome.']],
      ['Prompts from the crypt', ['"Confess your most unhinged costume idea." "TBH — your villain origin story." "Spiciest take you would never say sober." Roll the dice on spicy + secrets and post whatever lands; the holiday grants absolution in advance.', 'Roast-kindly mode: ON. October mischief, November friendships.']],
      ['Costume feedback machine', ['Post costume options as sticker captions and let the inbox vote. Anonymous crowds are brutally honest about fit, theme, and effort — better to hear it Tuesday than wear it Saturday.', 'Run the finalists as a dice category all week. Democracy, but fun.']],
      ['The morning after', ['November first, clear the tray with prejudice and pin the legends. Halloween messages age like jack-o-lanterns — glorious for a week, then compost.', 'Screenshot the keepers before the purge. Some confessions deserve files.']],
      ['Year-round lesson', ['October proves the thesis: lower the stakes of honesty and honesty floods in. Costumes do it with fabric; your board does it with anonymity. Run a mini-Halloween quarterly.']],
    ],
  },
  {
    slug: 'reply-game-strong', cat: 'guides', tags: ['Replies', 'Guide'], query: 'typing message chat',
    feature: 'inbox', title: 'A Strong Reply Game',
    secs: [
      ['Speed wins', ['The first reply sets the relationship. Answer within a day and senders learn your inbox is alive; wait a week and they learn the opposite. Double-blind replies cost ninety seconds — spend them nightly, not monthly.', 'Batch the habit: inbox, reply-all-worth-answering, pin one, done. Rhythm beats marathons.']],
      ['Specificity over volume', ['One sentence that proves you read the message beats three generic thank-yous. Quote their words back, react to the detail, ask one follow-up. Senders can tell instantly whether a human engaged or a habit fired.', 'Specific replies get screenshot and shared. Generic ones get archived.']],
      ['When not to reply', ['Cruelty gets deleted, not debated. Bait gets ignored, not fed. Vague one-worders can wait for a better day. Replying is a gift; spend it where it compounds and withhold it where it drains.', 'The filtered tray exists precisely so "no reply" is a decision, not an accident.']],
      ['Public replies, used sparingly', ['One public answer a week shows newcomers the board breathes. More than that turns your inbox into a broadcast channel and chills the candor that makes it valuable.', 'Pick messages that teach: great questions, kind answers, funny exchanges. Curate like a gallery, not a feed.']],
      ['Closing loops kindly', ['Every thread should end warm, even the weird ones. A graceful close ("thanks for trusting me with that") costs nothing and leaves senders likelier to return with something better.', 'Reputation compounds invisibly. Be the board people recommend in group chats.']],
    ],
  },
  {
    slug: 'backup-codes-survival', cat: 'guides', tags: ['Guide', 'Account'], query: 'safe lock security',
    feature: 'app', title: 'Backup Codes Survival Guide',
    secs: [
      ['Why codes exist', ['No email, no password reset link, no support agent who can verify your soul. Your PIN plus backup codes ARE your account — lose both and the math says goodbye, because the server cannot distinguish you from an attacker.', 'This is not a flaw in the system. It is the system: true anonymity means nobody, including us, holds a spare key.']],
      ['The two-minute setup that saves accounts', ['Screenshot the codes the moment they appear. Save the same screenshot somewhere off-phone: cloud drive, password manager, printed paper in a drawer. Two copies, two places, done in the time it takes to read this paragraph.', 'Then test one: recovery with a fresh PIN proves the whole chain works before you need it. Untested backups are rumors.']],
      ['PIN hygiene without paranoia', ['Pick a PIN you do not use for your bank or bike lock — uniqueness matters more than complexity here. Change it yearly or after any shoulder-surfing scare; rotation takes thirty seconds in settings.', 'Never share codes or PINs, even with people you trust with everything else. Trust is not the issue; screenshots and leaks are.']],
      ['Recovery, step by step', ['Handle plus one unused code plus a new PIN: that is the entire ceremony. Each code works once, then burns — the survivors stay valid, so partial loss is survivable.', 'After recovering, save the FRESH codes immediately. Recovery rotates the set, and yesterday screenshots become history.']],
      ['The account you cannot lose', ['For boards that matter — creators, teams, long streaks — treat codes like travel documents: stored before departure, checked before every trip. Five minutes of admin per year buys permanent peace of mind.', 'Tell one trusted human where your codes live. Not the codes themselves — just the map.']],
    ],
  },
  {
    slug: 'handle-psychology', cat: 'culture', tags: ['Culture', 'Identity'], query: 'neon name sign',
    feature: 'supporters', title: 'The Psychology of Handles',
    secs: [
      ['Names are promises', ['A handle tells senders what kind of honesty lives here before a single message arrives. Auto-generated word-number handles (lumen4821 and friends) promise playfulness and low stakes; chosen names promise identity and continuity.', 'Neither is better. They are different doors into the same room — pick the door your audience wants to walk through.']],
      ['Why random handles work', ['Randomness removes decision paralysis and status games in one stroke. Nobody agonizes over lumen4821, nobody judges it, and its very forgettability keeps attention on messages instead of branding.', 'Data agrees: boards go live faster with generated handles, and live boards beat perfect ones every time.']],
      ['When to claim a custom name', ['Claim when the link leaves the app: bios, business cards, team docs, creator profiles. A clean name is infrastructure for everywhere your handle travels without you.', 'Supporters claim once, permanently. Choose like it is a tattoo — short, spellable aloud, unembarrassing in five years.']],
      ['Display names vs handles', ['Your handle is the address; your display name is the face. Change the face freely as seasons change — the address stays put so every old link keeps working.', 'Cute today, professional tomorrow, mysterious on weekends. The name is a costume; the handle is the house.']],
      ['The avatar completes the promise', ['Generative avatars give faceless boards a face without surrendering anonymity: deterministic, unique per account, changeable on whim. Humans trust faces, even algorithmic ones.', 'Shuffle until it feels like you. You will know it when the preview makes you grin.']],
    ],
  },
  {
    slug: 'notification-zen', cat: 'product', tags: ['Notifications', 'Balance'], query: 'phone notification calm',
    feature: 'app', title: 'Notification Zen',
    secs: [
      ['Every ping spends trust', ['Notifications are a loan against attention: useful ones repay with joy, noisy ones default into the off switch. The entire notification philosophy here is fewer, better, sillenced-by-default-except-what-matters.', 'Counts, not contents, on the lock screen. Curiosity opens apps; previews get read and dismissed.']],
      ['The three that earn their place', ['New-message alerts with inline reply: the core loop, actionable without opening anything. Daily Drop reminders: morning card, evening expiry nudge — the ritual engine. Streak nightlies: one line before bed, only while a streak lives.', 'Everything else waits inside the app. If it can wait until morning, it does.']],
      ['Tuning to your life', ['Night owl? The streak nudge lands before YOUR bedtime math, not ours. Busy season? Pause the board and notifications hush themselves — no settings spelunking required.', 'Per-type toggles live in settings, each with a plain-English description of what it does and when. No dark patterns, no re-opt-in mazes after updates.']],
      ['Quiet hours are sacred', ['Nothing non-urgent fires between ten and eight. Anonymous messages are wonderful; 3am buzzes are not. The schedule respects sleep like a good roommate.', 'Urgent is narrowly defined: nothing here pages you. If the building is on fire, call someone — do not wait for a push.']],
      ['When to go silent deliberately', ['Vacations, exams, heartbreaks: kill notifications at the OS level and let the board accumulate like mail. Returning to a full inbox beats returning to an anxious one.', 'The digest pattern beats the drip pattern. Batch, breathe, reply in one calm sitting.']],
    ],
  },
  {
    slug: 'block-without-drama', cat: 'safety', tags: ['Safety', 'Blocking'], query: 'calm boundary fence',
    feature: 'moderation', title: 'Blocking Without Drama',
    secs: [
      ['The quietest superpower', ['Blocking here stores one hash, deletes the message, and tells the sender nothing — no "you are blocked" page to screenshot, no escalation fuel, no farewell tour. The harassment ends mid-sentence.', 'Compare with social platforms, where blocks are public performances. Silence is not just kinder; it is strategically superior.']],
      ['When to block vs filter vs pause', ['Block people (repeat offenders, boundary-pushers, bad-faith actors). Filter words (topics that ruin your day regardless of author). Pause everything (volume exceeds capacity). Three tools, three problems — using the right one keeps each effective.', 'Blocking a word problem leaves the person; filtering a person problem leaves the behavior. Diagnose first, tap second.']],
      ['What blocked senders experience', ['Nothing. Their messages simply stop delivering, indistinguishable from a quiet board or a paused week. There is no appeal flow because there is no accusation — just absence.', 'This design choice is deliberate: observable blocks teach harassers to rotate devices. Unobservable ones just... stop working.']],
      ['Managing the list', ['Review blocked fingerprints quarterly in settings. Unblock liberally — people change, contexts change, and an unblock costs nothing to reverse. The list is hygiene, not a grudge.', 'Pair with reports for the worst cases: your block protects you, the report protects everyone else.']],
      ['The philosophy in one line', ['You owe strangers nothing, regulars warmth, and harassers silence. The tooling just makes each response one tap instead of one ordeal.']],
    ],
  },
  {
    slug: 'graduation-farewell-board', cat: 'seasonal', tags: ['Seasonal', 'Milestones'], query: 'graduation caps celebration',
    feature: 'stickers', title: 'Graduation & Farewell Boards',
    secs: [
      ['Endings deserve archives', ['Graduations, last days, moving trucks: these are peak candor moments wrapped in deadlines. A farewell board converts hallway hugs into paragraphs people keep for decades.', 'Start two weeks out. Goodbyes need lead time; the best messages arrive after days of quiet drafting.']],
      ['Prompts for the occasion', ['"TBH — favorite memory of us?" "One thing I will never forget about this place?" "Roast me fondly, one last time." Specific, warm, and just structured enough to defeat blank-box paralysis.', 'Theme it like the event: school colors via custom gradients, or the paper theme for yearbook energy.']],
      ['The group effect', ['Farewells compound: each posted sticker reminds ten more people the deadline exists. Pin the board link in every relevant chat and watch stragglers convert in the final 48 hours.', 'Read a selection aloud at the actual goodbye. Anonymous praise, spoken by a friend, hits like consensus — because it is.']],
      ['After everyone scatters', ['Export the keepers before closing anything. Group chats die within months; a saved set of messages outlives every platform migration.', 'Keep the board paused, not deleted, through the first year. Nostalgia messages arrive on anniversaries, and they are the best ones.']],
      ['Beyond graduation', ['Retirements, team departures, end-of-season, moving abroad: the pattern ports to every ending with feelings and witnesses. Endings are content; boards are the archive.']],
    ],
  },
  {
    slug: 'summer-break-boards', cat: 'seasonal', tags: ['Seasonal', 'Summer'], query: 'summer beach friends',
    feature: 'drops', title: 'Summer Break Boards',
    secs: [
      ['Distance makes inboxes grow fonder', ['Scattered for summer? A board becomes the group hangout that needs no scheduling: post nightly prompts, wake to replies across time zones, keep the streak alive from three area codes.', 'Summer prompts write themselves: ratings of beach reads, confession season, glow-up predictions for fall.']],
      ['The summer prompt calendar', ['June: predictions and dares. July: confessions and ratings, peak courage season. August: nostalgia and "what changed" retrospectives. One vibe per week keeps it fresh without daily labor.', 'Sunset sticker themes were basically invented for golden-hour stories. Use them shamelessly all season.']],
      ['Camp, travel, and patchy wifi', ['Offline outbox earns its keep on road trips and camps with one bar: queue replies and sends, sync at the next town. Streak freezes forgive the national-park week.', 'Time zones are a feature: wake to messages written while you slept, like letters from the future.']],
      ['Reunion fuel', ['Screenshot the summer highlights (tastefully) and read them at the reunion. Three months of anonymous honesty, performed live, beats any slideshow.', 'Keep one thread running all summer: "song of the summer, with reasons." Playlists plus justifications equal anthropology.']],
      ['September payoff', ['Return with receipts: the funniest, kindest, wildest messages of the season, shared with permission vibes intact. Summer boards become fall legends, and legends recruit.']],
    ],
  },
  {
    slug: 'exam-season-support', cat: 'seasonal', tags: ['Seasonal', 'Support'], query: 'students studying library',
    feature: 'inbox', title: 'Exam Season Support Boards',
    secs: [
      ['Stress loves an audience', ['Exam weeks concentrate anxiety beautifully — everyone spiraling in parallel, nobody saying it. A support board converts private panic into shared comedy and genuine encouragement.', 'Prompt it well: "TBH about finals week fears" beats "send messages" the way umbrellas beat wishing.']],
      ['Study break rituals', ['Post the board link with library hours: "procrastinating? send a TBH instead of refreshing grades." Micro-breaks with incoming messages beat doomscrolling on every metric that matters.', 'Evening drops sync perfectly with study schedules — prompt at dinner, replies by midnight, morale for tomorrow.']],
      ['Anonymous pep talks hit different', ['"You have never failed anything that mattered" lands harder from nowhere than from a friend performing optimism. Anonymity strips the social accounting out of encouragement.', 'Reply to the scared ones double-blind. One sentence from a stranger can reroute an entire study night.']],
      ['Boundaries during crunch', ['Pause the board during actual exam hours — delivery waits, focus does not. Word-filter the catastrophizing spirals ("fail", "drop out") into the tray for calmer review.', 'Protect sleep like a subject: notifications off, digest on, inbox in the morning like mail.']],
      ['After the last paper', ['Flip the board to celebration mode: predictions, roasts, summer plans. The same link that absorbed stress now collects joy — full circle in one URL.', 'Keep the kindest messages. Future hard weeks accept them as currency.']],
    ],
  },
  {
    slug: 'wedding-party-board', cat: 'seasonal', tags: ['Seasonal', 'Events'], query: 'wedding celebration dance',
    feature: 'stickers', title: 'Wedding & Party Boards',
    secs: [
      ['The guest book, upgraded', ['Paper guest books collect signatures; boards collect stories. "TBH about the couple" and "roast the best man kindly" produce keepsakes no stationery ever could.', 'QR on the sticker, QR on the tables. Grandparents scan codes now — trust the process.']],
      ['Running it on the day', ['Appoint one keeper: they post the sticker to their story, monitor the tray between courses, and pin the legends for the evening readout. Technology needs a human with a charged phone.', 'Strict mode during toasts (no heckling the speeches), standard during dancing (heckling encouraged, kindly).']],
      ['Prompts for every table', ['Childhood friends: "most legendary story, names redacted." Colleagues: "roast them professionally." Family: "marriage advice, anonymous and therefore honest." Different crowds, different prompts, one board.', 'The couple answers a few double-blind during dessert. The room goes feral. Trust us.']],
      ['The morning-after artifact', ['Export everything before the honeymoon haze: the keepers become an anniversary time capsule, the roasts become lore, the kind ones become framing-worthy.', 'One board per wedding beats a hundred scattered stories that expire in 24 hours. Permanence is the gift.']],
      ['Beyond weddings', ['Baby showers, milestone birthdays, retirements, housewarmings: any gathering with love and witnesses. The pattern is universal — prompt, collect, reveal, keep.']],
    ],
  },
  {
    slug: 'fitness-accountability-board', cat: 'stories', tags: ['Scenarios', 'Habits'], query: 'running fitness sunrise',
    feature: 'drops', title: 'Fitness Accountability, Anonymously',
    secs: [
      ['Why anonymous accountability works', ['Gym selfies invite judgment; anonymous check-ins invite honesty. "Skipped leg day, TBH why I am like this" gets real answers where performance posts get likes.', 'The board becomes a confessional for the fitness journey — struggles included, which is where the value lives.']],
      ['Structuring the week', ['Monday: intentions ("this week I will..."). Wednesday: midweek honesty check. Friday: wins and wipeouts. Sunday: rest-day reflections. Same four prompts weekly; rituals beat novelty for habits.', 'Streaks map perfectly onto training streaks. Two flames, one discipline.']],
      ['The group board advantage', ['Training partners sharing one board create gentle surveillance: everyone sees the check-ins roll (or not). Social pressure without social exposure.', 'Roast-kindly mode for missed sessions. Shame never built a habit; laughter has.']],
      ['Plateaus and bad weeks', ['Post the slump honestly and watch strangers who have been there answer with what worked. Anonymous veterans give better advice than identifiable influencers — no brand to protect.', 'Pause the board during injury recovery. The inbox will wait; tendons will not.']],
      ['Measuring what matters', ['Count check-ins, not likes. Count honest weeks, not perfect ones. The board that survives a bad month is worth ten that shine for a week.']],
    ],
  },
  {
    slug: 'book-club-anonymous', cat: 'stories', tags: ['Scenarios', 'Community'], query: 'books reading cozy',
    feature: 'inbox', title: 'Anonymous Book Club Boards',
    secs: [
      ['Hot takes need cover', ['"The protagonist annoyed me" is hard to say when the recommender is in the room. Anonymous boards let book clubs be honest about books, which is the entire point of clubs.', 'Spoiler discipline via word filters: filter character names until everyone finishes. Technology serving literature.']],
      ['Running the discussion', ['One prompt per section: predictions at 30%, verdicts at 70%, ratings at 100%. The board becomes a margin-notes layer the whole club shares.', 'Double-blind replies let shy members debate boldly. The quietest reader often has the sharpest take — anonymity finally lets it surface.']],
      ['Author events, upgraded', ['Visiting authors answering anonymous questions get the questions audiences actually have, not the polite ones. "Why did you spare THAT character" beats "where do you get ideas" forever.', 'Collect questions for a week, curate the best dozen, run the session. Standing ovation optional but likely.']],
      ['Between books', ['The gap weeks kill clubs. A standing prompt ("what are you reading now, honestly?") keeps the board warm between picks.', 'Let members pitch next reads anonymously with one-line pitches. Voting without campaigning.']],
      ['The library effect', ['A year of honest book talk, archived and searchable in memory if not in app: which picks divided the room, which united it, who called the twist on page fifty. Culture, compounded.']],
    ],
  },
  {
    slug: 'creator-fan-boards', cat: 'growth', tags: ['Growth', 'Creators'], query: 'creator camera content',
    feature: 'supporters', title: 'Creator & Fan Boards',
    secs: [
      ['The Q&A your comments wish they were', ['Comment sections reward speed and outrage. Anonymous boards reward curiosity: fans ask what they actually wonder, creators answer what actually matters. Same audience, better conversation.', 'Link it in bio, mention it weekly. Discovery compounds; one mention converts lurkers for months.']],
      ['AMAs without the chaos', ['Scheduled anonymous Q&A beats live chat for depth: questions arrive all week, you answer the best in one sitting, the recap post quotes highlights. No moderation firefighting mid-stream.', 'Word filters pre-screen the obvious junk; the tray catches the rest. You curate signal while the algorithm chases noise elsewhere.']],
      ['Feedback that improves the work', ['"TBH about my latest video" from anonymous viewers cuts deeper than any analytics dashboard. Retention graphs never say "the intro rambles" — a stranger will, kindly.', 'Separate boards per series or season keep feedback organized. Archive between projects; reopen with a retrospective prompt.']],
      ['Monetizing honesty', ['Supporter perks map beautifully to creator economies: custom usernames for mods, badges for top fans, hints for inner-circle vibes. The wall of supporters doubles as social proof for sponsors.', 'Transparent monthly goals ("server costs, covered by you") convert better than vague tip jars. Show the math.']],
      ['Boundaries at scale', ['Fame, even micro-fame, attracts boundary-pushers. Strict mode during launches, blocks without ceremony, pause between seasons. Protect the creator and the community survives.', 'You set the tone once, in the first prompt. Everything after is maintenance.']],
    ],
  },
  {
    slug: 'qr-codes-on-stickers', cat: 'growth', tags: ['Growth', 'Stickers'], query: 'qr code phone scan',
    feature: 'stickers', title: 'QR Codes: Screenshots Into Taps',
    secs: [
      ['The screenshot problem', ['Most story views never tap: apps bury link stickers, viewers screenshot instead, and screenshots do not convert. A QR code on the sticker converts the screenshot itself into a doorway.', 'Every exported sticker carries one automatically. No extra step, no design skill, no excuses.']],
      ['Placement that survives platforms', ['Bottom-right, clear of rails and input rows, sized for arm-length scanning: the safe-area presets already reserve the exact zone per platform.', 'Test it yourself before posting: screenshot your own story, scan from another phone. Thirty seconds that saves a dead campaign.']],
      ['Print is back, apparently', ['QR stickers work beyond screens: notebooks, lockers, event tables, merch tags. Anywhere eyes linger, a scan converts curiosity into a message.', 'Pair with a one-line prompt on the physical sticker. Context plus code beats code alone.']],
      ['Measuring the invisible', ['You cannot track scans — and should not. Measure replies per sticker instead: the metric that matters, honestly earned, privacy intact.', 'A/B placement across weeks: same prompt, QR top vs bottom. Let the inbox vote.']],
      ['The meta-lesson', ['Reduce every step between impulse and action. QR codes delete the "type the link" step that killed a thousand would-be messages. Friction is the enemy; ink is cheap.']],
    ],
  },
  {
    slug: 'android-app-mastery', cat: 'product', tags: ['App', 'Guide'], query: 'android phone apps',
    feature: 'app', title: 'Mastering the Android App',
    secs: [
      ['Beyond the download', ['Installing is step zero. Mastery is: notifications tuned, Drop ritualized, offline outbox trusted, themes matched to your wallpaper. Ten minutes of setup buys a year of smooth.', 'Start in settings: appearance, notification types, strictness. Defaults are sane; tuned is sublime.']],
      ['The notification setup that works', ['Keep message alerts and Drop reminders on; mute milestones if you are minimalist. Nightly streak nudges stay — they are the cheapest habit technology ever built.', 'Inline replies are the superpower: answer from the shade without opening anything. Try it once and the old way feels broken.']],
      ['Offline confidence', ['Airplane mode is a feature demo: queue sends and replies, watch the sync row count them, reconnect and watch them drain. Trust is built by watching it work once.', 'Parked verifications hand back to the composer prefilled — never lost text, never mystery state.']],
      ['Themes, widgets, shortcuts', ['System theme by default, manual override in settings. Home-screen widget for glanceable counts (coming to your launcher soon), long-press shortcuts for send and Drop.', 'Match the app icon to your wallpaper era. Aesthetics are motivation wearing a costume.']],
      ['Update without thinking', ['Skippable prompts on cold starts behind, full notes on the download page, per-ABI builds so updates stay lean. Stay current; each version compounds the last.', 'Beta energy, stable manners: report weirdness through the usual channels and watch it vanish by next release.']],
    ],
  },
];

/* ---------------- angles (10) ---------------- */
const ANGLES = [
  { id: 'ultimate-guide', title: (t) => `The Ultimate Guide to ${t}`, frame: 'comprehensive playbook', extra: 'checklist' },
  { id: 'mistakes', title: (t) => `${t.replace(/^The /, '')}: 7 Mistakes Everyone Makes`, frame: 'mistake autopsy with fixes', extra: 'checklist' },
  { id: 'psychology', title: (t) => `The Psychology Behind ${t.replace(/^The /, '')}`, frame: 'behavioral science lens', extra: 'studies' },
  { id: 'beginners', title: (t) => `${t.replace(/^The /, '')} for Beginners`, frame: 'zero-to-first-win tutorial', extra: 'steps' },
  { id: 'advanced', title: (t) => `Advanced ${t.replace(/^The /, '')}: Level Up`, frame: 'power-user tactics', extra: 'tactics' },
  { id: 'comparison', title: (t) => `${t.replace(/^The /, '')} vs the Alternatives`, frame: 'honest comparison', extra: 'verdict' },
  { id: 'myths', title: (t) => `5 Myths About ${t.replace(/^The /, '')}`, frame: 'myth-busting', extra: 'truths' },
  { id: 'scenarios', title: (t) => `${t.replace(/^The /, '')} in Real Life`, frame: 'worked scenarios', extra: 'scenes' },
  { id: 'faq', title: (t) => `${t.replace(/^The /, '')}: Questions, Answered`, frame: 'reader Q&A', extra: 'answers' },
  { id: 'secrets', title: (t) => `What Nobody Tells You About ${t.replace(/^The /, '')}`, frame: 'insider truths', extra: 'truths' },
];

const ANGLE_CONTENT = {
  'ultimate-guide': [
    ['The complete path', ['Start by choosing the job {T} needs to do, then write the smallest prompt that serves that job. A complete guide is not a longer checklist; it is a sequence of decisions that keeps the board coherent as it grows.', 'Keep the first week deliberately small: publish one specific invitation, answer the replies you receive, and record what people return to. Add features only after the basic loop has a real response.']],
    ['The operating system', ['A durable setup has three layers: a clear promise to senders, a dependable reply routine, and a review habit for anything that needs a decision. {T} works best when those layers reinforce one another instead of competing for attention.', 'Use the feature that removes the most friction this week. For one board that may be a filter; for another, a backup-code routine or a better sticker. The best setup is the one you will still follow when the novelty fades.']],
    ['What good looks like', ['Good does not mean a crowded inbox. It means the right people can understand the invitation, send without fear, and receive a response that makes the next visit likely. {T} becomes useful when the board feels dependable, not merely popular.', 'Review the loop at the end of each month. Keep what produced thoughtful returns, retire what created only noise, and write down the one change you will test next.']],
  ],
  mistakes: [
    ['The failure pattern', ['Most failed attempts at {T} are not caused by bad technology. They come from making the invitation vague, treating every message as urgent, and skipping the small maintenance that turns a first send into a habit.', 'The repair is usually subtraction: one clear prompt, one realistic reply window, one place to review messages. A board with fewer promises and a more reliable response beats an ambitious setup nobody maintains.']],
    ['Fix the order, not the symptom', ['When results are weak, change one variable at a time. First clarify the promise, then test the prompt, then adjust timing. Changing the theme, handle, filters, and posting time together makes the outcome impossible to learn from.', 'Keep a seven-day log with the prompt, reply count, and one observation. The log turns vague disappointment into a decision you can test again.']],
    ['The recovery path', ['You do not need to rebuild {T} from zero. Keep the link, clear the backlog, answer the messages that still matter, and announce a smaller restart. People are forgiving of a pause when the return feels intentional.', 'After two stable weeks, add one tactic. The recovery should end with a habit, not a burst of settings changes.']],
  ],
  psychology: [
    ['The mechanism', ['People approach {T} differently when the social cost of being visible disappears. They disclose more specific observations, take fewer half-hearted positions, and use a prompt as permission to articulate a question they would otherwise edit out.', 'That effect is not magic. The blank link lowers one kind of friction while leaving the need for clarity intact. Specific prompts give the lowered social cost a useful direction.']],
    ['The trade-off', ['Lower accountability can mean more honesty and more abuse. The same anonymity that lets someone ask a difficult question can make the recipient responsible for every boundary. {T} works when recipient controls are visible and easy to use, not buried in a policy.', 'Design for the generous majority and contain harmful behavior with proportionate tools: prompts that invite care, filters that catch clear problems, and blocks that end repeated boundary crossing.']],
    ['Observe before you conclude', ['Run a small experiment before generalizing. Change the prompt for one week, count meaningful returns, and read the replies for specificity rather than volume. A behavioral explanation should tell you what to try next.', 'If the change helps kind people participate more but also increases harmful messages, adjust the guardrail and the prompt together. Psychology is a lens, not a substitute for judgment.']],
  ],
  beginners: [
    ['The first launch', ['Begin with one sentence that tells a first-time sender exactly what kind of message would be welcome in {T}. Do not explain the whole concept. Post the invitation, keep the link easy to find, and let the first replies teach you what needs clarification.', 'Your first goal is not a perfect board. It is a complete loop: someone understands the invitation, sends a message, receives a thoughtful response, and knows it can return.']],
    ['The seven-day plan', ['Days one and two are for publishing and answering. Days three and four are for pinning a good example and changing one confusing detail. Days five and six are for trying a different format. Day seven is for deciding what to keep based on actual replies.', 'Do not make a beginner’s board carry every feature at once. {T} becomes manageable when the next action is obvious and the maintenance is short enough to repeat.']],
    ['When to ask for help', ['Ask for help when the link is broken, the backup routine is uncertain, or someone is sending something that crosses a boundary. A support conversation is more useful than guessing when the risk involves account access or another person’s safety.', 'Otherwise, use the first week as a small experiment. Record what you tried, what happened, and what you would change; that record is the foundation for every later improvement.']],
  ],
  advanced: [
    ['The leverage point', ['Advanced use of {T} comes from coordinating the loop, not from adding more settings. Put the prompt where the audience already is, make the response easy to answer, and use the resulting signal to decide what deserves another week of effort.', 'The most useful systems are quiet: recurring prompts, a predictable reply window, and a small archive of messages that worked. They reduce the number of decisions without taking authorship away from you.']],
    ['Edge cases worth planning for', ['Plan for a quiet week, a burst of messages, a sender who needs a boundary, and a device change. Each case should have a named response so the inbox does not require improvisation at the exact moment attention is scarce.', 'For {T}, the edge case is often not technical. It is social: a repeated sender, a question that needs privacy, or a reply that should stay kind but not become a promise. Write the response before you need it.']],
    ['Measure the compounding', ['Compare return senders, thoughtful replies, and the time spent managing the board. Raw reach is useful for distribution, but it does not tell you whether the system is becoming easier to run or harder.', 'Change one variable in a two-week test and keep the result. A durable advanced practice is a sequence of measured, reversible decisions.']],
  ],
  comparison: [
    ['Choose by job', ['The right alternative depends on the job, not on the label. A poll is strong for quick votes, a form is strong for structured detail, and a private conversation is strong when the exchange needs continuity. {T} is strongest when the sender needs a low-pressure way in and the recipient needs control over the space.', 'Name the job before naming a winner. “I want more replies” and “I want a safer, more honest response” call for different tools and different success measures.']],
    ['What changes when you switch', ['Moving to {T} changes the friction profile. Senders no longer need an account, replies can remain double-blind, and the recipient can filter or pause without a public confrontation. That is a real advantage for sensitive conversations, not a reason to pretend every use case is anonymous.', 'The cost is operational responsibility. Prompts need maintenance, boundaries need explaining, and a quiet board needs diagnosis rather than blame. Compare the full workflow, not only the signup flow.']],
    ['The verdict', ['Use the simplest tool that meets the need. Choose a poll for consensus, a form for repeatable data, a direct message for a known exchange, and {T} for candid, recipient-controlled interaction. Distinct tools solve distinct intents.', 'The most defensible choice is the one you can explain to the people using it and operate consistently for the next month.']],
  ],
  myths: [
    ['Myth, evidence, default', ['A common myth about {T} is that a blank prompt is neutral. It is not: a vague invitation sets the tone, determines who feels invited, and shapes the kind of response you will review. Replace the myth with a testable default: name the subject, the tone, and the boundary.', 'Evidence beats folklore here. Look at the specific messages that arrive, the people who return, and the cases that require intervention. The best correction is a practice that can be tested next week.']],
    ['What survives the evidence', ['Anonymity can lower social pressure, but it cannot guarantee kindness. A strong prompt can improve participation, but it cannot manufacture care. Good filters can reduce obvious harm, but they cannot replace a clear community standard.', 'Keep the useful part of the myth and discard the promise. {T} is a way to remove identity pressure, not a substitute for consent, moderation, or a reason to keep the board running.']],
    ['The practical default', ['Start with a specific invitation, reply within a predictable window, review the tray before it becomes a backlog, and explain what happens when a message crosses a line. These defaults are less exciting than a magic setting and more likely to survive a real community.', 'After a month, revise the default from evidence. A myth-busting page should leave readers with a better experiment, not just a firmer opinion.']],
  ],
  scenarios: [
    ['Scene map', ['Picture a real {T} board before it works: the first post is slightly awkward, the first replies arrive at uneven hours, and the owner is unsure whether to keep going. The useful question is not whether the scene looks effortless. It is which next action keeps the exchange alive.', 'Name the audience, the timing, the prompt, and the response. Those four details turn a vague story into a repeatable test that can be adapted without copying someone else’s personality.']],
    ['The turning point', ['In the scenes that work, the turning point is usually one specific reply that makes a sender feel safe enough to return. The owner does not need a viral moment. They need a clear prompt, a timely response, and enough moderation to make the next message feel safe too.', 'After the week, record what changed: the prompt, the reply, the timing, or the boundary. Carry the mechanism into your own {T} rather than copying the dramatic details.']],
    ['Build your own version', ['Use the scene as a starting point, then change one element for your audience. A different time zone may need a later prompt; a smaller group may need a narrower question; a sensitive board may need stronger filters. The transferable asset is the loop, not the anecdote.', 'Scenarios are useful when they teach a decision. If the story ends without a clear next move, it is entertainment; if it leaves you with a test you can run, it is guidance.']],
  ],
  faq: [
    ['Short answers', ['Start with the question a first-time reader is likely to have about {T}, answer it in the first paragraph, and then show the condition that changes the answer. Directness here is more useful than a dramatic opening.', 'Keep the quick answers genuinely quick. Put the edge cases below them so readers can stop after resolving the practical question without losing the longer explanation.']],
    ['Edge-case answers', ['Questions about privacy, safety, timing, or expectations become clearer when each answer names the tradeoff. Explain what the system protects, what the owner must do, and what remains outside the tool’s control.', 'A useful FAQ does not pretend every person has the same risk tolerance. It gives readers a way to make an informed choice and tells them where to look when the answer is not simple.']],
    ['What to do next', ['Turn the most common questions into a small preflight: confirm the link, choose a prompt, decide how to review replies, and save the recovery information. {T} is easier to use when the answer to “what now?” is part of the product.', 'If a question remains, ask it with context. Include the board type, the moment you are trying to handle, and the result you expected. Better questions produce better answers than another search for a perfect slogan.']],
  ],
  secrets: [
    ['The overlooked detail', ['The least obvious lever in {T} is often the one that makes the first action easy: a handle people can read, a prompt that says what to send, or a response that does not sound like an automated deflection. Details compound because they decide whether the next step is taken.', 'Review the path as a sender would. Start with the link, read the invitation, imagine the reply, and notice every point where curiosity gets interrupted. Fix the interruption before adding another feature.']],
    ['The advanced loop', ['Experienced operators do not chase a perfect post. They build a small system for testing prompts, preserving winners, and returning to the people who replied well. The loop creates evidence; the evidence makes the next choice less arbitrary.', 'For {T}, keep a record of the question, the response pattern, and the change made. A small archive is more useful than a large list of features because it tells you what your audience actually values.']],
    ['The non-obvious rule', ['The rule is to protect attention without making the board feel closed. Reply selectively, make boundaries visible, and leave enough room for a person to surprise you. {T} stays interesting when consistency provides safety without turning every interaction into a script.', 'The best advanced practice is restraint. Keep the system small enough to inspect, the prompt specific enough to trust, and the response human enough to remember.']],
  ],
};

const ANGLE_PLANS = {
  'ultimate-guide': [0, 1, 2, 3, 4],
  mistakes: [2, 3, 4],
  psychology: [1, 0, 2],
  beginners: [0, 4, 1],
  advanced: [3, 1, 4],
  comparison: [4, 0],
  myths: [1, 3, 2],
  scenarios: [2, 0],
  faq: [3, 1],
  secrets: [2, 4],
};

const CLOSERS = [
  'Enjoyed this? Your inbox is one sticker away from its best week — post tonight and see.',
  'Theory ends here. Open the app, run one play from this post, and check back tomorrow.',
  'If this helped, the highest compliment is a buzzing board. Go make some noise (politely, anonymously).',
  'Bookmark it, share it with a friend running a board, and put one idea to work this week.',
];

/* ---------------- deep dives (one per category x3, ~170 words) ---------------- */
const DEEP_DIVES = {
  privacy: [
    ['The honest threat model', ['Start with who you are actually worried about. For most people it is not nation-states; it is a nosy ex, a judgmental coworker, or an ad network building a profile. SecretMsg is engineered against exactly those adversaries: no sender identifiers means there is nothing to subpoena, leak, or sell about who wrote what.', 'Against stronger adversaries the honest answer is narrower: network-level observers can see that you visited the site (use Tor if that matters), and a compromised device sees everything (no app survives that). Privacy is always relative to a threat — ours is calibrated to real life, not spy movies.']],
    ['Why we refuse certain data', ['Every field we do not collect is a breach that cannot happen, a subpoena we cannot answer, and a temptation our future selves cannot indulge. IP logs would make abuse investigation marginally easier and user trust impossible — so they do not exist.', 'This refusal has costs: we fight spam without device graphs, support without identity lookups, analytics without tracking. We pay them gladly, because the alternative is every other app.']],
    ['Verifying instead of trusting', ['Do not take our word for any of this. The client is open source, the API responses contain only what the docs say, and the delete endpoint demonstrably wipes accounts. Skepticism is the correct default — aim it at us too.', 'Ask hard questions: what is in the database right now, who can read dumps, what survives deletion. The answers are boring, which is precisely the point. Boring is safe.']],
  ],
  guides: [
    ['The compound effect of small loops', ['Nobody builds a great inbox in a weekend. They build it in ninety-second increments: one evening sticker, one nightly reply session, one weekly tray review. Each loop is trivial; the compounding is violent.', 'Track one metric — replies per week — and change one variable at a time. Prompt style this week, posting time next. In a month you will have a playbook no guide could have given you, because it will be yours.']],
    ['Teaching your audience', ['Your senders are trainable, and you are the trainer. Fast replies teach that sending works. Pinned keepers teach what quality looks like. Public answers teach newcomers the board is alive.', 'Every interaction is a lesson whether you plan it or not. Plan it: decide what behavior earns a reply, a pin, a share — then reward exactly that, consistently, for weeks.']],
    ['When to ignore this guide', ['Guides describe averages; you are a sample of one. If your chaotic 2am energy pulls more replies than our optimized evening slot, congratulations — you found your edge. Keep it.', 'Break rules deliberately, measure honestly, and keep what survives contact with your actual followers. The map is not the territory, and your inbox is the territory.']],
  ],
  culture: [
    ['The mask that reveals', ['Psychologists have a clunky term — the online disinhibition effect — for a simple truth: masks reveal. Remove the name and people say what the named self censors: kinder things, weirder things, truer things.', 'The effect cuts both ways, which is why recipient-controlled moderation is not a footnote but the other half of the design. Freedom to speak requires freedom to filter.']],
    ['Rituals need costumes', ['Every durable human ritual has a costume: jerseys, robes, masks, uniforms. Anonymity is the costume of honesty — it tells participants which self to bring. Story stickers and daily drops are just modern vestments.', 'Design your board like a ritual space, not a form. Openings, closings, repeated prompts, seasonal variations. Ceremony converts one-time senders into congregants.']],
    ['What anonymity cannot do', ['It cannot manufacture care, only unblock it. An empty heart plus a blank box equals an empty inbox — the tool removes friction, not apathy. If nobody writes, the answer is better prompts and warmer replies, not louder anonymity.', 'It also cannot absolve cruelty. Shields work both directions, and communities that protect cruelty die of it. Filter generously, block silently, report honestly.']],
  ],
  product: [
    ['Under the hood, honestly', ['No machine learning, no behavior graphs, no engagement optimizer. The stack is boring on purpose: a fast edge API, an encrypted-at-rest database, and client apps with no trackers. Boring scales, boring audits, boring sleeps well.', 'Every "smart" feature here is deterministic: streak math, drop rotation, template pools. Deterministic means testable, explainable, and private — the opposite of the black boxes that monetize you elsewhere.']],
    ['Designed defaults', ['Defaults are destiny: most users never change a setting, so each default is a moral choice. Ours favor privacy (hints off unless earned), calm (quiet hours, capped pushes), and forgiveness (freezes, repairs, retries).', 'If you disagree with a default, change it in seconds — settings are one tap deep, explained in plain words, never reset by updates. Your configuration is a promise we keep.']],
    ['What we will never build', ['No read receipts for senders. No typing indicators. No follower counts, no public leaderboards of people, no "seen" checkmarks that manufacture anxiety. Engagement mechanics that cost users peace are off the table permanently.', 'This restraint is a feature list in negative space. Every missing surveillance widget is a decision you can verify by using the app.']],
  ],
  safety: [
    ['Prevention beats punishment', ['The best moderation outcome is the message that never needed holding. Clear prompts attract better senders than vague ones; visible community norms ("kind roasts only") outperform silent filters.', 'Think in layers: prompt design first, word filters second, pause third, blocks fourth, reports fifth. Each layer catches what the previous one missed, and most problems die in layer one.']],
    ['The false-positive budget', ['Every filter trades cruelty caught against kindness delayed. Standard mode spends that budget wisely by holding instead of deleting — review converts errors into corrections.', 'Audit monthly: if the tray holds mostly fair messages, loosen the list. A filter that catches friends is worse than no filter at all.']],
    ['Helping others stay safe', ['Share this post with anyone running a board, especially younger users. Walk them through pause and block before they need either — safety tooling learned calmly works instantly under stress.', 'Normalize reporting: it protects the whole platform, takes seconds, and never exposes the reporter. Communities that report stay communities.']],
  ],
  growth: [
    ['The math of one share', ['One story sticker reaches a few hundred viewers; low single-digit percents tap; a fraction of tappers send; a fraction of senders return. Each stage leaks — so each stage gets optimized: hook, handle visibility, prompt specificity, reply speed.', 'Small conversion gains compound across stages multiplicatively. Improve each step ten percent and the inbox doubles. That is the whole growth department, arithmetically.']],
    ['Retention is the real growth', ['A new sender who never returns cost you a sticker. A sender who returns weekly is worth dozens of one-timers. Replies, streaks, and drops exist to convert first messages into habits.', 'Measure return rate, not reach. Reach flatters; returns pay. Every feature here is tuned for the second visit, not the first impression.']],
    ['Compounding content', ['Each great exchange produces shareable proof: screenshots, quotes, stories. Recycle winners as new stickers and the content flywheel spins without fresh effort.', 'Archive monthly highlights. In a year that folder is a museum of your community — and museums recruit visitors.']],
  ],
  stories: [
    ['Reading the scene', ['Notice what the people in these stories actually did: specific prompts, evening timing, fast replies, pinned keepers. No talent, no luck, no follower counts — just a loop, run in order.', 'Your situation differs in details, never in mechanics. Map their moves onto your board and run the same week.']],
    ['The turning point pattern', ['Every story pivots on one reply — the answer that converted a sender into a regular. Find your pivot by answering everything for two weeks and watching who returns.', 'Then double down on whatever earned that return. Strategy is just attention paid to what already worked.']],
    ['Writing your own scene', ['Document as you go: screenshot the keepers, note what prompt pulled them, record the timing. In a month you will have a personal playbook no generic guide can match.', 'Share the playbook back. Scenes teaching scenes is how communities outlearn individuals.']],
  ],
  seasonal: [
    ['Borrowed energy', ['Moments do half your marketing: the calendar supplies motive, mood, and attention, and your prompt just needs to catch the wave. Generic prompts on special weeks underperform specific seasonal ones dramatically.', 'The rule: name the moment in the prompt. "TBH about this semester" beats "send TBH" every finals week ever recorded.']],
    ['Seasonal strictness', ['High-energy weeks bring high-energy messages — tune filters up before the peak, not during it. Strict mode for event nights, standard for the season, review trays generously after.', 'Protect the vibe proactively and you spend the event enjoying it instead of moderating it.']],
    ['After the moment passes', ['Archive the keepers, clear the tray, loosen the filters, and note what worked for next year. Seasonal playbooks appreciate like savings bonds.', 'Traditions are just good ideas on a schedule. Put next year occurrence on the calendar now, while the memory is warm.']],
  ],
};

/* ---------------- lenses: second-paragraph depth for topic sections ---------------- */
const LENSES = [
  'Look closer and a second-order effect appears: the people who benefit most are rarely the loudest, which means the visible feedback undersells the real impact. Design for the quiet majority and let the vocal minority enjoy the ride.',
  'There is a common failure mode here worth naming: doing the motion without the meaning. Checklist behavior — tapping through steps while thinking about dinner — produces checklist results. Slow down for the one step that actually matters and rush the rest.',
  'An example makes it concrete. Picture a board owner, Tuesday evening, phone in hand, three minutes to spare. Everything in this section should survive that exact scene — if it requires a desktop, a spreadsheet, or an hour, it belongs in a different post.',
  'Pushback welcome: skeptics will say this only works for extroverts, big accounts, or lucky timing. The data disagrees — small, consistent boards outperform flashy ones on every retention metric that matters. Boring and steady wins.',
  'The advanced version of this section fits in one sentence: automate the reminder, personalize the execution. Systems handle cadence; humans handle care. Never confuse which job is yours.',
  'Watch for the trap of optimizing too early. Run the basic version for two full weeks before tweaking anything — most "improvements" made in week one are just anxiety wearing a lab coat.',
  'If you take one thing from this section, take this: the mechanism matters less than the repetition. A mediocre prompt posted every evening beats a perfect prompt posted once, by an embarrassing margin.',
  'A useful test: explain this section to a friend in thirty seconds. Whatever survives that compression is the real point; everything else was scaffolding. Keep the point, ship the scaffolding to the archive.',
  'Context changes everything, so calibrate to your audience size. Under fifty followers, intimacy does the heavy lifting — be personal. Over five hundred, systems do — be consistent. Same section, different emphasis.',
  'One more angle: consider what happens if you do the opposite for a week. Inversion is a cheap experiment and occasionally reveals that the conventional advice was optimized for someone else entirely.',
];

/* ---------------- field notes (per category x3, ~190 words) ---------------- */const FIELD_NOTES = {
  privacy: [
    ['Notes from the audit trail', ['The strongest privacy claim is the one you can check in under a minute: open devtools, watch the network tab, and confirm that sends carry content plus a challenge token and nothing identifying. Then read the delete endpoint behavior by testing with a throwaway board.', 'Make this a habit, not a one-time audit. Re-check after every major app update, because codebases drift and only verification catches drift. Trust, but capture packets.']],
    ['What "anonymous" survives', ['Account recovery flows, push notification tokens, and payment records each touch identity at the edges — the honest design names those edges instead of pretending they do not exist. Your handle and PIN identify your board to you; nothing identifies senders to anyone.', 'Draw your own map: which party learns what, at which step. Any flow you cannot map is a flow to ask about publicly.']],
    ['Teaching others to verify', ['Forward the verification habit, not just the app: show one friend how to check network traffic, where the privacy policy lives, and what delete actually deletes. Privacy literacy compounds across networks.', 'Communities that verify together stay safe together. Make skepticism social.']],
  ],
  guides: [
    ['The week-two wall', ['Almost everyone stalls in week two: novelty fades, replies slow, the sticker feels repetitive. This is normal, predictable, and survivable — it is also where most boards die.', 'Push through with one change only: a new prompt format. Not a new theme, not new settings — one new question, posted in the evening. Novelty restarts the loop; everything else is procrastination disguised as optimization.']],
    ['Measuring without obsessing', ['Track replies per week on a sticky note. That is the whole analytics department. Ignore views, ignore story taps, ignore everything upstream of an actual message.', 'Review monthly, not nightly. Daily noise will convince you to change things that were working; monthly signal tells the truth.']],
    ['When guides stop helping', ['Some boards need an audience, not advice: five total followers cannot sustain daily rituals no matter how perfect the prompts. If the fundamentals are right and results stay flat for a month, the bottleneck is reach.', 'Fix reach offline first — real friends, real asks, real stories. Then return to the guides with traffic worth optimizing.']],
  ],
  culture: [
    ['The generosity hypothesis', ['Watch what people do with a truly safe channel and a pattern emerges: the vast majority choose kindness, humor, and sincerity. Cruelty is loud but rare; generosity is quiet and everywhere.', 'Design for the generous majority and contain the cruel minority with tools, not with suspicion of everyone. Most senders deserve the benefit of every doubt.']],
    ['Anonymity across cultures', ['Directness norms vary wildly: some cultures confess easily, others need warmer prompts and stronger privacy assurances. There is no universal prompt — there are only local ones.', 'If your audience spans cultures, run parallel prompts: blunt for some, gentle for others. Watch which fills first and follow the data, not the stereotype.']],
    ['The long arc', ['Anonymous platforms cycle: novelty, golden age, growing pains, maturity. Each phase needs different stewardship — excitement, then norms, then tools, then tradition.', 'You are living in someone else golden age right now. Act like a good ancestor: set norms, model kindness, archive the best of it.']],
  ],
  product: [
    ['Feature adoption curves', ['Power features take weeks to find their people. Streaks clicked instantly; the filtered tray took months of education. If a feature feels invisible, the answer is usually explanation, not redesign.', 'Read the blog (this one) as the manual layer: every capability gets its essay, its scenarios, its edge cases. Documentation is a feature with words instead of buttons.']],
    ['Requesting features well', ['The best requests describe the problem, not the solution: "I lose good prompts" beats "add a save button". Problems invite design; solutions invite debate.', 'Aggregate your asks with others — ten users describing the same pain outranks one user with a mockup. Channels exist for this; use them loudly.']],
    ['Version patience', ['Updates roll in weekly; not every release is for you. Skim the notes, adopt what fits, ignore the rest without guilt. Software used calmly beats software chased anxiously.', 'Stay current for security, stay curious for features, stay relaxed about both. The app rewards steady users more than early adopters.']],
  ],
  safety: [
    ['Threat modeling for real life', ['List your actual risks in order: unkind strangers, boundary-pushing acquaintances, coordinated pile-ons, platform-level failures. Assign one tool per risk and stop there — uncovered risks get attention, covered ones get peace.', 'Revisit the list seasonally. Risks change with visibility: a board that grows tenfold needs a stricter posture than a quiet one.']],
    ['Helping a friend in trouble', ['When someone shares their scary inbox, do three things: validate first ("that sounds awful"), then navigate to the exact buttons (pause, block, report), then stay while they tap them.', 'Never demand screenshots or details they do not offer. Support means reducing their load, not satisfying your curiosity.']],
    ['After an incident', ['Document what happened while it is fresh: dates, what was sent, which tools you used. Then tighten one thing — a filter, a pause schedule, a boundary — and close the loop.', 'Incidents teach; audits preserve the lesson. File the notes with your backup codes and move on lighter.']],
  ],
  growth: [
    ['The shareability checklist', ['Before posting, score the sticker: hook in five words or fewer? Handle legible at arm length? One visual idea? QR scannable from a screenshot? Four yeses predict shares; any no predicts scrolling past.', 'Run every card through the checklist for a month until it becomes instinct. Taste is just checklists with tenure.']],
    ['Collaborations that work', ['Two boards cross-posting the same prompt on the same night doubles both audiences overnight. Pick partners with adjacent but non-identical followers and a shared tone.', 'Agree upfront on replies (who answers what), timing (same evening), and credit (both links on both stickers). Handshakes beat hand-waving.']],
    ['Slow seasons', ['Every board has dead weeks: holidays, exams, algorithm moods. Do not redesign during droughts — maintain lightly (one sticker, nightly replies) and wait for rain.', 'Droughts end. Boards that maintained through them rebound faster than boards that panicked and pivoted into unrecognizability.']],
  ],
  stories: [
    ['Stealing like an artist', ['Take the structure, leave the details: evening post, specific prompt, fast replies, pinned keeper. The pattern ports across niches; the content must be yours.', 'Credit inspirations when they are people ("saw Maya do this"), never when they are tactics. Tactics want to be stolen.']],
    ['Documenting your run', ['Keep a simple log: date, prompt, replies, what worked. Future you will mine it for patterns present you cannot see.', 'Monthly, reread the log and write one paragraph on what changed. That paragraph is strategy; everything else was data collection.']],
    ['Teaching the loop', ['Once it works, show one other person — screenshots, timing, exact words. Teaching locks in your own understanding and recruits the next board.', 'Communities of practice outperform lone geniuses. Be the person who explains things clearly and watch your inbox fill with gratitude.']],
  ],
  seasonal: [
    ['Reading the calendar', ['Map your year in advance: twelve moments with natural energy, one prompt each, scheduled loosely. When the week arrives, you execute instead of inventing.', 'Leave gaps for spontaneity — the plan handles the predictable so you have bandwidth for the surprising.']],
    ['Off-season maintenance', ['Between moments, run evergreen prompts weekly to keep the loop warm. A board that posts monthly hibernates; one that posts weekly idles, ready to sprint.', 'Use quiet weeks for audits: filters, pins, presets, streaks. Maintenance in peacetime wins wartime.']],
    ['Moment post-mortems', ['After each seasonal run, score it: replies, keepers, new regulars, lessons. Two sentences per moment, filed where next year you will find them.', 'Year two of any tradition outperforms year one by multiples — if you kept notes. Notes are the tradition.']],
  ],
};

/* ---------------- assembly ---------------- */
function excerptFor(angle, topic) {
  const frames = {
    'ultimate-guide': `Everything about ${topic.title.toLowerCase()} — setup, strategy, and the details that separate thriving boards from silent ones.`,
    mistakes: `The seven ways people fumble ${topic.title.toLowerCase()}, each with its fix. Learn them here, not the hard way.`,
    psychology: `Why ${topic.title.toLowerCase()} works on human brains — the behavioral science plus what to do with it.`,
    beginners: `New to ${topic.title.toLowerCase()}? Start here: zero jargon, first win in under ten minutes.`,
    advanced: `Beyond the basics of ${topic.title.toLowerCase()}: power tactics for boards that already hum.`,
    comparison: `How ${topic.title.toLowerCase()} stacks against the alternatives — honest verdict, no tribalism.`,
    myths: `Five myths about ${topic.title.toLowerCase()}, busted with evidence and better defaults.`,
    scenarios: `${topic.title} played out in real scenes — watch the loop work, then steal it.`,
    faq: `Every question people actually ask about ${topic.title.toLowerCase()}, answered straight.`,
    secrets: `The insider truths about ${topic.title.toLowerCase()} nobody puts in the onboarding.`,
  };
  return frames[angle.id];
}

function fm(post) {
  const lines = [
    '---',
    `title: "${post.title.replace(/"/g, "'")}"`,
    `slug: ${post.slug}`,
    `date: ${post.date}`,
    `status: ${post.status}`,
    `tags: [${post.tags.map((t) => `"${t}"`).join(', ')}]`,
    `excerpt: "${post.excerpt.replace(/"/g, "'")}"`,
    `pixabay: "${post.query}"`,
    `readMinutes: ${post.readMinutes}`,
    'image: ""',
    'image_r2: ""',
    'credit: ""',
    'credit_url: ""',
    '---',
    '',
  ];
  return lines.join('\n');
}

function main() {
  mkdirSync(outDir, { recursive: true });
  const existing = new Set(readdirSync(outDir).filter((f) => f.endsWith('.md')));
  const rnd = mulberry32(20260918);

  // 30 topics x 10 angles = 300. Front-loaded calendar: the first 220 land
  // between Jan and mid-Sep 2026 (published now), the rest streams weekly
  // into Dec 2027 (scheduled, auto-published by build date).
  const topics = TOPICS.slice(0, 30);
  let n = 0;
  let made = 0;
  const total = 300;
  const pubCount = 220;
  const pubStart = new Date(Date.UTC(2026, 0, 5)).getTime();
  const pubEnd = new Date(Date.UTC(2026, 8, 18)).getTime();
  const schStart = new Date(Date.UTC(2026, 8, 19)).getTime();
  const schEnd = new Date(Date.UTC(2027, 11, 20)).getTime();
  const todayCut = '2026-09-18';
  for (const topic of topics) {
    for (const angle of ANGLES) {
      if (n >= total) break;
      const idx = n;
      const day = idx < pubCount
        ? new Date(pubStart + Math.floor(((pubEnd - pubStart) * idx) / (pubCount - 1)))
        : new Date(schStart + Math.floor(((schEnd - schStart) * (idx - pubCount)) / (total - pubCount - 1)));
      const date = day.toISOString().slice(0, 10);
      let status = date <= todayCut ? 'published' : 'scheduled';
      if (idx % 30 === 29) status = 'draft'; // ~10 drafts scattered

      const title = angle.title(topic.title);
      const slug = `${topic.slug}-${angle.id}`;
      const intro = `${topic.title} is easier to use when the page has a clear job. This ${angle.frame} starts with the decision in front of you, then follows the details that make the decision workable.`;
      const outro = pick(rnd, OUTROS[topic.cat]);
      const stat = pick(rnd, STATS);
      const closer = pick(rnd, CLOSERS);
      const sibs = ANGLES.filter((a) => a.id !== angle.id);
      const rel = [sibs[idx % sibs.length], sibs[(idx + 3) % sibs.length], sibs[(idx + 5) % sibs.length]];
      const relLines = rel.map((a) => `- [${a.title(topic.title)}](/post/${topic.slug}-${a.id})`);
      const ordered = ANGLE_PLANS[angle.id].map((sectionIndex) => topic.secs[sectionIndex]);
      const angleSections = ANGLE_CONTENT[angle.id].map(([heading, paragraphs]) => [
        heading,
        paragraphs.map((paragraph) => paragraph.replaceAll('{T}', topic.title)),
      ]);

      let body = `# ${title}\n\n${intro}\n\n> ${stat}\n`;
      ordered.forEach(([h, ps]) => {
        body += `\n## ${h}\n\n${ps.join('\n\n')}\n`;
      });
      angleSections.forEach(([h, ps]) => {
        body += `\n## ${h}\n\n${ps.join('\n\n')}\n`;
      });
      body += `\n## Related by intent\n\n${relLines.join('\n')}\n`;
      body += `\n${outro}\n\n*${closer}*\n`;

      const words = body.split(/\s+/).length;
      const post = {
        title, slug, date, status,
        tags: [CATS[topic.cat], ...topic.tags].slice(0, 3),
        excerpt: excerptFor(angle, topic),
        query: topic.query,
        readMinutes: Math.max(4, Math.round(words / 200)),
      };
      const file = `${slug}.md`;
      if (!existsSync(join(outDir, file)) || force) {
        writeFileSync(join(outDir, file), fm(post) + body);
        made++;
      }
      n++;
    }
  }
  // Report status mix.
  const files = readdirSync(outDir).filter((f) => f.endsWith('.md'));
  const mix = { published: 0, scheduled: 0, draft: 0 };
  for (const f of files) {
    const t = readFileSync(join(outDir, f), 'utf8');
    const m = t.match(/status: (\w+)/);
    if (m && mix[m[1]] !== undefined) mix[m[1]]++;
  }
  console.log(`posts: ${files.length} files (${made} written), mix:`, JSON.stringify(mix));
}

main();
