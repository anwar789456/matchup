# PricingCard

A subscription plan — name, price in big numerals, one-line pitch, the main action and what is (and isn't) included.

## When to use
- **Default** side by side on the plans page and in the plan comparison modal (`modal-l`): Joueur Gratuit / Premium, Propriétaire Starter / Pro, Coach.
- **Compact** as rows in the mobile plan picker sheet.
- Put a SegmentedControl « Mensuel · Annuel (2 mois offerts) » above a group; every card follows its `period`.

## Anatomy & specs
| Part | Spec |
|---|---|
| Surface | `mu-card`, padding `space-6`, gap `space-5`; cards in a row share their height |
| Eyebrow | icon 16 + audience `overline` `text-secondary`; « Populaire » badge at the end |
| Name | `h3`; pitch `body` `text-secondary` |
| Price | amount `num-xl` + unit `body` `text-secondary` (« / mois », « / an », « pour toujours ») |
| Yearly line | savings badge (`success-soft`, gift icon) « 2 mois offerts » + « soit 15,833 DT/mois » `caption` |
| Action | Button L full width — primary on the recommended plan, secondary otherwise |
| Trial note | `caption` `text-secondary`, centred, wraps only between « · » segments |
| Features | hairline `border` above, gap `space-3`; check 18 `success-text` + `body`; not included: x `text-disabled` + `text-secondary` |
| Compact | name `label-l` + badges, pitch `caption`; amount `num-l` over unit `caption`, padding `space-4` |

## Variants
- **recommended** — Volt « Populaire » badge (`accent`/`on-accent`, star), a 2px `primary` border inside the edge (ink in Light, Volt in Night match), `elevation-2`, primary CTA. One per group.
- **current** — « Ton offre actuelle »: a disabled-looking block (`surface-muted`, `border` ring, `text-secondary`, check-circle in `success-text`) in place of the button; no trial note.
- **period** — month or year; free plans read « 0 DT pour toujours ».

## States
- The card itself is not interactive; the CTA carries hover, pressed, focus, loading and success (see Button).
- Loading: `skeleton` keeps eyebrow, name, pitch, price, button and four feature lines.

## Content
- CTAs are verbs: « Passer à Premium », « Commencer l’essai gratuit », « Choisir Starter ».
- Trial note: « 14 jours gratuits, puis 19 DT/mois · Résiliable à tout moment ».
- Yearly prices use the thousands space: « 1 490 DT / an »; per-month equivalent with 3 decimals: « soit 124,167 DT/mois ».
- Features start with the benefit, ≤ 40 characters; use a narrow no-break space before « % ».

## Accessibility
- Not-included features are announced « Non inclus : … »; the x icon is decorative.
- « Ton offre actuelle » is text, not a disabled button, so it stays readable (≥ 4.5:1).
- Prices are isolated LTR (`dir="ltr"`) so « 1 490 DT » keeps its order in RTL.
- The recommended border is backed by the « Populaire » label — never the border alone.

## Do / Don't
- Do align the same features across the cards of a group, in the same order.
- Do show the savings on the yearly price, not on the monthly one.
- Don't mark more than one plan « Populaire ».
- Don't put AI gradients or Volt text on pricing; Volt is the badge fill only.

## Props (web preview)
`audience` · `name` · `icon` · `price` · `yearlyPrice` · `period` · `savings` · `pitch` · `features` · `recommended` · `current` · `cta` · `onCta` · `trialNote` · `variant` · `skeleton`. See `index.d.ts`.

## Flutter
`MuPricingCard(plan:, period: MuBillingPeriod.year, recommended: true, current: false, onCta:)` — `MuCard` with a `Column`; recommended border via `RoundedRectangleBorder(side: BorderSide(width: 2, color: primary))`; amount `Text.rich` (`num-xl` + `body`); features `Column` of `Row(Icon, Expanded(Text))`. In a `Row` of plans wrap each in `Expanded` inside `IntrinsicHeight`.
