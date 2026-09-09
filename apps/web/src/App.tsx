import React, { useState, Suspense, lazy } from 'react';
import { Routes, Route, useNavigate } from 'react-router-dom';
import { ApiClient, UserProfile } from './lib/api';
import { Navbar } from './components/Navbar';
import { DonationModal } from './components/DonationModal';
import { LandingPage } from './pages/LandingPage';
import { SendMessagePage } from './pages/SendMessagePage';
import { InboxPage } from './pages/InboxPage';
import { SettingsPage } from './pages/SettingsPage';
import { LoginPage } from './pages/LoginPage';
import { BlindReplyPage } from './pages/BlindReplyPage';
import { LegalPage } from './pages/LegalPage';
import { SupportersPage } from './pages/SupportersPage';

const AboutPage = lazy(() => import('./pages/AboutPage').then(m => ({ default: m.AboutPage })));
const DicePage = lazy(() => import('./pages/DicePage').then(m => ({ default: m.DicePage })));
const StickerStudioPage = lazy(() => import('./pages/StickerStudioPage').then(m => ({ default: m.StickerStudioPage })));
const DemoPage = lazy(() => import('./pages/DemoPage').then(m => ({ default: m.DemoPage })));
const FaqPage = lazy(() => import('./pages/FaqPage').then(m => ({ default: m.FaqPage })));
const ContactPage = lazy(() => import('./pages/ContactPage').then(m => ({ default: m.ContactPage })));
const SafetyPage = lazy(() => import('./pages/SafetyPage').then(m => ({ default: m.SafetyPage })));
const ChildSafetyPage = lazy(() => import('./pages/ChildSafetyPage').then(m => ({ default: m.ChildSafetyPage })));
const ApproachToSafetyPage = lazy(() => import('./pages/ApproachToSafetyPage').then(m => ({ default: m.ApproachToSafetyPage })));
const OnlineSafetyGuidePage = lazy(() => import('./pages/OnlineSafetyGuidePage').then(m => ({ default: m.OnlineSafetyGuidePage })));
const CommunityGuidelinesPage = lazy(() => import('./pages/CommunityGuidelinesPage').then(m => ({ default: m.CommunityGuidelinesPage })));
const SafetyToolsPage = lazy(() => import('./pages/SafetyToolsPage').then(m => ({ default: m.SafetyToolsPage })));
const SafetyResourcesPage = lazy(() => import('./pages/SafetyResourcesPage').then(m => ({ default: m.SafetyResourcesPage })));
const PrivacyPage = lazy(() => import('./pages/PrivacyPage').then(m => ({ default: m.PrivacyPage })));
const TermsPage = lazy(() => import('./pages/TermsPage').then(m => ({ default: m.TermsPage })));
const CookiesPage = lazy(() => import('./pages/CookiesPage').then(m => ({ default: m.CookiesPage })));
const DisclaimerPage = lazy(() => import('./pages/DisclaimerPage').then(m => ({ default: m.DisclaimerPage })));

const PublicSuspense: React.FC = () => (
  <div className="min-h-[40vh] flex items-center justify-center">
    <div className="w-8 h-8 rounded-full border-2 border-indigo-500 border-t-transparent animate-spin" />
  </div>
);

