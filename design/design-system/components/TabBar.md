# TabBar

The mobile bottom navigation — Accueil, Explorer, Mes matchs, Entraînement, Communauté — with the Volt pill behind the active icon and the AI Fab floating above.

## When to use
- On the five root screens of the player app. Hide it inside flows (booking, payment, create a game) and full-screen takeovers.
- Not for switching views inside a page — use Tabs or SegmentedControl.

## Anatomy & specs
| Part | Spec |
|---|---|
| Bar | `tab-bar` 64 + bottom safe area, `surface`, `elevation-2-up`, `z-sticky`, padding-inline `space-1` |
| Tab | the whole cell is the target; pill over label, gap `space-1`. Widths start from content (pill or label, whichever is wider) and share the rest equally, so French « Entraînement » and « Communauté » never touch; Arabic tabs come out equal |
| Pill | 56 × 32, `radius-full`; `accent` when active |
| Icon | `icon-m` 24 — Fill weight in `on-accent` when active, Regular in `text-secondary` otherwise |
| Label | `label-s` — `text` when active, `text-secondary` otherwise; never truncated |
| Badge | Counter 18 high (`destructive`, white digits) with a 2px `surface` ring at the icon’s top-end; dot 10 for presence |
| Fab | core Fab 56, `space-4` above the bar, `space-4` from the trailing edge |

## States
- **Active**: the pill grows from 40% width over `duration-base` `ease-move`; the icon switches to Fill.
- **Hover** (web): a `text` wash at `opacity-hover` inside the pill. **Pressed**: `opacity-pressed` wash, icon scales to 0.9 (`ease-pop`).
- **Focus**: `focus-ring` around the pill.
- A badge on the active tab rides on the pill; the ring keeps it separate.

## Content
- One word or two, exactly: « Accueil · Explorer · Mes matchs · Entraînement · Communauté ». Arabic: « الرئيسية · استكشاف · مبارياتي · التدريب · المجتمع ».
- Badges mean “something needs you”: invitations, unpaid shares, unread messages — never a count of content.

## Accessibility
- `nav` « Navigation principale » containing `role="tablist"`; tabs are `role="tab"` with `aria-selected` and a roving `tabIndex`; ← → (mirrored in RTL), Home, End.
- The badge is `aria-hidden`; its meaning is appended to the tab name: « Mes matchs, 2 invitations ».
- Targets are the full cell (≥ 56 × 64). `on-accent` on `accent` 13.2:1; `text-secondary` labels ≥ 5.1:1.

## Do / Don't
- Do keep exactly five tabs; the AI Fab is a separate entry point, never a sixth tab.
- Do mirror the order in RTL — Accueil sits on the right.
- Don’t put Volt on an inactive tab or tint icons with sport colours.
- Don’t hide labels on inactive tabs.

## Props (web preview)
`items` (each may carry an `href`: the bar then renders route links with `aria-current="page"`) · `value` · `defaultValue` · `onChange` · `label` · `safeArea` · `fab` · `states`. See `index.d.ts`.

## Flutter
`MuTabBar(items: [MuTabItem(icon: PhosphorIcons.house, label: 'Accueil', badge: 2)], index:, onChanged:)`. Build on `NavigationBar` with `indicatorColor: accent`, `indicatorShape: StadiumBorder()`, height 64, labels `label-s`; or a `Row` whose `Expanded` flex weights come from `TextPainter` widths so leftover space is split equally. Wrap in `SafeArea(top: false)`. The Fab is the Scaffold’s `floatingActionButton` (`endFloat`), 16 above the bar.
