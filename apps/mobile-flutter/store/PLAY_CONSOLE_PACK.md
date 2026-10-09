# Play Console submission pack

Copy-paste answers for **App content** and the store listing, derived from
[DATA_SAFETY.md](DATA_SAFETY.md). That annex is the audited source; this file is
only a transcription into the fields the console actually asks for. If the two
disagree, the annex is right and this file needs correcting.

Answers here reflect the **1.7.0** build (`versionCode 26`).

---

## 1. Privacy policy

```
https://secretmsg.net/p/privacy/
```

Canonical form, trailing slash. A bare `/privacy` matches the `/:username` route
and serves the homepage shell — do not use it.

## 2. App access

**Is any part of the app restricted?** Yes — the inbox requires sign-in.

Reviewer credentials (already provisioned in production D1 as the `playreview`
handle; store the PIN and backup codes in the password manager, never here):

```
Handle:  playreview
PIN:     <from the password manager>
```

Instructions to paste:

```
Sign in with the handle and PIN above from the app's first screen
(handle-and-PIN is the primary sign-in method; no email is needed).
The account has 4 seeded messages plus 1 quarantined sample, so the inbox,
thread view, and report flow are all reachable without sending anything.

Two features are account-gated on the web but not in this app: Dice Roulette
and Sticker Studio. In the app they are reachable directly from the bottom
navigation.
```

## 3. Ads

**Does the app contain ads?** **Yes.**

- Ad network: **Google AdMob** (Google Mobile Ads SDK via `google_mobile_ads` 9.1.0)
- Formats: **banner** and **rewarded video** only

Do not declare interstitial, app-open, rewarded-interstitial or native. If a
release build ever shows one, this answer is wrong and must be re-derived.

> **The website shows no ads.** Do not declare app ads for `secretmsg.net`; the
> site loads no ad SDK and no ad script.

## 4. Content rating questionnaire

Category: **Communication** (not Social, not Utility).

| Question | Answer |
|---|---|
| Violence, blood, sexual content, nudity, profanity | **No** to all |
| Controlled substances, gambling, alcohol, tobacco | **No** |
| **Users can interact / share content with other users** | **Yes** |
| **Users can share location** | **No** |
| **Personal information can be shared publicly** | **Yes** — a board is public by design |
| **Digital purchases** | **Yes** — one item, `remove_ads` |
| **User-generated content is shared with other users** | **Yes** |
| **Unmoderated user-generated content** | **No** — filtered words are enforced server-side at compose time, and every message carries a report control |

The two answers that drive the rating are user interaction and public
self-expression. The moderation answer must stay **No** only while
`POST /api/report` and the server-side filter enforcement both exist — if either
is removed, this answer becomes false.

## 5. Target audience and content

| Question | Answer |
|---|---|
| Target age groups | **13+** (do not select any group under 13) |
| Does the app appeal to children? | **No** |
| Is the app designed for children? | **No** |
| Do you want your app to be available to children? | **No** |

> [!IMPORTANT]
> This declaration is critical, not advisory, and it is the one Play is most
> likely to challenge. The product is an anonymous-messaging app in the same
> category as NGL and TBH, which are 13+/17+ apps. Selecting a child-directed
> audience would also make the AdMob configuration wrong, because the app
> explicitly sets a non-child `ageRestrictedTreatment` value — see
> SUBMISSION.md for that call site.

## 6. Data safety

### Top-level answers

| Question | Answer |
|---|---|
| Does the app collect or share required user data types? | **Yes** |
| Is all collected data encrypted in transit? | **Yes** |
| Can users request deletion of their data? | **Yes** |
| Is data deletion available without reinstalling? | **Yes** — in-app, and at `https://secretmsg.net/delete-account/` |

### Data types — collect / share

"Shared" uses the conservative processor-disclosure reading: a transfer to a
processor is declared as sharing, which is the safer reading of a Play-policy
judgment call.

