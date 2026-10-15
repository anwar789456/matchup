# MatchUp — instructions for Claude Code

MatchUp is a Flutter app for amateur sports in Tunisia (5-a-side football, padel, basketball). Players find games at their level, book courts and pay their share; venue owners, coaches, organisers and admins use desktop dashboards. French UI with informal « tu »; Arabic (RTL) and English later.

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
| `design/screens/SCREENS.md` | Index of the 43 designed screens + 5 diagrams: code, purpose, entry, where each button goes | To know what to build and the navigation |
| `design/screens/png/<CODE>.png` | Pixel reference of each screen | Match it |
| `design/screens/source/<CODE>.dc.html` | Design source of each screen: exact French copy, layout, and which component is used (`<x-import component-from-global-scope="MatchUp.X">` = component X) | For exact text and structure |

## Rules (non-negotiable)

1. **Never hardcode a colour, size, font or duration.** Use `context.mu.<token>`, `MuSpace`, `MuRadius`, `MuType`, `MuSize`, `MuMotion` from `lib/theme/theme.dart`. If something is missing, stop and say so.
2. **Build reusable widgets from the component specs** in `lib/ui/` (`MuButton`, `MuTextField`, `MuChip`, `MuStepIndicator`, …) before screens, and use them everywhere. One widget per spec, named as in its `## Flutter` section.
3. **Match the PNGs.** Same layout, spacing, copy (French, character for character from the `.dc.html`), states.
4. Volt (`accent`) is a fill for selected states only, always with `onAccent` text on it. Sport colours only categorise and always come with the sport icon. Status = colour + icon + label.
5. Accessibility: touch targets ≥ 44 px, `Semantics` labels on icon-only buttons, visible labels on inputs, text never only colour. Respect `MediaQuery.disableAnimations`.
6. RTL-ready from day one: `EdgeInsetsDirectional`, `AlignmentDirectional`; never mirror numbers, scores, prices, maps.
7. No backend yet: data comes from repository interfaces with fake implementations (realistic Tunisian data from the screens). Swap for a real API later without touching UI.
8. Work in small steps, run `flutter analyze` and the app after each step, and commit. Don't build screens that aren't designed yet — later milestones will add them.

## Architecture

- Flutter stable (3.27+), Dart 3.
- Packages: `google_fonts`, `phosphor_flutter`, `flutter_svg`, `go_router` (navigation, one route per screen code), `flutter_riverpod` (state), `flutter_localizations` + `intl` (fr default, ar, en later).
- Folders:
  ```
  lib/
    main.dart, app.dart            MaterialApp.router, MuTheme.light()/dark(), locale
    theme/                          the generated theme (copied from design/flutter_theme/lib/theme) — do not edit
    ui/                             Mu* design-system widgets (button, text_field, chip, step_indicator, …)
    router.dart                     go_router routes named by screen code (/onb/splash, /auth/signup, …)
    features/
      onboarding/ auth/ player_onboarding/ owner_onboarding/ coach_onboarding/ organizer_onboarding/ home/
        each: screens/, widgets/, controllers/ (Riverpod), data/ (repository + fake)
  assets/icons/sport/, assets/logo/, assets/illustrations/
  ```
- Owner / coach / organizer screens are desktop layouts (1440×900) that must also work on tablets; use `LayoutBuilder` with the breakpoints from `s03-layout.md` (600 / 840 / 1200).
