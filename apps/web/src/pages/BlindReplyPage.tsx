import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { ApiClient } from '../lib/api';
import { Reply, Sparkles, Clock, AlertCircle, ArrowLeft } from 'lucide-react';

export const BlindReplyPage: React.FC = () => {
  const { token } = useParams<{ token: string }>();
  const [thread, setThread] = useState<{ content: string; reply_content?: string; reply_at?: string; created_at: string } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) return;

    ApiClient.checkReply(token)
      .then((data) => setThread(data))
      .catch((err) => setError(err.message || 'Thread not found'))
      .finally(() => setLoading(false));
  }, [token]);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-3">
        <div className="w-8 h-8 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
        <p className="text-xs text-slate-400">Looking up reply thread...</p>
      </div>
    );
  }

  if (error || !thread) {
    return (
      <div className="max-w-md mx-auto my-16 px-4">
        <div className="glass-panel p-8 rounded-2xl text-center space-y-4">
          <div className="w-12 h-12 bg-rose-500/10 border border-rose-500/20 rounded-full flex items-center justify-center mx-auto text-rose-400">
            <AlertCircle className="w-6 h-6" />
          </div>
          <h2 className="text-xl font-bold text-white">Reply Thread Not Found</h2>
          <p className="text-xs text-slate-400">
            This private reply claim token is invalid or the message may have been deleted.
          </p>
          <div className="pt-2">
            <Link
              to="/"
              className="inline-flex items-center justify-center space-x-2 py-2.5 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back to Home</span>
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-lg mx-auto py-12 px-4 space-y-6">
      <div className="text-center space-y-1">
        <h2 className="text-xl font-bold text-white flex items-center justify-center space-x-2">
          <Sparkles className="w-5 h-5 text-indigo-400" />
          <span>Double-Blind Anonymous Thread</span>
        </h2>
        <p className="text-xs text-slate-400">
          Only you (with this token) and the recipient can see this thread.
        </p>
      </div>

      <div className="glass-panel p-6 rounded-2xl space-y-5">
        {/* Original Message */}
        <div className="space-y-1.5">
          <div className="text-[11px] font-semibold text-slate-400 flex items-center space-x-1 font-mono">
            <Clock className="w-3 h-3 text-slate-500" />
            <span>Sent on {new Date(thread.created_at).toLocaleDateString()}</span>
          </div>
          <div className="p-4 bg-dark-900 rounded-xl border border-white/5 text-sm text-slate-200">
            {thread.content}
          </div>
        </div>

        {/* Reply */}
        {thread.reply_content ? (
          <div className="space-y-1.5 pt-2 border-t border-white/5">
            <div className="text-xs font-semibold text-indigo-400 flex items-center space-x-1.5">
              <Reply className="w-3.5 h-3.5" />
              <span>Recipient's Reply:</span>
            </div>
            <div className="p-4 bg-indigo-950/40 border border-indigo-500/30 rounded-xl text-sm text-indigo-100">
              {thread.reply_content}
            </div>
          </div>
        ) : (
          <div className="p-6 bg-dark-900/50 rounded-xl border border-dashed border-white/10 text-center space-y-1">
            <p className="text-xs text-slate-400">The recipient has not replied to this message yet.</p>
            <p className="text-[11px] text-slate-500">Bookmark this page to check back later.</p>
          </div>
        )}
      </div>
    </div>
  );
};
