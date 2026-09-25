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
  'A specific question gives senders a clear starting point; compare it with a blank invitation on your own board.',
  'Posting times vary by audience; test a small number of windows instead of assuming one is best.',
  'Vibe templates can help someone start when a blank box feels difficult.',
  'Double-blind replies hide sender identity from the recipient while still giving them a way to answer.',
  'Pause submissions rejects new messages until the board is active again; senders must try later.',
  'A clear question can reduce uncertainty about what kind of message to send.',
  'A useful first reply can make the next interaction easier, but no reply guarantees another message.',
  'Anonymous feedback can feel lower-pressure; it does not guarantee candor or kindness.',
];

const INTROS = {
  privacy: [
    'Privacy policies are usually where honesty goes to die — long, vague, and unenforceable. This post is the opposite: a concrete look at {T}, including what is stored, processed, or left out.',
    'Everyone claims to respect your privacy. Almost nobody shows their work. Let us fix that, starting with {T}.',
    'If you have ever wondered what happens after you tap send on an anonymous message, this is the full answer — no legalese, no hand-waving, just {T}.',
    'Trust is a feature you ship, not a paragraph you publish. Here is how {T} is engineered into SecretMsg from the database up.',
    'Data that is not collected needs no retention or deletion. That constraint shapes the choices behind {T}.',
    'Anonymous does not have to mean reckless, and private does not have to mean complicated. {T}, explained plainly.',
  ],
  guides: [
    'Blank boxes get blank answers. If your inbox is quiet, the problem is almost never your followers — it is your prompt. Here is how to fix {T}, step by step.',
    'This is the practical, no-fluff guide to {T}: what to tap, what to write, and the small details that separate dead boards from active ones.',
    'You do not need more followers. You need a clearer invitation. Start with {T}.',
    'This guide distills the setup into {T} you can try in a short session.',
    'Skip the theory — here is the exact playbook for {T}, in the order you should do things.',
    'Useful anonymous inboxes are built, not found. Here is the construction manual for {T}.',
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
    'Apps can have more features than you need. Consider this a practical guide to the parts of {T} worth using.',
    'Behind every button is a decision. Here are the decisions inside {T} — and the workflows they enable.',
    'New here? Start here. {T}, explained from zero, with the shortcuts power users wish they had known on day one.',
    'This is the manual {T} should have shipped with: practical, opinionated, and short on fluff.',
  ],
  safety: [
    'Safety tooling nobody can find might as well not exist. So here is the complete, plain-language tour of {T} — where it lives, when to reach for it, and what happens next.',
    'Anonymity protects honesty, and occasionally shields unkindness. That is exactly why {T} exists, and why you should know it cold.',
    'A useful inbox starts with an owner who knows its controls and limits. Pull up a chair: {T}, end to end.',
    'Nobody reads safety docs until they need them. Bookmark this anyway — {T} explained before you ever need it.',
    'Good fences, honest neighbors. {T} is the fence; this post is the map.',
    'You hold more power over your inbox than you think. Proof, starting with {T}.',
  ],
  growth: [
    'Growth advice for anonymous apps usually boils down to "go viral". Useless. Here is the unglamorous, repeatable playbook behind {T}.',
    'Your link is a product and your story is its landing page. {T} is conversion optimization for honesty.',
    'A blank box can make a first message feel awkward. People may share a story, a question, or a reply that made their day. {T} gives the invitation a home.',
    'Small boards grow the same way big ones did: one great share at a time. The mechanics of {T}.',
    'Your link is a product and your story is its landing page. {T} is a way to make the invitation clearer.',
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
    'Timing can help a seasonal invitation. Test {T} when your audience is most likely to see it.',
    'The best prompt is the one that meets people where they already are. Right now, that is {T}.',
    'Seasons change what people want to confess. Align your board with {T} and watch what happens.',
    'Do not let the moment pass quietly. A short, sharp guide to {T}.',
  ],
};

