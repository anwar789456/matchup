# AiLabel

The « IA » mark every AI output carries — a sparkle and two letters that say the AI made this, before anyone reads further.

## When to use
- On everything the AI writes, ranks or scores: suggestion cards, match recaps, plan summaries, post drafts, match-fit scores, assistant answers.
- **surface** (default) on cards, rows and screen headers; **media** on photos, posters and the dark dashboard sidebar; **inline** under text the person can reuse.
- Not on plain algorithmic features (sort by distance, filters, availability): no AI content, no label.

## Anatomy & specs
| Size | Height | Padding (inline) | Gap | Sparkle | Text |
|---|---|---|---|---|---|
| S | 20 | 5 / 6 | 3 | 12 | « IA » in `overline` |
| M | 24 | 7 / 8 | `space-1` | 14 | « IA » in `overline` |

- Radius `radius-full`. The sparkle is Phosphor `sparkle`, fill weight — the only AI glyph.
- **surface**: `ai-soft` fill, `ai-text` sparkle and text. Inside an AiTextBlock (already `ai-soft`) the chip turns `surface`.
- **media**: `ink-900` at 80 % with an 8px backdrop blur, a 1px inner ring of `white` at 16 %, `white` text, the sparkle filled with `--ai-gradient`. Pin it top-start, `space-3` from the edges, on the darker part of the image.
- **inline**: no pill. Sparkle 16 + `label-s` (S: 14 + `caption`) in `ai-text`, gap 6.
- M sits beside `h2`/`h3` titles; S in cards, list rows and on photos.

## Variants
| Variant | Ground | Text | Use |
|---|---|---|---|
| surface | `ai-soft` | `ai-text` | cards, headers, rows |
| media | `ink-900` 80 % + blur | `white`, gradient sparkle | photos, posters, `nav-bg` |
| inline | none | `ai-text` | provenance under text |

## States
Static. The label never animates and is never a button — AiShimmer carries the « working » motion, AiSuggestionCard the actions.

## Content
- Chips say « IA ». Never « AI », « Smart », « Magic », a robot or an emoji.
- Inline text states provenance: « Généré par l’IA », « Résumé généré par l’IA », « Rédigé avec l’IA · modifié par Yassine ».
- When a person edits AI text, keep the label and add « modifié par toi ».

## Accessibility
- The visible « IA » is hidden from screen readers and replaced by « Généré par l’IA » (`srLabel`, also the tooltip).
- Never colour alone: the sparkle and the letters always travel together.
- `ai-text` on `ai-soft`: 4.6:1 Light, 6.0:1 Night match. Media pill: `white` ≥ 9:1 even over a white photo; the gradient sparkle ≥ 3:1 over court colours.

## Do / Don't
- Do place it where the eye lands first: before the title, the top corner of a photo, under a recap.
- Do keep it after the person edits the content — provenance doesn't expire.
- Don't put two labels on one output (a card and the text inside it).
- Don't use `ai-*` or the gradient to decorate anything that isn't AI.

## Props (web preview)
`variant` · `size` · `children` (visible text) · `srLabel`. See `index.d.ts`.

## Flutter
`MuAiLabel(variant: MuAiLabelVariant.surface, size: MuAiLabelSize.m, text: 'IA')` — a `StatelessWidget` returning a `DecoratedBox(shape: StadiumBorder)` around a `Row` of sparkle and text. Media: `ClipRRect` + `BackdropFilter(ImageFilter.blur(sigmaX: 8, sigmaY: 8))`; paint the sparkle through `ShaderMask(shaderCallback: MuGradients.ai.createShader)`. Wrap in `Semantics(label: 'Généré par l’IA', excludeSemantics: true)`.
