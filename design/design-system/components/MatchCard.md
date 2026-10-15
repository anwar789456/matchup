# MatchCard
A fixture or result on a scoreboard — round and court, two teams with monograms, Barlow scores, the winner on a Volt highlight, live minute or padel sets.

## When to use
- **Default** in a tournament's « Matchs » tab, a team page and the live centre.
- **Compact** in brackets, « Résultats » lists and the home « En direct » strip.
- For a casual open game use GameCard; MatchCard is about the score.

## Anatomy & specs
| Part | Spec |
|---|---|
| Surface | `mu-card`, padding `space-4`, rows `space-3` apart |
| Head | « DEMI-FINALE · TERRAIN 2 » `overline` `text-secondary` · status at the end: StatusBadge live + minute « 34’ » `num-s` `error-text`, « TERMINÉ » `overline`, or the date `label-s` |
| Board | grid: monogram 40 (`radius-sm`, `<sport>-soft`, initials `label`) · name `label-l` (2 lines max; padel pairs one player per line) · score column; rows ≥ 64, `border` hairline between them |
| Score | football and basket: `num-xl` in a 44-wide cell; padel: one `num-m` column per set, set winner `text`, set loser `text-secondary` |
| Winner | score on `accent` (Volt) with `on-accent` digits, `radius-sm`; trophy icon after the name; loser name `body-l` and score `text-secondary` |
| Live set | the current set column on `surface-muted` from header to last row, « ● S3 » header in `error-text` |
| Upcoming | kick-off tile instead of scores: « 18h30 » `num-l` + « Coup d’envoi » `caption` on `surface-muted`, `radius-sm`, `border` ring |
| Footer | competition `caption` with sport icon · basket target « Premier à 21 points » (`target` icon) |
| Compact | min-height 88: head + broadcast line (monogram 32 · short name `label` · score `num-l` « 3 – 2 », winner on Volt · short name · monogram); padel: two-row mini board (monogram 24, sets `num-s`) |

## Variants
`default` · `compact`; scores or padel sets (`teams[].sets`).

## States
- **Upcoming** — kick-off tile and date in the head.
- **Live** — « EN DIRECT » badge with the pulsing `live` dot and the minute; no winner emphasis; padel highlights the set in play.
- **Final** — « TERMINÉ », winner score on Volt, trophy, loser muted.
- **Focus** `focus-ring` around the card · **Skeleton** two rows of blocks.

## Content
- Rounds in French: « Poule A », « Quart de finale », « Demi-finale », « Finale ».
- Courts: « Terrain 2 » (football, basket), « Court 1 » (padel). Live minute « 34’ ».
- Padel teams are pairs « Yassine B. / Hamza R. »; compact uses first names « Yassine / Hamza ».

## Accessibility
- A hidden heading names the card « Les Faucons de La Marsa contre Ennasr United »; a stretched link carries that name.
- Monograms are decorative; the trophy reads « Vainqueur ».
- Scores and minute are text, so screen readers get « 3, 2, 34e minute ».

## Do / Don't
- Do keep Volt for the winner's score only — one bright mark per card.
- Do keep numbers unmirrored in RTL; each score stays next to its team.
- Don't show a winner while the match is live.

## Props (web preview)
`variant` · `sport` · `round` · `court` · `competition` · `status` · `start` · `minute` · `teams` (`name`, `shortName`, `monogram`, `score`, `sets`) · `currentSet` · `target` · `href` · `onOpen` · `skeleton` · `state`. See `index.d.ts`.

## Flutter
`MuMatchCard(match: MuMatch, variant: MuMatchCardVariant.standard, onTap:, loading:)` — `MuCardSurface` with a `Table`/`Row`-based board (`IntrinsicColumnWidth` for monogram and scores, `FlexColumnWidth` for names); the live set column is a `DecoratedBox` behind the column; animate score changes with `AnimatedSwitcher` (`duration-counter`).