const OUTROS = {
  privacy: [
    'Privacy is a design constraint, not a guarantee. Read the current policy and note which processors receive content, connection data, or a limited preview.',
    'Read the policy, then check the current implementation when a detail matters. Both should describe the same service.',
  ],
  guides: [
    'Do one thing from this guide tonight — tonight, not someday — and your next check of the inbox will feel different.',
    'The whole playbook fits in a pocket: specific prompt, low friction, good timing. Go post.',
  ],
  culture: [
    'The booth is open whenever you are. What gets said in it has a way of mattering more than anyone expects.',
    'Stay honest out there — and give someone else room to be honest back without promising anonymity or safety you cannot guarantee.',
  ],
  product: [
    'Now go use it for real. When you find an edge case this guide does not cover, note the setup and result so your next test is more precise.',
    'Update the app, tap around, and make the feature yours. That is what it is for.',
  ],
  safety: [
    'Filter, pause, block, or report according to the situation. These are recipient controls, not comprehensive automated moderation.',
    'Save this post and share it with anyone running a board: know the available controls, their limits, and the steps for a safety concern.',
  ],
  growth: [
    'Post tonight. Measure tomorrow. Repeat what moved. That is the entire growth department.',
    'A clear invitation gives the next sender an easy way in. Post, observe, and improve the next version.',
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
    'Everything lands in one calm stream with filters for unread, replied, and pinned — a simple way to decide what to read next.',
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
    'Dice roulette turns "what should I ask?" into a game: pick a vibe, roll, and send whatever lands. The pool contains 9,000 prompts, so repeats are possible but uncommon in a short session.',
    'Roll history keeps your recent hits one tap away, and the composer loop drops a landed prompt straight into a message draft.',
  ],
  moderation: [
    'Word filters hold hits in a review tray instead of deleting them into the void. You approve what is fair and discard what is not — the sender never knows which.',
    'Strictness controls whether matching words are skipped, held for review, or rejected and held; pause rejects new submissions, and blocks use recipient-scoped hashed fingerprints when available.',
  ],
  supporters: [
    'Supporters help fund the service. Depending on the verified checkout and account grant, perks can include supporter badges, sender hints, or a custom username.',
    'Play purchases are verified server-side, and Polar grants are applied only after a verified webhook — no client-side unlocks.',
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
      ['What anonymous messaging actually is', ['Anonymous messaging means the recipient is not given the sender’s name or account. SecretMsg still processes and stores message text to deliver it, applies a send-time Turnstile bot check, and can store a hash of a mobile app-generated sender value. The privacy promise is limited to not disclosing a sender identity to the recipient, not to making a sender untraceable.', 'That distinction matters. Recipients can configure hidden-word filtering, pause submissions, block a mobile sender fingerprint for their own inbox, and report a message. Those controls do not reveal a sender, and a report does not by itself trigger a network-wide block or account action.']],
      ['Why it works better than you expect', ['Removing a visible identity can lower social pressure for some senders, which may make a specific question easier to ask. It does not guarantee honesty, kindness, or a return visit. The blank text box is a simple way to invite a response without asking a sender to create an account.', 'The catch is friction. A confusing link, a dead board, or a silent inbox can stop the exchange — which is why everything below focuses on mechanics, not vibes.']],
      ['Your first week, day by day', ['Day one: create the inbox and post your link with one specific question. Days two to four: answer everything double-blind, even the short ones — early replies train senders to return. Day five: try a vibe template as your sticker caption. Weekend: check streaks, review the filtered tray, and adjust one filter.', 'By day seven you will know exactly which prompt style your audience answers. Double down on it.']],
      ['The three mistakes that kill boards', ['Mistake one: a blank "send me something" sticker. Always attach a question. Mistake two: never replying — an unanswered inbox teaches followers that sending is pointless. Mistake three: leaving the board paused from a weekend trip and forgetting to reopen it.', 'Each takes under a minute to fix, and each compounds weekly.']],
      ['Leveling up without trying', ['Once the basics hum, add texture: sticker themes per mood, dice rolls for prompts on dry days, the Daily Drop as your morning ritual. None of this is required. Each can make the invitation easier to understand, but results still depend on your audience and follow-through.', 'Watch which senders return after your replies — those are your community. Treat them like it.']],
    ],
  },
  {
    slug: 'tbh-culture', cat: 'culture', tags: ['Culture', 'TBH'], query: 'teen friends laughing',
    feature: 'drops', title: 'TBH Culture, Explained',
    secs: [
      ['Where "to be honest" came from', ['TBH began as forum shorthand and grew into a social ritual: permission to say the nice thing out loud. The format has moved across forum and social platforms as people look for sincere, specific affirmation.', 'Modern TBH runs on story stickers: a link, a prompt, and a little courage from the sender.']],
      ['Why compliments can land differently', ['A compliment from a known friend carries social accounting — what do they want, what do I owe back? An anonymous TBH removes the visible sender name from that exchange. The recipient can respond to the words rather than the person attached to them.', 'Specificity often gives the recipient more to respond to. "Your energy" is broad; "the way you defended Maya at lunch" names a moment. Prompt for details, then judge the replies that actually arrive.']],
      ['The anatomy of a useful TBH prompt', ['A focused prompt gives senders a clear shape: a topic (energy, style, courage), a frame (TBH or confession), and a boundary. "TBH about my red flags — be honest but kind" tells someone what kind of message to write; "send tbh" leaves more of the interpretation to them.', 'Rotate prompts when one starts to feel repetitive. Fresh wording can help, but no wording guarantees more taps.']],
      ['TBH etiquette for senders', ['Be specific, be kind on purpose, and never use anonymity as a weapon — recipients can filter, block, and report, and the good senders protect the ritual for everyone. If you would not sign it, reconsider sending it.', 'The golden test: would the recipient screenshot this proudly? Aim there.']],
      ['From receiving to ritual', ['A thoughtful reply gives a sender a reason to visit the link again, but it does not guarantee a return. Reply double-blind when useful and use the Daily Drop for a fresh local prompt each day.', 'A small ritual still needs a realistic response routine. Choose a window you can protect, review the messages that deserve care, and let the rest wait until the next check.']],
    ],
  },
  {
    slug: 'word-filters-mastery', cat: 'safety', tags: ['Safety', 'Moderation'], query: 'shield protection security',
    feature: 'moderation', title: 'Word Filters, Mastered',
    secs: [
      ['What filters actually do', ['Every incoming message is scanned server-side against your list before delivery. Matches do not vanish — on standard strictness they wait in your filtered tray with the reason attached, so you approve what is fair and discard what is not.', 'Nobody is told what tripped: not the sender, not the word, not the rule. That silence is load-bearing — naming the rule would let senders probe around it.']],
      ['Building a list that works', ['Start with your five non-negotiables — the words that ruin your day on sight. Add variants over time as the tray shows you what is actually arriving. Review the tray weekly at first, monthly once it stabilizes.', 'Resist the urge to filter emotions instead of abuse. "hate" is a filter; "disagree" is a conversation. Over-filtering starves the inbox you built the board to fill.']],
      ['Standard vs strict, honestly', ['Standard quarantines a match and returns a generic success response to the sender. Strict returns a generic rejection and still quarantines the message for the recipient’s review. Both modes can produce false positives, and neither understands context or provides comprehensive abuse detection.', 'Off skips hidden-word checks entirely. Choose the mode that matches the board, review held messages regularly, and remember that filters are only one part of handling abuse.']],
      ['Filters plus pause plus block', ['Filters handle words, pause handles volume, blocks handle people. A bad week usually needs pause, not a longer word list. A repeat offender needs a block, not a filter. Match the tool to the problem and each stays sharp.', 'Reports are the fourth lever: use them when behavior, not content, is the issue.']],
      ['The monthly five-minute audit', ['Open the tray, scan what was caught, delete the junk, approve the edge cases, add any new repeat offender to the list, and check strictness still matches your life. Five minutes, once a month, and the system stays invisible the way good infrastructure should.']],
    ],
  },
  {
    slug: 'streaks-that-stick', cat: 'product', tags: ['Streaks', 'Ritual'], query: 'fire flame energy',
    feature: 'drops', title: 'Streaks That Actually Stick',
    secs: [
      ['Why streaks can work on brains', ['A visible count turns a vague intention such as "check in more" into a concrete daily action. That can make the next check-in easier to remember, especially when the app has something useful to show.', 'The practical caveat: a streak does not create value by itself. If refreshing the inbox feels pointless, change the prompt or response habit first. The streak should record a useful ritual, not replace one.']],
      ['The anatomy of our streaks', ['A successful authenticated inbox refresh counts as a check-in — no tasks are required. Consecutive local calendar days grow the flame; a miss normally resets it, while one banked freeze can preserve it.', 'Each newly reached 7-day milestone can earn a freeze, up to one stored at a time. The feature adds a little forgiveness; it does not guarantee a long streak.']],
      ['Designing your unmissable day', ['Anchor the check-in to something you already do: morning coffee, the commute, or lights-out scrolling. Enable the nightly nudge if a 9:30pm reminder fits your routine.', 'Pair it with the Daily Drop: open the prompt, check the inbox, and answer what deserves care. Small routines are easier to repeat than an ambitious setup.']],
      ['When streaks break anyway', ['Life happens — travel, illness, dead batteries. Without a banked freeze, the next successful check-in starts a new count at one. The current app does not expose a supporter streak-repair control, so do not plan around a repair that is not available.', 'Treat a reset as a prompt to make the habit easier, not a verdict. A useful inbox and a realistic reminder matter more than pretending the old count survived.']],
      ['Streaks as social proof', ['A long streak can signal that someone is still checking the app, but it does not prove how often they read or reply. Share a milestone only if it fits your profile; do not treat a flame as an engagement metric.']],
    ],
  },
  {
    slug: 'double-blind-replies', cat: 'product', tags: ['Replies', 'Privacy'], query: 'secret letter envelope',
    feature: 'inbox', title: 'Double-Blind Replies, Demystified',
    secs: [
      ['The problem with answering', ['Replies create a reason to return, but a visible username, thread, or tell can make an answer feel exposed. Double-blind replies are designed for that tradeoff: the sender does not receive the recipient’s account identity.', 'The flow keeps a conversation available without making either side’s name the other side’s profile. The server still processes and stores the message and reply so it can deliver them.']],
      ['How blind reply links work', ['Each message carries a reply token — a long random string handed to the original sender. Your answer attaches to that token, not to a sender profile. When the sender checks the private link, the service returns the message and reply without showing a recipient identity.', 'Senders do not create accounts, and the reply link has no public profile attached. This is anonymity from the other participant’s view, not a promise that the service cannot read or retain the content.']],
      ['Replying well is a skill', ['Answer the message that was sent, not the one you wish arrived. Short replies can be useful; specific replies give the sender something concrete to respond to. A single thoughtful sentence is often easier to answer than a paragraph of filler.', 'Set a rhythm: clear the inbox at a predictable time, pin the keepers, and use private double-blind replies when you want to answer without publishing a response to the board.']],
      ['What senders see', ['From their side: a private link containing the original message and your reply, without a recipient identity. The current link is for viewing the reply; it is not a public conversation thread or a second composer.', 'Treat the link like a private handoff. Keep it if you want to preserve the exchange, and remember that deleting the message removes the stored thread from the service.']],
      ['Edge cases, handled', ['A paused board rejects new submissions; it does not queue a sender’s message. Deleting a message removes its stored reply data. A recipient-specific block stores the message’s hashed mobile sender value when one is present, so future messages from that app-generated value are rejected for that recipient only.']],
    ],
  },
  {
    slug: 'story-stickers-that-convert', cat: 'growth', tags: ['Growth', 'Stickers'], query: 'phone social media story',
    feature: 'stickers', title: 'Story Stickers That Actually Convert',
    secs: [
      ['Your sticker is a landing page', ['The sticker carries the invitation: the hook, the handle, the destination, and the QR code. Make the question easy to read and the link easy to find, then test whether the card makes sense at phone size.', 'A specific question plus a visible handle and one visual idea gives viewers a clearer choice than a generic "ask me anything" card, but the response still depends on your audience.']],
      ['Anatomy of a clear card', ['Top: your avatar and handle link, kept legible. Middle: one question in a readable text size. The QR code appears at the top-right of the generated card for screenshot-and-scan use. Background: a theme with enough contrast for the text to remain readable on a phone.', 'Safe-area presets exist because platforms place controls near the edges: Instagram uses a side rail, TikTok uses a larger lower area, and Snapchat uses the upper area. Design inside the guides, not the canvas.']],
      ['Caption strategy in thirty seconds', ['Use a preset from Ideas or write one specific sentence: "TBH about my cooking — destroy me kindly" gives a sender more context than "send tbhs". Rotate captions with your sticker theme when the same wording starts to feel repetitive.', 'Keep the wording aligned with the invitation you want. A clear caption is easier to test than a decorative one, and your own replies are the best guide to what people understand.']],
      ['Posting cadence that compounds', ['Space stickers so each one has a clear moment to be seen. The recents tray makes resharing a recent card easy, while leaving enough time between posts can help you notice which question gets understood.', 'Watch which cards pull replies and compare their structure — same layout skeleton, new question. A repeatable format is more useful than a claim about a perfect posting time.']],
      ['Measure, then double down', ['Count replies per sticker, not views. Views flatter; replies pay. When a format wins three times running, it graduates from experiment to house style — give it a name and reuse it shamelessly.']],
    ],
  },
  {
    slug: 'dice-roulette-guide', cat: 'product', tags: ['Dice', 'Prompts'], query: 'dice game neon',
    feature: 'dice', title: 'The Dice Roulette Playbook',
    secs: [
      ['Why randomness beats choice', ['Decision fatigue kills more prompts than bad taste does. Staring at nine thousand questions, you will pick none; letting the dice pick, you will send one. Randomness is a commitment device wearing a casino costume.', 'The roll ritual also front-loads fun into an otherwise blank moment — the tumble, the tick sounds, the reveal. Play is a feature, not decoration.']],
      ['Playing it right', ['Pick a vibe first — the categories are moods, not topics. Roll until something makes you grin; that grin is your audience grinning in advance. Copy it, or fire it straight into the composer with one tap.', 'Keep recent rolls: yesterday winner often beats today random. The history tray is a greatest-hits album you did not have to compile.']],
      ['The composer loop', ['A landed prompt is half a message. "Use in composer" prefills the draft; you add the recipient and send. The route is direct, but Turnstile and network conditions still affect delivery.', 'Roll a few prompts, send the one that fits, and keep the others in your notes. The feature gives you a starting point; the message is still yours to write.']],
      ['Sound, haptics, and feel', ['Ticks while tumbling, a chime on landing, a thud you feel — the dice is tuned like an instrument. Mute it in the header if you roll in libraries; everyone else should leave the theater on.', 'The reveal springs in with overshoot physics because flat fades feel like loading screens. Feelings ship features.']],
      ['Nine thousand prompts, with room to repeat', ['The pool spans crushes, chaos, 3am thoughts, real talk, spice, and secrets — 1,500 each. Categories keep rolls relevant; All Vibes mixes them together. Random selection can repeat a prompt, so roll history and the composer handoff are there to help you move on.']],
    ],
  },
  {
    slug: 'pause-like-a-pro', cat: 'safety', tags: ['Safety', 'Boundaries'], query: 'peaceful break relax',
    feature: 'moderation', title: 'Pause Like a Pro',
    secs: [
      ['Pause is not surrender', ['An always-on inbox can need an off switch that is not account deletion. Pause submissions is that switch: new sends are rejected while the board is paused, and the profile remains available. Reopening the board allows new submissions again.', 'Use it for weekends, exams, launches, grief, vacations — any stretch where incoming volume exceeds outgoing care.']],
      ['Choosing your duration', ['The app offers 30 minutes, one hour, 24 hours, one week, permanent pause, or an active link. A timed pause automatically ends at its stored time; a permanent pause stays paused until you reactivate it.', 'Permanent pause is for boards in cold storage: the link lives, submissions are rejected, and you return whenever.']],
      ['What senders experience', ['The profile can remain visible while the API rejects a new submission with a board-is-paused response. A sender can return after reopening, but SecretMsg does not queue a message for later delivery.', 'If you need to accept messages without interruptions, leave the board active and use hidden words, blocking, or reporting for unwanted submissions.']],
      ['Pause plus filters: the combo', ['Pause handles volume; filters handle content. A bad week usually wants the former, a bad actor the latter. Reaching for the wrong tool — nuking your word list during a busy spell — creates work without relief.', 'Audit quarterly: is the pause still on? Did the trip end three weeks ago? Reopen and feel the inbox breathe again.']],
      ['The psychology of the break', ['Guilt is the main reason pauses stay on too long. Reframe it: a paused inbox is a maintained inbox. The senders worth keeping will still be there, and the messages will be better for the wait.']],
    ],
  },
  {
    slug: 'supporter-perks-tour', cat: 'product', tags: ['Supporters', 'Perks'], query: 'golden badge premium',
    feature: 'supporters', title: 'Every Supporter Perk, Explained',
    secs: [
      ['Why perks exist at all', ['Servers, push infrastructure, and app operations cost money. Supporters help cover those costs, and eligible extras are the thank-you. The message, inbox, filter, block, report, and reply features are available without a supporter purchase.', 'Pricing and eligible perks can change, so check the current checkout rather than relying on a permanent promise. The current app verifies Play purchases server-side before granting supported perks.']],
      ['Badges and supporter status', ['A supporter badge reflects a verified grant on the account. The current app can show a supporter tier such as Coffee Backer, Silver Patron, or another grant recorded by a qualifying contribution.', 'Treat the badge as account status, not a promise of extra reach. The app does not provide a public follower count or a guaranteed distribution boost.']],
      ['Sender hints, carefully scoped', ['A sender hint is a coarse platform clue such as "Mobile / Android" or "Web Browser." It appears only when the sender opts in and the recipient has the sender-hints entitlement; it is not a name, location, or unique identity.', 'The mobile app can generate a stable installation value whose SHA-256 hash is stored for a message and, when blocked, in that recipient’s list. The server does not reverse the hash into a person.']],
      ['Custom usernames', ['If the account has the custom-slug entitlement, the app lets its owner request a different handle. The endpoint checks availability and updates the public link, so an old link is not guaranteed to remain the address after a change.', 'Treat the handle as a public choice: it is unique at claim time, and the app does not promise that every username can be claimed or that the link is permanent.']],
      ['How backing works', ['Android purchases use Google Play Billing and the server verifies the purchase token before granting the supported perk. A Polar contribution is recorded only through a verified webhook, and any eligible account grant is applied server-side.', 'The available checkout and the exact grant vary by path. Do not treat a supporter badge, custom handle, or hint as automatically included in every contribution; check the current checkout and your account settings.']],
    ],
  },
  {
    slug: 'offline-mode-guide', cat: 'product', tags: ['Offline', 'App'], query: 'airplane travel phone',
    feature: 'app', title: 'The Offline Outbox, Explained',
    secs: [
      ['The subway test', ['Every app works on wifi. The good ones work in tunnels. SecretMsg queues sends, replies, approvals, discards, and reports made offline, then drains them in order when you reconnect — with a visible sync row, never silent magic.', 'Drafts and local streak state stay on the device, but a new authenticated check-in still needs a connection. The ritual can survive dead zones without pretending every action is available offline.']],
      ['How queuing actually works', ['The app keeps a local FIFO outbox for the actions it supports. Message sends include a client message ID so a retry can resolve to the original row; other actions are designed to converge when repeated, but they do not all share one server-side idempotency key.', 'A network error pauses the drain and resumes after connectivity returns. A send that cannot pass the send-time Turnstile check is handed back to the composer for a fresh challenge rather than silently retried forever.']],
      ['The verification exception', ['Turnstile verification cannot be completed offline. A queued send that reaches a send-time verification failure is handed back to the composer with its text intact so you can complete a fresh challenge.', 'The visible sync row tells you when an action is queued, blocked, or needs attention. That status is about this device’s outbox, not a guarantee that every service is available offline.']],
      ['Reading while offline', ['The last saved inbox and filtered-tray snapshot can render with a staleness label such as "Updated 2h ago". It is cached data, not a live view.', 'When connectivity returns, the app requests a fresh inbox and tray. It does not perform a separate scan-event or message-difference report for the QR sticker.']],
      ['What stays online-only', ['Login, signup, recovery, and the send-time Turnstile check remain server-backed. The offline outbox and cached inbox cover the named actions above; they are not a general promise that every screen or provider works without a connection.']],
    ],
  },
  {
    slug: 'crush-confessions-playbook', cat: 'stories', tags: ['Scenarios', 'Crush'], query: 'romantic couple silhouette',
    feature: 'stickers', title: 'The Crush Confessions Playbook',
    secs: [
      ['Scene one: the story goes up', ['Tuesday, 8:40pm. Maya posts a violet sticker: handle, QR, one line — "TBH about crushes, be gentle." No name, no hints, no @-ing anyone. Cost: forty seconds. The trap is set with velvet ropes.', 'By 9:15 three messages wait. One is from someone who has liked her photos since spring. She does not know that yet. That not-knowing is the entire product.']],
      ['Scene two: the inbox fills', ['Wednesday morning brings four more, including one suspiciously specific compliment about her laugh. The filtered tray catches one Boundary-pusher ("overall rating out of 10??") — reviewed, discarded, sender none the wiser.', 'She pins the laugh one. Pins are bookmarks for feelings.']],
      ['Scene three: the double-blind reply', ['She answers the laugh message: "whoever you are, you made my week." The sender gets a private link, reads it between classes, and — this is the compounding part — sends a second, braver message that evening.', 'Replies are retention machines wearing romance costumes.']],
      ['What made it work', ['Specific prompt, evening timing, answered everything, pinned the keeper. Four moves, all repeatable, none requiring a public identity from the sender. The exact time and response volume will vary.', 'Maya can keep the loop going without knowing who sent each message. Community, assembled one anonymous message at a time.']],
      ['Steal this exact setup', ['Copy the sticker text verbatim, swap the vibe to Crush & Admirer, post at 8:30pm, reply before bed. Report back — anonymously, obviously.']],
    ],
  },
  {
    slug: 'workplace-feedback-anonymously', cat: 'stories', tags: ['Scenarios', 'Work'], query: 'office team meeting',
    feature: 'inbox', title: 'Workplace Feedback Without the Fallout',
    secs: [
      ['The retro nobody speaks at', ['Teams often have a meeting where honesty would help and silence wins. An anonymous board can make it easier to critique an idea without attaching your name to it, though the content itself can still reveal context.', 'A team can try this as a small experiment with a clear topic and a private link. Keep the scope narrow, explain the rules, and decide what will happen with the feedback before asking for it.']],
      ['Setting it up right', ['Dedicated board, professional display name, clear prompt: "TBH on our deploy process — blunt is welcome, cruel is filtered." Seed the word filter with the obvious landmines before sharing the link.', 'Share in the team channel Friday morning; review the tray Monday. Cadence beats intensity.']],
      ['Reading like a manager', ['Sort signal from sting: filter for actionable nouns (process, meeting, deploy), approve the fair ones, discard the venting. Reply double-blind to useful critiques so the sender receives an answer.', 'Publish a periodic "you said, we did" note. Anonymous input still needs a visible follow-up plan if the team wants the loop to continue.']],
      ['The guardrails that matter', ['Strict mode rejects matching sends while still holding them for the recipient’s review; standard quarantines matches for review. Pause submissions when a board needs a break, and tell the team what reporting can and cannot do: it records a reason and quarantines the message for review.', 'Anonymity at work requires more structure, not less. The structure is the product.']],
      ['What to change next', ['Look for recurring themes, decide which follow-up belongs to the team, and keep the board’s rules visible. Anonymity can lower the cost of speaking up, but it does not remove the work of responding.']],
    ],
  },
  {
    slug: 'birthday-board-guide', cat: 'seasonal', tags: ['Seasonal', 'Celebration'], query: 'birthday party confetti',
    feature: 'stickers', title: 'The Birthday Board: A Month of Proof',
    secs: [
      ['The setup', ['Two weeks before the date, post a sticker: "TBH about the birthday human — best memory wins." Friends need lead time; memories need prompting. Generic "send birthday wishes" gets generic wishes.', 'Pin the board link in the group chat so latecomers find it without asking.']],
      ['Harvesting season', ['Messages may arrive at different times as the story gets shared. Answer a few double-blind replies when they fit the occasion; the app does not measure or promise a particular arrival pattern.', 'The filtered tray earns its keep here: birthday roasts walk a line, and you decide exactly where yours sits.']],
      ['The reveal', ['Save the keepers as screenshots, read a few aloud at the party, and let the room react. Anonymous praise can land differently when it is spoken, but the board does not add app badges to message screenshots.', 'Keep one message pinned if you want it easy to find later. Future rough days can have an antidote on file.']],
      ['Why it can beat a group card', ['Group cards collect signatures; boards collect sentences. A paragraph from someone who rarely comments publicly can give the occasion more texture than a short reaction, depending on the audience.', 'Next year, the board already exists. You can decide whether the ritual is worth continuing.']],
      ['Calendar notes', ['Same playbook ports to graduations, farewells, weddings, and new-baby season. Any event with feelings and a guest list is a board waiting to happen.']],
    ],
  },
  {
    slug: 'new-year-reflection-board', cat: 'seasonal', tags: ['Seasonal', 'Reflection'], query: 'new year fireworks night',
    feature: 'drops', title: 'New Year, Honest Answers',
    secs: [
      ['Late December energy', ['People may be reflective near the end of the year. Give them somewhere to say it out loud: "TBH — what should I leave in 2026?" Post between Christmas and New Year if that timing fits your audience.', 'A specific reflection prompt gives people more to answer than a generic "send TBH" invitation. Test the timing rather than assuming a seasonal increase.']],
      ['Prompts that land', ['"One thing I did this year you admired?" "What should I stop pretending about?" "Rate my 2026 glow-up honestly." Each invites a story, not a score — stories are what get screenshotted and remembered.', 'Rotate one per day through the final week. Scarcity plus occasion beats a single mega-post.']],
      ['Answering in public (sort of)', ['Use double-blind replies for the gems and keep the tender ones private. The current app does not publish a shared response feed; if you want a recap, save the messages and share your own summary elsewhere.', 'On January first, pin the single message that describes who you are becoming. Let it headline the new year.']],
      ['The group version', ['Friend groups can use several overlapping boards: one person posts, another replies, and the group chat keeps the ritual moving. The app does not create a shared group account, so somebody still has to manage the links and replies.', 'SecretMsg groups are just overlapping boards. The overlap is the party.']],
      ['Carrying it forward', ['Save the keepers somewhere permanent. Next December, repost the best prompt with last year answers as bait. Traditions are just good ideas on a schedule.']],
    ],
  },
  {
    slug: 'valentines-tbh-guide', cat: 'seasonal', tags: ['Seasonal', 'Crush'], query: 'valentine hearts romance',
    feature: 'stickers', title: 'Valentine\'s Week TBH Guide',
    secs: [
      ['A prompt with some romantic stakes', ['February can make anonymous crush prompts feel especially timely for some people. A clear invitation may turn that mood into messages, but the app does not measure a seasonal increase in courage or guarantee more sends.', 'Post when your audience is likely to see it; the brave may need runway, and the shy may want a little context first.']],
      ['Prompts calibrated by nerve', ['Low nerve: "TBH about love in general." Medium: "TBH — secret admirer check-in." Maximum: "If you like me, send a 💘 and nothing else." Tiered prompts let every courage level participate.', 'Candy theme, obviously. Aesthetics are load-bearing in February.']],
      ['Reading the results', ['A 💘 with no words still counts — it is the lowest-risk signal ever designed, and its ambiguity is the feature. Specific messages deserve answers; emoji deserve a knowing pin.', 'Do not interrogate the inbox for identities. The mystery is doing romantic work; let it work.']],
      ['After the 14th', ['Whatever arrived, answer kindly when you choose to respond. A thoughtful reply can preserve the tone of the exchange without promising a particular future outcome.', 'Keep the board up through the weekend if you want to accept more messages; a pause will reject new submissions until the board is active again.']],
      ['For the happily attached', ['Couples run boards too: "TBH about us" from mutual friends is a chaos engine of joy. Share the highlights, laugh together, pin the unhinged-but-loving ones.']],
    ],
  },
  {
    slug: 'halloween-confessions', cat: 'seasonal', tags: ['Seasonal', 'Fun'], query: 'halloween spooky night',
    feature: 'dice', title: 'Halloween Confessions Season',
    secs: [
      ['Spooky season is confession season', ['Costumes and anonymous links can change the tone of a conversation. October may be a good time to try a themed prompt and the darkest sticker theme you own; the app does not track a monthly usage peak for the dice categories.', 'Obsidian theme exists for exactly this kind of seasonal prompt. You are welcome.']],
      ['Prompts from the crypt', ['"Confess your most unhinged costume idea." "TBH — your villain origin story." "Spiciest take you would never say sober." Roll the dice on spicy + secrets and post whatever lands, while keeping the community boundary clear.', 'Add a roast-kindly instruction to the prompt rather than assuming a special moderation mode. The app has hidden-word filtering, pause, blocking, and reporting; it does not grant the holiday any safety exemption.']],
      ['Costume feedback machine', ['Post costume options as sticker captions and let the inbox vote. Anonymous crowds are brutally honest about fit, theme, and effort — better to hear it Tuesday than wear it Saturday.', 'Run the finalists as a dice category all week. Democracy, but fun.']],
      ['The morning after', ['November first, clear the tray with prejudice and pin the legends. Halloween messages age like jack-o-lanterns — glorious for a week, then compost.', 'Screenshot the keepers before the purge. Some confessions deserve files.']],
      ['Year-round lesson', ['October proves the thesis: lower the stakes of honesty and honesty floods in. Costumes do it with fabric; your board does it with anonymity. Run a mini-Halloween quarterly.']],
    ],
  },
  {
    slug: 'reply-game-strong', cat: 'guides', tags: ['Replies', 'Guide'], query: 'typing message chat',
    feature: 'inbox', title: 'A Strong Reply Game',
    secs: [
      ['Speed can help', ['A reply gives a sender a response to return to; timing still depends on the person and the situation. Double-blind replies are short to compose, but the time to write a good one varies.', 'Batch the habit: inbox, reply to what deserves an answer, pin one, done. Rhythm beats marathons.']],
      ['Specificity over volume', ['One sentence that shows you read the message can be more useful than several generic thank-yous. Refer to the detail, or ask one focused follow-up. Senders may be able to tell whether a person engaged or a habit fired.', 'Specific replies may be easier to remember, but the app does not track screenshots, shares, or replies to future sends.']],
      ['When not to reply', ['Cruelty gets deleted, not debated. Bait gets ignored, not fed. Vague one-worders can wait for a better day. Replying is a gift; spend it where it compounds and withhold it where it drains.', 'The filtered tray exists precisely so "no reply" is a decision, not an accident.']],
      ['Private replies, used consistently', ['Double-blind replies let you answer without turning the inbox into a public broadcast. Keep the rhythm realistic, and reserve replies for messages that deserve a response.', 'Pick messages that teach: great questions, kind answers, funny exchanges. Curate like a gallery, not a feed.']],
      ['Closing loops kindly', ['A graceful close ("thanks for trusting me with that") can keep the exchange respectful. It may make a sender more comfortable returning, but no reply format guarantees a return.', 'Keep the rules and follow-through consistent. That is more useful than claiming an invisible reputation metric.']],
    ],
  },
  {
    slug: 'backup-codes-survival', cat: 'guides', tags: ['Guide', 'Account'], query: 'safe lock security',
    feature: 'app', title: 'Backup Codes Survival Guide',
    secs: [
      ['Why codes exist', ['No email, no password reset link, no support agent who can verify your soul. Your PIN plus backup codes ARE your account — if you lose both, the server cannot distinguish you from an attacker and cannot recover the account.', 'This is a recovery design choice, not a promise of anonymity. Account credentials are handled separately from the sender identity that a message sender may provide.']],
      ['The two-minute setup that saves accounts', ['Screenshot the codes the moment they appear, or use the app’s Save .txt option and move the file somewhere you trust. Keep a second copy in a secure password manager if that is part of your threat model; do not leave backup codes in an ordinary photo album.', 'Testing a recovery consumes a code and rotates the set. If you test, save the fresh codes immediately and confirm you can still sign in before relying on the backup.']],
      ['PIN hygiene without paranoia', ['Pick a PIN you do not use for your bank or bike lock — uniqueness matters more than complexity here. Change it yearly or after any shoulder-surfing scare; rotation takes thirty seconds in settings.', 'Never share codes or PINs, even with people you trust with everything else. Trust is not the issue; screenshots and leaks are.']],
      ['Recovery, step by step', ['Handle plus one unused code plus a new PIN: that is the entire ceremony. Each code works once, then burns — the survivors stay valid, so partial loss is survivable.', 'After recovering, save the FRESH codes immediately. Recovery rotates the set, and yesterday screenshots become history.']],
      ['The account you cannot lose', ['For boards that matter — creators, teams, long streaks — treat codes like travel documents: stored before departure, checked before every trip. The time it takes is small, but no backup routine can guarantee that nothing will go wrong.', 'If a trusted person knows where a secure copy lives, do not give them the codes or PIN themselves. The app cannot restore a set that has been lost or exposed.']],
    ],
  },
  {
    slug: 'handle-psychology', cat: 'culture', tags: ['Culture', 'Identity'], query: 'neon name sign',
    feature: 'supporters', title: 'The Psychology of Handles',
    secs: [
      ['Names are promises', ['A handle tells senders what kind of honesty lives here before a single message arrives. Auto-generated word-number handles (lumen4821 and friends) promise playfulness and low stakes; chosen names promise identity and continuity.', 'Neither is better. They are different doors into the same room — pick the door your audience wants to walk through.']],
      ['Why random handles work', ['Randomness removes a naming decision from the first setup. A generated handle like lumen4821 can keep attention on the messages instead of branding.', 'There is no built-in claim that generated handles make a board go live faster. If a chosen name matters, the custom-slug entitlement lets an eligible account change its handle; the current link changes with it.']],
      ['When to claim a custom name', ['Claim when the link leaves the app: bios, business cards, team docs, or creator profiles. A clean name can be easier to remember when the handle is shared outside SecretMsg.', 'The account must already have the custom-slug entitlement, and the current endpoint allows a later change when another valid name is available. Do not promise a one-time or permanent address.']],
      ['Display names vs handles', ['Your handle is the address; your display name is the face. Change the face freely as seasons change — the address stays put so every old link keeps working.', 'Cute today, professional tomorrow, mysterious on weekends. The name is a costume; the handle is the house.']],
      ['The avatar completes the promise', ['Generative avatars give faceless boards a face without surrendering anonymity: deterministic, unique per account, changeable on whim. Humans trust faces, even algorithmic ones.', 'Shuffle until it feels like you. You will know it when the preview makes you grin.']],
    ],
  },
  {
    slug: 'notification-zen', cat: 'product', tags: ['Notifications', 'Balance'], query: 'phone notification calm',
    feature: 'app', title: 'Notification Zen',
    secs: [
      ['Every ping spends trust', ['Notifications are a loan against attention: useful ones can be welcome, noisy ones can send you to the off switch. The app separates new-message alerts, Daily Drop reminders, streak nudges, weekly tray review, and milestone reminders so you can tune them.', 'FCM receives a message ID, unread count, and a server-truncated preview of up to 140 characters for a new message. Full message bodies do not travel through FCM, but a preview can still appear on the lock screen.']],
      ['The three that earn their place', ['New-message alerts with inline reply: the core loop, actionable without opening anything. Daily Drop reminders: morning card, evening expiry nudge — the ritual engine. Streak nightlies: one line before bed, only while a streak lives.', 'Everything else waits inside the app. If it can wait until morning, it does.']],
      ['Tuning to your life', ['The streak nudge is scheduled for 9:30pm local when the current state calls for it. Busy season? Pause submissions; new sends will be rejected until the board is active again, while existing inbox notifications remain under your device settings.', 'Per-type toggles live in settings, each with a plain-English description. The app does not promise a custom bedtime, a message digest, or a re-opt-in maze after updates.']],
      ['Quiet hours are sacred', ['The local ritual scheduler avoids its 10pm–8am quiet window, but that setting does not silence every FCM message notification. Android notification channels and the device’s own settings determine whether a new-message alert is shown.', 'If the building is on fire, call someone — do not wait for a push.']],
      ['When to go silent deliberately', ['Vacations, exams, heartbreaks: pause submissions and use the device notification settings when you want fewer interruptions. Paused submissions are rejected rather than accumulated for later delivery.', 'When you return, read the saved inbox and reply in one calm sitting. The app has a weekly filtered-tray review, not a general message digest.']],
    ],
  },
  {
    slug: 'block-without-drama', cat: 'safety', tags: ['Safety', 'Blocking'], query: 'calm boundary fence',
    feature: 'moderation', title: 'Blocking Without Drama',
    secs: [
      ['The quietest superpower', ['When a mobile message has an app-generated sender value, blocking stores its hash in the recipient’s block list and removes that message. The API does not reveal a name or a global block status; browser senders without that value are not added to the fingerprint list.', 'The block is recipient-specific. It can stop future submissions carrying the same hashed app value for that recipient, but it is not a network-wide ban or a human account judgment.']],
      ['When to block vs filter vs pause', ['Block people (repeat offenders, boundary-pushers, bad-faith actors). Filter words (topics that ruin your day regardless of author). Pause everything (volume exceeds capacity). Three tools, three problems — using the right one keeps each effective.', 'Blocking a word problem leaves the person; filtering a person problem leaves the behavior. Diagnose first, tap second.']],
      ['What blocked senders experience', ['Nothing. Their messages simply stop delivering, indistinguishable from a quiet board or a paused week. There is no appeal flow because there is no accusation — just absence.', 'This design choice is deliberate: observable blocks teach harassers to rotate devices. Unobservable ones just... stop working.']],
      ['Managing the list', ['Review blocked fingerprints in settings. Unblock when the context changes and the list has a clear reason to keep the hash. The list is a recipient control, not a permanent grudge.', 'Pair with reports when you need a reason recorded. A report quarantines that message and stores the reason, but it does not automatically protect every other inbox.']],
      ['The philosophy in one line', ['You owe strangers nothing, regulars warmth, and harassers silence. The tooling just makes each response one tap instead of one ordeal.']],
    ],
  },
  {
    slug: 'graduation-farewell-board', cat: 'seasonal', tags: ['Seasonal', 'Milestones'], query: 'graduation caps celebration',
    feature: 'stickers', title: 'Graduation & Farewell Boards',
    secs: [
      ['Endings deserve archives', ['Graduations, last days, moving trucks: these are peak candor moments wrapped in deadlines. A farewell board converts hallway hugs into paragraphs people keep for decades.', 'Start two weeks out. Goodbyes need lead time; the best messages arrive after days of quiet drafting.']],
      ['Prompts for the occasion', ['"TBH — favorite memory of us?" "One thing I will never forget about this place?" "Roast me fondly, one last time." Specific, warm, and structured enough to give senders a starting point.', 'Theme it like the event with one of the available Sticker Studio themes, such as the paper theme for yearbook energy. The app does not provide custom event gradients.']],
      ['The group effect', ['Farewells can compound when each shared sticker gives the next person a reason to respond. Pin the board link in the relevant chats and decide when the final reminder should go out.', 'Read a selection aloud at the actual goodbye. Anonymous praise can land as a group moment, but the app does not promise consensus or a particular response rate.']],
      ['After everyone scatters', ['Save screenshots of the keepers before closing anything. A saved set can remain useful after a platform migration, but the app has no message-export feature for a whole board.', 'Keep the board active or pause submissions through the first year according to your boundary. A paused board rejects new messages rather than storing them for an anniversary.']],
      ['Beyond graduation', ['Retirements, team departures, end-of-season, moving abroad: the pattern ports to every ending with feelings and witnesses. Endings are content; boards are the archive.']],
    ],
  },
  {
    slug: 'summer-break-boards', cat: 'seasonal', tags: ['Seasonal', 'Summer'], query: 'summer beach friends',
    feature: 'drops', title: 'Summer Break Boards',
    secs: [
      ['Distance makes inboxes grow fonder', ['Scattered for summer? A board can become a low-scheduling group hangout: post prompts, check replies across time zones, and keep a local streak going when the app is available.', 'Summer prompts write themselves: ratings of beach reads, confession season, glow-up predictions for fall.']],
      ['The summer prompt calendar', ['June: predictions and dares. July: confessions and ratings. August: nostalgia and "what changed" retrospectives. One vibe per week keeps it fresh without daily labor.', 'Sunset sticker themes suit golden-hour stories. Use them all season if the color fits your invitation.']],
      ['Camp, travel, and patchy wifi', ['The offline outbox can queue supported replies, sends, approvals, discards, and reports made during a network failure, then drains them when connectivity returns. Streak freezes can cover one missed day when available.', 'Time zones are a feature: wake to messages written while you slept, like letters from the future.']],
      ['Reunion fuel', ['Screenshot the summer highlights (tastefully) and read them at the reunion. A shared set of messages can make the reunion more personal than a generic slideshow.', 'Keep one thread running all summer: "song of the summer, with reasons." Playlists plus justifications equal anthropology.']],
      ['September payoff', ['Return with receipts: the funniest, kindest, and most memorable messages of the season, shared only when the sender is comfortable. Summer boards can become a shared story for the group.']],
    ],
  },
  {
    slug: 'exam-season-support', cat: 'seasonal', tags: ['Seasonal', 'Support'], query: 'students studying library',
    feature: 'inbox', title: 'Exam Season Support Boards',
    secs: [
      ['Stress loves an audience', ['Exam weeks can concentrate anxiety for some people, and a support board gives them a place to name it. A clear prompt can invite shared encouragement without pretending every reply will help.', 'Prompt it well: "TBH about finals week fears" gives people more to answer than "send messages".']],
      ['Study break rituals', ['Post the board link with library hours: "procrastinating? send a TBH instead of refreshing grades." A short message exchange can give someone a break, but it does not replace rest, study support, or a real safety plan.', 'Evening drops can fit a study schedule — prompt at dinner, then review replies when you are ready. The app schedules reminders locally; it does not promise replies by midnight.']],
      ['Anonymous pep talks can feel different', ['"You have never failed anything that mattered" may land differently from a stranger than from someone performing optimism. Anonymity can lower the social pressure attached to encouragement.', 'Reply to the scared ones double-blind when that feels appropriate. One sentence can be useful, but the app cannot promise that it will change someone’s night.']],
      ['Boundaries during crunch', ['Pause submissions during actual exam hours — new sends are rejected while the board is paused, and focus can stay with the exam. Word-filter terms such as "fail" or "drop out" into the tray for review when that is useful.', 'Protect sleep like a subject: adjust notifications, review the inbox when you are ready, and remember that a paused board does not hold submissions for later.']],
      ['After the last paper', ['Flip the board to celebration mode: predictions, roasts, summer plans. The same link that absorbed stress now collects joy — full circle in one URL.', 'Keep the kindest messages. Future hard weeks accept them as currency.']],
    ],
  },
  {
    slug: 'wedding-party-board', cat: 'seasonal', tags: ['Seasonal', 'Events'], query: 'wedding celebration dance',
    feature: 'stickers', title: 'Wedding & Party Boards',
    secs: [
      ['The guest book, upgraded', ['Paper guest books collect signatures; boards collect stories. "TBH about the couple" and "roast the best man kindly" can produce keepsakes that stationery does not.', 'QR on the sticker, QR on the tables. Some guests will scan a code; others will need the link printed beside it.']],
      ['Running it on the day', ['Appoint one keeper: they post the sticker to their story, monitor the tray between courses, and pin the legends for the evening readout. Technology needs a human with a charged phone.', 'Strict mode during toasts (no heckling the speeches), standard during dancing (heckling encouraged, kindly).']],
      ['Prompts for every table', ['Childhood friends: "most legendary story, names redacted." Colleagues: "roast them professionally." Family: "marriage advice, anonymous and therefore honest." Different crowds, different prompts, one board.', 'The couple answers a few double-blind during dessert. The room goes feral. Trust us.']],
      ['The morning-after artifact', ['Save the keepers before the honeymoon haze: the roasts can become lore, and the kind ones can become framing-worthy. The app does not provide a bulk message-export feature, so use screenshots or your own archive.', 'One board can collect the occasion in one place, but it is not automatically permanent. Save what matters before deleting the account or message.']],
      ['Beyond weddings', ['Baby showers, milestone birthdays, retirements, housewarmings: any gathering with love and witnesses. The pattern is universal — prompt, collect, reveal, keep.']],
    ],
  },
  {
    slug: 'fitness-accountability-board', cat: 'stories', tags: ['Scenarios', 'Habits'], query: 'running fitness sunrise',
    feature: 'drops', title: 'Fitness Accountability, Anonymously',
    secs: [
      ['Why anonymous accountability works', ['Gym selfies can invite judgment; an anonymous check-in can invite honesty. "Skipped leg day, TBH why I am like this" gives people a way to ask for support without attaching their name.', 'The board can become a place for the fitness journey — struggles included, where the value may live.']],
      ['Structuring the week', ['Monday: intentions ("this week I will..."). Wednesday: midweek honesty check. Friday: wins and wipeouts. Sunday: rest-day reflections. A small set of weekly prompts can make the habit easier to follow than constant novelty.', 'The app streak can mirror a training streak, but it does not measure fitness or guarantee consistency. Two flames, one discipline.']],
      ['The group board advantage', ['Training partners can use one board as a place to post intentions, setbacks, and wins. It does not create a shared public check-in feed; the recipient sees the messages in the private inbox.', 'Add a roast-kindly instruction to the prompt rather than assuming a special mode. Use pause, hidden words, blocking, or reporting when the board needs a boundary.']],
      ['Plateaus and bad weeks', ['Post the slump honestly and let people who have been there answer with what worked for them. Anonymous advice is not automatically better than advice from an identifiable expert; compare it with your own goals and a qualified professional where relevant.', 'Pause submissions during injury recovery. New messages will be rejected while the board is paused; tendons will not.']],
      ['Measuring what matters', ['Count check-ins, not likes. Count honest weeks, not perfect ones. A board that survives a bad month may be more useful than one that looks bright for a week and then disappears.']],
    ],
  },
  {
    slug: 'book-club-anonymous', cat: 'stories', tags: ['Scenarios', 'Community'], query: 'books reading cozy',
    feature: 'inbox', title: 'Anonymous Book Club Boards',
    secs: [
      ['Hot takes need cover', ['"The protagonist annoyed me" is hard to say when the recommender is in the room. Anonymous boards let book clubs be honest about books, which is the entire point of clubs.', 'Spoiler discipline via word filters: filter character names until everyone finishes. Technology serving literature.']],
      ['Running the discussion', ['One prompt per section: predictions at 30%, verdicts at 70%, ratings at 100%. The board becomes a margin-notes layer the whole club shares.', 'Double-blind replies let shy members debate boldly. The quietest reader often has the sharpest take — anonymity finally lets it surface.']],
      ['Author events, upgraded', ['Visiting authors answering anonymous questions can surface questions that people might not ask in a crowded room. "Why did you spare THAT character" can be more specific than "where do you get ideas".', 'Collect questions for a week, curate the best dozen, and run the session. A standing ovation is optional.']],
      ['Between books', ['The gap weeks can cool a club down. A standing prompt ("what are you reading now, honestly?") keeps the board active between picks.', 'Let members pitch next reads with one-line messages. The app does not provide a built-in voting or campaigning feature; collect and compare the pitches yourself.']],
      ['The library effect', ['A year of honest book talk, archived and searchable in memory if not in app: which picks divided the room, which united it, who called the twist on page fifty. Culture, compounded.']],
    ],
  },
  {
    slug: 'creator-fan-boards', cat: 'growth', tags: ['Growth', 'Creators'], query: 'creator camera content',
    feature: 'supporters', title: 'Creator & Fan Boards',
    secs: [
      ['The Q&A your comments wish they were', ['Comment sections reward speed and outrage. Anonymous boards reward curiosity: fans ask what they actually wonder, creators answer what actually matters. Same audience, better conversation.', 'Link it in bio, mention it weekly. Discovery compounds; one mention converts lurkers for months.']],
      ['AMAs without the chaos', ['Collect questions during the week, answer the useful ones in one sitting, and publish a recap elsewhere if you want. The app has no automatic content classifier or live-chat moderation; a hidden-word filter and the filtered tray are recipient-controlled tools.', 'Word filters hold exact matches for review. They do not catch every piece of junk, so review the tray, report concerns, and use boundaries rather than calling the filter comprehensive.']],
      ['Feedback that improves the work', ['"TBH about my latest video" from viewers can add context that an analytics dashboard does not capture. A message may point out something the creator missed, but it is not guaranteed to be useful or correct.', 'Separate boards per series or season can keep feedback organized. Save the keepers between projects; reopen the link with a retrospective prompt when you want another round.']],
      ['Monetizing honesty', ['Supporter contributions can help fund the project, but the available grant depends on the checkout and account. Eligible options can include a supporter badge, sender hints, or a custom username; the app does not automatically give perks to top fans or mods.', 'The supporters wall lists qualifying Polar contributions. Treat a public wall as community information, not a promise of sponsor reach or a guaranteed conversion result.']],
      ['Boundaries at scale', ['Fame, even micro-fame, can attract boundary-pushers. Strict mode rejects matching sends, blocks are recipient-specific, and pause submissions closes the board to new messages until reopened. None of those controls guarantees that a community will be safe.', 'You set the tone once, in the first prompt. Everything after is maintenance.']],
    ],
  },
  {
    slug: 'qr-codes-on-stickers', cat: 'growth', tags: ['Growth', 'Stickers'], query: 'qr code phone scan',
    feature: 'stickers', title: 'QR Codes: Screenshots Into Taps',
    secs: [
      ['The screenshot problem', ['A viewer who screenshots a story card may not have a tappable link. A QR code on the card gives that screenshot another route to the board.', 'Every generated Sticker Studio card carries a QR code automatically. The app does not claim that every viewer will scan it or that scans are automatically measured.']],
      ['Placement that survives platforms', ['The Sticker Studio places the QR code at the top-right of the card and offers platform safe-area guides. Test the result on the platform you use rather than assuming one placement fits every app.', 'Test it yourself before posting: screenshot your own story, scan from another phone, and check that the link opens the board you intended.']],
      ['Print is back, apparently', ['QR stickers work beyond screens: notebooks, lockers, event tables, merch tags. Anywhere eyes linger, a scan converts curiosity into a message.', 'Pair with a one-line prompt on the physical sticker. Context plus code beats code alone.']],
      ['Measuring the invisible', ['Sticker Studio does not emit a scan event or provide scan analytics. The account’s public profile can show a view count through the normal profile lookup, so do not describe QR scans as untrackable in every part of the service.', 'A/B placement across weeks: same prompt, QR at the top-right versus a different layout you create. Let the inbox and your own notes guide the next version.']],
      ['The meta-lesson', ['Reduce the steps between seeing a card and opening the board. A QR code removes the need to type the link, but the service cannot predict how many people will take that step. Reduce friction, then test the result.']],
    ],
  },
  {
    slug: 'android-app-mastery', cat: 'product', tags: ['App', 'Guide'], query: 'android phone apps',
    feature: 'app', title: 'Mastering the Android App',
    secs: [
      ['Beyond the download', ['Installing is step zero. Start with the controls that matter to you: notifications, the Daily Drop, the offline outbox, and the theme. There is no measured setup time that guarantees a year of smooth use; make the routine yours.', 'Start in settings: appearance, notification types, and strictness. Defaults are a starting point, not a promise of a particular experience.']],
      ['The notification setup that works', ['Keep message alerts and Daily Drop reminders on if they help; mute milestones if you are minimalist. The nightly streak nudge is a local reminder, not a guarantee that a habit will form.', 'Inline replies are a useful shortcut: answer from the notification when the Android action is available, then decide whether to open the app for the full thread.']],
      ['Offline confidence', ['Airplane mode is a feature demo: queue sends and replies, watch the sync row count them, reconnect and watch them drain. Trust is built by watching it work once.', 'Parked verifications hand back to the composer prefilled — never lost text, never mystery state.']],
      ['Themes, widgets, shortcuts', ['System theme by default, with a manual override in settings. The current app has no home-screen integration or long-press launcher shortcuts for send and Drop; the Android app provides its in-app tabs and settings instead.', 'Match the app icon to your wallpaper era. Aesthetics are motivation wearing a costume.']],
      ['Update without thinking', ['Skippable prompts appear on cold starts when the version feed says the app is behind. The download page offers the current APK, checksum, and other architectures; it does not promise full release notes. Stay current if an update matters to your device.', 'Use the app’s current support channel for a problem. There is no promise that a report will be fixed or disappear by the next release.']],
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
    ['The failure pattern', ['A common failure pattern at {T} is an unclear invitation, treating every message as urgent, or skipping the small maintenance that turns a first send into a habit. Technology is only one part of the workflow.', 'The repair is usually subtraction: one clear prompt, one realistic reply window, one place to review messages. A smaller setup you can maintain is more useful than an ambitious setup nobody follows.']],
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
     ['Choose by job', ['The right alternative depends on the job, not on the label. A poll is strong for quick votes, a form is strong for structured detail, and a private conversation is strong when the exchange needs continuity. {T} is a good fit when the sender needs a low-pressure way in and the recipient needs control over the space.', 'Name the job before naming a winner. “I want more replies” and “I want a more candid response” call for different tools and different success measures.']],
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
    ['The turning point', ['In a useful scene, one specific reply can give a sender a reason to return. The owner does not need a viral moment. A clear prompt, a timely response, and a boundary the owner can maintain matter more than a dramatic anecdote.', 'After the week, record what changed: the prompt, the reply, the timing, or the boundary. Carry the mechanism into your own {T} rather than copying the dramatic details.']],
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
    ['The honest threat model', ['Start with who you are actually worried about. For some people it is a nosy ex, a judgmental coworker, or an ad network building a profile. SecretMsg does not ask senders for a name or account, but the service processes message text, Cloudflare processes connection data, and a mobile sender value may be stored as a hash.', 'Against stronger adversaries the honest answer is narrower: network-level observers can see that you visited the site, and a compromised device sees everything. Privacy is always relative to a threat.']],
    ['Why we refuse certain data', ['A field that is not collected needs no retention or deletion. That is useful, but it is not a promise that no processor sees connection data: Cloudflare hosts the API, and Turnstile receives the raw connecting IP when verification is requested.', 'This refusal has costs: the service uses rate limits, send-time Turnstile, and recipient controls without an automated content classifier. Review the current policy and implementation before making a claim about what is or is not stored.']],
    ['Verifying instead of trusting', ['Do not take our word for any of this. Review the current source, API responses, and deletion documentation. Skepticism is the correct default — aim it at us too.', 'Ask hard questions: what is in the database right now, which processors receive connection data, and what survives deletion. The answers should be documented rather than assumed.']],
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
    ['Under the hood, honestly', ['No machine-learning content classifier or behavior-graph optimizer is implemented in the current service. The stack includes an edge API, Cloudflare D1, Firebase Cloud Messaging for push, and client apps without an advertising or analytics SDK identified in the current code.', 'Deterministic features such as streak math, drop rotation, and template pools are easier to explain than a black-box classifier, but no design choice makes the service unable to process message content.']],
    ['Designed defaults', ['Defaults are choices: users may change them, so each setting deserves a clear explanation. The current app uses opt-in sender clues, local ritual reminders, hidden-word quarantine, and retry behavior for supported offline actions.', 'If you disagree with a default, change it in settings and check the result. The app does not promise that every setting is one tap away, that repairs are available, or that updates will never change behavior.']],
    ['What we will never build', ['No read receipts for senders. No typing indicators. No follower counts, no public leaderboards of people, no "seen" checkmarks that manufacture anxiety. Those are current product boundaries, not a promise that a future release will never change them.', 'This restraint is a feature list in negative space. Review the current app before relying on a missing capability.']],
  ],
  safety: [
    ['Prevention beats punishment', ['A clear prompt and a visible community norm can reduce avoidable friction before a message is sent. The current safeguards are still recipient-configured rules, not comprehensive content moderation.', 'Think in layers: prompt design first, hidden words second, pause third, blocks fourth, reports fifth. Each tool has a different job; none can guarantee that every harmful message is caught.']],
    ['The false-positive budget', ['Every filter trades cruelty caught against kindness delayed. Standard mode spends that budget wisely by holding instead of deleting — review converts errors into corrections.', 'Audit monthly: if the tray holds mostly fair messages, loosen the list. A filter that catches friends is worse than no filter at all.']],
    ['Helping others stay safe', ['Share this post with anyone running a board, especially younger users. Walk them through pause, hidden words, blocking, and reporting before they need any of them. These controls work best when their limits are understood in advance.', 'Normalize reporting: it records a reason, quarantines the message for review, and does not reveal the sender or automatically block them everywhere. Use the published child-safety contact for a concern outside an inbox.']],
  ],
  growth: [
    ['The math of one share', ['One story sticker reaches a few hundred viewers; low single-digit percents tap; a fraction of tappers send; a fraction of senders return. Each stage leaks — so each stage gets optimized: hook, handle visibility, prompt specificity, reply speed.', 'Small conversion gains compound across stages multiplicatively. Improve each step ten percent and the inbox doubles. That is the whole growth department, arithmetically.']],
    ['Retention is the real growth', ['A new sender who never returns may have received a useful answer once, but the app does not assign a value to that person. Replies, streaks, and drops can support a habit when they are useful to the recipient.', 'Measure return rate if you maintain your own records, and do not treat reach, replies, or a flame as a guaranteed growth result. Every feature is a tool, not a conversion promise.']],
    ['Compounding content', ['Each great exchange produces shareable proof: screenshots, quotes, stories. Recycle winners as new stickers and the content flywheel spins without fresh effort.', 'Archive monthly highlights. In a year that folder is a museum of your community — and museums recruit visitors.']],
  ],
  stories: [
    ['Reading the scene', ['Notice what the people in these stories actually did: specific prompts, a chosen posting time, replies, and pinned keepers. These are observed choices, not evidence that every board will work the same way.', 'Your situation differs in details. Map the useful moves onto your own board and test them without assuming that the scene’s result is a promise.']],
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
    ['Moment post-mortems', ['After each seasonal run, note the replies, keepers, new regulars, and lessons. Two sentences per moment, filed where next year you will find them.', 'A second year can be more intentional than the first if you kept notes. Notes are the tradition.']],
  ],
};

