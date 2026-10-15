# TransactionRow

One line of the wallet history — category circle, what it was for, when and how it was paid, the signed amount and its status.

## When to use
- **Default** in Portefeuille › Historique, grouped under date headers (« Aujourd’hui », « Cette semaine », then « Octobre 2026 »).
- **Compact** on desktop dashboards, receipts and summaries where only label and amount matter.
- Rows sit inside a `mu-card`; the first and last rows inherit its corner radius.

## Anatomy & specs
| Part | Default | Compact |
|---|---|---|
| Row | min height 72, padding `space-3` `space-4`, gap `space-3`, `surface` | min height 52, padding-block `space-2` |
| Circle | 40px, icon 20 | 32px, icon 16 |
| Label | « Réservation · Arena Five » `label`, one line | `body`, one line |
| Meta | « sam. 18 oct. · 20h00 · Carte •••• 4242 » `caption` `text-secondary` | — |
| Amount | `num-s` tabular, end-aligned | same |
| Status | StatusBadge S under the amount | icon-only StatusBadge after the amount |
| Chevron | caret-right 16 `text-secondary` (mirrors in RTL) | — |
| Divider | 1px `border`, inset to the text column (start `space-4` + 40 + `space-3`) | inset start `space-4` + 32 + `space-3` |

Date headers: `overline` `text-secondary`, `space-2` above the card, `space-5` between groups.

## Variants
| Category | Circle | Icon |
|---|---|---|
| booking | `<sport>-soft` + `<sport>-text` sport icon (neutral calendar-check without a sport) | sport-football / padel / basketball |
| topup | `surface-muted` + `border` ring, `text` | plus |
| refund | neutral | arrow-u-up-left |
| payout | neutral | bank |
| subscription | neutral | crown |
| penalty | neutral | calendar-x |

## States
- Amounts: debit « −15 DT » in `text`, credit « +45 DT » in `success-text` — the sign always shows, colour never alone. **failed**: struck through in `text-secondary`, announced « Non débité ».
- Status badges: « Remboursé » (info), « En attente » (warning), « Échec » (error).
- Hover → `text` wash at `opacity-hover`; pressed → `opacity-pressed`; focus → inset 2px `focus` ring with a 2px `surface` gap (rows are clipped by their card), the row's divider hides.
- Loading: `skeleton` keeps circle, two lines and amount; dividers stay.

## Content
- Label = what + where: « Réservation · Arena Five », « Ta part · Hoop Zone », « Pénalité · annulation tardive ».
- Meta = game date and time or the transaction time, then the method: « Carte •••• 4242 », « Portefeuille », « Attijari bank •••• 0187 ».
- Amounts per the money format: « −13,333 DT », « +50 DT », « −1 250 DT ».

## Accessibility
- The row is one button or link (opens the receipt); its name reads label, meta, amount and status in order.
- The minus is a real minus sign (U+2212) so screen readers say « moins »; the amount is isolated LTR (`dir="ltr"`) so « −15 DT » never mirrors in RTL.
- Never rely on green for credits: the « + » is part of the text.

## Do / Don't
- Do group by date with headers; newest first.
- Do keep the category circle neutral unless it is a booking with a sport.
- Don't colour debits red — a debit is normal; only « Échec » is an error.
- Don't truncate the amount; truncate the label and meta instead.

## Props (web preview)
`category` · `sport` · `label` · `meta` · `amount` · `status` · `variant` · `skeleton` · `href` / `onClick` · `chevron`. See `index.d.ts`.

## Flutter
`MuTransactionRow(tx:, variant: MuRowVariant.regular, onTap:)` — `InkWell` + `Row(MuIconCircle, Expanded(Column(label, meta)), Column(amount, MuStatusBadge.s), Icon(caret))`; list = `MuCard(child: Column(children: rows with MuInsetDivider(indent: 68)))`.
