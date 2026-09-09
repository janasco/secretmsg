import React, { useState } from 'react';
import { ChevronDown, ChevronRight, MessageSquare, Info, Globe, Share2, Cookie, ShieldCheck } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

const faqItems: { question: string; answer: string }[] = [
  {
    question: 'What is a Secret Msg?',
    answer: 'A secret msg is a unique URL tied to your profile on secretmsg.net. Share it with anyone — they can open it and send you an anonymous message without logging in or creating an account. All messages are delivered privately to your board and only you can read them.',
  },
  {
    question: 'Is Secret Msg really anonymous?',
    answer: 'Yes, completely. Secret Msg does not collect or store any identifying information about message senders — no IP address, no device fingerprint, no login data. Your anonymous messages are truly private and untraceable.',
  },
  {
    question: 'How do I log in to my Secret Msg board?',
    answer: 'Go to secretmsg.net/login, enter your board\'s unique link (or slug) and the password you set when you created it. You will be redirected to your profile where you can view settings and manage your board.',
  },
  {
    question: 'How do I change my Secret Msg password?',
    answer: 'Log in to your account and go to your Profile page. Scroll to the Change Password section, enter your new password (minimum 6 characters), and click Change Password. Your new password takes effect immediately.',
  },
  {
    question: 'How do I delete my Secret Msg account?',
    answer: 'Log in and open your Profile page. Scroll to the Delete Account section at the bottom and click Delete My Account. This will permanently remove your board, all received anonymous messages, and your account data. This action cannot be undone.',
  },
  {
    question: 'How do I send an anonymous message to someone?',
    answer: 'Open the secret message link shared by your friend, type your message in the text box, and tap Send. No account, no sign-up, and no personal information is required. Your identity is never revealed to the link owner.',
  },
  {
    question: 'Why is my Secret Msg link not working?',
    answer: 'The most common cause is cookies being disabled. Open Chrome, go to Settings → Site settings → Cookies, and make sure they are turned on. Then reload your secret message link and try again.',
  },
  {
    question: 'Can I use Secret Msg on Instagram?',
    answer: 'Yes! Add your anonymous message link to your Instagram bio or story sticker. Followers can tap the link and send you anonymous messages instantly — no app download needed.',
  },
  {
    question: 'Why should I use Secret Msg?',
    answer: 'Secret Msg is 100% free, takes under a minute to set up, and requires no sign-up for senders. You get a full profile to manage your board — change your name, update your password, view your link, and delete your account any time.',
  },
  {
    question: 'Is Secret Msg safe to use?',
    answer: 'Yes. You are always in full control — delete individual messages from your board, change your password, or permanently delete your entire account from your Profile page at any time. We continuously improve safety features to keep SecretMessage secure for everyone.',
  },
  {
    question: 'What should I do if someone sends abusive anonymous messages?',
    answer: 'Delete the abusive messages directly from your board. If the problem persists, go to your Profile page and use Delete Account to permanently remove your board. Because the service is fully anonymous, individual senders cannot be traced. For serious threats, please contact your local authorities.',
  },
];

const howToCreate = [
  { step: '1', title: 'Open secretmsg.net', desc: 'Open secretmsg.net in your browser (Chrome recommended on all devices).' },
  { step: '2', title: 'Enter your display name', desc: 'Enter your display name so friends and followers know whose link it is.' },
  { step: '3', title: 'Set a password', desc: 'Set a secure password — you will use this to log in and access your private board from any device at any time.' },
  { step: '4', title: 'Generate Your Link', desc: 'Click "Create Your Anonymous Message Link" — your unique secret message URL is generated instantly.' },
  { step: '5', title: 'Share Your Link Everywhere', desc: 'Share your link on Instagram Stories, WhatsApp Status, Facebook, X (Twitter), or anywhere you like. Once your link is live, people can send you anonymous messages at any time. Only you can see them on your private message board!' },
];

const howToSend = [
  { step: '1', title: 'Open Link', desc: 'Open the secret message link shared by your friend on Instagram, WhatsApp, or Twitter.' },
  { step: '2', title: 'Type Message', desc: 'Type your message in the text box (up to 80 words / 300 characters). You can insert emojis or choose vibes.' },
  { step: '3', title: 'Tap Send', desc: 'Tap Send — your message is delivered instantly and your identity is never revealed.' },
];

