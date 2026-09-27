import { isAssetRequest, isClientRoute, isNoindexRoute, legacyRedirect, notFoundHtml, postSlug } from './route-policy';
import { loadPostSlugs } from './post-slugs';
import { CSP_REPORT_MAX_BYTES, CSP_REPORT_PATH, SECURITY_HEADERS } from './security-headers';

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

// no-store because a report is never cacheable: a cache that stored one would
// let a burst of reports be answered from cache, which is the one way this
// endpoint could be turned into an amplifier. The size cap is the other half of
// that story, and it lives in security-headers.ts next to the path the policy
// names. What an attacker can still do is fill Workers Logs, which is a
// Cloudflare rate-limiting or WAF rule away and deliberately not a Durable
// Object.
const CSP_REPORT_HEADERS = { ...SECURITY_HEADERS, 'cache-control': 'no-store' };

// What the browser sends, and how much of it is worth reading. Only the
// report-uri media type is accepted, because that is the only one the policy
// asks for: a second accepted shape would be a claim nobody can test, and a
// report the sink rejects shows up in the browser console instead of nowhere.
const CSP_REPORT_CONTENT_TYPES = new Set(['application/csp-report']);
const CSP_REPORT_FIELDS = [
  'document-uri',
  'effective-directive',
  'violated-directive',
  'blocked-uri',
  'disposition',
  'source-file',
  'line-number',
  'column-number',
  'sample',
];
const CSP_REPORT_FIELD_LIMIT = 200;

function notFound(): Response {
  return new Response(notFoundHtml, { status: 404, headers: { ...NOT_FOUND_HEADERS } });
}

/** Read at most `limit` bytes, or null if the body is larger than that. */
async function readBounded(request: Request, limit: number): Promise<string | null> {
  if (!request.body) return '';
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > limit) {
        await reader.cancel();
        return null;
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const body = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder().decode(body);
}

/**
 * One report, reduced to the fields a reader needs and truncated so that one
 * hostile report cannot push everything else out of the log. report-uri (CSP3
 * §5.5) wraps the report in "csp-report"; a bare object is read as the report
 * itself, so an unexpected shape is still logged rather than dropped.
 */
function summarizeCspReport(body: string): Record<string, unknown> {
  let parsed: unknown;
  try {
    parsed = JSON.parse(body);
  } catch {
    return { unreadable: body.slice(0, CSP_REPORT_FIELD_LIMIT) };
  }
  const envelope = (typeof parsed === 'object' && parsed !== null ? parsed : {}) as Record<string, unknown>;
  const report = envelope['csp-report'] ?? envelope;
  const fields = (typeof report === 'object' && report !== null ? report : {}) as Record<string, unknown>;
  return {
    report: Object.fromEntries(CSP_REPORT_FIELDS
      .filter((name) => fields[name] !== undefined && fields[name] !== null)
      .map((name) => [name, String(fields[name]).slice(0, CSP_REPORT_FIELD_LIMIT)])),
  };
}

/**
 * The one POST this Worker answers: CSP violation reports for the
 * report-only policy in security-headers.ts. It has to exist at all, because
 * a report-uri whose request fails is just a console error nobody reads — the
 * browser logs the violation and moves on. Workers Logs captures console output,
 * so one line here is the whole sink: no storage, no forwarding to the API, and
 * nothing sent back.
 *
 * Only POST on CSP_REPORT_PATH is intercepted. GET and HEAD on it keep falling
 * through to the routing below, so no other method's behaviour changes and no
 * board URL is reserved by this.
 */
async function cspReport(request: Request): Promise<Response> {
  const contentType = (request.headers.get('content-type') ?? '').split(';')[0].trim().toLowerCase();
  if (!CSP_REPORT_CONTENT_TYPES.has(contentType)) {
    return new Response(null, { status: 415, headers: { ...CSP_REPORT_HEADERS } });
  }
  const body = await readBounded(request, CSP_REPORT_MAX_BYTES);
  if (body === null) {
    // Cancelling mid-upload is what makes the cap cheap: nothing above the cap
    // is ever buffered. In `wrangler dev` the aborted upload makes the very next
    // request answer 500 with "Network connection lost" in the proxy log, which
    // is an artifact of the local proxy and not of this code.
    return new Response(null, { status: 413, headers: { ...CSP_REPORT_HEADERS } });
  }
  console.log('csp-report', JSON.stringify(summarizeCspReport(body)));
  // 204 and no body: a report needs a non-error to count as delivered, and a
  // report must never be reflected to whoever sent it. no-store so that no
  // cache can turn a burst of reports into a burst of hits.
  return new Response(null, { status: 204, headers: { ...CSP_REPORT_HEADERS } });
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

  // Before the method gate, which is the whole reason this endpoint exists:
  // the gate below answers 404 to every method that is not GET or HEAD, so a
  // report posted here would be dropped and the browser would keep logging a
  // violation nobody collects.
  if (request.method === 'POST' && url.pathname === CSP_REPORT_PATH) {
    return cspReport(request);
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
