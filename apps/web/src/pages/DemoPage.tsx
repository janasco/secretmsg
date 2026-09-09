import React, { useState, useCallback } from 'react';
import { Send, RotateCcw, Sparkles, Mail, Wand2, RefreshCw, MessageSquare } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';
import { ROULETTE_POOL } from '../lib/data/rouletteData';

interface DemoMessage {
  id: number;
  text: string;
  vibe: string;
  time: string;
  status: 'encrypted' | 'waiting';
}

const VIBES = [
  { id: 'tbh', label: '💬 TBH', color: 'text-sky-400 border-sky-500/30 bg-sky-500/10' },
  { id: 'crush', label: '😍 Crush', color: 'text-rose-400 border-rose-500/30 bg-rose-500/10' },
  { id: 'spicy', label: '🌶️ Spicy', color: 'text-amber-400 border-amber-500/30 bg-amber-500/10' },
  { id: 'vibe', label: '✨ Vibes', color: 'text-emerald-400 border-emerald-500/30 bg-emerald-500/10' },
];

const EMOJI_QUICK = ['👀', '😳', '🙈', '✨', '💘', '🔥', '🫨', '💯'];

const SEED: DemoMessage[] = [
  { id: 1, text: 'Honestly? Your energy is so underrated. Keep glowing ✨', vibe: 'Vibes', time: '2m ago', status: 'encrypted' },
  { id: 2, text: 'Okay but WHY are you so good at making people feel seen? 🥹', vibe: 'TBH', time: '11m ago', status: 'encrypted' },
  { id: 3, text: 'Lowkey been meaning to ask… do you know how magnetic your laugh is? 😳', vibe: 'Crush', time: '34m ago', status: 'encrypted' },
  { id: 4, text: 'Bet you could make a meme out of our college story and it would break the internet 🔥', vibe: 'Spicy', time: '1h ago', status: 'encrypted' },
];

