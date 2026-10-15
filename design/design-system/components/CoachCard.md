# CoachCard

A coach at a glance — verified avatar, specialties, a scoreboard strip of rating, students and session price, and « Voir les programmes ».

## When to use
- **Default** in coach search results, on program pages (« Ton coach ») and in the coach's own profile preview.
- **Compact** in lists and pickers (choose a coach for a private session).

## Anatomy & specs
| Part | Default | Compact |
|---|---|---|
| Surface | `mu-card`, padding `space-4`, gap `space-4` | padding `space-3` / `space-4`, gap `space-3` |
| Avatar | Avatar L 56 + verified seal 22 (Volt `accent` disc, `on-accent` seal-check, 2px `surface` ring) at the bottom end | Avatar M 40 + seal 16 |
| Name | « Coach Karim S. » `label-l`, one line | `label` |
| Sub line | map-pin + « Lac 2 » · translate + « FR · AR », `caption` `text-secondary` | ★ rating · « 120 élèves »; sport icon + « Padel · Service, Défense » |
| Tags | Chip sport (S) + static tags (S, `surface-muted`, `border` hairline), gap `space-2` | — |
| Stats strip | 3 cells on `surface-muted`, `radius-sm`, padding `space-3`, `border` dividers; value `num-m`, label `caption` `text-secondary` | price column: « dès » `caption`, `num-m`, « / séance » `caption` |
| CTA | secondary M, full width, « Voir les programmes » + arrow | — (the row is the link) |

- Stats: « ★ 4,9 » over « 86 avis » · « 120 » over « élèves » · « dès 40 DT » over « par séance ».

## Variants
- **verified** — seal on the avatar.
- **pending** (the coach's own view) — warning-soft hourglass badge on the avatar, StatusBadge « Vérification en cours » under the name, stats « — / Aucun avis » and « 0 élève » in `text-secondary`, an info line explaining the 48 h check, CTA « Compléter mon profil » with pencil.
- **none** — no seal (players never see unverified coaches in search).

## States
- Hover → `elevation-2`; pressed → `scale-press`; focus → `focus-ring` (the name is a stretched link; the CTA sits above it).
- Loading: `skeleton` keeps avatar, name, three pills, the stats well and the button shape.

## Content
- Always « Coach » + first name + initial: « Coach Amel T. ».
- 2–4 specialties, nouns in sentence case: « Service », « Défense », « Préparation physique ».
- Price is the lowest per-session price: « dès 40 DT / séance ». Languages as codes: « FR · AR ».

## Accessibility
- The seal is `role="img"` « Coach vérifié »; the pending badge reads « Vérification en cours ».
- Stats are a `dl` (label + value), so screen readers read « 86 avis, 4,9 ».
- Languages announce « Langues : FR, AR ».

## Do / Don't
- Do keep the stats strip to three numbers, in this order.
- Do show the sport as the first tag, with its icon.
- Don't use Volt for the seal's check on a light ground — it is always ink on a Volt disc.
- Don't hide « Vérification en cours » from the coach; explain what happens next.

## Props (web preview)
`name` · `sport` · `city` · `specialties` · `rating` · `reviews` · `students` · `priceFrom` · `languages` · `verification` · `cta` · `onCta` · `variant` · `skeleton` · `href` / `onClick`. See `index.d.ts`.

## Flutter
`MuCoachCard(coach:, verification: MuVerification.pending, variant: MuCardVariant.regular, onTap:, onCta:)` — `MuCard` with a `Column`; avatar = `Stack(MuAvatar.l, Positioned(MuSeal))`; tags = `Wrap(spacing: 8)` of `MuChip`; stats = `IntrinsicHeight(Row)` of three `Expanded` cells separated by `VerticalDivider`, on `surface-muted`.
