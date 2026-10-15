# Stepper

A − value + control for small whole numbers — « Nombre de joueurs » — whose helper recomputes the price per person as the number changes.

## When to use
- Small integers changed one at a time within known bounds: players (8–14 on a 5-a-side pitch), places for friends (0–3), substitutes.
- Whenever the number changes what each player pays, show it next to the control: « 10 joueurs · 15 DT par personne » (court price ÷ players).
- Free amounts or large ranges → a number field; ranges → RangeSlider.

## Anatomy & specs
| Size | − / + | Value | Value box | Gap |
|---|---|---|---|---|
| M (default) | IconButton secondary 40 (hit 44) | `num-l` | min 64 × 40, `radius-sm` | `space-2` |
| S | IconButton secondary 32 (hit 44) | `num-m` | min 40 × 32, `radius-sm` | `space-1` |

- Label `label` (`text`); helper `body` (`text-secondary`) with the per-person price in `num-s` `text`.
- **Stacked**: label, control (`space-2`), helper. **Inline**: label + helper at the start, control at the end of a full-width row (forms, settings).
- The digits slide 45 % up on increase (down on decrease) with a fade over `duration-fast`.

## States
- **At min**: « − » disabled; **at max**: « + » disabled (IconButton disabled: `text-disabled` icon, no press).
- **Focus**: `focus-ring` around the value (the spinbutton).
- **Disabled**: both buttons disabled; label, value and helper `text-disabled`.
- Hover and press come from IconButton (wash, 0.94 scale).

## Content
- The label names the quantity: « Nombre de joueurs », « Places pour tes amis ».
- Money uses `formatDT`: 150 ÷ 10 → « 15 DT », 150 ÷ 8 → « 18,750 DT », 150 ÷ 11 → « 13,636 DT ».
- Button names include the unit: « Ajouter un joueur », « Retirer un joueur ».

## Accessibility
- The value is `role="spinbutton"` with `aria-valuenow/min/max` and a French `aria-valuetext` (« 10 joueurs, 15 DT par personne »).
- Keys: ArrowUp/Right +1, ArrowDown/Left −1, PageUp/Down ±5, Home/End = min/max — one Tab stop per stepper; − and + stay reachable by pointer and screen-reader touch.
- The helper is a polite live region, so the new price is announced.

## Do / Don't
- Do set real bounds (sport format, court capacity) and say why when one is reached.
- Do keep the price per person next to the control, not only in the summary.
- Don't use it beyond ~20 steps — use a slider or a field.
- Don't make the value editable as text.

## Props (web preview)
`value` · `defaultValue` · `onChange` · `min` · `max` · `step` · `label` · `helper` (node or `value => node`) · `valueText` · `format` · `size` · `layout` · `disabled` · `decrementLabel` · `incrementLabel`. See `index.d.ts`.

## Flutter
`MuStepper(value:, min: 8, max: 14, onChanged:, label: 'Nombre de joueurs', helper: (n) => …, size: MuStepperSize.m, layout: MuStepperLayout.inline)` — a `Row` of two `MuIconButton.secondary` around an `AnimatedSwitcher` (slide + fade) number, wrapped in `Semantics(value:, increasedValue:, decreasedValue:, onIncrease:, onDecrease:)` so it reads as one adjustable control.
