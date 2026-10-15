# BottomSheet

The mobile panel that rises from the bottom edge — a drag handle, three heights (peek, half, full) or a content-sized one, a header with title and close, a scrolling body and a sticky footer.

## When to use
- **Filters**: full, « Filtres » with « Réinitialiser » and « Voir 24 parties ».
- **Slot details**: peek and non-modal, so the planning above stays usable.
- **Split payment** (half, « Comment partager ? »), **quick rating** (auto, « Note la partie »), **share** (auto, « Partager la partie »).
- Menu `presentation="sheet"` reuses it as an action sheet. On desktop use a Popover, Menu, Dialog or Drawer.

## Anatomy & specs
| Height | Token | Default |
|---|---|---|
| peek | `sheet-peek` 30 % | non-modal: no scrim, the page stays usable |
| half | `sheet-half` 55 % | modal with scrim; the default starting height |
| full | `sheet-full` 92 % | modal; the page still shows above it |
| auto | content, up to 92 % | modal; no snap points |

- **Panel**: `surface-elevated`, top corners `radius-lg`, `elevation-3`; heights are shares of the screen.
- **Handle**: a 36 × 4 bar, `radius-full`, `border-strong` (hover `text-secondary`; 44 wide while dragging), centred in a 64 × 20 button `space-1` from the top with a 44-high hit area.
- **Header**: min `control-xl` 56, padding inline `space-4` / `space-2`; title `h3` on one line; optional `headerAction` (tertiary « Réinitialiser »); IconButton « Fermer ». A `border` hairline appears under it once the body scrolls.
- **Body**: scrolls on its own; padding `space-2` `space-4`, bottom `space-6` + safe area (`space-4` when there is a footer).
- **Footer**: sticky, `surface-elevated`, `elevation-2-up`, padding `space-3` `space-4` + safe area: one XL full-width primary, or secondary + primary with the primary at the end.
- **Layer** `z-sheet` (300) — above popovers and sticky bars, under dialogs; `scrim` (ink-900 at 40 %, 64 % in Night match) when modal.

## States
- **Enter**: slides up from `translateY(100 %)` over `duration-slow`, `ease-enter`, the scrim fading in. **Exit**: back down over `duration-base`, `ease-exit`.
- **Resize**: drag the handle or header; on release it snaps to the nearest of `snapPoints` (default peek, half, full), animating over `duration-slow`, `ease-move`. Releasing below 60 % of the lowest height closes it. Pressing the handle cycles the heights; ↑ / ↓ step on the keyboard.
- **Dismiss**: X, scrim tap, Esc or drag down. `dismissible={false}` removes all four; the handle still resizes.
- **Non-modal** (peek by default, or `modal={false}`): no scrim, no focus trap, the page stays interactive.
- **Scrolled**: header hairline on; the footer stays put.

## Content
- The title names the task: « Filtres », « Comment partager ? », « Note la partie », or the slot « Sam. 18 oct. · 20h00 ».
- The footer is one verb with its result or price: « Voir 24 parties », « Continuer · 15 DT », « Envoyer ma note » — price per person when money is involved.
- Handle names: « Agrandir le panneau », and « Réduire le panneau » at the top height.

## Accessibility
- `role="dialog"` labelled by the title (`label` when there is none). Modal sheets set `aria-modal`, move focus inside, trap Tab and return focus to the trigger when they close; page scroll locks.
- The handle is a real button — tap or Enter cycles heights, arrows step — so dragging is never the only way.
- Esc never reaches an overlay underneath. A Dialog may open over a sheet; it takes the focus trap until it closes.
- Safe areas come from `env(safe-area-inset-bottom)`, or from `safeArea` inside a phone frame.

## Do / Don't
- Do keep the primary action in the sticky footer, full width, in the thumb zone.
- Do use peek for details that must not hide the map or the planning.
- Don't stack two sheets — change the content or go to full height.
- Don't put a long form in an auto sheet; use full with a sticky footer.

## Props (web preview)
`open` · `onClose` · `height` · `defaultHeight` · `onHeightChange` · `snapPoints` · `title` · `headerAction` · `showClose` · `closeLabel` · `footer` · `children` · `modal` · `scrim` · `dismissible` · `handle` · `safeArea` · `label` · `bodyClassName` · `inline` · `autoFocus` · `state` (preview only). See `index.d.ts`.

## Flutter
`MuBottomSheet.show(context, height: MuSheetHeight.half, snapPoints: [MuSheetHeight.peek, MuSheetHeight.half, MuSheetHeight.full], title: 'Comment partager ?', footer: MuButton(...), modal: true)` → `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, barrierColor: colors.scrim)` around a `DraggableScrollableSheet(snap: true, snapSizes: [0.30, 0.55, 0.92], maxChildSize: 0.92)` holding our handle, header, scrolling body and footer in a `Column`. The non-modal peek is a persistent sheet (`Scaffold.of(context).showBottomSheet`).
