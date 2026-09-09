import React from 'react';
import { Link } from 'react-router-dom';
import { Heart, Sparkles, Shield, Check, ExternalLink, X, Github } from 'lucide-react';

interface DonationModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const PERKS = [
  {
    title: 'Custom Vanity Link',
    desc: 'Claim clean personal URLs like secretmsg.net/alex without numbers or random characters.',
  },
  {
    title: 'Double-Blind Anonymous Replies',
    desc: 'Send replies back to anonymous senders safely without compromising anyone’s privacy.',
  },
  {
    title: 'GitHub Issue Funding & Bounties',
    desc: 'Back specific roadmap features or bug bounties directly on our GitHub repository via Polar.',
  },
  {
    title: 'Instagram & TikTok Story Themes',
    desc: 'Unlock exclusive vibrant gradients and high-res export formats for your social stories.',
  },
  {
    title: 'Broad Sender Hint Clues',
    desc: 'See non-identifying hints (e.g. device type or rough time zone) if the sender opted in.',
  },
  {
    title: 'Golden Supporter Badge',
    desc: 'Display a tasteful gold badge on your profile and story cards to show community support.',
  },
];

export const DonationModal: React.FC<DonationModalProps> = ({ isOpen, onClose }) => {
  const donationUrl = (import.meta as any).env?.VITE_DONATION_URL || 'https://polar.sh/janasco/secretmsg';

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-in fade-in duration-200">
      <div className="glass-panel max-w-lg w-full rounded-2xl p-6 sm:p-8 space-y-6 relative max-h-[90vh] overflow-y-auto">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 text-slate-400 hover:text-white rounded-lg hover:bg-white/5 transition-colors"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Header */}
        <div className="text-center space-y-2">
          <div className="w-14 h-14 bg-indigo-500/10 border border-indigo-500/20 rounded-2xl flex items-center justify-center mx-auto text-indigo-400 shadow-lg shadow-indigo-500/10">
            <Heart className="w-7 h-7 fill-indigo-400" />
          </div>
          <h3 className="text-2xl font-bold text-white tracking-tight">Support SecretMsg on Polar</h3>
          <p className="text-xs sm:text-sm text-slate-400 max-w-sm mx-auto">
            SecretMsg is an open-source personal project. We use <span className="text-indigo-300 font-semibold">Polar.sh</span> for GitHub issue funding and transparent community sponsorship.
          </p>
        </div>

        {/* Supporter Perks Grid */}
        <div className="space-y-3">
          <h4 className="text-xs font-semibold text-indigo-400 uppercase tracking-wider flex items-center space-x-1.5">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Unlocked Supporter Perks</span>
          </h4>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
            {PERKS.map((perk, i) => (
              <div
                key={i}
                className="bg-dark-900/80 border border-white/10 p-3 rounded-xl space-y-1 hover:border-indigo-500/30 transition-colors"
              >
                <div className="flex items-center space-x-2 text-xs font-semibold text-slate-200">
                  <Check className="w-3.5 h-3.5 text-indigo-400 shrink-0" />
                  <span>{perk.title}</span>
                </div>
                <p className="text-[11px] text-slate-400 leading-snug pl-5.5">{perk.desc}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Donation CTA */}
        <div className="pt-2 space-y-3">
          <a
            href={donationUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full py-3.5 px-4 rounded-xl font-semibold text-sm bg-gradient-to-r from-blue-600 via-indigo-600 to-violet-600 hover:opacity-95 text-white shadow-lg shadow-indigo-500/25 flex items-center justify-center space-x-2 transition-all group"
          >
            <Github className="w-4 h-4" />
            <span>Sponsor & Fund Issues on Polar.sh</span>
            <ExternalLink className="w-4 h-4 opacity-75 group-hover:translate-x-0.5 transition-transform" />
          </a>

          <div className="text-center pt-1">
            <Link
              to="/supporters"
              onClick={onClose}
              className="text-xs text-indigo-400 hover:text-indigo-300 font-medium hover:underline inline-flex items-center space-x-1"
            >
              <span>View Wall of Anonymous Donors</span>
              <span>→</span>
            </Link>
          </div>

          <div className="flex items-center justify-center space-x-2 text-[11px] text-slate-500">
            <Shield className="w-3.5 h-3.5 text-emerald-400" />
            <span>Open-source issue funding. Powered by Polar.sh.</span>
          </div>
        </div>
      </div>
    </div>
  );
};
