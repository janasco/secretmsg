# Play Data safety answers

Derived from the API source (`secretmsg-private/api/src/index.ts` and
`api/schema.sql`), not from the marketing copy. If the backend changes, this
needs revisiting — a Data safety form that contradicts actual behaviour is a
policy violation in itself.

## Does your app collect or share any of the required user data types?

**Yes.**

## Is all of the user data collected by your app encrypted in transit?

**Yes.** Every endpoint is HTTPS-only.

## Do you provide a way for users to request that their data be deleted?

**Yes.** Settings → Delete my account (`DELETE /api/account`), which removes the
profile and cascades to every message received. A web-accessible deletion route
is also required by policy — see the blocker in `SUBMISSION.md`.

---

## Data types to declare

### Personal info → Email address
- **Collected:** yes. **Shared:** no.
- **Required or optional:** required (it is currently the only sign-in method).
- **Purpose:** Account management.
- **Where:** `users.email`, and transiently in `auth_sessions` alongside a
  6-digit OTP that expires in 15 minutes.
- Sent to Resend solely to deliver that login code.

### Messages → Other in-app messages
- **Collected:** yes. **Shared:** no.
- **Required.** **Purpose:** App functionality.
- **Where:** `messages.content`, plus `reply_content` when the owner answers.
- Senders are not asked for any identifying detail; the message body is the
  only thing stored about them.

### Financial info → Purchase history
- **Collected:** yes. **Shared:** no.
- **Optional** (only if a supporter perk is bought).
- **Purpose:** App functionality.
- **Where:** `purchases` stores the Google Play purchase token, order id,
  product id and state. Card details are never seen by this app — Google Play
  handles the payment entirely.

### App info and performance
- **Not collected.** There is no analytics SDK and no crash reporter in the
  app. `pubspec.yaml` carries only http, webview_flutter,
  flutter_secure_storage, share_plus, path_provider, url_launcher and
  in_app_purchase.

### Device or other IDs
- **Not collected.** Worth being precise, because it looks close: each message
  stores a `device_hint` such as `"Mobile / Android"` or `"Desktop / Windows"`,
  derived from the User-Agent header at send time. It is a coarse platform
  label with no identifier in it, it cannot distinguish two senders, and it is
  only shown to the recipient if they have the Sender Hints perk.

### Location, Contacts, Photos, Health, Calendar, Files
- **Not collected.** The app requests no runtime permissions; the manifest
  declares only `INTERNET`, `ACCESS_NETWORK_STATE` and
  `com.android.vending.BILLING`.

---

## Notes for the reviewer-facing privacy policy

`https://secretmsg.net/p/privacy` must actually describe the above. Two things
to check before submitting:

- **IP addresses.** Not stored in readable form: rate limiting keys on a
  SHA-256 hash of the address (`rate_limits.id`). The hosting provider still
  processes IPs to serve requests, which the policy should say plainly.
- **Retention.** Messages persist until the recipient deletes them or deletes
  their account. Pairing codes expire after 5 minutes; OTPs after 15.
