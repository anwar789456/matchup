# Bracket

A tournament tree — single elimination, or group tables feeding a knockout — on a zoom-and-pan canvas on desktop and one round per column on mobile, with the live match ringed and your team in Volt.

## When to use
- The tournament's « Tableau »: follow results, see who you meet next, when and on which court.
- **canvas** on desktop (players and organisers): the whole tree, zoom and pan. **rounds** on phones: round tabs and one swipeable column per round.
- Not for a single match (Scoreboard) or a fixtures list (MatchCard).

## Anatomy & specs
| Part | Spec |
|---|---|
| Card | `mu-card`, padding `space-5`, gap `space-4`; title `h3` + subtitle `body` `text-secondary`; tools: zoom pill (IconButton S − / +, « 94 % » `num-xs`, 1px `border-strong`, `radius-full`) + Button S secondary « Ajuster » (`frame-corners`) |
| Viewport | `height` (default 560), `radius-md`, `bg` with a `border-strong` dot grid that scales with zoom, 1px `border`; opens fitted, never above 100 % |
| Round header | name `overline` + date `caption` `text-secondary` |
| Match | 232 wide; meta line: label `caption` (« QF 1 ») + « Ton équipe » pill · status at the end; card `surface`, `radius-sm`, `elevation-1` + 1px `border` |
| Team row | 36 high: seed box 22 (`radius-xs`, `surface-muted`, `num-xs`) · name `body` (winner `label`) · score `num-m` |
| Rhythm | columns 72 apart, matches 24 apart, canvas padding 32 |
| Wires | 1.5px `border-strong`, turns rounded up to 8px; dashed 4 / 4 while the feeding match is undecided |
| Champion | 196 × 128, `radius-md`: 48 trophy disc (`surface-muted`, then `accent` + `on-accent` once decided), name `label-l`, « Finale 20h00 » `caption` before |
| Group table | 448 wide, 112 before the knockout; « Poule A » `label-l` + « 3 journées sur 3 » `caption`; columns # · Équipe · J · V · D · Diff. · Pts in `label-s`, values `num-s`, rows 36 |
| Legend | Ton équipe · En direct · Qualifié · À jouer, in `caption` |

- **rounds**: a full-width SegmentedControl of the round short names; columns `100 % − space-10` wide (the next one peeks), scroll-snapped, `space-4` apart; each pair is bracketed by a 1.5px `border-strong` connector; the champion card closes the final column. No card surface.

## Variants
`canvas` · `rounds`; single elimination (`rounds` only) · groups + knockout (`groups` + `rounds`).

## States
- **Upcoming**: `clock` 14 + « 21h00 · Terrain 1 » `caption`; an undecided team shows its placeholder (« Vainqueur QF 4 ») in `text-secondary` with a dashed seed box.
- **Live**: a 2px `live` ring around the card; pulsing `live` dot + « EN DIRECT » `overline` in `error-text` + minute `num-xs`.
- **Final**: « Terminé », or the note (« t.a.b. 4–3 »); the loser's row in `text-secondary`. Final is inferred when both scores are set; `live` is always set explicitly.
- **Your team**: Volt seed box, the row tinted `accent` at 22 %, « Ton équipe » pill (`accent`, `on-accent`, `label-s`).
- **Groups**: qualified rows in `text` with `check-circle` 16 + « Qualifié » in `success-text`, the others `text-secondary`; a dashed `border-strong` rule marks the cut.
- **Navigate**: drag pans (grab cursor); − / + and Ctrl/⌘ + wheel zoom between 40 % and 160 % (buttons disable at the limits); « Ajuster » refits.
- **Empty**: EmptyState « Le tableau arrive bientôt » · « Il sera publié à la clôture des inscriptions. Tu recevras une notification. » + optional `emptyAction`. **Loading**: Skeleton blocks on the same geometry.

## Content
- Rounds « Quarts de finale », « Demi-finales », « Finale » (tabs « Quarts », « Demies », « Finale »), dates « sam. 18 oct. »; matches « QF 1 », « Demie 2 ».
- Live minute « 34’ » (football) or clock « 6:12 » (basket); difference « +19 », « −7 » with a true minus; seeds 1–8 or « A1 », « B2 ».
- **Data**: `rounds` = `{ name, short, date, matches }`; a match is `{ label, status, teams: [team | null, team | null], placeholders, winner, note, minute, time, court }`, a team `{ name, seed, score, you }`. Matches 0 + 1 feed the next round's match 0, 2 + 3 feed match 1…; `winner` settles a draw on penalties.
- `groups` = `{ name, note, rows: [{ team, played, won, lost, diff, points, qualified, you, seed }] }`; `rounds[0].feeds` overrides the default A1–B2, B1–A2 wiring.

## Accessibility
- The canvas is a focusable `region` (« canevas ») whose name explains the keys: arrows pan 48px, + / − zoom, 0 fits; the zoom value is `aria-live`.
- Each match is a `group` named in full — « QF 4 : Sousse Kickers 1 contre Gammarth FC 2, en direct, 34’ », with « ton équipe joue » when it is yours. Group tables are real tables with `abbr` headers (« J » = Joués).
- Live is dot + words, your team is pill + tint, winners are weight + score — never colour alone. Zoom buttons have 44 hit areas.
- In RTL the tree runs right to left and the wires mirror; scores and seeds don't.

## Do / Don't
- Do give every upcoming match its time and court.
- Do switch to `rounds` on phones; a pinch-zoom canvas is not a mobile pattern.
- Don't colour teams or rounds; Volt marks only your team and the decided trophy.
- Don't show an empty tree before the draw — use the empty state.

## Props (web preview)
`rounds` · `groups` · `layout` · `height` · `title` · `subtitle` · `defaultRound` · `legend` · `skeleton` · `emptyTitle` · `emptyDescription` · `emptyAction`. See `index.d.ts`.

## Flutter
`MuBracket(rounds: [...], groups: [...], layout: MuBracketLayout.canvas, height: 560)` — canvas: `InteractiveViewer(constrained: false, minScale: 0.4, maxScale: 1.6, transformationController: …)` over a `Stack` laid out from the same constants (232 · 36 · 72 · 24 · 32), wires in a `CustomPainter` (dashed when pending); « Ajuster » sets the fit matrix. rounds: `MuSegmentedControl` synced with a `PageView(viewportFraction: ≈ 0.9)`. Each match in `Semantics(label: …)`, group tables as `Table`.
