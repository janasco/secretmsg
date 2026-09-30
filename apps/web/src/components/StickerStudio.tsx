import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Copy, Check, Download, Shuffle, Sparkles } from 'lucide-react';
import {
  STICKER_STYLES,
  ensureFont,
  type StickerStyle,
} from '@/lib/stickers/design';
import {
  renderSticker,
  stickerToBlob,
  type StickerData,
} from '@/lib/stickers/render';
import { HANDLE_MAX, NAME_MAX, PROMPT_MAX, W, H } from '@/lib/stickers/constants';
import {
  PRESETS,
  rollPrompt,
  rememberRecent,
  hashSeed,
} from '@/lib/stickers/prompts';

type Copied = 'caption' | 'link' | null;

const sanitizeHandle = (value: string): string =>
  value.replace(/[^a-zA-Z0-9_.-]/g, '').toLowerCase().slice(0, HANDLE_MAX);

export const StickerStudio: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [styleId, setStyleId] = useState(STICKER_STYLES[0].id);
  const [prompt, setPrompt] = useState(PRESETS[0].prompt);
  const [displayName, setDisplayName] = useState('Your Board');
  const [handle, setHandle] = useState('');
  const [copied, setCopied] = useState<Copied>(null);
  const [history, setHistory] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);

  const style: StickerStyle = useMemo(
    () => STICKER_STYLES.find((s) => s.id === styleId) ?? STICKER_STYLES[0],
    [styleId],
  );

  const data: StickerData = useMemo(() => {
    const clean = sanitizeHandle(handle);
    return {
      prompt: prompt.slice(0, PROMPT_MAX),
      name: displayName.slice(0, NAME_MAX),
      handle: clean,
      url: clean ? `secretmsg.net/${clean}` : 'secretmsg.net/yourname',
    };
  }, [prompt, displayName, handle]);

  /**
   * Painting runs in an effect, never during render. /sticker-studio is
   * prerendered to static HTML at build time where `document` does not exist,
   * so touching a canvas while rendering would throw during `npm run build`.
   */
  useEffect(() => {
    let cancelled = false;
    // The font has to be resident before the text is measured, or the card is
    // laid out against a fallback and every metric is wrong.
    void ensureFont(style.font).then(() => {
      if (cancelled) return;
      if (canvasRef.current) renderSticker(canvasRef.current, style, data);
    });
    return () => {
      cancelled = true;
    };
  }, [style, data]);

  // Warm the next style's face so stepping through the list is not a stall.
  useEffect(() => {
    const idx = STICKER_STYLES.findIndex((s) => s.id === styleId);
    const next = STICKER_STYLES[(idx + 1) % STICKER_STYLES.length];
    void ensureFont(next.font);
  }, [styleId]);

  const handleRoll = useCallback(() => {
    // The history holds *subjects*, not finished prompts — rollPrompt filters
    // subjects, so storing prompts here would make the avoid list a no-op.
    const { prompt: next, subject } = rollPrompt(
      hashSeed(`${history.length}:${Date.now()}`),
      history,
    );
    setHistory((prev) => rememberRecent(prev, subject));
    setPrompt(next);
  }, [history]);

  const handleDownload = useCallback(async () => {
    const canvas = canvasRef.current;
    if (!canvas || busy) return;
    setBusy(true);
    try {
      await ensureFont(style.font);
      renderSticker(canvas, style, data);
      const blob = await stickerToBlob(canvas);
      if (!blob) return;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `secretmsg-${style.id}-${data.handle || 'board'}.png`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      // Revoking immediately can cancel the download in some browsers.
      window.setTimeout(() => URL.revokeObjectURL(url), 4000);
    } finally {
      setBusy(false);
    }
  }, [busy, data, style]);

  const flash = (which: Exclude<Copied, null>) => {
    setCopied(which);
    window.setTimeout(() => setCopied(null), 1800);
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-[236px_minmax(0,1fr)_340px] gap-6 items-start">
      {/* ---------------- catalogue ---------------- */}
      <nav aria-label="Sticker styles" className="lg:sticky lg:top-24">
        <p className="text-[11px] font-semibold uppercase tracking-wider text-slate-400 mb-3">
          {STICKER_STYLES.length} styles
        </p>
        <ul className="grid grid-cols-2 lg:grid-cols-1 gap-1.5 max-h-[70vh] overflow-y-auto pr-1">
          {STICKER_STYLES.map((s) => {
            const active = s.id === styleId;
            return (
              <li key={s.id}>
                <button
                  type="button"
                  onClick={() => setStyleId(s.id)}
                  aria-pressed={active}
                  title={s.vibe}
                  className={[
                    'w-full text-left rounded-xl border px-3 py-2 transition-colors',
                    active
                      ? 'border-indigo-400/70 bg-indigo-500/15'
                      : 'border-white/10 hover:border-white/25',
                  ].join(' ')}
                >
                  <span
                    className={[
                      'block text-xs font-semibold truncate',
                      active ? 'text-white' : 'text-slate-300',
                    ].join(' ')}
                  >
                    {s.name}
                  </span>
                  <span className="block text-[10px] text-slate-500 truncate">
                    {s.font.family} · {s.vibe}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      </nav>

      {/* ---------------- preview ---------------- */}
      <div className="lg:sticky lg:top-24 flex flex-col items-center gap-3">
        <canvas
          ref={canvasRef}
          width={W}
          height={H}
          role="img"
          aria-label={`Sticker preview: ${style.name}, ${data.prompt}`}
          className="w-full max-w-[440px] aspect-[9/16] rounded-2xl border border-white/10 shadow-2xl"
        />
        <p className="text-[11px] text-slate-500 text-center">
          {W}×{H} · exports at full story resolution
        </p>
      </div>

      {/* ---------------- controls ---------------- */}
      <div className="glass-panel rounded-3xl p-5 space-y-5">
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <label htmlFor="sticker-prompt" className="text-xs font-semibold text-slate-300">
              Caption
            </label>
            <span className="text-[10px] text-slate-500 tabular-nums">
              {prompt.length}/{PROMPT_MAX}
            </span>
          </div>
          <textarea
            id="sticker-prompt"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            maxLength={PROMPT_MAX}
            rows={3}
            className="w-full rounded-xl bg-dark-900 border border-white/15 focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 px-3 py-2 text-sm text-white outline-none resize-y"
          />
          <button
            type="button"
            onClick={handleRoll}
            className="w-full flex items-center justify-center gap-2 rounded-xl border border-indigo-400/40 bg-indigo-500/15 hover:bg-indigo-500/25 py-2 text-xs font-semibold text-indigo-200 transition-colors"
          >
            <Shuffle className="w-3.5 h-3.5" />
            Roll me something
          </button>
        </div>

        <div className="space-y-1.5">
          <label htmlFor="sticker-presets" className="text-xs font-semibold text-slate-300">
            Presets
          </label>
          <div id="sticker-presets" className="flex flex-wrap gap-1.5">
            {PRESETS.map((preset) => (
              <button
                key={preset.id}
                type="button"
                onClick={() => setPrompt(preset.prompt)}
                className={[
                  'px-2.5 py-1 rounded-lg border text-[11px] font-medium transition-colors',
                  prompt === preset.prompt
                    // The selected chip uses the remapped plain `text-white`,
                    // not a pale indigo step. That step has no light-mode remap
                    // in index.css and rendered white-on-white. Written without
                    // naming the utility literally: both the Tailwind content
                    // glob and scripts/a11y-color.mjs scan raw source text,
                    // comments included, so naming it here would both emit an
                    // unused rule and register a phantom finding.
                    ? 'border-indigo-400/70 bg-indigo-500/20 text-white'
                    : 'border-white/10 bg-dark-900/60 text-slate-400 hover:text-slate-200 hover:border-white/25',
                ].join(' ')}
              >
                {preset.label}
              </button>
            ))}
          </div>
        </div>

        <div className="space-y-1.5">
          <label htmlFor="sticker-name" className="text-xs font-medium text-slate-400">
            Board name
          </label>
          <input
            id="sticker-name"
            type="text"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            maxLength={NAME_MAX}
            className="w-full rounded-lg bg-dark-900 border border-white/15 focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 px-3 py-2 text-xs text-white outline-none"
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="sticker-handle" className="text-xs font-medium text-slate-400">
            Your handle
          </label>
          <div className="flex items-center gap-2">
            <span className="text-[11px] text-slate-500 font-mono shrink-0">secretmsg.net/</span>
            <input
              id="sticker-handle"
              type="text"
              value={handle}
              onChange={(e) => setHandle(sanitizeHandle(e.target.value))}
              maxLength={HANDLE_MAX}
              placeholder="yourname"
              className="w-full rounded-lg bg-dark-900 border border-white/15 focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 px-3 py-2 text-xs text-white outline-none"
            />
          </div>
          <p className="text-[10px] text-slate-500">
            Letters, numbers, <code>_ . -</code> only. Appears on the card and in the file.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
          <button
            type="button"
            onClick={() =>
              void navigator.clipboard
                ?.writeText(prompt)
                .then(() => flash('caption'))
                .catch(() => undefined)
            }
            className="flex items-center justify-center gap-1.5 rounded-xl py-2.5 px-3 text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
          >
            {copied === 'caption' ? (
              <Check className="w-3.5 h-3.5 text-emerald-400" />
            ) : (
              <Copy className="w-3.5 h-3.5" />
            )}
            {copied === 'caption' ? 'Copied' : 'Caption'}
          </button>

          <button
            type="button"
            disabled={!handle}
            onClick={() =>
              void navigator.clipboard
                ?.writeText(`https://${data.url}`)
                .then(() => flash('link'))
                .catch(() => undefined)
            }
            className="flex items-center justify-center gap-1.5 rounded-xl py-2.5 px-3 text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors disabled:opacity-40"
          >
            {copied === 'link' ? (
              <Check className="w-3.5 h-3.5 text-emerald-400" />
            ) : (
              <Sparkles className="w-3.5 h-3.5" />
            )}
            {copied === 'link' ? 'Copied' : 'Link'}
          </button>

          <button
            type="button"
            onClick={() => void handleDownload()}
            disabled={busy}
            className="flex items-center justify-center gap-1.5 rounded-xl py-2.5 px-3 text-xs font-semibold bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 text-white shadow-lg shadow-indigo-500/20 transition-colors disabled:opacity-60"
          >
            <Download className="w-3.5 h-3.5" />
            {busy ? 'Saving…' : 'PNG'}
          </button>
        </div>

        <p className="text-[10px] text-slate-500 leading-relaxed">
          Exports a {W}×{H} PNG — the exact size an Instagram or Snapchat story expects.
          Post it, then add <code className="text-slate-400">secretmsg.net/yourname</code> as a
          story link sticker so replies land on your board.
        </p>
      </div>
    </div>
  );
};
