# Spinner

An indeterminate spinning arc used only inside a loading Button, short inline checks and the blocking payment overlay — content loads with Skeleton.

## When to use
- A Button's `loading` state: the spinner replaces the label at the button's icon size.
- LoadingOverlay while a payment is processed (« Paiement en cours »), at 32.
- Short inline checks next to text: OtpInput's Spinner 16 + « Vérification du code… ».
- Never for lists, cards, pages or images — use Skeleton.

## Anatomy & specs
| Size | Stroke | Use |
|---|---|---|
| 16 | 1.7 | inline with text, S buttons |
| 20 (default) | 2.1 | M and L buttons |
| 24 | 2.5 | XL buttons |
| 32 | 3.3 | payment overlay |

- A full track ring in `currentColor` at 25 % opacity under a quarter arc in `currentColor` with round caps; the stroke is 2.5 on a 24 grid, so it scales with the size.
- It turns once every 0.8 s, linear.
- Colour is inherited: `on-primary` inside a primary button, `text` elsewhere.

## States
- **Spinning** while the operation runs. **Reduced motion**: the rotation stops and the static arc stays; the text beside it carries the meaning.
- Replace it with the outcome: the Button's `success` check, the overlay's success check, a Toast, or an error message.

## Content
- Standing alone, pair it with a present-tense line: « Paiement en cours », « Vérification du code… ».
- Inside a Button nothing is shown; « Chargement » is announced.

## Accessibility
- With `label` it is `role="status"` named by the label; without one it is `aria-hidden` (a loading Button sets `aria-busy` and names its spinner « Chargement »).
- Through `currentColor` the arc keeps its text's contrast: `on-primary` on `primary` 17.2:1 (Light), 13.2:1 (Night match).
- Never rely on motion alone: say what is happening in text.

## Do / Don't
- Do keep the container stable — a loading Button keeps its width.
- Do block the screen only for payment; elsewhere the page stays usable.
- Don't use a Spinner in place of a Skeleton.
- Don't show two spinners on one screen.

## Props (web preview)
`size` · `label`. See `index.d.ts`.

## Flutter
`MuSpinner(size: 20, semanticLabel:)` — a `RotationTransition` (`AnimationController` 800 ms, linear, `repeat()`) around a `CustomPaint` that draws the 25 % track and a 90° arc (`StrokeCap.round`, stroke = size × 2.5 / 24) in `IconTheme.of(context).color`; don't start the rotation when `MediaQuery.disableAnimations`. Not `CircularProgressIndicator`, whose arc length breathes. Add `Semantics(liveRegion: true, label:)` only when labelled.
