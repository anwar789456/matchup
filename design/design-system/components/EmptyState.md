# EmptyState

The empty list, tab or panel done right: a flat sport-colour illustration, one title, one helpful sentence and one action — never a dead end.

## When to use
- Nothing to show yet or for these filters: no upcoming matches, no notifications, no program, no search results, an empty table.
- **compact** inside cards, panels, tables and sheets; full size for a whole screen or tab.
- Not for errors (Banner, or an inline error with « Réessayer ») or loading (Skeleton).

## Anatomy & specs
| Part | Full | Compact |
|---|---|---|
| Container | centred column, padding `space-8` (block) / `space-6` (inline), gap `space-2` | padding `space-6` / `space-4` |
| Illustration | 200 × 160, `space-4` below | 140 × 112, `space-2` below |
| Title | `h3` in `text` | `label-l` in `text` |
| Description | `body` in `text-secondary` | same |
| Actions | Buttons, gap `space-3`, `space-4` above, centred, wrapping | same |

- Title and description are centred and capped at 320 wide.
- Illustrations are flat shapes on a 200 × 160 canvas in the sport colours, `volt-400`, `surface-inverse`, `border` and `court-line`, so they follow the theme.

## Variants
| `illustration` | Scene | For |
|---|---|---|
| `bookings` | calendar card with a check on a football pitch strip, a Volt ball | no matches or bookings |
| `notifications` | padel-blue bell with a basketball clapper, sleeping « z » | nothing new |
| `programs` | basketball-orange training cones, a Volt ball | no program or lessons |
| `results` (default) | football pitch under a magnifier with « ? » | no search or filter results |

`illustration={null}` drops the art for tight panels.

## States
Static, no motion. When the first item arrives, the content replaces the empty state in place.

## Content
- Title: what is empty, in a few words: « Aucun match à venir », « Tout est calme », « Pas encore de programme », « Aucune partie trouvée ».
- Description: one sentence in « tu » with the way forward: « Trouve une partie à ton niveau près de chez toi. », « Élargis la distance ou le niveau, ou crée ta propre partie. »
- Action: one verb that fixes it: « Explorer les parties », « Modifier les filtres », « Créer mon plan ». Without an action, say what will appear: « Tu verras ici les invitations, rappels et paiements. »

## Accessibility
- The illustration is `aria-hidden`; the title is a real `h3` heading in both sizes, so it appears in the heading outline.
- `text-secondary` description ≥ 5.1:1 on `surface` and `bg`.
- The action is a normal Button, reachable right after the text.

## Do / Don't
- Do pick the illustration by meaning, not by the sport on screen.
- Do offer one action; add `secondaryAction` only for a real alternative.
- Don't write « Oups » or « Rien ici ! » — say what is empty and what to do next.
- Don't stack an EmptyState under a list that has items, or show it while data is still loading.

## Props (web preview)
`illustration` · `title` · `description` · `action` · `secondaryAction` · `compact`. See `index.d.ts`.

## Flutter
`MuEmptyState(illustration: MuEmptyIllustration.bookings, title: 'Aucun match à venir', description:, action: MuButton(...), secondaryAction:, compact: false)` — a `Column(mainAxisSize: MainAxisSize.min)` in `Padding` (32 / 24, compact 24 / 16) with a `ConstrainedBox(maxWidth: 320)` around the centred texts and a `Wrap(spacing: 12, alignment: WrapAlignment.center)` for the actions. Paint the four illustrations with a `CustomPainter` that reads `MuTheme` colours so they follow the theme; title in `Semantics(header: true)`, art in `ExcludeSemantics`.
