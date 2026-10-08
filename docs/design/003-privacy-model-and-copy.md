# SecretMsg — privacy model, UI copy, value proposition

Companion to the feature briefs. This file holds the parts that must be
**coherent across every feature**, so they are written once rather than per-brief.

---

## 1. The privacy model, stated honestly

The hybrid model was chosen because end-to-end encryption and server-side AI
moderation cannot both be true as normally specified: a server cannot classify
content it cannot read. The resolution is to be precise about *which* guarantee
applies *where*, rather than claiming both.

| Layer | Who can read it | Why |
|---|---|---|
| Message body | Sender and recipient only | End-to-end encrypted; the server holds ciphertext |
| Timestamps, size, recipient, delivery state | Server | Abuse prevention, rate limiting, delivery |
| Rate-limit keys | Server (hashed) | Throttling; no readable IP stored |
| FCM push payload | Google, and the device | Data-only, truncated preview, never the full body |

### What this guarantee does NOT cover — state it, do not bury it

1. **Client-side moderation is bypassable.** Filtering runs on the recipient's
   device against plaintext. A modified client can skip it. This is weaker than
   server-side filtering, and the app must not imply otherwise.
2. **Metadata is not encrypted.** Who received a message, when, and how large it
   was are all visible to the server. "Anonymous" means the *sender's identity*
   is not disclosed — it does not mean the exchange is invisible.
3. **The recipient can always screenshot.** No cryptographic property prevents it.

### Four consequences that will otherwise be discovered late

These are architectural, not cosmetic, and each one breaks something that works
today:

- **Server-side Filtered Words stops working.** It is currently enforced at
  compose time because the server can read the content. Under E2E that is
  impossible. It must either move to the sender's client (before encryption) or
  be dropped. Moving it is preferred — filtering at compose is still *before*
  delivery — but the enforcement guarantee weakens from "cannot be bypassed" to
  "cannot be bypassed by an unmodified client". The existing listing and policy
  copy that describe server-side enforcement must change with it.
- **The 140-character push preview cannot be produced server-side.** It is
  truncated by the Worker today, which requires reading the body. Under E2E the
  preview must be generated on the sending device and sent alongside the
  ciphertext — which means the sender chooses whether a preview exists at all.
  The privacy policy's current wording about push needs revisiting.
- **"Report this message" needs a design.** A moderator cannot review content the
  server cannot decrypt. The workable answer is opt-in disclosure: when a user
  reports, their client attaches the plaintext of *that message only*, with the
  action named plainly at the moment of reporting. That is defensible, but it is
  a deliberate weakening of the guarantee and belongs in the report screen's copy,
  not in a policy footnote.
- **Multi-device and reinstall need a key story.** A user who reinstalls has no
  key and cannot read history unless keys are escrowed — and escrow is a
  backdoor by another name. The honest default is that history is not recoverable
  after reinstall, and the onboarding must say so *before* the user relies on it.

### Sender hints — investigated, and a correction

An earlier assessment called this "the single most privacy-invasive feature in
the product". **That was wrong, and the correction matters more than the
original claim.**

What the recipient actually receives (`api/src/index.ts:375-383`) is one of five
coarse strings:

```
Mobile / Android · Mobile / iOS · Desktop / Mac · Desktop / Windows · Web Browser
```

and only when the sender passes `allowClue === true` **and** the recipient has
hints enabled. Five possible values, opt-in on both sides. Nobody is identifiable
from that, and it is metadata in exactly the sense the model above already
covers — so it does not conflict with an encrypted body.

There is a real fact nearby, but it is a different one. `sender_fp_hash` is the
SHA-256 of a random 32-character string the client generates once and keeps in
secure storage. It is **not** a hardware identifier — but it is stable per
install, so the server can link every message from one install, across
recipients. It is never returned in a message payload; it exists so
`blocked_senders` can work and so the inbox can paginate.

**Recommendation: keep the feature, change three things.**

1. **Rename it.** "Sender hints" implies the recipient learns something *about
   the sender*. It does not. A name like "Device context" removes the implied
   conflict at zero architectural cost.
