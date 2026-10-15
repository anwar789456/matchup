# Button

The action control: a verb that says what happens next — « Réserver », « Rejoindre et payer », « Payer ma part » — never a lone « OK ».

## When to use
- **Primary** for the one thing the screen is for. One per view; on mobile it lives in the sticky bottom bar at **XL**, full width, in the thumb zone.
- **Secondary** for the alternative next to a primary (« Voir le terrain », « Modifier »).
- **Tertiary** (ghost) for low-emphasis actions in toolbars, cards and dialogs (« Plus tard », « Partager »).
- **Destructive** for irreversible actions after a dialog has stated the consequence (« Annuler la réservation »); **destructive-outline** when the destructive action sits next to a safer primary (« Quitter la partie »).
- **Link** for navigation inside text (« Politique d’annulation »). If it changes data, it is a button, not a link.

## Anatomy & specs
| Size | Height | Padding (inline) | Radius | Label style | Icon |
|---|---|---|---|---|---|
| S | `control-s` 32 | `space-3` | `radius-sm` | `label` | 16 |
| M | `control-m` 40 | `space-4` | `radius-md` | `label` | 20 |
| L | `control-l` 48 | `space-5` | `radius-md` | `label-l` | 20 |
| XL | `control-xl` 56 | `space-6` | `radius-md` | `label-l` | 24 |

- Icon-to-label gap `space-2`. S buttons grow an invisible hit area to `touch-target` 44.
- **Price inside**: label · dot · price in `num-m` (L/XL) or `num-s` (S/M) — « Rejoindre et payer · 15 DT ». Always the price *per person*.
- **Countdown inside**: label · timer icon · `num-*` tabular digits — « Réclamer la place · 14:59 ».

## Colours
| Variant | Fill | Label | Border |
|---|---|---|---|
| primary | `primary` (ink · Volt in Night match) | `on-primary` | — |
| secondary | `surface` | `text` | `border-strong` → `text` on hover |
| tertiary | transparent | `text` | — |
| destructive | `destructive` | `on-destructive` | — |
| destructive-outline | transparent | `error-text` | `error` |
| link | — | `link`, underlined | — |

## States
- **Hover**: primary → `primary-hover`; others get a wash of the label colour at `opacity-hover`.
- **Pressed**: scale `scale-press` (0.98) over `duration-fast`, `ease-enter`; primary → `primary-pressed`, others `opacity-pressed` wash.
- **Focus**: `focus-ring` (2px gap + 2px `focus`), never removed.
- **Disabled**: `disabled-fill` + `text-disabled` (filled variants), `border` + `text-disabled` (outlined); no hover, no press.
- **Loading**: a spinner replaces the label, the width stays fixed, clicks are ignored, `aria-busy="true"`.
- **Success**: `success` fill with a check for `duration-success` (1.2 s), then back to default — use after payments and saves.

## Content
- Verb first, sentence case, 1–3 words: « Réserver », « Inviter des joueurs », « Payer ma part ».
- Destructive labels say the consequence when it is about money: « Annuler · 45 DT remboursés ».
- Never « OK », « Valider » alone, or « Cliquez ici ».

## Accessibility
- Label text ≥ 4.5:1 on its fill in both themes (primary 17.2:1 / 13.2:1).
- Icon-only actions use **IconButton** with a label, not Button.
- Loading announces « Chargement »; the success check announces « Fait ».

## Do / Don't
- Do keep one primary per view; pair it with secondary or tertiary.
- Do put the primary last in a group: right on desktop, bottom on mobile (see ButtonGroup).
- Don't use Volt as a button label or outline on white — in Light the primary is ink.
- Don't stack two XL buttons in the sticky bar; the second action is tertiary above it.

## Props (web preview)
`variant` · `size` · `leadingIcon` · `trailingIcon` · `price` · `countdown` · `loading` · `success` · `disabled` · `fullWidth` · `href` · `children` (the label). See `index.d.ts`.

## Flutter
`MuButton(label:, onPressed:, variant: MuButtonVariant.primary, size: MuButtonSize.xl, leading:, trailing:, price: '15 DT', countdown:, loading:, success:)` — a `StatelessWidget` over `FilledButton`/`OutlinedButton`/`TextButton` styled from `MuTheme` (see the Flutter section). Wrap the child in `AnimatedScale(scale: pressed ? 0.98 : 1)`; keep the width with an `IndexedStack` of label and spinner.
