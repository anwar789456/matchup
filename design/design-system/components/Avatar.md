# Avatar

A person as a photo or initials, in five sizes, with an optional Volt level badge on the 1,0–7,0 scale and an online dot.

## When to use
- Wherever a player, coach or owner appears: list rows and comments (S), notifications and the top bar (M), lineups and coach cards (L), the profile header (XL), stacks in cards (XS, through AvatarStack).
- **Level badge** where level drives a decision: lineups, join requests, suggested players.
- **Online dot** in chats and team lists only.

## Anatomy & specs
| Size | Diameter | Initials | Level badge (min) |
|---|---|---|---|
| XS | `avatar-xs` 24 | `label-s`, one letter | not shown |
| S | `avatar-s` 32 | `label-s` | 24 × 18, `num-xs` |
| M (default) | `avatar-m` 40 | `label` | 24 × 18, `num-xs` |
| L | `avatar-l` 56 | `h3` | 26 × 18, `num-s` |
| XL | `avatar-xl` 96 | `h1` | 40 × 24, `num-s` |

- Circle (`radius-full`). Initials in `avatar-text` on `avatar-bg`; a photo covers the circle (`object-fit: cover`).
- Level badge: `accent` pill, `on-accent` digits, padding-inline 4, 2px `surface` ring, at the bottom-end (inline-end −6, bottom −4; XL: −4 and 2).
- Online dot: 25 % of the diameter, clamped to 8–16 px, `success`, 2px `surface` ring, at the top-end.
- `ring` adds a 2px `surface` ring for stacks and photos on busy grounds.

## States
Static. While a photo loads, the `avatar-bg` circle shows; if it fails, the initials replace it.

## Content
- Names as players show them — first name and initial: « Nour A. » → « NA »; XS and `short` use one letter (« N »).
- The level badge holds the value only, comma and one decimal: « 3,5 ». The band (« Intermédiaire ») goes in nearby text.

## Accessibility
- `role="img"` named from the props: « Nour A., niveau 3,5, en ligne ». Initials, badge and dot are hidden from assistive tech.
- Online is in the name, not only in the green dot.
- Initials contrast: 11.9:1 (Light), 8.7:1 (Night match); `on-accent` on `accent` 13.2:1.

## Do / Don't
- Do keep one size per list.
- Do keep the level badge Volt — it is a highlight, never a sport colour.
- Don't expect a level badge at XS; it isn't rendered.
- Don't replace missing photos with a generic silhouette — initials are the fallback.

## Props (web preview)
`name` · `src` · `size` · `level` · `online` · `ring` · `short` · `title`. See `index.d.ts`.

## Flutter
`MuAvatar(name: 'Nour A.', imageUrl:, size: MuAvatarSize.m, level: 3.5, online: false, ring: false)` — a `CircleAvatar` (radius = size / 2, `backgroundColor: avatarBg`, initials `Text` as `child`, `foregroundImage: NetworkImage(imageUrl)`, `onForegroundImageError` keeping the initials) inside a `Stack(clipBehavior: Clip.none)` with a `PositionedDirectional` level badge (end −6, bottom −4) and online dot (end 0, top 0). Wrap it in `Semantics(image: true, label: 'Nour A., niveau 3,5, en ligne', excludeSemantics: true)`.
