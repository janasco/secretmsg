# Privacy Policy for SecretMsg (`secretmsg.net`)

**Last Updated:** September 2026

At SecretMsg (`secretmsg.net`), privacy is not an afterthought—it is the core foundation of our design. This Privacy Policy explains how information is collected, used, and protected when you use our platform.

---

## 1. What We Collect

### For Message Senders (Anonymous Users)
- **Zero Identification**: When you send an anonymous message to a user via `secretmsg.net/{username}`, we **do NOT store** your name, phone number, physical address, or account information.
- **Message Content**: We temporarily store the sanitized text content of your message so the recipient can read it.
- **Spam Verification**: We use Cloudflare Turnstile to verify that you are a human. Turnstile evaluates non-invasive browser signals without tracking cookies or cross-site monitoring.
- **Transient Ephemeral Logs**: Standard Cloudflare edge infrastructure may process IP addresses transiently for rate-limiting and DDoS defense; however, IP addresses are never associated with message bodies in the application database.

### For Registered Recipients (Account Holders)
- **Email Address / Account Identifier**: Collected strictly to authenticate your account.
- **Username / Public Handle**: The unique slug (minimum 4 characters) used to construct your sharing link (e.g. `secretmsg.net/yourname`).
- **Received Messages**: The sanitized text of messages sent to your link.
- **Supporter Status & Perks**: Flags indicating whether you have unlocked modular donation perks (Verified Badge, Viewer Hints, Sender Hints, or Complete VIP Pass).
- **Client Preferences & Safety Controls**: Notification preferences, appearance preferences, custom hidden word blocklists, blocked sender lists, and link pause settings are stored directly in your local browser storage or associated securely with your board session.

---

## 2. What We NEVER Do

- We **never sell, rent, or trade** user data or email addresses to advertisers, data brokers, or third parties.
- We **never display advertising tracking pixels** or third-party behavioral trackers.
- We **never reveal the sender's identity to the recipient**.
- We **never log or sell custom hidden word lists or blocked user lists**.

---

## 3. How We Use Information

Information is used solely to:
1. Deliver anonymous messages to the intended recipient's inbox.
2. Authenticate account holders when logging in via email OTP.
3. Defend the platform against bot floods, spam campaigns, and malicious exploitation.
4. Process voluntary supporter donations via third-party open-source merchant providers (Polar.sh / Stripe).

---

## 4. Third-Party Service Providers

We utilize minimal, privacy-conscious infrastructure providers:
- **Cloudflare** (Edge routing, Cloudflare D1 database, Turnstile bot defense).
- **Resend** (Transactional email delivery for login OTPs).
- **Donation Providers** (Payment processors for supporters; we never see or store raw credit card details).

---

## 5. Data Retention & Account Deletion (GDPR & CCPA Rights)

### Complete Data Wipeout
Under GDPR, CCPA, and our privacy commitment, you have the absolute right to erasure.
- You can navigate to **Settings → Delete Account** inside the SecretMsg web or mobile app.
- When you confirm deletion, your account row, email address, username, and **every single message in your inbox are permanently deleted** from the database via SQL cascade.
- This process is instantaneous and irreversible.

---

## 6. Security Measures

- All network traffic is encrypted via TLS 1.3 over HTTPS.
- Authentication utilizes short-lived cryptographically secure OTP tokens.
- Secret tokens and API credentials are kept strictly isolated from public repositories and client-side bundles.

---

## 7. Contact for Privacy Inquiries

If you have questions about this policy or your personal data:
- **Email**: `privacy@secretmsg.net` or `janasco@duck.com`
