# Icon

The one icon component: Phosphor Icons (MIT) Regular at a 1.5px stroke on 24, Fill for selected states, plus six MatchUp sport icons drawn on the same grid.

## When to use
- **Regular** by default: app bars, list rows, inputs, buttons and meta lines (`map-pin` « La Marsa · 2,4 km », `clock` « 20h00 »).
- **Fill** only for "this one is on": the active tab in the Volt pill, a toggled IconButton or ToggleButton, the selected segment, the Fab sparkle and the icons inside StatusBadge.
- **Sport icons** wherever a sport is named or colour-coded: `sport-football`, `sport-padel`, `sport-basketball`. `sport-whistle` marks the coach role and match events (« Coup d’envoi », « Mi-temps »), `sport-trophy` tournaments and winners, `sport-court` venues and the court-owner role.
- Not for illustration (EmptyState art) or imagery (CourtArt).

## Anatomy & specs
| Size | Token | Stroke | Use |
|---|---|---|---|
| 16 | `icon-xs` | 1 | badges, S chips, inline meta |
| 20 | `icon-s` | 1.25 | buttons, chips, inputs, dense rows |
| 24 (default) | `icon-m` | 1.5 | app bars, tab bar, list leading icons |
| 32 | `icon-l` | 2 | sport tiles, desktop notification circles, empty-state badges |

- Every icon sits on a 256 `viewBox` with a 16-unit round stroke, so Phosphor and sport icons match at every size.
- Colour is `currentColor`: `text` by default, `text-secondary` for inactive and meta icons, `<sport>-text` on `<sport>-soft`, status `-text` roles, `on-accent` on Volt, `on-primary` on primary.
- Sport icons have one weight; `weight="fill"` applies to Phosphor only.
- The bundle holds the Phosphor names listed in `src/icons/*.json` (286 today). Add one by listing an existing Phosphor name there and running `tools/icons.mjs`; an unknown name renders an empty square and warns in the console.

## Variants
`regular` (default) · `fill`. Directional icons mirror automatically in RTL: `arrow-left`, `arrow-right`, `caret-left`, `caret-right`, `caret-double-left`, `caret-double-right`, `arrow-up-right`, `arrow-square-out`, `arrow-u-up-left`, `arrow-bend-up-left`, `arrow-line-up-right`, `sign-in`, `sign-out`, `door-open`, `paper-plane-right`, `list-bullets`, `list-numbers`, `sidebar-simple`. `mirror` forces or prevents it.

## States
An icon has no state of its own; its parent sets colour and weight. Selected → Fill in `on-accent`; disabled → `text-disabled`, like its label.

## Content
- Keep one meaning per icon. The tab icons set the vocabulary: `house` Accueil, `compass` Explorer, `calendar-check` Mes matchs, `barbell` Entraînement, `users-three` Communauté.
- Put a word next to an icon in navigation and actions. Icon-only is for universal actions with an accessible name: « Rechercher », « Partager », « Plus d’actions ».
- A sport colour always travels with its sport icon.

## Accessibility
- Decorative by default (`aria-hidden`). Pass `label` when the icon alone carries meaning (`sport-trophy` « Vainqueur »): it becomes `role="img"` with that name.
- Meaningful icons need 3:1 against their ground: `text-secondary` ≥ 5.1:1, `<sport>-text` ≥ 4.6:1 on `<sport>-soft`. Never Volt icons on light grounds (1.3:1).
- Never mirror numbers, scores, media controls or maps; `mirror={false}` keeps a directional icon that shows a real-world direction.

## Do / Don't
- Do use Fill only for a selected or status state, never for emphasis.
- Do use the MatchUp sport icons, not Phosphor's `soccer-ball` or `basketball`.
- Don't tint icons in sport colours outside sport categorisation.
- Don't draw one-off glyphs: pick a Phosphor name first; add a sport icon only in `tools/sport_icons.py`, on the same grid and stroke.

## Props (web preview)
`name` · `size` · `weight` · `label` · `mirror`, plus any SVG attribute. See `index.d.ts`.

## Flutter
`MuIcon('calendar-check', size: 24, weight: MuIconWeight.regular, semanticLabel:)` — Phosphor through the `phosphor_flutter` package (`PhosphorIcons.calendarCheck()`, `PhosphorIcons.house(PhosphorIconsStyle.fill)`) rendered by `Icon`, coloured from `IconTheme`. The six sport icons ship as SVG assets exported by `tools/sport_icons.py` (`football.svg`, `padel.svg`, `basketball.svg`, `whistle.svg`, `trophy.svg`, `court.svg`) and render with `SvgPicture.asset` (flutter_svg) and `ColorFilter.mode(IconTheme.of(context).color!, BlendMode.srcIn)`. Flip the directional list with `Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl)`.
