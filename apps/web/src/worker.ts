import { isAssetRequest, legacyRedirect, notFoundHtml } from './route-policy';

export interface AssetBinding {
  fetch(input: Request | URL | string): Promise<Response>;
}

export interface WorkerEnv {
  ASSETS: AssetBinding;
}

export async function handleRequest(request: Request, env: WorkerEnv): Promise<Response> {
  const url = new URL(request.url);
  const redirect = legacyRedirect(url.pathname);
  if (redirect) {
    return new Response(null, {
      status: 301,
      headers: { location: redirect },
    });
  }

  if (request.method !== 'GET' || isAssetRequest(url.pathname)) {
    return new Response(notFoundHtml, {
      status: 404,
      headers: {
        'cache-control': 'no-store',
        'content-type': 'text/html; charset=utf-8',
      },
    });
  }

  return env.ASSETS.fetch(new URL('/index.html', url));
}

export default {
  fetch: handleRequest,
};
