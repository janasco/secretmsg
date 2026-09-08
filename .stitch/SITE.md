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
    ├── index.html               # Screen 1: Home & Explore
    ├── compose.html             # Screen 2: Compose Anonymous Message
    ├── dice.html                # Screen 3: TBH Roulette & Prompt Shuffle
    ├── sticker-studio.html      # Screen 4: Story Sticker Studio
    ├── inbox.html               # Screen 5: Secret Inbox
    ├── message-detail.html      # Screen 6: Message Detail & Double-Blind Reply
    ├── profile.html             # Screen 7: Profile & Vanity Link Hub
    ├── supporters.html          # Screen 8: Supporters Wall & Polar Perks
    └── settings.html            # Screen 9: Privacy & Account Settings
```

## 4. Live Sitemap
- [x] `index.html` — Home & Explore (Featured viral templates, categories, search bar)
- [x] `compose.html` — Compose Anonymous Message (Target recipient, vibe tag, send button)
- [x] `dice.html` — TBH Roulette & Prompt Shuffle (Interactive prompt die roll)
- [x] `sticker-studio.html` — Instagram/Snapchat Story Sticker Exporter
- [x] `inbox.html` — Anonymous Inbox & Unread Messages Feed
- [x] `message-detail.html` — Message Detail with Double-Blind Reply
- [x] `profile.html` — Profile & Vanity Link Hub
- [x] `supporters.html` — Supporters Wall & Polar Perks
- [x] `settings.html` — Privacy Vault & Data Controls

## 5. The Roadmap (Backlog)
### High Priority
- Initialize Stitch project and core tokens.
- Generate Screen 1: Home & Explore with categories, search bar, and viral templates.
- Generate Screen 2: Compose Message.
- Generate Screen 3: Dice Prompt Shuffle.
- Generate Screen 4: Story Sticker Studio.
- Generate Screen 5: Secret Inbox.
- Generate Screen 6: Message Detail with Double-Blind Reply.
- Generate Screen 7: Profile & Vanity Link Hub.
- Generate Screen 8: Supporters Wall.
- Generate Screen 9: Privacy & Settings.
- Build interactive mobile container with bottom navigation bar and shared routing.
