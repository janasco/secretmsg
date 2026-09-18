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
    if (!slug || !/^[a-z0-9-]+$/.test(slug)) {
      setMissing(true);
      return;
    }
    fetch(`/posts/${slug}.json`)
      .then((r) => {
        if (!r.ok) throw new Error('missing');
        return r.json();
      })
      .then((d) => setPost(d))
      .catch(() => setMissing(true));
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
      <div className="flex flex-wrap items-center gap-2 mb-6">
        {post.tags.map((t) => (
          <span
            key={t}
            className="px-2.5 py-1 rounded-full text-[11px] font-semibold bg-indigo-500/10 text-indigo-300 border border-indigo-500/20"
          >
            {t}
          </span>
        ))}
        <span className="inline-flex items-center gap-1 text-[11px] text-slate-500 ml-1">
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
            className="w-full rounded-2xl border border-white/10 object-cover max-h-[420px]"
          />
          {post.credit && (
            <figcaption className="mt-2 flex items-center gap-1.5 text-[11px] text-slate-500">
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
