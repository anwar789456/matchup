# Fab

The floating AI assistant button — a 56 px circle in the AI gradient with a filled sparkle — the single entry point to « Assistant MatchUp » on mobile.

## When to use
- On the mobile root screens, floating above the TabBar at the trailing edge.
- **Extended** (« Demande à MatchUp ») to introduce the assistant where there is room, such as onboarding or an empty home screen; the circle everywhere else.
- Not for « Créer une partie » or any non-AI action — use a Button or a primary IconButton. From `bp-expanded` (840) the assistant is a side panel, not a Fab.

## Anatomy & specs
| Part | Spec |
|---|---|
| Circle | `control-xl` 56 × 56, `radius-full`, `ai-gradient` fill (violet → blue at 135°), `elevation-2`, `z-sticky` |
| Extended | same height, label `label` in `white`, fill `ai-gradient-strong` so the label keeps 4.5:1 |
| Icon | `sparkle`, Fill weight, 24, `white` |
| Extended | 56 high, padding-inline `space-5` (icon side) and `space-6`, icon-to-label gap `space-2`, label `label` in `white` |
| Placement | `space-4` above the TabBar, `space-4` from the trailing edge (right in LTR, left in RTL) |

## Variants
Circle (default, icon only) · `extended` (icon + visible label).

## States
- **Hover** (web): `elevation-3`.
- **Pressed**: `scale-press` 0.98 over `duration-fast`, `ease-enter`.
- **Focus**: `focus-ring` on top of `elevation-2`.
- There is no disabled or loading style: hide the Fab when the assistant is unavailable.

## Content
- Accessible name « Assistant MatchUp » (the default `label`); extended text « Demande à MatchUp » — an invitation in « tu », two or three words.
- The assistant it opens follows the AI rules: every answer carries the « IA » label and says why (« Recommandé car… »), can be edited or dismissed, and never books, pays or publishes without the player's confirmation.

## Accessibility
- The circle is a `button` named by `aria-label`; extended, the visible label is the name.
- The circle uses `ai-gradient`: white holds 4.4:1 to 3.7:1 across it, enough for the icon (non-text, ≥ 3:1). The extended pill carries a text label, so it fills with `ai-gradient-strong` (same hues, one step deeper): white holds 5.5:1 to 5.2:1.
- Pad the bottom of scrolling content by 56 + `space-4` so the last card clears the Fab.
- Under reduced motion the press scale is skipped; nothing else moves.

## Do / Don't
- Do keep exactly one Fab per screen, at the same spot on every root screen.
- Do hide it inside flows (booking, payment, create a game) and takeovers, like the TabBar.
- Don't use the AI gradient or the sparkle on any other button.
- Don't make it a sixth tab, and don't badge it.

## Props (web preview)
`label` · `extended` · `icon` · `onClick` · `state`. See `index.d.ts`.

## Flutter
`MuFab(onPressed:, label: 'Assistant MatchUp', extended: false)` — set as `Scaffold.floatingActionButton` with `FloatingActionButtonLocation.endFloat`, 16 above the TabBar. `FloatingActionButton` cannot paint a gradient, so build it from `Material(shape: StadiumBorder(), elevation:)` + `Ink(decoration: ShapeDecoration(shape: StadiumBorder(), gradient: MuGradients.ai))` (the extended pill: `MuGradients.aiStrong`) + `InkWell(customBorder: StadiumBorder())`, with `PhosphorIcons.sparkle(PhosphorIconsStyle.fill)` in white, `Semantics(button: true, label:)` and `AnimatedScale(0.98)` on press. Don't build it from `bp-expanded` up.
