import React from 'react';
import { Navigate, useParams } from 'react-router-dom';

/**
 * Legacy /legal/:doc URLs. These used to render an abbreviated copy of each
 * document, which meant users agreed to a summary rather than the real terms.
 * The route is kept so existing links keep resolving, but it now forwards to
 * the canonical /p/* document.
 */
const CANONICAL: Record<string, string> = {
  terms: '/p/terms',
  privacy: '/p/privacy',
  cookies: '/p/cookies',
  disclaimer: '/p/disclaimer',
};

export const LegalPage: React.FC = () => {
  const { doc } = useParams<{ doc: string }>();
  const target = CANONICAL[(doc || '').toLowerCase()] ?? '/p/terms';

  if (
    typeof window !== 'undefined' &&
    window.location.hostname !== 'secretmsg.net' &&
    window.location.hostname.endsWith('secretmsg.net')
  ) {
    window.location.replace(`https://secretmsg.net${target}`);
    return null;
  }

  return <Navigate to={target} replace />;
};
