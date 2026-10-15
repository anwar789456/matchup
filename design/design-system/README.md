MatchUp is the amateur-sports platform for Tunisia: 5-a-side football, padel and basketball. Players find teammates and open games at their level, book courts, pay their share, join tournaments, train and talk with the community; venue owners, coaches, organisers and admins run it all from desktop dashboards. Tagline: « Joue. Réserve. Progresse. »

The look is **a modern scoreboard meets a premium booking app**: generous white space, bold condensed numerals, sport-coded accents, rounded cards, courts under evening lights. It is energetic and social, and it stays clean and trustworthy because money changes hands on almost every screen.

This system is the single source for every MatchUp screen, web or Flutter. Use its tokens, type styles and components as they are; when a screen needs something new, add it here first. No one-off colours, sizes or components.

## Using this system

- **Tokens.** Every colour, length, shadow, duration and easing is a token in `tokens.json`. In CSS, use the custom property of the same name (`var(--surface)`, `var(--space-4)`, `var(--radius-md)`, `var(--duration-base)`). Never paste a hex, a pixel size or a timing that has a token.
- **Themes.** Two themes, switched with `data-theme` on the root: `light` (« Light ») and `dark` (« Night match »). Style through the semantic roles (`bg`, `surface`, `text`, `primary`…) and both themes follow automatically. Never write a `[data-theme]` selector in a component.
- **Type.** Set text only through the type classes on the element that holds it: `display h1 h2 h3 body-l body caption overline label-l label label-s` (Plus Jakarta Sans) and `score num-hero num-xl num-l num-m num-s num-xs` (Barlow Condensed, tabular figures). Never set `font-size`, `line-height` or `font-weight` by hand.
- **Components.** `components/bundle.js` defines `window.MatchUp` (React 18, loaded before it); `components/bundle.css` styles it. Each component card has a live preview, its guidelines and a `## Flutter` note naming the widget to build. Root classes are `mu-<name>`, parts `mu-<name>__part`, states `is-<state>`.
- **Flutter.** The Flutter section ships the same tokens as Dart (`MuColors`, `MuType`, `MuSpace`, `MuRadius`, `MuMotion`, `MuTheme.light()` / `MuTheme.dark()`), generated from `tokens.json` so the app and this system never drift.

## The rules that never bend

