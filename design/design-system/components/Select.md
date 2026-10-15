# Select

A field-like trigger with a caret that opens a list of options — icons, descriptions, a check on the selected one, disabled options and group headers.

## When to use
- One choice among roughly 4 to 15 known options: sport, level, court, sort order, preferred time slot.
- 2–3 options visible at once read better as a SegmentedControl or choice Chips; several choices need MultiSelect; long or open lists need SearchField.

## Anatomy & specs
- **Trigger**: the TextField box — L 48 / M 40, `radius-sm`, `surface`, 1px `border-control` — with the selected option's icon, its label (`body-l` / `body`, ellipsis) or the placeholder in `text-secondary`, and `caret-down` 20 in `text-secondary` that turns 180° while open (`duration-base`, `ease-move`).
- **Popover**: `space-1` under the trigger, same width, `surface-elevated`, `elevation-2`, `radius-lg`, padding `space-2`, max 360 high then scrolls.
- **Option**: ≥ 44 high, padding `space-2` `space-3`, `radius-sm`; optional icon 20 (sport icons in `<sport>-text`), label, description (`caption`, `text-secondary`), trailing content (price per person in `num-s`), and a `check` 20 when selected (label semibold).
- **Group header**: `overline`, `text-secondary`; groups divided by a 1px `border` rule.

## States
- Trigger: default, hover (`text-secondary` border), focus (2px `focus` + `focus-ring`), open (2px `focus`), filled, error (`error` border + message), disabled (`disabled-fill`, caret `text-disabled`).
- Option: highlighted (hover or keyboard) gets a wash of the text colour at `opacity-hover`; selected shows the check; disabled options are `text-disabled`, skipped by the keyboard and say why (« Complet ce soir »).
- **Mobile**: below 600 px the options open in a bottom sheet (`radius-lg` top corners, `elevation-3`, drag handle, title = label) with the same rows at 56 high; the choice applies on tap and closes the sheet.

## Content
- Label names the value: « Sport », « Ton niveau », « Terrain ». Placeholder starts with a verb: « Choisis un sport ».
- Option labels are short and parallel; put the detail in the description: « Intermédiaire » · « Niveau 2,5 à 3,9 · tu joues chaque semaine ».
- Order by meaning (levels low → high, slots by time), else alphabetically. Show price per person when options cost money.

## Accessibility
- Select-only combobox pattern: the trigger is `role="combobox"` with `aria-expanded`, `aria-controls`, `aria-activedescendant`; options are `role="option"` with `aria-selected` / `aria-disabled`, grouped in `role="group"`.
- Keys: ↓ ↑ Entrée Espace open; ↑ ↓ Début Fin move; letters jump (type-ahead); Entrée or Espace select; Échap closes; focus stays on the trigger.
- The label is clickable and names the trigger.

## Do / Don't
- Do pre-select a sensible default only when most players would pick it.
- Do explain disabled options instead of hiding them.
- Don't use a Select for yes/no — use a Switch or two choice Chips.
- Don't put actions (« Ajouter un terrain ») inside the list.

## Props (web preview)
`label` · `optional` · `helper` · `error` · `success` · `size` · `placeholder` · `options` (`value`, `label`, `description`, `icon`, `sport`, `group`, `disabled`, `trail`) · `value` / `defaultValue` / `onChange(value, option)` · `disabled` · `open` / `defaultOpen` / `onOpenChange` · `name` · `state`. See `index.d.ts`.

## Flutter
`MuSelect<T>(label:, options: [MuOption(value:, label:, description:, icon:, enabled:)], value:, onChanged:, placeholder:)` — the trigger is an `InputDecorator` styled like `MuTextField` inside an `InkWell`. On wide layouts open a `MenuAnchor` (or `DropdownMenu`) styled with `surface-elevated`, radius 16 and `elevation-2`; on compact layouts call `showModalBottomSheet` with a `ListView` of rows and a check on the selected one. Expose `Semantics(button: true, value:)` on the trigger.
