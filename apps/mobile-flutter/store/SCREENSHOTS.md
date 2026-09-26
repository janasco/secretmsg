# SecretMsg Play Store phone screenshots

> The app is now ad-supported: a banner and a rewarded prompt. Read
> [Ads in screenshots](#ads-in-screenshots) before the capture run. It decides
> what may appear in a shot, and it is deliberately conservative about honesty.

## Ads in screenshots

### The short answer

Play permits ads in listing screenshots. Nothing in Play policy forbids
showing a real ad in a store screenshot, and hiding one is not required. But
every screenshot must still show the actual app, and an ad is a third party's
creative that SecretMsg does not control.

**Default recommendation: capture the listing screenshots in the ad-free
state.** Reasons, in order of weight:

1. The banner creative is not SecretMsg's. It can carry a landing page, an
   offer, or a brand that changes without notice, and it will change between
   the capture run and the review of the listing.
2. Ad creatives can contain text that conflicts with the content rating, with
   the "no data sale" framing in the listing, or with the brand. A screenshot
   is not the place to accept that risk.
3. A shot with a live ad is also a shot that will not reproduce. If the ad
   fails to fill, or the network is slow, or the kill-switch is off, the
   capture session produces a different image than the one you approved.

If you do want one shot that shows the ad-supported reality, capture it
separately, mark it clearly as optional, and use it in addition to the
ad-free set rather than instead of it. It is not a substitute for any of the
seven required feature shots.

### Do not misrepresent the app

- Do not composite, retouch, or mock an ad into a shot.
- Do not present the ad-free state as the only state the app has. The listing
  copy says the app is ad-supported, and that is the accurate description.
- Do not crop or hide a banner that is present in an otherwise ad-free-looking
  shot in order to make a shot look cleaner. If the banner is in the frame,
  either accept it or capture in the ad-free state.
- Do not add promotional badges, arrows, or captions pointing at an ad, and do
  not add text such as "ad supported" or "remove ads" onto the image after
  capture.

### Avoiding a banner overlapping the bottom navigation

The banner is mounted inside the shell's `bottomNavigationBar` column,
**directly above** the custom notch navigation bar
(`lib/screens/app_shell.dart:105`), as a fixed 50 dp slot
(`kBannerHeight` in `lib/ads/ads_config.dart`). So on any shell tab screen
the vertical order from the bottom is: system navigation inset, notch nav,
banner, content. Two consequences for capture:

- The banner and the notch nav occupy the same bottom region. They stack
  rather than overlap in the current layout, so a correct build shows both
  fully. **If a capture shows the banner covering or clipping the notch nav, or
  the notch indicator sitting on top of the banner, that is a layout bug, not a
  screenshot problem.** Do not crop around it and do not ship that build's
  screenshot; report the layout issue instead.
- The existing "retain the complete custom bottom navigation" rule now means
  the whole bottom stack — notch nav **and** banner if the banner is present —
  must be unclipped. If a 9:16 crop cannot hold both plus the content you
  wanted, drop content, not the bottom stack.
- The banner is wrapped in `SafeArea(top: false, bottom: false)`
  (`lib/ads/ads_banner.dart`), so it does not add its own system-inset padding.
  Do not fabricate padding around it.
- Pushed routes (message detail, Daily Drop) do not render the shell, so no
  banner appears there. Do not add a banner to those shots.

### Getting the ad-free state for a capture

- Purchase or restore `remove_ads` on the capture device, or sign in as an
  account whose entitlement is active. The entitlement suppresses the banner
  before any ad is requested, so the slot is absent rather than blank.
- **Do not fake it** by cropping the banner out of an ad-enabled capture. If
  the entitlement cannot be established on the device, capture in the
  ad-enabled state and accept the banner, or reshoot later.
- The remote kill-switch (`ads_enabled`, cached for six hours) is another way
  to get a clean run, but it is the wrong lever for a listing capture: the
  cache is local and a stale cached `false` can outlive a server change.
  Document which lever you used next to the PNGs.

### The rewarded prompt

The rewarded-video prompt is an interaction, not a static surface. It appears
when a user has an active streak and no freeze held. Capturing it is optional
and generally not worth it:

- If you capture it, capture the **prompt**, not a playing ad. A playing or
  completed third-party video creative in a store screenshot has the same
  reproducibility and content-rating problems as a live banner, and it may
  contain audio, motion, or flashing imagery.
- The reward is a streak freeze, and streak state is local
  `SharedPreferences` that cannot be seeded server-side. Getting the prompt on
  camera therefore requires a clean install plus a completed check-in, which
  conflicts with the seeded-content rules below. Treat a rewarded-prompt shot
  as optional and do not distort the seeded data to force it.
- If a rewarded shot is captured, the account must be in the seeded
  `playreview` state and no third-party creative may be frozen into the frame.

### Validation additions

Add these to the post-capture pass for every PNG:

- [ ] Either the shot is in the ad-free state, or any banner in it is complete,
      unclipped, in the correct position above the notch nav, and a real ad that
      actually appeared in the app.
- [ ] No banner overlaps, clips, or sits under the custom bottom navigation.
- [ ] No third-party ad creative, logo, slogan, landing-page fragment, or URL
      has been added, retouched, or cropped into the frame.
- [ ] No shot implies the app is ad-free when the listing says it is
      ad-supported, and no shot implies it is ad-supported when the capture
      was ad-free. The listing copy and the capture state must not contradict
      each other.

## Capture specification

Capture on a physical phone; no emulator is required. Produce 2–8 phone screenshots, with seven recommended shots below and an optional eighth only when the ad-free purchase screen is not ready for the listing.

Use these exact device and export settings for every shot:

- Orientation: portrait.
- Output: true 1080 × 1920 pixels, 9:16 portrait.
- Format: 24-bit RGB PNG with 8 bits per channel and no alpha channel. Do not export JPEG.
- App appearance: dark. The obsidian surfaces, violet accents, glowing cards, and neon sticker themes express the brand most strongly.
- Font scale: the device default. Do not enlarge text to make it easier to read.
- Keyboard: hidden in every final capture.
- System navigation: choose one Android navigation mode and use it consistently in all shots.
- Framing: retain the complete status bar and the complete custom bottom navigation wherever the screen provides them. Do not crop them. They evidence the app's notch and safe-area handling. Pushed message-detail and Daily Drop routes cover the shell's bottom navigation by design; do not add or fake one on those screens. On shell tab screens the optional ad banner sits directly **above** the notch nav in the same bottom stack, so "complete bottom navigation" means the whole stack; see [Ads in screenshots](#ads-in-screenshots).
- Animation: after changing tabs, wait at least 400 ms for the custom bottom-nav glide to finish. Capture only after the violet selection bubble and notch have settled on the selected tab.

**Critical aspect-ratio warning:** a modern phone screenshot is commonly 1080 × 2400, which is 9:20, not 9:16. Do not stretch or squeeze it into 9:16. Use a real 9:16 device or capture profile. If lossless cropping is unavoidable, produce exactly 1080 × 1920 and keep the full top bar, all intended app content, and the full bottom navigation. Crop only expendable background; never scale, resample, or distort the UI.

## Pre-capture checklist

1. Clear notification history and notification shade content. Make sure the status bar does not expose a real name, account, message, email address, or other private text.
2. Use clean app data for the capture run. Open SecretMsg after clearing app data, sign in as the seeded `playreview` account, and do not substitute a personal account.
3. On the first authenticated inbox load, wait for the daily check-in. The first-run dialog says **How are you vibing today?** Complete it with a mood or dismiss it. It must not cover a listing shot.
4. **Establish the ad state before anything else, and write it down.** Either activate the `remove_ads` entitlement on the device, or accept that ads are live. Also complete or dismiss the EEA/UK consent form if the device is in a consent-required region: **a consent dialog, a "why am I seeing this" form, or a "personalise ads" prompt in a listing screenshot is a rejection-grade mistake**, and it is the single most likely new failure in this capture run. If consent cannot be settled, do not shoot.
5. Leave **Profile → App → Appearance** set to **Dark**, not **System** or **Light**.
6. Keep the seeded content in place: four synthetic inbox messages, one synthetic blind reply, and `received_count=4` / `replies_count=1`. The account should resolve to rank **Newcomer**.
7. Use clean app data for the ritual state. Streak and Daily Drop completion are stored on-device in SharedPreferences, not in D1, so they cannot be seeded server-side. After the first authenticated check-in, a clean install should deliberately show a 1-day streak.
8. Wait for the inbox, profile, prompt pool, recipient lookup, and Turnstile to finish loading. No spinner, sync row, queued action, stale-cache notice, error, snackbar, ad placeholder, or ad error state may be visible. A banner slot showing an unloaded or failed ad is not a usable capture state.
9. Before each capture, hide the keyboard, dismiss tooltips and long-press menus, and wait for the 380 ms custom bottom-nav transition and other animations to settle.

## Recommended upload order

### 1. Populated inbox

- **File:** `01-secret-inbox-dark.png`
- **Navigation from launch:** Launch SecretMsg → signed-in launch lands on **Inbox** → remain on the **All** filter → do not open a message.
- **Ready state:** The four synthetic messages are loaded. The title, streak chip, unread count, filters, statistics, and message cards are populated. No loading, syncing, error, moderation, or report state is open. The first-run mood dialog is gone, the keyboard is hidden, and the **Inbox** item is settled in the custom bottom nav.
- **Why this shot:** It immediately shows a real anonymous inbox with concise, varied synthetic messages and the core experience.

### 2. Message detail with the double-blind reply

- **File:** `02-double-blind-reply-dark.png`
- **Navigation from launch:** Launch SecretMsg → **Inbox** → select the seeded message that already has the one synthetic reply → open its message detail.
- **Ready state:** The top of the detail shows **Anonymous Sender**, the synthetic message, and the green **Your blind reply** card with its synthetic reply. The reply editor is not open, the keyboard is hidden, and the report/block controls are outside the captured viewport. No loading or sending state is visible. This pushed route does not show the shell's custom bottom navigation; retain the complete system status bar and system navigation area.
- **Why this shot:** It makes the double-blind reply exchange understandable without exposing either participant's identity.

### 3. Anonymous composer after recipient lookup

- **File:** `03-anonymous-composer-dark.png`
- **Navigation from launch:** Launch SecretMsg → tap **Send** in the custom bottom nav → enter the synthetic seeded handle `playreview` → tap **Continue** → wait for the recipient profile and composer to load.
- **Ready state:** The recipient card for `playreview`, anonymous message field, **Get inspired**, device-hint switch, Turnstile area, and **Send Anonymously** control are visible and settled. Use short synthetic text, or leave the field at its neutral placeholder; do not open **Get inspired**. Hide the keyboard. No lookup spinner, Turnstile error, send state, personal profile, or real handle is visible. The **Send** item is settled in the custom bottom nav.
- **Why this shot:** It shows the simple recipient-to-composer path while making anonymity clear.

### 4. Daily Drop prompt

- **File:** `04-daily-drop-dark.png`
- **Navigation from launch:** Launch SecretMsg → **Inbox** → dismiss or complete the first-run mood dialog → tap **Today's Drop is live** in the inbox banner → open the Daily Drop prompt.
- **Ready state:** Capture the Daily Drop card before tapping **I answered it**. The daily prompt, expiry countdown, explanatory copy, and actions are fully visible, with no keyboard, spinner, share sheet, or snackbar. The prompt must be suitable for a public listing. This pushed route does not show the shell's custom bottom navigation; retain the complete system status bar and system navigation area.
- **Why this shot:** It shows a recurring ritual that gives recipients a reason to return each day.

### 5. Dice result

- **File:** `05-dice-result-dark.png`
- **Navigation from launch:** Launch SecretMsg → tap **Dice** in the custom bottom nav → choose a tame category such as **Deep Secrets** or **Real Talk** → tap **Roll the dice** → reroll until the result is suitable.
- **Ready state:** The prompt pool has loaded, the roll has completed, the result card and its **Copy** and **Use in composer** actions are visible, and the keyboard is hidden. Use **Deep Secrets**, **Real Talk**, **Chaotic & Wild**, or **3AM Thoughts**; do not use **Spicy** or **Crush & Flirt**. The **Dice** item is settled in the custom bottom nav.
- **Why this shot:** It demonstrates a playful conversation starter and a clear path from inspiration to sending.

### 6. Sticker Studio 9:16 preview

- **File:** `06-sticker-studio-dark.png`
- **Navigation from launch:** Launch SecretMsg → tap **Stickers** in the custom bottom nav → wait for the signed-in `playreview` identity and 9:16 preview to load.
- **Ready state:** Scroll just enough to center the 9:16 preview while retaining the complete app top bar and custom bottom nav. Use a synthetic caption, the `playreview` board link, a dark theme such as **Cyber Neon** or **SecretMsg Violet**, and **Generic** safe-area settings. Turn **Guides** off. Hide the keyboard and do not open Share, recents, or a system permission dialog. The **Stickers** item is settled in the custom bottom nav.
- **Why this shot:** It shows a polished shareable artifact and the app's strongest violet/neon visual system.

### 7. Profile with rank, challenges, and badges

- **File:** `07-profile-progress-dark.png`
- **Navigation from launch:** Launch SecretMsg → tap **Profile** in the custom bottom nav → wait for both the profile and progress data to load → scroll only enough to keep the profile identity, **Rank: Newcomer**, **Today's Challenges**, and the start of the **Badge Shelf** visible together.
- **Ready state:** The synthetic `playreview` profile is loaded. The rank, 1-day streak, challenge progress, and badge shelf are present; no unlock, rank-up, error, or loading dialog is open. The keyboard is hidden and the **Profile** item is settled in the custom bottom nav.
- **Why this shot:** It shows lightweight progression and activity without turning the listing into a competitive ranking claim.

## Optional eighth shot

Use this only if the ad-free purchase surface is not ready for the listing. It is not a substitute for any of the seven required feature shots.

### 8. Signed-out Welcome screen

- **File:** `08-welcome-dark.png`
- **Navigation from launch:** Launch SecretMsg after the other shots → tap **Profile** → scroll to **Account** → tap **Sign out** → confirm **Sign out** → wait for the signed-out Welcome screen.
- **Ready state:** The first Welcome card, **Your anonymous inbox**, is centered with the SecretMsg mark, page indicator, and the **Create my inbox — free** / **I already have one — log in** choices visible. No keyboard, system permission, account name, or personal data is visible.
- **Why this shot:** It gives the listing a clean first impression before sign-in while leaving the ad-free purchase copy out of the featured set.

## Content and policy-safety rules

- Use only the synthetic seeded content. Never capture real handles, names, avatars, messages, replies, or report text.
- Keep the account restricted to the seeded reviewer data: four synthetic inbox messages, one synthetic blind reply, `received_count=4`, `replies_count=1`, and rank **Newcomer**.
- Use a tame Dice category. Reroll if any result is unsuitable. The six real categories are **Crush & Flirt**, **Spicy**, **Deep Secrets**, **Chaotic & Wild**, **Real Talk**, and **3AM Thoughts**; do **not** use **Spicy** or **Crush & Flirt**.
- On the Send screen, do not open or feature the **Crush** or **Confessions** inspiration presets.
- Do not feature the report flow, a report dialog, report text, child-safety policy, or moderation/legal screens as marketing shots.
- Do not add device frames, finger or touch overlays, captions added after capture, or promotional **Best**, ranking, discount, or call-to-action badges.
- Do not add credentials, email addresses, backup codes, PINs, pairing codes, private reply links, or account identifiers to the image or its surrounding content.
- Do not feature the ad-supported purchase flow, the ad-free upsell, an ad consent form, the AdMob "why am I seeing this" form, an ad settings screen, or a child's-directed ad configuration screen as marketing shots. The ad model is described in the listing copy, not by a screenshot of a dialog.
- Do not add a banner, an ad creative, or an ad-shaped placeholder to a shot where the app did not render one. See [Ads in screenshots](#ads-in-screenshots).

## Post-capture validation

Run this pass on every PNG before upload:

- [ ] Dimensions are exactly 1080 × 1920, and the aspect ratio is exactly 9:16 portrait.
- [ ] The file is PNG, 8 bits per channel, RGB/24-bit colour, with no alpha and no embedded JPEG data.
- [ ] The complete status bar is visible and unclipped, with no private notification content.
- [ ] The complete custom bottom nav is visible and unclipped on shell tab screens; its selected bubble has finished moving.
- [ ] Pushed message-detail and Daily Drop screens have their complete system bars and do not contain an added or fabricated app bottom nav.
- [ ] The keyboard, input-method bar, cursor, tooltip, snackbar, spinner, sync row, error, and system share/permission sheet are absent.
- [ ] Every handle, name, avatar, message, reply, caption, link, and Dice result is approved synthetic content; the labeled moderation sample and any report text are absent.
- [ ] The image is not stretched, squeezed, blurred, recompressed, or sharpened; text and icon edges are clean.
- [ ] The layout has no clipping, overlap, broken safe-area inset, offscreen control, unexpected empty state, or unresolved loading state.
- [ ] The filename and upload order match the sequence below.

## Naming and handoff

Place only the final validated PNGs in:

`store/listing/phone/`

Use this order:

1. `01-secret-inbox-dark.png`
2. `02-double-blind-reply-dark.png`
3. `03-anonymous-composer-dark.png`
4. `04-daily-drop-dark.png`
5. `05-dice-result-dark.png`
6. `06-sticker-studio-dark.png`
7. `07-profile-progress-dark.png`
8. `08-welcome-dark.png` only if used

Reviewer credentials, backup codes, and D1 seed SQL must never be placed in `store/listing/phone/`.
