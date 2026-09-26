import { isAssetRequest, isClientRoute, isNoindexRoute, legacyRedirect, notFoundHtml, postSlug } from './route-policy';
import { loadPostSlugs } from './post-slugs';
import { SECURITY_HEADERS } from './security-headers';

export interface AssetBinding {
  fetch(input: Request | URL | string): Promise<Response>;
}

export interface WorkerEnv {
  ASSETS: AssetBinding;
}

const NOT_FOUND_HEADERS = {
  ...SECURITY_HEADERS,
  'cache-control': 'no-store',
  'content-type': 'text/html; charset=utf-8',
};

function notFound(): Response {
  return new Response(notFoundHtml, { status: 404, headers: { ...NOT_FOUND_HEADERS } });
}

function withSecurityHeaders(response: Response, extra: Record<string, string> = {}): Response {
  const headers = new Headers(response.headers);
  for (const [name, value] of Object.entries(SECURITY_HEADERS)) headers.set(name, value);
  for (const [name, value] of Object.entries(extra)) headers.set(name, value);
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export async function handleRequest(request: Request, env: WorkerEnv): Promise<Response> {
  const url = new URL(request.url);
  const redirect = legacyRedirect(url.pathname);
  if (redirect) {
    return new Response(null, {
      status: 301,
      headers: {
        ...SECURITY_HEADERS,
        location: redirect,
      },
    });
  }

  const methodAllowed = request.method === 'GET' || request.method === 'HEAD';
  if (!methodAllowed || isAssetRequest(url.pathname, url.search) || !isClientRoute(url.pathname)) {
    return notFound();
  }

  // A post slug the build does not ship. This is the only status this Worker
  // changes, and it is deliberately the narrow one: a live post has a
  // prerendered page in dist and is answered by the asset layer before the
  // Worker runs, so this branch only ever sees slugs that do not exist. Nothing
  // else moves — /:username, /inbox, /settings and /reply/:token stay 200,
  // because a 404 on somebody's shareable board link is a product decision,
  // not a routing detail.
  const slug = postSlug(url.pathname);
  if (slug !== null) {
    const slugs = await loadPostSlugs(env.ASSETS, url);
    if (slugs && !slugs.has(slug)) return notFound();
  }

  const shellRequest = new Request(new URL('/', url), request);
  const noindex = isNoindexRoute(url.pathname) ? { 'x-robots-tag': 'noindex' } : undefined;
  return withSecurityHeaders(await env.ASSETS.fetch(shellRequest), noindex);
}

export default {
  fetch: handleRequest,
};
