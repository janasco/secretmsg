import React, { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Copy, Check, Download, Wand2, Share2, Palette } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

const THEMES = [
  { id: 'neon', name: 'Cyber Neon', bg: 'from-violet-900 via-indigo-950 to-dark-950', border: 'border-indigo-500/40', accent: 'text-indigo-400' },
  { id: 'sunset', name: 'Amber Sunset', bg: 'from-amber-900/60 via-dark-900 to-dark-950', border: 'border-amber-500/40', accent: 'text-amber-400' },
  { id: 'emerald', name: 'Emerald Velvet', bg: 'from-emerald-950 via-teal-950 to-dark-950', border: 'border-emerald-500/40', accent: 'text-emerald-400' },
  { id: 'candy', name: 'Cotton Candy', bg: 'from-pink-900/60 via-purple-950 to-dark-950', border: 'border-pink-500/40', accent: 'text-pink-400' },
  { id: 'obsidian', name: 'Pure Obsidian', bg: 'from-dark-900 to-black', border: 'border-white/20', accent: 'text-white' },
];

const PRESETS = [
  { id: 'tbh', label: 'TBH Messages', text: 'send me anonymous tbh messages 💬' },
  { id: 'confessions', label: 'Confessions', text: 'tbh & confessions... be honest! 🙈' },
  { id: 'crush', label: 'Secret Crush', text: 'who has a secret crush on me? 👀' },
  { id: 'vibe', label: 'Vibe Check', text: 'what vibe do I genuinely give off? ⚡' },
  { id: 'ama', label: 'Ask Anything', text: 'ask me anything (100% anonymous) 🤫' },
  { id: 'hype', label: 'Friendly & Hype', text: 'drop honest hype thoughts about me 🌟' },
];

