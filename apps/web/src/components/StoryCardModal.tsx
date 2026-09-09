import React, { useState } from 'react';
import { Copy, Check, Download, X, Share2, Wand2 } from 'lucide-react';
import { UserProfile } from '../lib/api';

interface StoryCardModalProps {
  user: UserProfile;
  isOpen: boolean;
  onClose: () => void;
}

const THEMES = [
  { id: 'neon', name: 'Cyber Neon', bg: 'from-violet-900 via-indigo-950 to-dark-950', border: 'border-indigo-500/40', accent: 'text-indigo-400' },
  { id: 'sunset', name: 'Amber Sunset', bg: 'from-amber-900/60 via-dark-900 to-dark-950', border: 'border-amber-500/40', accent: 'text-amber-400' },
  { id: 'emerald', name: 'Emerald Velvet', bg: 'from-emerald-950 via-teal-950 to-dark-950', border: 'border-emerald-500/40', accent: 'text-emerald-400' },
  { id: 'candy', name: 'Cotton Candy', bg: 'from-pink-900/60 via-purple-950 to-dark-950', border: 'border-pink-500/40', accent: 'text-pink-400' },
  { id: 'obsidian', name: 'Pure Obsidian', bg: 'from-dark-900 to-black', border: 'border-white/20', accent: 'text-white' },
];

const PROMPT_PRESETS = [
  { id: 'tbh', label: 'TBH Messages', text: 'send me anonymous tbh messages 💬' },
  { id: 'confessions', label: 'Confessions', text: 'tbh & confessions... be honest! 🙈' },
  { id: 'crush', label: 'Secret Crush', text: 'who has a secret crush on me? 👀' },
  { id: 'vibe', label: 'Vibe Check', text: 'what vibe do I genuinely give off? ⚡' },
  { id: 'ama', label: 'Ask Anything', text: 'ask me anything (100% anonymous) 🤫' },
  { id: 'hype', label: 'Friendly & Hype', text: 'drop honest hype thoughts about me 🌟' },
];

