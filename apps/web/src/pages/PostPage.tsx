import React, { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, Clock, Link2, Check, Camera } from 'lucide-react';
import { PublicPage } from '@/components/PublicPage';
import { formatPostDate } from '@/pages/BlogPage';
import { useSeo } from '@/lib/seo';

interface FullPost {
  slug: string;
  title: string;
  excerpt: string;
  date: string;
  readMinutes: number;
  tags: string[];
  image: string;
  credit: string;
  credit_url: string;
  html: string;
  headings: { id: string; text: string }[];
  related: { slug: string; title: string; image: string }[];
}

export const PostPage: React.FC = () => {
  const { slug } = useParams<{ slug: string }>();
  const [post, setPost] = useState<FullPost | null>(null);
  const [missing, setMissing] = useState(false);
  const [copied, setCopied] = useState(false);

  const ogImage = post?.image
    ? post.image.startsWith('http')
      ? post.image
      : `https://secretmsg.net${post.image}`
    : undefined;

  useSeo({
    title: post ? `${post.title} - SecretMsg Blog` : 'Post - SecretMsg Blog',
    description: post?.excerpt ?? 'Notes on honest messaging, privacy, and anonymous culture.',
    url: `https://secretmsg.net/post/${slug ?? ''}`,
    image: ogImage,
    ...(post ? { publishedTime: `${post.date}T12:00:00Z` } : {}),
  });

  useEffect(() => {
    const controller = new AbortController();
    setPost(null);
    setMissing(false);
    setCopied(false);

    if (!slug || !/^[a-z0-9-]+$/.test(slug)) {
      setMissing(true);
      return () => controller.abort();
    }

    fetch(`/posts/${slug}.json`, { signal: controller.signal })
      .then((r) => {
        if (!r.ok) throw new Error('missing');
        return r.json();
      })
      .then((d) => {
        if (!controller.signal.aborted) setPost(d);
      })
      .catch((error: unknown) => {
        if (error instanceof DOMException && error.name === 'AbortError') return;
        if (!controller.signal.aborted) setMissing(true);
      });

    return () => controller.abort();
  }, [slug]);

  if (missing) {
    return (
      <PublicPage title="Post not found" description="This story doesn't exist (yet).">
        <div className="text-center space-y-4 py-10">
          <p className="text-sm text-slate-400">
            The link may be mistyped — or the post is still being written.
          </p>
          <Link
            to="/blog"
            className="inline-flex items-center gap-2 py-2.5 px-5 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            Back to the blog
          </Link>
        </div>
      </PublicPage>
    );
  }

  if (!post) {
    return (
      <PublicPage title="Loading…" description="">
        <div className="flex justify-center py-16">
          <div className="w-8 h-8 rounded-full border-2 border-indigo-500 border-t-transparent animate-spin" />
        </div>
      </PublicPage>
    );
  }

  const postUrl = `https://secretmsg.net/post/${slug ?? ''}`;
  const shareLinks = post
    ? [
        {
          name: 'X',
          href: `https://twitter.com/intent/tweet?text=${encodeURIComponent(post.title)}&url=${encodeURIComponent(postUrl)}`,
        },
        {
          name: 'Facebook',
          href: `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(postUrl)}`,
        },
        {
          name: 'WhatsApp',
          href: `https://wa.me/?text=${encodeURIComponent(`${post.title} ${postUrl}`)}`,
        },
        {
          name: 'Telegram',
          href: `https://t.me/share/url?url=${encodeURIComponent(postUrl)}&text=${encodeURIComponent(post.title)}`,
        },
      ]
    : [];

  const jsonLd = post
    ? {
        '@context': 'https://schema.org',
        '@type': 'BlogPosting',
        headline: post.title,
        description: post.excerpt,
        image: post.image.startsWith('http') ? [post.image] : [`https://secretmsg.net${post.image}`],
        datePublished: `${post.date}T12:00:00Z`,
        author: { '@type': 'Organization', name: 'SecretMsg', url: 'https://secretmsg.net' },
        publisher: {
          '@type': 'Organization',
          name: 'SecretMsg',
          logo: { '@type': 'ImageObject', url: 'https://secretmsg.net/logo.svg' },
        },
        mainEntityOfPage: { '@type': 'WebPage', '@id': postUrl },
      }
    : null;

  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(`https://secretmsg.net/post/${post.slug}`);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* clipboard unavailable */
    }
  };

  return (
    <PublicPage
      title={post.title}
      eyebrow={`${formatPostDate(post.date)} • ${post.readMinutes} min read`}
      description={post.excerpt}
    >
      {jsonLd && (
        <script type="application/ld+json">{JSON.stringify(jsonLd)}</script>
      )}
      <div className="flex flex-wrap items-center gap-2 mb-6">
        {post.tags.map((t) => (
          <span
            key={t}
            className="px-2.5 py-1 rounded-full text-[11px] font-semibold bg-indigo-500/10 text-indigo-300 border border-indigo-500/20"
          >
            {t}
          </span>
        ))}
        <span className="inline-flex items-center gap-1 text-[11px] text-slate-400 ml-1">
          <Clock className="w-3 h-3" />
          {post.readMinutes} min read
        </span>
        <button
          onClick={copyLink}
          className="ml-auto inline-flex items-center gap-1.5 text-[11px] text-slate-400 hover:text-white transition-colors"
          title="Copy link to this post"
        >
          {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Link2 className="w-3.5 h-3.5" />}
          {copied ? 'Copied' : 'Copy link'}
        </button>
      </div>

      {post.image && (
        <figure className="mb-8">
          <img
            src={post.image}
            alt={post.title}
            decoding="async"
            className="w-full aspect-video rounded-2xl border border-white/10 object-cover max-h-[420px]"
          />
          {post.credit && (
            <figcaption className="mt-2 flex items-center gap-1.5 text-[11px] text-slate-400">
              <Camera className="w-3 h-3 shrink-0" />
              {post.credit_url ? (
                <>
                  <a href={post.credit_url} target="_blank" rel="noopener noreferrer" className="hover:text-slate-300 underline underline-offset-2">
                    {post.credit}
                  </a>
                  <span>· via Pixabay</span>
                </>
              ) : (
                <span>{post.credit}</span>
              )}
            </figcaption>
          )}
        </figure>
      )}

      <article className="blog-body" dangerouslySetInnerHTML={{ __html: post.html }} />

      {post.headings.length > 0 && (
        <nav className="mt-8 glass-panel p-5 rounded-2xl border-white/5">
          <h2 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">
            On this page
          </h2>
          <ul className="space-y-1.5">
            {post.headings.map((h) => (
              <li key={h.id}>
                <a href={`#${h.id}`} className="text-xs text-slate-400 hover:text-indigo-300 transition-colors">
                  {h.text}
                </a>
              </li>
            ))}
          </ul>
        </nav>
      )}

      <div className="mt-8 flex flex-wrap items-center gap-2">
        <span className="text-xs text-slate-400 mr-1">Share this post:</span>
        {shareLinks.map((s) => (
          <a
            key={s.name}
            href={s.href}
            target="_blank"
            rel="noopener noreferrer"
            className="px-3 py-1.5 rounded-lg text-[11px] font-semibold bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10 transition-colors"
          >
            {s.name}
          </a>
        ))}
      </div>

      {post.related.length > 0 && (
        <div className="mt-10">
          <h2 className="text-base font-bold text-white mb-4">Keep reading</h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            {post.related.map((r) => (
              <Link
                key={r.slug}
                to={`/post/${r.slug}`}
                className="glass-panel rounded-xl border-white/5 hover:border-indigo-500/40 transition-all overflow-hidden group"
              >
                {r.image && (
                  <div className="h-24 overflow-hidden">
                    <img
                      src={r.image}
                      alt=""
                      loading="lazy"
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                  </div>
                )}
                <p className="p-3 text-xs font-semibold text-slate-200 group-hover:text-indigo-300 transition-colors line-clamp-2">
                  {r.title}
                </p>
              </Link>
            ))}
          </div>
        </div>
      )}

      <div className="mt-12 glass-panel p-6 rounded-2xl border-indigo-500/20 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
          <h3 className="text-sm font-bold text-white">Want messages like these?</h3>
          <p className="text-xs text-slate-400 mt-0.5">Get your free secret link in under a minute.</p>
        </div>
        <Link
          to="/login"
          className="py-2.5 px-5 rounded-xl text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white transition-colors shrink-0"
        >
          Get Your Free Link
        </Link>
      </div>

      <div className="mt-8">
        <Link
          to="/blog"
          className="inline-flex items-center gap-2 text-xs text-slate-400 hover:text-white transition-colors"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          All posts
        </Link>
      </div>
    </PublicPage>
  );
};
