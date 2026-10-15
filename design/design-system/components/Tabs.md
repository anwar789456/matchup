# Tabs

Switch between views of the same content — « À venir 2 · Passés · Annulés » — with an underline that slides, or pill tabs inside cards.

## When to use
- **Underline** at page level, under a title or app bar: lists filtered by state (bookings, matches), profile sections. 2–7 tabs; more scroll horizontally.
- **Pill** inside a card to swap its content: « Toutes 24 · À confirmer 4 · Payées 18 », « Aperçu · Joueurs · Discussion ».
- Not for picking a value (sort, period, map/list) — that is SegmentedControl. Not for app sections — that is TabBar. Not for steps — WizardStepper.

## Anatomy & specs
| Part | Underline | Pill |
|---|---|---|
| Height | `control-l` 48 | `control-s` 32 in a `space-1` padded track |
| Label | `label`, `text-secondary` → `text` when active | `label`, `text-secondary` → `on-accent` |
| Indicator | 2px `primary` (ink · Volt in Night match), content width, top radius 2 | `accent` thumb, `radius-full`, `elevation-1` |
| Spacing | gap `space-6`; the first label sits on the page margin | padding-inline `space-4` |
| Count | Counter `muted` → `neutral` when active, shows up to 999 | `surface` → `on-accent` pill with `accent` digits |
| Track | 1px `border` hairline under the row | `surface-muted` + inset `border`, `radius-full` |

## Variants
`underline` (page level, scrolls when it overflows) · `pill` (in cards) · `fullWidth` shares the width equally (phone columns with 2–3 tabs).

## States
- **Selection**: the indicator moves (translate + width) over `duration-base` `ease-move`.
- **Hover**: label to `text`. **Focus**: `focus-ring` around the label, `radius-sm`. **Disabled**: `text-disabled`, skipped by the arrows.
- **Overflow**: the row scrolls without a scrollbar; a 48px fade (`space-12`) masks each side that has more; the active tab is scrolled into view.

## Content
- Nouns, one or two words, sentence case. Add a count only when it helps decide (« À confirmer 4 »).
- Keep the order stable; never reorder tabs by their counts.

## Accessibility
- `role="tablist"` with an `aria-label`; tabs `role="tab"`, `aria-selected`, `aria-controls` → a `role="tabpanel"` labelled by the tab id (`idBase-value`).
- ← → move and select (mirrored in RTL), Home and End jump; Tab leaves the list (roving `tabIndex`).
- Targets are 48 high and their hit areas cover the gaps.

## Do / Don't
- Do use pill tabs for switches inside a card and underline tabs at page level — never both in one view.
- Do keep labels short enough that three tabs fit a 358 phone column without scrolling.
- Don’t use Volt text for the active underline tab in Light — the indicator is ink.

## Props (web preview)
`items` (`value`, `label`, `count`, `icon`, `disabled`, `panelId`) · `value` · `defaultValue` · `onChange` · `variant` · `fullWidth` · `label` · `idBase` · `states`. See `index.d.ts`.

## Flutter
`MuTabs(tabs: [MuTabItem('À venir', count: 2), …], controller:, variant: MuTabsVariant.underline)`. Underline: `TabBar(isScrollable: true, tabAlignment: TabAlignment.start, indicatorSize: TabBarIndicatorSize.label, indicator: UnderlineTabIndicator(borderSide: BorderSide(width: 2, color: primary)))` with a `ShaderMask` for the edge fades. Pill: `TabBar` with a `BoxDecoration(color: accent, borderRadius: full)` indicator inside a `surface-muted` `DecoratedBox`.
