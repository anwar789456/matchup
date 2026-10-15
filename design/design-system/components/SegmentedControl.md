# SegmentedControl

Two to four mutually exclusive views or values in one track — « Parties · Terrains · Tournois », « Mensuel · Annuel », « Carte · Liste » — with a Volt thumb that slides to the selected segment.

## When to use
- Switching the view of the same content: Explorer « Parties · Terrains · Tournois », « Carte · Liste ».
- Picking a value that changes the content at once: billing « Mensuel · Annuel », dashboard range « Jour · Semaine · Mois ».
- Not for moving between pages (Tabs), filters that combine (filter Chips), or more than four options (Select or choice Chips).

## Anatomy & specs
| Size | Track height | Segment height | Segment padding (inline) | Icon |
|---|---|---|---|---|
| M (default) | `control-m` 40 | 32 | `space-4` | 20 |
| S | `control-s` 32 | 24 | `space-3` | 16 |

- Track: `surface-muted`, `radius-md`, padding `space-1`, 1px inset `border` ring.
- Thumb: `accent`, `radius-sm`, `elevation-1`; slides and resizes over `duration-base` with `ease-move`.
- Segment: `label` in `text-secondary`, icon-to-label gap `space-2`; selected → `on-accent` with the icon in Fill weight.
- Badge: `label-s`, min-width 18, padding-inline 5, `radius-full`, `surface` with a `border` ring; on the selected segment `on-accent` fill with `accent` text (« −20 % »).
- `fullWidth` stretches the track and shares it equally; otherwise segments hug their labels. Uncontrolled, it starts on the first option.

## States
- **Hover**: label → `text`.
- **Selected**: thumb under the segment, `on-accent` label, Fill icon.
- **Focus**: `focus-ring` on the focused segment.
- There is no disabled segment: leave out options that don't apply.

## Content
- Nouns, one word each, sentence case: « Parties », « Terrains », « Tournois »; « Jour · Semaine · Mois ».
- A badge carries one short fact about its option: « −20 % » on « Annuel ».
- Icon segments keep their word (« Carte », « Liste »); an icon-only segment needs `ariaLabel`.

## Accessibility
- `role="radiogroup"` named by `label` (« Explorer », « Période »); segments are `role="radio"` with `aria-checked` and a roving `tabIndex`.
- ← / → move and select, wrapping at the ends; in RTL the keys follow the reading direction.
- `on-accent` on `accent` 13.2:1; `text-secondary` on `surface-muted` ≥ 5.1:1.
- Segments are 32 (M) and 24 (S) high; each grows an invisible hit area to the 44 `touch-target` (it never overlaps a neighbour, only extends up and down). Use M on touch screens, preferably `fullWidth`.

## Do / Don't
- Do apply the choice immediately; never add « Appliquer ».
- Do use `fullWidth` on mobile so each segment is a wide target.
- Don't mix icon-only and labelled segments in one control.
- Don't use it for an action (« Trier », « Exporter ») — it shows a state.

## Props (web preview)
`options` (`value` · `label` · `icon` · `badge` · `ariaLabel`) · `value` · `onChange` · `size` · `fullWidth` · `label`. See `index.d.ts`.

## Flutter
`MuSegmentedControl<T>(segments: [MuSegment(value: 'parties', label: 'Parties', icon:, badge:)], value:, onChanged:, size: MuSegmentedSize.m, expand: false, semanticLabel: 'Explorer')` — a custom widget, not Material `SegmentedButton` (outlined, with check marks): a `Stack` with an `AnimatedPositionedDirectional` thumb (200 ms, `ease-move` curve; offsets measured from each segment after layout, or an `AnimatedAlign` + `FractionallySizedBox(widthFactor: 1 / n)` when `expand`) under a `Row` of `InkWell` segments in `Semantics(inMutuallyExclusiveGroup: true, selected:)`, each with a 44 px hit area.
