# CourtArt

The art-directed stand-in for photography: amateur courts under evening floodlights, coded by sport, used wherever MatchUp would show a photo.

## When to use
- **photo** — venue galleries, the featured GameCard header (16:9), program covers, lesson thumbnails; any aspect ratio.
- **poster** — tournament posters and covers at 3:4.
- **pattern** — quiet square thumbnails (64 in lists, upload tiles) where a full scene would be noise.
- In production, show the venue's real photo; keep CourtArt as the fallback while it loads or when there is none. Never a grey box.

## Anatomy & specs
| Variant | Canvas | Content | Theme |
|---|---|---|---|
| photo | 400 × 240, cover-cropped | night sky `night-900` → `ink-900`; two floodlights with white beams and glow; the court in perspective in `<sport>` with `court-line` markings (padel adds glass walls and the net, basketball the hoop); ground `night-800` | fixed — the same in both themes, like a photo |
| poster | 300 × 400 (3:4), cover-cropped | `<sport>` ground, bold court circles and lines at 55 %, a `volt-400` ball with an `ink-900` seam at the top right, an `ink-900` fade (0 → 85 %) over the bottom 37 % for a title | fixed |
| pattern | 120 × 120, cover-cropped | `<sport>-soft` ground, court outline in `<sport>-text` at 55 % | follows the theme |

- The art fills its box: size it with `style` (`width` + `aspectRatio`, or `width` + `height`). The root clips (`overflow: hidden`), so a radius on it applies — `radius-md` on cards, `radius-sm` on 64 thumbs.
- `children` render in a full-height layer above the art: put `photo-scrim` under any text, then `white` text or a StatusBadge.

## Variants
`photo` (default) · `poster` · `pattern` × `football` (default) · `padel` · `basketball`.

## States
Static: no hover or motion of its own. The parent card supplies hover, press and focus.

## Content
- Match the sport of the venue or game: Arena Five → football, Smash Padel Club → padel, Hoop Zone → basketball.
- Keep overlays short: a StatusBadge « EN DIRECT », an `overline` « PARTIES POUR TOI », a time `num-xl` « 20h00 ».

## Accessibility
- Decorative by default. Pass `label` (« Terrain de padel, Smash Padel Club ») only when the image adds information; it becomes `role="img"`.
- Text over photo art needs `photo-scrim` beneath it; keep it in the lower part, over the scrim's dark end. The poster's own fade plays that role.
- The art is an image: it is not mirrored in RTL. Overlays use logical positions (`inset-inline-start`).

## Do / Don't
- Do let the art bleed to the card edges and clip it with the card radius.
- Do show one sport per image; a multi-sport venue uses the sport of the item shown.
- Don't tint, blur or recolour photo and poster per theme — they are fixed like a photograph.
- Don't lay text on photo art without `photo-scrim`.
- Don't use CourtArt for avatars, logos or empty states (EmptyState has its own art).

## Props (web preview)
`sport` · `variant` · `label` · `style` · `children`. See `index.d.ts`.

## Flutter
`MuCourtArt(sport: MuSport.padel, variant: MuCourtArtVariant.photo, semanticLabel:, child:)` — a `CustomPainter` per variant that scales its fixed canvas (400 × 240, 300 × 400, 120 × 120) to cover the box, centred (`BoxFit.cover` maths); photo and poster use fixed palette colours, pattern reads `MuTheme`. Size it with `AspectRatio`, clip with `ClipRRect`, and lay `child` in a `Stack` over a `DecoratedBox(gradient: MuGradients.photoScrim)`. For real photos use `Image.network(frameBuilder:)` and return `MuCourtArt` until the first frame arrives.
