# Privacy Policy for SecretMsg (`secretmsg.net`)

**Last Updated:** September 2026

At SecretMsg (`secretmsg.net`), privacy is not an afterthought—it is the core foundation of our design. This Privacy Policy explains how information is collected, used, and protected when you use our platform.

---

## 1. What We Collect

### For Message Senders (Anonymous Users)
- **Zero Identification**: When you send an anonymous message to a user via `secretmsg.net/{username}`, we **do NOT store** your name, phone number, physical address, or account information.
- **Message Content**: We temporarily store the sanitized text content of your message so the recipient can read it.
- **Spam Verification**: We use automated human-verification tools to confirm you are not a bot. They evaluate non-invasive browser signals without tracking cookies or cross-site monitoring.
- **Transient Ephemeral Logs**: Standard hosting infrastructure may process IP addresses transiently for rate-limiting and abuse defense; however, IP addresses are never associated with message bodies in the application database.

### For Registered Recipients (Account Holders)
- **Email Address / Account Identifier**: Collected strictly to authenticate your account.
- **Username / Public Handle**: The unique slug (minimum 4 characters) used to construct your sharing link (e.g. `secretmsg.net/yourname`).
- **Received Messages**: The sanitized text of messages sent to your link.
- **Supporter Status & Perks**: Flags indicating whether you have unlocked modular donation perks (Verified Badge, Viewer Hints, Sender Hints, or Complete VIP Pass), and, on Android, records of verified Google Play purchases used for entitlement and replay protection.
- **Client Preferences & Safety Controls**: Notification preferences, appearance preferences, custom hidden word blocklists, and link pause settings are associated securely with your board session. Sender-hint preferences control whether coarse context clues (e.g. an approximate device type) are shown to you on received messages; they never reveal a sender's identity.

---

## 2. What We NEVER Do

- We **never sell, rent, or trade** user data or email addresses to advertisers, data brokers, or third parties.
- We **never display advertising tracking pixels** or third-party behavioral trackers.
- We **never reveal the sender's identity to the recipient**.
- We **never log or sell custom hidden word lists**.

---

## 3. How We Use Information

Information is used solely to:
1. Deliver anonymous messages to the intended recipient's inbox.
2. Authenticate account holders — via email one-time codes, or via pairing codes that open a read-only browser session.
3. Defend the platform against bot floods, spam campaigns, and malicious exploitation.
4. Verify supporter payments through signature-checked webhooks (Polar.sh) or server-side purchase verification (Google Play) before granting perks.

---

## 4. Third-Party Service Providers

We utilize minimal, privacy-conscious infrastructure providers:
- **Hosting & Infrastructure** (secure hosting, storage, and abuse defense).
- **Email Delivery** (A transactional email service used for login codes).
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
