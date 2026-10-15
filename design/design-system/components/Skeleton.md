# Skeleton

A shimmering placeholder shaped like the content it replaces — text lines, circles, pills and blocks — used for every content load instead of a spinner.

## When to use
- Lists, cards, profiles, tables and charts while their data loads: compose Skeleton blocks in the component's real layout (every card's `skeleton` prop does this).
- Not for actions (Button `loading`), payments (LoadingOverlay) or AI generation (AiShimmer).

## Anatomy & specs
| Shape | Size | Radius |
|---|---|---|
| rect (default) | `width` × `height` | `radius-sm`; override with `radius` (`radius-md` for a card cover) |
| text | 12 high, full width (or `width`); `lines` stack `space-2` apart, the last at 62 % | `radius-xs` |
| circle | `width` × `height` — the avatar size (24–96) | `radius-full` |
| pill | `width` × `height` — a chip (32) or button | `radius-full` |

- Fill `skeleton`; a `skeleton-highlight` band sweeps across over `duration-shimmer` (1.4 s) with `ease-move`, repeating.
- Both colours read on `bg` and `surface` in Light and Night match.
- **SkeletonGroup** wraps a loading region: `role="status"`, `aria-live="polite"`, `aria-busy="true"` and a visually hidden label (default « Chargement… »). It adds no box of its own (`display: contents`).

## Variants
`rect` · `text` · `circle` · `pill`.

## States
- **Loading**: shimmering. **Reduced motion**: the sweep stops and the blocks stay.
- **Loaded**: the content takes the blocks' place at the same size, with no layout jump.
- **Failed**: replace the skeleton with an error that says what to do (« Réessayer »); never leave it shimmering.

## Content
- Mirror the real layout: a 40 circle for the avatar, two text lines, a pill for the price — not a generic grey card.
- Name what loads in the group label: « Chargement des parties ».
- Show about as many items as will arrive (three cards, not twelve).

## Accessibility
- Blocks are `aria-hidden`; only the SkeletonGroup announces, once, politely.
- Blocks carry no meaning and are exempt from contrast; nothing in a skeleton is focusable.
- Motion never conveys anything here; the reduced-motion version is complete.

## Do / Don't
- Do keep headers, tabs and buttons live while the content below loads.
- Do reuse the component's own `skeleton` layout rather than a generic block.
- Don't put a Spinner inside or over a skeleton.
- Don't tint skeletons with sport or AI colours (AI loading is AiShimmer).

## Props (web preview)
`shape` · `width` · `height` · `lines` · `radius` · `style`; SkeletonGroup: `label` · `children`. See `index.d.ts`.

## Flutter
`MuSkeleton(shape: MuSkeletonShape.text, width:, height:, lines: 2, radius:)` and `MuSkeletonGroup(label: 'Chargement des parties', child:)` — blocks are `DecoratedBox`es in `colors.skeleton`. The group runs one `AnimationController` (1400 ms, repeat) and paints the sweep with a `ShaderMask(blendMode: BlendMode.srcATop)` and a `LinearGradient(skeleton → skeletonHighlight → skeleton)` translated by the animation, stopped when `MediaQuery.disableAnimations` is true. The group is `Semantics(liveRegion: true, label:)` with its blocks in `ExcludeSemantics`.
