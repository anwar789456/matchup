# MultiSelect

A field that collects several values: removable chips in the trigger (+N when they overflow), and a popover with search, checkboxes, « Tout effacer » and « Appliquer ».

## When to use
- Several answers from a known list: neighbourhoods, available days, sports a coach teaches, filters on a dashboard.
- Up to 5–6 options that all fit on screen read better as filter Chips; free-form values need TagInput.

## Anatomy & specs
- **Trigger**: the TextField box (L 48 / M 40, `radius-sm`, `surface`, 1px `border-control`); inline padding drops to `space-2` (`space-1` in M) once chips are in.
- **Chips**: Chip `input` S (24, `label-s`, remove ✕) `space-1` apart — as many as fit on one line, then a « +N » pill (`surface-inverse` / `text-inverse`, `label-s`); the caret stays at the end.
- **Popover**: `space-1` below, same width, `surface-elevated`, `elevation-2`, `radius-lg`, padding `space-2`:
  - search box — the M field (40) with `magnifying-glass`, `space-2` above the list;
  - list — max 242 high so a half row hints the scroll; rows ≥ 44 with a 20 checkbox (`radius-xs`, 1.5px `border-control`; checked = `primary` fill and `on-primary` tick), label, optional count (`caption`, « 12 terrains »);
  - footer — 1px `border` rule, padding `space-3` `space-4`: « Tout effacer » (tertiary S) and « Appliquer (3) » (primary S).

## States
- Trigger: default, hover, focus, open (2px `focus`), filled, error, disabled (chips dimmed, no remove buttons).
- Ticking boxes edits a **draft**; « Appliquer » commits it, Échap or a press outside discards it. Removing a chip commits at once.
- Search filters as you type (accents ignored); with no match: « Aucun résultat pour “bizerte” ».
- Disabled options say why in their count slot (« Bientôt »).
- **Mobile**: opens as a bottom sheet with the search on top, a scrolling list and a sticky footer with « Tout effacer » and an XL « Appliquer ».

## Content
- Label names the set: « Quartiers », « Jours disponibles »; placeholder « Choisis tes quartiers ».
- « Appliquer (3) » shows how many will be applied; « Tout effacer » only clears the draft.
- Keep option labels short: chips truncate with an ellipsis at their maximum width.

## Accessibility
- The trigger is a `combobox` named by the label; its value is read as « 3 sélectionnés : La Marsa, Lac 2, Ennasr ».
- The list is `role="listbox"` with `aria-multiselectable`; options use `aria-selected`. The search box drives `aria-activedescendant`.
- Keys: ↓ Entrée Espace open; ↑ ↓ move; Entrée toggles; Ctrl/⌘ + Entrée applies; Échap discards; Retour arrière on the trigger removes the last value.
- Each chip's ✕ is a button: « Retirer La Marsa ».

## Do / Don't
- Do keep the selection visible as chips — never only « 3 sélectionnés ».
- Do order options by meaning (days of the week) or by popularity (busiest neighbourhoods first).
- Don't apply on every tick when each change reloads results; use the footer.
- Don't nest groups more than one level deep.

## Props (web preview)
`label` · `optional` · `helper` · `error` · `size` · `placeholder` · `options` (`value`, `label`, `description`, `icon`, `sport`, `count`, `disabled`) · `value` / `defaultValue` / `onChange(values)` · `maxChips` · `searchable` · `searchPlaceholder` · `noMatchText` · `disabled` · `open` · `query` · `state`. See `index.d.ts`.

## Flutter
`MuMultiSelect<T>(label:, options:, values:, onChanged:, searchable: true)` — the trigger is an `InputDecorator` holding a single-line `Row` of `MuChip.input`s; measure with a `LayoutBuilder` + `TextPainter` to decide how many fit before the « +N » pill. Desktop: `OverlayPortal` panel; compact: `showModalBottomSheet(isScrollControlled: true)` with a `TextField`, a `ListView` of `CheckboxListTile`s and a pinned footer. Keep the draft in local state until « Appliquer ».