const creativeWays = [
  { emoji: '📸', title: 'Instagram Stories', desc: 'Add your secret message link to your story sticker and let followers send you anonymous questions, hot takes, or compliments.' },
  { emoji: '💬', title: 'WhatsApp Status', desc: 'Share your anonymous message link on your WhatsApp status and discover what your contacts really think about you.' },
  { emoji: '🎉', title: 'Event Feedback', desc: 'Collect honest, unfiltered feedback after meetups, community workshops, podcast episodes, or team hackathons.' },
  { emoji: '🎓', title: 'Classroom Q&A', desc: 'Teachers, professors, and study leaders can let students ask candid questions without fear of peer social pressure.' },
  { emoji: '🌱', title: 'Self-Improvement & Candid Honest TBHs', desc: 'Ask your personal and professional network for candid constructive opinions. Anonymity strips away social friction and encourages truthful, empowering answers.' },
];

const troubleshooting = [
  { icon: Cookie, color: 'text-amber-400', title: '1. Enable cookies', desc: 'In Chrome go to Settings → Site settings → Cookies and set to Allow. Essential cookies are required to authenticate your board and verify bot prevention.' },
  { icon: Globe, color: 'text-sky-400', title: '2. Use Chrome', desc: 'We recommend Chrome on Android and iPhone for the best compatibility and smoothest local message storage.' },
  { icon: ShieldCheck, color: 'text-emerald-400', title: '3. Clear your cache', desc: 'A stale browser cache can sometimes break the page. Clear your browser cache and reload the link.' },
  { icon: Share2, color: 'text-purple-400', title: '4. Check the URL', desc: 'Copy the exact link from your secret message board rather than typing it manually.' },
];

const FaqItem: React.FC<{
  question: string;
  answer: string;
  isOpen: boolean;
  onToggle: () => void;
}> = ({ question, answer, isOpen, onToggle }) => (
  <div className={`glass-panel rounded-2xl border transition-colors ${isOpen ? 'border-indigo-500/30' : 'border-white/10'}`}>
    <button
      onClick={onToggle}
      className="w-full py-3.5 px-4 rounded-xl bg-dark-900/60 border border-white/10 text-left text-sm font-semibold text-white hover:border-indigo-500/40 transition-colors flex items-center justify-between gap-3"
    >
      <span>{question}</span>
      {isOpen ? (
        <ChevronDown className="w-4 h-4 text-slate-400 shrink-0" />
      ) : (
        <ChevronRight className="w-4 h-4 text-slate-400 shrink-0" />
      )}
    </button>
    {isOpen && (
      <div className="px-4 pb-4 pt-1 text-xs text-slate-300 leading-relaxed border-t border-white/10">
        {answer}
      </div>
    )}
  </div>
);

