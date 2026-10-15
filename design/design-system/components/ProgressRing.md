# ProgressRing

Circular progress at 32 / 48 / 72 / 120 px with the value in the centre in Barlow — programs « 3/12 séances », goals, uploads — and a success medal when complete.

## When to use
- Program and goal progress on cards (72) and detail headers (120).
- Compact status in lists: 48 with « 25 % », 32 without text next to a label.
- Use ProgressBar for linear flows and money; a ring answers "how much of a whole is done".

## Anatomy & specs
| Size | Stroke | Centre | Check |
|---|---|---|---|
| 32 | 4 | none (label beside it) | 16 |
| 48 | 5 | `num-xs` | 20 |
| 72 | 6 | `num-m` « 3/12 » | 28 |
| 120 | 8 | `num-xl` « 3/12 » + unit `caption` `text-secondary` « séances » | 40 |

- Track `border`; arc `primary` (ink · Volt in Night match) with round caps, starting at 12 o'clock and running clockwise — not mirrored in RTL.
- Complete: arc `success`, an inner `success-soft` disc inset by the stroke + 3px, and a 2.6-unit check in `success-text`.

## Variants
Tones `primary` (default) · `success` · `warning` · `error` · `info` · `ai` (gradient `ai-gradient-from` → `ai-gradient-to`, AI tasks only). Formats: fraction « 3/12 » (default when `unit` is set or max ≠ 100) · percentage « 62 % ».

## States
- Empty (0): track only — no dot.
- In progress: the arc animates `stroke-dashoffset` over `duration-counter`, `ease-move`.
- Complete (value = max): success medal + check, popping in with `ease-pop`.

## Content
- A fraction when the unit is countable (« 3/12 », unit « séances »); a percentage otherwise (« 62 % », narrow no-break space).
- Pair the ring with a line that says what's next: « Prochaine séance jeu. 15 oct. · 18h30 ».

## Accessibility
- `role="progressbar"` with min / max / now, `aria-valuetext` « 3 sur 12 séances » (+ « terminé ») and `aria-label` naming what progresses (« Programme Vitesse »); the centre text is hidden from AT.
- Completion is a check shape, not only a colour change.

## Do / Don't
- Do keep one ring per card — it is the card's focal stat.
- Don't write words longer than « séances » inside; the 72 ring holds numbers only.
- Don't use rings for countdowns (Countdown) or for loading content (Skeleton).

## Props (web preview)
`value` · `max` · `size` · `stroke` · `tone` · `format` · `unit` · `label` · `showValue`. See `index.d.ts`.

## Flutter
`MuProgressRing(value: 3, max: 12, size: 72, tone: MuTone.primary, unit: 'séances', label: 'Programme Vitesse')` — a `CustomPainter` (`drawArc`, `StrokeCap.round`, `SweepGradient` for AI) inside a `TweenAnimationBuilder<double>` (`MuMotion.counter`), centre `Text` in `MuType.numM` with tabular figures, and `Semantics(value: '3 sur 12 séances')`.
