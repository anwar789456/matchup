import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import 'assistant_models.dart';

/// A scripted answer of the fake assistant: what it understood, the search steps (AI-04), the
/// court found on the way, then the answer.
typedef AiScript = ({
  AiUnderstood understood,
  String? searching,
  List<String> steps,
  AiFound? found,
  List<AiBlock> blocks,
});

/// What the fake assistant says, from the screens AI-01…07 (« now » = ven. 16 oct. 18h00). The
/// backend's model will answer instead; the texts are data, like any server answer.
abstract final class AssistantStory {
  /// The owner's venue (AI-07: « Espace propriétaire · Arena Five »).
  static const ownerVenue = 'Arena Five';

  static const suggestions = [
    'Trouve-moi une partie de padel demain soir',
    'Réserve un terrain à La Marsa samedi',
    'Quel programme pour améliorer mon service ?',
  ];

  static const ownerSuggestions = [
    'Mes créneaux les moins remplis',
    'Mes revenus du mois',
    'Les absents de la semaine',
  ];

  static final playerContext = [
    AiContextItem(PhosphorIcons.gauge(), 'Padel 3,5', 'Foot 3,0'),
    AiContextItem(PhosphorIcons.mapPin(), 'La Marsa', '10 km · ta zone'),
    AiContextItem(PhosphorIcons.calendarCheck(), 'Lun., mer., sam.', 'Tes soirs libres'),
    AiContextItem(PhosphorIcons.wallet(), 'Solde 30 DT', 'Si tu confirmes'),
  ];

  static final ownerContext = [
    AiContextItem(PhosphorIcons.storefront(), 'Arena Five', '3 terrains · La Marsa'),
    AiContextItem(PhosphorIcons.calendarBlank(), 'Ton planning', '4 semaines'),
    AiContextItem(PhosphorIcons.chartBar(), 'Tes revenus', 'Septembre et octobre'),
    AiContextItem(PhosphorIcons.tag(), 'Tes tarifs', 'Heures pleines et creuses'),
  ];

  // ── AI-02: « Réserve un terrain à La Marsa samedi » ─────────────────────────────────────────

  static final arenaSlots = AiSlots(
    venueId: Story.arenaFive.id,
    sport: MuSport.football,
    venue: 'Arena Five',
    place: 'La Marsa',
    rating: 4.7,
    reviews: 128,
    distanceKm: 1.4,
    surface: 'synthétique, extérieur, éclairé',
    slots: [
      AiSlot(start: Story.at(17, 19), court: 'Terrain 1'),
      AiSlot(start: Story.at(17, 20), court: 'Terrain 2'),
      AiSlot(start: Story.at(17, 22), court: 'Terrain 3', indoor: true),
    ],
    picked: 1,
    price: 150,
    players: 10,
    reason: 'tu joues le plus souvent vers 20h00 et le Terrain 2 est extérieur et éclairé.',
  );

  static final _g1Factors = [
    MuFitFactor(
      icon: PhosphorIcons.gauge(),
      label: 'Niveau proche',
      detail: 'Toi 3,0 · partie 3,0–4,5',
    ),
    MuFitFactor(
      icon: PhosphorIcons.users(),
      label: 'Milieu recherché',
      detail: 'Ton poste au foot',
    ),
    MuFitFactor(icon: PhosphorIcons.mapPin(), label: 'À 1,4 km', detail: 'Arena Five · La Marsa'),
  ];

  static final _g2Factors = [
    MuFitFactor(
      icon: PhosphorIcons.gauge(),
      label: 'Niveau proche',
      detail: 'Toi 3,5 · partie 3,0–4,0',
    ),
    MuFitFactor(
      icon: PhosphorIcons.users(),
      label: 'Côté gauche recherché',
      detail: 'Ton côté au padel',
    ),
    MuFitFactor(
      icon: PhosphorIcons.handshake(),
      label: 'A déjà joué avec Mariem K.',
      detail: 'Victoire 6-4 6-3 le 9 oct.',
    ),
  ];

  static AiUnderstood get _footSaturday => [
    (PhosphorIcons.soccerBall(), 'Foot 5v5'),
    (PhosphorIcons.mapPin(), 'La Marsa'),
    (PhosphorIcons.calendarBlank(), 'sam. 17 oct. · soir'),
  ];

