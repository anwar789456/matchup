# ProgramCard

The training-program tile: cover art, sport and level, coach, length, rating and price — or, once the player has joined, progress and « Continuer ».

## When to use
- **Default** in the Entraînement catalogue (carousels and grids, 264–358 wide) and on coach pages.
- **Compact** in « Mes programmes », search results and any one-per-row list of programs.
- One session of a program is a **LessonCard**, not a ProgramCard.

## Anatomy & specs
| Part | Default | Compact |
|---|---|---|
| Surface | `mu-card`: `surface`, `radius-md`, `elevation-1` | same, padding `space-3`, gap `space-3` |
| Cover | CourtArt photo or pattern, 16:9, top corners `radius-md` | 64×64 thumbnail, `radius-sm` |
| Chips | Chip sport + Chip level, size S, gap `space-2` | — |
| Title | `label-l`, 2 lines max | `label`, 2 lines max |
| Coach | Avatar XS + « Coach Karim S. » `body` `text-secondary` + verified seal 16 | `caption`, seal 14 |
| Meta | « 4 sem. · 12 séances · 25 min/jour » `body` `text-secondary` | `caption`, one line |
| Footer | hairline `border`; ★ + `num-s` rating + `caption` count; price `num-m` | price `num-m` over rating `num-xs` |

- Body padding `space-4`; chips → title `space-3`, title → coach `space-2`, coach → meta `space-1`. The footer is pinned to the bottom so cards in a row align.
- Verified seal: Volt `accent` disc with the `on-accent` seal-check — the language of StatusBadge « Vérifié ».
- « Inclus dans Premium »: Volt badge (`accent` / `on-accent`, crown icon) in the price slot; « Premium » in compact.

## Variants
- **available** — rating and price, or the Premium badge.
- **enrolled** — « 3/12 séances » (`num-m` + `body`), percent `num-s` `text-secondary`, 6px bar (`primary` on `border`, `radius-xs` ends), « Prochaine : Séance 4 · Lob défensif » `caption`, primary M « Continuer » with play icon. Compact: 44px ring (`primary` on `border`) with « 3/12 » `num-xs`.
- **completed** — « 8/8 séances » + StatusBadge « Terminé », full `success` bar, completion line, secondary M « Noter le programme ». Compact: full `success` ring with a check.

## States
- Hover → `elevation-2`; pressed → `scale-press` (0.98, `duration-fast`); focus → `focus-ring` around the whole card.
- Loading: `skeleton` renders the same layout with Skeleton blocks (cover, two pills, two title lines, coach row, meta, footer).

## Content
- Title = outcome + duration, sentence case: « Service canon en 4 semaines », « Finition devant le but ».
- Always prefix the coach: « Coach Amel T. ». Price for the whole program: « 89 DT », « 120 DT ».
- Rating with a comma, count in brackets: « 4,8 (96) ». Completion line: « Le dim. 12 oct. · 8 séances en 13 jours ».

## Accessibility
- The card is an `article` labelled by its title; the title is a stretched link covering the card, and « Continuer » sits above it with its own name — no nested links.
- The rating announces « Note 4,8 sur 5, 96 avis »; the bar is a `progressbar` « 3 séances sur 12 ».
- Cover art is decorative; the sport is given in text by the sport chip.

## Do / Don't
- Do show the price or the Premium badge — never both.
- Do keep « Continuer » as the only primary action, and only when enrolled.
- Don't tint the card border by sport; the sport lives in the chip and the cover.
- Don't shorten the title to one line in the default card; let it wrap to two.

## Props (web preview)
`title` · `coach` · `sport` · `level` · `weeks` · `sessions` · `minutesPerDay` · `rating` · `reviews` · `price` · `premium` · `cover` · `status` · `progress` · `nextLesson` · `completedOn` · `variant` · `skeleton` · `href` / `onClick` · `onContinue` · `onRate`. See `index.d.ts`.

## Flutter
`MuProgramCard(program:, variant: MuCardVariant.regular, status: MuProgramStatus.enrolled, progress: 3, onTap:, onContinue:, onRate:)` — a `StatelessWidget` on `MuCard` (Material `Card` + `InkWell`, `radius-md`, `AnimatedScale(0.98)` on press). Cover: `AspectRatio(16 / 9)` + `MuCourtArt`; progress: `LinearProgressIndicator` (6px, `primary` on `border`) or `CircularProgressIndicator` in compact. Skeleton: `MuSkeleton` blocks in the same `Column`.
