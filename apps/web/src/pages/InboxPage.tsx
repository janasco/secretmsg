import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ViewOnlyNote } from '../components/ViewOnlyBanner';
import { ApiClient, UnauthorizedError, UserProfile, AnonymousMessage, getShareUrl } from '../lib/api';
import { tierMeta, rankTierOf } from '../lib/rank';
import { StoryCardModal } from '../components/StoryCardModal';
import { MessageSquare, Reply, Flag, Copy, Check, Share2, Heart, Smartphone, Clock, Ban } from 'lucide-react';

interface InboxPageProps {
  user: UserProfile | null;
  onOpenDonation: () => void;
  onLogout: () => void;
}

export const InboxPage: React.FC<InboxPageProps> = ({ user, onOpenDonation, onLogout }) => {
  // A browser paired from the app holds a read-only token; every write 403s.
  const isReadOnly = ApiClient.isReadOnly();
  const navigate = useNavigate();
  const [messages, setMessages] = useState<AnonymousMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [replyOpenId, setReplyOpenId] = useState<string | null>(null);
  const [replyText, setReplyText] = useState('');
  const [isReplying, setIsReplying] = useState(false);
  const [copiedLink, setCopiedLink] = useState(false);
  const [isStoryModalOpen, setIsStoryModalOpen] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [toastError, setToastError] = useState(false);
  const [reportId, setReportId] = useState<string | null>(null);
  const [reportReason, setReportReason] = useState('');
  const [reporting, setReporting] = useState(false);
  const [blockId, setBlockId] = useState<string | null>(null);
  const [blocking, setBlocking] = useState(false);

  const showToast = (msg: string, isErr = false) => {
    setToast(msg);
    setToastError(isErr);
    setTimeout(() => setToast(null), 4000);
  };

  useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }

    ApiClient.getInbox()
      .then((msgs) => setMessages(msgs))
      .catch((err) => {
        if (err instanceof UnauthorizedError) {
          onLogout();
          navigate('/login');
          return;
        }
        console.error('Failed to load messages:', err);
      })
      .finally(() => setLoading(false));
  }, [user, navigate, onLogout]);

  if (!user) return null;

  const publicLink = getShareUrl(user.username);

  const handleCopyLink = () => {
    navigator.clipboard.writeText(publicLink);
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2000);
  };

  const handleSendReply = async (messageId: string) => {
    if (!replyText.trim() || isReplying) return;
    setIsReplying(true);
    try {
      await ApiClient.replyMessage(messageId, replyText.trim());
      setMessages((prev) =>
        prev.map((m) =>
          m.id === messageId ? { ...m, reply_content: replyText.trim(), reply_at: new Date().toISOString() } : m
        )
      );
      setReplyOpenId(null);
      setReplyText('');
      showToast('Reply posted anonymously.');
    } catch (err: any) {
      if (err instanceof UnauthorizedError) {
        onLogout();
        navigate('/login');
        return;
      }
      showToast(err.message || 'Failed to submit reply', true);
    } finally {
      setIsReplying(false);
    }
  };

  const submitReport = async () => {
    if (!reportId || !reportReason.trim() || reporting) return;
    setReporting(true);
    try {
      await ApiClient.reportMessage(reportId, reportReason.trim().slice(0, 200));
      showToast('Message reported. It has been quarantined.');
      setMessages((prev) => prev.filter((m) => m.id !== reportId));
      setReportId(null);
      setReportReason('');
    } catch {
      showToast('Failed to submit report', true);
    } finally {
      setReporting(false);
    }
  };

  const submitBlock = async () => {
    if (!blockId || blocking) return;
    setBlocking(true);
    try {
      await ApiClient.blockSender(blockId);
      showToast('Sender blocked and message removed.');
      setMessages((prev) => prev.filter((m) => m.id !== blockId));
      setBlockId(null);
    } catch (err: any) {
      showToast(err.message || 'Failed to block sender', true);
    } finally {
      setBlocking(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto py-8 sm:py-12 px-4 space-y-8">
      {toast && (
        <div className={`p-3 rounded-xl text-xs border ${toastError ? 'bg-rose-500/10 border-rose-500/30 text-rose-300' : 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300'}`}>
          {toast}
        </div>
      )}
      {/* Share Link Banner */}
      <div className="glass-panel p-6 sm:p-8 rounded-2xl space-y-4 border-indigo-500/30">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="space-y-1">
            <h2 className="text-lg sm:text-xl font-bold text-white flex items-center space-x-2">
              <span>Your Secret Link is Ready</span>
              {user.is_premium === 1 && (
                <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                  {user.badge_title || 'Supporter'}
                </span>
              )}
              {(() => {
                const meta = tierMeta(rankTierOf(user));
                return (
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-indigo-500/15 text-indigo-300 border border-indigo-500/30">
                    {meta.emoji} {meta.name}
                  </span>
                );
              })()}
            </h2>
            <p className="text-xs text-slate-400">
              Copy your personal link or generate a social story card to share with friends.
            </p>
          </div>

          <div className="flex items-center space-x-2 w-full sm:w-auto">
            <button
              onClick={() => setIsStoryModalOpen(true)}
              className="flex-1 sm:flex-none py-2.5 px-4 rounded-xl text-xs font-semibold bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 text-white shadow-lg shadow-indigo-500/20 flex items-center justify-center space-x-1.5 transition-all"
            >
              <Share2 className="w-3.5 h-3.5" />
              <span>Create Story Card</span>
            </button>
            <button
              onClick={handleCopyLink}
              className="flex-1 sm:flex-none py-2.5 px-4 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 text-white border border-white/10 flex items-center justify-center space-x-1.5 transition-colors"
            >
              {copiedLink ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-400" />
                  <span>Copied!</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" />
                  <span>Copy Link</span>
                </>
              )}
            </button>
          </div>
        </div>

        <div className="bg-dark-900 px-4 py-2.5 rounded-xl text-xs font-mono text-indigo-300 border border-white/10 flex items-center justify-between overflow-x-auto">
          <span>{publicLink}</span>
        </div>
      </div>

      {/* Messages Header */}
      <div className="flex items-center justify-between border-b border-white/10 pb-4">
        <div className="flex items-center space-x-2">
          <MessageSquare className="w-5 h-5 text-indigo-400" />
          <h3 className="text-lg font-bold text-white">Received Messages ({messages.length})</h3>
        </div>

        {user.is_premium === 0 && (
          <button
            onClick={onOpenDonation}
            className="text-xs text-amber-400 hover:underline flex items-center space-x-1 font-medium"
          >
            <Heart className="w-3.5 h-3.5 fill-amber-400" />
            <span>Support & Unlock Custom Handles</span>
          </button>
        )}
      </div>

      {/* Messages List */}
      {loading ? (
        <div className="flex flex-col items-center justify-center py-16 space-y-3">
          <div className="w-8 h-8 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
          <p className="text-xs text-slate-400">Checking your inbox...</p>
        </div>
      ) : messages.length === 0 ? (
        <div className="glass-panel p-12 rounded-2xl text-center space-y-4">
          <div className="w-12 h-12 bg-dark-900 border border-white/10 rounded-full flex items-center justify-center mx-auto text-slate-500">
            <MessageSquare className="w-6 h-6" />
          </div>
          <h4 className="text-base font-semibold text-white">No messages yet</h4>
          <p className="text-xs text-slate-400 max-w-sm mx-auto">
            Share your link on your Instagram story, bio, or group chat to receive your first secret message!
          </p>
          <button
            onClick={() => setIsStoryModalOpen(true)}
            className="py-2.5 px-5 rounded-xl text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white transition-colors"
          >
            Create Share Card
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          {messages.map((msg) => (
            <div key={msg.id} className="glass-panel p-5 sm:p-6 rounded-2xl space-y-4 glass-card-hover">
              <div className="flex items-start justify-between gap-3">
                <div className="space-y-2 flex-1">
                  <p className="text-sm sm:text-base text-slate-100 whitespace-pre-wrap leading-relaxed">
                    {msg.content}
                  </p>

                  <div className="flex flex-wrap items-center gap-3 text-[11px] text-slate-500 font-mono">
                    <span className="flex items-center space-x-1">
                      <Clock className="w-3 h-3 text-slate-400" />
                      <span>{new Date(msg.created_at).toLocaleDateString()}</span>
                    </span>

                    {msg.device_hint && (
                      <span className="flex items-center space-x-1 text-indigo-400 bg-indigo-500/10 px-2 py-0.5 rounded-full">
                        <Smartphone className="w-3 h-3" />
                        <span>{msg.device_hint}</span>
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex items-center space-x-1 shrink-0">
                  <button
                    onClick={() => { setReportId(msg.id); setReportReason(''); }}
                    title="Report Message"
                    className="p-1.5 text-slate-500 hover:text-rose-400 rounded-lg hover:bg-white/5 transition-colors"
                  >
                    <Flag className="w-3.5 h-3.5" />
                  </button>
                  {!isReadOnly && (
                    <button
                      onClick={() => setBlockId(msg.id)}
                      title="Block sender"
                      className="p-1.5 text-slate-500 hover:text-amber-400 rounded-lg hover:bg-white/5 transition-colors"
                    >
                      <Ban className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>
              </div>

              {/* Reply Section */}
              {msg.reply_content ? (
                <div className="bg-dark-900 border-l-2 border-indigo-500 p-3.5 rounded-r-xl space-y-1 text-xs">
                  <div className="text-indigo-400 font-semibold flex items-center space-x-1">
                    <Reply className="w-3 h-3" />
                    <span>Your Anonymous Reply:</span>
                  </div>
                  <p className="text-slate-300">{msg.reply_content}</p>
                </div>
              ) : (
                <div>
                  {replyOpenId === msg.id ? (
                    <div className="space-y-2.5 pt-2 border-t border-white/5">
                      <textarea
                        value={replyText}
                        onChange={(e) => setReplyText(e.target.value)}
                        placeholder="Write a blind reply (the sender can view this anonymously with their private claim token)..."
                        rows={2}
                        className="w-full bg-dark-900 border border-white/10 rounded-lg p-2.5 text-xs text-white focus:border-indigo-500 outline-none resize-none"
                      />
                      <div className="flex items-center justify-end space-x-2">
                        <button
                          onClick={() => setReplyOpenId(null)}
                          className="px-3 py-1.5 rounded-lg text-xs text-slate-400 hover:text-white"
                        >
                          Cancel
                        </button>
                        <button
                          onClick={() => handleSendReply(msg.id)}
                          disabled={!replyText.trim() || isReplying}
                          className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white disabled:opacity-50"
                        >
                          {isReplying ? 'Sending...' : 'Post Reply'}
                        </button>
                      </div>
                    </div>
                  ) : (
                    isReadOnly ? (
                      <ViewOnlyNote className="mt-1">
                        Replies are sent from the app.
                      </ViewOnlyNote>
                    ) : (
                      <button
                        onClick={() => {
                          setReplyOpenId(msg.id);
                          setReplyText('');
                        }}
                        className="text-xs text-indigo-400 hover:text-indigo-300 flex items-center space-x-1 font-medium pt-1"
                      >
                        <Reply className="w-3.5 h-3.5" />
                        <span>Reply Anonymously</span>
                      </button>
                    )
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Story Card Modal */}
      <StoryCardModal
        user={user}
        isOpen={isStoryModalOpen}
        onClose={() => setIsStoryModalOpen(false)}
      />

      {/* Report modal (replaces prompt()/alert()) */}
      {reportId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60" onClick={() => setReportId(null)}>
          <div className="glass-panel w-full max-w-md p-6 rounded-2xl space-y-4" onClick={(e) => e.stopPropagation()}>
            <h4 className="text-sm font-bold text-white">Report message</h4>
            <p className="text-xs text-slate-400">Harassment, spam, illegal content? Reports are quarantined for moderation.</p>
            <textarea
              value={reportReason}
              onChange={(e) => setReportReason(e.target.value)}
              rows={3}
              maxLength={200}
              placeholder="Reason (1-200 characters)"
              className="w-full bg-dark-900 border border-white/10 rounded-xl p-3 text-xs text-white placeholder-slate-500 outline-none focus:border-rose-500/50 resize-none"
            />
            <div className="flex justify-end gap-2">
              <button onClick={() => setReportId(null)} className="px-3 py-2 rounded-lg text-xs text-slate-400 hover:text-white">Cancel</button>
              <button onClick={submitReport} disabled={!reportReason.trim() || reporting} className="px-4 py-2 rounded-lg text-xs font-semibold bg-rose-600 hover:bg-rose-500 text-white disabled:opacity-50">
                {reporting ? 'Sending…' : 'Submit Report'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Block modal */}
      {blockId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60" onClick={() => setBlockId(null)}>
          <div className="glass-panel w-full max-w-md p-6 rounded-2xl space-y-4" onClick={(e) => e.stopPropagation()}>
            <h4 className="text-sm font-bold text-white">Block this sender?</h4>
            <p className="text-xs text-slate-400">Their anonymous fingerprint is blocked (hash only, they stay anonymous) and this message is deleted. Manage the list in Settings.</p>
            <div className="flex justify-end gap-2">
              <button onClick={() => setBlockId(null)} className="px-3 py-2 rounded-lg text-xs text-slate-400 hover:text-white">Cancel</button>
              <button onClick={submitBlock} disabled={blocking} className="px-4 py-2 rounded-lg text-xs font-semibold bg-amber-500/20 hover:bg-amber-500/30 text-amber-200 border border-amber-500/30 disabled:opacity-50">
                {blocking ? 'Blocking…' : 'Block Sender'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
