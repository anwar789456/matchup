# AvatarStack

Overlapping avatars that show who's in — the first few faces, then « +N » — on game, booking and event cards.

## When to use
- Card footers next to a caption: « 8 inscrits », « 10 inscrits » (XS).
- List and team rows (S), lobbies and game-detail headers (M).
- Grouped notifications: « Yassine et 3 autres ont rejoint ta partie ».
- Not when each name matters (lineup, roster, payments) — list people with Avatar and name.

## Anatomy & specs
| Size | Avatar | Overlap | Typical place |
|---|---|---|---|
| XS | 24 | −6 | cards |
| S (default) | 32 | −8 | lists |
| M | 40 | −10 | lobby, detail header |

- Each avatar has a 2px `surface` ring and one initial; later avatars sit on top of earlier ones.
- `max` (default 4) avatars, then « +N »: a circle of the same size in `surface-muted` with a 1px `border` ring inside the 2px `surface` ring, `label-s` in `text`.
- Avatars appear in the order of `people`: put the organiser first.

## States
Static. When someone joins or leaves, the stack and the « +N » update in place.

## Content
- Pair it with a count in text — « 8 inscrits » — which the stack never replaces.
- « +3 » counts the people not shown, never the total.

## Accessibility
- `role="group"` named by `label` (default « 8 joueurs »); pass the meaning, e.g. « 8 inscrits ». Avatars inside keep their names; « +N » is hidden.
- Ring and overlap are visual only; the order read is the order of `people`.
- Initials contrast 11.9:1 (Light), 8.7:1 (Night match); « +N » `text` on `surface-muted` ≥ 14.5:1.

## Do / Don't
- Do let the caption disappear before the stack shrinks in tight footers (GameCard does).
- Do keep one size per stack.
- Don't show more than five faces; the rest is « +N ».
- Don't make the stack a tap target without a name — wrap it in a link « Voir les 8 joueurs ».

## Props (web preview)
`people` (`name` · `src`) · `max` · `size` · `label`. See `index.d.ts`.

## Flutter
`MuAvatarStack(people: [...], max: 4, size: MuAvatarSize.xs, semanticLabel: '8 inscrits')` — a `Row(mainAxisSize: MainAxisSize.min)` of `MuAvatar(ring: true, short: true)`, every child but the last wrapped in `Align(alignment: AlignmentDirectional.centerStart, widthFactor: (size − overlap) / size)` so later avatars paint over earlier ones; the « +N » bubble is the last child. The `Row` follows `Directionality`, so RTL starts on the right. Wrap it in `Semantics(container: true, label:)`.
