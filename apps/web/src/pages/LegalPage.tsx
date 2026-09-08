import React from 'react';
import { useParams, Link } from 'react-router-dom';
import { Shield, ArrowLeft } from 'lucide-react';

export const LegalPage: React.FC = () => {
  const { doc } = useParams<{ doc: string }>();

  return (
    <div className="max-w-3xl mx-auto py-12 px-4 space-y-8">
      <Link to="/" className="inline-flex items-center space-x-1.5 text-xs text-slate-400 hover:text-white transition-colors">
        <ArrowLeft className="w-3.5 h-3.5" />
        <span>Back to secretmsg.net</span>
      </Link>

      <div className="glass-panel p-8 sm:p-10 rounded-2xl space-y-6">
        <div className="flex items-center space-x-3 border-b border-white/10 pb-4">
          <Shield className="w-6 h-6 text-indigo-400" />
          <h1 className="text-2xl font-bold text-white capitalize">
            {doc === 'terms' ? 'Terms of Service' : doc === 'privacy' ? 'Privacy Policy' : 'Personal Project Disclaimer'}
          </h1>
        </div>

        <div className="prose prose-invert prose-sm max-w-none text-slate-300 space-y-4 leading-relaxed">
          {doc === 'privacy' ? (
            <>
              <p><strong>Last Updated: September 2026</strong></p>
              <h3 className="text-base font-bold text-white">1. Core Privacy Philosophy</h3>
              <p>SecretMsg (secretmsg.net) collects zero identifying details from message senders. We do not require an account, name, or phone number to send an anonymous message.</p>
              <h3 className="text-base font-bold text-white">2. Right to Erasure (GDPR / CCPA)</h3>
              <p>Account holders can permanently wipe their profile and all received messages from Cloudflare D1 at any time under Settings → Delete Account.</p>
              <h3 className="text-base font-bold text-white">3. Third-Party Infrastructure</h3>
              <p>We use Cloudflare (edge hosting & D1 database), Cloudflare Turnstile (bot protection), and Resend (email OTP delivery). We never sell data to advertisers.</p>
            </>
          ) : doc === 'disclaimer' ? (
            <>
              <h3 className="text-base font-bold text-white">Personal Project & Limitation of Liability</h3>
              <p>SecretMsg is an independent, non-commercial open-source personal project created by janasco. It is provided on an <strong>"AS-IS"</strong> and <strong>"USE AT YOUR OWN RISK"</strong> basis without warranties of any kind.</p>
              <p>The maintainer assumes zero liability for user-generated communications transmitted across the service. To report abuse or request takedowns, email abuse@secretmsg.net.</p>
            </>
          ) : (
            <>
              <p><strong>Last Updated: September 2026</strong></p>
              <h3 className="text-base font-bold text-white">Acceptable Use & Anti-Harassment</h3>
              <p>SecretMsg is built for positive questions, candid constructive feedback, and fun communications. Violent threats, hate speech, bullying, extortion, and malware are strictly prohibited with zero tolerance.</p>
              <p>Accounts and links violating community standards will be immediately removed.</p>
            </>
          )}
        </div>
      </div>
    </div>
  );
};
