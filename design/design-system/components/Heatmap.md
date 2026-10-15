# Heatmap
The venue occupancy grid: days across, hours down, each slot on the one-hue seq ramp, with a scale legend, today’s column, an AI-flagged empty period, cell tooltips and a table twin.

## When to use
- Weekly occupancy patterns for venue owners (« Taux d’occupation par créneau · 5 dernières semaines »).
- One measure on a one-hue scale. Exact comparisons belong to the table view; one slot’s trend to a LineChart.

## Anatomy & specs
- Grid: 40px hour column + 7 equal day columns; header row 32px; rows 24px; 2px `surface` gaps; cells `radius-xs`.
- Day headers `label-s` `text-secondary`; today is an `accent` pill with `on-accent` and `aria-current="date"`. Hours `num-xs` `text-secondary`.
- Seven bins: 0–14 % `seq-100` · 15–29 `seq-200` · 30–44 `seq-300` · 45–59 `seq-400` · 60–74 `seq-500` · 75–89 `seq-600` · 90–100 `seq-700`. The ramp flips in Night match (full = lightest).
- Closed slot: transparent cell, 1px dashed `border-strong` (« Fermé »).
- In-cell labels `num-xs`, only at the extremes — the two lightest steps (creux) and `seq-700` (complet) — and only when the column fits « 100 % ». Ink: `text` on steps 100–400, `text-inverse` on 500–700.
- Scale legend: « 0 % » + 7 swatches 20 × 12 + « 100 % », plus the « Fermé » and « Creux repéré par l’IA » keys.
- AI annotation: a 2px `ai-500` outline around the flagged slots with a sparkle badge; the insight sits in the footer (« IA » tag, text `label`, why `caption`, a secondary action, dismiss).

## States
Hover (1px gap + 2px `text` outline; tooltip beside the cell: « jeu. 15h · 20 % occupé · 3/15 créneaux ») · keyboard focus (`focus-ring`) · table view · loading (shimmering grid) · refreshing · empty (ghost grid + message + action) · error.

## Content
- Columns « lun. … dim. » (« jeudi » for screen readers), rows « 8h … 23h »; « 20 % »; counts « 3/15 créneaux » (3 terrains × 5 semaines).
- The insight names the slot, the number and a lever: « Jeudi 14h–17h : 80 % de créneaux vides » + « Créer une offre −20 % » — it opens the offer editor and never publishes on its own.

## Accessibility
- `role="grid"` with column and row headers; one tab stop; arrows move by cell, Home / End along the row (with Ctrl to the corners), Esc hides the tooltip. Every cell is labelled (« jeudi 15h : 20 % occupé, 3/15 créneaux »).
- Ramp, validator `--ordinal`, both modes: monotone lightness PASS, adjacent ΔL ≥ 0.06 PASS, single hue (2° spread) PASS. Light-end contrast 1.14:1 (Light) / 1.26:1 (Night) misses the ordinal 2:1 floor — expected for sequential magnitude, where the lightest step means near-empty and recedes; gaps keep every cell visible and those cells carry labels.
- Label ink ≥ 4.5:1 on every labelled step: Light `seq-100` / `seq-200` 15.15 / 12.18:1 (ink), `seq-700` 11.34:1 (white); Night 12.77 / 9.35:1 and 13.25:1. Light `seq-500` (4.37 / 3.95:1) and Night `seq-400` (4.15 / 3.87:1) have no AA ink, so mid-range cells are never labelled — the tooltip and the table carry them.
- AI outline `ai-500` 4.38 / 3.94:1 on `surface`; today pill 13.2:1.

## Do / Don't
- Do keep one hue; never a rainbow or traffic-light ramp for occupancy.
- Don't print a number in every cell, and don't mark closed slots by colour alone.

## Props (web preview)
`title` · `subtitle` · `columns` · `rows` · `values` · `booked` · `capacity` · `today` · `annotation` · `insight` · `cellLabels` · `slotLabel` · `skeleton` · `refreshing` · `error` · `onRetry` · `emptyTitle` · `emptyDescription` · `emptyAction` · `view` · `defaultView` · `onViewChange` · `activeCell` · `footer`. See `index.d.ts`.

## Flutter
`MuHeatmap(title:, columns: [...], rows: [...], booked: [[...]], capacity: 15, today: 1, annotation: const MuHeatAnnotation(col: 3, from: 6, to: 8), insight: MuAiInsight(...))` — a `Table` of `MuHeatCell` (`Container` + `Focus` + `Semantics`) so focus order and labels come for free; the tooltip is an `OverlayPortal`; the annotation is a `Positioned` outline in a `Stack` above the grid.
