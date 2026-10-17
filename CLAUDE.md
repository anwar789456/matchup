# MatchUp — instructions for Claude Code

MatchUp is a Flutter app for amateur sports in Tunisia (5-a-side football, padel, basketball). Players find games at their level, book courts and pay their share; venue owners, coaches, organisers and admins have their own spaces in the same phone app (role switcher). French UI with informal « tu »; Arabic (RTL) and English later.

This folder is the design handoff. Treat it as the source of truth for how the app looks and behaves.

## What is in `design/`

| Path | What it is | When to read it |
|---|---|---|
| `design/brief/MatchUp-brief.md` | The full product brief (all roles, modules, screens, rules) | Before any feature |
| `design/design-system/README.md` + `s01…s10-*.md` | Brand rules, colour, type, layout, icons, motion, accessibility, RTL, overlays, copy, Flutter | Before writing UI |
| `design/design-system/components/<Comp>.md` | Spec of each of the 95 components, each ending with a `## Flutter` section naming the widget to build (`MuButton`, `MuTextField`, …) | Before building that widget |
| `design/design-system/tokens.json` | Every colour, size, radius, duration — the single source of values | Never edit by hand |
| `design/design-system/assets/` | Logos, the 6 sport icons, empty-state illustrations (SVG) | Copy into `assets/` |
| `design/flutter_theme/` | Ready Dart theme generated from tokens.json (`MuTheme`, `MuColors`, `MuType`, `MuSpace`, `MuRadius`, `MuMotion`…) + its README | Install first (step 1 of the plan) |
| `design/screens/SCREENS.md` | Index of every designed screen (the whole app, 229 screens) + 5 diagrams: code, purpose, entry, where each button goes | To know what to build and the navigation |
| `design/payments/STRIPE-APPEARANCE.md` | Stripe appearance values mapped to our tokens (web + flutter_stripe) and what to check before real payments | Before the checkout |
| `design/screens/STORY-DATA.md` | The fake data shared by all screens (people, venues, games, prices, dates, "now" = ven. 16 oct. 2026 18h00) | When writing fake repositories |
| `design/screens/png/<CODE>.png` | Pixel reference of each screen. A PNG taller than 844 px is the whole scrolled page (top bar at top, sticky bar / tab bar at the bottom of the screen, the rest scrolls) | Match it |
| `design/screens/source/<CODE>.dc.html` | Design source of each screen: exact French copy, layout, and which component is used (`<x-import component-from-global-scope="MatchUp.X">` = component X) | For exact text and structure |

## Rules (non-negotiable)