  static AiScript get _book => (
    understood: _footSaturday,
    searching: null,
    steps: const [],
    found: null,
    blocks: [
      const AiText(
        'Samedi soir, Arena Five a encore 3 créneaux : c’est le terrain vérifié le plus proche de '
        'toi (1,4 km). Je te propose 20h00 sur le Terrain 2.',
      ),
      arenaSlots,
      const AiText(
        'Tu préfères rejoindre une partie déjà ouverte ? Il reste 2 places dimanche, au même '
        'endroit.',
      ),
      AiGame(game: Story.g1, factors: _g1Factors),
      AiFollowUps([
        (PhosphorIcons.clock(), 'Moins cher avant 18h'),
        (PhosphorIcons.gridFour(), 'En indoor'),
        (PhosphorIcons.calendarBlank(), 'Plutôt dimanche'),
      ]),
    ],
  );

  static AiScript get _indoor => (
    understood: [..._footSaturday, (PhosphorIcons.gridFour(), 'Indoor')],
    searching: null,
    steps: const [],
    found: null,
    blocks: [
      const AiText(
        'En indoor samedi soir, Arena Five a le Terrain 3 à 22h00. C’est le seul couvert.',
      ),
      arenaSlots.pick(2),
    ],
  );

  static AiScript get _cheaper => (
    understood: [..._footSaturday, (PhosphorIcons.clock(), 'avant 18h')],
    searching: null,
    steps: const [],
    found: null,
    blocks: [
      const AiText(
        'Avant 18h, Arena Five est complet samedi. Le soir reste le moins cher près de toi : '
        '15 DT par joueur à 10.',
      ),
      arenaSlots,
    ],
  );

  static AiScript get _sunday => (
    understood: [
      (PhosphorIcons.soccerBall(), 'Foot 5v5'),
      (PhosphorIcons.mapPin(), 'La Marsa'),
      (PhosphorIcons.calendarBlank(), 'dim. 18 oct. · soir'),
    ],
    searching: null,
    steps: const [],
    found: null,
    blocks: [
      const AiText('Dimanche à 20h00, la partie d’Arena Five a encore 2 places, à ton niveau.'),
      AiGame(game: Story.g1, factors: _g1Factors),
    ],
  );

  // ── AI-04 → AI-05: « Trouve-moi une partie de padel demain soir » ───────────────────────────

  static AiScript get _padel => (
    understood: [
      (PhosphorIcons.tennisBall(), 'Padel'),
      (PhosphorIcons.calendarBlank(), 'sam. 17 oct. · 18h–23h'),
      (PhosphorIcons.gauge(), 'Niveau 3,0–4,0'),
      (PhosphorIcons.mapPin(), '10 km'),
    ],
    searching: 'Je cherche ta partie de padel',
    steps: const [
      'Lecture de ta demande',
      'Courts libres près de toi',
      'Parties ouvertes à ton niveau',
    ],
    found: const AiFound(
      sport: MuSport.padel,
      venue: 'Smash Padel Club · Court 1',
      when: 'sam. 17 oct. · 19h30–21h00 · indoor',
      meta: 'Lac 2 · 3,1 km · court libre',
      price: 25,
      players: 4,
    ),
    blocks: [
      const AiNothingFound('demain soir à ton niveau, à moins de 10 km.', 'Aucune partie ouverte'),
      const AiText(
        'Pas de partie à rejoindre, mais un court est libre à 19h30. Je peux créer ta partie et '
        'proposer les 3 places à des joueurs de ton niveau.',
      ),
      AiCreateGame(
        venueId: Story.smashPadel.id,
        sport: MuSport.padel,
        start: Story.at(17, 19, 30),
        minutes: 90,
        venue: 'Smash Padel Club · Court 1',
        meta: 'Lac 2 · 3,1 km · indoor',
        price: 100,
        players: 4,
        reason: 'tu as gagné 6-4 6-3 dans ce club le 9 oct. et le court est libre à ton heure habituelle.',
      ),
      const AiText('Ou ce soir : une partie à ton niveau a encore 2 places.'),
      AiGame(game: Story.g2, factors: _g2Factors),
      const AiAlert('Padel · sam. 17 oct. · soir · 3,0–4,0'),
      AiFollowUps([
        (PhosphorIcons.mapPin(), 'Élargir à 15 km'),
        (PhosphorIcons.calendarBlank(), 'Dimanche soir'),
        (PhosphorIcons.gauge(), 'Niveau 2,5–4,5'),
      ]),
    ],
  );

