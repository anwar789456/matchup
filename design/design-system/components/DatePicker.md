# DatePicker

French date picking: a lundi-first month calendar (single date or range) with Volt selection and availability dots, a popover under a field (« sam. 17 oct. »), and the scrolling day strip of the venue page.

## When to use
- **Calendar** (`variant="calendar"`): inline in sheets and dashboards — an owner blocking days, an organiser setting tournament dates (`mode="range"`).
- **Popover** (`variant="popover"`): forms with a date field (« Date du match »).
- **Strip** (`variant="strip"`): venue page and booking flow — the next 14 days, one tap away, right above the time slots.

## Anatomy & specs
| Part | Spec |
|---|---|
| Header | « octobre 2026 » in `label-l`; prev / next IconButton S (32, hit 44), prev disabled before `minDate` |
| Weekdays | « lun. mar. mer. jeu. ven. sam. dim. », `caption`, `text-secondary` |
| Day | 44 tall cell; 40×40 `radius-full` button; number `num-s` |
| Today | 1.5px inset `text` ring (`on-accent` when selected) |
| Selected | `accent` (Volt) fill, `on-accent` number |
| Range | start and end Volt; days between on a `surface-muted` band (`border` inside the popover), rounded at row ends |
| Availability | 4px `success` dot under the number (`on-accent` on Volt) + legend « Créneaux libres » |
| Field | `control-l` 48, `radius-sm`, 1px `border-control`, calendar icon, value `body-l`, caret |
| Popover | `surface-elevated`, `radius-lg`, `elevation-2`, 8px under the field, `z-popover` |
| Strip pill | 52 wide, `radius-full`, 1px `border-strong` on `surface`; day name `caption` (« Auj. » for today), number `num-m`, 4px availability pip |

## States
- **Day**: hover `surface-muted` circle, pressed 0.94, focus `focus-ring`; disabled (past or closed) `text-disabled`, no hover.
- **Range picking**: after the start, the band previews up to the hovered or focused day; the summary reads « Choisis la date de fin », then « sam. 24 → sam. 31 oct. · 8 jours ».
- **Strip**: selected Volt; sold out dimmed on `surface-muted`, number struck through, no pip — still selectable to ask for an alert.
- **Field**: hover / open border `text` (open adds a 1px inner ring and flips the caret), focus `focus-ring`, placeholder « Choisis une date » in `text-secondary`.

## Content
- Lowercase French dates: « octobre 2026 », « sam. 17 oct. », ranges « ven. 23 → dim. 25 oct. ».
- « Auj. » marks today in the strip; never « Aujourd’hui » in a 52px pill.

## Accessibility
- The month is a `role="grid"`; day buttons are named « samedi 17 octobre 2026, créneaux disponibles »; today has `aria-current="date"`; disabled days `aria-disabled`.
- Keys: arrows ±1 day / ±1 week (mirrored in RTL), Home/End start/end of week, PageUp/Down ±1 month (Shift: year), Enter/Space select — one Tab stop (roving focus).
- Popover: `aria-haspopup="dialog"` + `aria-expanded`; opening moves focus to the selected day; picking or Escape closes and returns focus to the field.
- Strip: `radiogroup`; arrows move and select; pills are 52×64.

## Do / Don't
- Do disable past days and explain closures where the slots show, rather than hiding days.
- Do start weeks on lundi.
- Don't fill today with Volt — today is a ring; Volt means selected.

## Props (web preview)
`variant` · `mode` · `value` · `onChange` · `month` · `onMonthChange` · `today` · `minDate` · `maxDate` · `isDateDisabled` · `availability` · `legend` · `label` · `placeholder` · `open` · `onOpenChange` · `startDate` · `days` · `bleed`. See `index.d.ts`.

## Flutter
`MuCalendar(mode:, selected:, onSelected:, availability:)` — a custom 7-column grid (Material `CalendarDatePicker` can't draw range bands, dots or Volt days) using `DateFormat('EEE d MMM', 'fr')` and Monday as first day; `MuDateField` opens it in an `OverlayPortal` (a bottom sheet on small phones); `MuDateStrip` is a horizontal `ListView` of 52px pills with `Scrollable.ensureVisible` on selection.