1. **Never hardcode a colour, size, font or duration.** Use `context.mu.<token>`, `MuSpace`, `MuRadius`, `MuType`, `MuSize`, `MuMotion` from `lib/theme/theme.dart`. If something is missing, stop and say so.
2. **Build reusable widgets from the component specs** in `lib/ui/` (`MuButton`, `MuTextField`, `MuChip`, `MuStepIndicator`, …) before screens, and use them everywhere. One widget per spec, named as in its `## Flutter` section.
3. **Match the PNGs.** Same layout, spacing, copy (French, character for character from the `.dc.html`), states.
4. Volt (`accent`) is a fill for selected states only, always with `onAccent` text on it. Sport colours only categorise and always come with the sport icon. Status = colour + icon + label.
5. Accessibility: touch targets ≥ 44 px, `Semantics` labels on icon-only buttons, visible labels on inputs, text never only colour. Respect `MediaQuery.disableAnimations`.
6. RTL-ready from day one: `EdgeInsetsDirectional`, `AlignmentDirectional`; never mirror numbers, scores, prices, maps.
7. No backend yet: data comes from repository interfaces with fake implementations (realistic Tunisian data from the screens). Swap for a real API later without touching UI.
8. Work in small steps, run `flutter analyze` and the app after each step, and commit. Every screen of the app is now designed. Build only the phase you are asked to build; a tab or button whose phase isn't built yet shows the « Bientôt disponible » placeholder.
9. **Phone only** (portrait, 390-wide designs; scale fluidly from 360 to 430), for every role: player, venue owner, coach, organiser and admin. Never build desktop or web layouts. The only exception is the existing pro onboarding screens OWN-01…09, COA-01…03, ORG-01…02, which were drawn wide: build them as phone forms with the same content and steps.
10. Payment: every « Payer… » button opens our checkout (PAY-01). Until a backend exists, payments go through a fake `PaymentRepository` whose outcome (success, 3-D Secure, declined, network error) is chosen in the debug menu. The card fields sit in a `CardInputZone` widget that will later host `flutter_stripe`'s `CardFormField` (styles in `design/payments/STRIPE-APPEARANCE.md`). Never imitate Stripe's hosted checkout.
11. Emails (`EML-*`) are server templates, built later with the backend — never in Flutter. Push notifications are simulated with local notifications until the backend exists.
12. **No hardcoded strings in widgets.** Every visible text, including labels inside Mu* widgets (« Places », « par joueur », « Rejoindre », « (facultatif) »…), comes from the l10n files (`lib/l10n/app_fr.arb`, then `app_ar.arb`, `app_en.arb`). Format dates, prices and decimals with `intl` per locale. In Arabic: prices « 15 د.ت », 24 h times, Western digits; wrap ranges, codes and card numbers in LTR isolation (`Directionality(textDirection: TextDirection.ltr)` or `\u2066…\u2069`). See RTL-01…03.
13. **Dark mode « Night match »**: follow DRK-01…04. Emphasis cards that are dark in light mode (balance, stats, next arrival) stay dark (`night700` + 1 px `border`) in dark mode, never white blocks; the booking QR button is Volt; pitches are night-lit (see `components/Lineup.md`); elevation becomes lighter surfaces, not shadows.
14. **Roles**: one account can hold several roles. Each role has its own `StatefulShellRoute` with its own tab bar (see the TabBar items in the screens: player 5 tabs, owner Aujourd’hui · Planning · Check-in · Réservations · Plus, coach Tableau · Programmes · Élèves · Revenus, organiser Tableau · Tournois · Scores · Annonces, admin Vue · Utilisateurs · Vérifications · Modération · Finance). PRF-06 switches role.

## Architecture

- Flutter stable (3.27+), Dart 3.
- Packages: `google_fonts`, `phosphor_flutter`, `flutter_svg`, `go_router` (navigation, one route per screen code; `StatefulShellRoute` for the 5 tabs), `flutter_riverpod` (state), `flutter_localizations` + `intl` (fr default, ar, en later), `shared_preferences`. Added in Milestone 3: `flutter_map` + `latlong2` (Explorer map, muted tiles, no API key), `qr_flutter` (booking QR), `url_launcher` (Itinéraire), `share_plus` (share links). Added in Milestones 4–5: `pdf` + `printing` (receipt PDF), `flutter_local_notifications` (simulated push). `flutter_stripe` only when the backend exists. Ask before adding any other package.
- Folders:
  ```
  lib/
    main.dart, app.dart            MaterialApp.router, MuTheme.light()/dark(), locale
    theme/                          the generated theme (copied from design/flutter_theme/lib/theme) — do not edit
    ui/                             Mu* design-system widgets (button, text_field, chip, step_indicator, …)
    router.dart                     go_router routes named by screen code (/onb/splash, /auth/signup, …)
    features/
      onboarding/ auth/ player_onboarding/ owner_onboarding/ coach_onboarding/ organizer_onboarding/ home/
      explore/ venue/ booking/ games/ matches/ profile/ settings/      (Milestone 3)
      payments/ wallet/ subscription/ notifications/                (Milestones 4–5)
      states/ owner/ admin/ tournaments/ organizer/ training/ coach/ forum/ assistant/   (Milestones 6–9)
        each: screens/, widgets/, controllers/ (Riverpod), data/ (repository + fake)
  assets/icons/sport/, assets/logo/, assets/illustrations/
  ```
- All screens are phone layouts. Tablets simply get the phone layout centered with a max width of 480.
