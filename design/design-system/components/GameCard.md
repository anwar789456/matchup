# GameCard
The open-game card — sport, venue and level up top, a scoreboard strip with time, spots left and price per player, then who's in and « Rejoindre ».

## When to use
- **Default** in the « Parties » feed, search results and venue pages (mobile 358, desktop 2–3-up grids).
- **Featured** for the first slot of « Parties pour toi » — one per screen, with the photo header.
- **Compact** in dense lists: « Mes parties », map bottom sheet, a venue's « Ce soir ».
- Not for a booked court without open spots (use BookingCard) or an event with individual sign-up (EventCard).

## Anatomy & specs
| Part | Spec |
|---|---|
| Surface | `mu-card`: `surface`, `radius-md`, `elevation-1` (hairline ring in Night match), padding `space-4`, rows `space-3` apart |
| Head | sport Chip S (`<sport>-soft`) + game-type Chip S · flags and AI pill at the end (a wrapped group starts line 2) |
| Identity | title `label-l` (featured `h3`) · place `body` `text-secondary` + 16 px pin · level Chip S « Niveau 3,0–4,5 » (`gauge`, value `num-xs`) · organiser `caption` + name `label-s` + shield `success-text` « Fiable 96 % » |
| Scoreboard strip | full bleed (`-space-4`), `surface-muted` band, `border` hairlines around and between cells; cell padding `space-3` (edges `space-4`, `space-2` when the strip is ≤ 340); label `overline` `text-secondary`, value `num-l` + unit `num-m`, sub `caption` |
| Cells | HEURE « 20h00 » / « sam. 18 oct. » · PLACES « 2 libres » / dots meter · PRIX « 15 DT » / « par joueur » |
| Dots meter | one dot per player (≤ 12): 7 px (shrinks to 4 px), 3 px gap; filled = taken in `<sport>`, hollow = free, 1.5 px `border-strong` ring |
| Footer | AvatarStack XS (4 + « +N ») + caption « 8 inscrits » (hidden when the footer is ≤ 300) · Button M, never shrinks, 44 px hit area |
| Compact | min-height 88, padding `space-3`; tile 64 `radius-sm` on `<sport>-soft`: day `overline` + time `num-m`; title `label` (one line); meta `caption` with sport icon; dots + « 2 places libres » `label-s`; price `num-m` + « /joueur » |
| Featured | CourtArt photo 16:9 under `photo-scrim`; overlay padding `space-4`: sport chip + « PARTIES POUR TOI » `overline`, time `num-xl` + date `label` in `white`; strip PLACES · PRIX · NIVEAU |

## Variants
`default` · `featured` · `compact`. Columns of the strip share the width equally; a column whose content needs more room takes it (`minmax(min-content, 1fr)`), so a value is never clipped.

## States
- **Open** — CTA « Rejoindre » (primary). **AI fit** (optional) « ✦ 92 % compatible » in `ai-text` on `ai-soft`: the only AI colour on the card.
- **Almost full** (1 spot) — warning badge « Plus que 1 place » (`warning-soft`, `warning` icon).
- **Full** — StatusBadge « Complet », « 0 libre », every dot filled, CTA « Liste d’attente » (secondary).
- **You're in** — Volt badge « Tu joues », CTA « Voir la partie » (secondary).
- **Starting soon** (`startsIn` < 60) — the HEURE sub becomes « Dans 45 min » with a timer, `warning-text`; on featured a warning pill next to the time.
- **Cancelled** — StatusBadge « Annulée », values struck through in `text-secondary`, dots `text-disabled`, no CTA, line « Remboursé 15 DT sur ton solde » in `info-text`.
- **Hover** `elevation-2` · **Pressed** `scale-press` (not when an inner button is pressed) · **Focus** `focus-ring` around the card · **Skeleton** the same layout in Skeleton blocks.

## Content
- Title « Arena Five · Terrain 2 »; place « La Marsa · 2,4 km »; type « Mixte », « Femmes », « Hommes ».
- Always the price per player (court price ÷ players): « 15 DT », never « 150 DT ».
- Spots left, not taken: « 2 libres », « 1 libre », « Plus que 1 place ».
- The AI pill is the IA mark (sparkle); tapping it opens « Pourquoi ? » (« Recommandé car ton niveau et tes soirées du samedi correspondent ») with « Masquer ce type de suggestion ». The AI never joins or pays for the player.

## Accessibility
- `article` named by its title; the title is a stretched link, so the whole card opens the game while inner buttons stay separately focusable.
- The strip is a `dl` (label = `dt`, value and sub = `dd`); the dots meter is decorative, the text reads « 2 libres sur 10 ».
- The AI pill reads « IA : 92 % compatible »; its tooltip says why.

## Do / Don't
- Do keep time, place, price per player and spots left visible in every variant.
- Do let the « 8 inscrits » caption disappear before the CTA shrinks.
- Don't add a coloured border — the sport chip, dots and tile carry the sport.
- Don't show the AI pill on full, joined or cancelled games.

## Props (web preview)
`variant` · `sport` · `gameType` · `venue` · `court` · `place` · `distance` · `start` · `dateLabel` · `spotsTotal` · `spotsLeft` · `price` · `levelMin` · `levelMax` · `players` · `organiser` · `matchFit` · `matchFitReason` · `status` · `startsIn` · `refund` · `onJoin` · `onWaitlist` · `onView` · `href` · `onOpen` · `skeleton` · `state`. See `index.d.ts`.

## Flutter
`MuGameCard(game: MuGame, variant: MuGameCardVariant.standard, onJoin:, onWaitlist:, onView:, onTap:, loading: false)` — a `StatelessWidget` on `MuCardSurface` (`Material` + `InkWell`, `AnimatedScale` 0.98). Build the strip as `IntrinsicHeight(Row([...cells], VerticalDivider))` on `colors.surfaceMuted`; derive almost-full / full from `spotsLeft`; `loading: true` renders `MuSkeleton` blocks in the same layout.
