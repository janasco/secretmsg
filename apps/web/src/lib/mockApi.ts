/**
 * SecretMsg Offline Mock API Adapter
 * Enables open-source contributors to develop and test the full client UI
 * without needing a Cloudflare backend or production credentials.
 */

import { UserProfile, AnonymousMessage, SupportersData } from './api';

const MOCK_STORAGE_KEY_MESSAGES = 'secretmsg_mock_messages';
const MOCK_STORAGE_KEY_REPLIES = 'secretmsg_mock_replies';

export class MockApiClient {
  private static getStoredMessages(): AnonymousMessage[] {
    const raw = localStorage.getItem(MOCK_STORAGE_KEY_MESSAGES);
    if (!raw) {
      const initial: AnonymousMessage[] = [
        {
          id: 'mock_msg_1',
          content: 'TBH your playlist taste is unmatched! What song have you been looping lately?',
          reply_content: 'Thank you! Currently looping new tracks from Fred again.. and Tycho ✨',
          reply_at: new Date(Date.now() - 3600000 * 2).toISOString(),
          is_pinned: 1,
          is_read: 1,
          device_hint: 'Mobile / iOS',
          created_at: new Date(Date.now() - 3600000 * 5).toISOString(),
        },
        {
          id: 'mock_msg_2',
          content: 'You always bring good energy to every room. Keep doing your thing 🤍',
          reply_content: null,
          reply_at: null,
          is_pinned: 0,
          is_read: 0,
          device_hint: 'Mobile / Android',
          created_at: new Date(Date.now() - 3600000 * 1).toISOString(),
        },
        {
          id: 'mock_msg_3',
          content: 'I have had a secret crush on you since last semester…',
          reply_content: null,
          reply_at: null,
          is_pinned: 0,
          is_read: 0,
          device_hint: 'Desktop / Mac',
          created_at: new Date(Date.now() - 1800000).toISOString(),
        },
      ];
      localStorage.setItem(MOCK_STORAGE_KEY_MESSAGES, JSON.stringify(initial));
      return initial;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return [];
    }
  }

  static async getRecipientProfile(username: string): Promise<UserProfile> {
    return {
      id: 'mock_usr_123',
      username: username || 'janasco',
      display_name: username || 'janasco',
      avatar_seed: username || 'janasco',
      bio: 'Open source contributor & privacy advocate',
      is_premium: 1,
      badge_title: 'Golden Guardian',
    };
  }

  static async sendAnonymousMessage(
    _username: string,
    content: string,
    _turnstileToken?: string,
    allowClue?: boolean
  ): Promise<{ success: boolean; replyToken: string }> {
    const messages = this.getStoredMessages();
    const replyToken = `mock_rep_${Math.random().toString(36).substring(2, 12)}`;
    const newMsg: AnonymousMessage = {
      id: `mock_msg_${Date.now()}`,
      content,
      reply_content: null,
      reply_at: null,
      is_pinned: 0,
      is_read: 0,
      device_hint: allowClue ? 'Mobile / Web' : null,
      created_at: new Date().toISOString(),
    };
    messages.unshift(newMsg);
    localStorage.setItem(MOCK_STORAGE_KEY_MESSAGES, JSON.stringify(messages));

    // Also store reply token map
    const repliesRaw = localStorage.getItem(MOCK_STORAGE_KEY_REPLIES) || '{}';
    const replies = JSON.parse(repliesRaw);
    replies[replyToken] = newMsg;
    localStorage.setItem(MOCK_STORAGE_KEY_REPLIES, JSON.stringify(replies));

    return { success: true, replyToken };
  }

  static async requestOtp(_email: string): Promise<void> {
    // In mock mode, any 6-digit OTP code works (e.g. 123456)
  }

  static async verifyOtp(email: string, _otp: string): Promise<{ user: UserProfile; token: string }> {
    const user: UserProfile = {
      id: 'mock_user_id',
      username: email.split('@')[0] || 'mockuser',
      display_name: email.split('@')[0] || 'Mock User',
      email,
      avatar_seed: email,
      is_premium: 1,
      badge_title: 'Developer',
    };
    return { user, token: 'mock_jwt_token_for_local_testing' };
  }

  static async getInbox(): Promise<AnonymousMessage[]> {
    return this.getStoredMessages();
  }

  static async replyMessage(messageId: string, reply: string): Promise<void> {
    const messages = this.getStoredMessages();
    const target = messages.find((m) => m.id === messageId);
    if (target) {
      target.reply_content = reply;
      target.reply_at = new Date().toISOString();
      target.is_read = 1;
      localStorage.setItem(MOCK_STORAGE_KEY_MESSAGES, JSON.stringify(messages));
    }
  }

  static async checkReply(token: string): Promise<{ content: string; reply_content?: string; reply_at?: string; created_at: string }> {
    const repliesRaw = localStorage.getItem(MOCK_STORAGE_KEY_REPLIES) || '{}';
    const replies = JSON.parse(repliesRaw);
    const thread = replies[token];
    if (!thread) {
      return {
        content: 'This is a mock question thread.',
        reply_content: 'This is a simulated reply for token verification.',
        reply_at: new Date().toISOString(),
        created_at: new Date(Date.now() - 3600000).toISOString(),
      };
    }
    return thread;
  }

  static async deleteAccount(): Promise<void> {
    localStorage.removeItem(MOCK_STORAGE_KEY_MESSAGES);
    localStorage.removeItem(MOCK_STORAGE_KEY_REPLIES);
  }

  static async reportMessage(_messageId: string, _reason: string): Promise<void> {
    // No-op mock report
  }

  static async getSupporters(): Promise<SupportersData> {
    return {
      supporters: [
        {
          id: 'sup-1',
          alias: 'Open Source Supporter',
          tier: 'Golden Guardian',
          note: 'Supporting privacy-focused communication platforms.',
          createdAt: new Date().toISOString(),
        },
      ],
      stats: {
        totalSupporters: 42,
        monthlyServerGoalPercent: 100,
        currentMonth: 'September 2026',
      },
    };
  }
}
