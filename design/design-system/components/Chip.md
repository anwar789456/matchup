# Chip

Compact pills that filter, choose and tag — filter, choice, sport, level and removable input chips — with a Volt fill when selected.

## When to use
- **filter** — multi-select filters above lists and maps: « Ce soir », « Mixte », « Éclairé »; with `count` for the « Filtres 3 » opener; with `trailingIcon="caret-down"` when it opens a menu (« Date »).
- **choice** — one value from a short set: « Matin · Après-midi · Soir ».
- **sport** — a sport tag on cards and rows; with `onClick` it becomes a sport filter.
- **level** — a player's or game's level: the value and its band.
- **input** — a value the player entered, removable: « La Marsa », « Niveau 3,0–4,5 ».
- Not for status (StatusBadge), counts on their own (Counter) or actions (Button).

## Anatomy & specs
| Size | Height | Padding (inline) | Label | Icon |
|---|---|---|---|---|
| M (default) | `control-s` 32 | `space-3` | `label` | 18 |
| S | 24 | `space-2` | `label-s` | 16 |

- `radius-full`, icon-to-label gap `space-1`. Interactive chips grow an invisible hit area by 6 px above and below (M → 44).
- **Count**: 18 high, min-width 18, `label-s`, `surface-inverse` / `text-inverse`; on a selected chip `on-accent` / `accent`.
- **Trailing icon**: 16.

## Variants
| Kind | Element | Rest | Selected |
|---|---|---|---|
| filter (default) | `button`, `aria-pressed` | `surface`, 1px `border-strong`, `text` | `accent` fill and border, `on-accent`, a leading check (pops in with `ease-pop`); a chip with its own icon turns it Fill instead |
| choice | `button`, `role="radio"`, `aria-checked` | as filter | as filter |
| sport | tag: `span`; with `onClick`: `button`, `aria-pressed` | `<sport>-soft` fill, `<sport>-text` label and sport icon, no outline; labels « Football », « Padel », « Basket » | `accent`, `on-accent`, sport icon kept |
| level | `span` | `surface-muted`, 1px `border`; value `num-s` · 1px `border-strong` divider · band in `label` | — |
| input | `span` + remove `button` | `surface-muted`, 1px `border`; remove: 24 circle, `x` 14 in `text-secondary`, 44 hit area, hover `border` fill | — |

## States
- **Hover** (interactive): border → `text`.
- **Pressed**: scale 0.96 with `ease-pop`.
- **Focus**: `focus-ring`, on the chip and on the remove button.
- **Selected**: Volt fill with a check.
- **Disabled**: `text-disabled`, `border` outline.

## Content
- One or two words, sentence case: « Ce soir », « Éclairé », « Après-midi ».
- Levels use a comma and one decimal on 1,0–7,0, with the band from the value: Débutant (< 2,5), Intermédiaire (2,5–3,9), Avancé (4,0–5,4), Expert (≥ 5,5) — « 3,5 · Intermédiaire » in running text; ranges « Niveau 3,0–4,5 ».
- Places as the player chose them: « La Marsa », « Lac 2 ». The remove button is named « Retirer La Marsa » (or `removeLabel`).

## Accessibility
- Wrap choice chips in an element with `role="radiogroup"` and an `aria-label` (« Créneau »).
- Selection shows as fill plus a check, never colour alone; sport chips always carry the sport icon (basketball orange is only 2.9:1 on white).
- `on-accent` on `accent` 13.2:1; `<sport>-text` on `<sport>-soft` ≥ 4.6:1.
- Interactive S chips grow their hit area by 10 px above and below (24 → 44); still prefer M for filters on touch screens.

## Do / Don't
- Do lead a filter row with « Filtres » and its count; active filters follow.
- Do keep sport colours for sport chips only.
- Don't fill a chip with Volt unless it is selected.
- Don't use choice chips for more than five options — use a Select.

## Props (web preview)
`kind` · `selected` · `sport` · `level` · `icon` · `trailingIcon` · `count` · `onRemove` · `removeLabel` · `size` · `disabled` · `state` · `onClick` · `children` (the label). See `index.d.ts`.

## Flutter
`MuChip(label:, kind: MuChipKind.filter, selected:, onSelected:, sport:, level:, icon:, count:, onRemove:, size: MuChipSize.m)` — Material 3 `FilterChip` / `ChoiceChip` / `InputChip` themed with `StadiumBorder`, `side: BorderSide(color: borderStrong)`, `selectedColor: accent`, `checkmarkColor: onAccent`, `labelStyle: MuType.label` and `materialTapTargetSize: MaterialTapTargetSize.padded` (M3 chips are 32 high, like M). Static sport and level chips are a `DecoratedBox(ShapeDecoration(shape: StadiumBorder()))` around a `Row`; the level value uses `MuType.numS`.
