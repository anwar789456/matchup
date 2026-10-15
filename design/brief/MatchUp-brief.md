# MatchUp — Complete UI/UX Design Brief

## 0. Your role and how to work
You are a senior product designer (UI/UX). Design the complete experience of MatchUp: the design system, every screen for every user role, the overlay system, the notification system, the Stripe checkout, the dashboards and the email templates.

- This is a large project. Work milestone by milestone in the order of section 15. Deliver one milestone, summarize what you made in a few lines, then stop and wait for me to reply "next".
- Every milestone reuses the design system from Milestone 1. No one-off colors, sizes or components.
- Quality bar: production-ready and portfolio-quality — consistent spacing, real content, every important state designed.
- Everything must be original: do not copy the look of existing sports or booking apps.

## 1. Product context
MatchUp is a platform for amateur sports in Tunisia: 5-a-side football, padel and basketball. Today, players organize games in messy WhatsApp groups, venues take bookings by phone, and tournaments run on spreadsheets. MatchUp lets players find teammates and open games at their level, book courts, pay their share, join tournaments, follow training programs and talk with the community.

Tagline: « Joue. Réserve. Progresse. »

### User roles (one account can hold several roles → role switcher)
- Joueur / Player (main user, mobile): finds and joins games, books courts, pays, joins tournaments, trains, posts in the forum.
- Propriétaire de terrain / Venue owner (desktop, plus mobile at the venue): manages courts, slots, prices, bookings, check-ins and revenue.
- Coach (desktop): publishes training programs, follows students, earns money.
- Organisateur / Organizer (desktop): creates tournaments and events, manages teams, brackets and live scores.
- Admin (desktop): manages users, verifications, payments, moderation and platform stats.

### The 6 independent modules
1. Users — accounts, roles, profiles, AI level estimation, reliability score.
2. Venues & Bookings — courts, slots, reservations, open games (public bookings with missing spots), check-in.
3. Tournaments & Events — tournaments, social events, teams, registrations, brackets, live scores, leaderboards.
4. Coaching & Training — programs, lessons, enrollments, progress, AI training plans.
5. Payments & Subscriptions — Stripe checkout, split payments, wallet, plans, invoices, refunds.
6. Forum — posts, comments, reactions, reports, AI moderation.
Cross-cutting: notifications (in-app, push, email) and an AI assistant.

### Platforms and locale
- Player app: mobile-first (390×844) with responsive desktop versions of key screens.
- Dashboards (owner, coach, organizer, admin): desktop-first (1440×900). The venue owner also needs a few mobile screens for use at the venue.
- UI copy: French by default (informal « tu »). Arabic with full RTL and English available through a language switcher.
- Currency: Tunisian dinar, written « 60 DT », « 12,500 DT » (3 decimals, comma separator), « 1 250 DT ».
- Phone: +216 followed by 8 digits. Dates and times: « sam. 18 oct. · 20h00 ».

## 2. UX principles
1. Join a game in 3 taps: Home → game card → « Rejoindre et payer ».
2. Time, place, price per person and spots left are visible on every game and booking card.
3. Show the price per person, not only the court price.
4. Main actions sit in the thumb zone on mobile (sticky bottom action bar).
5. Trust everywhere: verified venue badge, player reliability score, cancellation and refund rules shown before paying.
6. Progressive disclosure: simple first, details in bottom sheets and drawers.
7. Transparent AI: every AI output is labeled « IA », explains why (« Recommandé car… »), can be edited or dismissed, and never books, pays or publishes without explicit confirmation.
8. No dark patterns: cancelling is as easy as subscribing; opt-outs are as visible as opt-ins.
9. Every screen has its full set of states: loading, empty, error, success, disabled.
10. Accessibility is part of the design (see 3.9).

## 3. Visual design system
### 3.1 Personality
Energetic, sporty and social, but clean and trustworthy because money is involved. A modern scoreboard meets a premium booking app: generous white space, bold numerals, sport-coded accents, rounded cards, photos of real amateur games under evening lights.

### 3.2 Logo
An original bold geometric wordmark « MatchUp », where a ball-like dot can replace part of a letter. Provide an app icon (rounded square) and a monochrome version.

