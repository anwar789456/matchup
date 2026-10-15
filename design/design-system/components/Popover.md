# Popover

A non-modal panel anchored to its trigger — title, content, a footer link and an optional 8px arrow — for explanations, date presets, the notification panel and other small choices next to what they affect.

## When to use
- Explain a value in more than a tooltip line: « Pourquoi ce niveau ? » with the scale and a link.
- Pick from a short list next to a control: date presets with `Popover.Options`.
- The desktop notification panel: `width="var(--notification-panel)"` (400), `flush`.
- Use a **Tooltip** for one line, a **Menu** for actions, a **Dialog** for anything to confirm; on mobile prefer a BottomSheet.

## Anatomy & specs
| Part | Spec |
|---|---|
| Panel | `surface-elevated`, `radius-lg`, `elevation-2` (a hairline in Night match); 240–360 wide to its content, or a fixed `width` |
| Header | padding `space-4` `space-4` 0; title `label-l` + optional `headerAction` (a link button, « Tout marquer comme lu ») |
| Body | padding `space-4` (`space-2` on top under a header); `flush` lists: `space-1` `space-1` `space-2`, the rows carry their own `space-3` inset |
| Footer | padding `space-3` `space-4` above a `border` hairline: one link (« Voir tout », « Personnaliser les dates ») |
| Arrow | a 12px `surface-elevated` square turned 45° (an 8px point), on the trigger's centre, or 24 in from the corner for wide triggers |
| Options | `listbox` rows: min `control-m` 40, padding `space-2` `space-3`, `radius-sm`; label `body` (selected: `label`), hint `caption` `text-secondary`, `check` 16 at the end; hover `opacity-hover` wash, focus an inset 2px `focus` ring |

- **Placement**: `bottom-start` (default) · `bottom` · `bottom-end` · `top-start` · `top` · `top-end` · `start` · `end`. Logical: start is left in LTR, right in RTL. `space-2` from the trigger, `space-3` with the arrow.
- **Layer** `z-popover` (200): above content and sticky bars, under sheets, drawers and modals. No scrim.

## States
- **Enter**: fade + a 4px slide away from the trigger + scale 0.98 → 1 over `duration-base`, `ease-enter` (side placements: scale only). **Exit**: fade over `duration-fast`, `ease-exit`.
- **Open / close**: the trigger toggles it; a click anywhere outside — including another popover's trigger — or Esc closes it, so one is open at a time. Esc returns focus to the trigger.
- Picking an option can close it (call `onOpenChange(false)` in `onChange`).
- Controlled (`open` + `onOpenChange`) or uncontrolled (`defaultOpen`).

## Content
- Titles are short questions or nouns: « Pourquoi ce niveau ? », « Période », « Notifications ».
- Explanations give the rule and its source: « Ton niveau 3,5 vient de tes 12 dernières parties : les résultats, le niveau de tes adversaires et l’avis des joueurs. »
- Options carry exact dates as hints: « 7 derniers jours » · « 7 – 13 oct. ».
- One footer link, phrased as where it goes: « Voir mes statistiques ».

## Accessibility
- `role="dialog"` by default (`region` or `tooltip` for passive content), labelled by its title or `label`. The trigger gets `aria-haspopup="dialog"`, `aria-expanded` and `aria-controls`.
- Opened by the person, focus moves inside — to the selected option, else the first control. Focus is not trapped: Tab carries on through the page.
- `Popover.Options` is a `listbox` with `aria-selected`; ↑ / ↓ wrap, Home / End jump, one Tab stop.
- Icon-only triggers carry a label (« Pourquoi ce niveau ? ») and a 44 hit area.

## Do / Don't
- Do anchor it to the thing it explains and keep it short.
- Do close a single-choice popover as soon as a value is picked.
- Don't nest popovers, or open one from a menu item.
- Don't hide the only way to finish a task inside a popover.

## Props (web preview)
`trigger` · `open` · `defaultOpen` · `onOpenChange` · `placement` · `arrow` · `title` · `headerAction` · `children` · `footer` · `width` · `flush` · `label` · `role` · `autoFocus` · `anchorClassName`; `Popover.Options`: `options` (`value`, `label`, `hint`, `icon`, `disabled`, `type: 'separator'`) · `value` · `defaultValue` · `onChange` · `label`. See `index.d.ts`.

## Flutter
`MuPopover(trigger: MuIconButton(icon: 'question', label: 'Pourquoi ce niveau ?'), placement: MuPlacement.bottomStart, arrow: true, title: 'Pourquoi ce niveau ?', footer: MuButton.link('Voir mes statistiques'), child: …)` — `OverlayPortal` + `CompositedTransformTarget` / `CompositedTransformFollower` with `AlignmentDirectional` anchors from the placement, `TapRegion(onTapOutside:)` to close, an Esc shortcut, and `FadeTransition` + `SlideTransition` over 200 ms. Options rows in `Semantics(selected:, inMutuallyExclusiveGroup: true)`.
