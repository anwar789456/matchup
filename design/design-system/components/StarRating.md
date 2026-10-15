# StarRating

Shows a rating — « 4,7 » + « (128 avis) » with half stars — or collects one from 1 to 5, like the post-game « Niveau » and « Fair-play » quick rating.

## When to use
- **Display**: venue ratings on cards (16), lists (20) and the venue header (28); compact « ★ 4,7 (128) » on map pins and tight cards.
- **Input**: the post-game quick rating of teammates, the venue review after a booking.
- Not for levels (use the 1,0–7,0 scale) or reliability (« Fiable 96 % »).

## Anatomy & specs
| Size | Use | Star gap | Value | Count |
|---|---|---|---|---|
| 16 | cards, compact | 1px | `num-s` | `caption`, `text-secondary` |
| 20 (default) | lists | 2px | `num-s` | `caption` |
| 28 | input, venue header | input: 44×44 targets | `num-m` | `caption` |

- **Filled**: `warning` fill with a 1px `warning-text` edge, so every star reaches 3:1 on white. **Empty**: 1.5px `border-control` outline. **Half**: inline-start half filled (mirrored in RTL).
- Display rounds the stars to the nearest half (4,7 → 4½, 4,2 → 4) and prints the exact value.
- Input row: optional 88px label column (`label` + the word in `label-s`, « À noter » in `caption` when empty), then five 44×44 buttons; without a label the word follows the stars in `label` (« Touche pour noter » in `body`, `text-secondary`).

## States
- **Hover** (input): stars fill up to the pointer, the hovered star scales to 1.15 (`ease-pop`), the word previews (« Bien »).
- **Pressed**: 0.9. **Focus**: `focus-ring` (`radius-sm`) around the current star.
- **Disabled** (already sent): filled stars `text-disabled`, empty ones `border-strong`, words `text-disabled`.

## Content
- One decimal with a comma: « 4,7 »; thousands with a thin space: « (1 250 avis) ».
- Default words: Décevant · Moyen · Correct · Bien · Excellent. Fair-play: Mauvais esprit · Limite · Correct · Sympa · Exemplaire.
- Ask briefly — « Note tes coéquipiers » — and send with « Envoyer mes notes ».

## Accessibility
- Display is one `role="img"`: « Note 4,7 sur 5, 128 avis ».
- Input is a `radiogroup` of five `radio` buttons named « 4 sur 5 · Bien »: arrows ±1 (mirrored in RTL), Home/End, number keys 1–5, one Tab stop.
- Stars are never the only cue: the word and the number carry the value.

## Do / Don't
- Do keep input stars at 28px with 44px targets; 16 and 20 are for display.
- Do let players send one criterion without the other.
- Don't show half stars in input.
- Don't colour stars Volt or with sport colours.

## Props (web preview)
`value` · `defaultValue` · `onChange` · `readOnly` · `size` · `compact` · `showValue` · `count` · `label` · `labels` · `showWord` · `disabled`. See `index.d.ts`.

## Flutter
`MuStarRating.display(value: 4.7, count: 128, size: 20)` and `MuStarRating.input(value:, onChanged:, label: 'Fair-play', labels: […])` — stars painted by a `CustomPainter` (fill `warning`, 1px `warningText` stroke; the half star clipped with a `ClipRect` that respects `Directionality`); input = five 44px `InkResponse`s in `Semantics(inMutuallyExclusiveGroup: true)`.
