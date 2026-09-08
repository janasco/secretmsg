import React, { useState } from 'react';
import { Send, Shield, Sparkles, CheckCircle2, Lock, ArrowRight, Dices, Heart, Flame, Smile, Coffee, UserCheck } from 'lucide-react';
import { ApiClient, UserProfile } from '../lib/api';

interface ComposeModalProps {
  recipient: UserProfile;
  onSuccess?: () => void;
}

type VibeCategory = 'friendly' | 'chill' | 'wholesome' | 'crush' | 'confession';
type RecipientTarget = 'friend' | 'crush' | 'unknown' | 'mutual';

interface TemplateItem {
  id: string;
  category: VibeCategory;
  target?: RecipientTarget;
  text: string;
}

const VIBE_TEMPLATES: TemplateItem[] = [
  // Friendly & Hype
  {
    id: 'hype-1',
    category: 'friendly',
    target: 'friend',
    text: 'TBH, you always have the best energy and your style is unmatched. We definitely need to hang out more soon!',
  },
  {
    id: 'hype-2',
    category: 'friendly',
    target: 'friend',
    text: 'TBH, you are genuinely one of the funniest people I know. Never stop being you.',
  },
  {
    id: 'hype-3',
    category: 'friendly',
    target: 'unknown',
    text: 'TBH, I love seeing your posts on my feed, you seem like such a down-to-earth person.',
  },

  // Low-key & Chill
  {
    id: 'chill-1',
    category: 'chill',
    target: 'friend',
    text: "TBH, we don't talk as much as we used to, but I still think you're a super cool person.",
  },
  {
    id: 'chill-2',
    category: 'chill',
    target: 'mutual',
    text: "TBH, you've always been a real one. Appreciate you.",
  },
  {
    id: 'chill-3',
    category: 'chill',
    target: 'unknown',
    text: 'TBH, you seem like a great person to talk to, slide into my DMs sometime!',
  },

  // Sweet & Wholesome
  {
    id: 'wholesome-1',
    category: 'wholesome',
    target: 'friend',
    text: "TBH, you're a wonderful person and you always know exactly how to make people smile.",
  },
  {
    id: 'wholesome-2',
    category: 'wholesome',
    target: 'friend',
    text: "TBH, I'm really glad we became friends this year. You've been a huge support.",
  },
  {
    id: 'wholesome-3',
    category: 'wholesome',
    target: 'mutual',
    text: 'TBH, you bring such calm, uplifting comfort everywhere you go. Keep shining!',
  },

  // Crush & Admirer
  {
    id: 'crush-1',
    category: 'crush',
    target: 'crush',
    text: "TBH, I've had a little crush on you for a while and your smile genuinely makes my whole day.",
  },
  {
    id: 'crush-2',
    category: 'crush',
    target: 'crush',
    text: 'TBH, you are effortlessly gorgeous and your laugh is totally contagious.',
  },
  {
    id: 'crush-3',
    category: 'crush',
    target: 'crush',
    text: "TBH, I wish I had the guts to say this in person, but you're truly someone special.",
  },

  // TBH & Confessions
  {
    id: 'confess-1',
    category: 'confession',
    target: 'friend',
    text: "TBH, I was low-key intimidated by you when we first met, but you turned out to be the sweetest person.",
  },
  {
    id: 'confess-2',
    category: 'confession',
    target: 'mutual',
    text: 'TBH, you always give the best perspective whenever things get hectic. Always respect your mindset.',
  },
  {
    id: 'confess-3',
    category: 'confession',
    target: 'unknown',
    text: 'TBH, you radiate main character energy wherever you go and inspire people without even knowing it.',
  },
];

const TARGET_CHIPS: { id: RecipientTarget; label: string; icon: string }[] = [
  { id: 'friend', label: 'Close Friend', icon: '🫂' },
  { id: 'crush', label: 'A Crush', icon: '💘' },
  { id: 'unknown', label: "Don't know well", icon: '👀' },
  { id: 'mutual', label: 'Mutual / Real one', icon: '🤝' },
];

