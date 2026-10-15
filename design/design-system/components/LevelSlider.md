# LevelSlider

Picks one level on the MatchUp 1,0–7,0 scale (step 0,5) with a big readout and the four bands — and, after the AI questionnaire, shows the « IA » estimate as a marker above the track.

## When to use
- Setting or adjusting a player's level for one sport: the onboarding « Ajuster » step, profile editing.
- With `aiEstimate` right after the AI questionnaire, so the player sees the estimate and can move away from it.
- Compact (`readout={false}`) for a required level in a form (« Niveau minimum requis »). Level *ranges* in filters → RangeSlider with bands.

## Anatomy & specs
| Part | Spec |
|---|---|
| Label | `label`, `text-secondary`; compact: `text`, with « 3,0 Intermédiaire » (`num-m` + `label`) at the end of the row |
| Readout | value `num-xl` « 3,5 » + band `h3` « Intermédiaire », `space-3` apart on one baseline |
| Track | 6px, one segment per band with 3px gaps; `primary` fill up to the thumb, `border` after it |
| Thumb | 28, `surface`, 2px `border-control`, `elevation-1`, 44px hit circle |
| Bands | four equal columns: name `caption` (current band `label-s`, `text`) over its range in `num-xs` (« 2,5–4 ») |
| AI marker | 22px pill: `ai-soft` fill, 1px `ai-500` ring, 14px sparkle `ai-500`, « IA » `label-s` + « 3,5 » `num-xs` in `ai-text`; 1.5px `ai-500` stem down to the track |
| AI note | `caption`, `text-secondary`: « Estimé par l’IA : 3,5 · d’après tes réponses » + Link button « Revenir à 3,5 » |

- Bands follow `levelLabel`: Débutant 1,0–2,5 · Intermédiaire 2,5–4,0 · Avancé 4,0–5,5 · Expert 5,5–7,0.
- AI colours appear on the marker only; track, thumb and readout stay neutral.

## States
- **Dragging**: 2px `primary` thumb ring + `elevation-2`; the readout is the live value (no bubble).
- **Hover**: thumb ring → `text`. **Focus**: `focus-ring` on the thumb.
- **Disabled** (level set by a coach): fill and readout `text-disabled`, no pointer.
- **AI**: the marker stays on the estimate; « Revenir à 3,5 » shows only while the value differs.

## Content
- Always pair the number with the band: « 3,5 · Intermédiaire ».
- Explain the estimate (« d’après tes réponses ») and that it can be changed later; the CTA confirms: « Confirmer mon niveau ».
- In onboarding, describe the current band under the slider (« Tu tiens l’échange et tu commences à placer la balle. »).

## Accessibility
- `role="slider"` labelled by the visible label, `aria-valuetext` « 3,5 – Intermédiaire »; the AI note is linked with `aria-describedby`.
- Keys: arrows ±0,5 (mirrored in RTL), PageUp/Down ±1,5 (one band), Home/End 1,0 / 7,0. A tap anywhere on the track jumps there.

## Do / Don't
- Do let the player override the AI without friction; never save the estimate without « Confirmer mon niveau ».
- Don't colour bands with status or sport colours — a level is not good or bad.
- Don't hide the scale: band names and ranges stay visible.

## Props (web preview)
`value` · `defaultValue` · `onChange` · `onChangeEnd` · `label` · `aiEstimate` · `aiNote` · `readout` · `min` · `max` · `step` · `disabled`. See `index.d.ts`.

## Flutter
`MuLevelSlider(value: 3.5, onChanged:, label: 'Niveau padel', aiEstimate: 3.5, readout: true)` — Material `Slider(min: 1, max: 7, divisions: 12)` with a custom `SliderTrackShape` painting the four segments and a 28px thumb shape; the AI pill is `Positioned` in a `Stack` at `(estimate − 1) / 6` of the track width; the readout uses an `AnimatedSwitcher`.
