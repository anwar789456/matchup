import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';

/// A level the AI estimates for one sport, with its history (PRF-01 « Mes niveaux »).
@immutable
class SportLevel {
  const SportLevel({
    required this.sport,
    required this.level,
    required this.matches,
    required this.position,
    required this.trend,
    required this.confidence,
    required this.reason,
    required this.history,
    this.updatedOn,
    this.range,
  });

  final MuSport sport;
  final double level;
  final int matches;

  /// « côté gauche », « milieu ».
  final String position;
  final double trend;
  final MuConfidence confidence;
  final String reason;

  /// The last 10 matches, oldest first.
  final List<double> history;
  final String? updatedOn;

  /// « très probablement entre 3,3 et 3,7 ».
  final (double, double)? range;
}

@immutable
class Reliability {
  const Reliability({
    required this.score,
    required this.honored,
    required this.total,
    required this.note,
  });

  final int score;
  final int honored;
  final int total;
  final String note;
}

@immutable
class ProfileBadge {
  const ProfileBadge({required this.icon, required this.name, required this.detail, this.progress});

  final IconData icon;
  final String name;
  final String detail;

  /// Earned when null; a 0–1 ring otherwise (« Centurion 50/100 »).
  final double? progress;
}

enum MatchOutcome { win, loss, friendly }

@immutable
class ProfileMatch {
  const ProfileMatch({required this.outcome, required this.title, required this.meta, this.delta});

  final MatchOutcome outcome;

  /// « Victoire 6-4 6-3 ».
  final String title;

  /// « ven. 9 oct. · Padel · avec Mariem K. ».
  final String meta;

  /// Level change, « +0,1 »; null for a friendly.
  final double? delta;
}

@immutable
class ProfileReview {
  const ProfileReview({
    required this.author,
    required this.meta,
    required this.text,
    required this.rating,
  });

  final MuPerson author;
  final String meta;
  final String text;
  final double rating;
}

@immutable
class ReviewSummary {
  const ReviewSummary({
    required this.average,
    required this.count,
    required this.note,
    required this.tags,
    required this.latest,
  });

  final double average;
  final int count;

  /// « fair-play et ponctualité ».
  final String note;
  final List<(String, int)> tags;
  final List<ProfileReview> latest;
}

/// Why a level is what it is (PRF-03).
@immutable
class LevelExplanation {
  const LevelExplanation({required this.factors, required this.matches});

  /// (label, weight 0–1, detail).
  final List<(String, double, String)> factors;

  /// (result, date, detail, delta).
  final List<(String, String, String, double)> matches;
}

enum ProfileVisibility { everyone, followers }

/// A player's profile — mine (PRF-01) or someone else's (PRF-02).
@immutable
class PlayerProfile {
  const PlayerProfile({
    required this.name,
    required this.handle,
    required this.zone,
    required this.bio,
    required this.sports,
    required this.positions,
    required this.followers,
    required this.following,
    required this.since,
    required this.winRate,
    required this.matches,
    required this.wins,
    required this.tournaments,
    required this.levels,
    required this.reliability,
    required this.badges,
    required this.badgeCount,
    required this.recentMatches,
    required this.reviews,
    required this.coverSport,
    this.zones = const [],
    this.visibility = ProfileVisibility.everyone,
    this.showLevel = true,
    this.showReliability = true,
    this.suggestPartner = true,
    this.fit,
    this.fitReason,
    this.together,
    this.followed = false,
    this.otherSportNote,
  });

  final String name;
  final String handle;
  final String zone;
  final String bio;
  final List<MuSport> sports;

  /// Position per sport (« côté gauche », « milieu »).
  final Map<MuSport, String> positions;
  final int followers;
  final int following;

