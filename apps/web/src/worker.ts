import { isAssetRequest, isClientRoute, legacyRedirect, notFoundHtml } from './route-policy';
import { SECURITY_HEADERS } from './security-headers';

export interface AssetBinding {
  fetch(input: Request | URL | string): Promise<Response>;
}

export interface WorkerEnv {
  ASSETS: AssetBinding;
}

function withSecurityHeaders(response: Response): Response {
  const headers = new Headers(response.headers);
  for (const [name, value] of Object.entries(SECURITY_HEADERS)) headers.set(name, value);
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
    return new Response(notFoundHtml, {
      status: 404,
      headers: {
        ...SECURITY_HEADERS,
        'cache-control': 'no-store',
        'content-type': 'text/html; charset=utf-8',
      },
    });
  }

  const shellRequest = new Request(new URL('/', url), request);
  return withSecurityHeaders(await env.ASSETS.fetch(shellRequest));
}

export default {
  fetch: handleRequest,
};
