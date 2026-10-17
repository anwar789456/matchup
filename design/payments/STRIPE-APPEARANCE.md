# Stripe appearance values (from tokens.json)

The checkout screens (PAY-01…PAY-10, WAL-03, SUB-02) are **our** screens. Only the card fields inside the box captioned « Zone sécurisée Stripe » come from Stripe.
Style that box with the values below so it looks like the rest of MatchUp. Never use Stripe's hosted checkout page.

## Web (Stripe Elements Appearance API)

```js
const matchupAppearance = {
  theme: 'stripe',
  variables: {
    colorPrimary: '#0B1B33',      // primary (ink-900) — focus, selected
    colorBackground: '#FFFFFF',   // surface
    colorText: '#0B1B33',         // text (ink-900)
    colorTextSecondary: '#5B6B82',// text-secondary (ink-500)
    colorTextPlaceholder: '#5B6B82',
    colorDanger: '#CA2C37',       // error-text (AA on white)
    fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
    fontSizeBase: '16px',         // body-l: avoids iOS zoom on focus
    borderRadius: '8px',          // radius-sm (inputs)
    spacingUnit: '4px',           // 4px base grid
    gridRowSpacing: '16px',
    gridColumnSpacing: '12px',
  },
  rules: {
    '.Input': { border: '1px solid #A9B4C4', boxShadow: 'none', padding: '12px 14px' },        // border-strong
    '.Input:focus': { border: '1px solid #0B1B33', boxShadow: '0 0 0 2px #FFFFFF, 0 0 0 4px #0B1B33' }, // focus-ring
    '.Input--invalid': { border: '1px solid #CA2C37', boxShadow: 'none' },
    '.Label': { fontWeight: '600', fontSize: '14px', marginBottom: '6px' },
    '.Error': { fontSize: '12px' },
  },
};

// Dark theme « Night match »
const matchupAppearanceDark = {
  theme: 'night',
  variables: {
    colorPrimary: '#C6F135',      // volt-400 (primary in dark)
    colorBackground: '#0F1B2E',   // surface (night-800)
    colorText: '#F5F7FA',         // text (ink-50)
    colorTextSecondary: '#A9B4C4',
    colorTextPlaceholder: '#A9B4C4',
    colorDanger: '#FF817E',       // error-text dark
    fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
    fontSizeBase: '16px',
    borderRadius: '8px',
    spacingUnit: '4px',
  },
  rules: {
    '.Input': { border: '1px solid #5B6B82', backgroundColor: '#16243A', boxShadow: 'none' },
    '.Input:focus': { border: '1px solid #C6F135', boxShadow: '0 0 0 2px #0F1B2E, 0 0 0 4px #C6F135' },
  },
};
```

## Flutter (flutter_stripe)

The app is Flutter, so use `flutter_stripe` with the **embedded card field** (`CardFormField`) inside our checkout layout, not the Payment Sheet, so the screen matches PAY-01 / PAY-03.

| Token | Value light | Value dark | `CardFormStyle` field |
|---|---|---|---|
| surface | #FFFFFF | #0F1B2E | `backgroundColor` |
| text | #0B1B33 | #F5F7FA | `textColor` |
| text-secondary | #5B6B82 | #A9B4C4 | `placeholderColor` |
| border-strong | #A9B4C4 | #5B6B82 | `borderColor` |
| radius-sm | 8 | 8 | `borderRadius` |
| border width | 1 | 1 | `borderWidth` |
| primary | #0B1B33 | #C6F135 | `cursorColor` |
| error-text | #CA2C37 | #FF817E | `textErrorColor` |
| font | Plus Jakarta Sans 16 | same | `fontSize` (font family follows the app) |

Read these from `context.mu` at runtime (never hardcode in widgets), e.g. `CardFormStyle(backgroundColor: context.mu.surface, textColor: context.mu.text, …)`.
Apple Pay / Google Pay buttons: `flutter_stripe` platform pay buttons, shown in the « Paiement express » row only when the device supports them.

## Before real payments go live — check this first
Design and test mode work today. For real money, check with Stripe (and your accountant) **before** building the backend:
- whether your Stripe account (country of the company that holds it) can charge in **TND**, which is a 3-decimal currency (`15 DT` = `15000` in minor units if supported);
- whether Tunisian-issued cards can pay online with that account;
- how payouts to Tunisian venue owners (RIB) would work.
If any answer is no, a local gateway (for example Konnect, Flouci, Paymee or ClicToPay) can sit in the same « Zone sécurisée » box: the screens stay the same, only the provider inside the box changes.
