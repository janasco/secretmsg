import React, { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, Clock, Link2, Check } from 'lucide-react';
import { PublicPage } from '@/components/PublicPage';
import { getPost, formatPostDate } from '@/lib/blog';
import { useSeo } from '@/lib/seo';

export const PostPage: React.FC = () => {
  const { slug } = useParams<{ slug: string }>();
  const [copied, setCopied] = useState(false);
  const post = slug ? getPost(slug) : undefined;

  useSeo({
    title: post ? `${post.title} - SecretMsg Blog` : 'Post not found - SecretMsg',
    description: post?.excerpt ?? 'This story does not exist (yet).',
    url: `https://secretmsg.net/post/${post?.slug ?? slug ?? ''}`,
    ...(post ? { publishedTime: `${post.date}T12:00:00Z` } : {}),
  });

  if (!post) {
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
      <div className="flex flex-wrap items-center gap-2 mb-8">
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

      <article className="space-y-8">
        {post.sections.map((section, i) => (
          <section key={i} className="space-y-3">
            {section.heading && (
              <h2 className="text-xl font-bold text-white tracking-tight">{section.heading}</h2>
            )}
            {section.body.map((para, j) => (
              <p key={j} className="text-sm sm:text-[15px] text-slate-300 leading-relaxed">
                {para}
              </p>
            ))}
            {section.quote && (
              <blockquote className="border-l-2 border-amber-400/60 pl-4 py-1 text-base sm:text-lg font-medium italic text-white/90">
                “{section.quote}”
              </blockquote>
            )}
          </section>
        ))}
      </article>

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