export const FaqPage: React.FC = () => {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const toggleFaq = (index: number): void => {
    setOpenIndex(prev => (prev === index ? null : index));
  };

  return (
    <PublicPage
      title="Frequently Asked Questions"
      description="Everything you need to know about creating your link, sending anonymous messages, managing your board, troubleshooting URLs, and our zero-knowledge privacy guarantee."
    >
      <div className="glass-panel rounded-2xl p-6 sm:p-8 border border-white/10 space-y-6 mb-10">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 flex items-center justify-center font-bold text-sm">
            1
          </div>
          <div>
            <h2 className="text-xl sm:text-2xl font-bold text-white tracking-tight">
              How to Create Your Anonymous Message Link
            </h2>
            <p className="text-xs text-slate-400">Getting started takes less than a minute:</p>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
          {howToCreate.map((item) => (
            <div
              key={item.step}
              className={`rounded-2xl p-4 border space-y-2 ${
                item.step === '5'
                  ? 'sm:col-span-2 bg-gradient-to-r from-indigo-500/10 via-purple-500/10 to-transparent border-indigo-500/20'
                  : 'bg-white/5 border-white/10'
              }`}
            >
              <div className={`flex items-center gap-2 font-bold ${item.step === '5' ? 'text-indigo-300' : 'text-white'}`}>
                <span className={`w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-mono ${item.step === '5' ? 'bg-indigo-500/20 text-indigo-300' : 'bg-white/10'}`}>
                  {item.step}
                </span>
                {item.title}
              </div>
              <p className="text-slate-400 leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>
      </div>

      <div className="glass-panel rounded-2xl p-6 sm:p-8 border border-white/10 space-y-6 mb-10">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center font-bold text-sm">
            2
          </div>
          <div>
            <h2 className="text-xl sm:text-2xl font-bold text-white tracking-tight">
              How to Send an Anonymous Message
            </h2>
            <p className="text-xs text-slate-400">Sending an anonymous message is even easier than creating one:</p>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          {howToSend.map((item) => (
            <div key={item.step} className="bg-white/5 rounded-2xl p-4 border border-white/10 space-y-2">
              <div className="text-emerald-400 font-bold">
                Step {item.step}: {item.title}
              </div>
              <p className="text-slate-400 leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>

        <div className="p-3 bg-emerald-950/30 border border-emerald-500/30 rounded-2xl text-xs text-emerald-300 flex items-center gap-2">
          <ShieldCheck className="w-5 h-5 shrink-0" />
          <span><strong>No sign-up, no login, no account required.</strong> Just open, type, and send your anonymous message.</span>
        </div>
      </div>

      <div className="space-y-4 mb-10">
        <h2 className="text-xl sm:text-2xl font-bold text-white tracking-tight">
          Creative Ways to Use Anonymous Messages
        </h2>
        <p className="text-xs text-slate-400">Here are popular ways people use SecretMsg every day:</p>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 text-xs">
          {creativeWays.map((item) => (
            <div
              key={item.title}
              className={`glass-panel p-5 rounded-2xl border border-white/10 space-y-2 hover:border-indigo-500/40 transition-colors ${
                item.title.includes('Self-Improvement') ? 'sm:col-span-2 md:col-span-2' : ''
              }`}
            >
              <div className="text-2xl">{item.emoji}</div>
              <div className="font-bold text-sm text-white">{item.title}</div>
              <p className="text-slate-400 leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>
      </div>

      <div className="glass-panel rounded-2xl p-6 sm:p-8 border border-white/10 space-y-4 mb-10 text-sm text-slate-300 leading-relaxed">
        <h2 className="text-xl sm:text-2xl font-bold text-white tracking-tight">
          Manage Your Secret Msg Board
        </h2>
        <p className="text-xs text-slate-400">
          Once your board is created, you have full control through your Profile page. Here is what you can do:
        </p>
        <div className="space-y-3 text-xs">
          <div className="p-4 rounded-2xl bg-white/5 border border-white/10">
            <strong className="text-white block font-bold mb-1">Login:</strong>
            Visit secretmsg.net/login, enter your board link (slug) and password to access your account from any device at any time.
          </div>
          <div className="p-4 rounded-2xl bg-white/5 border border-white/10">
            <strong className="text-white block font-bold mb-1">View your board link:</strong>
            Your profile shows your unique anonymous message link so you can copy and share it anytime with 1 tap.
          </div>
          <div className="p-4 rounded-2xl bg-white/5 border border-white/10">
            <strong className="text-white block font-bold mb-1">Change your display name:</strong>
            Update the name shown on your public message board directly from your profile settings whenever you like.
          </div>
          <div className="p-4 rounded-2xl bg-white/5 border border-white/10">
            <strong className="text-white block font-bold mb-1">Change your password:</strong>
            Set a new password from the Profile page under the Change Password section (minimum 6 characters). Your new password takes effect immediately.
          </div>
          <div className="p-4 rounded-2xl bg-rose-950/20 border border-rose-500/30">
            <strong className="text-rose-300 block font-bold mb-1">Delete your account (Danger Zone):</strong>
            <span className="text-slate-300">Permanently delete your board and all received messages from the Danger Zone in your profile. This action cannot be undone.</span>
          </div>
        </div>
      </div>

      <div className="glass-panel rounded-2xl p-6 sm:p-8 border border-white/10 space-y-6 mb-10">
        <div>
          <div className="inline-flex items-center gap-1.5 text-xs font-bold text-amber-400 uppercase tracking-wider mb-2">
            <Info className="w-4 h-4" />
            Fix Common Issues
          </div>
          <h2 className="text-xl sm:text-2xl font-bold text-white tracking-tight">
            Troubleshooting: Why Your Secret Msg URL Might Not Work
          </h2>
          <p className="text-xs text-slate-400 mt-1">If your anonymous message link won't open or looks broken, try these simple fixes:</p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
          {troubleshooting.map((item) => (
            <div key={item.title} className="p-4 rounded-2xl bg-white/5 border border-white/10 space-y-2">
              <div className="font-bold text-white flex items-center gap-2">
                <item.icon className={`w-4 h-4 ${item.color}`} />
                {item.title}
              </div>
              <p className="text-slate-300 leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>
      </div>

      <div className="space-y-4">
        <div>
          <div className="inline-flex items-center gap-1.5 text-xs font-bold text-indigo-400 uppercase tracking-wider mb-2">
            <MessageSquare className="w-4 h-4" />
            Knowledge Base
          </div>
          <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
            Frequently Asked Questions
          </h2>
        </div>

        <div className="space-y-3">
          {faqItems.map((item, index) => (
            <FaqItem
              key={index}
              question={item.question}
              answer={item.answer}
              isOpen={openIndex === index}
              onToggle={() => toggleFaq(index)}
            />
          ))}
        </div>
      </div>
    </PublicPage>
  );
};