export const StickerStudioPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const initial = searchParams.get('question') || PRESETS[0].text;
  const [prompt, setPrompt] = useState(initial);
  const [theme, setTheme] = useState(THEMES[0]);
  const [displayName, setDisplayName] = useState('Your Board');
  const [username, setUsername] = useState('');
  const [copied, setCopied] = useState(false);
  const [copiedLink, setCopiedLink] = useState(false);

  const publicUrl = username ? `https://secretmsg.net/${encodeURIComponent(username)}` : 'secretmsg.net/yourname';

  const handleCopyCaption = () => {
    navigator.clipboard?.writeText(prompt);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleCopyLink = () => {
    if (!username) return;
    navigator.clipboard?.writeText(publicUrl);
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2000);
  };

  const handleSave = () => {
    alert('Tip: Screenshot or save this card, add it to your Instagram/Snapchat Story, and paste your SecretMsg link into the story link sticker!');
  };

  return (
    <PublicPage
      title="Story Sticker Studio"
      eyebrow="24/7 Personal Sticker Studio"
      description="Design a beautiful 9:16 story sticker card for your anonymous message board — pick a theme, write your prompt, and post to your story."
    >
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 items-start">
        {/* Live preview */}
        <div className="space-y-3 md:sticky md:top-24">
          <div className={`p-6 rounded-3xl bg-gradient-to-b ${theme.bg} border ${theme.border} shadow-2xl text-center space-y-4 transition-all duration-300 relative overflow-hidden`}>
            <div className="absolute -top-12 -left-12 w-32 h-32 bg-white/5 rounded-full blur-2xl pointer-events-none" />
            <div className="w-14 h-14 rounded-full bg-gradient-to-tr from-indigo-500 via-purple-500 to-amber-500 p-0.5 mx-auto shadow-lg">
              <div className="w-full h-full bg-dark-900 rounded-full flex items-center justify-center text-xl font-bold text-white uppercase">
                {(displayName || 'B').slice(0, 2)}
              </div>
            </div>
            <div className="space-y-1">
              <h4 className="text-base font-bold text-white">{displayName || 'Your Board'}</h4>
              <p className="text-xs text-indigo-300 font-mono">@{username || 'yourname'}</p>
            </div>
            <div className="bg-dark-950/80 border border-white/15 p-4 rounded-xl shadow-inner backdrop-blur-sm">
              <p className="text-sm sm:text-base font-bold text-white leading-snug tracking-wide">{prompt}</p>
            </div>
            <div className="pt-2 flex flex-col items-center space-y-1.5">
              <span className="inline-block px-3 py-1 rounded-full text-[11px] font-mono bg-white/10 text-white/90 border border-white/15 shadow-sm">
                {publicUrl}
              </span>
              <span className="text-[10px] text-slate-400 font-medium">🔒 100% anonymous • no sign-up required to send</span>
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-2">
            <button
              onClick={handleCopyCaption}
              className="flex-1 py-2.5 px-3 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 flex items-center justify-center space-x-2 transition-colors"
            >
              {copied ? <Check className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
              <span>{copied ? 'Caption Copied!' : 'Copy Caption'}</span>
            </button>
            <button
              onClick={handleCopyLink}
              disabled={!username}
              className="flex-1 py-2.5 px-3 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 flex items-center justify-center space-x-2 transition-colors disabled:opacity-50"
            >
              {copiedLink ? <Check className="w-4 h-4 text-emerald-400" /> : <Share2 className="w-4 h-4" />}
              <span>{copiedLink ? 'Link Copied!' : 'Copy Story Link'}</span>
            </button>
            <button
              onClick={handleSave}
              className="flex-1 py-2.5 px-3 rounded-xl text-xs font-semibold bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 text-white shadow-lg shadow-indigo-500/20 flex items-center justify-center space-x-2 transition-colors"
            >
              <Download className="w-4 h-4" />
              <span>Save Sticker</span>
            </button>
          </div>
        </div>

        {/* Controls */}
        <div className="glass-panel rounded-3xl p-6 space-y-5">
          <div className="space-y-2">
            <label className="text-xs font-semibold text-slate-300 flex items-center space-x-1.5">
              <Wand2 className="w-3.5 h-3.5 text-indigo-400" />
              <span>Story Sticker Presets:</span>
            </label>
            <div className="grid grid-cols-2 gap-1.5">
              {PRESETS.map((preset) => (
                <button
                  key={preset.id}
                  type="button"
                  onClick={() => setPrompt(preset.text)}
                  className={`py-1.5 px-2.5 rounded-lg text-left text-xs font-medium border transition-all truncate ${
                    prompt === preset.text
                      ? 'border-indigo-500 bg-indigo-500/20 text-indigo-200 shadow-sm'
                      : 'border-white/10 bg-dark-900/60 text-slate-400 hover:text-slate-200 hover:border-white/20'
                  }`}
                >
                  {preset.label}
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-medium text-slate-400">Sticker Caption:</label>
            <input
              type="text"
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              maxLength={90}
              className="w-full bg-dark-900 border border-white/15 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-lg px-3 py-2 text-xs text-white outline-none"
            />
            <p className="text-[10px] text-slate-500 text-right">{prompt.length}/90</p>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-medium text-slate-400">Your Board Name (optional):</label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              maxLength={30}
              className="w-full bg-dark-900 border border-white/15 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-lg px-3 py-2 text-xs text-white outline-none"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-medium text-slate-400">Your secretmsg.net username (adds your real link):</label>
            <div className="flex items-center gap-2">
              <span className="text-xs text-slate-500 font-mono shrink-0">secretmsg.net/</span>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value.replace(/[^a-zA-Z0-9_]/g, '').toLowerCase())}
                maxLength={30}
                className="w-full bg-dark-900 border border-white/15 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-lg px-3 py-2 text-xs text-white outline-none"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-medium text-slate-400 flex items-center space-x-1.5">
              <Palette className="w-3.5 h-3.5 text-indigo-400" />
              <span>Theme Palette:</span>
            </label>
            <div className="grid grid-cols-5 gap-1.5">
              {THEMES.map((themeOpt) => (
                <button
                  key={themeOpt.id}
                  type="button"
                  onClick={() => setTheme(themeOpt)}
                  className={`py-2 px-1 rounded-lg text-[10px] font-medium border text-center transition-all ${
                    theme.id === themeOpt.id
                      ? 'border-indigo-500 bg-indigo-500/20 text-white shadow-sm'
                      : 'border-white/10 bg-dark-900/50 text-slate-400 hover:border-white/20'
                  }`}
                >
                  {themeOpt.name}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </PublicPage>
  );
};