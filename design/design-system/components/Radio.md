# Radio

Radios pick exactly one option from a short, visible list — payment method, game type, preferred padel side.

## When to use
- 2–5 mutually exclusive options the user should compare: « Chacun paie sa part » / « Je paie le terrain ».
- Always inside `Radio.Group` (`role="radiogroup"`) with a visible label.
- More than 5 options → Select. Views or modes → SegmentedControl. Big onboarding answers → ChoiceCard. Short choices in a filter bar → Chip (choice).

## Anatomy & specs
| Part | Spec |
|---|---|
| Circle | 20×20, `radius-full`, 1.5px `border-control`, `surface` |
| Selected | 2px `primary` ring + 10px `primary` dot (ink in Light, Volt in Night match) |
| Label | `body` (`label` when a description follows), `text`, `space-3` after the circle |
| Description | `body`, `text-secondary` |
| Row | min-height `touch-target` 44, `space-3` padding block — the whole row is the target |
| Group | label (`label`) + description, `space-2` to the options |

## Variants
- **Vertical** (default): rows touch (they are 44px tall); use for options with descriptions and checkout choices.
- **Horizontal**: 2–3 short options (« Gauche · Droite · Peu importe »), `space-6` apart, wrapping when space runs out.

## States
- **Hover**: ring → `text` (selected: `primary-hover`). **Pressed**: 0.9 scale. **Focus**: `focus-ring` on the circle.
- **Selected**: the dot pops in with `ease-pop` over `duration-fast`.
- **Error** (group): `error` rings on `error-soft`, the message with its icon under the group, `aria-invalid` on the radiogroup.
- **Disabled**: `disabled-fill` circle, `text-disabled` label; keep it visible and give the reason in the description (« Non proposé par Arena Five. »).

## Content
- Options are parallel and short; the consequence goes in the description, with the amount per person (« 15 DT par joueur, payés en rejoignant la partie. »).
- Pre-select the common, safe option (« Chacun paie sa part »). Leave a required choice empty only when no default is right, and say why it blocks: « Choisis un type pour publier la partie. »
- Order options meaningfully: cheapest → most expensive, beginner → advanced.

## Accessibility
- Native radios share a `name`: Tab lands on the selected option, arrow keys move and select.
- The radiogroup is named by the group label; `aria-required` and `aria-invalid` when relevant; descriptions via `aria-describedby`.
- The ring + dot change shape, not only colour; `border-control` keeps 3:1.

## Do / Don't
- Do update the dependent CTA in place (« Payer ma part » ↔ « Payer le terrain »).
- Don't use a single radio on its own — that's a Checkbox.
- Don't hide unavailable options; disable them with the reason.

## Props (web preview)
`Radio`: `value` · `label` · `description` · `disabled` · `error` · `checked` / `defaultChecked` (standalone) · `onChange` — `Radio.Group`: `label` · `description` · `error` · `value` · `defaultValue` · `onChange` · `orientation` · `required` · `disabled` · `name`. See `index.d.ts`.

## Flutter
`MuRadioGroup<T>(label:, value:, onChanged:, direction: Axis.vertical, error:, children: [MuRadio(value: 'part', label: 'Chacun paie sa part', description: …)])` — Material `Radio<T>` with `fillColor: primary` and a 1.5px `borderControl` side, each in a 44px `InkWell` row; the group is a `Semantics(container: true, label:)` around a `Column` (or `Wrap` when horizontal).
