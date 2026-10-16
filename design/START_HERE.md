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

## Milestone 3 — Player core (phases 5 to 8)

### Update your project with the new designs (once)

1. Commit what you have: in the terminal, inside `matchup_app`, run `git add -A` then `git commit -m "Phases 0-4"` (skip if you don't use git yet).
2. Delete the old `matchup_app/design` folder.
3. Unzip this new package and copy the `matchup_handoff` folder into `matchup_app/`, renamed to `design` (same as the first time).
4. Move `matchup_app/design/CLAUDE.md` up to `matchup_app/CLAUDE.md`, replacing the old one (it has new rules 8–10 and new packages).
5. Start Claude Code again in `matchup_app` (`claude`) so it reads the new CLAUDE.md, then paste the phases below one at a time.

Phase 5 replaces the « Bientôt disponible » placeholders on Accueil, Explorer and Mes matchs. Entraînement and Communauté keep the placeholder until Milestone 6: that is expected.

### Phase 5 — app shell, Home and Explorer

```
Phase 5. Read the new CLAUDE.md, design/screens/STORY-DATA.md and the "Milestone 3" part of design/screens/SCREENS.md (tables Accueil & Explorer). Then:
1. Replace the current tab placeholders with a go_router StatefulShellRoute for the 5 tabs (MuTabBar from its spec, with the AI Fab; Entraînement and Communauté keep the « Bientôt disponible » screen). After onboarding, PLY-11 (tour) shows once, then Home is HOM-01.
2. Put the story data in fake repositories (games, venues, bookings, me) with an injectable clock set to ven. 16 oct. 2026 18h00.
3. Build these widgets from design/design-system/components/<Comp>.md (## Flutter section) first: MuGameCard, MuVenueCard, MuBookingCard, MuTournamentCard, MuSegmentedControl, MuSearchField, MuSkeleton, MuEmptyState, MuBottomSheet, MuRangeSlider, MuMapView (flutter_map), MuTopAppBar (home variant), MuMatchFitScore, MuAiLabel. Add them to the widget gallery.
4. Build HOM-01, HOM-02 (loading state of Home), EXP-01 to EXP-07 matching each PNG and the exact copy in design/screens/source/<CODE>.dc.html. EXP-04 is a bottom sheet, EXP-06 and EXP-07 are states of Explorer (no results, offline), not separate routes.
Links to screens of later phases (GAM-, VEN-, MAT-05, PRF-05) can open a temporary placeholder for now. Run flutter analyze until clean, then tell me what doesn't match the PNGs.
```

### Phase 6 — venue and booking flow

```
Phase 6. Build the "Terrains & réservation" screens VEN-01, VEN-02, BKG-01 to BKG-05 from design/screens/SCREENS.md, same rules. Widgets first from their specs: MuSlotGrid, the strip variant of MuCalendar (DatePicker spec), MuStepper, MuLevelSlider, MuRadio (reuse MuChoiceCard and MuCheckbox from phase 1), MuStatusBadge, MuTakeover ticket (QR with qr_flutter), MuStarRating. Keep the booking draft in one Riverpod controller across the flow (slot → type → public settings or invites → summary). The per-person price always updates with the number of players. « Payer ma part » goes through the fake PaymentRepository (CLAUDE.md rule 10) to BKG-05, and the new booking appears in Mes matchs and on Home. Wire Home's "Réserver un terrain" and "Créer une partie" to EXP-03. Analyze, test the whole flow private and public, list mismatches.
```

### Phase 7 — open games and Mes matchs

```
Phase 7. Build the "Parties ouvertes" screens GAM-01 to GAM-05 and the "Mes matchs" screens MAT-01 to MAT-09, same rules. Widgets first from their specs: MuLineup (5v5 pitch with dashed « + » slots), MuCountdown, MuReliabilityBadge, MuAvatarStack, MuTabs, MuDialog (destructive), MuMatchCard, MuScoreboard, MuStarRating. Behaviour: joining G1 (Rejoindre et payer) uses the fake payment then GAM-05 and adds it to Mes matchs; a full game offers the waitlist (GAM-03); add a debug-menu button "Simuler une place libérée" that opens the GAM-04 takeover with a real 15:00 countdown. Cancelling MU-48213 (MAT-06) moves it to Annulés with the refund; leaving G1 (MAT-07) shows the snackbar « Partie quittée · Annuler ». MAT-04 is the empty state of À venir. Analyze, test each flow, list mismatches.
```

### Phase 8 — profile, account menu and settings

```
Phase 8. Build the "Profil & paramètres" screens PRF-01 to PRF-06 and SET-01 to SET-07, same rules. Widgets first from their specs: MuSparkline, MuLevelIndicator, MuRoleSwitcher, MuSwitch, MuSelect, MuTagInput, MuFileUpload (photo/cover picker), MuSocialButton, plus one MuSettingsRow (icon, title, description, value, chevron, destructive variant) reused by every SET screen. PRF-03 and PRF-05/PRF-06 are bottom sheets. Language (SET-04) switches the app locale (French now; Arabic turns the layout RTL even if texts stay French for now) and theme (clair / sombre / système) applies immediately; both are saved with shared_preferences. Delete account (SET-07) enables its button only when « SUPPRIMER » is typed and signs out to ONB-01. « Propriétaire de terrain » in the role switcher opens the existing OWN-09 dashboard. Analyze, test light and dark, list mismatches.
```

## Later milestones

Each time a new milestone of designs is ready (Payments, Notifications…), you get a new package: replace `design/`, move the new CLAUDE.md to the root, and paste the new phases. Widgets first, then screens, one module per prompt.

## Tips

- If Claude Code invents a colour or a size, say: "Use the theme tokens only, see CLAUDE.md rule 1."
- If a screen doesn't match, attach or name the PNG and say what differs.
- Commit after every phase (`git init` once, then ask Claude Code to commit).
