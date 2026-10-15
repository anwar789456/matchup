# ProgressBar

Linear progress on a 4 / 6 / 8 px track — continuous, segmented (one segment per place) or game spots with confirmed, pending and free places.

## When to use
- **Bar**: profile completion, money collected, uploads of known size, AI analysis.
- **Segmented**: countable units — places in a game, sessions in a week (up to ~12 visible units).
- **Spots**: game cards and lobbies — « 8/10 joueurs » with confirmed (solid), pending payment (hatched) and free places.
- **Indeterminate** only for uploads of unknown size. Content that loads uses Skeleton, never a bar.

## Anatomy & specs
| Size | Track | Use |
|---|---|---|
| S | 4px | inside cards, under a hero countdown |
| M | 6px (default) | forms, lists, hints |
| L | 8px | spots, money, featured progress |

- Track `border`, ends `radius-xs`; fill `primary` (ink · Volt in Night match). Segments: 3px gaps, each `radius-xs`.
- Header row (`space-2` above the track): label `label` `text` at the start; value at the end — `num-s` fraction + unit `body` `text-secondary` (« 6/10 places ») or a percentage (« 80 % »).
- Pending: 45° stripes of the fill colour with a 1.5px inset outline, 2px after the solid part.
- Spots header: AvatarStack XS + « 8/10 » `num-m` + « joueurs » `body`; at the end « 2 places libres » `label-s` `text-secondary`, or StatusBadge « Complet ». Legend `caption` with 14 × 8 keys.
- Hint under the track: `caption` `text-secondary`; the error tone adds `warning-circle` and `error-text`.

## Variants
`bar` · `segmented` · `spots`; tones `primary` (default) · `success` · `warning` · `error` · `info` · `ai` (`ai-gradient`, AI tasks only; AI segments use `ai-500`). Sport colours are never fills.

## States
- Determinate: the fill animates its width over `duration-slow`, `ease-move`.
- Indeterminate: a 36 % segment slides start → end over `duration-shimmer`, looping; under reduced motion it is a static full bar at 35 % opacity while the label still says « Envoi… ».
- Complete: switch to `success` and say it in the hint (« Tout le monde a payé sa part. »).
- Error: keep the reached value, `error` fill, and a hint that says what to do.

## Content
- Countable units as fraction + unit: « 6/10 places », « 14/20 matchs »; money with `formatDT`: « 90/150 DT ».
- Spots always say what is left: « 2 places libres », or « Complet ».
- Uploads name the thing (« Envoi de la photo du terrain… ») and put the file name in the hint.

## Accessibility
- `role="progressbar"` with min / max / now and `aria-valuetext` (« 6 sur 10 places », « 8 joueurs sur 10, dont 2 en attente », « 90/150 DT, plus 30 en attente »), named by the label; the hint is linked with `aria-describedby`.
- Indeterminate omits `aria-valuenow` and sets `aria-busy`.
- Pending is hatched and outlined, not just lighter; the legend repeats every count in words.

## Do / Don't
- Do show the number with the bar — a bar alone is decoration.
- Do use the stacked (pending) form for shared payments so organisers see who still has to pay.
- Don't use the AI gradient for non-AI progress.
- Don't put an indeterminate bar on page content — use Skeleton.

## Props (web preview)
`value` · `max` · `pending` · `variant` · `size` · `tone` · `label` · `unit` · `valueLabel` · `showValue` · `hint` · `indeterminate` · `people` · `legend`. See `index.d.ts`.

## Flutter
`MuProgressBar(value: 6, max: 10, pending: 0, variant: MuProgressVariant.segmented, size: MuProgressSize.l, tone: MuTone.primary, label: 'Places réservées', unit: 'places')` — a `ClipRRect` track with an `AnimatedFractionallySizedBox` fill (`MuMotion.slow`), a `Row` of `Expanded` segments for segmented / spots, and a `CustomPainter` for the hatch; indeterminate is an `AnimationController` sliding a 36 % box (stopped when `MediaQuery.disableAnimations`). Expose `Semantics(value: '6 sur 10 places')`.
