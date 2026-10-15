# Colour

Ink carries the interface, Volt marks what is selected, three sport hues sort the content, and semantic colours report status. Every value below is a token in `tokens.json`; the brief's values are kept exact, and every addition is marked ADDITION in its usage note.

## Palette (primitives)

| Token | Value | Role |
|---|---|---|
| `ink-900` | #0B1B33 | Main text and primary buttons in Light |
| `ink-700` | #24324A | Primary-button hover; strong secondary text |
| `ink-500` | #5B6B82 | Secondary text in Light |
| `ink-400` | #818FA2 | ADDITION: control boundaries (fields, checkboxes) at 3:1 |
| `ink-300` | #A9B4C4 | Strong borders in Light; secondary text in Night match |
| `ink-100` | #E6EBF2 | Borders and dividers in Light |
| `ink-50` | #F5F7FA | Light app background; text in Night match |
| `white` | #FFFFFF | Light surfaces |
| `volt-400` | #C6F135 | The brand accent: fills only |
| `night-900` | #070F1F | Night match background |
| `night-800` | #0F1B2E | Night match surface |
| `night-700` | #16243A | Night match elevated surface |
| `football` | #1F9D55 | Football marks |
| `padel` | #2F80ED | Padel marks |
| `basketball` | #F2711C | Basketball marks |
| `success` · `warning` · `error` · `info` | #16A34A · #F59E0B · #E5484D · #3B82F6 | Status marks and fills |
| `ai-500` → `info` | #7C5CFC → #3B82F6 | The AI gradient (`ai-gradient`) |

## Semantic roles

Components use roles, never primitives. A role resolves to a different primitive per theme.

| Role | Light | Night match | Use |
|---|---|---|---|
| `bg` | ink-50 | night-900 | Page behind cards |
| `surface` | white | night-800 | Cards, inputs, sheets, bars |
| `surface-elevated` | white | night-700 | Popovers, menus, modals, drawers |
| `surface-muted` | ink-50 | night-700 | Quiet fills inside a surface: hover rows, tracks, stat wells |
| `surface-inverse` / `text-inverse` | ink-900 / white | ink-50 / ink-900 | Tooltips |
| `text` | ink-900 | ink-50 | Primary text and icons |
| `text-secondary` | ink-500 | ink-300 | Metadata, placeholders, inactive icons |
| `text-disabled` | ink-300 | ink-500 | Disabled labels only |
| `border` | ink-100 | #263752 | Hairlines and dividers (decorative) |
| `border-strong` | ink-300 | ink-500 | Secondary-button and chip outlines, dashed empty slots |
| `border-control` | ink-400 | #6A7A90 | Field, checkbox, radio and switch boundaries |
| `primary` / `on-primary` | ink-900 / white | volt-400 / ink-900 | Primary button |
| `accent` / `on-accent` | volt-400 / ink-900 | volt-400 / ink-900 | Selected states, active-tab pill, highlights |
| `focus` | ink-900 | volt-400 | The 2 px focus ring |
| `link` | ink-900 | volt-400 | Inline links, always underlined |
| `destructive` / `on-destructive` | #CA2C37 / white | #CA2C37 / white | Destructive buttons |
| `toast-bg` / `toast-text` / `toast-action` | ink-900 / white / volt-400 | #22324C / ink-50 / volt-400 | Toasts and snackbars, dark in both themes |
| `nav-bg` / `nav-active` | ink-900 / volt-400 | night-800 / volt-400 | Dashboard sidebar and its active pill |
| `scrim` | ink-900 at 40 % | near-black at 64 % | Behind modals, sheets and drawers |

## Rules

- Put `on-accent` on every Volt fill. Never use Volt for text, icons or 1 px outlines on `bg` or `surface` in Light (1.3:1). The selected state always adds a second cue: a check, a filled icon, a bolder label.
- Use a sport hue for marks only: the chip icon, the map pin, the court, the dots of a lineup meter. Write sport-coloured text in `<sport>-text` on `surface`, `bg` or `<sport>-soft`. Basketball orange is 2.9:1 on white, so it never travels without its icon and name.
- Write status text in `<status>-text` on `<status>-soft`; use the base `success`, `warning`, `error`, `info` for icons, dots and fills. `warning` (2.2:1 on white) is never text.
- Show live with the `live` dot (an alias of `error`) pulsing beside « EN DIRECT » in `error-text`.
- Keep `ai-500`, `ai-text`, `ai-soft`, `ai-gradient` and `ai-gradient-strong` for AI features and AI-generated content. `ai-gradient-strong` is the same gradient one step deeper, for fills that carry a white label.
- Use `destructive` (not the brief's `error` red) for filled destructive buttons: white on #E5484D is only 3.9:1.
- Draw chart series from `chart-1` to `chart-8` in that fixed order, gridlines in `chart-grid`, axes in `chart-axis`, and the occupancy heatmap on the `seq-100` → `seq-700` ramp. Label series directly when a slot is under 3:1 (`chart-3`, `chart-4`, `chart-5`).
- Paint maps with `map-land`, `map-road`, `map-water`, `map-park` and `map-label`; markings on sport-coloured courts use `court-line`.

## Measured contrast

Every text pair meets 4.5:1 and every control boundary, focus ring and meaningful icon meets 3:1, in both themes.

| Pair | Light | Night match |
|---|---|---|
| `text` on `surface` | 17.2:1 | 16.1:1 |
| `text` on `bg` | 16.1:1 | 17.8:1 |
| `text-secondary` on `surface` | 5.4:1 | 8.2:1 |
| `text-secondary` on `bg` | 5.1:1 | 9.1:1 |
| `text-secondary` on `surface-elevated` | 5.4:1 | 7.4:1 |
| `on-primary` on `primary` | 17.2:1 | 13.2:1 |
| `on-accent` on `accent` | 13.2:1 | 13.2:1 |
| `border-control` on `surface` | 3.3:1 | 3.9:1 |
| `border-control` on `surface-elevated` | 3.3:1 | 3.6:1 |
| `focus` on `surface` | 17.2:1 | 13.2:1 |
| `football-text` / `padel-text` / `basketball-text` on `surface` | 5.2 / 5.3 / 5.3:1 | 7.7 / 7.4 / 7.2:1 |
| `success-text` on `success-soft` | 4.6:1 | 6.1:1 |
| `warning-text` on `warning-soft` | 4.7:1 | 6.6:1 |
| `error-text` on `error-soft` | 4.7:1 | 6.0:1 |
| `info-text` on `info-soft` | 4.6:1 | 6.0:1 |
| `ai-text` on `ai-soft` | 4.6:1 | 6.0:1 |
| `on-destructive` on `destructive` | 5.3:1 | 5.3:1 |
| `toast-text` / `toast-action` on `toast-bg` | 17.2 / 13.2:1 | 12.0 / 9.8:1 |
| `nav-text` on `nav-bg` | 16.1:1 | 16.1:1 |

## Night match

The dark theme is « Night match »: the page is `night-900`, cards `night-800`, anything floating `night-700`, text `ink-50`. Primary buttons turn Volt with ink labels, the focus ring and links turn Volt, and elevation becomes a lighter surface plus a 1 px hairline instead of a shadow. Toasts, the dashboard sidebar and celebration takeovers stay dark in both themes: they are the scoreboard.
