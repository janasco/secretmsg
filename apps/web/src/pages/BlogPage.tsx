import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Clock, ArrowRight } from 'lucide-react';
import { PublicPage } from '@/components/PublicPage';
import { useSeo } from '@/lib/seo';

interface BlogIndexEntry {
  slug: string;
  title: string;
  excerpt: string;
  date: string;
  readMinutes: number;
  tags: string[];
  image: string;
  credit: string;
  credit_url: string;
}

export const formatPostDate = (iso: string): string => {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });
};

export const BlogPage: React.FC = () => {
  const [posts, setPosts] = useState<BlogIndexEntry[] | null>(null);
  const [error, setError] = useState(false);
  const [loadKey, setLoadKey] = useState(0);

  useSeo({
    title: 'Blog - SecretMsg',
    description:
      'Essays on privacy, anonymous culture, and getting the most out of your SecretMsg inbox.',
    url: 'https://secretmsg.net/blog',
  });

  useEffect(() => {
    const controller = new AbortController();
    setError(false);
    setPosts(null);

    fetch('/blog-index.json', { signal: controller.signal })
      .then((r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      })
      .then((d: unknown) => {
        if (!Array.isArray(d)) throw new Error('Invalid blog index');
        if (!controller.signal.aborted) setPosts(d);
      })
      .catch((loadError: unknown) => {
        if (loadError instanceof DOMException && loadError.name === 'AbortError') return;
        if (!controller.signal.aborted) setError(true);
      });

    return () => controller.abort();
  }, [loadKey]);

  return (
    <PublicPage
      title="SecretMsg Blog"
      eyebrow="Notes on Honest Messaging"
      description="Essays on privacy, anonymous culture, and getting the most out of your inbox. New posts most weeks."
    >
      {error ? (
        <div className="text-center py-10 space-y-4" role="alert">
          <p className="text-sm text-slate-300">Unable to load blog posts.</p>
          <button
            onClick={() => setLoadKey((key) => key + 1)}
            className="py-2.5 px-5 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
          >
            Try again
          </button>
        </div>
      ) : posts === null ? (
        <div className="flex justify-center py-16">
          <div className="w-8 h-8 rounded-full border-2 border-indigo-500 border-t-transparent animate-spin" />
        </div>
      ) : posts.length === 0 ? (
        <p className="text-sm text-slate-400 text-center py-10">
          No posts yet — check back soon.
        </p>
      ) : (
        <div className="space-y-4">
          {posts.map((post) => (
            <Link
              key={post.slug}
              to={`/post/${post.slug}`}
              className="glass-panel rounded-2xl border-white/5 hover:border-indigo-500/40 transition-all hover:shadow-lg hover:shadow-indigo-500/10 flex flex-col sm:flex-row gap-4 group overflow-hidden"
            >
              {post.image && (
                <div className="sm:w-44 shrink-0 h-32 sm:h-auto overflow-hidden">
                  <img
                    src={post.image}
                    alt=""
                    loading="lazy"
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                </div>
              )}
              <div className="flex-1 space-y-1.5 min-w-0 p-5 sm:pl-1">
                <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-slate-400">
                  <span>{formatPostDate(post.date)}</span>
                  <span className="inline-flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {post.readMinutes} min read
                  </span>
                  {post.tags.map((t) => (
                    <span
                      key={t}
                      className="px-2 py-0.5 rounded-full bg-white/5 border border-white/10 text-slate-400"
                    >
                      {t}
                    </span>
                  ))}
                </div>
                <h2 className="text-base sm:text-lg font-bold text-white group-hover:text-indigo-300 transition-colors flex items-start gap-2">
                  <span className="flex-1">{post.title}</span>
                  <ArrowRight className="w-4 h-4 mt-1 text-slate-600 group-hover:text-indigo-400 group-hover:translate-x-1 transition-all shrink-0" />
                </h2>
                <p className="text-xs sm:text-sm text-slate-400 leading-relaxed line-clamp-2">
                  {post.excerpt}
                </p>
              </div>
            </Link>
          ))}
        </div>
      )}
    </PublicPage>
  );
};
