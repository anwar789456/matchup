# Counter

A small count pill for unread and pending items on bells, tabs, filters and nav items — capped at « 99+ » — or a 10 px dot when only "something new" matters.

## When to use
- Items waiting for the player or owner: invitations, unread messages, unpaid shares, requests to answer.
- **Dot** when the number doesn't matter: a new message thread, a new post in Communauté.
- Not for totals of content (« 248 parties » is text), not for status (StatusBadge), not on an IconButton (it has its own `badge`).

## Anatomy & specs
| Part | Spec |
|---|---|
| Pill | 20 high, min-width 20 (a circle for one digit), padding-inline 6, `radius-full`; digits in `label-s` |
| Dot | 10 × 10, `radius-full`, with a 2px `surface` ring so it reads on top of icons |
| Cap | above `max` (default 99) it shows « 99+ »; a value of 0 or none renders nothing |

## Variants
| Tone | Fill | Text | Use |
|---|---|---|---|
| alert (default) | `destructive` | `on-destructive` | the player has something to do |
| neutral | `surface-inverse` | `text-inverse` | informative counts that need no action |
| accent | `accent` | `on-accent` | on or next to a selected item |
| muted | `surface-muted` + 1px `border` ring | `text-secondary` | secondary counts in sidebars and tabs |

## States
Static; the number updates in place. At 0 the Counter disappears — never show « 0 ».

## Content
- Digits only, no words inside: « 3 », « 12 », « 99+ ».
- Count what needs attention, not what exists.

## Accessibility
- The pill is announced with `label` (default « 3 non lus »); pass a precise one: « 2 invitations », « 3 messages non lus ».
- When the parent control's name already includes the count (« Mes matchs, 2 invitations »), wrap the Counter in an `aria-hidden` element so it isn't read twice.
- The dot is `role="status"` only when it has a `label` (« Nouveau »); without one it is invisible to assistive tech, so its parent must say it.
- `on-destructive` on `destructive` 5.4:1; `text-inverse` on `surface-inverse` 17.2:1; `on-accent` on `accent` 13.2:1; `text-secondary` on `surface-muted` ≥ 5.1:1.

## Do / Don't
- Do sit it at the top-end corner of an icon or right after a label — it follows the reading direction in RTL.
- Do keep alert red for "you have something to do".
- Don't put a Counter and a dot on the same item.
- Don't use a Counter as a decorative number or a score.

## Props (web preview)
`value` · `max` · `tone` · `dot` · `label`. See `index.d.ts`.

## Flutter
`MuCounter(value: 3, max: 99, tone: MuCounterTone.alert, dot: false, semanticLabel: '3 messages non lus')` — Material 3 `Badge` with `label: Text(value > max ? '$max+' : '$value', style: MuType.labelS)`, `largeSize: 20`, `smallSize: 10` for the dot, `padding: EdgeInsets.symmetric(horizontal: 6)`, and `backgroundColor` / `textColor` from the tone; return `SizedBox.shrink()` at 0. Draw the dot's 2px `surface` ring with a `DecoratedBox` border, and attach `Semantics(label:)` or `ExcludeSemantics` as above.