/* ---------------- assembly ---------------- */
function excerptFor(angle, topic) {
  const frames = {
    'ultimate-guide': `Everything about ${topic.title.toLowerCase()} — setup, strategy, and the details that separate thriving boards from silent ones.`,
    mistakes: `The seven ways people fumble ${topic.title.toLowerCase()}, each with its fix. Learn them here, not the hard way.`,
    psychology: `Why ${topic.title.toLowerCase()} works on human brains — the behavioral science plus what to do with it.`,
    beginners: `New to ${topic.title.toLowerCase()}? Start here: zero jargon, a complete first loop.`,
    advanced: `Beyond the basics of ${topic.title.toLowerCase()}: power tactics for boards that already hum.`,
    comparison: `How ${topic.title.toLowerCase()} stacks against the alternatives — honest verdict, no tribalism.`,
    myths: `Five myths about ${topic.title.toLowerCase()}, busted with evidence and better defaults.`,
    scenarios: `${topic.title} played out in real scenes — watch the loop work, then steal it.`,
    faq: `Every question people actually ask about ${topic.title.toLowerCase()}, answered straight.`,
    secrets: `The insider truths about ${topic.title.toLowerCase()} nobody puts in the onboarding.`,
  };
  return frames[angle.id];
}

function readExistingIdentity(slug) {
  const file = join(outDir, `${slug}.md`);
  if (!existsSync(file)) return null;
  const head = readFileSync(file, 'utf8').slice(0, 600);
  const date = /^date:\s*(\S+)\s*$/m.exec(head);
  const status = /^status:\s*(\S+)\s*$/m.exec(head);
  if (!date || !status) return null;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date[1])) return null;
  if (!/^(published|scheduled|draft)$/.test(status[1])) return null;
  return { date: date[1], status: status[1] };
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

      // Date and status are assigned by iteration index, so reordering the
      // angle list would silently reshuffle every post's publish date. Once a
      // post exists, keep whatever it was given: the publish calendar is
      // content, not a derived value, and must survive regeneration.
      const existing = readExistingIdentity(`${topic.slug}-${angle.id}`);
      const finalDate = existing ? existing.date : date;
      const finalStatus = existing ? existing.status : status;

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
        title, slug, date: finalDate, status: finalStatus,
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
