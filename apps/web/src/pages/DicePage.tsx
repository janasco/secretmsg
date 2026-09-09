import React, { useMemo, useState, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { Dices, Send, Copy, Check, Wand2, Sparkles } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';
import { ROULETTE_POOL } from '../lib/data/rouletteData';

type CatKey = keyof typeof ROULETTE_POOL;

const CATS: { key: CatKey; label: string; color: string }[] = [
  { key: 'all', label: 'ðŸ”¥ All Vibes (9,000+)', color: 'text-white' },
  { key: 'crush', label: 'ðŸ’˜ Crush & Flirt (1,500+)', color: 'text-rose-400' },
  { key: 'spicy', label: 'ðŸŒ¶ï¸ Spicy (1,500+)', color: 'text-amber-400' },
  { key: 'secrets', label: 'ðŸ¤« Deep Secrets (1,500+)', color: 'text-violet-400' },
  { key: 'chaotic', label: 'ðŸŒªï¸ Chaotic & Wild (1,500+)', color: 'text-emerald-400' },
  { key: 'realtalk', label: 'ðŸ’¬ Real Talk (1,500+)', color: 'text-sky-400' },
  { key: 'latenight', label: 'ðŸŒ™ 3AM Thoughts (1,500+)', color: 'text-indigo-400' },
];

const CAT_TAG: Record<string, { label: string; color: string }> = {
  crush: { label: 'CRUSH', color: 'text-rose-400' },
  spicy: { label: 'SPICY', color: 'text-amber-400' },
  secrets: { label: 'SECRETS', color: 'text-violet-400' },
  chaotic: { label: 'CHAOTIC', color: 'text-emerald-400' },
  realtalk: { label: 'REAL TALK', color: 'text-sky-400' },
  latenight: { label: '3AM THOUGHTS', color: 'text-indigo-400' },
};

const POOL_PAGE_SIZE = 20;

export const DicePage: React.FC = () => {
  const [activeCat, setActiveCat] = useState<CatKey>('all');
  const [featured, setFeatured] = useState<string>('"Send me an honest TBH. Don\'t hold back ðŸ«£"');
  const [rolling, setRolling] = useState(false);
  const [copied, setCopied] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [poolCount, setPoolCount] = useState(POOL_PAGE_SIZE);
  const [diceKey, setDiceKey] = useState(0);

  const pool = useMemo(() => ROULETTE_POOL[activeCat] || ROULETTE_POOL.all, [activeCat]);
  const visible = useMemo(() => pool.slice(0, poolCount), [pool, poolCount]);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  }, []);

  const roll = useCallback(() => {
    if (rolling) return;
    setRolling(true);
    setDiceKey(k => k + 1);
    window.setTimeout(() => {
      const list = ROULETTE_POOL[activeCat] || ROULETTE_POOL.all;
      const p = list[Math.floor(Math.random() * list.length)];
      setFeatured(`"${p}"`);
      setRolling(false);
      showToast('New prompt unlocked!');
    }, 750);
  }, [activeCat, rolling, showToast]);

  const handleCopy = useCallback(() => {
    const text = featured.replace(/^"|"$/g, '').trim();
    navigator.clipboard?.writeText(text).then(() => {
      setCopied(true);
      showToast('Prompt copied to clipboard!');
      window.setTimeout(() => setCopied(false), 2000);
    });
  }, [featured, showToast]);

  const switchCat = useCallback((key: CatKey) => {
    setActiveCat(key);
    setPoolCount(POOL_PAGE_SIZE);
    setFeatured('"Roll the dice to unlock a prompt ðŸŽ²"');
  }, []);

  const loadPrompt = useCallback((prompt: string) => {
    setFeatured(`"${prompt}"`);
    showToast('Loaded into roulette card!');
  }, [showToast]);

  const currentPrompt = featured.replace(/^"|"$/g, '').trim();

  return (
    <>
      <PublicPage
        title="3D Dice Prompt Roulette"
        eyebrow="1,500+ curated prompts per category Â· 9,000+ total"
        description="Roll the dice to shake out a viral, candid, or deep question to post on your story â€” or browse the pool manually."
      >
        <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
          {/* Left: Die + actions */}
          <div className="md:col-span-5 md:sticky md:top-24 space-y-4">
            <section className="glass-panel rounded-3xl p-6 flex flex-col items-center text-center relative overflow-hidden border border-white/10">
              <div className="absolute inset-0 bg-gradient-to-b from-white/5 to-transparent pointer-events-none" />

              {/* Animated die */}
              <button
                onClick={roll}
                aria-label="Roll prompt roulette"
                className="relative w-44 h-44 rounded-full flex items-center justify-center my-1 cursor-pointer group"
                disabled={rolling}
              >
                <div className="absolute inset-0 bg-indigo-500/10 rounded-full blur-2xl" />
                <div
                  key={diceKey}
                  className={`relative z-10 w-32 h-32 rounded-3xl bg-white shadow-2xl flex items-center justify-center border-4 border-slate-200 group-hover:scale-105 transition-transform ${
                    rolling ? 'animate-spin' : ''
                  }`}
                  style={{ animationDuration: rolling ? '0.6s' : undefined }}
                >
                  <span className="text-7xl">{rolling ? 'ðŸŽ²' : 'âœ¨'}</span>
                </div>
              </button>

              <button
                onClick={roll}
                disabled={rolling}
                className="w-full max-w-[260px] py-3 bg-white text-dark-900 font-bold text-sm rounded-full active:scale-95 transition-all flex items-center justify-center gap-2 mt-2 shadow-lg disabled:opacity-70"
              >
                <Dices className="w-5 h-5" />
                {rolling ? 'Rollingâ€¦' : 'Roll Prompt Roulette ðŸŽ²'}
              </button>

              <div className="w-full bg-dark-850 rounded-2xl p-4 mt-4 text-center border border-white/10 min-h-[72px] flex items-center justify-center transition-all">
                <p className="text-sm font-semibold text-white leading-snug">{featured}</p>
              </div>

              <div className="flex gap-2 w-full mt-3">
                <Link
                  to={`/sticker-studio?question=${encodeURIComponent(currentPrompt)}`}
                  className="flex-1 py-2.5 px-3 bg-white/10 text-white rounded-full text-xs font-semibold hover:bg-white/20 transition-colors flex items-center justify-center gap-1.5 active:scale-95"
                >
                  <Wand2 className="w-4 h-4" /> Story Sticker
                </Link>
                <button
                  onClick={handleCopy}
                  title="Copy prompt text"
                  className="w-10 h-10 glass-panel rounded-full flex items-center justify-center text-white hover:bg-white/10 transition-colors shrink-0 active:scale-95"
                >
                  {copied ? <Check className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
                </button>
              </div>

              <Link
                to="/"
                className="mt-3 inline-flex items-center gap-1.5 text-xs text-slate-400 hover:text-white transition-colors"
              >
                <Send className="w-3.5 h-3.5" /> Send with your board (secretmsg.net/yourname)
              </Link>
            </section>
          </div>

          {/* Right: Pool */}
          <div className="md:col-span-7 space-y-4">
            <div className="flex flex-wrap gap-2">
              {CATS.map(cat => (
                <button
                  key={cat.key}
                  onClick={() => switchCat(cat.key)}
                  className={`px-4 py-2 rounded-full text-xs font-semibold transition-all ${
                    activeCat === cat.key
                      ? 'bg-white text-dark-900 shadow-sm'
                      : 'glass-panel text-slate-300 hover:text-white'
                  } ${activeCat === cat.key ? '' : cat.color}`}
                >
                  {cat.label}
                </button>
              ))}
            </div>

            <div className="flex justify-between items-center">
              <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Curated Roulette Pool</h3>
              <span className="text-xs text-slate-400 font-mono">{pool.length.toLocaleString()} prompts</span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {visible.map((prompt, i) => {
                const tagKey = activeCat === 'all'
                  ? ['crush', 'spicy', 'secrets', 'chaotic', 'realtalk', 'latenight'][i % 6]
                  : activeCat;
                const tag = CAT_TAG[tagKey] || { label: 'VIRAL', color: 'text-slate-400' };
                const rolls = (12 + (i * 1.3) % 40).toFixed(1);
                return (
                  <div
                    key={`${activeCat}-${i}`}
                    className="glass-panel rounded-2xl p-3.5 flex items-center justify-between gap-3 transition-transform active:scale-[0.99] hover:border-indigo-500/30"
                  >
                    <div className="flex-1">
                      <span className={`text-[10px] ${tag.color} font-mono block mb-0.5`}>{tag.label} â€¢ {rolls}K ROLLS</span>
                      <p className="text-xs font-medium text-white">"{prompt}"</p>
                    </div>
                    <button
                      onClick={() => loadPrompt(prompt)}
                      className="px-3 py-1.5 bg-white/10 hover:bg-white text-slate-300 hover:text-dark-900 rounded-full text-xs font-semibold transition-all shrink-0"
                    >
                      Try
                    </button>
                  </div>
                );
              })}
            </div>

            {poolCount < pool.length && (
              <button
                onClick={() => setPoolCount(c => c + POOL_PAGE_SIZE)}
                className="w-full py-3.5 glass-panel rounded-2xl text-xs font-bold text-white flex items-center justify-center gap-2 transition-all hover:bg-white/5"
              >
                <Sparkles className="w-4 h-4" />
                Load More Prompts ({Math.min(poolCount, pool.length).toLocaleString()} of {pool.length.toLocaleString()})
              </button>
            )}
          </div>
        </div>
      </PublicPage>

      {/* Toast */}
      <div
        className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 glass-panel px-4 py-2.5 rounded-full text-xs font-semibold text-white transition-all duration-300 flex items-center gap-2 ${
          toast ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4 pointer-events-none'
        }`}
      >
        <Dices className="w-4 h-4 text-amber-400" />
        {toast}
      </div>
    </>
  );
};
