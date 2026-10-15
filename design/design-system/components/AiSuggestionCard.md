# AiSuggestionCard

One AI recommendation — a game, a partner, a session, a price change — in a gradient-bordered card that says why, takes a thumbs vote and can be dismissed.

## When to use
- Player feeds (« Parties pour toi », « Joueurs pour toi »), coach and program nudges, owner dashboards (« Tarifs », « Remplissage »).
- **default** for a suggestion in a list or a dashboard column; **compact** in horizontal carousels, where the whole card opens the detail.
- Not for search results, promotions or system tips — those are ordinary cards without the gradient.

## Anatomy & specs
- Card: `mu-card` with a 1.5px border painted by `--ai-gradient` (`surface` on the padding box, the gradient on the border box), `radius-md`, `elevation-1`. Padding `space-4`, gap `space-3` (compact: `space-3` / `space-2`).
- Header: AiLabel S, context in `label-s` `text-secondary` (one line, ellipsis), dismiss IconButton S `x` at the end.
- With media (compact): CourtArt 16:9 edge to edge on top; AiLabel media S top-start at `space-3`, dismiss in the same dark glass top-end at `space-2`.
- Title: `h3` (compact `label-l`, two lines max).
- Fit: MatchFitScore pill S under the title; tapping it opens the « why » popover.
- Content slot: `body` in `text-secondary`. For a game, time, place, price per person and spots left are always visible (price in `num-m`, time in `num-xs`).
- Reason: an `ai-soft` well, `radius-sm`, padding `space-2` `space-3` — lightbulb (fill, 18) + « Recommandé car » in `label` + the reason in `body`, all `ai-text`. Compact: no well, `caption`, two lines.
- Footer: thumbs (IconButton S, gap `space-3`) at the start, actions M at the end — secondary, then primary. Wraps below on narrow widths.

## Variants
| Variant | Media | Footer | Opens the detail |
|---|---|---|---|
| default | optional | thumbs + 1–2 actions | the primary action |
| compact | CourtArt 16:9 | none (dismiss stays) | the whole card |

## States
- **Feedback**: a pressed thumb takes the `accent` fill and its fill-weight icon (`ease-pop`); the other thumb hides and « Merci pour ton retour » fades in (`caption`, `text-secondary`). Pressing it again withdraws the vote.
- **Dismissed**: collapses to a `surface-muted` row with a 1px dashed `border-strong` outline — eye-slash, « Suggestion masquée », tertiary S « Annuler ». Focus moves to « Annuler »; the row stays until the list refreshes. In a carousel the compact card keeps its slot as a dashed tile, content centred.
- **Loading**: AiShimmer `card`, same footprint.
- **Compact**: hover `elevation-2`, press 0.98, `focus-ring` around the card when its title button has focus.

## Content
- Title = the suggestion, concrete: « Partie de padel à Lac 2 ce soir », « Jeudi 14h–17h : 80 % de créneaux vides. Proposer −20 % ? ».
- Reason = evidence from the person's own data, never flattery: « ton niveau (3,5) est dans la fourchette et tu es dispo le jeudi soir ».
- Actions navigate or open a confirmation: « Voir la partie », « Appliquer » (then a sheet lists the 12 slots and the new price), « Ignorer ». Never « Rejoindre et payer » from a suggestion.

## Accessibility
- The card is an `article` labelled by its title. Thumbs form a group « Ton avis sur cette suggestion » of toggle buttons (`aria-pressed`); the thank-you is a polite status.
- Dismiss is named « Masquer la suggestion ». Compact: one stretched title button opens the game; dismiss and the fit pill stay separate targets above it.

## Do / Don't
- Do send the primary action to a review step — the AI never books, pays, publishes or changes a price by itself.
- Do keep one suggestion and one primary action per card.
- Don't drop the reason to save space — shorten it.
- Don't put the gradient border on non-AI cards.

## Props (web preview)
`variant` · `context` · `title` · `children` · `media` · `fit` · `fitFactors` · `reason` · `reasonLead` · `primaryAction` · `secondaryAction` · `showFeedback` · `feedback` · `onFeedback` · `dismissible` · `dismissed` · `onDismiss` · `onUndo` · `onClick`. See `index.d.ts`.

## Flutter
`MuAiSuggestionCard(title:, context:, content:, reason:, fit:, media:, primary: MuAction(...), secondary:, onFeedback:, onDismiss:, onUndo:, compact: false)` — a `StatefulWidget` (vote, dismissed). Paint the border with an outer `DecoratedBox(gradient: MuGradients.ai)` + 1.5 padding + an inner `surface` box (radius 10.5). Swap card ↔ dismissed row in an `AnimatedSwitcher` (`duration-base`); compact wraps the card in `InkWell`.