  // ── Training (Entraînement) and level ───────────────────────────────────────────────────────

  static AiScript get _programs => (
    understood: [
      (PhosphorIcons.barbell(), 'Entraînement'),
      (PhosphorIcons.tennisBall(), 'Padel'),
      (PhosphorIcons.target(), 'Service'),
    ],
    searching: null,
    steps: const [],
    found: null,
    blocks: const [
      AiText(
        'Pour ton service, « Service et retour » est fait pour toi : il travaille la régularité '
        'du premier service et le retour croisé. Tu peux le suivre en parallèle de ton programme '
        'Bandeja, où tu en es à la séance 5.',
      ),
      AiPrograms(['service-retour']),
    ],
  );

  static AiScript get _level => (
    understood: const [],
    searching: null,
    steps: const [],
    found: null,
    blocks: const [
      AiText(
        'Ton 3,5 vient surtout de tes 18 matchs et de 9 avis de coéquipiers. Il a pris +0,2 en '
        '30 jours.',
      ),
    ],
  );

  static AiScript _help(AssistantSpace space) => (
    understood: const [],
    searching: null,
    steps: const [],
    found: null,
    blocks: [
      AiText(
        space == AssistantSpace.owner
            ? 'Je t’aide sur ton planning, tes tarifs et tes réservations. Par exemple :'
            : 'Je peux te trouver une partie, réserver un terrain ou te conseiller un programme. '
                  'Par exemple :',
      ),
      AiFollowUps([
        for (final s in space == AssistantSpace.owner ? ownerSuggestions : suggestions)
          (PhosphorIcons.sparkle(), s),
      ]),
    ],
  );

  // ── AI-07: « Quels créneaux sont les moins remplis cette semaine ? » ────────────────────────

  static AiScript get _emptySlots => (
    understood: [
      (PhosphorIcons.storefront(), 'Arena Five · 3 terrains'),
      (PhosphorIcons.calendarBlank(), 'lun. 12 → dim. 18 oct.'),
    ],
    searching: null,
    steps: const [],
    found: null,
    blocks: [
      const AiText(
        'Les après-midi de semaine. Le plus vide : jeudi 14h–17h, rempli à 20 % seulement sur '
        'tes 3 terrains. Le soir, tu es au-dessus de 85 % tous les jours.',
      ),
      const AiChart(
        title: 'Créneaux les plus vides',
        subtitle: 'Taux de remplissage · lun. 12 → dim. 18 oct.',
        categories: ['Jeu. 14h–17h', 'Mar. 14h–17h', 'Lun. 10h–13h', 'Mer. 8h–11h'],
        values: [20, 33, 38, 42],
      ),
      AiPromo(
        weekday: DateTime.thursday,
        fromHour: 14,
        toHour: 17,
        percent: 20,
        priceBefore: 120,
        slots: 9,
        date: Story.at(22, 14),
        players: 10,
        title: 'Jeudi 14h–17h : 80 % de créneaux vides. Proposer −20 % ?',
        reason:
            '4 de tes 5 derniers jeudis après-midi sont restés presque vides, alors que tes soirs '
            'sont pleins.',
      ),
      AiFollowUps([
        (PhosphorIcons.calendarBlank(), 'Et la semaine prochaine ?'),
        (PhosphorIcons.gridFour(), 'Détail par terrain'),
      ]),
    ],
  );

  /// Lower case, no accents: « Réserve » → « reserve ».
  static String normalize(String s) {
    const from = 'àâäéèêëîïôöùûüç’';
    const to = 'aaaeeeeiioouuuc\'';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    return b.toString();
  }

  /// Picks the script for [request].
  static AiScript answer(String request, AssistantSpace space) {
    final q = normalize(request);
    bool has(String w) => q.contains(w);
    if (space == AssistantSpace.owner) {
      return has('rempli') || has('vide') || has('creneau') ? _emptySlots : _help(space);
    }
    if (has('programme') || has('service') || has('entrain') || has('progresser')) return _programs;
    if (has('pourquoi') || has('niveau') && has('3,5')) return _level;
    if (has('padel')) return _padel;
    if (has('indoor')) return _indoor;
    if (has('dimanche')) return _sunday;
    if (has('moins cher') || has('avant 18')) return _cheaper;
    if (has('reserve') || has('terrain') || has('foot') || has('marsa')) return _book;
    return _help(space);
  }
}
