# Checkbox

Checkboxes pick any number of independent options — filter lists (« Équipements »), a consent before paying, row selection in owner tables.

## When to use
- Multi-select lists where each option stands alone: « Vestiaires », « Douches », « Parking », « Éclairage ».
- A single consent that gates an action: « J’accepte les conditions d’annulation » above « Payer ma part ».
- Row selection in desktop tables (no visible label — pass `aria-label`).
- Use **Switch** for a setting that applies at once, **Radio** for one-of-many, **Chip** (filter) for a horizontal filter bar, **ChoiceCard** for big onboarding answers.

## Anatomy & specs
| Part | Spec |
|---|---|
| Box | 20×20, `radius-xs`, 1.5px `border-control` on `surface` |
| Mark | 14px check or dash, 2px round stroke, `on-primary` |
| Label | `body` (`label` when a description follows), `text`, `space-3` after the box |
| Description | `body`, `text-secondary`, 2px under the label |
| Row | min-height `touch-target` 44 with `space-3` padding block — the whole row is the hit area |
| Error | `caption` + 16px `warning-circle` (fill) in `error-text`, aligned with the label |

- The box and the first text line share the top edge (20px line height); long labels wrap under themselves, never under the box.
- Groups: label (`label`) + optional description, then rows with no extra gap (rows are already 44px). Horizontal groups wrap with `space-6` between options.
- A bare checkbox keeps a 44×44 hit area around the 20px box without taking layout space.
- Nest children under « Tous les équipements » with a 32px inline-start indent (box + gap).

## Variants
- **Unchecked** · **Checked**: `primary` fill (ink in Light, Volt in Night match) with the `on-primary` check · **Indeterminate**: same fill with a dash, for a parent when only some children are checked.
- **With description** when the option needs a consequence.

## States
- **Hover**: border → `text`; checked → `primary-hover`.
- **Pressed**: the box scales to 0.9 over `duration-fast`.
- **Focus**: `focus-ring` on the box, keyboard only.
- **Error**: `error` border on an `error-soft` box + the message under the row; it clears as soon as the box is checked.
- **Disabled**: `disabled-fill` box with a `border-strong` edge, `text-disabled` label and mark; no hover.
- The mark draws in over `duration-base` (`ease-enter`); with reduced motion it appears at once.

## Content
- Options are short nouns or statements in sentence case: « Douches », « Accepter les remplaçants ».
- Consents start with « J’accepte… »; the description states the consequence: « Annulation gratuite jusqu’à 24 h avant le match. »
- Errors say what to do: « Coche la case pour payer ta part. »

## Accessibility
- A native `<input type="checkbox">` sits under the box: Space toggles, a click anywhere on the row toggles.
- `indeterminate` is set on the input, so screen readers announce « mixte ».
- The visible label names the input (`aria-labelledby`); description and error are linked with `aria-describedby`; errors set `aria-invalid`.
- `Checkbox.Group` is `role="group"` named by its label.
- `border-control` reaches 3:1 on `surface` and `bg` in both themes.

## Do / Don't
- Do put a « select all » parent above long lists.
- Do show the error only after the user tries to continue.
- Don't use a checkbox to trigger an immediate action — that's a Switch or a Button.
- Don't turn the label red on error; the message carries it.

## Props (web preview)
`checked` · `defaultChecked` · `indeterminate` · `onChange(checked)` · `label` · `description` · `error` · `disabled` · `name` · `value` · `aria-label` — `Checkbox.Group`: `label` · `description` · `error` · `value[]` · `onChange` · `orientation` · `disabled`. See `index.d.ts`.

## Flutter
`MuCheckbox(value: true, tristate: true, onChanged:, label: 'Douches', description:, error:)` — Material `Checkbox` themed with `side: BorderSide(1.5, borderControl)`, `shape: RoundedRectangleBorder(radius 4)`, `fillColor: primary`, `checkColor: onPrimary`, inside a 44px `InkWell` row wrapped in `MergeSemantics`. `MuCheckboxGroup(label:, values:, onChanged:, children:)` lays out the rows.
