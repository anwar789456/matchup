# EventCard
A social game or initiation day with individual sign-up, drawn as a ticket — a date stub, a perforation, then what, where, who runs it, places and price.

## When to use
- **Default** for « Événements » lists: « Journée initiation padel », « Soirée mixte football », afterworks.
- **Compact** in agendas, venue pages and « Mes inscriptions ».
- Players sign up one by one; for a team competition use TournamentCard, for an open game GameCard.

## Anatomy & specs
| Part | Spec |
|---|---|
| Surface | `mu-card`, row layout: stub + body |
| Stub | 72 wide, full height, `<sport>-soft`, start corners `radius-md`: weekday `overline`, day `num-xl` `text`, month `overline`, a 1 px rule in `<sport>-text`, start time `num-s` + duration `caption` |
| Perforation | 1.5 px dashed `border-strong` on the body's start edge |
| Body | padding `space-4`, rows `space-3` apart: kind `overline` with sport icon « PADEL · INITIATION » · title `label-l` · place `body` + pin · organiser « Par Smash Padel Club » + Vérifié seal, or « Par Lina F. · Fiable 97 % » |
| Scoreboard strip | bleeds to the body edges: PLACES « 6 libres » / dots (≤ 12 places) or fill bar · PRIX « Gratuit » or « 10 DT » / « raquettes prêtées », « par personne » |
| Footer | AvatarStack XS + « 10 inscrits » (hidden when the footer is ≤ 300) · CTA |
| Compact | min-height 88, padding `space-3`; stub 52 × 64 `radius-sm` (`num-l` day); kind `overline`, title `label`, « 10h00 – 13h00 · Smash Padel Club » `caption`; price `num-m` + places `label-s` or « Inscrit » badge at the end |

## Variants
`default` · `compact`.

## States
- **Open** — primary « S’inscrire ».
- **Registered** — ToggleButton pressed: Volt « Inscrit » with a check (compact: Volt badge). Tapping it opens « Se désinscrire ? » — never unregisters in one tap.
- **Almost full** — dots meter shows the last spots; compact count in `warning-text` (≤ 2).
- **Full** — « 0 libre », meter full, secondary « Liste d’attente ».
- **Focus** `focus-ring` · **Skeleton** same layout (stub without tint).

## Content
- Title says what and who for: « Initiation basket 3×3 femmes ».
- Price per person: « Gratuit » or « 10 DT »; the sub says what is included: « raquettes prêtées », « coach inclus ».
- Kind as one or two words: « Initiation », « Soirée sociale », « Afterwork ».

## Accessibility
- The stub is decorative; date and time are read with the title: « dim. 19 oct., 10h00 – 13h00 ».
- The registered toggle has `aria-pressed="true"` and the name « Inscrit — gérer mon inscription ».
- The Vérifié seal is an icon badge with the text « Vérifié » for screen readers.

## Do / Don't
- Do keep the perforation — it is what makes an event read as a ticket next to games.
- Do show who runs it; clubs carry the Vérifié seal, players their reliability.
- Don't colour the whole card with the sport; only the stub is tinted.

## Props (web preview)
`variant` · `sport` · `kind` · `title` · `start` · `end` · `venue` · `place` · `price` · `spotsTotal` · `spotsLeft` · `organiser` · `attendees` · `includes` · `registered` · `defaultRegistered` · `onRegisterChange` · `onWaitlist` · `href` · `onOpen` · `skeleton` · `state`. See `index.d.ts`.

## Flutter
`MuEventCard(event: MuEvent, variant: MuEventCardVariant.standard, registered:, onRegisterChanged:, onWaitlist:, onTap:, loading:)` — `MuCardSurface` with `IntrinsicHeight(Row([MuTicketStub, DashedDivider(vertical), Expanded(body)]))`; draw the perforation with a `CustomPainter` (dash 4, gap 4).