- **Volt is a fill, never ink.** `accent` (Volt #C6F135) marks selected chips and slots, the active-tab pill, highlights and Night-match primary buttons, always with `on-accent` (ink) on it. Never set Volt text, icons or thin outlines on a light ground. The one exception is `toast-action`, because `toast-bg` is dark in both themes.
- **Sport colours only categorise.** `football`, `padel` and `basketball` colour chips, map pins, card accents, courts and illustrations, and always travel with the sport icon and name. Text in a sport hue uses `<sport>-text`; tints use `<sport>-soft`.
- **Status is never colour alone.** Every state is colour + icon + label: use `StatusBadge` (« Confirmé », « En attente », « Annulé », « Complet », « En direct », « Remboursé », « Vérifié »).
- **AI is labelled, explained and optional.** `ai-*` colours and `ai-gradient` belong to AI features only. Every AI output carries the « IA » label (`AiLabel`), says why (« Recommandé car… »), can be edited or dismissed, and never books, pays or publishes without an explicit confirmation.
- **Price per person, always.** Show the share each player pays (« 15 DT /pers. »), not only the court price. Time, place, price per person and spots left are visible on every game and booking card.
- **Thumb zone.** On mobile the main action sits in a sticky bottom bar as an XL full-width `Button`. On desktop the primary action is on the right.
- **Night match lifts with light, not shadow.** In the dark theme, elevation is a lighter surface (`surface-elevated`) plus a hairline ring; shadows are not used.
- **Every screen has every state.** Loading (skeletons shaped like the content, not spinners), empty (an illustration and one helpful action), error (what happened and what to do), success and disabled.
- **Accessible by construction.** WCAG 2.2 AA in both themes, 44 px touch targets, a visible focus ring, a visible label on every input, errors explained in words, a name on every icon-only button. See Accessibility.
- **Mirror the layout, not the numbers.** In Arabic, mirror layout, navigation, progress and directional arrows; never mirror numbers, scores, media controls or maps.
- **No dark patterns.** Cancelling is as easy as subscribing; « Non merci » is as visible as the offer; refund and cancellation rules show before the pay button.

## Content fundamentals

French by default, informal « tu », short and energetic. Arabic (RTL) and English are available from the language switcher.

- **Buttons are verbs**: « Rejoindre », « Réserver », « Payer ma part », « Réclamer la place ». Never a lone « OK », « Valider » or « Cliquez ici ».
- **Errors say what happened and what to do next**: « Paiement refusé par ta banque. Aucun montant débité. Essaie une autre carte. »
- **Confirmations state the consequence**: « Annuler la réservation ? 45 DT seront remboursés sur ton solde MatchUp. »
- **Money**: « 60 DT », « 12,500 DT » (three decimals after a comma when not whole), « 1 250 DT » (narrow space for thousands).
- **Dates and times**: « sam. 18 oct. · 20h00 ». Durations « 1 h 30 ». Countdowns « 14:59 ».
- **Phone**: « +216 20 123 456 » (+216, then 8 digits grouped 2-3-3).
- **Levels**: « 3,5 · Intermédiaire » on the 1,0–7,0 scale (Débutant < 2,5 ≤ Intermédiaire < 4,0 ≤ Avancé < 5,5 ≤ Expert).
- **Trust**: « Fiable 96 % », « 48/50 matchs honorés », « Terrain vérifié ».
- **AI**: « IA » label, « Recommandé car tu joues le jeudi soir et ton niveau (3,5) correspond. », « 92 % compatible », « L'IA peut se tromper. »
- **Real data only, never lorem ipsum.** Players Yassine B., Mariem K., Skander T., Ines M., Hamza R., Nour A.; places La Marsa, Lac 2, Ennasr, Menzah 6, Ariana, Sousse, Sfax; venues Arena Five (football, La Marsa), Smash Padel Club (padel, Lac 2), Hoop Zone (basketball, Ennasr). A football court at 150 DT for 10 players is 15 DT each; padel at 60 DT for 4 is 15 DT each.
- No emoji in the interface. The voice is the one of a friend who organises the Thursday game: direct, warm, precise about money.

## Visual foundations at a glance

- **Colour**: ink neutrals (`ink-900` … `ink-50`) carry the interface; Volt is the single brand accent; three sport hues categorise; semantic `success`, `warning`, `error`, `info`; a violet→blue gradient for AI only; a red pulsing dot + « EN DIRECT » for live. See Colour.
- **Type**: Plus Jakarta Sans for words, Barlow Condensed with tabular figures for every number people compare (scores, prices, times, stats, countdowns), IBM Plex Sans Arabic for Arabic. See Typography.
- **Space and shape**: 4 px base (`space-1` … `space-16`); radii 8 for inputs and small buttons, 12 for cards and buttons, 16 for sheets and modals, full for chips and avatars; three soft elevation levels in Light. See Layout.
- **Icons and imagery**: Phosphor Regular (1.5 px stroke at 24) with Fill for the selected tab, plus six MatchUp sport icons; night-lit court art (`CourtArt`) stands in for photography; flat illustrations in the sport colours. See Iconography & imagery.
- **Motion**: 150–250 ms, ease-out in, ease-in out, a 0.98 press, skeleton shimmer, rolling score counters, confetti only for the big moments, all of it off under reduced motion. See Motion.

## Components

Ninety-five components in twelve groups, each previewed in both themes with its states:

- **Brand**: Logo, Icon, CourtArt.
- **Actions**: Button, IconButton, Fab (AI assistant), SocialButton, ButtonGroup, SegmentedControl, ToggleButton.
- **Inputs**: TextField, PasswordField, PhoneField, OtpInput, SearchField, Select, MultiSelect, TagInput, RichTextEditor, FileUpload.
- **Selection**: Checkbox, Radio, ChoiceCard, Switch, Stepper, RangeSlider, LevelSlider, StarRating, DatePicker, TimeSlotPicker.
- **Data display**: Chip, StatusBadge, Counter, Avatar, AvatarStack, LevelIndicator, ReliabilityBadge, ProgressBar, ProgressRing, StepIndicator, Countdown, Tooltip, DataTable.
- **Charts**: KpiCard, Sparkline, LineChart, BarChart, DonutChart, Heatmap (occupancy).
- **Cards** (default, compact and skeleton): GameCard, VenueCard, BookingCard, TournamentCard, EventCard, MatchCard, TeamCard, ProgramCard, LessonCard, CoachCard, ForumPostCard, PricingCard, TransactionRow, NotificationItem.
- **Sport**: Lineup (5v5 pitch, padel 2v2, basketball half-court), SlotGrid, Bracket, Scoreboard, MapView.
- **Navigation**: TopAppBar, TabBar, Tabs, Breadcrumbs, Sidebar, RoleSwitcher, TopBar, Pagination, WizardStepper.
- **AI**: AiLabel, AiSuggestionCard, AiTextBlock, AiShimmer, MatchFitScore.
- **Feedback**: Skeleton, Spinner, EmptyState.
- **Overlays**: Toast, Snackbar, Banner, Dialog, BottomSheet, Drawer, Popover, Menu, Takeover, LoadingOverlay. Their layer order and rules are in Overlay system.

Build screens from these. A pattern used on two screens becomes a component here before it ships.
