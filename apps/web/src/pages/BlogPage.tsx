import React from 'react';
import { Link } from 'react-router-dom';
import { Newspaper, Clock, ArrowRight } from 'lucide-react';
import { PublicPage } from '@/components/PublicPage';
import { BLOG_POSTS, formatPostDate } from '@/lib/blog';

export const BlogPage: React.FC = () => {
  return (
    <PublicPage
      title="SecretMsg Blog"
      eyebrow="Notes on Honest Messaging"
      description="Essays on privacy, anonymous culture, and getting the most out of your inbox. New posts most weeks."
    >
      <div className="space-y-4">
        {BLOG_POSTS.map((post) => (
          <Link
            key={post.slug}
            to={`/post/${post.slug}`}
            className="glass-panel p-6 rounded-2xl border-white/5 hover:border-indigo-500/40 transition-all hover:shadow-lg hover:shadow-indigo-500/10 flex flex-col sm:flex-row sm:items-center gap-4 group"
          >
            <div className="w-12 h-12 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400 shrink-0">
              <Newspaper className="w-5 h-5" />
            </div>
            <div className="flex-1 space-y-1.5 min-w-0">
              <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-slate-500">
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
              <h2 className="text-base sm:text-lg font-bold text-white group-hover:text-indigo-300 transition-colors">
                {post.title}
              </h2>
              <p className="text-xs sm:text-sm text-slate-400 leading-relaxed line-clamp-2">
                {post.excerpt}
              </p>
            </div>
            <ArrowRight className="w-4 h-4 text-slate-600 group-hover:text-indigo-400 group-hover:translate-x-1 transition-all shrink-0 self-center" />
          </Link>
        ))}
      </div>
    </PublicPage>
  );
};
