# Takeover

A full-screen moment above everything (`z-takeover`) — « Partie complète ! », a freed waitlist spot to claim within 15 minutes, our frame around the bank's 3-D Secure window, the check-in QR code, the photo and video viewer, and the AI assistant on mobile.

## When to use
- `Takeover.Celebration` when the last spot of a game fills (« Partie complète ! »).
- `Takeover.Claim` when a waitlist spot frees up: 15 minutes to claim it.
- `Takeover.SecurePayment` around the bank's 3-D Secure page during a payment.
- `Takeover.Ticket` for the booking QR code at check-in; `Takeover.Viewer` for venue and match photos and videos; `Takeover.Assistant` for the AI assistant on mobile.
- The bare `Takeover` for another full-screen moment of the same weight. Not for forms or confirmations (Dialog) or browsing (a page).

## Anatomy & specs
- **Shell**: fills the screen on `bg` inside the device safe areas; no scrim — it covers bars, sheets, dialogs and toasts. **Layer** `z-takeover` (600), the highest.
- **Bar**: min `app-bar` 56, padding inline `space-2`: `barStart` · centred title `label-l` · `barEnd` + IconButton « Fermer » (`closePlacement` start or end, `closeIcon`).
- **Body** scrolls; **footer** padding `space-3` `space-4` `space-4`: a stacked ButtonGroup, a tertiary L above the full-width XL primary.
- `tone="dark"` renders it in Night match in both themes — used by Celebration and Viewer (Volt and confetti need a dark ground, media reads best on dark).

| Composition | Spec |
|---|---|
| Celebration | 152 mark: `accent` disc with an `on-accent` check that draws on, two `accent` rings, four sport and Volt dots; sport Chip eyebrow; title `display`; summary `label-l`; detail `body` `text-secondary`; AvatarStack S (6 + « +4 »); 30 confetti pieces in Volt and sport colours, one fall; « Partager » + « Voir la partie » |
| Claim | « LISTE D’ATTENTE » `overline` with `hourglass-medium`; title `h1`; 216 ring timer (8px `border` track, `primary` progress and head) around « 14:59 » `num-hero` + « pour réclamer ta place » `caption`; game card (CourtArt 48, venue `label`, time and « 9/10 joueurs » `caption`, price `num-m` « / joueur »); « Laisser passer » + « Réclamer la place · 14:59 » |
| SecurePayment | no X; title `h3` + « Paiement sécurisé par Stripe » (`lock-simple`); summary card: merchant `label`, detail `caption`, amount `num-l`; bank zone: 1.5px dashed `border-strong`, `radius-md`, min 240, legend « Fenêtre de ta banque » `label-s`; a `warning-soft` strip « Ne ferme pas cette page » |
| Ticket | title « Check-in »; « Luminosité augmentée » pill (`sun` in `warning`); card `surface`, `radius-lg`, `elevation-2`: sport Chip, venue `label`, court `h2`, date `overline` + time `num-l`, a 208 QR in `ink-900` on `white` in both themes with the logo, reference `num-m` tracked 0.12em; a perforation; Joueurs · Payé (`num-m`) · Statut « Confirmé » in `success-text` |
| Viewer | X at the start, « 2 / 8 » `num-s` as title, share at the end; media 4:3 (video 16:9 with a 64 play disc and a `num-xs` duration); inverse prev / next IconButtons at the edges; caption `label-l` + credit `caption`; 6px dots, the current one 20 wide in `accent` |
| Assistant | bar: 32 `ai-gradient` mark + « Assistant MatchUp »; sender « MatchUp » + « IA » label (`ai-soft`, `ai-text`); greeting bubble `body-l` on `ai-soft`; sparkle suggestion Chips; composer: `control-xl` pill with a `border-control` edge, input `body-l`, microphone, send (primary, disabled while empty); disclaimer `caption` |

## States
- **Enter**: fade + `translateY(16px)` → 0 over `duration-slow`, `ease-enter`. **Exit**: the reverse over `duration-base`, `ease-exit`.
- **Close**: X or Esc (there is no scrim to tap). `closable={false}` (3-D Secure) or `busy` hides the X and ignores Esc, with `aria-busy` — the payment flow closes it.
- **Claim**: counts down from `total` (900 s) or follows `seconds`; in the last 60 s the ring turns `error` and the digits `error-text`. Its X reads « Décider plus tard ».
- **Reduced motion**: the confetti hangs still and the check appears without drawing on.

## Content
- « Partie complète ! » · « 10/10 joueurs · sam. 18 oct. · 20h00 » · « Arena Five · La Marsa · Terrain 2 ».
- « Une place s’est libérée ! » · « Sans réponse, la place passe au suivant de la liste. »
- « Authentification de ta banque » · « Ta banque prend le relais » · « Tu reviendras automatiquement sur MatchUp. »
- Assistant: « Demande à MatchUp… » and « L’IA peut se tromper. Elle ne réserve et ne paie rien sans ta confirmation. »

## Accessibility
- `role="dialog"`, `aria-modal`, labelled by the title or `label`. Focus moves in — to the primary on Celebration and Claim — Tab stays inside, page scroll locks, and focus returns to the trigger on close.
- The claim timer is `role="timer"` (« Temps restant 14:59 »); the celebration is `role="status"`; the assistant thread is `aria-live="polite"`; the QR is an `img` « QR code de la réservation MU-20481 »; the bank zone is a labelled `group`.
- Viewer: ← / → and swipes of 48px or more follow the reading direction; playback controls never mirror.

## Do / Don't
- Do keep one takeover at a time; it replaces whatever was open.
- Do let people leave every takeover except the 3-D Secure frame.
- Don't celebrate anything smaller than a full game or a won tournament.
- Don't hide the price per player on the claim card.

## Props (web preview)
`open` · `onClose` · `tone` · `closable` · `closeLabel` · `closeIcon` · `closePlacement` · `title` · `label` · `barStart` · `barEnd` · `footer` · `children` · `busy` · `safeArea` · `bodyClassName` · `inline` · `autoFocus`; `.Celebration`: `eyebrow` · `summary` · `detail` · `people` · `primaryLabel` · `onPrimary` · `secondaryLabel` · `onSecondary` · `confetti`; `.Claim`: `seconds` · `total` · `game` · `claimLabel` · `onClaim` · `passLabel` · `onPass` · `note`; `.SecurePayment`: `provider` · `amount` · `merchant` · `detail` · `bankLabel` · `children`; `.Ticket`: `reference` · `sport` · `venue` · `court` · `date` · `time` · `players` · `price` · `brightness`; `.Viewer`: `items` · `index` · `defaultIndex` · `onIndexChange` · `onShare`; `.Assistant`: `greeting` · `suggestions` · `onSuggestion` · `placeholder` · `onSend` · `disclaimer`. See `index.d.ts`.

## Flutter
`MuTakeover.show(context, child: …, tone: MuTakeoverTone.dark, closable: true)` → `Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(opaque: true, fullscreenDialog: true, transitionDuration: 250 ms, reverseTransitionDuration: 200 ms))` with a `FadeTransition` and a 16px `Transform.translate`; the root navigator puts it over everything, `PopScope(canPop: closable && !busy)` guards Back, and `tone: dark` wraps it in the Night match theme. Compositions are named constructors: `.celebration` (confetti `CustomPainter`), `.claim` (ring `CustomPaint` driven by a `Ticker`), `.securePayment` (the bank page in a `WebView`), `.ticket` (raise screen brightness while open), `.viewer` (`PageView`), `.assistant`.
