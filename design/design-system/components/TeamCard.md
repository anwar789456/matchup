# TeamCard
A team — monogram on the sport tint, captain, record and average level on the scoreboard strip, members and the action that fits your role.

## When to use
- **Default** in « Équipes » search, a player's profile and tournament registration.
- **Compact** in lists of teams, invitations and brackets.
- For one-off games without a fixed squad, use GameCard.

## Anatomy & specs
| Part | Spec |
|---|---|
| Surface | `mu-card`, padding `space-4`, rows `space-3` apart |
| Monogram | 64 × 64, `radius-md`, `<sport>-soft`, initials `h3` `<sport>-text` (« Les Faucons de La Marsa » → « FM », articles skipped) |
| Identity | name `label-l` · sport Chip S + status badge · « Capitaine : Yassine B. · La Marsa » `caption` with a filled crown |
| Scoreboard strip | BILAN « 12 V · 3 D » (`num-l` digits, `num-m` letters, `text-secondary` dot) / « 80 % victoires » · NIVEAU « 3,8 » / « Intermédiaire » · EFFECTIF « 7/8 » / fill bar in `<sport>` |
| Footer | AvatarStack XS + « 7 membres » (hidden when the footer is ≤ 300) · Button M |
| Compact | min-height 88, padding `space-3`; monogram 40; name `label`; sport icon + « 7 membres · niv. 3,8 · La Marsa » `caption`; badge; record `num-m` at the end |

## Variants
`default` · `compact`.

## States
- **Open to members** — success badge « Recrute » (`user-plus`), primary « Rejoindre ».
- **Full** — StatusBadge full « Complète », secondary « Voir l’équipe ».
- **You're captain** — Volt badge « Capitaine » (crown), « Capitaine : toi », primary « Inviter » (`user-plus`).
- **Member** — success badge « Membre », secondary « Voir l’équipe ».
- **Focus** `focus-ring` · **Skeleton** same layout.

## Content
- Record as wins · draws · losses: « 12 V · 3 D », « 9 V · 1 N · 4 D »; win rate « 80 % victoires ».
- Level with one decimal and its band: « 3,8 · Intermédiaire ».
- Team names keep their articles on the card; only the monogram drops them.

## Accessibility
- The record reads « 12 victoires, 3 défaites »; the crown is decorative next to the word « Capitaine ».
- The monogram is decorative (the name is the heading); the fill bar is decorative next to « 7/8 ».

## Do / Don't
- Do show one action, chosen by role: join, invite or view.
- Do keep the monogram tint to the team's sport.
- Don't show « Rejoindre » on a full team.

## Props (web preview)
`variant` · `sport` · `name` · `monogram` · `place` · `captain` · `members` · `capacity` · `levelAvg` · `wins` · `losses` · `draws` · `status` · `youAreCaptain` · `onJoin` · `onInvite` · `onView` · `href` · `onOpen` · `skeleton` · `state`. See `index.d.ts`.

## Flutter
`MuTeamCard(team: MuTeam, variant: MuTeamCardVariant.standard, role: MuTeamRole.visitor, onJoin:, onInvite:, onView:, onTap:, loading:)` — `MuCardSurface` with `Row(MuMonogram(size: 64), Expanded(Column))`, the shared `MuScoreboardStrip`, and a footer `Row(MuAvatarStack, Spacer, MuButton)`.
