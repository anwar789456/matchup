# Overlay system

Everything that appears above the page: feedback, decisions, panels and full-screen moments. Each type has one job, one place in the stack and one way in and out.

## Layer order

From lowest to highest. A layer always covers the ones below it.

| Layer | Token | Holds |
|---|---|---|
| Content | `z-content` 0 | The page |
| Sticky bars | `z-sticky` 100 | Top app bar, sticky bottom action bar, tab bar, the assistant FAB |
| Popovers | `z-popover` 200 | Popovers, dropdown and « … » menus, tooltips, the desktop notification panel |
| Sheets and drawers | `z-sheet` 300 | Bottom sheets (mobile), side drawers (desktop) |
| Modals | `z-modal` 400 | Dialogs |
| Toasts | `z-toast` 500 | Toasts and snackbars, so feedback is never hidden by a dialog |
| Takeovers | `z-takeover` 600 | Full-screen takeovers and the blocking payment overlay |

Banners are not overlays: they sit in the page flow, under the app bar.

## Rules

- **One modal at a time.** Close or replace a dialog before opening another; a dialog may open over a sheet, never over another dialog.
- **Scrim**: `scrim`, ink-900 at 40 % in Light (64 % near-black in Night match) behind dialogs, modal sheets, modal drawers and the payment overlay. Popovers, menus and toasts have no scrim.
- **Closing**: the X button, a tap on the scrim, or Esc, except during payment (3-D Secure and the payment overlay cannot be dismissed).
- **Focus**: dialogs, modal sheets and drawers trap focus inside, start on the first meaningful control (never on a destructive one) and return focus to the trigger on close. Popovers and menus close on Esc and return focus too.
- **Actions**: in dialogs and drawers, the primary action is on the right on desktop (secondary first, primary last) and full width at the bottom on mobile, in the thumb zone. Destructive actions say their consequence.
- **Motion**: in with `ease-enter`, out with `ease-exit`, faster out than in (see Motion).

## Types

| Type | Use it for | Size | Animation | Layer |
|---|---|---|---|---|
| **Toast** | Non-blocking feedback: « Réservation confirmée ». At most one action, optional undo. Auto-dismiss after `duration-toast` (4 s), paused on hover or focus. | Mobile: full width minus `space-4` margins, above the tab bar. Desktop: `toast` 360, top-right under the top bar. Max 3 stacked. | Fade + 8 px slide, `duration-base` | `z-toast` |
| **Snackbar** | One message, one action: « Partie quittée · Annuler ». | Mobile full width; desktop bottom centre, 360–560 | Fade + 8 px slide, `duration-base` | `z-toast` |
| **Banner** | Persistent states until resolved: email not verified, payment failed, offline, test mode, subscription expiring. | Inset (in the margins, `radius-md`) or strip (edge to edge) | Fades out on dismiss, `duration-fast` | In the page |
| **Dialog** | Confirmations and destructive actions that state the consequence: « Annuler la réservation ? 45 DT seront remboursés sur ton solde MatchUp. » | `modal-s` 400 · `modal-m` 560 · `modal-l` 720; mobile centred or bottom card | Scrim fades, panel scales 0.96 → 1, `duration-slow` | `z-modal` |
| **Bottom sheet** | Mobile filters, slot details, split payment, quick rating, share. Drag handle, three heights. | `sheet-peek` 30 % · `sheet-half` 55 % · `sheet-full` 92 %, or sized to content | Slides up, `duration-slow`; snaps with `ease-move` | `z-sheet` |
| **Side drawer** | Desktop details without leaving the table: a booking, a user, flagged content. | `drawer` 480, full height, trailing edge | Slides in, `duration-slow` | `z-sheet` |
| **Popover** | Small explanations and choices next to their trigger: « Pourquoi ce niveau ? », date presets, the notification panel. | 240–360, or `notification-panel` 400 | Fade + 4 px slide, `duration-base` | `z-popover` |
| **Menu** | Dropdowns and « … » context menus; an action sheet on mobile. | 224–320 | Fade + 4 px slide, `duration-base` | `z-popover` |
| **Tooltip** | A short label or explanation on hover (after 400 ms) and on focus. | Max 240 (rich: 280) | Fade, `duration-fast` | `z-popover` |
| **Takeover** | Full-screen moments: « Partie complète ! », a freed waitlist spot with a 15-minute claim countdown, the 3-D Secure frame around the bank's window, the mobile AI assistant, the photo and video viewer, the check-in QR code. | Full screen inside the safe areas | Fade + 16 px rise, `duration-slow` | `z-takeover` |
| **Payment overlay** (LoadingOverlay) | Blocking, only while a payment is processed: « Paiement en cours… · 15 DT · Ne ferme pas cette page ». | Centred card over the scrim | Card scales 0.96 → 1, `duration-slow` | `z-takeover` |

Anatomy, states and examples for each type are on its component card: Toast, Snackbar, Banner, Dialog, BottomSheet, Drawer, Popover, Menu, Tooltip, Takeover, LoadingOverlay.
