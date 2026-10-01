import React from 'react';
import { Link } from 'react-router-dom';

interface PublicPageProps {
  title: string;
  eyebrow?: string;
  description?: string;
  children: React.ReactNode;
  /**
   * Opt out of the 768px reading column. Only for genuinely wide tools — the
   * Sticker Studio needs room for a 9:16 preview beside its controls, and at
   * max-w-3xl the canvas collapsed to about 140px.
   */
  wide?: boolean;
}

const PUBLIC_HOST = 'secretmsg.net';

export const usePublicHostRedirect = (): void => {
  React.useEffect(() => {
    if (typeof window === 'undefined') return;
    const host = window.location.hostname;
    if (host !== PUBLIC_HOST && host.endsWith('secretmsg.net')) {
      window.location.replace(`${window.location.protocol}//${PUBLIC_HOST}${window.location.pathname}${window.location.search}`);
    }
  }, []);
};

export const PublicPage: React.FC<PublicPageProps> = ({ title, eyebrow, description, children, wide }) => {
  usePublicHostRedirect();

  return (
    <div className={`mx-auto px-4 py-10 sm:py-14 ${wide ? 'max-w-7xl' : 'max-w-3xl'}`}>
      <Link
        to="/"
        className="inline-flex items-center gap-1.5 text-xs text-slate-400 hover:text-white transition-colors mb-8"
      >
        <span className="text-base leading-none">←</span>
        <span>Back to secretmsg.net</span>
      </Link>

      <div className="text-center mb-10 sm:mb-12">
        {eyebrow && (
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-indigo-500/10 border border-indigo-500/20 text-indigo-300 text-xs font-semibold mb-4">
            {eyebrow}
          </div>
        )}
        {/* `display-2` rather than an ad-hoc size: this heading is rendered for
            21 public pages, so the scale belongs here once rather than being
            re-picked on each of them. */}
        <h1 className="display-2 text-white">{title}</h1>
        {description && (
          <p className="text-slate-300 text-sm sm:text-base leading-relaxed max-w-2xl mx-auto mt-3">{description}</p>
        )}
      </div>

      {children}
    </div>
  );
};