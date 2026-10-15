# LessonCard

One session of a training program — video thumbnail with play button and duration, « Séance 3 · Placement au filet », drill count and its state (done, today, locked).

## When to use
- **Default** for the session list on a program page, one card per session, gap `space-3`.
- **Compact** for the numbered playlist under the video player and in dense lists.
- A whole program is a **ProgramCard**.

## Anatomy & specs
| Part | Default | Compact |
|---|---|---|
| Surface | `mu-card`, padding `space-3`, gap `space-3` | same, end padding `space-4` |
| Media | CourtArt photo 128 wide, 16:10, `radius-sm`, `photo-scrim` | 36px index circle |
| Play | 36px disc, `white` with `ink-900` glyph (a media overlay, same in both themes), `elevation-2` | — |
| Duration | « 12 min » `num-xs`, `white`, bottom end of the thumbnail | in the meta line |
| Eyebrow | « SÉANCE 3 » `overline` `text-secondary` | — |
| Title | `label`, 2 lines max | `label`, 1 line |
| Meta | « 4 exercices · Hors ligne » `caption` `text-secondary` | « 12 min · 4 exercices » |

- Watched progress: a 3px Volt (`accent`) bar along the thumbnail bottom, from the start edge.
- Index circle: `surface-muted` with a `border` hairline and the number in `num-s`.

## Variants
- **available** — play disc; number in compact.
- **current** — Volt play disc, Volt badge « À faire aujourd’hui » (« Aujourd’hui » in compact), a 2px `primary` ring inside the card edge. One per program.
- **done** — « ✓ Terminée » in `success-text` with check-circle; compact index becomes `success-soft` with a check.
- **locked** — `scrim` over the thumbnail, lock in the disc, Volt badge with lock « Premium »; the card opens the paywall.
- **downloaded** — « Hors ligne » with cloud-check in the meta, combinable with any state.

## States
- Hover → `elevation-2` and the play disc grows to 1.08 (`ease-pop`); pressed → `scale-press`; focus → `focus-ring`.
- Loading: `skeleton` keeps the thumbnail (or index circle), eyebrow, title and meta shapes.

## Content
- Eyebrow « Séance 3 », title is the skill in sentence case: « Placement au filet », « Lob défensif ».
- Count drills: « 1 exercice », « 4 exercices ». Durations in minutes: « 12 min ».
- State labels: « Terminée », « À faire aujourd’hui », « Premium », « Hors ligne ».

## Accessibility
- The card is labelled « Séance 3 · Placement au filet »; the title is a stretched link that starts the video (or opens the paywall when locked) and carries the state for screen readers: « Placement au filet · à faire aujourd’hui ».
- Status is colour + icon + label (« Terminée », « Premium »), never the ring or the Volt alone.
- Thumbnail, play disc and duration overlay are decorative; the duration is repeated in text in compact.

## Do / Don't
- Do mark exactly one session « À faire aujourd’hui ».
- Do keep locked sessions readable at full contrast — locked is not disabled.
- Don't use a spinner while the list loads; use the skeleton.
- Don't mirror the play glyph in RTL (media controls never mirror).

## Props (web preview)
`index` · `title` · `duration` · `drills` · `sport` · `status` · `progress` · `downloaded` · `variant` · `skeleton` · `href` / `onClick`. See `index.d.ts`.

## Flutter
`MuLessonCard(lesson:, status: MuLessonStatus.current, progress: 0.35, downloaded: true, variant: MuCardVariant.compact, onTap:)` — a `Row` inside `MuCard`; thumbnail = `ClipRRect(radius-sm)` + `Stack` (`MuCourtArt`, scrim `DecoratedBox`, play disc, duration `Text`, `FractionallySizedBox` watched bar). Current ring: `foregroundDecoration` with a 2px `primary` border.
