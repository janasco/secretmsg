import React from 'react';
import { Link } from 'react-router-dom';
import { Heart, Sparkles, LogOut, User, Lock, Smartphone } from 'lucide-react';
import { UserProfile } from '../lib/api';

interface NavbarProps {
  user: UserProfile | null;
  onOpenDonation: () => void;
  onLogout: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ user, onOpenDonation, onLogout }) => {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-white/10 bg-dark-950/80 backdrop-blur-md">
      <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
        {/* Logo & Brand */}
        <Link to="/" className="flex items-center space-x-2.5 group">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-indigo-600 to-amber-500 p-0.5 shadow-lg shadow-indigo-500/20 group-hover:scale-105 transition-transform">
            <div className="w-full h-full bg-dark-900 rounded-[10px] flex items-center justify-center">
              <Lock className="w-4 h-4 text-indigo-400" />
            </div>
          </div>
          <div className="flex flex-col">
            <span className="font-bold text-lg tracking-tight bg-gradient-to-r from-white via-slate-100 to-indigo-300 bg-clip-text text-transparent">
              secretmsg<span className="text-amber-400">.net</span>
            </span>
          </div>
        </Link>

        {/* Navigation Actions */}
        <div className="flex items-center space-x-2 sm:space-x-3">
          <a
            href="https://m.secretmsg.net"
            className="text-xs text-slate-400 hover:text-slate-200 px-2.5 py-1.5 rounded-lg hover:bg-white/5 transition-colors font-medium hidden sm:flex items-center space-x-1"
            title="Open touch-optimized mobile web version"
          >
            <Smartphone className="w-3.5 h-3.5 text-indigo-400" />
            <span>Mobile App</span>
          </a>

          <Link
            to="/supporters"
            className="text-xs text-slate-400 hover:text-slate-200 px-2.5 py-1.5 rounded-lg hover:bg-white/5 transition-colors font-medium flex items-center space-x-1"
          >
            <span>Supporters</span>
          </Link>

          {/* Donation / Support Button */}
          <button
            onClick={onOpenDonation}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-amber-500/10 text-amber-300 border border-amber-500/20 hover:bg-amber-500/20 hover:border-amber-500/30 transition-colors shadow-sm"
          >
            <Heart className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
            <span className="hidden sm:inline">Donate & Unlock Perks</span>
            <span className="sm:hidden">Donate</span>
          </button>

          {user ? (
            <div className="flex items-center space-x-2">
              <Link
                to="/inbox"
                className="px-3.5 py-1.5 rounded-lg text-sm font-medium bg-indigo-600 hover:bg-indigo-500 text-white transition-colors shadow-sm flex items-center space-x-1.5"
              >
                <Sparkles className="w-4 h-4" />
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
              className="px-4 py-1.5 rounded-lg text-sm font-medium bg-white/10 hover:bg-white/15 text-white transition-colors border border-white/10"
            >
              Get Your Link
            </Link>
          )}
        </div>
      </div>
    </header>
  );
};
