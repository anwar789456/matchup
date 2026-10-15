# Switch

An on/off setting that applies immediately — « Terrain couvert », « Rappel avant le match », « Validation manuelle ».

## When to use
- Settings and filters that take effect at once, without a save button.
- Binary amenities in the « Filtres » sheet (« Terrain couvert », « Éclairé le soir »).
- Use a **Checkbox** when the choice is submitted with a form (consent, multi-select lists) and a **ToggleButton** for an action (« Suivre »).

## Anatomy & specs
| Size | Track | Knob off → on | Check | Gap to label |
|---|---|---|---|---|
| M (default) | 48×28, `radius-full` | 16 → 20 | 12 | `space-3` |
| S | 36×20, `radius-full` | 12 → 14 | 10 | `space-2` |

- **Off**: `surface` track with a 1.5px `border-control` outline; knob `border-control`.
- **On**: `primary` track (ink in Light, Volt in Night match); knob `on-primary` with a tiny check in `primary`.
- The knob slides with `ease-move` over `duration-fast` and grows as it turns on.
- Row: min-height `touch-target` 44. Label `body` (`label` with a description); description `body`, `text-secondary`.
- `labelPosition="start"` makes a full-width settings row: icon (24, `text-secondary`) · label + description · switch at the end, vertically centred.

## States
- **Hover**: track border → `text`, knob → `text-secondary`; on → `primary-hover`.
- **Pressed**: the knob stretches 6px toward its travel (M: 22 off, 24 on).
- **Focus**: `focus-ring` around the track.
- **Disabled**: `disabled-fill` track; knob `text-disabled` (off) or `surface` with a `text-disabled` check (on); label `text-disabled`.

## Content
- The label names the setting, not the action: « Rappel avant le match », not « Activer le rappel ».
- The description says what happens when it is on: « 2 h avant le coup d’envoi, avec l’adresse du terrain. »
- Never write « Oui / Non » or « ON / OFF » in or next to the track.

## Accessibility
- `<input type="checkbox" role="switch">`: Space toggles; screen readers announce « activé / désactivé ».
- The whole row toggles and is ≥ 44px tall; the description is linked with `aria-describedby`.
- On vs off is shown by position, fill and the check — never colour alone.
- Without a visible label pass `aria-label`.

## Do / Don't
- Do save immediately; if saving fails, flip back and show a toast with « Réessayer ».
- Do align switches at the end of settings rows separated by `border` hairlines.
- Don't use a switch in a form that ends with « Enregistrer » — use a Checkbox.
- Don't disable a switch without saying why in its description.

## Props (web preview)
`checked` · `defaultChecked` · `onChange(checked)` · `label` · `description` · `icon` · `labelPosition` · `size` · `disabled` · `name` · `aria-label`. See `index.d.ts`.

## Flutter
`MuSwitch(value:, onChanged:, label:, description:, icon:, size: MuSwitchSize.m)` — a custom widget: `AnimatedContainer` track (outline when off) and an `AnimatedPositionedDirectional` knob (150 ms, `ease-move` curve) holding a check icon, inside a 44px `InkWell` row with `Semantics(toggled: value)`. Material 3 `Switch` (`thumbIcon`, `trackOutlineColor`) is close but 52×32 — don't scale it.
