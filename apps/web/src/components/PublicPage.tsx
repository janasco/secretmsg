import React from 'react';
import { Link } from 'react-router-dom';

interface PublicPageProps {
  title: string;
  eyebrow?: string;
  description?: string;
  children: React.ReactNode;
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

export const PublicPage: React.FC<PublicPageProps> = ({ title, eyebrow, description, children }) => {
  usePublicHostRedirect();

  return (
    <div className="max-w-3xl mx-auto px-4 py-10 sm:py-14">
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
        <h1 className="text-3xl sm:text-4xl font-black text-white tracking-tight leading-tight">{title}</h1>
        {description && (
          <p className="text-slate-300 text-sm sm:text-base leading-relaxed max-w-2xl mx-auto mt-3">{description}</p>
        )}
      </div>

      {children}
    </div>
  );
};