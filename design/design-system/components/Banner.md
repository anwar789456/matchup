# Banner

A persistent, full-width message in the flow of the page — icon, text and one action — for states that last until someone deals with them.

## When to use
- Account and billing states: « Vérifie ton email pour sécuriser ton compte », « Le paiement de ton abonnement a échoué », « Ton abonnement Premium expire dans 3 jours ».
- Screen-wide conditions: offline (« Tu es hors ligne · Données en cache du 18 oct. à 20h00 ») and test mode (« MODE TEST · carte 4242 4242 4242 4242 »).
- Use a **Toast** for passing feedback, a field message for form errors.

## Anatomy & specs
- **inset** (default): `radius-md`, inside the page margins. Padding `space-3` `space-4`; icon 20 (fill) in `<tone>-text`; title `label` `text`; detail `body` `text-secondary`; gap `space-3`.
- Under 600px of banner width: the action (Button S secondary) sits under the text; the close (IconButton S « Masquer ») stays top-end. From 600px: one row — icon · title + detail · action · close, centred, padding-inline `space-5`.
- **strip**: edge to edge under the app bar or top bar, radius 0, padding `space-2` `space-4` (`space-8` from 600px), a 1px bottom rule in the tone ink at 22 %; regular-weight icon; title and detail stack on mobile and share one line (« · ») on desktop.
- **ribbon**: the loud test-mode strip — `warning` fill with 45° hazard stripes of `ink-900` at 16 % (10px), a solid `warning` plate (`radius-full`) holding flask (fill, 16) + « MODE TEST » in `overline` + detail in `caption` with the card number in `num-xs`. `ink-900` text: 8:1, same in both themes.

| Tone | Ground | Icon / ink | Default icon |
|---|---|---|---|
| info | `info-soft` | `info-text` | info |
| success | `success-soft` | `success-text` | check-circle |
| warning | `warning-soft` | `warning-text` | warning |
| error | `error-soft` | `error-text` | warning-circle |
| neutral | `surface-muted` + 1px `border` | `text-secondary` | info |

## States
- **Dismissible**: a close button; it fades out over `duration-fast` (`ease-exit`) and the page closes the gap. Use it only when nothing is blocked (email, Premium reminder, success).
- **Non-dismissible**: payment failed, offline, test mode — they leave when the condition is resolved.
- The action runs its flow (« Renvoyer l’email » → sent; « Mettre à jour la carte » → card sheet); the banner updates or disappears when the state changes.

## Content
- Title = the situation, with « tu »: « Le paiement de ton abonnement a échoué ».
- Detail = the fact the person needs: « Ta carte Visa •••• 4821 a été refusée le 12 oct. », « Lien envoyé à yassine.b@email.tn ».
- Action = the fix as a verb: « Renvoyer l’email », « Mettre à jour la carte », « Renouveler ».

## Accessibility
- Error banners are `role="alert"`, others `role="status"`, the ribbon `role="note"`.
- Never colour alone: every tone has its icon and words; the ribbon says « MODE TEST ».
- `text-secondary` on every soft ground ≥ 4.7:1 (Light) and 6.5:1 (Night match).

## Do / Don't
- Do show at most one strip and one inset banner per screen; errors win over reminders.
- Do keep the test-mode ribbon above everything on checkout and dashboards, never scrolled away.
- Don't use a banner for marketing.
- Don't make blocking states dismissible.

## Props (web preview)
`tone` · `variant` · `icon` · `title` · `children` (detail) · `action` · `onAction` · `dismissible` · `onDismiss` · `dismissLabel`. See `index.d.ts`.

## Flutter
`MuBanner(tone: MuTone.error, variant: MuBannerVariant.inset, icon:, title:, detail:, action: MuAction('Mettre à jour la carte', onTap), onDismiss:)` — a `StatelessWidget` over `Material` + `LayoutBuilder` (row from 600). Strip: full-width `ColoredBox` with a bottom `BorderSide`. Ribbon: `CustomPaint` stripes behind a `StadiumBorder` plate. Dismiss with `AnimatedSize` + `FadeTransition`.