export const ComposeModal: React.FC<ComposeModalProps> = ({ recipient }) => {
  const [content, setContent] = useState('');
  const [activeCategory, setActiveCategory] = useState<VibeCategory>('friendly');
  const [activeTarget, setActiveTarget] = useState<RecipientTarget | 'all'>('all');
  const [allowClue, setAllowClue] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [sentSuccess, setSentSuccess] = useState(false);
  const [replyToken, setReplyToken] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const maxLength = 500;
  const remaining = maxLength - content.length;

  const filteredTemplates = VIBE_TEMPLATES.filter((t) => {
    const matchesCategory = t.category === activeCategory;
    const matchesTarget = activeTarget === 'all' || t.target === activeTarget;
    return matchesCategory && matchesTarget;
  });

  const handleSelectTemplate = (templateText: string) => {
    setContent(templateText);
  };

  const handleShufflePrompt = () => {
    const pool = activeTarget === 'all' 
      ? VIBE_TEMPLATES 
      : VIBE_TEMPLATES.filter(t => t.target === activeTarget || !t.target);
    const randomPick = pool[Math.floor(Math.random() * pool.length)];
    if (randomPick) {
      setContent(randomPick.text);
      setActiveCategory(randomPick.category);
    }
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!content.trim() || isSending) return;

    setError(null);
    setIsSending(true);

    try {
      const res = await ApiClient.sendAnonymousMessage(
        recipient.username,
        content.trim(),
        undefined, // Turnstile token handled via widget or header
        allowClue
      );
      setSentSuccess(true);
      if (res.replyToken) {
        setReplyToken(res.replyToken);
      }
    } catch (err: any) {
      setError(err.message || 'Failed to send message. Please try again.');
    } finally {
      setIsSending(false);
    }
  };

  if (sentSuccess) {
    return (
      <div className="glass-panel max-w-md w-full mx-auto p-6 sm:p-8 rounded-2xl text-center space-y-5 animate-in fade-in zoom-in-95 duration-200">
        <div className="w-16 h-16 bg-emerald-500/10 border border-emerald-500/20 rounded-full flex items-center justify-center mx-auto text-emerald-400 shadow-lg shadow-emerald-500/10">
          <CheckCircle2 className="w-8 h-8" />
        </div>
        
        <div className="space-y-2">
          <h3 className="text-xl font-bold text-white">Sent Anonymously!</h3>
          <p className="text-sm text-slate-400">
            Your message was delivered safely to <span className="text-slate-200 font-medium">@{recipient.username}</span> without any trace of your identity.
          </p>
        </div>

        {replyToken && (
          <div className="bg-dark-900 border border-indigo-500/20 p-4 rounded-xl text-left space-y-2">
            <div className="flex items-center space-x-1.5 text-xs font-semibold text-indigo-400">
              <Sparkles className="w-3.5 h-3.5" />
              <span>Private Reply Link (Double-Blind)</span>
            </div>
            <p className="text-xs text-slate-400">
              If @{recipient.username} replies to your message, you can view their response anonymously using this private link:
            </p>
            <div className="bg-dark-950 px-3 py-2 rounded-lg text-xs font-mono text-indigo-300 select-all break-all border border-white/5">
              {window.location.origin}/reply/{replyToken}
            </div>
          </div>
        )}

        <div className="pt-2">
          <a
            href="/"
            className="inline-flex items-center justify-center space-x-2 w-full py-3 px-4 rounded-xl font-medium text-sm bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 text-white shadow-lg shadow-indigo-500/20 transition-all"
          >
            <span>Create Your Own SecretMsg Link</span>
            <ArrowRight className="w-4 h-4" />
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="glass-panel max-w-xl w-full mx-auto p-5 sm:p-7 rounded-2xl shadow-2xl space-y-5">
      {/* Recipient Header */}
      <div className="flex items-center space-x-3.5 border-b border-white/10 pb-4">
        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-indigo-500 to-amber-500 p-0.5 shadow-md shrink-0">
          <div className="w-full h-full bg-dark-900 rounded-full flex items-center justify-center text-lg font-bold text-white uppercase">
            {recipient.display_name.slice(0, 2)}
          </div>
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center space-x-2">
            <h2 className="text-lg font-semibold text-white truncate">{recipient.display_name}</h2>
            {recipient.is_premium === 1 && (
              <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                {recipient.badge_title || 'Supporter'}
              </span>
            )}
          </div>
          <p className="text-xs text-slate-400 font-mono">secretmsg.net/{recipient.username}</p>
        </div>
        <div className="flex items-center space-x-1 text-xs text-indigo-300 bg-indigo-500/10 px-2.5 py-1 rounded-full border border-indigo-500/20">
          <Lock className="w-3 h-3" />
          <span>100% Anonymous</span>
        </div>
      </div>

      {error && (
        <div className="p-3.5 bg-rose-500/10 border border-rose-500/20 rounded-xl text-xs text-rose-300 flex items-center space-x-2">
          <span>{error}</span>
        </div>
      )}

      {/* Vibe Selection Header & Dice Button */}
      <div className="space-y-3 pt-1">
        <div className="flex items-center justify-between">
          <label className="text-xs font-semibold text-slate-300 flex items-center space-x-1.5">
            <Sparkles className="w-3.5 h-3.5 text-amber-400" />
            <span>Choose a vibe or TBH template:</span>
          </label>
          <button
            type="button"
            onClick={handleShufflePrompt}
            className="flex items-center space-x-1.5 text-xs text-indigo-300 hover:text-indigo-200 bg-indigo-500/10 hover:bg-indigo-500/20 border border-indigo-500/30 px-2.5 py-1 rounded-lg transition-all active:scale-95"
            title="Randomize TBH prompt"
          >
            <Dices className="w-3.5 h-3.5 text-indigo-400" />
            <span>🎲 Shuffle Prompt</span>
          </button>
        </div>

        {/* Category Tabs */}
        <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 no-scrollbar text-xs">
          <button
            type="button"
            onClick={() => setActiveCategory('friendly')}
            className={`px-3 py-1.5 rounded-lg font-medium whitespace-nowrap transition-all flex items-center space-x-1 ${
              activeCategory === 'friendly'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-dark-900/60 text-slate-400 hover:text-slate-200 hover:bg-dark-800 border border-white/5'
            }`}
          >
            <Smile className="w-3 h-3 text-amber-300" />
            <span>Friendly & Hype</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveCategory('chill')}
            className={`px-3 py-1.5 rounded-lg font-medium whitespace-nowrap transition-all flex items-center space-x-1 ${
              activeCategory === 'chill'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-dark-900/60 text-slate-400 hover:text-slate-200 hover:bg-dark-800 border border-white/5'
            }`}
          >
            <Coffee className="w-3 h-3 text-cyan-300" />
            <span>Low-key & Chill</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveCategory('wholesome')}
            className={`px-3 py-1.5 rounded-lg font-medium whitespace-nowrap transition-all flex items-center space-x-1 ${
              activeCategory === 'wholesome'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-dark-900/60 text-slate-400 hover:text-slate-200 hover:bg-dark-800 border border-white/5'
            }`}
          >
            <Heart className="w-3 h-3 text-rose-300" />
            <span>Sweet & Wholesome</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveCategory('crush')}
            className={`px-3 py-1.5 rounded-lg font-medium whitespace-nowrap transition-all flex items-center space-x-1 ${
              activeCategory === 'crush'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-dark-900/60 text-slate-400 hover:text-slate-200 hover:bg-dark-800 border border-white/5'
            }`}
          >
            <span>💘 Crush & Admirer</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveCategory('confession')}
            className={`px-3 py-1.5 rounded-lg font-medium whitespace-nowrap transition-all flex items-center space-x-1 ${
              activeCategory === 'confession'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-dark-900/60 text-slate-400 hover:text-slate-200 hover:bg-dark-800 border border-white/5'
            }`}
          >
            <Flame className="w-3 h-3 text-amber-400" />
            <span>TBH & Confessions</span>
          </button>
        </div>

        {/* Who is this for chips */}
        <div className="flex items-center space-x-2 pt-1">
          <span className="text-[11px] text-slate-400 font-medium">For:</span>
          <button
            type="button"
            onClick={() => setActiveTarget('all')}
            className={`px-2.5 py-0.5 rounded-full text-[11px] font-medium border transition-colors ${
              activeTarget === 'all'
                ? 'bg-white/15 text-white border-white/30'
                : 'bg-transparent text-slate-400 border-white/10 hover:border-white/20'
            }`}
          >
            All
          </button>
          {TARGET_CHIPS.map((chip) => (
            <button
              key={chip.id}
              type="button"
              onClick={() => setActiveTarget(chip.id)}
              className={`px-2.5 py-0.5 rounded-full text-[11px] font-medium border transition-colors flex items-center space-x-1 ${
                activeTarget === chip.id
                  ? 'bg-indigo-500/20 text-indigo-200 border-indigo-500/40'
                  : 'bg-transparent text-slate-400 border-white/10 hover:border-white/20'
              }`}
            >
              <span>{chip.icon}</span>
              <span>{chip.label}</span>
            </button>
          ))}
        </div>

        {/* Clickable Template Suggestions */}
        <div className="grid grid-cols-1 gap-2 pt-1 max-h-40 overflow-y-auto pr-1">
          {filteredTemplates.map((template) => (
            <button
              key={template.id}
              type="button"
              onClick={() => handleSelectTemplate(template.text)}
              className="text-left text-xs bg-dark-900/80 hover:bg-indigo-950/40 border border-white/10 hover:border-indigo-500/40 p-2.5 rounded-xl text-slate-300 hover:text-white transition-all group"
            >
              <div className="flex items-start justify-between gap-2">
                <span className="line-clamp-2 leading-relaxed">"{template.text}"</span>
                <span className="text-[10px] text-indigo-400 opacity-0 group-hover:opacity-100 shrink-0 font-medium transition-opacity">
                  Use ↵
                </span>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Message Textarea */}
      <form onSubmit={handleSend} className="space-y-4 pt-1">
        <div className="relative">
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            maxLength={maxLength}
            rows={4}
            placeholder={`Say something candid, positive, or honest to ${recipient.display_name}...`}
            className="w-full bg-dark-900/90 border border-white/15 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500/50 rounded-xl p-3.5 text-sm text-slate-100 placeholder-slate-500 resize-none transition-all outline-none leading-relaxed"
            required
          />
          <div className="absolute bottom-2.5 right-3 text-[11px] font-mono text-slate-500">
            {remaining} left
          </div>
        </div>

        {/* Sender Hint / Clue Option */}
        <label className="flex items-start space-x-2.5 cursor-pointer select-none group">
          <input
            type="checkbox"
            checked={allowClue}
            onChange={(e) => setAllowClue(e.target.checked)}
            className="mt-0.5 rounded border-white/20 bg-dark-900 text-indigo-600 focus:ring-indigo-500/30"
          />
          <span className="text-xs text-slate-400 group-hover:text-slate-300 transition-colors">
            Include broad non-identifying clue (e.g. "Mobile / Android") to let them guess who sent it.
          </span>
        </label>

        {/* Submission Button */}
        <button
          type="submit"
          disabled={!content.trim() || isSending}
          className="w-full py-3.5 px-4 rounded-xl font-medium text-sm bg-gradient-to-r from-indigo-600 via-indigo-500 to-indigo-600 hover:opacity-95 text-white shadow-lg shadow-indigo-500/25 flex items-center justify-center space-x-2 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSending ? (
            <span>Delivering candid message...</span>
          ) : (
            <>
              <Send className="w-4 h-4" />
              <span>Send Anonymously</span>
            </>
          )}
        </button>
      </form>

      {/* Privacy Guarantee Footer */}
      <div className="pt-2 border-t border-white/5 flex items-center justify-between text-[11px] text-slate-500">
        <div className="flex items-center space-x-1.5">
          <Shield className="w-3.5 h-3.5 text-indigo-400" />
          <span>Zero sender tracking. Cloudflare Turnstile protected.</span>
        </div>
        <a href="/legal/privacy" className="hover:underline text-slate-400">Privacy Policy</a>
      </div>
    </div>
  );
};
