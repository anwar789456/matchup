# Scoreboard

The match header — the score in large Barlow Condensed numerals, the « EN DIRECT » minute, padel sets and the current game, the basketball race to 21 and a timeline of the match's moments — with a compact strip for cards.

## When to use
- **Full** at the top of a live or finished match, a tournament match page and the organiser's scoring screen.
- **Compact** inside game and tournament cards: one line, two for padel.
- Not for the whole tournament (Bracket) or a list of fixtures (MatchCard).

## Anatomy & specs
| Part | Spec |
|---|---|
| Card | `mu-card` with a radial wash from `surface-elevated` (top) to `surface`; padding `space-5` (bottom `space-6`), sections `space-5` apart |
| Status line | live: `live` dot + « EN DIRECT » `overline` in `error-text` + clock `num-s` + period `caption` `text-secondary` · final: `flag-checkered` 16 + « Terminé » `label-s` + « · jeu. 16 oct. » · upcoming: `clock` 16 + « À venir » + « · 20h00 »; venue `map-pin` 14 + `caption` at the end |
| Teams | crest shield 56 × 64 with a 2–3 letter monogram in `label-l` — home solid `surface-inverse`, away `surface-muted` + `border-strong` (two kits); name `label-l`, 2 lines max; tag « Ton équipe » (`accent`, `on-accent`) or « Vainqueur » (`surface-inverse`, trophy 14) in `label-s` |
| Score | `score` (48/48) with a `text-secondary` dash, `space-2` apart, over a 1.5px `border` court watermark; upcoming: kickoff `num-l` + « Coup d’envoi » `caption` |
| Padel | « SET 1 » `overline` headers; set cells `num-l` in 36 columns, the current set in a `surface-muted` box; « JEU » tile 64 × 56 on `surface-inverse` with the points in `score`; players one per line in `label`; serve: 12px `accent` dot with a 1.5px `on-accent` ring |
| Basketball | two 8px meters (`basketball` on `surface-muted`, 1px `border`) growing outward from « Premier à 21 » `caption`; `target` defaults to 21 |
| Timeline | `border` hairline above and a 1px spine in the centre; home events left, away right; minute pill `num-xs` in a 1px `border-strong` ring; 28 icon disc on `surface-muted`; label `label` + player `caption`; neutral events as centred `surface-muted` chips (« Mi-temps 2 – 1 ») |
| Compact | `surface-muted`, 1px `border`, `radius-sm`, min 48, padding `space-2` `space-3`: state (`live` dot + « EN DIRECT » `overline` + minute `num-xs`, both `error-text`; or « Terminé » / « À venir » `label-s`) · home · score `num-m` · away; padel: two rows, sets `num-s` in 20 columns, the game in a `surface-inverse` cell, 8px serve dot |

## Variants
`full` · `compact`, for `football` · `padel` · `basketball`, in `upcoming` · `live` · `final`.

## States
- **Live**: a changed number rolls — the old one slides out, the new one in — over `duration-counter` (600 ms), `ease-move`, downward when a score is corrected. On the full football and basketball board it also flashes in `accent` / `on-accent` for 2 × `duration-counter`. The newest event fades up over `duration-base`, `ease-enter`. Under reduced motion values just change.
- **Final**: loser name, crest (55 %) and score in `text-secondary`; « Vainqueur » tag; padel lost sets in `text-secondary` and a trophy 20 beside the winning pair. A draw has no winner.
- **Upcoming**: kickoff time instead of the score.
- **Loading** (`skeleton`): two crest circles, a score block and three text lines; compact is one bar.

## Content
- Events: « But », « Panier », « Tir à 2 pts », « Break », « Set », « Carton jaune », « Temps mort », « Remplacement », « Mi-temps », « Coup d’envoi », « Fin du match »; `label` overrides.
- Clock « 34’ » with a typographic apostrophe, basket « 6:12 »; period « 2e mi-temps », « Set 3 »; neutral scores « 2 – 1 ».
- Padel pairs « Mariem K. / Lina F. »; venue « Arena Five · Terrain 2 »; final date « jeu. 16 oct. ».
- **Data**: `teams` = [home, away], each `{ name, short, players, you }`; `score` = [home, away] goals or points; padel `sets` = [[6, 4], [3, 6], [5, 3]] (the last is live), `game` = ['40', '30'], `serving` = 0 | 1; `events` newest first, `{ minute, type, team: 0 | 1 (omit for neutral), player, label, score }`.

## Accessibility
- A visually hidden `aria-live="polite"` line announces « En direct, 34’. FC La Marsa 3, Lac 2 United 2 »; the drawn board is hidden from screen readers.
- The timeline is an ordered list « Temps forts », one sentence per item: « 33’ But — Hamza R. (FC La Marsa) ». Meters are `role="meter"` (« Ennasr Ballers : 17 points sur 21 »); the padel board is a `table`.
- Live = pulsing dot + « EN DIRECT » on both the full board and the compact strip; the strip's accessible name starts with « En direct ».
- Winners are shown by weight, tag and trophy, not colour alone. Digits never mirror; in RTL the home side moves to the right with its score.

## Do / Don't
- Do pass `you` so players find their side at a glance.
- Do send the whole event list on every update, newest first.
- Don't use sport colours on the board beyond the basketball meters — teams are not sports.
- Don't add a second live badge around the card; the status line carries it.

## Props (web preview)
`sport` · `status` · `teams` · `score` · `sets` · `game` · `serving` · `clock` · `period` · `target` · `events` · `venue` · `kickoff` · `date` · `variant` · `skeleton`. See `index.d.ts`.

## Flutter
`MuScoreboard(sport: MuSport.football, status: MuMatchStatus.live, teams: [...], score: (3, 2), clock: '34’', period: '2e mi-temps', events: [...], variant: MuScoreboardVariant.full)` — `MuCardSurface` + `Column`; each number in an `AnimatedSwitcher(duration: 600 ms)` with a vertical `SlideTransition` on the `ease-move` curve; crests as a `CustomPaint` shield; the padel board a `Table`; the timeline a `Column` of three-slot `Row`s around a centred divider. Wrap the status text in `Semantics(liveRegion: true)`.
