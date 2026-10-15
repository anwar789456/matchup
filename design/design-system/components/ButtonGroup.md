# ButtonGroup

Lays out two or three related buttons with the primary last: on the right on desktop, at the bottom — in the thumb zone — on mobile.

## When to use
- Dialog and sheet footers: « Garder la réservation » + « Annuler · 45 DT remboursés ».
- Decision rows on cards and panels: « Refuser » + « Accepter l’invitation ».
- Mobile prompts in a sheet or card: « Plus tard » above « Activer les notifications ».
- Not for the sticky bottom bar of a mobile flow — it holds one XL primary, with any second action as a tertiary Button above it. Not for mutually exclusive options — use SegmentedControl.

## Anatomy & specs
| Layout | Direction | Gap | Children |
|---|---|---|---|
| inline (default) | row, wraps onto new lines | `space-3` | natural width, justified by `align` |
| stack | column | `space-3` | full width |

- `align` (inline): `end` (default — dialogs), `start`, `between` (secondary at the start, primary at the end — cards and panels), `center`, `fill` (equal widths).
- Children go in DOM order [secondary…, primary], so reading and tab order end on the main action.
- Sizes: M in desktop dialogs, panels and cards; L in mobile sheets. Never mix sizes in one group.

## Variants
`inline` · `stack`, each with an `align`.

## States
The group has no state; each Button keeps its own (hover, pressed, focus, loading, success, disabled). A wrapped inline group keeps the primary last, on the last line.

## Content
- Pair verbs that answer the same question: « Refuser » / « Accepter l’invitation », « Plus tard » / « Activer les notifications ».
- The safe option says what is kept: « Garder la réservation », never a bare « Annuler » next to a destructive « Annuler la réservation ».
- When money moves, the destructive label states the consequence: « Annuler · 45 DT remboursés ».

## Accessibility
- Focus order follows the DOM: secondary first, primary last.
- In RTL the inline group mirrors with the layout: the primary sits on the left.
- Each Button keeps its own accessible name; a group of two or three needs no extra label.

## Do / Don't
- Do keep one primary per group, paired with a secondary or tertiary.
- Do make the destructive button the main action of a destructive confirmation, with a tertiary way out.
- Don't put more than three buttons in a group — move the rest into a menu.
- Don't reorder children for mobile; `stack` already puts the primary at the bottom.

## Props (web preview)
`layout` · `align` · `children`. See `index.d.ts`.

## Flutter
`MuButtonGroup(layout: MuButtonGroupLayout.inline, align: MuButtonGroupAlign.end, children: [secondary, primary])` — inline is a `Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.end)`; `between` → `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)`; `fill` → `Row` of `Expanded` with 12 gaps. Stack is a `Column(crossAxisAlignment: CrossAxisAlignment.stretch)` with 12 gaps. Both follow `Directionality`, so RTL puts the primary on the left.