### 3.3 Color tokens (named tokens, light and dark)
- Ink (neutrals): ink-900 #0B1B33 (main text, primary buttons), ink-700 #24324A, ink-500 #5B6B82 (secondary text), ink-300 #A9B4C4 (strong borders), ink-100 #E6EBF2 (borders, dividers), ink-50 #F5F7FA (app background), white surfaces.
- Brand accent: volt-400 #C6F135 for selected states, active tab indicator, highlights and primary buttons on dark surfaces. Never use Volt as text or icon color on white; text on Volt is always ink-900.
- Sport colors (categorization only: chips, map pins, card accents, illustrations): Football #1F9D55, Padel #2F80ED, Basketball #F2711C.
- Semantic: success #16A34A, warning #F59E0B, error #E5484D, info #3B82F6. Status is never shown by color alone: color + icon + label.
- AI: ai-500 #7C5CFC and a violet→blue gradient (#7C5CFC → #3B82F6), used only for AI features and AI-generated content.
- Live: pulsing error-red dot + « EN DIRECT ».
- Dark theme « Night match »: background #070F1F, surface #0F1B2E, elevated #16243A, text #F5F7FA; primary buttons become Volt with ink-900 text.

### 3.4 Typography (Google Fonts)
- UI: Plus Jakarta Sans. Scores, stats, prices and countdowns: Barlow Condensed with tabular numbers. Arabic: IBM Plex Sans Arabic.
- Scale (size/line height): Display 40/48 bold · H1 32/40 bold · H2 24/32 semibold · H3 20/28 semibold · Body L 16/24 · Body 14/20 · Caption 12/16 · Overline 11/16 uppercase, 0.08em tracking · Score 48/48 Barlow Condensed semibold.

### 3.5 Layout
- 4px base unit; spacing scale 4, 8, 12, 16, 20, 24, 32, 40, 48, 64.
- Mobile: 4-column grid, 16px side margins. Desktop: 12-column grid; dashboards use a 248px sidebar (collapsible to 72px) and fluid content.
- Radius: 8 (inputs, small buttons), 12 (cards, buttons), 16 (sheets, modals), full (chips, avatars, pills).
- Elevation: 3 soft levels (cards; sticky bars and popovers; modals). In dark mode, use lighter surfaces instead of shadows.

### 3.6 Icons and imagery
Rounded line icons, 1.5px stroke, 20/24px, one consistent set, plus custom sport icons (ball, padel racket, basketball, whistle, trophy, court). Photography of diverse Tunisian amateur players, women and men. Flat empty-state illustrations using the sport colors.

### 3.7 Motion
150–250ms; ease-out on enter, ease-in on exit. Skeletons instead of spinners for content. Micro-interactions: button press scale 0.98, chip selection, animated score counters, live lineup updates. Subtle confetti only for big moments (game full, tournament won, program completed). Respect reduced motion.

### 3.8 RTL
In Arabic, mirror layout, navigation, progress and back arrows. Do not mirror numbers, scores, media controls or maps.

### 3.9 Accessibility
WCAG 2.2 AA contrast, touch targets ≥ 44×44px, visible focus ring (2px ink-900 with 2px offset; Volt in dark mode), visible labels on every input, errors explained in text, accessible names on icon-only buttons.

