# ReliabilityBadge

« Fiable 96 % » — the share of games a player honoured, toned by score and always written as a number.

## When to use
- Next to a player wherever trust matters: join requests, lineups, player sheets, admin user tables (size S).
- **Detail** on the profile and the player sheet: « 48/50 matchs honorés » with a 4px bar.
- Add a **tooltip** where people meet the score for the first time — it explains how it is computed.

## Anatomy & specs
| Size | Height | Padding (inline) | Icon | Text |
|---|---|---|---|---|
| S | 20 | 6 / `space-2` | 14 | `label-s` « Fiable » + `num-xs` « 96 % » |
| M | 24 | `space-2` / 10 | 16 | `label-s` « Fiable » + `num-xs` « 96 % » |

- Pill `radius-full`, gap `space-1`, icon in its fill weight.
- Detail (min 220px, rows `space-2` apart): badge + period `caption` `text-secondary` on one row; a 4px track (`border`, `radius-xs`) filled in the tone; « 48/50 » `num-s` + « matchs honorés » `body` `text`.

## Variants
| Score | Tone | Fill / text | Icon | Detail bar |
|---|---|---|---|---|
| ≥ 90 % | success | `success-soft` / `success-text` | `shield-check` | `success` |
| 75–89 % | neutral | `surface-muted` + 1px `border` / `text-secondary` | `shield-check` | `text-secondary` |
| < 75 % | warning | `warning-soft` / `warning-text` | `shield-warning` | `warning` |

## States
- Default · focus (`focus-ring`) — only when it carries a tooltip: it then becomes focusable (`tabindex="0"`, help cursor).
- The tooltip opens after 400 ms of hover or at once on keyboard focus; Esc closes it (see Tooltip).

## Content
- Always « Fiable NN % », narrow no-break space before %. The tone comes from the rounded number shown, so text and colour always agree.
- Detail: « 48/50 matchs honorés » and the period « 12 derniers mois ».
- The tooltip says the rule and how to improve: « Un désistement à moins de 24 h compte comme une absence. »
- Hide the badge until a player has 5 counted games — « Fiable 100 % » on one game is misleading.

## Accessibility
- The words and number carry the meaning; colour and icon only reinforce it (status is never colour alone).
- Tone text is ≥ 4.5:1 on its soft fill in both themes.
- The detail bar is a `progressbar` named « Matchs honorés » (« 48 sur 50 »).
- With a tooltip the trigger gets `aria-describedby` pointing to the explanation.

## Do / Don't
- Do let admins sort user tables by reliability (size S).
- Do explain the warning tone with what to do next.
- Don't shame: never « Pas fiable » or red — the lowest tone is warning.
- Don't show it alone as a colour dot on avatars.

## Props (web preview)
`score` · `honored` · `total` · `variant` · `size` · `tooltip` · `period` (+ HTML attributes and `ref`). See `index.d.ts`.

## Flutter
`MuReliabilityBadge(score: 96, size: MuBadgeSize.m, detail: false, honored: 48, total: 50, tooltip: '…')` — a `StadiumBorder` `Container` with `PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill)` and a `Text.rich` (`MuType.labelS` + `MuType.numXs`); wrap it in `MuTooltip` when explained. Detail is a `Column` with a 4px `ClipRRect` + `FractionallySizedBox` bar and `Semantics(value: '48 sur 50')`.