  /// « oct. 2025 ».
  final String since;
  final int winRate;
  final int matches;
  final int wins;
  final int tournaments;
  final List<SportLevel> levels;
  final Reliability reliability;
  final List<ProfileBadge> badges;
  final int badgeCount;
  final List<ProfileMatch> recentMatches;
  final ReviewSummary reviews;
  final MuSport coverSport;
  final List<String> zones;
  final ProfileVisibility visibility;
  final bool showLevel;
  final bool showReliability;
  final bool suggestPartner;

  /// Someone else's profile: the AI fit with their games and its reason.
  final int? fit;
  final String? fitReason;

  /// « 4 matchs ensemble · le dernier sam. 3 oct. ».
  final String? together;
  final bool followed;

  /// « Confiance faible · 7 matchs de padel » for the sport they rarely play.
  final (MuSport, double, String)? otherSportNote;

  String get initials => initialsOf(name);

  PlayerProfile copyWith({
    String? handle,
    String? bio,
    List<MuSport>? sports,
    Map<MuSport, String>? positions,
    List<String>? zones,
    ProfileVisibility? visibility,
    bool? showLevel,
    bool? showReliability,
    bool? suggestPartner,
    bool? followed,
  }) => PlayerProfile(
    name: name,
    handle: handle ?? this.handle,
    zone: zone,
    bio: bio ?? this.bio,
    sports: sports ?? this.sports,
    positions: positions ?? this.positions,
    followers: followers,
    following: following,
    since: since,
    winRate: winRate,
    matches: matches,
    wins: wins,
    tournaments: tournaments,
    levels: levels,
    reliability: reliability,
    badges: badges,
    badgeCount: badgeCount,
    recentMatches: recentMatches,
    reviews: reviews,
    coverSport: coverSport,
    zones: zones ?? this.zones,
    visibility: visibility ?? this.visibility,
    showLevel: showLevel ?? this.showLevel,
    showReliability: showReliability ?? this.showReliability,
    suggestPartner: suggestPartner ?? this.suggestPartner,
    fit: fit,
    fitReason: fitReason,
    together: together,
    followed: followed ?? this.followed,
    otherSportNote: otherSportNote,
  );
}

abstract interface class PlayerProfileRepository {
  Future<PlayerProfile> me();
  Future<PlayerProfile> player(String name);
  Future<void> save(PlayerProfile profile);
  Future<void> follow(String name, {required bool follow});
  Future<LevelExplanation> explain(MuSport sport);

  /// « Ajuster »: counts as a self-assessment, confirmed by the next 3 matches.
  Future<void> adjustLevel(MuSport sport, double level);
  Future<void> contestLevel(MuSport sport);
}

