# Design notes

Product specifications produced ahead of the 1.8 cycle. **None of this is
implemented**, and none of it should land before 1.7.0 is through review.

| File | What |
|---|---|
| [001-e2e-and-ai-moderation.md](001-e2e-and-ai-moderation.md) | End-to-end encryption, and on-device toxicity filtering + auto-translation |
| [002-social-and-identity.md](002-social-and-identity.md) | Custom themes and branded links, reactions and upvotes, opt-in verified senders, group boxes |
| [003-privacy-model-and-copy.md](003-privacy-model-and-copy.md) | The governing privacy model, UI copy, and the one-sentence value proposition |

## Read 003 first

It states the model the other two depend on: **message bodies end-to-end
encrypted, metadata visible to the server, moderation split between the
recipient's device and the server's metadata channel.** Every acceptance
criterion in 001 and 002 is written against that split, and a spec that assumes
otherwise will contradict it.

It also states plainly what the model does *not* cover, which is the part that
matters:

- Client-side filtering is **bypassable by a modified client**. It is weaker than
  the server-side enforcement shipping today.
- Metadata is not encrypted. "Anonymous" means the sender's identity is not
  disclosed; it does not mean the exchange is invisible.
- The recipient can always screenshot.

## Four consequences that break working features

These are architectural, not cosmetic. Each one currently works *because* the
server can read message content, and each stops working the day it cannot:

1. **Server-side Filtered Words** — enforced at compose time today
   (`api/src/index.ts:338`). Must move to the sender's client.
2. **The 140-character push preview** — truncated by the Worker today
   (`api/src/fcm.ts:163`). Must move to the sending device, which means the
   sender decides whether a preview exists at all.
3. **Report a message** — a moderator cannot review what the server cannot
   decrypt. Needs an opt-in disclosure design, named on the report screen.
4. **Reinstall and multi-device** — history is unrecoverable without key escrow,
   and escrow is a backdoor by another name. Onboarding must say so.

Anything shipping E2E must fix all four in the same release. Shipping the
encryption while the copy still promises server-side queryable filters is the
failure mode a store reviewer — or a journalist — finds first.

## Scope boundary

This is a specification set, not a plan. Sequencing, effort and prioritisation
are open, and 002 in particular proposes more product surface than the app has
today. Treat the open questions at the end of each brief as genuine rather than
rhetorical — several are unresolved on purpose.
