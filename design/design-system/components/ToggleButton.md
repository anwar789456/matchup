# ToggleButton

A single on/off action that stays in place in both states — « Suivre » ↔ « Suivi », « M’alerter » ↔ « Alerte activée », favourite — with a Volt fill for « on ».

## When to use
- Following a player, coach or club: « Suivre » → « Suivi ».
- Asking to be told when something opens: « M’alerter » → « Alerte activée ».
- Saving or favouriting a venue, game or program: icon toggles `heart`, `bookmark-simple`.
- Not for settings (Switch), choosing among options (SegmentedControl, Chips), or one-shot actions (Button).

## Anatomy & specs
| Size | Height | Padding (inline) | Radius | Label | Icon |
|---|---|---|---|---|---|
| S | `control-s` 32 | `space-3` | `radius-sm` | `label` | 16 |
| M (default) | `control-m` 40 | `space-4` | `radius-md` | `label` | 20 |
| L | `control-l` 48 | `space-5` | `radius-md` | `label-l` | 20 |

- Off: `surface` fill, 1px `border-strong`, `text` label and icon; icon-to-label gap `space-2`.
- On: `accent` fill and border, `on-accent` label. A text toggle's icon becomes a check (or `onIcon`) and its label becomes `onLabel`.
- Icon-only: a square of the same height (32 / 40 / 48); on switches the icon to its Fill weight (or to `onIcon`).
- S grows an invisible hit area to `touch-target` 44 high.

## Variants
Text toggle (label, optional leading icon) · icon-only toggle (no children; needs `aria-label`).

## States
- **Hover**: border → `text`.
- **Pressed**: `scale-press` 0.98 over `duration-fast` with `ease-pop`.
- **Focus**: `focus-ring`.
- **On**: `aria-pressed="true"`, Volt fill, check or Fill icon.
- **Disabled**: `text-disabled` label and icon, `border` outline.

## Content
- Off names the action, on names the resulting state, from the same verb: « Suivre » → « Suivi », « M’alerter » → « Alerte activée ».
- Keep both labels close in length so the button barely changes width; the check icon marks on — never type a check character into the label.
- Switching off is the same tap — don't ask for confirmation.

## Accessibility
- A `button` with `aria-pressed`, which screen readers announce as on / off.
- Icon toggles need an `aria-label` that stays the same in both states (« Favori », « Enregistrer »); don't swap « Ajouter » / « Retirer ».
- With `onLabel` the name changes too; keep it a state word (« Suivi ») so « Suivi, activé » still reads right.
- On: `on-accent` on `accent` 13.2:1. Icon-only toggles grow an invisible hit area to the 44 `touch-target` (M 40 → 44).

## Do / Don't
- Do flip the state instantly and save in the background; if saving fails, flip back and say so in a Toast.
- Do keep Volt for the on state only.
- Don't use a ToggleButton for « Rejoindre » or « Payer » — they don't stay on.
- Don't place two toggles that cancel each other side by side — that is a SegmentedControl.

## Props (web preview)
`pressed` · `defaultPressed` · `onChange(pressed)` · `icon` · `onIcon` · `onLabel` · `size` · `disabled` · `state` · `children` (the label). See `index.d.ts`.

## Flutter
`MuToggleButton(pressed:, onChanged:, label: 'Suivre', onLabel: 'Suivi', icon: PhosphorIcons.userPlus(), onIcon:, size: MuToggleSize.m)` — an `OutlinedButton` driven by a `WidgetStatesController` that adds `WidgetState.selected` when on; its `style` resolves the selected fill (`accent`), side (`accent`) and foreground (`on-accent`). Swap icon and label in an `AnimatedSwitcher`, press with `AnimatedScale(0.98)`, and wrap in `Semantics(toggled: pressed)`. Icon-only: `IconButton(isSelected:, selectedIcon:)` in a `RoundedRectangleBorder`.
