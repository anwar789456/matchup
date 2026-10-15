# Lineup

Who plays where in an open game — a 5 v 5 pitch, a padel 2 v 2 court or a basketball half-court — with each player on their position and every free position a dashed « + » you tap to join.

## When to use
- **Full** as the centrepiece of the game lobby (« Composition »): see both teams, pick a position, join.
- **Compact** inside game cards and lists: a 64-high court with one dot per position and « 8/10 ».
- Not for a team's member list (TeamCard) or a game without positions — show an AvatarStack and spots left instead.

## Anatomy & specs
| Sport | Court (w : h) | Positions per team, in order | Teams |
|---|---|---|---|
| `football` | 200 : 336, 5 v 5 | Gardien · Défenseur · Défenseur · Attaquant · Attaquant | A bottom half, B top (turned 180°) |
| `padel` | 200 : 300, 2 v 2 | Côté gauche · Côté droit | A bottom, B top (turned 180°) |
| `basketball` | 200 : 188, 3 v 3 half-court | Meneur · Ailier · Pivot | A left of the key, B right (mirrored) |

- **Header**: title `label-l` (« Composition »), min height `control-s`; counter « 8/10 » in `num-m` + « 2 places libres » `label-s` `text-secondary`, or a StatusBadge S « Complet » when full.
- **Court**: `<sport>` fill (the same in both themes, like a photo), `radius-md`, `elevation-1`; 2px `court-line` markings, padel glass and net, basketball paint.
- **Team tag**: pinned to its half — 24 high, `radius-full`, `surface`, `elevation-1`: `t-shirt` 14 (fill) in `text-secondary` · name `label-s` · « 4/5 » `num-xs` after a 1px `border-strong` rule.
- **Player**: Avatar with its level badge and a 2px `surface` ring; name pill `space-1` below — `label-s` on `surface`, `elevation-1`, max 96 with ellipsis. Organiser or captain: a 22px `surface-inverse` disc with `crown` (fill) at the avatar's top corner.
- **You**: a 3px `accent` ring outside a 2px `surface` gap, and the pill reads « Toi » in `on-accent` on `accent`.
- **Free position**: a ring the size of the avatar, 2px dashed `court-line`, `plus` 22 (L) or 18 in `court-line`; the pill shows the position in `text-secondary`, no shadow.
- **Avatar size**: football and padel L 56 when the court is ≥ 330 wide, else M 40; basketball M 40, else S 32. `avatarSize` overrides.
- **Compact**: court 64 high, `radius-sm`, no shadow, football and padel turned landscape; dots 10px `white` with a 1.5px `ink-900` ring, you in `accent`, free ones 1.5px dashed `court-line`; counter « 8/10 » `num-m` over « 2 places » or « Complet » `label-s`, `space-3` from the court.

## Variants
`full` · `compact`, each for `football` · `padel` · `basketball`.

## States
- **Free position** — hover: the ring turns solid with a `court-line` wash at 22 % and the `plus` scales 1.15 (`ease-pop`); pressed: ring scale 0.94, wash 32 %; focus: solid ring + `focus-ring`. All over `duration-fast`, `ease-enter`.
- **Joining**: the new player drops in (from 14px above at scale 0.6) over `duration-slow`, `ease-pop`, with a `court-line` ring bursting out over 2 × `duration-slow`. Players present on first render don't animate; nothing moves under reduced motion.
- **Already in**: free positions read « Passer à ce poste »; `onJoin` moves you.
- **Full**: no free position left, StatusBadge « Complet ».
- **Registrations closed** (`disabled`): free positions stay visible, rings at 60 %, and are not buttons.
- **Loading** (`skeleton`): a court-shaped Skeleton with one dot per position.

## Content
- Names are first name + initial: « Yassine B. »; levels « 4,2 »; the signed-in player reads « Toi ».
- Team names: kit colours (« Blancs », « Bleus ») or the defaults « Équipe A » / « Équipe B ».
- The counter says what is left: « 2 places libres », « 1 place libre », « Complet ».
- **Data**: `teams` = [team A, team B], each `{ name, players }`; `players` has one entry per position in the order above, `null` for a free one; a player is `{ name, level, src, role: 'organizer' | 'captain', you }`.
- `onJoin(team, slot, position)` gives both indexes and the position name — open the join-and-pay sheet there (« Rejoindre et payer · 15 DT »).

## Accessibility
- The court is a `group` named « Football 5 contre 5 — 8 joueurs sur 10 »; each team is a list named « Bleus, 4 joueurs sur 5 »; tags are decorative.
- A player reads « Défenseur : Mariem K., niveau 4,2, organisateur »; a free position is a button « Rejoindre ce poste — Attaquant, Blancs ».
- The button covers ring and pill, ≥ 44 high at every avatar size. Roles and « you » never rely on colour: crown + spoken role, ring + « Toi ».
- Compact is a single `img`: « Football 5 contre 5 : 8 joueurs sur 10, 2 places libres ».
- The court is a drawing: it never mirrors in RTL, and the tags stay pinned to their corners.

## Do / Don't
- Do keep free positions visible after registrations close — the gaps tell the story.
- Do go through payment from `onJoin`; a tap never joins silently.
- Don't recolour courts by theme or use Volt for anyone but the signed-in player.
- Don't make the compact court a control — the card around it opens the lobby.

## Props (web preview)
`sport` · `teams` · `variant` · `title` · `onJoin` · `disabled` · `skeleton` · `avatarSize` · `showCounter` · `slotState` (preview only). See `index.d.ts`.

## Flutter
`MuLineup(sport: MuSport.football, teams: [MuLineupTeam(name: 'Blancs', players: [...])], variant: MuLineupVariant.full, onJoin: (team, slot, position) => …, disabled: false, loading: false)` — an `AspectRatio` + `LayoutBuilder` `Stack`: a `CustomPaint` court on the same 200-unit geometry, then each position `Positioned` at its fraction of the court and centred on the avatar. Free positions are an `InkWell` with a dashed `CustomPaint` ring in `Semantics(button: true, label: …)`; the drop-in is a `TweenAnimationBuilder` on `Cubic(0.34, 1.56, 0.64, 1)` (`ease-pop`). Wrap the court in `Directionality(textDirection: TextDirection.ltr)` so it never mirrors.