| Play category | Collected | Shared | Required? | Purposes |
|---|---|---|---|---|
| **Personal info** — name, email, user IDs, other | Yes | Yes | Required for the handle account; email optional | Account management, authentication, app functionality, advertising, fraud prevention |
| **Financial info** — purchase history | Yes | Yes | Optional | Purchase verification and entitlement |
| **Messages** — other in-app messages | Yes | Yes | Required to use messaging | App functionality, moderation |
| **App activity** — app interactions | Yes | Yes | Optional | App functionality, moderation, abuse prevention, analytics-not-present |
| **Device or other IDs** — device IDs, **advertising ID**, user IDs, FCM tokens | Yes | Yes | Ad ID present only when the ad SDK initialises | Advertising, app functionality, fraud prevention |
| **App info and performance** — diagnostics, crash data | **No** | **No** | — | No analytics, crash-reporter or attribution SDK is present |
| **Location** | **No** | **No** | — | Not requested; no coarse location is stored |
| **Health and fitness**, **Photos and videos**, **Audio files**, **Files and documents**, **Calendar**, **Contacts**, **Web browsing** | **No** | **No** | — | Not collected by the service |

Two entries are easy to get wrong and are deliberate above:

- **Device or other IDs is Yes, and the advertising ID is why.** It is present
  only when the ad SDK initialises and an ad is requested; a user who has bought
  `remove_ads` is not shown ads.
- **App activity is Yes** even though there is no analytics SDK. It covers
  server-side abuse prevention, rate limiting and inbox moderation.

### Deletion

```
Users delete their account in Settings → Delete my account, or at
https://secretmsg.net/delete-account/ without signing in.

This removes the primary account row, handle, profile, received messages,
blocked-sender records, reports, pairing codes, purchase records, email-keyed
one-time-code sessions and identifiable account-derived rate-limit rows.

It does not remove: IP-keyed rate-limit rows that cannot be mapped to an
account, data held by Google for advertising, local data on the device, or
encrypted backups (up to 90 days).

Ad-specific: the in-app flow cannot delete anything Google holds about the
advertising identifier. Resetting it is an Android Settings → Privacy → Ads
action the user takes themselves, and the app claims no in-app control.
```

### Security practices to tick

- Data encrypted in transit — **Yes**
- Users can request data deletion — **Yes**
- Committed to Play's Families policy — **No** (not a Families app)
- Independent security review — **No**

## 7. Financial features

| Question | Answer |
|---|---|
| App has in-app purchases? | **Yes** |
| Product | `remove_ads` — one-time, non-subscription, no tiers |

> [!NOTE]
> **Updated 2026-10-09 — the purchase path is no longer broken.** An earlier
> revision of this pack warned that the three `GOOGLE_PLAY_*` credentials were
> absent and that a paying user would be charged with nothing granted. They are
> now provisioned and bound (`GOOGLE_PLAY_PACKAGE_NAME`, `GOOGLE_PLAY_SA_EMAIL`,
> `GOOGLE_PLAY_SA_KEY`), and the Play Developer API answers 200 for this
> service account — an edit is created and tracks are listed.
>
> **What is still unverified:** a real purchase has never completed once. The
> credentials work and the endpoint is reachable, but the end-to-end flow —
> pay, verify, grant, acknowledge — has only been reasoned about. Confirm it
> with one transaction before enabling ads, because a user who wants the ads
> gone must be able to buy them away.
>
> **Declare only what ships.** The retired `/api/donation/google-pay` endpoint
> returns HTTP 410 and grants nothing; it exists so an old client gets "retired"
> rather than a 404. It is not a payment path and must not be declared as one.

## 8. Other declarations

| Section | Answer |
|---|---|
| News app | No |
| Government app | No |
| Health app | No |
| Contains a health/medical device | No |
| COVID-19 contact tracing | No |
| Data safety for a "Designed for Families" app | Not applicable |

---

## Stale claims found while writing this

Two statements in the annex are no longer true and should be corrected there:

1. **DATA_SAFETY.md** says of `/api/config/ads`: *"That endpoint does not exist
   in the Worker at the time of this re-derivation, so the current build resolves
   to ads-off."* The endpoint now exists and returns
   `{"ads_enabled": false}`. The conclusion (ads off) is still correct; the
   reason given for it is not.
2. The same annex is silent on the missing Play credentials, which is the one
   thing standing between this submission and a working paid feature.

Neither changes an answer above, but both would mislead the next reader.
