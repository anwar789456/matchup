# TournamentCard
A tournament — poster with its dates, registration status, venue and level, then entry fee, prize money and teams left on the scoreboard strip.

## When to use
- **Default** (poster on the left) in the « Tournois » list on mobile.
- **Vertical** (poster on top) in desktop grids, 2–3 up.
- **Compact** in search results, a venue page and « Mes tournois ».

## Anatomy & specs
| Part | Spec |
|---|---|
| Surface | `mu-card`, padding `space-4` (vertical: body padding `space-4`, poster full bleed) |
| Poster | CourtArt poster 3:4, width 96, `radius-sm`; dates printed at the bottom in `white`: « 24–26 » `num-l` + « OCT. » `overline`. Vertical: 16:10, top band of the poster, `photo-scrim`, status badge top-start |
| Identity | status badge · name `label-l` · dates and « Smash Padel Club · Lac 2 » `body` `text-secondary` with icons · sport Chip S + level Chip S « Niveau 3,5–5,0 » |
| Scoreboard strip | INSCRIPTION « 120 DT » / « par équipe » · DOTATION (trophy) « 1 500 DT » · PLACES « 4 libres » / fill bar (6 px, `radius-xs`, `<sport>` fill on `surface-muted`) |
| Footer | « 12/16 équipes inscrites » `caption` (count `num-xs`) · Button M |
| Compact | min-height 88, padding `space-3`; poster thumb 54 × 72 (`radius-sm`, hairline ring); name `label`; « 24–26 oct. · Smash Padel Club » `caption`; mini fill bar (64) + « 4 places » or a badge; fee `num-m` + « /équipe » |

## Variants
`default` · `vertical` · `compact`.

## States
- **Inscriptions ouvertes** — success badge, primary « S’inscrire ».
- **Almost full** (≤ 25 % of the teams left) — warning badge « Plus que 4 places », places in `warning-text` in compact.
- **Complet** — StatusBadge full, bar full, secondary « Liste d’attente ».
- **En cours** — StatusBadge live « EN COURS » with the pulsing dot; the third cell becomes ÉQUIPES « 16 » / « en lice »; secondary « Voir le tableau ».
- **Hover** `elevation-2` · **Pressed** `scale-press` · **Focus** `focus-ring` · **Skeleton** same layout.

## Content
- Dates as a range: « 24–26 oct. », « 30 oct. – 2 nov. ».
- Fee per team and prize money in full dinars: « 120 DT », « 1 500 DT » (narrow space thousands).
- Spots are what is left: « 4 libres », « Plus que 4 places ».

## Accessibility
- The poster is an image named « Affiche du tournoi Padel Masters Lac 2 »; the dates printed on it are repeated as text.
- The fill bar is decorative; the cell reads « 4 libres sur 16 équipes ».
- The live badge is colour + dot + « En cours »; the dot stops pulsing with reduced motion.

## Do / Don't
- Do keep the entry fee per team and the prize money side by side — they decide registration.
- Do use the vertical variant only in grids; on mobile the poster sits on the left.
- Don't invent prize breakdowns on the card; they belong to the tournament page.

## Props (web preview)
`variant` · `sport` · `name` · `start` · `end` · `venue` · `place` · `fee` · `feeUnit` · `prize` · `teamsTotal` · `teamsRegistered` · `levelMin` · `levelMax` · `status` · `onRegister` · `onWaitlist` · `onView` · `href` · `onOpen` · `skeleton` · `state`. See `index.d.ts`.

## Flutter
`MuTournamentCard(tournament: MuTournament, variant: MuTournamentCardVariant.standard, onRegister:, onWaitlist:, onViewBracket:, onTap:, loading:)` — `MuCardSurface`; poster as `ClipRRect(AspectRatio(3 / 4))` (vertical: `AspectRatio(16 / 10)` with `Alignment.topCenter` `FittedBox` and a gradient scrim); `LinearProgressIndicator` styled 6 px for the bar.
