import React, { useEffect, useRef, useState } from 'react';

interface TurnstileApi {
  render: (container: HTMLElement, options: Record<string, unknown>) => string;
  remove: (id: string) => void;
}

const TURNSTILE_SITE_KEY = import.meta.env?.VITE_TURNSTILE_SITE_KEY || '';
export const TURNSTILE_CONFIGURED = TURNSTILE_SITE_KEY.length > 0;

// NOTE: window.turnstile is already typed in ComposeModal.tsx — accessed
// loosely here to avoid duplicate global declarations.
const getTs = (): TurnstileApi | null =>
  (window as unknown as { turnstile?: TurnstileApi }).turnstile ?? null;

/**
 * Shared Cloudflare bot-check. Renders explicitly into its own box and
 * reports the token upward; parents disable submission until a token
 * exists (backend fails closed without one).
 */
export const TurnstileWidget: React.FC<{ onToken: (token: string | null) => void }> = ({ onToken }) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const widgetIdRef = useRef<string | null>(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    if (!TURNSTILE_CONFIGURED) return;
    let cancelled = false;
    let pollId: ReturnType<typeof setInterval> | null = null;

    const renderWidget = () => {
      const ts = getTs();
      if (!ts || !containerRef.current || cancelled) return;
      try {
        widgetIdRef.current = ts.render(containerRef.current, {
          sitekey: TURNSTILE_SITE_KEY,
          theme: document.documentElement.classList.contains('dark') ? 'dark' : 'light',
          callback: (token: string) => {
            setFailed(false);
            onToken(token);
          },
          'expired-callback': () => onToken(null),
          'error-callback': () => {
            setFailed(true);
            onToken(null);
          },
        });
      } catch {
        setFailed(true);
      }
    };

    if (getTs()) {
      renderWidget();
    } else {
      pollId = setInterval(() => {
        if (getTs()) {
          if (pollId) clearInterval(pollId);
          renderWidget();
        }
      }, 100);
      setTimeout(() => {
        if (pollId) clearInterval(pollId);
        if (!widgetIdRef.current && !cancelled) setFailed(true);
      }, 15000);
    }

    return () => {
      cancelled = true;
      if (pollId) clearInterval(pollId);
      const ts = getTs();
      if (widgetIdRef.current && ts) {
        try {
          ts.remove(widgetIdRef.current);
        } catch {
          /* already gone */
        }
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (!TURNSTILE_CONFIGURED) return null;

  return (
    <div className="space-y-1">
      <div ref={containerRef} className="flex justify-center min-h-[65px]" />
      {failed && (
        <p className="text-[11px] text-rose-400 text-center">
          Verification failed to load — check your connection and refresh.
        </p>
      )}
    </div>
  );
};
