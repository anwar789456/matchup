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

## Phase 4 — pro onboarding (phone)

The OWN/COA/ORG onboarding screens were drawn wide; the app is phone-only, so build them as phone forms with the same steps and copy. If you already built them as desktop pages, ask Claude Code to convert them in phase 13.

```
Phase 4. Build the "Onboarding pros" screens (OWN-01 to OWN-09, COA-01 to COA-03, ORG-01 to ORG-02) as PHONE forms (CLAUDE.md rule 9): same steps, fields and French copy as the PNGs, one column, sticky bottom actions, MuStepIndicator for the steps. Build MuFileUpload, MuPricingCard, MuKpiCard, MuEmptyState first from their specs. Same rules: exact copy, fake repositories, drafts saved locally.
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

## Milestones 4–5 — Payments and notifications (phases 9 to 11)

Do phases 5–8 first. Then update the designs exactly like last time:
1. Commit (`git add -A`, then `git commit -m "Phases 5-8"`).
2. Delete `matchup_app/design` and copy the new `matchup_handoff` folder in its place, renamed to `design`.
3. Move `matchup_app/design/CLAUDE.md` to `matchup_app/CLAUDE.md`, replacing the old one (new rules 10 and 11).
4. Restart `claude` in `matchup_app`, then paste the phases below one at a time.

No real money moves yet: payments stay fake until you have a backend. Read `design/payments/STRIPE-APPEARANCE.md` → "Before real payments go live" before you plan the backend.

### Phase 9 — checkout, payment states, split payment and wallet

```
Phase 9. Read the new CLAUDE.md, design/payments/STRIPE-APPEARANCE.md, the "Milestones 4–5" part of design/screens/SCREENS.md (tables Paiement and Portefeuille) and the "Milestones 4–5 additions" in design/screens/STORY-DATA.md. Then:
1. Widgets first from their specs: MuTransactionRow, MuLoadingOverlay, the secure-payment variant of MuTakeover, MuBanner (error), plus a CardInputZone widget (our cardholder field + a bounded box with card number, expiry, CVC, country drawn with our MuTextField; it will host flutter_stripe's CardFormField later).
2. A PaymentRepository interface with a fake implementation whose outcome is chosen in the debug menu: succès, 3-D Secure, refusée, erreur réseau, délai dépassé.
3. Build PAY-01 to PAY-10 as ONE checkout flow (the error screens are states of the checkout, not separate pages), PAY-11 and PAY-12 (split tracker with a live countdown), and WAL-01 to WAL-05 (wallet, top-up through the same checkout, refund request and status).
4. Wire it: BKG-04 « Payer ma part » → PAY-01; success → PAY-09 then MAT-05; MAT-05 « Paiements » → PAY-11; menu du compte « Portefeuille » → WAL-01. The wallet balance and history update after each fake payment, refund or top-up.
Match the PNGs and copy exactly, show the test ribbon only in debug builds. Analyze, test every outcome of the debug menu, list mismatches.
```

### Phase 10 — Premium plans and subscription

```
Phase 10. Build SUB-01 to SUB-08 from design/screens/SCREENS.md (table Portefeuille & abonnement), same rules. Widgets first: MuPricingCard, MuSegmentedControl (Mensuel / Annuel), an accordion for the FAQ, MuAiSuggestionCard for the retention offer. A fake SubscriptionRepository holds the plan state (Gratuit → Premium trial until ven. 30 oct. → cancelled but active until 30 oct.). The checkout SUB-02 reuses the Phase 9 checkout. Cancelling must stay as short as subscribing, and « Non merci, résilier » keeps the same size and weight as the offer. Generate the receipt SUB-09 as a real A4 PDF with the pdf + printing packages (open, share, save) from SUB-04 « PDF » and PAY-09 « Voir le reçu ». Wire menu du compte « MatchUp Premium » → SUB-01. Analyze, test subscribe / change to yearly / cancel / reactivate, list mismatches.
```

### Phase 11 — notifications

```
Phase 11. Build NOT-01, NOT-02, NOT-03, NOT-07 and NOT-10 from design/screens/SCREENS.md (table Notifications), same rules. Widgets first: MuNotificationItem (priorities, unread dot, grouped people, inline actions, countdown, swipe to « Lu » / « Supprimer »), MuToast + toast stack (max 3, 4 s, above the tab bar or the sticky bar), MuSnackbar. A fake NotificationRepository exposes a stream; the debug menu can push « Rami S. a rejoint la partie » while GAM-01 is open: the lineup updates and a toast appears (NOT-07). Every notification type of the catalog pages NOT-04/05/06 must exist as a model with its title, body, priority and action, even if its target screen comes later (then the action is hidden). NOT-10 saves preferences locally; payments and security cannot be turned off in-app. Show simulated push notifications with flutter_local_notifications from the debug menu, matching NOT-08 / NOT-09 texts and actions. Wire the bell on Home → NOT-01 and Paramètres › Notifications → NOT-10. Do NOT build the EML-* emails: they belong to the future backend. Analyze, test, list mismatches.
```

## The rest of the app — phases 12 to 18

The whole app is now designed. Update the designs once more exactly like before (commit, replace `design/`, move the new CLAUDE.md to the root — it has new rules 9 and 12–14 — restart `claude`).

**Order matters.** Phases 12–14 are needed to launch: polished states, the venue owners' app (venues are your supply) and the admin. Phases 15–18 are **optional for launch**: build them after real players use the app, one at a time, when you have a reason.

### Phase 12 — states, dark mode, Arabic (do this right after phase 11)

```
Phase 12. Read the new CLAUDE.md (rules 12–14), then the tables "États globaux" and "Sombre & arabe" in design/screens/SCREENS.md.
1. Move every visible string of lib/ui and lib/features into lib/l10n/app_fr.arb (no hardcoded French left), then add app_ar.arb with the Arabic of RTL-01, RTL-02, RTL-03 (other Arabic strings can stay French for now, mark them TODO).
2. Build the reusable states from STA-01 to STA-09 (offline banner with cached data, server error, not found, session expired, permission denied with steps, email not verified, suspended account, incomplete profile, pull-to-refresh, end of list, optimistic update with rollback) as widgets and wire them where they belong.
3. Dark mode: compare the app in dark with DRK-01 to DRK-04 and fix every difference (rule 13).
4. Arabic: switch the language in SET-04 and compare Home, the venue page and the checkout with RTL-01 to RTL-03. Fix mirroring and number isolation.
Analyze, run the app in light, dark and Arabic, list what still differs.
```

### Phase 13 — venue owner app

```
Phase 13. Build the owner space from the table "Espace propriétaire" (OWN-10 to OWN-25) and STA-05, as its own shell with the owner tab bar (rule 14). Also rebuild the existing owner onboarding OWN-01…OWN-09 as phone forms (rule 9). Widgets first from their specs: MuKpiCard, the planning grid (courts as columns, hours as rows, states free / booked / public / pending payment / blocked / no-show / mine), MuLineChart, MuTransactionRow reuse, MuStarRating reuse. The QR scanner uses mobile_scanner (ask before adding it) with the manual code fallback; results OWN-21/22/23 come from a fake CheckInRepository (MU-48213 valid, MU-48190 already used, anything else invalid). The AI insight card only proposes; « Appliquer » opens OWN-16 with the promo prefilled, nothing changes without saving. PRF-06 « Propriétaire de terrain » opens this space. Analyze, test check-in, blocking a slot and a no-show, list mismatches.
```

### Phase 14 — admin

```
Phase 14. Build the admin space from the table "Admin" (ADM-01 to ADM-10) with the admin tab bar. Lists replace tables: search, filter chips, sort sheet, a bulk-select mode with a sticky action bar. Destructive actions (suspend, ban, delete) always confirm and state the consequence (ADM-04, ADM-10). AI scores (toxicity, churn) only sort and suggest; nothing is sent or deleted without the admin. Fake AdminRepository with the story data. Analyze, test suspend → STA-07 on Omar D.'s account, list mismatches.
```

### Phase 15 (optional) — tournaments and organiser

```
Phase 15. Build the player tournament screens TRN-01 to TRN-11 (Explorer › Tournois) and the organiser space ORG-03 to ORG-14 (rebuild ORG-01/02 as phone forms). Widgets first: MuTournamentCard, MuEventCard, MuTeamCard, MuMatchCard, MuBracket (phone pattern: one round per column + overview), MuScoreboard, MuWizardStepper. Entry fee goes through the existing checkout (120 DT) then TRN-06. The AI schedule generator (ORG-11) is a fake that returns the planning shown; publishing needs confirmation. Courtside scoring (ORG-13) updates TRN-10 live through a fake stream. Analyze, test register a team → validate it as organiser → live score, list mismatches.
```

### Phase 16 (optional) — training and coach

```
Phase 16. Build ENT-01 to ENT-09 (the Entraînement tab) and the coach space COA-04 to COA-12 (rebuild COA-01…03 as phone forms). Widgets first: MuProgramCard, MuLessonCard, MuCoachCard, MuProgressRing, the lesson player (video_player, ask before adding it), MuFileUpload with progress. « Inclus dans Premium » follows the subscription state from phase 10. The AI plan (ENT-07) and video analysis (ENT-09) are fakes returning the designed results, always editable and never applied without « Accepter ». Analyze, test enrolment, a lesson, the AI plan, list mismatches.
```

### Phase 17 (optional) — community forum

```
Phase 17. Build FRM-01 to FRM-05 (the Communauté tab): feed with categories, sport filter and sort, new post with similar discussions and AI tag suggestions, the pre-publish nudge (FRM-03, a fake toxicity check on a few words), thread with 2 levels and best answer, report sheet, masked-content placeholder. Moderation decisions come from the admin screens of phase 14. Analyze, test, list mismatches.
```

### Phase 18 (optional) — AI assistant

```
Phase 18. Build AI-01 to AI-07: the assistant opened from the AI button of every tab bar (AI-07 in pro spaces). Use an AssistantRepository interface with a fake that returns the designed conversations (results, thinking, no result, error). The assistant never books or pays by itself: every action goes through the confirmation step AI-03 and then the normal checkout. Show « L'IA peut se tromper » and thumbs on every answer. A real LLM backend plugs in later behind the same interface. Analyze, test each state, list mismatches.
```

## Later

The design is complete. When you add a backend, keep the repository interfaces: each fake is replaced by a real implementation without touching the screens. If you change a screen's design later, update its PNG and source in `design/screens/` first, then ask Claude Code to match it.

## Tips

- If Claude Code invents a colour or a size, say: "Use the theme tokens only, see CLAUDE.md rule 1."
- If a screen doesn't match, attach or name the PNG and say what differs.
- Commit after every phase (`git init` once, then ask Claude Code to commit).
