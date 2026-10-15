# ChoiceCard

A large tappable answer card for onboarding questions — the sports picker and the AI level questionnaire — selected with a 2px `primary` border and a Volt check badge.

## When to use
- **Intentional addition** to brief §4.2: onboarding asks to « Choose sports (large sport cards, multi-select) » and the AI level questionnaire asks for « large tappable answers ». Checkbox and Radio rows are too small and too quiet for full-screen questions, and Chips are for compact filter bars — ChoiceCard is the big-target member of the same family, with the same semantics and the same Volt selection.
- Single answer (`type="radio"`) for questionnaire steps; multi-select (`type="checkbox"`) for sports, preferred times and the sports row of the « Filtres » sheet.
- 2–6 options that deserve a title and one line of description. Longer lists → Radio or Checkbox rows.

## Anatomy & specs
| Part | Row (default) | Tile |
|---|---|---|
| Card | `mu-card` (`surface`, `radius-md`, `elevation-1`) + 1px inset `border`; min-height 64; padding `space-3` `space-4` | padding `space-4`; media on top |
| Media | 40×40, `radius-sm`: `surface-muted` + `text` icon 24, or `<sport>-soft` + `<sport>-text` sport icon | 48×48, `radius-md`, icon 28 |
| Title | `label-l`, `text` | same |
| Description | `body`, `text-secondary` | same |
| Badge | 24px at the end: circle (radio) or `radius-xs` square (checkbox), 1.5px `border-control` | top-end corner, `space-3` inset |

- Cards in a group are `space-3` apart; tiles sit in a 2–3 column grid.
- **Selected**: inset 2px `primary` ring (ink in Light, Volt in Night match) + the badge filled with `accent` (Volt) and an `on-accent` check. Never Volt text.

## Variants
Row (answers, optional icon) · Tile (sport grid) · single (radio) · multi (checkbox) · media: sport tile, Phosphor icon, or none.

## States
- **Hover**: 1px `border-strong` ring + `elevation-2`. **Pressed**: `scale-press` 0.98.
- **Focus**: `focus-ring` around the card (keyboard only), kept together with the selected ring.
- **Selected**: the badge pops in (`ease-pop`, `duration-fast`) and the check draws in.
- **Error**: 1.5px `error` ring and an `error` badge outline; the group shows the message.
- **Disabled**: `surface-muted` card, `text-disabled` text, media at `opacity-disabled`.

## Content
- Titles are answers, not labels: « 6 mois à 2 ans », « Le soir ». Descriptions make them concrete: « Je joue régulièrement entre amis. », « 18h – minuit, terrains éclairés ».
- Answers never overlap: « Moins de 6 mois · 6 mois à 2 ans · 2 à 5 ans · Plus de 5 ans ».
- On full-screen questions the question is the screen title (`h2`); pass it to the group as `aria-label`.

## Accessibility
- Each card holds a real radio or checkbox input and is its label: Space and arrow keys behave natively, the whole card (≥ 64px) is the target.
- The group is a `radiogroup` (single) or a `group` (multi), named by the question.
- Selection shows as ring + badge + check, never colour alone.

## Do / Don't
- Do keep the CTA (« Continuer ») in the sticky bottom bar, disabled until a required answer exists.
- Do use sport colours only on the sport media tile.
- Don't put buttons or links inside a card — the whole card is one control.
- Don't mix rows and tiles in one question.

## Props (web preview)
`type` · `value` · `title` · `description` · `icon` · `sport` · `layout` · `checked` / `defaultChecked` · `onChange` · `disabled` · `error` — `ChoiceCard.Group`: `type` · `label` · `description` · `value` · `onChange` · `columns` · `error`. See `index.d.ts`.

## Flutter
`MuChoiceCard(title:, description:, leading: MuSportTile(Sport.padel), selected:, multi: true, onTap:)` — an `InkWell` on a `Material` with a `ShapeDecoration` (radius 12, 1px `border`, 2px `primary` when selected), `AnimatedScale(0.98)` on press and an `AnimatedSwitcher` badge. `MuChoiceGroup(single: true)` wraps the cards in `Semantics(inMutuallyExclusiveGroup: true)` and a `Column` or `GridView`.
