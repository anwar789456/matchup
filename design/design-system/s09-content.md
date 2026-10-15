# Content and microcopy

Friendly, short, energetic, in French with « tu ». Write like the player who organises the Thursday game: direct, warm, exact about money and time.

## Voice

| Do | Don't |
|---|---|
| « Rejoindre et payer · 15 DT » | « Valider » |
| « Plus que 1 place » | « Places disponibles : 1 » |
| « Paiement refusé par ta banque. Aucun montant débité. Essaie une autre carte. » | « Erreur 402 » |
| « Annuler la réservation ? 45 DT seront remboursés sur ton solde MatchUp. » | « Êtes-vous sûr ? » |
| « Aucun match à venir. Trouve une partie à ton niveau près de chez toi. » | « Aucune donnée » |
| « Non merci, résilier » (as visible as the offer) | A grey link hidden under the offer |

- Buttons are verbs, 1–3 words, sentence case: « Réserver », « Inviter des joueurs », « Réclamer la place ».
- Titles name the thing, not the screen: « Arena Five · Terrain 2 », not « Détail du terrain ».
- Errors: what happened, then what to do. Never blame the player, never apologise at length.
- Empty states: one sentence of why, one action.
- Count what is left, not what is taken: « 2 places libres ».
- Time-limited actions show the countdown in the button: « Réclamer la place · 14:59 ».

## Formats

| Thing | Format | Helper |
|---|---|---|
| Money | « 60 DT », « 12,500 DT », « 1 250 DT », « −15 DT », « +45 DT » | `formatDT` |
| Price per person | « 15 DT /pers. » or « 15 DT par joueur » | — |
| Date | « sam. 18 oct. » | `formatDate` |
| Time | « 20h00 » | `formatTime` |
| Date and time | « sam. 18 oct. · 20h00 » | `formatDateTime` |
| Countdown | « 14:59 », « 1:04:05 » | `formatCountdown` |
| Phone | « +216 20 123 456 » | `formatPhone` |
| Level | « 3,5 · Intermédiaire » (1,0–7,0) | `formatLevel`, `levelLabel` |
| Percent | « 96 % », « 92 % compatible » | `formatPercent` |
| Distance | « 2,4 km » | — |
| Booking code | « #MU-20481 » | — |

The middle dot « · » separates facts on one line. Decimals use a comma; thousands use a narrow space.

## AI copy

- Label every AI output « IA » and say why: « Recommandé car tu joues le jeudi soir et ton niveau (3,5) correspond. »
- Offer control: « Modifier », « Régénérer », « Masquer ce type de suggestion ».
- Before booking or paying, confirm in full: « Je réserve le Terrain 2 à Arena Five, sam. 18 oct. à 20h00, 60 DT (15 DT par joueur). Confirmer ? » → « Confirmer » / « Modifier ».
- Footnote where answers are generated: « L'IA peut se tromper. Vérifie les infos importantes. »

## Sample data

Players: Yassine B., Mariem K., Skander T., Ines M., Hamza R., Nour A., Aziz H., Salma G., Omar D., Lina F. Places: La Marsa, Lac 2, Ennasr, Menzah 6, Ariana, Sousse, Sfax. Venues (fictional): Arena Five (football, La Marsa), Smash Padel Club (padel, Lac 2), Hoop Zone (basketball, Ennasr). Teams: FC La Marsa, Lac 2 United, Les Faucons, Ennasr Ballers. Prices: football court 150 DT for 10 players (15 DT each), padel 60 DT for 4 (15 DT each), basketball 80 DT for 6 (13,333 DT each). Never lorem ipsum.