const GRADIENTS = [
  { id: 'g1', name: 'Rose Ember', cls: 'linear-gradient(135deg, #FF6B6B 0%, #556270 100%)' },
  { id: 'g2', name: 'Indigo Dusk', cls: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' },
  { id: 'g3', name: 'Pink Fizz', cls: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)' },
  { id: 'g4', name: 'Ocean Glow', cls: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)' },
];

const DOUBLE_BLIND_REPLIES = [
  'Thanks for the kind words — honestly needed to hear that today 🤍',
  'No spoilers on who you are… but this made my day!',
  'Wait, this message was ANONYMOUS? Impressive 😄',
];

export const DemoPage: React.FC = () => {
  const [messages, setMessages] = useState<DemoMessage[]>(SEED);
  const [activeVibe, setActiveVibe] = useState(VIBES[0]);
  const [text, setText] = useState('');
  const [toast, setToast] = useState<string | null>(null);
  const [rouletteCat, setRouletteCat] = useState<'all' | 'crush' | 'latenight'>('all');
  const [currentPrompt, setCurrentPrompt] = useState(ROULETTE_POOL.latenight[0]);
  const [gradient, setGradient] = useState(GRADIENTS[0]);
  const [openReply, setOpenReply] = useState<number | null>(null);
  const [replyText, setReplyText] = useState('');

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  }, []);

  const sendMessage = useCallback(() => {
    const trimmed = text.trim();
    if (!trimmed) return;
    const msg: DemoMessage = {
      id: Date.now(),
      text: trimmed,
      vibe: activeVibe.label,
      time: 'just now',
      status: 'encrypted',
    };
    setMessages(prev => [msg, ...prev]);
    setText('');
    showToast('Simulated message encrypted & delivered!');
  }, [text, activeVibe, showToast]);

  const resetDemo = useCallback(() => {
    setMessages(SEED);
    setText('');
    setReplyText('');
    setOpenReply(null);
    showToast('Demo data reset');
  }, [showToast]);

  const rollRoulette = useCallback(() => {
    const pool = ROULETTE_POOL[rouletteCat];
    setCurrentPrompt(pool[Math.floor(Math.random() * pool.length)]);
  }, [rouletteCat]);

  const openReplyModal = useCallback((id: number) => {
    setOpenReply(id);
    setReplyText(DOUBLE_BLIND_REPLIES[id % DOUBLE_BLIND_REPLIES.length]);
  }, []);

  const sendReply = useCallback(() => {
    setMessages(prev => prev.map(m =>
      m.id === openReply ? { ...m, status: 'waiting', text: replyText } : m
    ));
    setOpenReply(null);
    showToast('Double-blind reply sent (encrypted)');
  }, [openReply, replyText, showToast]);

  const open = messages.find(m => m.id === openReply);

  return (
    <>
      <PublicPage
        title="Interactive Platform Demo & Sandbox"
        eyebrow="Real-time Playground"
        description="Test anonymous messages, shuffle roulette prompts, preview story stickers, and experience double-blind inbox replies. No account needed."
      >
        <div className="flex flex-wrap items-center gap-3 mb-6">
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-500/10 border border-indigo-500/25 text-indigo-300 text-xs font-semibold">
            <Sparkles className="w-3.5 h-3.5" /> Simulated environment — nothing is stored
          </span>
          <button
            onClick={resetDemo}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold text-slate-300 hover:text-white bg-white/5 hover:bg-white/10 border border-white/10 transition-colors"
          >
            <RotateCcw className="w-3.5 h-3.5" /> Reset Demo Data
          </button>
        </div>

        {/* Composer + Live Inbox */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 mb-10">
          {/* Composer */}
          <section className="lg:col-span-5 space-y-4">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <Send className="w-5 h-5 text-indigo-400" /> 1. Try Sending a Message
            </h2>
            <p className="text-xs text-slate-400">
              This simulates what your followers see when they click your story link.
            </p>

            <div className="glass-panel rounded-3xl p-5 space-y-4 border border-white/10">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-indigo-500 to-purple-500 flex items-center justify-center font-bold text-white">S</div>
                <div>
                  <p className="text-sm font-bold text-white">@demo — Ask me anything</p>
                  <p className="text-[11px] text-slate-400">🔒 100% anonymous</p>
                </div>
              </div>

              <div className="flex flex-wrap gap-1.5">
                {VIBES.map(v => (
                  <button
                    key={v.id}
                    onClick={() => setActiveVibe(v)}
                    className={`px-3 py-1.5 rounded-full text-xs font-semibold border transition-colors ${
                      activeVibe.id === v.id ? v.color : 'border-white/10 bg-dark-900/60 text-slate-400 hover:text-slate-200'
                    }`}
                  >
                    {v.label}
                  </button>
                ))}
              </div>

              <textarea
                value={text}
                onChange={(e) => setText(e.target.value)}
                maxLength={500}
                rows={3}
                placeholder={`${activeVibe.label.replace(/^\S+\s/, '')}: type your question or message…`}
                className="w-full bg-dark-900 border border-white/15 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-xl px-3.5 py-3 text-sm text-white outline-none resize-none"
              />

              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-1">
                  {EMOJI_QUICK.map(e => (
                    <button
                      key={e}
                      onClick={() => setText(t => t + ' ' + e)}
                      className="w-8 h-8 rounded-lg text-base hover:bg-white/10 transition-colors"
                    >
                      {e}
                    </button>
                  ))}
                </div>
                <span className="text-[10px] text-slate-500 font-mono">{text.length}/500</span>
              </div>

              <button
                onClick={sendMessage}
                disabled={!text.trim()}
                className="w-full py-3 rounded-xl text-sm font-bold bg-white text-dark-900 hover:bg-slate-100 transition-colors flex items-center justify-center gap-2 disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <Send className="w-4 h-4" /> Send Anonymously
              </button>

              <p className="text-[11px] text-slate-500 text-center">
                🔐 Messages are end-to-end encrypted and delivered instantly — try it above.
              </p>
            </div>
          </section>

          {/* Live Inbox */}
          <section className="lg:col-span-7 space-y-4">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <Mail className="w-5 h-5 text-indigo-400" /> 2. Watch Your Demo Inbox
            </h2>
            <p className="text-xs text-slate-400">
              New messages appear instantly. Click one to try the double-blind reply flow.
            </p>

            <div className="space-y-2.5">
              {messages.slice(0, 6).map(m => (
                <button
                  key={m.id}
                  onClick={() => openReplyModal(m.id)}
                  className="w-full glass-panel rounded-2xl p-4 text-left border border-white/10 hover:border-indigo-500/30 transition-colors flex items-center justify-between gap-3"
                >
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-[10px] font-mono text-indigo-400 uppercase tracking-wider">{m.vibe}</span>
                      <span className="text-[10px] text-slate-500">{m.time}</span>
                    </div>
                    <p className="text-sm text-white truncate">{m.text}</p>
                  </div>
                  <span className={`shrink-0 inline-flex items-center gap-1 px-2 py-1 rounded-full text-[10px] font-semibold ${
                    m.status === 'encrypted'
                      ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                      : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                  }`}>
                    {m.status === 'encrypted' ? '🔒 Encrypted' : '💬 Awaiting reply'}
                  </span>
                </button>
              ))}
            </div>
          </section>
        </div>

        {/* Roulette + Sticker showcase */}
        <div className="grid grid-cols-1 md:grid-cols-12 gap-6">
          <section className="md:col-span-5 glass-panel rounded-3xl p-6 border border-white/10 space-y-4">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <RefreshCw className="w-5 h-5 text-indigo-400" /> 3. Shuffle a Prompt
            </h2>
            <div className="flex gap-1.5">
              {(['all', 'crush', 'latenight'] as const).map(c => (
                <button
                  key={c}
                  onClick={() => setRouletteCat(c)}
                  className={`px-3 py-1.5 rounded-full text-xs font-semibold border transition-colors ${
                    rouletteCat === c
                      ? 'border-indigo-500 bg-indigo-500/20 text-indigo-200'
                      : 'border-white/10 bg-dark-900/60 text-slate-400'
                  }`}
                >
                  {c === 'all' ? '🔥 All' : c === 'crush' ? '💘 Crush' : '🌙 3AM'}
                </button>
              ))}
            </div>
            <div className="bg-dark-850 border border-white/10 rounded-2xl p-4 min-h-[56px] flex items-center">
              <p className="text-sm font-semibold text-white">"{currentPrompt}"</p>
            </div>
            <button
              onClick={rollRoulette}
              className="w-full py-3 rounded-xl text-sm font-bold bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 text-white shadow-lg shadow-indigo-500/20 flex items-center justify-center gap-2 transition-colors"
            >
              <RefreshCw className="w-4 h-4" /> Roll Another
            </button>
          </section>

          <section className="md:col-span-7 glass-panel rounded-3xl p-6 border border-white/10 space-y-4">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <Wand2 className="w-5 h-5 text-indigo-400" /> 4. Story Sticker Preview
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-start">
              <div
                className="relative rounded-2xl p-6 text-center text-white shadow-2xl space-y-3 overflow-hidden aspect-[9/16] max-h-80"
                style={{ background: gradient.cls }}
              >
                <div className="w-10 h-10 rounded-full bg-white/20 backdrop-blur flex items-center justify-center font-bold text-sm mx-auto">S</div>
                <p className="text-base font-black leading-snug drop-shadow">"{currentPrompt.slice(0, 70)}"</p>
                <span className="absolute bottom-4 left-0 right-0 text-center text-[10px] font-mono bg-black/30 backdrop-blur py-1 mx-4 rounded-full">
                  secretmsg.net/yourname
                </span>
              </div>

              <div className="space-y-2.5">
                <p className="text-xs font-semibold text-slate-300">Gradient picker:</p>
                <div className="grid grid-cols-2 gap-1.5">
                  {GRADIENTS.map(g => (
                    <button
                      key={g.id}
                      onClick={() => setGradient(g)}
                      className={`py-1.5 px-2 rounded-lg text-[11px] font-medium border transition-all ${
                        gradient.id === g.id ? 'border-indigo-500 bg-indigo-500/20 text-white' : 'border-white/10 bg-dark-900/60 text-slate-400'
                      }`}
                    >
                      {g.name}
                    </button>
                  ))}
                </div>
                <p className="text-[11px] text-slate-500">💡 Head to the <a href="/sticker-studio" className="text-indigo-400 hover:text-indigo-300 underline">full Sticker Studio</a> for export options and your real board link.</p>
              </div>
            </div>
          </section>
        </div>
      </PublicPage>

      {/* Reply modal */}
      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="glass-panel max-w-md w-full rounded-2xl p-5 space-y-4">
            <div>
              <p className="text-[11px] font-mono text-indigo-400 uppercase tracking-wider">Double-blind reply · {open.vibe}</p>
              <p className="text-sm text-white mt-1">"{open.text}"</p>
            </div>
            <label className="text-xs font-medium text-slate-400">Your reply (sender is revealed back to you only after reply):</label>
            <textarea
              value={replyText}
              onChange={(e) => setReplyText(e.target.value)}
              rows={3}
              className="w-full bg-dark-900 border border-white/15 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-xl px-3 py-2.5 text-sm text-white outline-none resize-none"
            />
            <div className="flex gap-2">
              <button
                onClick={() => setOpenReply(null)}
                className="flex-1 py-2.5 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={sendReply}
                className="flex-1 py-2.5 rounded-xl text-xs font-semibold bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 text-white shadow-lg shadow-indigo-500/20 transition-colors flex items-center justify-center gap-1.5"
              >
                <MessageSquare className="w-3.5 h-3.5" /> Send Reply
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast */}
      <div
        className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 glass-panel px-4 py-2.5 rounded-full text-xs font-semibold text-white transition-all duration-300 flex items-center gap-2 ${
          toast ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4 pointer-events-none'
        }`}
      >
        <Sparkles className="w-4 h-4 text-indigo-400" />
        {toast}
      </div>
    </>
  );
};