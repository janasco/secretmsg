/**
 * SecretMsg Platform API Client
 * Talks to the real Cloudflare Worker backend at api.secretmsg.net.
 *
 * IMPORTANT: calls must use the absolute API_BASE_URL, not relative /api/... paths.
 * secretmsg.net (this static site) does not proxy /api/* to the Worker - a relative
 * fetch silently falls through to this site's own HTML fallback instead of the API.
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.SecretMsgAPI = factory();
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  var API_BASE_URL = 'https://api.secretmsg.net';
  var PUBLIC_DOMAIN = 'https://secretmsg.net';
  var APP_DOMAIN = 'https://app.secretmsg.net';
  var TOKEN_KEY = 'secretmsg_auth_token';
  var USER_KEY = 'secretmsg_user_profile';

  function getShareUrl(username) {
    return PUBLIC_DOMAIN + '/' + encodeURIComponent(username);
  }

  function getAppUrl(path) {
    var p = path || '/';
    return APP_DOMAIN + (p.charAt(0) === '/' ? p : '/' + p);
  }

  // Thrown when a Bearer-authed request comes back 401 - the session token is
  // missing, expired, or invalid. Callers should treat this as "log the user out".
  function UnauthorizedError(message) {
    var err = new Error(message || 'Session expired. Please log in again.');
    err.name = 'UnauthorizedError';
    Object.setPrototypeOf(err, UnauthorizedError.prototype);
    return err;
  }
  UnauthorizedError.prototype = Object.create(Error.prototype);
  UnauthorizedError.prototype.constructor = UnauthorizedError;

  function getToken() {
    return localStorage.getItem(TOKEN_KEY);
  }
  function setToken(token) {
    localStorage.setItem(TOKEN_KEY, token);
  }
  function removeToken() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
  }
  function getSavedUser() {
    var raw = localStorage.getItem(USER_KEY);
    if (!raw) return null;
    try {
      return JSON.parse(raw);
    } catch (e) {
      return null;
    }
  }
  function saveUser(user) {
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  }
  function isLoggedIn() {
    return Boolean(getToken());
  }

  async function parseJsonSafe(res) {
    try {
      return await res.json();
    } catch (e) {
      return {};
    }
  }

  async function getRecipientProfile(username) {
    var res = await fetch(API_BASE_URL + '/api/user/' + encodeURIComponent(username));
    if (!res.ok) {
      var errData = await parseJsonSafe(res);
      throw new Error(errData.error || 'User not found');
    }
    var data = await res.json();
    return data.user;
  }

  async function sendAnonymousMessage(username, content, turnstileToken, allowClue) {
    var res = await fetch(API_BASE_URL + '/api/message/' + encodeURIComponent(username), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content: content, turnstileToken: turnstileToken, allowClue: allowClue }),
    });
    var data = await parseJsonSafe(res);
    if (!res.ok) {
      throw new Error(data.error || 'Failed to send message');
    }
    return { success: true, replyToken: data.replyToken };
  }

  async function requestOtp(email) {
    var res = await fetch(API_BASE_URL + '/api/auth/otp-request', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: email }),
    });
    if (!res.ok) {
      var data = await parseJsonSafe(res);
      throw new Error(data.error || 'Failed to send verification code');
    }
  }

  async function verifyOtp(email, otp, username) {
    var res = await fetch(API_BASE_URL + '/api/auth/otp-verify', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: email, otp: otp, username: username }),
    });
    var data = await parseJsonSafe(res);
    if (!res.ok || !data.token || !data.user) {
      throw new Error(data.error || 'Invalid or expired code');
    }
    setToken(data.token);
    saveUser(data.user);
    return { user: data.user, token: data.token };
  }

  async function getMe() {
    var token = getToken();
    if (!token) throw new UnauthorizedError('Not logged in');
    var res = await fetch(API_BASE_URL + '/api/me', {
      headers: { Authorization: 'Bearer ' + token },
    });
    if (res.status === 401) throw new UnauthorizedError();
    if (!res.ok) throw new Error('Failed to load profile');
    var data = await res.json();
    saveUser(data.user);
    return data.user;
  }

  // updates: { paused_until?: number|null, hidden_words?: string[] }
  async function updateSettings(updates) {
    var token = getToken();
    if (!token) throw new UnauthorizedError('Not logged in');
    var res = await fetch(API_BASE_URL + '/api/me', {
      method: 'PATCH',
      headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
    if (res.status === 401) throw new UnauthorizedError();
    var data = await parseJsonSafe(res);
    if (!res.ok) throw new Error(data.error || 'Failed to update settings');
    return data;
  }

  async function getInbox() {
    var token = getToken();
    if (!token) throw new UnauthorizedError('Not logged in');
    var res = await fetch(API_BASE_URL + '/api/inbox', {
      headers: { Authorization: 'Bearer ' + token },
    });
    if (res.status === 401) throw new UnauthorizedError();
    if (!res.ok) throw new Error('Failed to load inbox');
    var data = await res.json();
    return data.messages || [];
  }

  async function replyMessage(messageId, reply) {
    var token = getToken();
    if (!token) throw new UnauthorizedError('Not logged in');
    var res = await fetch(API_BASE_URL + '/api/inbox/' + encodeURIComponent(messageId) + '/reply', {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
      body: JSON.stringify({ reply: reply }),
    });
    if (res.status === 401) throw new UnauthorizedError();
    if (!res.ok) {
      var data = await parseJsonSafe(res);
      throw new Error(data.error || 'Failed to send reply');
    }
  }

  async function checkReply(replyToken) {
    var res = await fetch(API_BASE_URL + '/api/reply/' + encodeURIComponent(replyToken));
    if (!res.ok) throw new Error('Reply thread not found');
    var data = await res.json();
    return data.thread;
  }

  async function deleteAccount() {
    var token = getToken();
    if (!token) throw new UnauthorizedError('Not logged in');
    var res = await fetch(API_BASE_URL + '/api/account', {
      method: 'DELETE',
      headers: { Authorization: 'Bearer ' + token },
    });
    if (res.status === 401) throw new UnauthorizedError();
    if (!res.ok) throw new Error('Failed to delete account');
    removeToken();
  }

  async function reportMessage(messageId, reason) {
    var token = getToken();
    var headers = { 'Content-Type': 'application/json' };
    if (token) headers.Authorization = 'Bearer ' + token;
    var res = await fetch(API_BASE_URL + '/api/report', {
      method: 'POST',
      headers: headers,
      body: JSON.stringify({ messageId: messageId, reason: reason }),
    });
    if (!res.ok) {
      var data = await parseJsonSafe(res);
      throw new Error(data.error || 'Failed to submit report');
    }
  }

  async function getSupporters() {
    var res = await fetch(API_BASE_URL + '/api/supporters');
    if (!res.ok) throw new Error('Failed to load supporters');
    return res.json();
  }

  // feature: 'badge' | 'viewer_hints' | 'sender_hints' | 'bundle'
  // Returns { url } - redirect the browser there to complete the Polar checkout.
  async function createCheckout(feature) {
    var token = getToken();
    if (!token) throw new UnauthorizedError('Not logged in');
    var res = await fetch(API_BASE_URL + '/api/checkout', {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
      body: JSON.stringify({ feature: feature }),
    });
    if (res.status === 401) throw new UnauthorizedError();
    var data = await parseJsonSafe(res);
    if (!res.ok || !data.url) {
      throw new Error(data.error || 'Failed to start checkout');
    }
    return { url: data.url };
  }

  async function submitGooglePayDonation(feature, paymentData, amountUsd) {
    var token = getToken();
    if (!token) throw new UnauthorizedError('Not logged in');
    var res = await fetch(API_BASE_URL + '/api/donation/google-pay', {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
      body: JSON.stringify({ feature: feature, paymentData: paymentData, amountUsd: amountUsd }),
    });
    if (res.status === 401) throw new UnauthorizedError();
    var data = await parseJsonSafe(res);
    if (!res.ok) {
      throw new Error(data.error || 'Google Pay perk unlock failed');
    }
    if (data.user) {
      saveUser(data.user);
    }
    return data;
  }

  return {
    API_BASE_URL: API_BASE_URL,
    PUBLIC_DOMAIN: PUBLIC_DOMAIN,
    APP_DOMAIN: APP_DOMAIN,
    getShareUrl: getShareUrl,
    getAppUrl: getAppUrl,
    UnauthorizedError: UnauthorizedError,
    getToken: getToken,
    setToken: setToken,
    removeToken: removeToken,
    getSavedUser: getSavedUser,
    saveUser: saveUser,
    isLoggedIn: isLoggedIn,
    getRecipientProfile: getRecipientProfile,
    sendAnonymousMessage: sendAnonymousMessage,
    requestOtp: requestOtp,
    verifyOtp: verifyOtp,
    getMe: getMe,
    getInbox: getInbox,
    replyMessage: replyMessage,
    checkReply: checkReply,
    deleteAccount: deleteAccount,
    reportMessage: reportMessage,
    getSupporters: getSupporters,
    updateSettings: updateSettings,
    createCheckout: createCheckout,
    submitGooglePayDonation: submitGooglePayDonation,
  };
});
