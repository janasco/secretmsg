import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { ApiClient, UserProfile } from '../lib/api';
import { ComposeModal } from '../components/ComposeModal';
import { AlertCircle, ArrowLeft } from 'lucide-react';

export const SendMessagePage: React.FC = () => {
  const { username } = useParams<{ username: string }>();
  const [recipient, setRecipient] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!username) return;

    let isMounted = true;
    setLoading(true);
    setError(null);

    ApiClient.getRecipientProfile(username)
      .then((user) => {
        if (isMounted) setRecipient(user);
      })
      .catch((err) => {
        if (isMounted) setError(err.message || 'User does not exist');
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [username]);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-4">
        <div className="w-10 h-10 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
        <p className="text-xs text-slate-400">Loading recipient profile...</p>
      </div>
    );
  }

  if (error || !recipient) {
    return (
      <div className="max-w-md mx-auto my-16 px-4">
        <div className="glass-panel p-8 rounded-2xl text-center space-y-4">
          <div className="w-12 h-12 bg-rose-500/10 border border-rose-500/20 rounded-full flex items-center justify-center mx-auto text-rose-400">
            <AlertCircle className="w-6 h-6" />
          </div>
          <h2 className="text-xl font-bold text-white">Link Not Found</h2>
          <p className="text-xs text-slate-400">
            No active SecretMsg user was found with the handle <span className="text-slate-200 font-mono">@{username}</span>.
          </p>
          <div className="pt-2">
            <Link
              to="/"
              className="inline-flex items-center justify-center space-x-2 py-2.5 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back to SecretMsg.net</span>
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-lg mx-auto py-8 sm:py-16 px-4">
      <ComposeModal recipient={recipient} />
    </div>
  );
};
