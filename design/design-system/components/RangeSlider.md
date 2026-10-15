# RangeSlider

A two-thumb slider for a min–max filter — price per person, distance, level range — with a value bubble while dragging.

## When to use
- Filters over a continuous range: « Prix par personne » 0–100 DT, « Distance » 0–20 km, « Niveau des joueurs » 1,0–7,0 (step 0,5).
- One value only (a player's level) → LevelSlider; an exact number → a field; 2–4 fixed buckets → Chips.

## Anatomy & specs
| Part | Spec |
|---|---|
| Header | label (`label`, `text`) at the start, current range (`num-m`, `text`) at the end |
| Hit area | 44 tall (`touch-target`), inset 12px each side so the thumbs stay inside |
| Track | 4px, `radius-full`, `border`; active segment `primary` (ink in Light, Volt in Night match) between the thumbs |
| Thumb | 24, `surface`, 1.5px `border-control`, `elevation-1`, invisible 44px hit circle |
| Bubble | `surface-inverse` / `text-inverse`, `num-s`, `radius-sm`, 8px caret, 10px above the thumb |
| Limits | `caption`, `text-secondary`, under the track ends (« 0 DT », « 100 DT ») |
| Bands | optional: the track splits at band edges with 3px gaps; names in `caption` under it (bands inside the range: `label-s`, `text`) — needs ≥ 320px |

## States
- **Hover**: thumb ring → `text`.
- **Dragging**: 2px `primary` ring + `elevation-2`; the bubble shows the dragged value and the header value fades out (`duration-fast`) so the two never collide.
- **Keyboard focus**: `focus-ring` + bubble.
- **Disabled**: fill `text-disabled`, thumbs `border-strong` without shadow, header `text-disabled`.
- Thumbs never cross: the smallest gap is one step (`minDistance`).

## Content
- Format with the helpers: `formatDT` (« 10 DT – 45 DT »), `formatLevel` (« 3,0 – 4,5 »), « 8 km ».
- Say open ends in words: « Jusqu’à 8 km » when the minimum is 0.
- Filter on the price per person, never on the court price.

## Accessibility
- Each thumb is a `role="slider"` named « Prix minimum » / « Prix maximum », bounded by the other thumb (`aria-valuemin/max`), with a French `aria-valuetext` « 10 DT à 45 DT » (« 3,0 à 4,5 » for levels). The group is labelled by the header label.
- Keys: arrows ±1 step (mirrored in RTL), PageUp/Down ±10 % (levels: one band), Home/End to the limit.
- Pointer: a tap on the track moves the nearest thumb; a drag keeps the grab offset.

## Do / Don't
- Do refresh results on `onChangeEnd`, not on every step.
- Do show the bubble only while interacting — at rest the header carries the value.
- Don't paint the track Volt in Light: Volt is the Night match `primary`, ink is the Light one.
- Don't stack more than three sliders without section titles.

## Props (web preview)
`value` · `defaultValue` · `onChange` · `onChangeEnd` · `min` · `max` · `step` · `pageStep` · `minDistance` · `label` · `format` · `formatRange` · `minLabel` · `maxLabel` · `bands` · `showLimits` · `disabled`. See `index.d.ts`.

## Flutter
`MuRangeSlider(values: RangeValues(10, 45), min: 0, max: 100, divisions: 100, label:, format: formatDT, bands:)` — Material `RangeSlider` themed with `SliderThemeData` (trackHeight 4, a 24px `RangeSliderThumbShape` with a 1.5px `borderControl` edge, `RangeSliderValueIndicatorShape` paddle in `surfaceInverse`, value indicator only while dragging) under a header `Row`; paint band gaps with a custom `RangeSliderTrackShape`.