/// Yassine B. and Skander T. from the story (design/screens/STORY-DATA.md).
class FakePlayerProfileRepository implements PlayerProfileRepository {
  FakePlayerProfileRepository({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;
  PlayerProfile _me = yassine;
  final _followed = <String>{};

  static final yassine = PlayerProfile(
    name: Story.myName,
    handle: 'yassine.b',
    zone: Story.zone,
    bio:
        'Padel le soir à Lac 2, foot le week-end à La Marsa. Toujours partant pour compléter une '
        'équipe.',
    sports: const [MuSport.padel, MuSport.football],
    positions: const {MuSport.padel: 'côté gauche', MuSport.football: 'milieu'},
    followers: 38,
    following: 41,
    since: 'oct. 2025',
    winRate: 58,
    matches: 50,
    wins: 29,
    tournaments: 2,
    zones: const ['La Marsa', 'Lac 2'],
    coverSport: MuSport.padel,
    levels: const [
      SportLevel(
        sport: MuSport.padel,
        level: 3.5,
        matches: 18,
        position: 'côté gauche',
        trend: 0.2,
        confidence: MuConfidence.high,
        reason: 'Basé sur tes 18 matchs de padel et 9 avis de coéquipiers.',
        history: [3.2, 3.2, 3.3, 3.3, 3.2, 3.4, 3.4, 3.5, 3.4, 3.5],
        updatedOn: 'ven. 9 oct.',
        range: (3.3, 3.7),
      ),
      SportLevel(
        sport: MuSport.football,
        level: 3.0,
        matches: 31,
        position: 'milieu',
        trend: 0,
        confidence: MuConfidence.medium,
        reason:
            'Basé sur tes 31 matchs de foot et 6 avis. Peu d’avis récents, la confiance remontera '
            'avec tes prochains matchs.',
        history: [3.0, 3.1, 3.0, 3.0, 2.9, 3.0, 3.0, 3.1, 3.0, 3.0],
        updatedOn: 'sam. 3 oct.',
        range: (2.8, 3.2),
      ),
    ],
    reliability: const Reliability(
      score: 96,
      honored: 48,
      total: 50,
      note:
          '2 absences en 12 mois. Un désistement à moins de 24 h compte comme une absence : '
          'préviens l’organisateur dès que tu sais.',
    ),
    badges: [
      ProfileBadge(icon: PhosphorIcons.clock(), name: 'Ponctuel', detail: '20 matchs'),
      ProfileBadge(icon: PhosphorIcons.handshake(), name: 'Fair-play', detail: '4,8/5'),
      ProfileBadge(icon: PhosphorIcons.trophy(), name: 'Finaliste', detail: 'Padel Cup'),
      ProfileBadge(
        icon: PhosphorIcons.medalMilitary(),
        name: 'Centurion',
        detail: '50/100',
        progress: 0.5,
      ),
    ],
    badgeCount: 12,
    recentMatches: const [
      ProfileMatch(
        outcome: MatchOutcome.win,
        title: 'Victoire 6-4 6-3',
        meta: 'ven. 9 oct. · Padel · avec Mariem K.',
        delta: 0.1,
      ),
      ProfileMatch(
        outcome: MatchOutcome.loss,
        title: 'Défaite 5-7',
        meta: 'sam. 3 oct. · Football · Arena Five',
        delta: 0,
      ),
      ProfileMatch(
        outcome: MatchOutcome.friendly,
        title: 'Partie amicale · sans score',
        meta: 'dim. 27 sept. · Basket · Hoop Zone',
      ),
    ],
    reviews: const ReviewSummary(
      average: 4.8,
      count: 23,
      note: 'fair-play et ponctualité',
      tags: [('Fair-play', 18), ('Ponctuel', 15), ('Collectif', 11)],
      latest: [
        ProfileReview(
          author: Story.mariem,
          meta: 'Padel · ven. 9 oct.',
          text:
              'Super partenaire à gauche, toujours positif même menés 2-4. On rejoue quand tu '
              'veux.',
          rating: 5,
        ),
      ],
    ),
  );

  static final skander = PlayerProfile(
    name: 'Skander T.',
    handle: 'skander.t',
    zone: 'La Marsa',
    bio:
        'Attaquant. J’organise le 5v5 du dimanche soir à Arena Five : niveau 3,0–4,5, chasubles '
        'fournies, on commence à l’heure.',
    sports: const [MuSport.football, MuSport.padel],
    positions: const {MuSport.football: 'attaquant'},
    followers: 184,
    following: 120,
    since: 'janv. 2025',
    winRate: 55,
    matches: 75,
    wins: 41,
    tournaments: 3,
    coverSport: MuSport.football,
    fit: 85,
    fitReason:
        'Recommandé car il cherche souvent un milieu, joue à 1,4 km de chez toi, et ses parties '
        '(3,0–4,5) sont à ton niveau.',
    together: '4 matchs ensemble · le dernier sam. 3 oct.',
    otherSportNote: (MuSport.padel, 3.0, 'Confiance faible · 7 matchs de padel'),
    levels: const [
      SportLevel(
        sport: MuSport.football,
        level: 4.0,
        matches: 68,
        position: 'attaquant',
        trend: 0.1,
        confidence: MuConfidence.high,
        reason: 'Basé sur ses 68 matchs de foot et 27 avis de coéquipiers.',
        history: [3.7, 3.8, 3.8, 3.9, 3.8, 3.9, 3.9, 4.0, 3.9, 4.0],
      ),
    ],
    reliability: const Reliability(
      score: 96,
      honored: 72,
      total: 75,
      note: '3 absences en 12 mois. Calculé sur les parties réservées sur MatchUp.',
    ),
    badges: [
      ProfileBadge(icon: PhosphorIcons.flagBanner(), name: 'Organisateur', detail: '40 parties'),
      ProfileBadge(icon: PhosphorIcons.clock(), name: 'Ponctuel', detail: '30 matchs'),
      ProfileBadge(icon: PhosphorIcons.handshake(), name: 'Fair-play', detail: '4,7/5'),
      ProfileBadge(icon: PhosphorIcons.trophy(), name: 'Tournois', detail: '3 joués'),
    ],
    badgeCount: 12,
    recentMatches: const [
      ProfileMatch(
        outcome: MatchOutcome.win,
        title: 'Victoire 6-3',
        meta: 'dim. 11 oct. · Football · Arena Five',
      ),
      ProfileMatch(
        outcome: MatchOutcome.loss,
        title: 'Défaite 5-7',
        meta: 'sam. 3 oct. · Football · Arena Five · avec toi',
      ),
    ],
    reviews: const ReviewSummary(
      average: 4.7,
      count: 28,
      note: 'surtout organisation et fair-play',
      tags: [('Organisé', 21), ('Fair-play', 18), ('Ponctuel', 16)],
      latest: [
        ProfileReview(
          author: Story.mariem,
          meta: 'Football · dim. 11 oct.',
          text:
              'Organisation au top : terrain confirmé la veille, chasubles prêtes, et il '
              'équilibre les équipes avant le coup d’envoi.',
          rating: 5,
        ),
      ],
    ),
  );

  @override
  Future<PlayerProfile> me() async {
    await Future<void>.delayed(latency);
    return _me;
  }

  @override
  Future<PlayerProfile> player(String name) async {
    await Future<void>.delayed(latency);
    if (name == Story.myName) return _me;
    return skander.copyWith(followed: _followed.contains(name));
  }

  @override
  Future<void> save(PlayerProfile profile) async {
    await Future<void>.delayed(latency);
    _me = profile;
  }

  @override
  Future<void> follow(String name, {required bool follow}) async {
    if (follow) {
      _followed.add(name);
    } else {
      _followed.remove(name);
    }
  }

  @override
  Future<LevelExplanation> explain(MuSport sport) async {
    await Future<void>.delayed(latency);
    return const LevelExplanation(
      factors: [
        ('Tes 18 matchs de padel', 0.55, 'Résultats et niveau des adversaires (3,0 à 4,5)'),
        ('9 avis de coéquipiers', 0.30, '7 « conforme », 2 « au-dessus » de ton niveau'),
        ('Ton questionnaire de départ', 0.15, ''),
      ],
      matches: [
        ('Victoire 6-4 6-3', 'ven. 9 oct.', 'Contre Ines M. et Nour A., moyenne 3,5', 0.1),
        ('Victoire 6-3 7-5', 'jeu. 1 oct.', 'Contre une paire à 3,7, donc plus forte', 0.1),
        ('Défaite 4-6 6-7', 'mar. 22 sept.', 'Serrée contre une paire à 4,0 : pas de baisse', 0),
      ],
    );
  }

  @override
  Future<void> adjustLevel(MuSport sport, double level) async {}

  @override
  Future<void> contestLevel(MuSport sport) async {}
}

final playerProfileRepositoryProvider = Provider<PlayerProfileRepository>(
  (ref) => FakePlayerProfileRepository(),
);

final myProfileProvider = FutureProvider<PlayerProfile>(
  (ref) => ref.watch(playerProfileRepositoryProvider).me(),
);

final playerProfileProvider = FutureProvider.family<PlayerProfile, String>(
  (ref, name) => ref.watch(playerProfileRepositoryProvider).player(name),
);