2. **Disclose the pseudonym.** State in the privacy policy that the server can
   link messages from the same install, in the same section as the hashed
   rate-limit keys. It is the same class of disclosure and it is better stated
   than discovered.
3. **Do not claim end-to-end encryption yet.** The actual tension is not hints —
   it is that the server reads every message body today, for `mod_sensitivity`
   scanning and Filtered Words. That is precisely what E2E changes, and until it
   does, the claim would be false.

Optional, unresolved: rotating `sender_fp_hash` periodically would reduce
long-term linkability while keeping blocking useful for a window. It trades
against block evasion — a blocked sender waits out the rotation. Left as an open
question rather than a recommendation.

### Compliance floor

- **COPPA** applies below 13. The product targets 13+, so the floor is a hard
  age gate at signup and **no** collection from under-13s. Play's Families policy
  is separate and stricter; staying out of Families is the simpler, honest choice.
- **GDPR** — lawful basis, deletion, and portability. Deletion already exists and
  is immediate for the primary record. Encrypted history is the awkward part:
  deleting the ciphertext is easy, but backups retain it for the retention
  window, and the policy must say so rather than implying instant erasure
  everywhere.
- **Retention** — a stated window per data class, enforced rather than described.

---

## 2. UI copy

Written to be pasted, and deliberately plain. No exclamation marks in error
states, no reassurance the app cannot back up.

### Onboarding (in order)

| Step | Copy |
|---|---|
| Value | `Get honest answers, anonymously.` |
| Value sub | `Share one link. People reply without an account — and without you ever knowing who they are.` |
| Age gate | `You must be 13 or older to use SecretMsg.` |
| Age gate sub | `We ask once, at signup. We do not knowingly collect anything from anyone under 13.` |
| Handle | `Pick your link name` |
| Handle hint | `Letters, numbers, dots, dashes. You can change this later — old links to it will stop working.` |
| Encryption | `Your messages are end-to-end encrypted.` |
| Encryption sub | `Not even we can read them. That also means: if you reinstall the app, your message history cannot be restored.` |
| Notifications | `Get told when someone replies?` |
| Notifications sub | `We send a short preview, never the full message.` |

### Buttons and labels

```
Create my link              Copy my link
Send anonymously            Reply anonymously
Pause my link               Resume my link
Report                      Block this sender
Delete for me               Delete for everyone
Turn on encryption          Verify this person
Join this box               Leave this box
Visible to the box          Visible to the owner only
```

### Empty and loading states

```
No messages yet.        Share your link and wait for the first one.
Nothing here yet.       When someone replies, it lands here.
Box is paused.          Nobody can send you anything right now.
Decrypting…             (transient, under 2 seconds)
Waiting for a key.      The recipient has not opened the app yet.
```

### Error messages

| Situation | Copy |
|---|---|
| Filtered at compose | `Your message contains a word this person has filtered. Edit it, or send something else.` |
| Send failed, offline | `Saved. This will send when you are back online.` |
| Send failed, blocked | `This person is not accepting messages right now.` |
| Device offline, no key | `The recipient's device has not received their key yet. Try again in a moment.` |
| Key mismatch | `This message could not be verified. It may have been altered in transit. Do not trust its contents.` |
| History after reinstall | `Your old messages cannot be restored. They were encrypted with a key that was on your previous device.` |
| Report disclosure | `Reporting shows us this message so we can review it. Nothing else in your inbox is shared.` |
| Age gate failure | `You need to be 13 or older to use SecretMsg.` |
| Group box, member posts | `This box has N members. Only the owner sees who sent what.` |

### Tone rules

- Errors say what happened and what to do. Never "Oops!".
- Never claim a guarantee the model above does not support — no "only you can
  read this" on a message whose metadata is server-visible.
- Say the cost of a privacy choice at the moment it is made, not in a policy.

---

## 3. Value proposition

**One sentence:**

> SecretMsg gives you a link that collects honest, anonymous replies — with the
> messages end-to-end encrypted, moderation on your device, and no account
> required for anyone who wants to answer.

**Shortened for a store subtitle:**

> Anonymous replies, end-to-end encrypted.
