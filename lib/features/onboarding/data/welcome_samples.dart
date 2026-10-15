import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// A booking split between players (ONB-03 illustration).
class SampleBooking {
  const SampleBooking({
    required this.sport,
    required this.venue,
    required this.court,
    required this.start,
    required this.courtPrice,
    required this.players,
    required this.paid,
    required this.people,
  });

  final MuSport sport;
  final String venue;
  final String court;
  final DateTime start;
  final num courtPrice;
  final int players;
  final int paid;
  final List<MuPerson> people;

  num get share => courtPrice / players;
}

/// The fixed content of the welcome slides' illustrations (ONB-02 to ONB-04): marketing art,
/// not live data, so it is not behind a repository.
abstract final class WelcomeSamples {
  static const double myLevel = 3.5;

  static const levelPeers = [
    ('Mariem K.', 3.5),
    ('Skander T.', 3.8),
    ('Ines M.', 3.2),
    ('Hamza R.', 4.0),
  ];

  static final game = MuGame(
    sport: MuSport.football,
    venue: 'Arena Five',
    court: 'Terrain 2',
    place: 'La Marsa',
    start: DateTime(2025, 10, 18, 20),
    spotsTotal: 10,
    spotsLeft: 2,
    pricePerPlayer: 15,
    levelMin: 3,
    levelMax: 4.5,
  );

  static final booking = SampleBooking(
    sport: MuSport.padel,
    venue: 'Smash Padel Club',
    court: 'Terrain 3',
    start: DateTime(2025, 10, 18, 20),
    courtPrice: 60,
    players: 4,
    paid: 3,
    people: const [
      MuPerson('Yassine B.'),
      MuPerson('Mariem K.'),
      MuPerson('Skander T.'),
      MuPerson('Ines M.'),
    ],
  );

  static const double basketLevel = 3.5;
  static const double basketTrend = 0.3;

  /// Progress from Intermédiaire towards Avancé, in %.
  static const double towardsNextBand = 67;

  static final tournament = MuTournament(
    sport: MuSport.basketball,
    name: 'Hoop Zone 3×3 Cup',
    start: DateTime(2025, 10, 24, 18),
    end: DateTime(2025, 10, 26, 22),
    venue: 'Hoop Zone',
    place: 'Ennasr',
    feePerTeam: 60,
    prize: 1500,
    teamsTotal: 16,
    teamsRegistered: 12,
    levelMin: 3.5,
    levelMax: 5.5,
  );
}
