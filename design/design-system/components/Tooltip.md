# Tooltip

A short explanation on `surface-inverse` with an 8px arrow, shown on hover after 400 ms and on keyboard focus; the rich variant adds a title and a link.

## When to use
- Name icon-only actions (« Plus d'actions ») and reveal truncated text.
- Explain a number in one or two lines: reliability, level, fees.
- **Rich** when the explanation needs a title and a « Comment ça marche » link.
- Never for errors, prices, rules or anything needed to finish a task — that belongs on the page.

## Anatomy & specs
| Part | Plain | Rich |
|---|---|---|
| Surface | `surface-inverse`, `radius-sm`, `elevation-2` | same |
| Text | `caption` `text-inverse` | title `label`, body `caption`, link `label-s` underlined + `arrow-right` 14 |
| Padding | 6px · `space-2` | `space-3`, gap `space-1` |
| Max width | 240 | 280 |

- Arrow: an 8px square rotated 45°, centred on the trigger; the bubble sits 8px from the trigger. Layer `z-popover`.
- Placement: top (default) · bottom · start · end — logical, so start is left in LTR and right in RTL. It flips to the opposite side when there is no room and slides along the edge to stay 8px inside the viewport; the arrow keeps pointing at the trigger.

## Variants
Plain (one caption line, wraps at 240) · rich (title + text + link).

## States
- Opens after 400 ms of hover, or at once on `:focus-visible`: fade + 4px slide (start / end: scale 0.96) over `duration-fast`, `ease-enter`.
- Closes on pointer leave (120 ms grace, rich 250 ms), blur, pointer-down on the trigger, or Esc — `ease-exit`.
- Hoverable: an invisible bridge spans the 8px gap so the pointer can move onto it (WCAG 1.4.13).
- Touch (Flutter): long-press shows it, release hides it.

## Content
- Labels without a full stop (« Plus d'actions »); explanations as sentences with one.
- Give the number and the rule: « 48 matchs honorés sur 50 ces 12 derniers mois. »
- The rich link is a short phrase: « Comment ça marche ». Keep everything under ~120 characters.

## Accessibility
- Plain: `role="tooltip"`; the trigger gets `aria-describedby`. For icon-only triggers use `describeChild={false}` so the text becomes the accessible name.
- Rich: a non-modal `role="dialog"` labelled by its title; the trigger is described by the body; Tab reaches the link while it is open.
- Non-interactive triggers (text, badges) are made focusable (`tabindex="0"`) so keyboard users get the same help.
- `text-inverse` on `surface-inverse`: 17.2:1 (Light) · 16.1:1 (Night match). Native `title` tooltips are removed to avoid doubles.

## Do / Don't
- Do keep one tooltip open at a time and let it follow the trigger's focus.
- Don't put buttons in a plain tooltip, or hide required information in one.
- Don't attach tooltips to disabled buttons — say on the page why the action is unavailable.

## Props (web preview)
`content` · `title` · `link` · `placement` · `open` · `defaultOpen` · `onOpenChange` · `delay` · `describeChild` · `children`. See `index.d.ts`.

## Flutter
`MuTooltip(message: 'Plus d’actions', placement: MuPlacement.top, child: …)` on `Tooltip` (`waitDuration: 400 ms`, `triggerMode: TooltipTriggerMode.longPress` on touch, a `ShapeDecoration` with an arrow `ShapeBorder` in `surfaceInverse`, `textStyle: MuType.caption`). Rich: `MuRichTooltip(title:, message:, action:)` built on `OverlayPortal` + `CompositedTransformFollower`, with `Semantics(tooltip: …)` on the trigger.
