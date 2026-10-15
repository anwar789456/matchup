# IconButton

An icon-only action with a required accessible name — « Partager », « Filtres », « Plus d’actions » — in three sizes and five variants, with an optional badge or toggle state.

## When to use
- App bars, toolbars, card corners and table rows, when the icon is universally understood (`magnifying-glass`, `share-network`, `dots-three`, `x`).
- **Toggle** (`pressed`) for a binary icon action: favourite (`heart`), vote (`arrow-fat-up`).
- With a word it is a Button; when the state needs words (« Suivre » / « Suivi »), use ToggleButton.

## Anatomy & specs
| Size | Visual | Hit area | Icon |
|---|---|---|---|
| S | `control-s` 32 | `touch-target` 44 (invisible) | 18 |
| M (default) | `control-m` 40 | 44 (invisible) | 20 |
| L | `control-l` 48 | 48 | 24 |

- Circle (`radius-full`) with a 1px border slot, transparent except on secondary.
- **Badge**: 18 high, min-width 18, padding-inline 5, `radius-full`, `label-s` in `on-destructive` on `destructive`, 2px `surface` ring, on the top-end corner (top −2, inline-end −4); caps at « 99+ ». `badge={true}` draws a 10 px dot inset 6 from the top-end. `badge={0}` draws nothing, so a cleared count disappears.

## Variants
| Variant | Fill | Icon | Edge | Use |
|---|---|---|---|---|
| ghost (default) | transparent | `text` | — | bars, rows, card corners |
| secondary | `surface` | `text` | 1px `border-strong` | standalone tools (« Filtres ») |
| primary | `primary` (ink · Volt in Night match) | `on-primary` | — | the one creating action (« Créer une partie ») |
| inverse | `surface-inverse` | `text-inverse` | — | the QR code on booking cards |
| on-media | `surface` | `text` | `elevation-2` | over CourtArt and photos (« Ajouter aux favoris ») |
| toggle on | `accent` | `on-accent`, Fill weight | — | any variant with `pressed` |

## States
- **Hover**: a wash of the icon colour at `opacity-hover`; primary → `primary-hover`.
- **Pressed**: wash at `opacity-pressed` and scale 0.94 over `duration-fast`, `ease-enter`.
- **Focus**: `focus-ring`.
- **Toggle**: `aria-pressed`; on = `accent` fill and the Fill icon.
- **Disabled**: icon `text-disabled`, no wash, no press.

## Content
- `label` is the verb a Button would use: « Partager », « Modifier », « Supprimer », « Afficher le QR code ».
- Put the badge's meaning in the label: « Notifications, 3 non lues ». The badge itself is hidden from assistive tech.

## Accessibility
- `label` is required: it becomes `aria-label` and the tooltip (`title`).
- Hit areas: S grows 6 px on every side and M 2 px, so space S buttons at least `space-3` apart and M `space-1` to keep targets from overlapping.
- Toggles keep one name in both states (« Favori », « Voter pour ») and let `aria-pressed` announce the state; don't swap « Ajouter » / « Retirer ».
- Icons reach ≥ 3:1 on every fill; `on-accent` on `accent` 13.2:1; badge digits 5.4:1.

## Do / Don't
- Do default to ghost; use at most one primary IconButton per view.
- Do use `arrow-left` for back — it mirrors in RTL by itself.
- Don't use an IconButton for an action nobody can guess from the icon; use a Button with a label.
- Don't badge things that don't need the player (counts of content, totals).

## Props (web preview)
`icon` · `label` · `size` · `variant` · `badge` · `pressed` · `weight` · `disabled` · `state`. See `index.d.ts`.

## Flutter
`MuIconButton(icon: PhosphorIcons.shareNetwork(), label: 'Partager', onPressed:, size: MuIconButtonSize.m, variant: MuIconButtonVariant.ghost, badge: 3, pressed:)` — Material 3 `IconButton` with `tooltip: label`, `style: IconButton.styleFrom(fixedSize: Size.square(40), shape: CircleBorder(), tapTargetSize: MaterialTapTargetSize.padded)`, and `isSelected` + `selectedIcon` (Fill) for toggles. Wrap the icon in `Badge(label: Text('3'), backgroundColor: destructive)` (`Badge(smallSize: 10)` for the dot) and press with `AnimatedScale(0.94)`.
