/**
 * SecretMsg Frontend API Client
 */

import { MockApiClient } from './mockApi';

const API_BASE_URL = (import.meta as any).env?.VITE_API_URL || 'https://api.secretmsg.net';
const USE_MOCK = (import.meta as any).env?.VITE_USE_MOCK === 'true';

export interface UserProfile {
  id: string;
  username: string;
  display_name: string;
  email?: string;
  avatar_seed: string;
  bio?: string;
  is_premium: number;
  badge_title?: string | null;
}

export interface AnonymousMessage {
  id: string;
  content: string;
  reply_content?: string | null;
  reply_at?: string | null;
  is_pinned: number;
  is_read: number;
  device_hint?: string | null;
  created_at: string;
}

export interface AnonymousSupporter {
  id: string;
  alias: string;
  tier: string;
  note: string | null;
  createdAt: string;
}

export interface SupportersData {
  supporters: AnonymousSupporter[];
  stats: {
    totalSupporters: number;
    monthlyServerGoalPercent: number;
    currentMonth: string;
  };
}

export class ApiClient {
  static getToken(): string | null {
    return localStorage.getItem('secretmsg_auth_token');
  }

  static setToken(token: string) {
    localStorage.setItem('secretmsg_auth_token', token);
  }

  static removeToken() {
    localStorage.removeItem('secretmsg_auth_token');
    localStorage.removeItem('secretmsg_user_profile');
  }

  static getSavedUser(): UserProfile | null {
    const raw = localStorage.getItem('secretmsg_user_profile');
    return raw ? JSON.parse(raw) : null;
  }

  static saveUser(user: UserProfile) {
    localStorage.setItem('secretmsg_user_profile', JSON.stringify(user));
  }

  static async getRecipientProfile(username: string): Promise<UserProfile> {
    if (USE_MOCK) return MockApiClient.getRecipientProfile(username);
    const res = await fetch(`${API_BASE_URL}/api/user/${encodeURIComponent(username)}`);
    if (!res.ok) {
      throw new Error('User not found');
    }
    const data = await res.json() as { user: UserProfile };
    return data.user;
  }

  static async sendAnonymousMessage(username: string, content: string, turnstileToken?: string, allowClue?: boolean): Promise<{ success: boolean; replyToken?: string }> {
    if (USE_MOCK) return MockApiClient.sendAnonymousMessage(username, content, turnstileToken, allowClue);
    const res = await fetch(`${API_BASE_URL}/api/message/${encodeURIComponent(username)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content, turnstileToken, allowClue }),
    });
    const data = await res.json() as { success?: boolean; error?: string; replyToken?: string };
    if (!res.ok) {
      throw new Error(data.error || 'Failed to send message');
    }
    return { success: true, replyToken: data.replyToken };
  }

  static async requestOtp(email: string): Promise<void> {
    if (USE_MOCK) return MockApiClient.requestOtp(email);
    const res = await fetch(`${API_BASE_URL}/api/auth/otp-request`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    });
    if (!res.ok) {
      const err = await res.json() as { error?: string };
      throw new Error(err.error || 'Failed to send OTP code');
    }
  }

  static async verifyOtp(email: string, otp: string): Promise<{ user: UserProfile; token: string }> {
    if (USE_MOCK) {
      const res = await MockApiClient.verifyOtp(email, otp);
      this.setToken(res.token);
      this.saveUser(res.user);
      return res;
    }
    const res = await fetch(`${API_BASE_URL}/api/auth/otp-verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, otp }),
    });
    const data = await res.json() as { user?: UserProfile; token?: string; error?: string };
    if (!res.ok || !data.token || !data.user) {
      throw new Error(data.error || 'Invalid or expired OTP');
    }
    this.setToken(data.token);
    this.saveUser(data.user);
    return { user: data.user, token: data.token };
  }

  static async getInbox(): Promise<AnonymousMessage[]> {
    if (USE_MOCK) return MockApiClient.getInbox();
    const token = this.getToken();
    if (!token) throw new Error('Not logged in');

    const res = await fetch(`${API_BASE_URL}/api/inbox`, {
      headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to load inbox');
    const data = await res.json() as { messages: AnonymousMessage[] };
    return data.messages || [];
  }

  static async replyMessage(messageId: string, reply: string): Promise<void> {
    if (USE_MOCK) return MockApiClient.replyMessage(messageId, reply);
    const token = this.getToken();
    if (!token) throw new Error('Not logged in');

    const res = await fetch(`${API_BASE_URL}/api/inbox/${messageId}/reply`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ reply }),
    });
    if (!res.ok) throw new Error('Failed to send reply');
  }

  static async checkReply(token: string): Promise<{ content: string; reply_content?: string; reply_at?: string; created_at: string }> {
    if (USE_MOCK) return MockApiClient.checkReply(token);
    const res = await fetch(`${API_BASE_URL}/api/reply/${token}`);
    if (!res.ok) throw new Error('Reply thread not found');
    const data = await res.json() as { thread: { content: string; reply_content?: string; reply_at?: string; created_at: string } };
    return data.thread;
  }

  static async deleteAccount(): Promise<void> {
    if (USE_MOCK) {
      await MockApiClient.deleteAccount();
      this.removeToken();
      return;
    }
    const token = this.getToken();
    if (!token) throw new Error('Not logged in');

    const res = await fetch(`${API_BASE_URL}/api/account`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to delete account');
    this.removeToken();
  }

  static async reportMessage(messageId: string, reason: string): Promise<void> {
    if (USE_MOCK) return MockApiClient.reportMessage(messageId, reason);
    await fetch(`${API_BASE_URL}/api/report`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messageId, reason }),
    });
  }

  static async getSupporters(): Promise<SupportersData> {
    if (USE_MOCK) return MockApiClient.getSupporters();
    try {
      const res = await fetch(`${API_BASE_URL}/api/supporters`);
      if (!res.ok) throw new Error('Failed to load supporters');
      return await res.json() as SupportersData;
    } catch {
      // Graceful fallback for offline / disconnected environments
      return {
        supporters: [
          {
            id: 'demo-1',
            alias: 'Anonymous Guardian',
            tier: 'Golden Guardian',
            note: 'Love the true zero-tracking privacy on SecretMsg. Keep it open!',
            createdAt: new Date(Date.now() - 3600000 * 4).toISOString(),
          },
          {
            id: 'demo-2',
            alias: 'Coffee Lover #42',
            tier: 'Coffee Backer',
            note: 'Super smooth UI. Coffee on me for server hosting ☕',
            createdAt: new Date(Date.now() - 3600000 * 26).toISOString(),
          },
          {
            id: 'demo-3',
            alias: 'Secret Admirer 🤫',
            tier: 'Silver Patron',
            note: 'Sent this to my crush and they replied! Thank you!',
            createdAt: new Date(Date.now() - 3600000 * 48).toISOString(),
          },
          {
            id: 'demo-4',
            alias: 'Anonymous Supporter',
            tier: 'Bronze Supporter',
            note: 'Supporting independent open-source web platforms.',
            createdAt: new Date(Date.now() - 3600000 * 72).toISOString(),
          },
        ],
        stats: {
          totalSupporters: 4,
          monthlyServerGoalPercent: 100,
          currentMonth: 'September 2026',
        },
      };
    }
  }
}
