# SocialButton

« Continuer avec Google » and « Continuer avec Apple » — full-width sign-in buttons that follow each provider's own button rules, with a slot for the official mark.

## When to use
- On the welcome, sign-in and sign-up screens, under the e-mail form after an « ou » divider, stacked full width `space-3` apart.
- Show both providers at the same size and prominence; Apple requires its button to be no less prominent than other sign-in options.
- Not for MatchUp's own actions: « Se connecter » is a primary Button.

## Anatomy & specs
| Part | Spec |
|---|---|
| Button | `control-l` 48 high, full width by default, padding-inline `space-4`, `radius-md` |
| Mark slot | 20 × 20 before the label, gap `space-3`; holds the official mark (a dashed square in the preview) |
| Label | `label`; mark and label are centred together |

| Provider | Light | Night match |
|---|---|---|
| Google | fill `#FFFFFF`, 1px border `#747775`, text `#1F1F1F`; hover `#F8F9FA` | fill `#131314`, 1px border `#8E918F`, text `#E3E3E3` |
| Apple | fill `#000000`, text `#FFFFFF` | fill `#FFFFFF`, text `#000000` |

These are the providers' published button colours — the one place where literal colours replace tokens. They don't change with MatchUp's brand.

## States
- **Hover**: Google in Light → `#F8F9FA`; no other hover change.
- **Pressed**: `scale-press` 0.98 over `duration-fast`.
- **Focus**: `focus-ring`.
- No loading or disabled style: the provider's sheet takes over at once; ignore repeat taps while it is open.

## Content
- Use the providers' approved French titles only: « Continuer avec Google », « Continuer avec Apple » (or « Se connecter avec… » / « S’inscrire avec… » where the screen is clearly one or the other). Never « Google » alone or « Connexion Google ».
- If sign-in fails, say it in text under the buttons: « La connexion avec Google n’a pas abouti. Réessaie ou continue avec ton e-mail. »

## Accessibility
- The mark is `aria-hidden`; the visible label is the button's name.
- Label contrast: Google 16.5:1 (Light) and 14.5:1 (Night match), Apple 21:1; the Google border is 4.5:1 on white.
- 48 px high, above `touch-target`.

## Do / Don't
- Do take the Google « G » and the Apple logo from Google's and Apple's branding kits, or use the provider's SDK button, and follow each provider's guidelines for mark size, padding and colour.
- Don't redraw, recolour, crop or outline the marks, and don't swap in a Phosphor glyph.
- Don't restyle these buttons in Volt or ink, or add a MatchUp icon to them.
- Don't show the two providers at different widths or heights.

## Props (web preview)
`provider` · `fullWidth` · `children` (the label) · `onClick` · `state`. See `index.d.ts`.

## Flutter
`MuSocialButton(provider: MuSocialProvider.google, onPressed:, label: 'Continuer avec Google')` — an `OutlinedButton` (Google) or `FilledButton` (Apple), 48 high, radius 12, with the provider colours as fixed values switched on `Theme.of(context).brightness` (not `MuTheme` roles) and the official mark as a 20 × 20 `SvgPicture.asset` from the provider's kit. Where the SDK ships a button — `SignInWithAppleButton` from `sign_in_with_apple` — prefer it to a custom build.