## 4. Component library (all variants and states, light and dark)
### 4.1 Buttons
- Variants: Primary (ink-900 fill, white text; Volt fill in dark mode), Secondary (white fill, ink border), Tertiary/Ghost, Destructive (filled and outline), Link, Icon button (3 sizes), Floating action button (AI assistant), social sign-in (Google, Apple, following each provider's button guidelines).
- Sizes: S 32px, M 40px, L 48px, XL 56px (full-width sticky mobile CTAs).
- States: default, hover, pressed, focus, disabled, loading (spinner replaces label, width stays fixed), success (checkmark, then back).
- Patterns: leading/trailing icons, price inside the button (« Payer ma part · 15 DT »), countdown inside the button (« Réclamer la place · 14:59 »), button groups, segmented controls, toggle buttons.

### 4.2 Inputs and selection
Text field (label, helper, error, counter, prefix/suffix), password with show/hide and strength meter, phone with +216 prefix, 6-digit OTP, search with recent searches and suggestions, select, multi-select, date picker, time-slot picker, range sliders (price, distance, level), level slider, stepper (number of players), toggle, checkbox, radio, star rating, photo/file upload with drag-and-drop and progress, rich-text editor, tag input with suggestions.

### 4.3 Data display
Chips (filter, sport, level, choice, removable), status badges (Confirmé, En attente, Annulé, Complet, En direct, Remboursé, Vérifié), counters, avatars XS–XL (with level badge, online dot), avatar stack (« +3 »), level indicator on a 1,0–7,0 scale (Débutant, Intermédiaire, Avancé, Expert), reliability badge (« Fiable 96 % »), progress bar, progress ring, step indicator, countdown, tooltip, KPI card, data table (sort, filter, pagination, bulk and row actions, empty state), charts (line, bar, donut, occupancy heatmap).

### 4.4 Cards (default, compact and skeleton versions)
Open game, venue, booking, tournament, event, match/score, training program, lesson, coach, team, forum post, pricing plan, transaction row, notification item, AI suggestion.

### 4.5 Sport-specific components
- Lineup view: 5v5 pitch, padel 2v2 court, basketball half-court; players placed by position; empty spots as dashed « + » slots you can tap to join.
- Slot grid (courts × times): available, selected, booked, blocked, peak price, discounted, mine.
- Bracket: single elimination and groups + knockout; zoom and pan; live match highlighted.
- Scoreboard: large Barlow Condensed score, padel sets, live indicator, event timeline.
- Map: muted custom style, sport-colored pins, clusters with counts, selected pin opens a mini card.

### 4.6 Navigation
Mobile top app bar (large and compact title), bottom tab bar with badges, tabs, breadcrumbs, desktop sidebar (sections, collapsed state, role switcher), desktop top bar (global search, notification bell, avatar menu), pagination, wizard stepper.

### 4.7 AI components
« IA » label chip with sparkle icon, AI suggestion card (gradient border, « Recommandé car… » line, thumbs up/down, dismiss), AI-generated text block (« Régénérer », « Modifier »), AI processing state (gradient shimmer), match-fit score (« 92 % compatible »).

## 5. Overlay system
Define anatomy, sizes, animation and layer order for each type, then show real examples. Layer order: content < sticky bars < popovers < bottom sheets/drawers < modals < toasts < full-screen takeovers.
- Toast: non-blocking feedback, auto-dismiss after 4s, optional undo. Mobile: above the tab bar; desktop: top-right; max 3 stacked. Ex: « Réservation confirmée ».
- Snackbar with action: « Partie quittée · Annuler ».
- Persistent banner: email not verified, payment failed, offline, test mode, subscription expiring.
- Modal dialog: confirmations and destructive actions that state the consequence. Ex: « Annuler la réservation ? 45 DT seront remboursés sur ton solde MatchUp. »
- Bottom sheet (mobile): filters, slot details, split payment, quick rating, share. Drag handle and 3 heights (peek, half, full).
- Side drawer (desktop): booking details, user details, flagged content review, without leaving the table.
- Popovers, dropdown menus, « … » context menus, tooltips.
- Full-screen takeovers: « Partie complète ! » celebration, waitlist spot available with a 15-minute claim countdown, 3-D Secure authentication, AI assistant on mobile, photo/video viewer, booking QR code at check-in.
- Blocking loading overlay: only for payment processing.
Rules: one modal at a time; scrim ink-900 at 40%; close with X, scrim tap or Esc (except during payment); focus trapped inside; primary action on the right on desktop, full-width at the bottom on mobile.

## 6. Information architecture and navigation
- Player mobile tab bar: Accueil · Explorer · Mes matchs · Entraînement · Communauté. Top bar: notification bell with unread badge + avatar menu (profil, portefeuille, paramètres, changer de rôle). AI assistant: floating button above the tab bar.
- Explorer uses a segmented control: Parties · Terrains · Tournois, each with a map/list toggle. On desktop: map + list split view.
- Venue owner sidebar: Tableau de bord · Planning · Réservations · Terrains · Tarifs · Clients · Avis · Revenus · Abonnement · Paramètres.
- Organizer sidebar: Tableau de bord · Tournois & événements · Équipes · Calendrier · Scores en direct · Annonces · Revenus.
- Coach sidebar: Tableau de bord · Programmes · Élèves · Retours · Revenus · Abonnement.
- Admin sidebar: Vue d'ensemble · Utilisateurs · Vérifications · Terrains · Réservations · Tournois · Programmes · Paiements · Modération · Paramètres.
- Deliver a sitemap and flow diagrams for the 4 critical journeys: (1) find and join an open game, (2) book a court and split the payment, (3) register a team in a tournament, (4) subscribe to Premium.

## 7. Onboarding and authentication
- Splash, welcome carousel with 3 slides (« Trouve des joueurs à ton niveau », « Réserve et paie en quelques secondes », « Progresse et affronte les meilleurs »), « Commencer » / « J'ai déjà un compte ».
- Sign up (email + password, Google, Apple), phone verification by OTP, email verification screen, login, forgot password (email → code → new password → success), account locked.
- Role selection: Joueur · Propriétaire de terrain · Coach · Organisateur (multi-select).
- Player onboarding (progress bar, back, « Passer » on optional steps, progress saved):
  1. Choose sports (large sport cards, multi-select).
  2. AI level questionnaire per sport: 5–6 quick questions (experience, frequency, tournaments played, self-assessment of key skills), one per screen, large tappable answers.
  3. AI result: « Niveau estimé : 3,5 · Intermédiaire » with confidence, a short why, and « Ajuster ». The level then updates automatically after matches.
  4. Preferred position per sport (football: gardien, défenseur, milieu, attaquant; padel: côté droit / côté gauche; basket: meneur, ailier, pivot).
  5. Availability grid (days × matin / après-midi / soir).
  6. Location: priming screen before the system prompt, preferred zones (La Marsa, Lac 2, Ennasr, Menzah, Ariana…), fallback if permission is denied.
  7. Notifications: priming screen explaining the value before the system prompt.
  8. Photo and nickname → personalized Home with a 3-step tooltip tour.
- Venue owner onboarding: business info, venue address on map, courts (sport, surface, indoor/outdoor, lighting), opening hours, pricing rules (peak/off-peak), photos, payout details (RIB), plan choice → dashboard with a setup checklist.
- Coach onboarding: bio, specialties, certification upload (pending verification state), prompt to create a first program.
- Organizer onboarding: organization name, logo, contact, past events (optional).

## 8. Screens by module
For each screen, show the main state plus relevant loading, empty and error states.

### Module 1 — Users
- My profile and public profile: cover, avatar, name, sports, AI level per sport with trend sparkline, reliability (« 48/50 matchs honorés »), stats (matchs, victoires, tournois), badges, recent matches, teammate reviews, actions (« Inviter à une partie », « Suivre »).
- « Pourquoi ce niveau ? » bottom sheet explaining the AI estimate.
- Edit profile. Settings: account, security (password, 2FA, active sessions), language FR/AR/EN, theme (clair, sombre, système), notifications (→ section 9), privacy, connected accounts, delete account with consequences.
- Role switcher.
- Admin: platform overview (new users, bookings, revenue, active venues, open reports), users table (search, filters by role and status, bulk actions), user detail drawer (activity, reports, payments), suspend/ban dialog, verification queue for coaches and venues.

### Module 2 — Venues & Bookings
Player:
- Home: greeting, AI « Parties pour toi » carousel with match-fit %, quick actions (« Réserver un terrain », « Créer une partie »), upcoming bookings, nearby venues, tournaments near you.
- Explorer (Parties / Terrains): map/list toggle, search, filter sheet (sport, date, time, price, distance, level range, indoor/outdoor, lighting, amenities, game type: mixte / femmes / hommes), sort, results, no-results state with suggestions.
- Venue detail: photo gallery, verified badge, rating, address + mini map + directions, amenities, courts, date strip + slot grid, price per slot and per person, cancellation policy, reviews, sticky « Réserver ».
- Booking flow: court and slot → booking type (privée: invite friends / publique: missing spots, level range, game type, visibility) → summary and payment split choice → checkout (section 10) → confirmation (QR code, add to calendar, share link, invite players).
- Open game lobby: lineup view with empty slots, players and levels, level range, price per person, countdown, chat preview, rules, directions, sticky « Rejoindre et payer · 15 DT »; if full, « Rejoindre la liste d'attente ».
- Waitlist: position in queue; spot available → full-screen takeover with a 15-minute claim countdown.
- Mes matchs: tabs À venir / Passés / Annulés, booking detail, cancel flow with refund preview, leave a game.
- After the game: quick rating sheet for teammates (niveau, fair-play), report a no-show, optional score entry.
Venue owner:
- Dashboard: KPIs (taux d'occupation, revenus du jour, réservations, no-shows), today's timeline, AI insight card (« Jeudi 14h–17h : 80 % de créneaux vides. Proposer -20 % ? » with Appliquer / Ignorer), latest reviews.
- Planning: calendar with courts as columns and time as rows, day/week views, drag to block slots, booking side drawer.
- Courts management, pricing rules (peak/off-peak, special dates), bookings table, customers, reviews with reply, payouts.
- Mobile at the venue: today's schedule, QR check-in scanner (valid / already used / invalid), mark a no-show.

### Module 3 — Tournaments & Events
Player:
- List with filters (sport, date, level, entry fee, city); tournament card (poster, dates, fee, prize, spots left). Events (social games, initiation days) use the same structure with individual sign-up instead of teams.
- Tournament detail: overview, rules, format, schedule, registered teams, prizes, venue, organizer, sticky « Inscrire mon équipe ».
- Team registration: create team (name, logo, members via search or invite link, captain), pay entry fee, pending/confirmed states.
- Bracket, group standings, leaderboard.
- Live match: scoreboard, sets, event timeline, « EN DIRECT »; after the match, an AI recap card (labeled IA) with share.
Organizer:
- Dashboard: active tournaments, registrations, revenue, upcoming matches.
- Create tournament wizard: infos → format (élimination directe, poules + phase finale) → rules → venue and courts → dates → fees and prizes → preview → publish.
- Registrations management: approve/reject teams, payment status.
- AI bracket and schedule generator: constraints form (available courts, time windows, rest between matches) → generated preview → drag-and-drop edits → publish.
- Courtside score entry: huge buttons, one-handed use, confirmation before the final score.
- Announcement composer (sends a notification and an email).

### Module 4 — Coaching & Training
Player:
- Programs catalog (filters: sport, level, duration, price, coach) and program cards.
- Program detail: description, curriculum (semaines → séances → exercices), coach profile, reviews, price or « Inclus dans Premium », sticky « S'inscrire ».
- Lesson player: video, drill instructions, timer or rep counter, mark as done, notes, next lesson.
- Mon entraînement: active programs with progress rings, weekly streak, this week's sessions.
- AI training plan generator: goal (service, endurance, placement…), available days, intensity → weekly plan in a calendar view with Régénérer / Modifier / Accepter.
- Video analysis (stretch feature): upload → processing → feedback with timestamps and tips (labeled IA).
Coach:
- Dashboard: students, active enrollments, earnings, ratings.
- Program builder: drag-and-drop weeks, sessions and drills; video upload with progress; pricing; publish.
- Students list with progress, student detail, feedback composer.

### Module 5 — Payments & Subscriptions
(Checkout and payment states in section 10.)
- Plans page: Joueur Gratuit vs Premium, Propriétaire Starter vs Pro, Coach; monthly/yearly toggle with savings badge; comparison table; FAQ.
- Wallet: balance card, top-up, transaction history with filters, refund entries.
- Billing: current plan, next payment date, change plan with proration preview, payment methods, invoices with PDF download.
- Cancel subscription: reason → AI retention offer (« -30 % pendant 2 mois ») with an equally visible « Non merci, résilier » → confirmation with end date.
- Refund request and refund status.
- Invoice PDF (A4).
- Admin finance: revenue charts, transactions table, payouts to venues and coaches, refunds queue, AI churn-risk list with suggested actions (send offer, contact).

### Module 6 — Forum
- Forum home: categories (Conseils & technique, Équipement, Terrains, Tournois, Discussions libres), sport filter, sort (Tendance, Récents, Top), post cards (title, excerpt, tags, author with level badge, votes, replies).
- Create post: title, rich text, images, AI-suggested tags, a « Discussions similaires » panel that appears while typing the title.
- Post detail: thread, comments (2 levels), reactions, best answer, report.
- User-side moderation: pre-submit nudge when text may be toxic (« Ce message pourrait blesser. Le modifier avant de publier ? »), hidden-content placeholder (« Masqué par la modération · en cours de vérification »).
- Moderation queue (admin): flagged content table with AI toxicity score and reason, review drawer, actions (approuver, supprimer, avertir, suspendre).

## 9. Notification system
### 9.1 Channels
In-app (notification center + real-time toasts), push (mobile), email, SMS only for OTP. Real-time updates: when someone joins the game you are viewing, the lineup animates and a toast appears.

### 9.2 Notification center
Bell with unread count (up to « 99+ »). Mobile: full screen. Desktop: 400px dropdown panel with « Voir tout ». Grouped by Aujourd'hui / Cette semaine / Plus ancien. Filters: Tout, Matchs, Réservations, Tournois, Paiements, Entraînement, Communauté. Unread dot, « Tout marquer comme lu », swipe actions (lu, supprimer), inline actions (Accepter / Refuser, Payer ma part, Noter les joueurs, Réclamer la place), grouped items (« Yassine et 3 autres ont rejoint ta partie »), empty state.

### 9.3 Anatomy
Category icon in a colored circle, title, body, timestamp, optional avatar or thumbnail, optional actions, optional countdown for time-limited actions, 3 priority levels (normal, important, urgent) with different visual weight.

### 9.4 Catalog (design each as an in-app item)
- Matchs: partie complète, un joueur a quitté, rappel 2h avant, place libérée (15 min pour réclamer), invitation à une partie, noter tes coéquipiers.
- Réservations: confirmée, annulée par le terrain, modifiée, check-in réussi.
- Paiements: paiement réussi, échec du paiement, part à payer, remboursement effectué, abonnement renouvelé, échec du renouvellement, fin d'essai proche.
- Tournois: inscription confirmée, tableau publié, ton match commence dans 30 min, résultat, annonce de l'organisateur.
- Entraînement: nouveau plan IA prêt, retour du coach, nouvelle séance disponible, série en danger.
- Communauté: réponse à ton post, mention, meilleure réponse, contenu masqué par la modération.
- Owner / coach / organizer: nouvelle réservation, annulation, no-show, nouvelle inscription, nouvel avis, versement envoyé.

### 9.5 Push previews
iOS and Android lock-screen and banner previews for 5 key notifications, including a grouped one and an actionable one.

### 9.6 Preferences
Matrix of categories × channels (in-app, push, email) with toggles; payments and security cannot be fully disabled; quiet hours; weekly digest frequency; « Tout mettre en pause » option.

### 9.7 Email templates (600px, mobile-friendly, dark-mode safe)
Logo header, clear title, key-info block, one primary button, footer with preferences and unsubscribe. Templates:
1. Bienvenue + vérification de l'email
2. Code de réinitialisation du mot de passe
3. Réservation confirmée (QR code, terrain, horaire, joueurs, accès, politique d'annulation)
4. Rappel de match
5. Reçu de paiement / facture
6. Demande de paiement de ta part
7. Abonnement renouvelé / échec de paiement / fin d'essai
8. Inscription au tournoi + calendrier des matchs
9. Récap hebdo « Parties près de chez toi » (personnalisé par l'IA)
10. Offre de rétention (risque de résiliation détecté par l'IA)
11. Nouvelle réservation et versement envoyé (propriétaire)

## 10. Stripe checkout and payment flows
Payments use Stripe (test mode for the demo). Design our own checkout page that embeds the Stripe Payment Element; do not imitate Stripe's hosted checkout.

### 10.1 Checkout page (mobile and desktop)
- Desktop: two columns, order summary on the left, payment on the right. Mobile: collapsible summary at the top (« Voir le détail · 60 DT »), payment below, sticky pay button.
- Order summary: item (booking, tournament fee, program or plan), venue, court, date and time, players, split breakdown (« Ta part : 15 DT sur 60 DT »), promo code (valid/invalid states), wallet toggle (« Utiliser mon solde : 10 DT »), fees, total.
- Payment: saved cards (radio list, default card, expiry warning); new card with our cardholder-name field plus a clearly bounded zone reserved for the Stripe Payment Element (card number, expiry, CVC, country); express wallet buttons row; « Enregistrer cette carte »; checkbox accepting terms and cancellation policy; pay button with the exact amount (« Payer 15 DT »); lock icon with « Paiement sécurisé par Stripe » as plain text; generic card-brand placeholders.
- Test-mode ribbon: « MODE TEST · carte 4242 4242 4242 4242 ».
- Provide Stripe Appearance API values that match our tokens so developers can style the Payment Element: colorPrimary, colorBackground, colorText, colorDanger, fontFamily, borderRadius, spacingUnit.

### 10.2 Payment states
Default, inline field errors (numéro invalide, CVC incorrect, carte expirée), card declined with alternatives (another card, wallet), processing (form locked, button spinner, « Ne ferme pas cette page »), 3-D Secure overlay around the bank's authentication window, network error with retry, timeout, success.

### 10.3 Related flows
- Payment success: animated check, receipt summary, QR code for bookings, « Ajouter au calendrier », « Partager », « Inviter des joueurs ».
- Payment failed: reason in plain words, retry, change method.
- Split payment tracker: players with Payé / En attente, « Relancer » button, deadline countdown, visible rule (« La réservation sera annulée si tout n'est pas payé 3h avant le match »), organizer option « Payer le reste ».
- Wallet top-up checkout, subscription checkout (plan, period, trial, next charge date), tournament entry fee checkout.

## 11. AI assistant
- Entry points: floating button on mobile, a « Demande à MatchUp… » bar on Home, a right side panel on desktop.
- Chat: welcome state with suggestion chips (« Trouve-moi une partie de padel demain soir », « Réserve un terrain à La Marsa samedi », « Quel programme pour améliorer mon service ? »), message bubbles, typing indicator, rich result cards inside the chat (games, slots, programs) with actions.
- Confirmation step before any booking or payment: « Je réserve le Terrain 2 à Arena Five, sam. 18 oct. à 20h00, 60 DT (15 DT par joueur). Confirmer ? » → Confirmer / Modifier.
- States: thinking, partial results, no result with alternatives, error, « L'IA peut se tromper » footnote, thumbs feedback on every answer.
- Dashboards: the same assistant in a side panel for owners, organizers and admins (« Quels créneaux sont les moins remplis cette semaine ? »).

## 12. Global states and edge cases
Reusable patterns, shown on real screens:
- Empty states: illustration + one helpful action (no bookings, no notifications, no programs, no results).
- Skeletons for every card and table type.
- Errors: offline banner with cached content, server error, 404, session expired, permission denied (location, camera, notifications) with steps to enable.
- Forms: inline validation on blur, error summary on long forms, never clear user input on error.
- Pull-to-refresh, infinite scroll with end-of-list, optimistic updates with rollback toast.
- Account states: email not verified, suspended account, incomplete profile reminder.

## 13. Content and microcopy
- No lorem ipsum. Realistic Tunisian data: players (Yassine B., Mariem K., Skander T., Ines M., Hamza R., Nour A.), places (La Marsa, Lac 2, Ennasr, Menzah 6, Ariana, Sousse, Sfax), fictional venues (Arena Five, Smash Padel Club, Hoop Zone), prices in DT.
- Tone: friendly, short, energetic, « tu ». Buttons are verbs (« Rejoindre », « Réserver », « Payer ma part »), never a lone « OK ».
- Error messages say what happened and what to do next.

## 14. Deliverables and organization
- Sections in this order: Cover · Foundations · Components · Overlays · Sitemap & flows · Onboarding · Modules 1–6 · Notifications · Checkout & payments · AI assistant · Dashboards · Emails · Dark mode & RTL.
- Frame sizes: mobile 390×844, desktop 1440×900, email 600px wide, invoice A4.
- Name every frame with a code: [ONB-01] Splash, [USR-03] Profil public, [BKG-07] Lobby de partie, [TRN-04] Tableau, [CCH-02] Lecteur de séance, [PAY-01] Checkout, [FRM-05] File de modération, [NOT-01] Centre de notifications, [EML-03] Réservation confirmée, [AI-02] Chat.
- Under each frame, a 1–2 line annotation: purpose, main action, entry point.
- Link the frames of the 4 critical journeys into a clickable prototype.
- Show Home, game lobby, live match and checkout in dark mode, and Home, venue detail and checkout in Arabic RTL.

## 15. Milestones (deliver one, then wait for "next")
1. Foundations, components and overlay system (sections 3, 4, 5).
2. Sitemap, critical journey flows, onboarding and authentication (sections 6, 7).
3. Player core: Module 2 player screens + Module 1 profile and settings.
4. Payments: checkout, payment states, split payment, wallet, plans, billing, cancellation (section 10 + Module 5 player screens).
5. Notification system: center, toasts, push previews, preferences, emails (section 9).
6. Tournaments, Training and Forum player screens (Modules 3, 4, 6).
7. AI assistant (section 11).
8. Dashboards: venue owner (with mobile check-in), organizer, coach, admin (overview, users, finance, moderation).
9. Global states, dark mode and RTL samples, final consistency pass (sections 12, 14).