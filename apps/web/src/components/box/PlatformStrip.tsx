import React, { useState } from 'react';
import { Flag, ShieldCheck } from 'lucide-react';
import { ReportWithConsent } from './ReportWithConsent';

interface PlatformStripProps {
  handle: string;
}

/**
 * Platform-owned strip that appears on every box page, themed or not (brief 1,
 * criterion 14). The report link works without login; it never asks for a PIN
 * or any account input, and it is the same component on the tombstone page so
 * a dead link still has a working report path.
 */
export const PlatformStrip: React.FC<PlatformStripProps> = ({ handle }) => {
  const [reportOpen, setReportOpen] = useState(false);
  return (
    <div className="mb-6 flex flex-wrap items-center justify-center gap-x-4 gap-y-2 rounded-xl border border-white/10 bg-black/30 px-4 py-2.5 text-[11px] text-slate-400">
      <span className="inline-flex items-center gap-1.5">
        <ShieldCheck className="h-3.5 w-3.5 text-emerald-400" aria-hidden="true" />
        SecretMsg never asks for your PIN on a box page.
      </span>
      <button
        type="button"
        onClick={() => setReportOpen(true)}
        className="box-report-link inline-flex items-center gap-1.5 rounded-lg border border-white/10 px-2 py-1 text-[11px] text-slate-300 hover:bg-white/5"
      >
        <Flag className="h-3 w-3" aria-hidden="true" />
        Report this page
      </button>
      {reportOpen && (
        <ReportWithConsent targetKind="box" targetId={handle} onClose={() => setReportOpen(false)} />
      )}
    </div>
  );
};
