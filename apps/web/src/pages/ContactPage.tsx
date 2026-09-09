import React from 'react';
import { Mail, Shield, AlertTriangle, Lock, Scale, Phone, type LucideIcon } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

const contactChannels: {
  title: string;
  description: string;
  email: string;
  icon: LucideIcon;
  accentClass: string;
  borderClass: string;
  buttonClass: string;
}[] = [
  {
    title: 'Trust, Abuse & Harassment',
    description: 'For cyberbullying, harassment, threats, or urgent safety concerns. Monitored with top priority.',
    email: 'abuse@secretmsg.net',
    icon: AlertTriangle,
    accentClass: 'bg-rose-500/10 text-rose-400',
    borderClass: 'border-rose-500/30 bg-rose-950/10',
    buttonClass: 'bg-rose-500 text-white hover:bg-rose-600',
  },
  {
    title: 'Child Protection & Minor Safety',
    description: 'Reports regarding underage users or any child endangerment concern.',
    email: 'safety@secretmsg.net',
    icon: Shield,
    accentClass: 'bg-amber-500/10 text-amber-400',
    borderClass: 'border-white/10',
    buttonClass: 'bg-white/10 text-white hover:bg-white/20',
  },
  {
    title: 'Privacy & GDPR Data Requests',
    description: 'Questions about our zero-log architecture or data verification inquiries.',
    email: 'privacy@secretmsg.net',
    icon: Lock,
    accentClass: 'bg-indigo-500/10 text-indigo-400',
    borderClass: 'border-white/10',
    buttonClass: 'bg-white/10 text-white hover:bg-white/20',
  },
  {
    title: 'Legal, DMCA & Law Enforcement',
    description: 'Official court orders, DMCA copyright takedown notices, or regulatory inquiries.',
    email: 'legal@secretmsg.net',
    icon: Scale,
    accentClass: 'bg-purple-500/10 text-purple-400',
    borderClass: 'border-white/10',
    buttonClass: 'bg-white/10 text-white hover:bg-white/20',
  },
  {
    title: 'General Inquiries & Feedback',
    description: 'Maintained by the SecretMsg Team.',
    email: 'hello@secretmsg.net',
    icon: Mail,
    accentClass: 'bg-sky-500/10 text-sky-400',
    borderClass: 'border-white/10',
    buttonClass: 'bg-white text-dark-900 hover:bg-slate-100',
  },
];

export const ContactPage: React.FC = () => {
  return (
    <PublicPage
      title="Contact Us"
      description="Have questions, feedback, or need urgent trust & safety assistance? Reach out to our dedicated channels below."
    >
      <div className="space-y-4">
        {contactChannels.map((channel) => (
          <div
            key={channel.email}
            className={`glass-panel rounded-2xl p-5 border ${channel.borderClass} flex flex-col sm:flex-row sm:items-center justify-between gap-4`}
          >
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <channel.icon className={`w-4 h-4 ${channel.accentClass}`} />
                <h3 className="font-bold text-white text-base">{channel.title}</h3>
              </div>
              <p className="text-xs text-slate-400">{channel.description}</p>
              <a
                href={`mailto:${channel.email}`}
                className="text-xs font-mono text-indigo-300 hover:text-indigo-200 transition-colors"
              >
                {channel.email}
              </a>
            </div>
            <a
              href={`mailto:${channel.email}`}
              className={`px-4 py-2 rounded-full text-xs font-bold text-center shrink-0 transition-colors ${channel.buttonClass}`}
            >
              Contact
            </a>
          </div>
        ))}
      </div>

      <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-white/10 space-y-4 mt-10 text-sm text-slate-300 leading-relaxed">
        <div className="flex items-center gap-2 mb-2">
          <Phone className="w-5 h-5 text-emerald-400" />
          <h3 className="text-lg font-bold text-white">Response Times</h3>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
          <div className="p-4 rounded-2xl bg-rose-950/20 border border-rose-500/30">
            <strong className="text-rose-300 block font-bold mb-1">Urgent Safety & Abuse</strong>
            <p className="text-slate-400">Monitored around the clock. Most urgent reports receive a response within 24 hours.</p>
          </div>
          <div className="p-4 rounded-2xl bg-white/5 border border-white/10">
            <strong className="text-white block font-bold mb-1">General Inquiries</strong>
            <p className="text-slate-400">We aim to respond to general questions and feedback within 2–3 business days.</p>
          </div>
          <div className="p-4 rounded-2xl bg-white/5 border border-white/10">
            <strong className="text-white block font-bold mb-1">Privacy & Data Requests</strong>
            <p className="text-slate-400">GDPR and data requests are processed within 30 days as required by regulation.</p>
          </div>
          <div className="p-4 rounded-2xl bg-white/5 border border-white/10">
            <strong className="text-white block font-bold mb-1">Legal & DMCA</strong>
            <p className="text-slate-400">Legal inquiries are reviewed promptly and escalated to our compliance team.</p>
          </div>
        </div>
      </div>

      <div className="glass-panel p-6 sm:p-8 rounded-2xl border border-amber-500/20 bg-amber-950/10 space-y-4 mt-6 text-sm text-slate-300 leading-relaxed">
        <div className="flex items-center gap-2 mb-2">
          <AlertTriangle className="w-5 h-5 text-amber-400" />
          <h3 className="text-lg font-bold text-white">Crisis & Escalation</h3>
        </div>
        <p className="text-xs text-slate-400 leading-relaxed">
          If you or someone you know is in immediate danger, please contact your local emergency services (911 in the US) or your country's crisis hotline. For urgent reports of self-harm, violence, or criminal activity, email <a href="mailto:abuse@secretmsg.net" className="text-rose-400 underline">abuse@secretmsg.net</a> immediately.
        </p>
      </div>
    </PublicPage>
  );
};
