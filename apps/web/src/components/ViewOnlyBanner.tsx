import React from 'react';
import { Eye, Smartphone } from 'lucide-react';
import { ApiClient } from '../lib/api';

/**
 * Shown while this browser is paired from the Android app.
 *
 * A paired session carries a read-only token: the API answers 403 on every
 * write. Without this the page would keep offering Reply and Delete buttons
 * that fail on click, so the restriction is stated up front instead.
 */
export const ViewOnlyBanner: React.FC = () => {
  if (!ApiClient.isReadOnly()) return null;

  return (
    <div className="bg-amber-500/10 border-b border-amber-500/20">
      <div className="max-w-5xl mx-auto px-4 py-2 flex items-center gap-2 text-[11px] sm:text-xs text-amber-200/90">
        <Eye className="w-3.5 h-3.5 shrink-0" />
        <span>
          <strong className="font-semibold">View-only.</strong>{' '}
          This browser is paired from the app, so you can read your inbox but not reply or change settings.
        </span>
        <span className="ml-auto hidden sm:flex items-center gap-1 text-amber-200/60 shrink-0">
          <Smartphone className="w-3.5 h-3.5" />
          Use the app to make changes
        </span>
      </div>
    </div>
  );
};

/**
 * Inline replacement for a control that a paired session cannot use.
 */
export const ViewOnlyNote: React.FC<{ children: React.ReactNode; className?: string }> = ({
  children,
  className = '',
}) => (
  <div
    className={
      'flex items-center gap-1.5 text-[11px] text-slate-500 bg-white/[0.02] border border-white/5 rounded-lg px-2.5 py-1.5 ' +
      className
    }
  >
    <Eye className="w-3.5 h-3.5 shrink-0 text-slate-400" />
    <span>{children}</span>
  </div>
);
