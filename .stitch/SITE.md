# SecretMsg Mobile App Constitution

## 1. Core Identity
- **Project Name**: SecretMsg Mobile
- **Stitch Project ID**: 9285542180576435575
- **Mission**: Open-source, privacy-first anonymous messaging & viral TBH platform allowing users to share candid prompts, secret compliments, and social story stickers.
- **Target Audience**: Mobile creators, friends, crushes, and social media users across Instagram, Snapchat, and TikTok.
- **Voice**: Clean, modern, trustworthy, candid, playful, and minimalist.

## 2. Visual Language
- **Vibe Keywords**: Clean Minimalist, Crisp White Accents, Sleek Dark Titanium / Obsidian Canvas, Fluid Micro-interactions.
- **Primary Color**: `#FFFFFF` (Crisp White / Glow Accents)
- **Background**: `#0B0E14` (Obsidian Void) & `#131823` (Card Glass Surface)
- **Accent Accents**: `#38BDF8` (Electric Sky), `#818CF8` (Soft Indigo), `#F43F5E` (Wholesome Rose)
- **Typography**: Inter (Modern, geometric, crystal legible)

## 3. Architecture & File Structure
```
/opt/secretmsg/
├── .stitch/
│   ├── metadata.json
│   ├── SITE.md
│   ├── DESIGN.md
│   ├── next-prompt.md
│   └── designs/
│       └── {page}.html
└── site/public/
    ├── css/
    │   └── common.css
    ├── landing.html             # Screen 0: Desktop & Mobile Minimal Landing Page (2-link Nav)
    ├── index.html               # Screen 1: Home & Explore (14,000+ Templates)
    ├── compose.html             # Screen 2: Compose Anonymous Message (Sanitize & Pause Aware)
    ├── dice.html                # Screen 3: 3D Roulette & Prompt Shuffle
    ├── sticker-studio.html      # Screen 4: Story Sticker Studio
    ├── inbox.html               # Screen 5: Secret Inbox (Viewer Counter & Quarantine Tabs)
    ├── message-detail.html      # Screen 6: Message Detail, Sender Hints & Block Controls
    ├── profile.html             # Screen 7: Profile, Vanity Link Hub & Verified Badge
    ├── supporters.html          # Screen 8: Modular Supporter Wall ($2-$7 Perks)
    ├── settings.html            # Screen 9: Preferences & Safety Controls (Words, Block, Pause)
    └── safety.html              # Screen 10: Safety Center & Trust Documentation
```

## 4. Live Sitemap
- [x] `landing.html` — Minimalist Landing Page (Retained 2-link header, direct creation form)
- [x] `index.html` — Home & Explore (Featured viral templates, categories, search bar)
- [x] `compose.html` — Compose Anonymous Message (Validation, pause checking, hidden words block)
- [x] `dice.html` — TBH Roulette & Prompt Shuffle (Interactive 3D Three.js dice)
- [x] `sticker-studio.html` — Instagram/Snapchat Story Sticker Exporter
- [x] `inbox.html` — Anonymous Inbox & Unread Messages Feed with View Counts
- [x] `message-detail.html` — Message Detail with Double-Blind Reply & Sender Hints
- [x] `profile.html` — Profile & Vanity Link Hub with Verified Badges
- [x] `supporters.html` — Modular Supporter Wall ($2 Verified Badge, $3 Viewer Hints, $4 Sender Hints, $7 VIP)
- [x] `settings.html` — Preferences (Notifications & 3-Choice Theme) & Safety Controls (Hidden Words, Blocked Users, Pause Link)
- [x] `safety.html` & Sub-pages — Safety Center, Child Safety, Guidelines, Crisis Resources

## 5. Architectural Accomplishments
- [x] 3-Choice Appearance System: Always Light, Always Dark, System Default.
- [x] Platform Input Sanitization: Strict 4-character minimum and XSS protection.
- [x] Modular Feature Donations: Independent database flags for Verified Badge, Viewer Hints, and Sender Hints.
- [x] Complete Safety Controls Suite: Pause Link (1h, 6h, 24h, permanent), custom Hidden Words filter, and sender device blocking.
- [x] Zero-breaking 2-link landing header navigation with rich responsive footer.

