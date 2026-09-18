import { useEffect } from 'react';

export interface SeoTags {
  title: string;
  description: string;
  url: string;
  image?: string;
  publishedTime?: string;
}

function upsertMeta(attr: 'name' | 'property', key: string, content: string): HTMLMetaElement | null {
  let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${key}"]`);
  if (!el) {
    el = document.createElement('meta');
    el.setAttribute(attr, key);
    document.head.appendChild(el);
    el.dataset.seo = 'new';
  } else if (el.dataset.seo !== 'touched' && el.dataset.seo !== 'new') {
    // Snapshot pre-existing (index.html) values so unmount restores them.
    el.dataset.seo = 'touched';
    el.dataset.prev = el.getAttribute('content') ?? '';
  }
  el.setAttribute('content', content);
  return el;
}

function upsertLinkCanonical(href: string): void {
  let el = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
  if (!el) {
    el = document.createElement('link');
    el.setAttribute('rel', 'canonical');
    document.head.appendChild(el);
    el.dataset.seo = 'new';
  } else if (el.dataset.seo !== 'touched' && el.dataset.seo !== 'new') {
    el.dataset.seo = 'touched';
    el.dataset.prev = el.getAttribute('href') ?? '';
  }
  el.setAttribute('href', href);
}

/**
 * Per-page SEO: title, description, canonical, Open Graph + Twitter cards.
 * Restores the previous document head on unmount (route change).
 */
export function useSeo(tags: SeoTags): void {
  useEffect(() => {
    const prevTitle = document.title;
    document.title = tags.title;
    upsertMeta('name', 'description', tags.description);
    upsertMeta('property', 'og:type', tags.publishedTime ? 'article' : 'website');
    upsertMeta('property', 'og:site_name', 'SecretMsg');
    upsertMeta('property', 'og:title', tags.title);
    upsertMeta('property', 'og:description', tags.description);
    upsertMeta('property', 'og:url', tags.url);
    upsertMeta('property', 'og:image', tags.image ?? 'https://secretmsg.net/logo.svg');
    upsertMeta('name', 'twitter:card', 'summary');
    upsertMeta('name', 'twitter:title', tags.title);
    upsertMeta('name', 'twitter:description', tags.description);
    upsertMeta('name', 'twitter:image', tags.image ?? 'https://secretmsg.net/logo.svg');
    if (tags.publishedTime) {
      upsertMeta('property', 'article:published_time', tags.publishedTime);
    }
    upsertLinkCanonical(tags.url);

    return () => {
      document.title = prevTitle;
      document.head.querySelectorAll('[data-seo]').forEach((el) => {
        const prev = (el as HTMLElement).dataset.prev;
        if (el.getAttribute('data-seo') === 'new') {
          el.remove();
        } else if (prev !== undefined) {
          if (el.tagName === 'LINK') el.setAttribute('href', prev);
          else el.setAttribute('content', prev);
          delete (el as HTMLElement).dataset.seo;
          delete (el as HTMLElement).dataset.prev;
        }
      });
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tags.title, tags.description, tags.url]);
}
