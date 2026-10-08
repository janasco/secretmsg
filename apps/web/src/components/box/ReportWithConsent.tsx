import React, { useState } from 'react';
import { Flag, X } from 'lucide-react';
import { useDialogFocus } from '@/lib/useDialogFocus';
import { BoxApi } from './box-api';

type ReportKind = 'box' | 'group_post' | 'member_box' | 'reaction' | 'group';

interface ReportWithConsentProps {
  targetKind: ReportKind;
  targetId: string;
  audience?: 'platform' | 'owner';
  /** Only offer item disclosure where the reporter actually holds a copy. */
  allowDisclosure?: boolean;
  disclosureLabel?: string;
  /** Provided by the caller when the reporter's plaintext copy is available. */
  disclosurePayload?: string;
  onClose: () => void;
}

/**
 * Consent is the point of this dialog, not a checkbox buried in a settings
 * page. Defaults: no disclosure, no reason preselected, nothing uploaded
 * unless the reporter submits. The copy names exactly what is shared, at the
 * moment the choice is made.
 */
export const ReportWithConsent: React.FC<ReportWithConsentProps> = ({
  targetKind,
  targetId,
  audience = 'platform',
  allowDisclosure = false,
  disclosureLabel = 'this item',
  disclosurePayload,
  onClose,
}) => {
  const dialogRef = useDialogFocus<HTMLDivElement>(true, onClose);
  const [reason, setReason] = useState('');
  const [includeCopy, setIncludeCopy] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState<string | null>(null);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (busy) return;
    setBusy(true);
    setError(null);
    try {
      const res = await BoxApi.report({
        target_kind: targetKind,
        target_id: targetId,
        reason,
        audience,
        ...(includeCopy && disclosurePayload
          ? { consent: true, disclosed_payload: disclosurePayload }
          : {}),
      });
      setDone(res.message || 'Report received.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Report failed. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[70] flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/70" onClick={onClose} aria-hidden="true" />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="box-report-title"
        className="relative w-full max-w-md rounded-2xl border border-white/10 bg-dark-900 p-6 text-slate-100 shadow-2xl"
      >
        <button
          type="button"
          onClick={onClose}
          aria-label="Close report dialog"
          className="absolute right-3 top-3 rounded-lg p-1.5 text-slate-400 hover:text-white"
        >
          <X className="h-4 w-4" />
        </button>

        <h2 id="box-report-title" className="flex items-center gap-2 text-base font-semibold text-white">
          <Flag className="h-4 w-4 text-rose-400" /> Report
        </h2>

        {done ? (
          <div className="mt-4 space-y-4">
            <p className="text-sm text-slate-300">{done}</p>
            <button
              type="button"
              onClick={onClose}
              className="w-full rounded-xl border border-white/10 bg-white/10 py-2.5 text-xs font-semibold text-white hover:bg-white/15"
            >
              Close
            </button>
          </div>
        ) : (
          <form onSubmit={submit} className="mt-4 space-y-4">
            <label className="block text-xs text-slate-300">
              What is wrong?
              <textarea
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                maxLength={200}
                rows={3}
                required
                minLength={3}
                placeholder="Impersonation, harassment, phishing, something else…"
                className="mt-1.5 w-full resize-none rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-sm text-white placeholder:text-slate-500 focus:border-indigo-400 focus:outline-none"
              />
            </label>

            {allowDisclosure && disclosurePayload && (
              <label className="flex items-start gap-2.5 rounded-xl border border-white/10 bg-white/5 p-3 text-xs text-slate-300">
                <input
                  type="checkbox"
                  checked={includeCopy}
                  onChange={(e) => setIncludeCopy(e.target.checked)}
                  className="mt-0.5 h-4 w-4 accent-indigo-500"
                />
                <span>
                  Include my copy of {disclosureLabel} with this report.
                  <span className="mt-1 block text-[11px] text-slate-400">
                    Reporting shows us this item so we can review it. Nothing else is shared.
                  </span>
                </span>
              </label>
            )}

            {error && <p className="text-xs text-rose-400">{error}</p>}

            <p className="text-[11px] leading-relaxed text-slate-500">
              Reports are reviewed by a person. Filing one never messages the other party.
            </p>

            <button
              type="submit"
              disabled={busy || reason.trim().length < 3}
              className="w-full rounded-xl bg-rose-500 py-2.5 text-xs font-semibold text-white transition-colors hover:bg-rose-400 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {busy ? 'Sending…' : 'Submit report'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
};
