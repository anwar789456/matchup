# Accessibility

WCAG 2.2 AA is part of the design, in both themes and in Arabic.

- **Contrast**: text 4.5:1 (3:1 at 24 px, or 19 px bold); control boundaries, focus rings and meaningful icons 3:1. The measured pairs are in Colour. Disabled labels are exempt and use `text-disabled`.
- **Focus**: every interactive element shows `focus-ring` on keyboard focus: a 2 px gap in the surface colour, then 2 px of `focus` (ink in Light, Volt in Night match), following the element's radius. Text fields show focus as a 2 px `focus` border instead. Never remove focus without a replacement.
- **Targets**: anything tappable has a 44 × 44 hit area (`touch-target`). Smaller visuals (S buttons, icon buttons, chips, segments, the chip « × ») grow an invisible hit area without overlapping their neighbours.
- **Labels**: every input has a visible label above it, never a placeholder in its place. Helper text and errors are tied to the field (`aria-describedby`); invalid fields set `aria-invalid`.
- **Errors**: say what happened and how to fix it, in text next to the field, with an icon and the error colour. Long forms add an error summary at the top that links to each field. Never clear what the person typed.
- **Names**: icon-only buttons have an accessible name; toggles keep one name and announce their state with `aria-pressed`; decorative icons and illustrations are hidden from assistive tech.
- **Status**: never colour alone. Badges carry an icon and a word; charts carry labels or a table view; the live state says « EN DIRECT ».
- **Live updates**: toasts, score changes and lineup updates are announced in polite live regions; payment and error messages that need action use `role="alert"`.
- **Overlays**: dialogs, sheets and drawers trap focus, close with Esc (except during payment) and return focus to their trigger. Only one modal is open at a time.
- **Motion**: honour reduced motion (see Motion); no flashing faster than three times a second.
- **Text size**: layouts reflow up to 200 % text size; numbers in cards wrap rather than clip.
- **Language**: set `lang="fr"`, `lang="ar"` with `dir="rtl"`, or `lang="en"` on the root so screen readers pronounce the content correctly.
