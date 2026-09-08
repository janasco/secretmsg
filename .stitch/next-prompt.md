---
page: settings
---
Mobile app Privacy Vault & Security Settings Screen for SecretMsg (`secretmsg.net`).

**DESIGN SYSTEM (REQUIRED):**
- Platform: Mobile viewport (390px width), clean minimalist mobile app layout.
- Theme: Clean minimalist dark titanium mode with high-contrast CRISP WHITE ACCENTS.
- Colors: Background #0B0E14, Card surface #151B26, Pure white #FFFFFF for primary accents & active pills, outline border rgba(255, 255, 255, 0.12), muted gray #94A3B8.
- Typography: Modern Inter typography, crisp legibility, tight headings, subtle letter spacing.
- Components: Rounded-2xl (16px) cards, pill-shaped tags (rounded-full), frosted glass search bar, persistent bottom navigation bar (Home, Dice, Stickers, Inbox, Profile) with white active indicator.
- Micro-details: Subtle hairlines, high touch-target buttons, clean white glowing highlights.

**Page Structure:**
1. **Top Header**: Back arrow to Profile, title "Privacy & Security Vault".
2. **Zero-Log Guarantee Card**: Minimalist security shield banner certifying that sender IP addresses and tracking cookies are never stored.
3. **Messaging Controls Section**:
   - Toggle "Allow Double-Blind Anonymous Replies" (Active)
   - Toggle "Display Approximate Sender Clues" (Active)
   - Toggle "Strict Bot Shield (Cloudflare Turnstile)" (Active)
4. **Account & Verification**:
   - Verified email: `janasco@duck.com` (Passwordless OTP)
   - Vanity handle: `@janasco` (Active)
5. **Nuclear Data Control Cards**:
   - Button: "Wipe All Stored Messages" (Permanent purge)
   - Button: "Delete Account Permanently"
6. **Bottom Navigation Bar**: Persistent 5-tab dock.
