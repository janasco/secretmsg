class VibeTarget {
  final String id;
  final String label;
  final String icon;
  const VibeTarget(this.id, this.label, this.icon);
}

class VibeCategory {
  final String id;
  final String label;
  final String icon;
  const VibeCategory(this.id, this.label, this.icon);
}

class VibeTemplate {
  final String id;
  final String category;
  final String? target;
  final String text;
  const VibeTemplate(this.id, this.category, this.target, this.text);
}

const List<VibeTarget> VIBE_TARGETS = [
  VibeTarget('friend', 'Close Friend', '🫂'),
  VibeTarget('crush', 'A Crush', '💘'),
  VibeTarget('unknown', "Don't know well", '👀'),
  VibeTarget('mutual', 'Mutual / Real one', '🤝'),
];

const List<VibeCategory> VIBE_CATEGORIES = [
  VibeCategory('friendly', 'Friendly & Hype', '😁'),
  VibeCategory('chill', 'Low-key & Chill', '☕'),
  VibeCategory('wholesome', 'Sweet & Wholesome', '💖'),
  VibeCategory('crush', 'Crush & Admirer', '💘'),
  VibeCategory('confession', 'TBH & Confessions', '🔥'),
];

const List<VibeTemplate> VIBE_TEMPLATES = [
  VibeTemplate('hype-1', 'friendly', 'friend',
      'TBH, you always have the best energy and your style is unmatched. We definitely need to hang out more soon!'),
  VibeTemplate('hype-2', 'friendly', 'friend',
      'TBH, you are genuinely one of the funniest people I know. Never stop being you.'),
  VibeTemplate('hype-3', 'friendly', 'unknown',
      'TBH, I love seeing your posts on my feed, you seem like such a down-to-earth person.'),
  VibeTemplate('chill-1', 'chill', 'friend',
      "TBH, we don't talk as much as we used to, but I still think you're a super cool person."),
  VibeTemplate('chill-2', 'chill', 'mutual',
      "TBH, you've always been a real one. Appreciate you."),
  VibeTemplate('chill-3', 'chill', 'unknown',
      'TBH, you seem like a great person to talk to, slide into my DMs sometime!'),
  VibeTemplate('wholesome-1', 'wholesome', 'friend',
      "TBH, you're a wonderful person and you always know exactly how to make people smile."),
  VibeTemplate('wholesome-2', 'wholesome', 'friend',
      "TBH, I'm really glad we became friends this year. You've been a huge support."),
  VibeTemplate('wholesome-3', 'wholesome', 'mutual',
      'TBH, you bring such calm, uplifting comfort everywhere you go. Keep shining!'),
  VibeTemplate('crush-1', 'crush', 'crush',
      "TBH, I've had a little crush on you for a while and your smile genuinely makes my whole day."),
  VibeTemplate('crush-2', 'crush', 'crush',
      'TBH, you are effortlessly gorgeous and your laugh is totally contagious.'),
  VibeTemplate('crush-3', 'crush', 'crush',
      "TBH, I wish I had the guts to say this in person, but you're truly someone special."),
  VibeTemplate('confess-1', 'confession', 'friend',
      "TBH, I was low-key intimidated by you when we first met, but you turned out to be the sweetest person."),
  VibeTemplate('confess-2', 'confession', 'mutual',
      'TBH, you always give the best perspective whenever things get hectic. Always respect your mindset.'),
  VibeTemplate('confess-3', 'confession', 'unknown',
      'TBH, you radiate main character energy wherever you go and inspire people without even knowing it.'),
];

const List<String> QUICK_EMOJIS = [
  '💜', '🔥', '💘', '🙈', '✨', '🥹', '🫶', '😭', '👀', '💯', '🌸', '🕊️',
];

/// Story sticker presets (mirrors StickerStudioPage / StoryCardModal).
class StoryPreset {
  final String id;
  final String label;
  final String text;
  const StoryPreset(this.id, this.label, this.text);
}

const List<StoryPreset> STORY_PRESETS = [
  StoryPreset('tbh', 'TBH Messages', 'send me anonymous tbh messages 💬'),
  StoryPreset('confessions', 'Confessions', 'tbh & confessions... be honest! 🙈'),
  StoryPreset('crush', 'Secret Crush', 'who has a secret crush on me? 👀'),
  StoryPreset('vibe', 'Vibe Check', 'what vibe do I genuinely give off? ⚡'),
  StoryPreset('ama', 'Ask Anything', 'ask me anything (100% anonymous) 🤫'),
  StoryPreset('hype', 'Friendly & Hype', 'drop honest hype thoughts about me 🌟'),
];

class StickerTheme {
  final String id;
  final String name;
  final List<String> gradient;
  final String border;
  final String accent;

  const StickerTheme(this.id, this.name, this.gradient, this.border, this.accent);
}

const List<StickerTheme> STICKER_THEMES = [
  StickerTheme('neon', 'Cyber Neon', ['#2E1065', '#1E1B4B', '#090A0F'], '#6366F1', '#818CF8'),
  StickerTheme('sunset', 'Amber Sunset', ['#78350F', '#1E1B4B', '#090A0F'], '#F59E0B', '#FBBF24'),
  StickerTheme('emerald', 'Emerald Velvet', ['#022C22', '#042F2E', '#090A0F'], '#10B981', '#34D399'),
  StickerTheme('candy', 'Cotton Candy', ['#831843', '#3B0764', '#090A0F'], '#EC4899', '#F9A8D4'),
  StickerTheme('obsidian', 'Pure Obsidian', ['#0F111A', '#090A0F'], '#FFFFFF', '#FFFFFF'),
];