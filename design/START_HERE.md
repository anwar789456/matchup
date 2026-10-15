# How to hand MatchUp to Claude Code

Build the app in phases, one prompt at a time, checking the result on your phone or emulator between phases. Do not ask for "the whole app" in one prompt: it produces a large, untested pile of code.

## Setup (once)

1. In a terminal, create the project: `flutter create --org tn.matchup --platforms android,ios,web matchup_app`
2. Unzip this package and copy the whole `matchup_handoff` folder into `matchup_app/`, renamed to `design`. You should have `matchup_app/design/CLAUDE.md`, `matchup_app/design/screens/…`.
3. Move `matchup_app/design/CLAUDE.md` up one level to `matchup_app/CLAUDE.md` (the project root). Claude Code reads it automatically every session.
4. In the terminal: `cd matchup_app` then `claude` to start Claude Code in that folder.
5. Paste the prompts below one at a time. After each, run the app (`flutter run`) and look at it next to the PNGs in `design/screens/png/`.

## Phase 0 — read and plan (no code)

```
Read CLAUDE.md, then everything in design/: the brief (design/brief), the design system (design/design-system/README.md and the s01–s10 sections), design/screens/SCREENS.md and a few PNGs. The design files are in design/, not at the root. Then give me a short plan for phase 1 and phase 2 below: packages, folders, the list of Mu* widgets needed by the Milestone 2 screens, and the routes. Don't write code yet.
```

## Phase 1 — foundation

```
Phase 1. Follow design/flutter_theme/README.md steps 1–7 to install the theme: copy design/flutter_theme/lib/theme to lib/theme, add the packages, copy the sport icons, logos and illustrations from design/design-system/assets into assets/, set MuTheme.light()/dark() in MaterialApp.router with go_router and Riverpod, French locale. Then build the design-system widgets the onboarding screens need, in lib/ui/, each following its spec in design/design-system/components/<Comp>.md (the ## Flutter section): MuButton (all variants and sizes), MuIconButton, MuTextField, MuPasswordField (strength + rules), MuPhoneField (+216), MuOtpInput, MuCheckbox, MuChoiceCard (+ group), MuChip, MuStepIndicator, MuProgressBar, MuAiLabel, MuBanner, MuAvatar, MuLogo (SVG assets). Add a debug-only "widget gallery" screen showing every widget in light and dark. Run flutter analyze until clean, and tell me how to open the gallery.
```

## Phase 2 — welcome and auth screens

```
Phase 2. Build the screens of the "Bienvenue & connexion" table in design/screens/SCREENS.md (ONB-01 to ONB-04, AUTH-01 to AUTH-11, including the error variants as states of the same screens), using only lib/ui widgets and theme tokens. Match each PNG in design/screens/png and take the exact French copy from design/screens/source/<CODE>.dc.html. Wire navigation exactly as the "Goes to" column says; AUTH-11 routes to the onboarding of the first selected role. Use a fake AuthRepository (any code 123456 works; "yassine.b@email.tn" is "already used" so I can see the error state). Run analyze and test each flow, then list anything that doesn't match the designs.
```

## Phase 3 — player onboarding

```
Phase 3. Build the "Onboarding joueur" screens PLY-01 to PLY-11 from design/screens/SCREENS.md, same rules. The AI questionnaire (PLY-02) is one screen with 6 questions; the level result (PLY-03) comes from a fake LevelEstimator that computes a 1.0–7.0 level from the answers. Save onboarding progress locally (shared_preferences) so the user resumes where they left. PLY-11 is Home with the 3-step tour overlay; build only what the PNG shows (the GameCard, TabBar and AI FAB from their specs). Location and notification steps call the real permission APIs (permission_handler) after the priming screen; on refusal show PLY-08.
```

## Phase 4 — pro onboarding (desktop)

```
Phase 4. Build the "Onboarding pros" screens (OWN-01 to OWN-09, COA-01 to COA-03, ORG-01 to ORG-02) as responsive desktop layouts (they run on Flutter web and tablets). Build MuWizardStepper, MuSidebar, MuTopBar, MuFileUpload, MuPricingCard, MuKpiCard, MuEmptyState first from their specs. Same rules: match the PNGs, exact copy, fake repositories, drafts saved locally.
```

## Later milestones

Each time a new milestone of designs is ready (Player core, Payments, Notifications…), add its screens to `design/` and repeat the same pattern: widgets first, then screens, one module per prompt.

## Tips

- If Claude Code invents a colour or a size, say: "Use the theme tokens only, see CLAUDE.md rule 1."
- If a screen doesn't match, attach or name the PNG and say what differs.
- Commit after every phase (`git init` once, then ask Claude Code to commit).
