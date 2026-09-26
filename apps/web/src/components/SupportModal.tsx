import React, { useId } from 'react';
import { Link } from 'react-router-dom';
import { Heart, Shield, Smartphone, X, Ban, CreditCard, ScrollText } from 'lucide-react';
import { useDialogFocus } from '@/lib/useDialogFocus';

interface SupportModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const POINTS = [
  {
    icon: Smartphone,
    title: 'The Android app shows ads',
    desc: 'Google AdMob serves a banner and an optional rewarded video. That ad revenue is what pays for hosting and keeps the service running.',
  },
  {
    icon: Ban,
    title: 'This website shows no ads',
    desc: 'secretmsg.net loads no ad network code and no ad scripts. There is nothing to remove here and nothing to block.',
  },
  {
    icon: CreditCard,
    title: 'One purchase removes them',
    desc: 'A single in-app purchase, “Remove Ads,” turns off ads in the Android app. It is not a subscription and it does not renew. Your ad-free status follows your SecretMsg account.',
  },
];

export const SupportModal: React.FC<SupportModalProps> = ({ isOpen, onClose }) => {
  const titleId = useId();
  const dialogRef = useDialogFocus<HTMLDivElement>(isOpen, onClose);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-in fade-in duration-200">
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        className="glass-panel max-w-lg w-full rounded-2xl p-6 sm:p-8 space-y-6 relative max-h-[90vh] overflow-y-auto"
      >
        <button
          onClick={onClose}
          aria-label="Close dialog"
          className="absolute top-4 right-4 p-2 text-slate-400 hover:text-white rounded-lg hover:bg-white/5 transition-colors"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="text-center space-y-2">
          <div className="w-14 h-14 bg-amber-500/10 border border-amber-500/20 rounded-2xl flex items-center justify-center mx-auto text-amber-400 shadow-lg shadow-amber-500/10">
            <Heart className="w-7 h-7 fill-amber-400" />
          </div>
          <h3 id={titleId} className="text-2xl font-bold text-white tracking-tight">Support SecretMsg</h3>
          <p className="text-xs sm:text-sm text-slate-400 max-w-sm mx-auto">
            SecretMsg is an independent project. Here is exactly how paying for it works now — no website checkout, no subscriptions.
          </p>
        </div>

        <div className="space-y-2.5">
          {POINTS.map(({ icon: Icon, title, desc }) => (
            <div
              key={title}
              className="bg-dark-900/80 border border-white/10 p-4 rounded-xl space-y-1.5 hover:border-amber-500/30 transition-colors"
            >
              <div className="flex items-center space-x-2 text-xs font-semibold text-slate-200">
                <Icon className="w-4 h-4 text-amber-400 shrink-0" />
                <span>{title}</span>
              </div>
              <p className="text-[11px] text-slate-400 leading-relaxed">{desc}</p>
            </div>
          ))}
        </div>

        <div className="pt-2 space-y-3">
          <Link
            to="/download"
            onClick={onClose}
            className="w-full py-3.5 px-4 rounded-xl font-semibold text-sm bg-gradient-to-r from-blue-600 via-indigo-600 to-violet-600 hover:opacity-95 text-white shadow-lg shadow-indigo-500/25 flex items-center justify-center space-x-2 transition-all"
          >
            <Smartphone className="w-4 h-4" />
            <span>Get the Android App</span>
          </Link>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            <Link
              to="/supporters"
              onClick={onClose}
              className="py-2.5 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors text-center"
            >
              How Support Is Counted
            </Link>
            <Link
              to="/p/privacy"
              onClick={onClose}
              className="py-2.5 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors text-center flex items-center justify-center space-x-1.5"
            >
              <ScrollText className="w-3.5 h-3.5 text-indigo-300" />
              <span>Ads &amp; Your Choices</span>
            </Link>
          </div>

          <div className="flex items-center justify-center space-x-2 text-[11px] text-slate-500">
            <Shield className="w-3.5 h-3.5 text-emerald-400" />
            <span>Payments run through Google Play. This site takes no card details.</span>
          </div>
        </div>
      </div>
    </div>
  );
};
