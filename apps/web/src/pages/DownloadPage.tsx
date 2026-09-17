import React, { useState } from 'react';
import { Download, Check, Copy, ShieldCheck, BellRing, Play } from 'lucide-react';
import { PublicPage } from '@/components/PublicPage';
import { APK_VERSION, APK_VARIANTS, APK_PRIMARY } from '@/lib/appVersion';

const STEPS = [
  {
    n: '1',
    title: 'Download the APK',
    body: 'Tap the button below. Your browser will warn that APKs can harm your device — that warning appears for every app installed outside a store.',
  },
  {
    n: '2',
    title: 'Allow this install',
    body: 'When prompted, allow installs from your browser (Chrome → Install unknown apps → Allow). Android 8.0+ asks per-app, not globally.',
  },
  {
    n: '3',
    title: 'Open & sign in',
    body: 'Open SecretMsg, create a handle + PIN (or log in), and save your backup codes. Pair your browser from Settings if you like.',
  },
];

export const DownloadPage: React.FC = () => {
  const [copiedHash, setCopiedHash] = useState(false);

  const copyHash = () => {
    navigator.clipboard?.writeText(APK_PRIMARY.sha256);
    setCopiedHash(true);
    setTimeout(() => setCopiedHash(false), 2000);
  };

  return (
    <PublicPage
      title="Get the Android App"
      eyebrow="Free • Open Source"
      description="The native SecretMsg experience: Daily Drop ritual, streaks, bot-checked sending, inbox with double-blind replies, ranks, challenges, badges, and Play-verified supporter perks."
    >
      <div className="space-y-6">
        {/* Current build */}
        <div className="glass-panel p-6 sm:p-8 rounded-3xl border-emerald-500/20 space-y-5">
          <div className="flex flex-col sm:flex-row sm:items-center gap-4">
            <div className="w-14 h-14 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 shrink-0">
              <Download className="w-6 h-6" />
            </div>
            <div className="flex-1 space-y-1">
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-lg font-bold text-white">SecretMsg for Android</h2>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/15 text-emerald-300 border border-emerald-500/20 font-mono">
                  {APK_VERSION}
                </span>
              </div>
              <p className="text-xs text-slate-400 font-mono">
                {APK_PRIMARY.file} • {APK_PRIMARY.size} • Android 8.0+
              </p>
            </div>
          </div>

          <a
            href={`/downloads/${APK_PRIMARY.file}`}
            download={APK_PRIMARY.file}
            className="w-full py-3.5 px-4 rounded-xl font-semibold text-sm bg-gradient-to-r from-emerald-600 to-emerald-500 hover:opacity-95 text-white shadow-lg shadow-emerald-500/25 flex items-center justify-center space-x-2 transition-all"
          >
            <Download className="w-4 h-4" />
            <span>Download APK ({APK_PRIMARY.size})</span>
          </a>

          <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-[11px] text-slate-500">
            <span>Other architectures:</span>
            {APK_VARIANTS.slice(1).map((v) => (
              <a
                key={v.file}
                href={`/downloads/${v.file}`}
                download={v.file}
                className="text-indigo-400 hover:text-indigo-300 font-mono"
              >
                {v.label} ({v.size})
              </a>
            ))}
          </div>

          <div className="bg-dark-900 border border-white/10 rounded-xl p-3.5 space-y-2">
            <div className="flex items-center justify-between gap-2">
              <span className="text-[11px] font-semibold text-slate-300 flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
                SHA-256 checksum
              </span>
              <button
                onClick={copyHash}
                className="p-1.5 text-slate-400 hover:text-white rounded-lg hover:bg-white/5 transition-colors"
                title="Copy checksum"
              >
                {copiedHash ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
            </div>
            <p className="text-[11px] font-mono text-slate-500 break-all select-all">{APK_PRIMARY.sha256}</p>
            <p className="text-[11px] text-slate-500">
              After downloading, compare the file's hash to verify it wasn't tampered with in transit.
            </p>
          </div>
        </div>

        {/* Install steps */}
        <div className="glass-panel p-6 rounded-3xl space-y-4">
          <h2 className="text-base font-bold text-white">Installing in 3 steps</h2>
          <div className="space-y-3">
            {STEPS.map((s) => (
              <div key={s.n} className="flex gap-3">
                <div className="w-7 h-7 rounded-full bg-indigo-500/15 border border-indigo-500/30 flex items-center justify-center text-xs font-bold text-indigo-300 shrink-0">
                  {s.n}
                </div>
                <div className="space-y-0.5">
                  <h3 className="text-sm font-semibold text-white">{s.title}</h3>
                  <p className="text-xs text-slate-400 leading-relaxed">{s.body}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Play Store / AAB status */}
        <div className="glass-panel p-6 rounded-3xl space-y-4 border-amber-500/20">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center text-white shrink-0">
              <Play className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-white">Google Play</h2>
              <p className="text-xs text-slate-400">Signed AAB build — in review prep, coming soon.</p>
            </div>
            <span className="ml-auto inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-bold bg-white/5 text-slate-400 border border-white/10 uppercase tracking-wider shrink-0">
              <BellRing className="w-3 h-3" />
              Soon
            </span>
          </div>
          <p className="text-xs text-slate-400 leading-relaxed">
            The Play release ships as a signed Android App Bundle with Play-verified supporter
            perks (Verified Badge, Viewer/Sender Hints). Until then, the APK above is the
            current build — same features, direct from this site.
          </p>
        </div>
      </div>
    </PublicPage>
  );
};
