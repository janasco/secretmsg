import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ApiClient } from '@/lib/api';

const tokenKey = 'secretmsg_auth_token';
const profileKey = 'secretmsg_user_profile';
const scopeKey = 'secretmsg_auth_scope';

const profile = {
  id: 'u1',
  username: 'tester',
  display_name: 'Tester',
  avatar_seed: 'tester',
  is_premium: 0,
};

let storage: Record<string, string>;

beforeEach(() => {
  storage = {};
  vi.stubGlobal('localStorage', {
    getItem: (key: string) => storage[key] ?? null,
    setItem: (key: string, value: string) => {
      storage[key] = value;
    },
    removeItem: (key: string) => {
      delete storage[key];
    },
  });
});

afterEach(() => {
  vi.unstubAllGlobals();
});

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

describe('ApiClient authentication storage', () => {
  it('stores and reads the session token, profile, and scope', () => {
    ApiClient.setToken('stored-token');
    ApiClient.saveUser(profile);
    ApiClient.setScope('read');

    expect(ApiClient.getToken()).toBe('stored-token');
    expect(localStorage.getItem(tokenKey)).toBe('stored-token');
    expect(ApiClient.getSavedUser()).toEqual(profile);
    expect(ApiClient.getScope()).toBe('read');
  });

  it('removes the token, profile, and scope together', () => {
    ApiClient.setToken('stored-token');
    ApiClient.saveUser(profile);
    ApiClient.setScope('read');

    ApiClient.removeToken();

    expect(ApiClient.getToken()).toBeNull();
    expect(localStorage.getItem(tokenKey)).toBeNull();
    expect(localStorage.getItem(profileKey)).toBeNull();
    expect(localStorage.getItem(scopeKey)).toBeNull();
  });

  it('reports read scope as read-only and full scope as writable', () => {
    ApiClient.setScope('full');
    expect(ApiClient.isReadOnly()).toBe(false);

    ApiClient.setScope('read');
    expect(ApiClient.isReadOnly()).toBe(true);
  });
});

describe('ApiClient token rotation', () => {
  it('persists the token returned by a PIN change', async () => {
    ApiClient.setToken('old-token');
    const fetchMock = vi.fn(async () => jsonResponse({ token: 'rotated-pin-token' }));
    vi.stubGlobal('fetch', fetchMock);

    await ApiClient.authChangePin('1111', '2222');

    expect(ApiClient.getToken()).toBe('rotated-pin-token');
    expect(fetchMock).toHaveBeenCalledOnce();
  });

  it('persists the token returned by a backup-code refresh', async () => {
    ApiClient.setToken('old-token');
    const fetchMock = vi.fn(async () => jsonResponse({
      token: 'rotated-backup-token',
      backupCodes: ['one', 'two'],
    }));
    vi.stubGlobal('fetch', fetchMock);

    await expect(ApiClient.authRefreshBackupCodes('1111')).resolves.toEqual(['one', 'two']);

    expect(ApiClient.getToken()).toBe('rotated-backup-token');
    expect(fetchMock).toHaveBeenCalledOnce();
  });

  it('keeps the existing token when PIN change omits a replacement', async () => {
    ApiClient.setToken('old-token');
    vi.stubGlobal('fetch', vi.fn(async () => jsonResponse({})));

    await ApiClient.authChangePin('1111', '2222');

    expect(ApiClient.getToken()).toBe('old-token');
  });

  it('keeps the existing token when backup refresh omits a replacement', async () => {
    ApiClient.setToken('old-token');
    vi.stubGlobal('fetch', vi.fn(async () => jsonResponse({ backupCodes: [] })));

    await ApiClient.authRefreshBackupCodes('1111');

    expect(ApiClient.getToken()).toBe('old-token');
  });
});

describe('ApiClient read-only deletion guard', () => {
  it('does not send an account deletion request for a read-only session', async () => {
    ApiClient.setToken('read-only-token');
    ApiClient.setScope('read');
    const fetchMock = vi.fn(async () => new Response(null, { status: 204 }));
    vi.stubGlobal('fetch', fetchMock);

    await expect(ApiClient.deleteAccount()).rejects.toThrow();
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
