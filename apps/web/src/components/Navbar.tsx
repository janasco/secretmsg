import React from 'react';
import { Link } from 'react-router-dom';
import { Heart, Sparkles, LogOut, User } from 'lucide-react';
import { UserProfile } from '../lib/api';

const LogoIcon = ({ className = 'w-8 h-8' }: { className?: string }) => (
  <svg viewBox="0 0 64 64" className={className}>
    <defs>
      <linearGradient id="navIconGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style={{ stopColor: '#8b5cf6' }} />
        <stop offset="100%" style={{ stopColor: '#6366f1' }} />
      </linearGradient>
    </defs>
    <rect width="64" height="64" rx="14" fill="#0f172a" />
    <g transform="translate(10, 10)">
      <rect x="2" y="2" width="20" height="20" rx="5" fill="url(#navIconGrad)" />
      <rect x="7" y="7" width="10" height="10" rx="3" fill="#0f172a" />
      <rect x="16" y="16" width="20" height="20" rx="5" fill="url(#navIconGrad)" />
      <rect x="21" y="21" width="10" height="10" rx="3" fill="#0f172a" />
    </g>
  </svg>
);

interface NavbarProps {
  user: UserProfile | null;
  onOpenDonation: () => void;
  onLogout: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ user, onOpenDonation, onLogout }) => {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-white/10 bg-dark-950/80 backdrop-blur-md">
      <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2 group shrink-0">
          <LogoIcon className="w-8 h-8 group-hover:scale-105 transition-transform" />
          <span className="font-bold text-base tracking-tight bg-gradient-to-r from-white via-slate-100 to-indigo-300 bg-clip-text text-transparent hidden xs:inline">
            secretmsg<span className="text-indigo-400">.net</span>
          </span>
        </Link>

        <div className="flex items-center gap-1.5 sm:gap-2">
          <button
            onClick={onOpenDonation}
            className="flex items-center gap-1 px-2.5 py-1.5 rounded-full text-xs font-medium bg-amber-500/10 text-amber-300 border border-amber-500/20 hover:bg-amber-500/20 hover:border-amber-500/30 transition-colors shadow-sm"
          >
            <Heart className="w-3.5 h-3.5 fill-amber-400 text-amber-400 shrink-0" />
            <span className="hidden sm:inline">Donate & Unlock Perks</span>
            <span className="sm:hidden">Donate</span>
          </button>

          {user ? (
            <div className="flex items-center gap-1.5">
              <Link
                to="/inbox"
                className="px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium bg-indigo-600 hover:bg-indigo-500 text-white transition-colors shadow-sm flex items-center gap-1.5"
              >
                <Sparkles className="w-4 h-4 shrink-0" />
                <span>Inbox</span>
              </Link>
              <Link
                to="/settings"
                title="Account Settings"
                className="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-dark-800 transition-colors"
              >
                <User className="w-4 h-4" />
              </Link>
              <button
                onClick={onLogout}
                title="Log Out"
                className="p-2 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-dark-800 transition-colors"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <Link
              to="/login"
              className="px-3 sm:px-4 py-1.5 rounded-lg text-xs sm:text-sm font-medium bg-indigo-600 hover:bg-indigo-500 text-white transition-colors shadow-sm flex items-center gap-1.5"
            >
              <span className="hidden sm:inline">Get Your Link</span>
              <span className="sm:hidden">Get Link</span>
            </Link>
          )}
        </div>
      </div>
    </header>
  );
};
