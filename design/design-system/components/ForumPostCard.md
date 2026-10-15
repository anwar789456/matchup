# ForumPostCard

A community thread in the forum feed — category, sport, title, two-line excerpt, tags, author with level, votes, replies and « Meilleure réponse ».

## When to use
- **Default** in the Communauté feed and category pages (358 on mobile, up to 640 on desktop).
- **Compact** for « Discussions populaires » on Home, search results and profile activity.

## Anatomy & specs
| Part | Spec |
|---|---|
| Surface | `mu-card`, padding `space-4`, gap `space-3` |
| Top row | category icon 16 + `overline` `text-secondary`, Chip sport S, « Épinglé » (push-pin fill + `label-s`), IconButton S « Plus d’options » |
| Title | `label-l`, 2 lines max; compact `label`, 1 line |
| Excerpt | `body` `text-secondary`, 2 lines max |
| Tags | « #service #débutant » `label-s` `text-secondary`, gap `space-3`; StatusBadge S « Meilleure réponse » (success, check) at the end |
| Footer | hairline `border`, padding-top `space-3`: Avatar M with level badge + name `label-s` + time `caption`; vote capsule; replies |
| Vote capsule | `surface-muted`, `border` ring, `radius-full`: IconButton S up · score `num-s` · IconButton S down |
| Compact | 40px category circle (`surface-muted`, `border` ring) · title · meta `caption` · counts `num-xs` with arrow and bubble icons |

- Phone width (card ≤ 372): « Épinglé » and « réponses » collapse to icon + count (container query); screen readers still hear the words.

Categories and icons: Conseils & technique (lightbulb) · Équipement (t-shirt) · Terrains (sport-court) · Tournois (sport-trophy) · Discussions libres (chats-circle).

## Variants
- **pinned** — « Épinglé » in the top row (pin icon in compact meta).
- **hidden** — content collapsed: dashed `border-strong` well on `surface-muted`, eye-slash circle, « Masqué par la modération · en cours de vérification »; no votes, no link.
- **reported** — full-bleed `warning-soft` strip at the bottom: flag (`warning-text`) + « Tu as signalé ce message. La modération va le vérifier. » + link « Annuler ».

## States
- Voted: the chosen arrow is a Volt (`accent`) disc with the fill icon and `on-accent` glyph; the score includes the vote. Tap again to remove.
- Hover → `elevation-2`; pressed → `scale-press`; focus → `focus-ring` (title is a stretched link; votes and menu sit above it).
- Loading: `skeleton` keeps top row, title, two excerpt lines and footer shapes.

## Content
- Titles are real questions or facts: « Comment rendre mon service plus régulier ? ».
- Tags lowercase without spaces: « #raquette », « #lamarsa ». Time is relative: « il y a 2 h », « hier ».
- Counts in words: « 1 réponse », « 12 réponses ».

## Accessibility
- Vote buttons are toggle buttons « Voter pour » / « Voter contre » (`aria-pressed`), 44px hit areas; the score is `aria-live` polite.
- The hidden placeholder is announced « Message masqué par la modération »; the reported strip is `role="status"`.
- Best answer and pinned are colour + icon + label.

## Do / Don't
- Do keep one sport chip; the category is the eyebrow, not a second chip.
- Do collapse hidden posts completely — no blurred text.
- Don't colour the vote arrows red/green; the voted state is the Volt fill.
- Don't show the menu on a hidden post.

## Props (web preview)
`category` · `sport` · `title` · `excerpt` · `tags` · `author` · `time` · `votes` · `vote` · `onVote` · `replies` · `bestAnswer` · `pinned` · `moderation` · `onUndoReport` · `onMore` · `variant` · `skeleton` · `href` / `onClick`. See `index.d.ts`.

## Flutter
`MuForumPostCard(post:, vote: MuVote.up, onVote:, moderation: MuModeration.reported, variant: MuCardVariant.regular, onTap:)` — `MuCard` + `Column`; vote capsule = `DecoratedBox(StadiumBorder)` with two `MuIconButton.s(toggle)` and an `AnimatedSwitcher` score; reported strip = `ClipRRect` bottom corners + `ColoredBox(warning-soft)`.
