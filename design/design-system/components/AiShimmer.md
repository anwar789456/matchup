# AiShimmer

The AI processing state — `ai-soft` shapes crossed by a violet→blue sweep, a twinkling sparkle and named steps — shown while the AI writes, ranks or plans.

## When to use
- Instead of a spinner whenever the AI is working: drafting a recap (**lines**), finding suggestions (**card**), a short wait inside a flow (**status**), a multi-step job like a training plan (**steps**).
- Not for ordinary loading of non-AI content — that is the core Skeleton (grey, no gradient).

## Anatomy & specs
- Sweep: `ai-soft` ground + a band of `--ai-gradient-from` → `--ai-gradient-to` at 30 %, 250 % wide, crossing start → end every `duration-shimmer` (1 400 ms) on `ease-move`. RTL reverses the direction.
- **lines**: 12px bars, 10px apart, `radius-xs`; widths 100 / 94 / 97 / 88 %, the last one 58 %. Every bar spans the full width and is clipped to its length, so one wave crosses the whole paragraph.
- **card**: the AiSuggestionCard frame (gradient border, `space-4` padding) with a real AiLabel S, a title bar (18px), a 132 × 24 pill, text lines, two 32px dots and a 128 × 40 button block.
- **status**: pill `control-s` high, `radius-full`, `ai-soft` fill, sparkle 16 filled with the gradient + `label-s` in `ai-text`. The sparkle twinkles (scale 0.82, −14°) every `duration-pulse`.
- **steps**: `mu-card`, padding `space-4`. Header: sparkle + `label` + « Étape 2 sur 3 » (`caption`, numbers `num-xs`). Bar: one 6px segment per step, gap `space-1` — done segments share one continuous gradient, the running one sweeps, the rest stay `ai-soft`. List: done = `check-circle` fill `ai-text` + `body` `text`; running = sparkle in a 22px ring + `label` `ai-text` + « … »; to do = `circle-dashed` + `text-secondary`.

## Variants
| Variant | Replaces | Typical place |
|---|---|---|
| lines | a paragraph not written yet | AiTextBlock body |
| card | an AiSuggestionCard | feeds, carousels, dashboard insights |
| status | the tools of a block, an inline wait | footers, sheets, chat |
| steps | a whole result | plan generation, team balancing |

## States
- Running (animated) · **still** (`animated={false}` or `prefers-reduced-motion`): same shapes, no sweep, no twinkle.
- Steps **done**: header « C’est prêt » with a check, full gradient bar, then the result replaces the panel.

## Content
- Say what the AI is doing, with « tu »: « L’IA analyse tes disponibilités… », « L’IA compare les niveaux… », « L’IA réécrit le résumé… ».
- Steps are 2–4 nouns of real work: « Analyse de tes matchs · Comparaison des niveaux · Préparation du plan ».

## Accessibility
- Every variant is a `status` region: lines and card announce their label (visually hidden), status and steps their visible text; the running step has `aria-current="step"` and each step a hidden « terminé / en cours / à venir ».
- Motion never carries meaning: the text says what is happening.

## Do / Don't
- Do match the footprint of the content that will replace it.
- Do keep the AiLabel visible on the card placeholder — the person knows the AI is at work.
- Don't use the AI sweep for non-AI loading.
- Don't leave a shimmer running past 10 s without a message (« Ça prend plus de temps que prévu… »).

## Props (web preview)
`variant` · `lines` · `label` · `steps` · `current` · `animated`. See `index.d.ts`.

## Flutter
`MuAiShimmer.lines(count: 3)`, `.card()`, `.status(label:)`, `.steps(steps:, current:)` — one `AnimationController` (1.4 s, repeat) drives a `LinearGradient` whose `transform` slides across a `ShaderMask` over the shapes. Check `MediaQuery.disableAnimationsOf(context)` and render the still frame.