export const App: React.FC = () => {
  const [user, setUser] = useState<UserProfile | null>(() => ApiClient.getSavedUser());
  const [isDonationOpen, setIsDonationOpen] = useState(false);
  const navigate = useNavigate();

  const handleLogout = () => {
    ApiClient.removeToken();
    setUser(null);
    navigate('/');
  };

  return (
    <div className="min-h-screen flex flex-col bg-dark-950 text-slate-100 selection:bg-indigo-500 selection:text-white">
      <Navbar
        user={user}
        onOpenDonation={() => setIsDonationOpen(true)}
        onLogout={handleLogout}
      />

      <main className="flex-1">
        <Routes>
          <Route path="/" element={<LandingPage onOpenDonation={() => setIsDonationOpen(true)} />} />
          <Route path="/login" element={<LoginPage onLoginSuccess={(u) => setUser(u)} />} />
          <Route path="/inbox" element={<InboxPage user={user} onOpenDonation={() => setIsDonationOpen(true)} onLogout={handleLogout} />} />
          <Route path="/settings" element={<SettingsPage user={user} onLogout={handleLogout} onOpenDonation={() => setIsDonationOpen(true)} />} />
          <Route path="/supporters" element={<SupportersPage onOpenDonation={() => setIsDonationOpen(true)} />} />
          <Route path="/donors" element={<SupportersPage onOpenDonation={() => setIsDonationOpen(true)} />} />
          <Route path="/about" element={<Suspense fallback={<PublicSuspense />}><AboutPage /></Suspense>} />
          <Route path="/dice" element={<Suspense fallback={<PublicSuspense />}><DicePage /></Suspense>} />
          <Route path="/sticker-studio" element={<Suspense fallback={<PublicSuspense />}><StickerStudioPage /></Suspense>} />
          <Route path="/demo" element={<Suspense fallback={<PublicSuspense />}><DemoPage /></Suspense>} />
          <Route path="/faq" element={<Suspense fallback={<PublicSuspense />}><FaqPage /></Suspense>} />
          <Route path="/contact" element={<Suspense fallback={<PublicSuspense />}><ContactPage /></Suspense>} />
          <Route path="/p/safety" element={<Suspense fallback={<PublicSuspense />}><SafetyPage /></Suspense>} />
          <Route path="/p/child-safety-policy" element={<Suspense fallback={<PublicSuspense />}><ChildSafetyPage /></Suspense>} />
          <Route path="/p/approach-to-safety" element={<Suspense fallback={<PublicSuspense />}><ApproachToSafetyPage /></Suspense>} />
          <Route path="/p/guide-to-online-safety" element={<Suspense fallback={<PublicSuspense />}><OnlineSafetyGuidePage /></Suspense>} />
          <Route path="/p/community-guidelines" element={<Suspense fallback={<PublicSuspense />}><CommunityGuidelinesPage /></Suspense>} />
          <Route path="/p/safety-tools" element={<Suspense fallback={<PublicSuspense />}><SafetyToolsPage /></Suspense>} />
          <Route path="/p/resources" element={<Suspense fallback={<PublicSuspense />}><SafetyResourcesPage /></Suspense>} />
          <Route path="/p/contact-us" element={<Suspense fallback={<PublicSuspense />}><ContactPage /></Suspense>} />
          <Route path="/p/legal/terms" element={<Suspense fallback={<PublicSuspense />}><TermsPage /></Suspense>} />
          <Route path="/p/legal/privacy" element={<Suspense fallback={<PublicSuspense />}><PrivacyPage /></Suspense>} />
          <Route path="/p/legal/cookies" element={<Suspense fallback={<PublicSuspense />}><CookiesPage /></Suspense>} />
          <Route path="/p/legal/disclaimer" element={<Suspense fallback={<PublicSuspense />}><DisclaimerPage /></Suspense>} />
          <Route path="/p/privacy" element={<Suspense fallback={<PublicSuspense />}><PrivacyPage /></Suspense>} />
          <Route path="/p/terms" element={<Suspense fallback={<PublicSuspense />}><TermsPage /></Suspense>} />
          <Route path="/p/cookies" element={<Suspense fallback={<PublicSuspense />}><CookiesPage /></Suspense>} />
          <Route path="/p/disclaimer" element={<Suspense fallback={<PublicSuspense />}><DisclaimerPage /></Suspense>} />
          <Route path="/reply/:token" element={<BlindReplyPage />} />
          <Route path="/legal/:doc" element={<LegalPage />} />
          <Route path="/:username" element={<SendMessagePage />} />
        </Routes>
      </main>

      <DonationModal
        isOpen={isDonationOpen}
        onClose={() => setIsDonationOpen(false)}
      />
    </div>
  );
};
