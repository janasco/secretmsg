import React from 'react';
import { Link } from 'react-router-dom';

export const Footer: React.FC = () => {
  return (
    <footer className="pt-12 pb-8 border-t border-white/10 mt-12">
      <div className="max-w-6xl mx-auto px-4 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-8">
        <div>
          <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Platform</h4>
          <ul className="space-y-2 text-xs text-slate-500">
            <li><Link to="/" className="hover:text-slate-300 transition-colors">Home</Link></li>
            <li><Link to="/about" className="hover:text-slate-300 transition-colors">About Us</Link></li>
            <li><Link to="/supporters" className="hover:text-slate-300 transition-colors">Supporters Wall</Link></li>
            <li><Link to="/faq" className="hover:text-slate-300 transition-colors">Help & FAQs</Link></li>
            <li><Link to="/demo" className="hover:text-slate-300 transition-colors">Interactive Demo</Link></li>
          </ul>
        </div>

        <div>
          <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Explore</h4>
          <ul className="space-y-2 text-xs text-slate-500">
            <li><Link to="/dice" className="hover:text-slate-300 transition-colors">3D Dice Roulette</Link></li>
            <li><Link to="/sticker-studio" className="hover:text-slate-300 transition-colors">Sticker Studio</Link></li>
            <li><a href="https://github.com/janasco/secretmsg/releases" className="hover:text-slate-300 transition-colors">Android App (APK)</a></li>
            <li><a href="https://secretmsg.net/inbox" className="hover:text-slate-300 transition-colors">Anonymous Inbox</a></li>
          </ul>
        </div>

        <div>
          <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Safety</h4>
          <ul className="space-y-2 text-xs text-slate-500">
            <li><Link to="/p/safety" className="hover:text-slate-300 transition-colors">Safety Center</Link></li>
            <li><Link to="/p/child-safety-policy" className="hover:text-slate-300 transition-colors">Child Safety Policy</Link></li>
            <li><Link to="/p/approach-to-safety" className="hover:text-slate-300 transition-colors">Approach to Safety</Link></li>
            <li><Link to="/p/guide-to-online-safety" className="hover:text-slate-300 transition-colors">Online Safety Guide</Link></li>
            <li><Link to="/p/community-guidelines" className="hover:text-slate-300 transition-colors">Community Guidelines</Link></li>
            <li><Link to="/p/safety-tools" className="hover:text-slate-300 transition-colors">Our Safety Tools</Link></li>
            <li><Link to="/p/resources" className="hover:text-slate-300 transition-colors">Crisis Resources (988)</Link></li>
            <li><Link to="/p/contact-us" className="hover:text-slate-300 transition-colors">Contact & Escalations</Link></li>
          </ul>
        </div>

        <div>
          <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Legal</h4>
          <ul className="space-y-2 text-xs text-slate-500">
            <li><Link to="/p/privacy" className="hover:text-slate-300 transition-colors">Privacy Policy</Link></li>
            <li><Link to="/p/terms" className="hover:text-slate-300 transition-colors">Terms of Service</Link></li>
            <li><Link to="/p/cookies" className="hover:text-slate-300 transition-colors">Cookies Policy</Link></li>
            <li><Link to="/p/disclaimer" className="hover:text-slate-300 transition-colors">Disclaimer & Safety</Link></li>
          </ul>
        </div>

        <div>
          <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Connect</h4>
          <ul className="space-y-2 text-xs text-slate-500">
            <li><a href="https://github.com/janasco/secretmsg" target="_blank" rel="noopener noreferrer" className="hover:text-slate-300 transition-colors">GitHub Repository</a></li>
            <li><a href="mailto:support@secretmsg.net" className="hover:text-slate-300 transition-colors">support@secretmsg.net</a></li>
          </ul>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 mt-8 pt-6 border-t border-white/5 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-600 gap-2">
        <span>&copy; 2026 secretmsg.net</span>
        <span>Personal Project by janasco</span>
        <span className="text-slate-600">Deepening authentic connections, safely.</span>
      </div>
    </footer>
  );
};