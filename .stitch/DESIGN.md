---
name: SecretMsg Clean White Minimalist
colors:
  surface: '#0B0E14'
  surface-dim: '#07090D'
  surface-bright: '#151B26'
  surface-container-lowest: '#05070A'
  surface-container-low: '#0E131C'
  surface-container: '#151B26'
  surface-container-high: '#1D2433'
  surface-container-highest: '#273142'
  on-surface: '#FFFFFF'
  on-surface-variant: '#94A3B8'
  inverse-surface: '#FFFFFF'
  inverse-on-surface: '#0B0E14'
  outline: 'rgba(255, 255, 255, 0.12)'
  outline-variant: 'rgba(255, 255, 255, 0.24)'
  primary: '#FFFFFF'
  on-primary: '#0B0E14'
  primary-container: '#F1F5F9'
  on-primary-container: '#0F172A'
  secondary: '#38BDF8'
  on-secondary: '#082F49'
  secondary-container: '#0284C7'
  on-secondary-container: '#E0F2FE'
  tertiary: '#F43F5E'
  on-tertiary: '#4C0519'
  tertiary-container: '#E11D48'
  on-tertiary-container: '#FFE4E6'
  error: '#EF4444'
  on-error: '#FFFFFF'
  background: '#0B0E14'
  on-background: '#FFFFFF'
typography:
  display-lg:
    fontFamily: Inter, -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter, -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-sm:
    fontFamily: Inter, -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-base:
    fontFamily: Inter, -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter, -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  caption:
    fontFamily: Inter, -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.375rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.25rem
  full: 9999px
spacing:
  unit: 4px
  container-padding: 16px
  gutter: 12px
  card-gap: 12px
  bottom-nav-height: 64px
  topbar-height: 56px
---

## 1. Brand & Aesthetic Vision
SecretMsg Mobile is a privacy-first viral anonymous messaging platform. 
The visual aesthetic is **Hyper-Clean Minimalist Mobile** with **Crisp White Accents**. Deep obsidian-titanium backdrop (`#0B0E14`) paired with crystal white high-contrast text and crisp white active elements (`#FFFFFF`), subtle translucent borders (`rgba(255, 255, 255, 0.12)`), smooth pill badges, and refined micro-radiance.

## 2. Colors & Contrast
- **Background**: `#0B0E14` (Deep obsidian dark)
- **Surfaces**: `#151B26` (Floating card container with 1px `rgba(255, 255, 255, 0.12)` hairline border)
- **High-contrast Primary**: `#FFFFFF` (Pure white accent buttons, badges, and headers)
- **Sub-text**: `#94A3B8` (Muted cool gray)
- **Vibe Highlights**: `#38BDF8` (Sky cyan for chill/friends), `#F43F5E` (Vibrant rose for crush/TBH), `#A855F7` (Electric violet for confessions)

## 3. Typography
- Modern sans-serif: `Inter`, system UI font stack (`-apple-system, BlinkMacSystemFont, 'Segoe UI'`)
- Crisp weights: 700 for bold stat titles, 600 for card headers, 400 for message text.

## 4. Layout & Mobile Dimensions
- Target screen width: 390px (Mobile portrait, iPhone 15/16 and modern Android form-factor).
- Header: Sticky 56px top bar with back navigation, logo mark, and contextual action.
- Content: Scrollable container with 16px horizontal padding and 12px gap between cards.
- Bottom Navigation: Fixed 64px bottom bar with icons and labels for Home, Explore/Dice, Create/Stickers, Inbox, and Profile.

## 5. UI Components
- **Search Bar**: Capsule pill input with search icon, clear button, and placeholder text "Search vibes, categories, friends..."
- **Category Chips**: Horizontal scrolling pill selector with active white fill state and inactive translucent border state.
- **Viral Template Card**: Rounded 16px card, subtle gradient ambient glow, prompt headline, category pill tag, and "Try Prompt" button.
- **Bottom Navigation Bar**: Persistent 5-tab bar with icons (Home, Dice, Stickers, Inbox, Profile).

## 6. Design System Notes for Stitch Generation
```
DESIGN SYSTEM (REQUIRED):
- Platform: Mobile viewport (390px width), clean minimalist mobile app layout.
- Theme: Clean minimalist dark titanium mode with high-contrast CRISP WHITE ACCENTS.
- Colors: Background #0B0E14, Card surface #151B26, Pure white #FFFFFF for primary accents & active pills, outline border rgba(255, 255, 255, 0.12), muted gray #94A3B8.
- Typography: Modern Inter typography, crisp legibility, tight headings, subtle letter spacing.
- Components: Rounded-2xl (16px) cards, pill-shaped tags (rounded-full), frosted glass search bar, persistent bottom navigation bar (Home, Dice, Stickers, Inbox, Profile) with white active indicator.
- Micro-details: Subtle hairlines, high touch-target buttons, clean white glowing highlights.
```
