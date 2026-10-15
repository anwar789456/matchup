# SearchField

The pill search bar with a magnifier, clear and filter buttons, opening a panel of recent searches and grouped suggestions — Terrains, Joueurs, Parties — with the match highlighted.

## When to use
- Explorer (mobile, L) and the desktop top bar (M): one entry point to find a venue, a player or an open game.
- To narrow a list already on screen, use filter Chips; to pick a value in a form, use Select.

## Anatomy & specs
| Size | Height | Padding (start) | Value style |
|---|---|---|---|
| L | `control-l` 48 | `space-4` | `body-l` |
| M | `control-m` 40 | `space-3` | `body` |

- Pill box: `radius-full`, `surface`, 1px `border-control`; `magnifying-glass` 20 in `text-secondary`; clear `x-circle` (fill) IconButton S; optional filter IconButton S `sliders-horizontal` after a 1px `border` divider, with a Volt count (`accent` / `on-accent`, `label-s`).
- **Panel**: `space-1` below the box, full width, `surface-elevated`, `elevation-2`, `radius-lg`, padding `space-2`, max 420 high then scrolls; animates in with `duration-base` `ease-enter`.
- **Group header**: `overline` in `text-secondary`; groups separated by a 1px `border` rule.
- **Rows** ≥ 44 (`touch-target`), `radius-sm`, padding `space-2` `space-3`, `space-3` gaps:
  - recent — `clock-counter-clockwise`, query (`body`), remove ✕ (IconButton S);
  - Terrains — 40 sport tile (`<sport>-soft` + `<sport>-text` icon), name (`label`), « Football · La Marsa » (`caption`);
  - Joueurs — Avatar S, name, « 4,2 (`num-xs`) · Avancé · Lac 2 »;
  - Parties — sport tile, « Foot 5 · Arena Five », « jeu. 16 oct. · 2 places · 15 DT/pers. », time « 20h00 » in `num-s` at the end.
- **Match highlight**: a Volt marker (`accent` fill, `on-accent` text, `radius-xs`) on the matched letters, in titles and places.

## States
- Default, hover, focus (2px `focus` + `focus-ring`), disabled (« Recherche indisponible hors ligne »).
- Focus with an empty query → recent searches (« Tout effacer » in the header). Typing → suggestions, up to 3 per group.
- Highlighted row (hover or ↑ ↓): a wash of the text colour at `opacity-hover`.
- **No result**: magnifier in a 48 circle, « Aucun résultat pour “padle” », a hint (« Vérifie l’orthographe ou cherche un quartier, un terrain ou un joueur. ») and one helpful action (« Rechercher “padel” », « Voir les terrains près de moi »).

## Content
- Placeholder names what can be found: « Terrain, joueur, partie… » (« Rechercher un joueur, un terrain… » on desktop).
- Groups are plural nouns: Terrains, Joueurs, Parties. Matching ignores case and accents (« ennasr » finds « Ennasr »).
- Game rows always carry time, spots left and price per person.

## Accessibility
- The input is a `combobox` (`aria-expanded`, `aria-controls`, `aria-autocomplete="list"`, `aria-activedescendant`); the panel is a `listbox` of `group`s and `option`s.
- Keys: ↑ ↓ move, Entrée opens the row (or searches), Échap closes then clears, Suppr. removes a highlighted recent search.
- Search is the one field whose label may be visually hidden: the magnifier and placeholder carry it; the label « Rechercher » stays as its accessible name.
- The filter button says its state: « Filtres, 2 actifs ».

## Do / Don't
- Do keep recent searches personal and removable one by one.
- Do end every empty state with an action.
- Don't show more than 3 rows per group — link to the full results page instead.
- Don't use Volt for anything in the panel other than the match marker.

## Props (web preview)
`label` · `showLabel` · `placeholder` · `size` · `value` / `defaultValue` / `onChange` · `recent` · `onRemoveRecent` · `onClearRecent` · `groups` · `filter` · `maxPerGroup` · `onSelect` · `onSubmit` · `onFilters` · `filterCount` · `emptyAction` · `disabled` · `open` · `activeIndex` · `state`. See `index.d.ts`.

## Flutter
`MuSearchField(controller:, recent:, groups:, onSelected:, onSubmitted:, onFilters:, filterCount:)` — a pill `TextField` (`StadiumBorder`) with `textInputAction: TextInputAction.search`. On mobile, focusing it pushes a full-screen search route (`SearchAnchor` view) that lists the same rows; on desktop, show the panel with `OverlayPortal` + `CompositedTransformFollower`. Debounce queries by 250 ms and highlight matches with `TextSpan`s.