export const StoryCardModal: React.FC<StoryCardModalProps> = ({ user, isOpen, onClose }) => {
  const [selectedTheme, setSelectedTheme] = useState(THEMES[0]);
  const [customPrompt, setCustomPrompt] = useState(PROMPT_PRESETS[0].text);
  const [copied, setCopied] = useState(false);

  if (!isOpen) return null;

  const publicUrl = `${window.location.origin}/${user.username}`;

  const handleCopyLink = () => {
    navigator.clipboard.writeText(publicUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="glass-panel max-w-md w-full rounded-2xl p-5 sm:p-6 space-y-5 relative max-h-[90vh] overflow-y-auto">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 text-slate-400 hover:text-white rounded-lg hover:bg-white/5 transition-colors"
        >
          <X className="w-4 h-4" />
        </button>

        <div className="space-y-1">
          <h3 className="text-lg font-bold text-white flex items-center space-x-2">
            <Share2 className="w-5 h-5 text-indigo-400" />
            <span>NGL & TBH Story Sticker</span>
          </h3>
          <p className="text-xs text-slate-400">
            Post this sticker card on Instagram, Snapchat, or TikTok stories with your secret link!
          </p>
        </div>

        {/* Live Preview Card */}
        <div className={`p-6 rounded-2xl bg-gradient-to-b ${selectedTheme.bg} border ${selectedTheme.border} shadow-2xl text-center space-y-4 transition-all duration-300 relative overflow-hidden`}>
          {/* Subtle glow background */}
          <div className="absolute -top-12 -left-12 w-32 h-32 bg-white/5 rounded-full blur-2xl pointer-events-none"></div>

          <div className="w-14 h-14 rounded-full bg-gradient-to-tr from-indigo-500 via-purple-500 to-amber-500 p-0.5 mx-auto shadow-lg">
            <div className="w-full h-full bg-dark-900 rounded-full flex items-center justify-center text-xl font-bold text-white uppercase">
              {user.display_name.slice(0, 2)}
            </div>
          </div>

          <div className="space-y-1">
            <h4 className="text-base font-bold text-white">{user.display_name}</h4>
            <p className="text-xs text-indigo-300 font-mono">@{user.username}</p>
          </div>

          {/* Sticker Prompt Box */}
          <div className="bg-dark-950/80 border border-white/15 p-4 rounded-xl shadow-inner backdrop-blur-sm">
            <p className="text-sm sm:text-base font-bold text-white leading-snug tracking-wide">
              {customPrompt}
            </p>
          </div>

          <div className="pt-2 flex flex-col items-center space-y-1.5">
            <span className="inline-block px-3 py-1 rounded-full text-[11px] font-mono bg-white/10 text-white/90 border border-white/15 shadow-sm">
              secretmsg.net/{user.username}
            </span>
            <span className="text-[10px] text-slate-400 font-medium">
              🔒 100% anonymous • no sign-up required to send
            </span>
          </div>
        </div>

        {/* Quick Vibe Presets */}
        <div className="space-y-2">
          <label className="text-xs font-semibold text-slate-300 flex items-center space-x-1.5">
            <Wand2 className="w-3.5 h-3.5 text-indigo-400" />
            <span>Story Sticker Presets:</span>
          </label>
          <div className="grid grid-cols-2 gap-1.5">
            {PROMPT_PRESETS.map((preset) => (
              <button
                key={preset.id}
                type="button"
                onClick={() => setCustomPrompt(preset.text)}
                className={`py-1.5 px-2.5 rounded-lg text-left text-xs font-medium border transition-all truncate ${
                  customPrompt === preset.text
                    ? 'border-indigo-500 bg-indigo-500/20 text-indigo-200 shadow-sm'
                    : 'border-white/10 bg-dark-900/60 text-slate-400 hover:text-slate-200 hover:border-white/20'
                }`}
              >
                {preset.label}
              </button>
            ))}
          </div>
        </div>

        {/* Custom Prompt Input */}
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-slate-400">Custom Sticker Caption:</label>
          <input
            type="text"
            value={customPrompt}
            onChange={(e) => setCustomPrompt(e.target.value)}
            maxLength={90}
            className="w-full bg-dark-900 border border-white/15 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-lg px-3 py-2 text-xs text-white outline-none"
          />
        </div>

        {/* Theme Picker */}
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-slate-400">Theme Palette:</label>
          <div className="grid grid-cols-5 gap-1.5">
            {THEMES.map((theme) => (
              <button
                key={theme.id}
                type="button"
                onClick={() => setSelectedTheme(theme)}
                className={`py-2 px-1 rounded-lg text-[10px] font-medium border text-center transition-all ${
                  selectedTheme.id === theme.id
                    ? 'border-indigo-500 bg-indigo-500/20 text-white shadow-sm'
                    : 'border-white/10 bg-dark-900/50 text-slate-400 hover:border-white/20'
                }`}
              >
                {theme.name}
              </button>
            ))}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="pt-2 flex items-center space-x-2">
          <button
            type="button"
            onClick={handleCopyLink}
            className="flex-1 py-2.5 px-3 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 flex items-center justify-center space-x-2 transition-colors"
          >
            {copied ? (
              <>
                <Check className="w-4 h-4 text-emerald-400" />
                <span>Link Copied!</span>
              </>
            ) : (
              <>
                <Copy className="w-4 h-4" />
                <span>Copy Story Link</span>
              </>
            )}
          </button>
          <button
            type="button"
            onClick={() => alert('Tip: Screenshot or save this card, add it to your Instagram/Snapchat Story, and paste your SecretMsg link into the story link sticker!')}
            className="flex-1 py-2.5 px-3 rounded-xl text-xs font-semibold bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 text-white shadow-lg shadow-indigo-500/20 flex items-center justify-center space-x-2 transition-colors"
          >
            <Download className="w-4 h-4" />
            <span>Save Sticker</span>
          </button>
        </div>
      </div>
    </div>
  );
};
