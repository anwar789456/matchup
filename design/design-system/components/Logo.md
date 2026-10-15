# Logo

The MatchUp wordmark — a geometric logotype whose « a » is a ball — and the app icon cut from that same ball and stem.

## When to use
- **Wordmark** in the desktop top bar and sidebar header, onboarding, sign-in, the splash screen and emails.
- **App icon** (`variant="icon"`) for the stores, the home screen, the favicon, and any square slot or space under 18 px high.
- Not as decoration in cards or lists, and never as a loading indicator (use Skeleton).

## Anatomy & specs
| Part | Spec |
|---|---|
| Wordmark | 587 × 126 units on a 100-unit cap height (4.66:1). `height` sets the size (default 28); the width follows |
| Ball | the bowl of the « a »: a disc 58 % of the wordmark height, crossed by one S-shaped seam 20 % of its radius thick |
| Clear space | the ball's diameter on every side — about 0.6 × the height, so 16 around a 28 px wordmark |
| Minimum size | wordmark 18 px high (the seam is 1 px there); below that, use the app icon |
| App icon | `ink-900` square tile, corners 22.37 % of the side; `volt-400` ball 49 % of the tile with an `ink-900` seam; `white` stem. Previewed at 96 (stores), 60 (home screen) and 32 (favicon, the smallest) |

## Variants
| Tone | Letters | Ball | Seam | Use on |
|---|---|---|---|---|
| `auto` (default) | `logo-ink` | `logo-ball` | `logo-seam` | the app's own `bg` and `surface`: ink in Light; white with a Volt ball in Night match |
| `light` | `ink-900` | `ink-900` | `volt-400` | fixed light grounds: white pages, emails, print |
| `dark` | `white` | `volt-400` | `ink-900` | fixed dark grounds: the sidebar (`nav-bg`), the splash, `ink-900` panels |
| `mono-ink` | `ink-900` | `ink-900` | knocked out | one-colour print and embossing on light grounds |
| `mono-white` | `white` | `white` | knocked out | photography, CourtArt and sport-colour grounds |

The app icon ignores `light` / `dark`; `mono-ink` and `mono-white` drop the tile and draw stem and ball in one colour.
Exports from `tools/logo.py`: `matchup-logo-light|dark|mono-ink|mono-white.svg`; `matchup-app-icon.svg` (iOS and stores, full bleed — the platform applies its own mask); `matchup-app-icon-rounded.svg` (web, marketing); `matchup-app-icon-foreground.svg` (Android adaptive foreground at 72 %, inside the safe circle, over an `ink-900` background layer); `matchup-app-icon-monochrome.svg` (Android 13+ themed icon: no tile, one ink, seam knocked out).

## States
Static: no hover, press or animation. When it links home (top bar, sidebar), the link carries `focus-ring`; the logo itself never changes colour.

## Content
- In running text write « MatchUp » — one word, capital M and U — never « Matchup », « MATCHUP » or « Match Up ».
- The tagline « Joue. Réserve. Progresse. » is live text (`display` or `h1`) set beside or under the wordmark, never drawn into it.

## Accessibility
- The SVG is `role="img"` named by `title` (default « MatchUp »). As the home link, that name is the link's name — don't add « logo ».
- Contrast: ink on white and white on `ink-900` 17.2:1; the Volt ball on `ink-900` 13.2:1. The Volt seam of the `light` tone is decorative.
- Set `mono-white` on the dark part of an image or over `photo-scrim`.

## Do / Don't
- Do let `auto` follow the theme; force `dark` in the sidebar, which stays `nav-bg` in both themes.
- Do keep the clear space free of text, icons and container edges.
- Don't recolour the ball in a sport colour, and don't rotate, outline, stretch or shadow the mark.
- Don't put the coloured wordmark on photos or sport colours — use `mono-white`.
- Don't type « MatchUp » in Plus Jakarta Sans as a stand-in for the wordmark.

## Props (web preview)
`variant` · `tone` · `height` · `title`. See `index.d.ts`.

## Flutter
`MuLogo(variant: MuLogoVariant.wordmark, tone: MuLogoTone.auto, height: 28, semanticLabel: 'MatchUp')` — ship the `tools/logo.py` exports as SVG assets and render them with `SvgPicture.asset` (flutter_svg) at `height`; `auto` picks `matchup-logo-light.svg` or `matchup-logo-dark.svg` from `Theme.of(context).brightness`. Generate launcher icons from 1024 px renders of the icon SVGs with `flutter_launcher_icons`: `image_path` the full icon, `adaptive_icon_background: '#0B1B33'`, `adaptive_icon_foreground` the foreground, `adaptive_icon_monochrome` the monochrome.
