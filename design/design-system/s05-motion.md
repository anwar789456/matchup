# Motion

Quick and physical: things appear with ease-out, leave with ease-in, and nothing makes a player wait for an animation.

## Tokens

| Token | Value | Use |
|---|---|---|
| `duration-fast` | 150 ms | Hover, press, chip selection, toggles |
| `duration-base` | 200 ms | Popovers, tabs, toasts, lineup updates |
| `duration-slow` | 250 ms | Sheets, drawers, modals, takeovers |
| `duration-counter` | 600 ms | Rolling score and KPI counters |
| `duration-success` | 1 200 ms | How long a button shows its success check |
| `duration-pulse` | 1 600 ms | One beat of the live dot |
| `duration-shimmer` | 1 400 ms | One sweep of a skeleton or the AI shimmer |
| `duration-toast` | 4 000 ms | Toast auto-dismiss (paused on hover and focus) |
| `ease-enter` | cubic-bezier(0, 0, 0.2, 1) | Anything appearing (ease-out) |
| `ease-exit` | cubic-bezier(0.4, 0, 1, 1) | Anything leaving (ease-in) |
| `ease-move` | cubic-bezier(0.2, 0, 0, 1) | Things that move or resize: sheet snaps, the tab indicator, a segmented thumb |
| `ease-pop` | cubic-bezier(0.34, 1.56, 0.64, 1) | A small overshoot: a chip selected, a player dropping into a lineup slot |
| `scale-press` | 0.98 | Press scale of buttons, cards and chips |

## Patterns

- **Press**: buttons, cards and chips scale to `scale-press` over `duration-fast`.
- **Overlays**: popovers fade and slide 4 px over `duration-base`; sheets slide up, drawers slide in from the trailing edge, dialogs fade and scale from 0.96, all over `duration-slow` with `ease-enter`; exits are shorter, with `ease-exit`.
- **Loading**: skeletons shaped like the content shimmer at `duration-shimmer`. Spinners appear only inside buttons and the payment overlay.
- **Live**: a joined player drops into the lineup with `ease-pop` and a toast appears; scores roll digit by digit over `duration-counter` and flash Volt once.
- **Success**: a button turns `success` with a check for `duration-success`, then returns. Payments end on an animated check.
- **Celebration**: subtle confetti only for the big moments: « Partie complète ! », a tournament won, a program completed. Never for a routine save.

## Reduced motion

Under `prefers-reduced-motion` (Flutter: `MediaQuery.disableAnimations`), durations drop to zero, the pulse and the shimmer stop, counters show their final value and confetti renders still. Never carry meaning in motion alone: a live match still says « EN DIRECT », a full game still says « Complet ».
