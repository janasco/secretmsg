import React, { useState, useEffect } from 'react';
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
          <Route path="/inbox" element={<InboxPage user={user} onOpenDonation={() => setIsDonationOpen(true)} />} />
          <Route path="/settings" element={<SettingsPage user={user} onLogout={handleLogout} onOpenDonation={() => setIsDonationOpen(true)} />} />
          <Route path="/supporters" element={<SupportersPage onOpenDonation={() => setIsDonationOpen(true)} />} />
          <Route path="/donors" element={<SupportersPage onOpenDonation={() => setIsDonationOpen(true)} />} />
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
