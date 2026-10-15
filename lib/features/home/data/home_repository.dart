import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// What the player Home shows (PLY-11).
abstract interface class HomeRepository {
  /// « Parties pour toi », best match first.
  Future<List<MuGame>> recommendedGames();

  Future<int> unreadNotifications();

  /// Invitations waiting on « Mes matchs ».
  Future<int> pendingInvitations();
}

/// The two games of PLY-11, dated tonight and tomorrow so they always look current.
class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  Future<List<MuGame>> recommendedGames() async {
    final today = _now();
    final tonight = DateTime(today.year, today.month, today.day, 20);
    final tomorrow = tonight.add(const Duration(days: 1));
    return [
      MuGame(
        sport: MuSport.padel,
        venue: 'Smash Padel Club',
        court: 'Court 3',
        place: 'Lac 2',
        distanceKm: 3.1,
        start: tonight,
        dateLabel: 'Ce soir',
        spotsTotal: 4,
        spotsLeft: 2,
        pricePerPlayer: 15,
        levelMin: 3,
        levelMax: 4,
        players: const [MuPerson('Mariem K.'), MuPerson('Ines M.')],
        organiser: 'Mariem K.',
        organiserReliability: 98,
        matchFit: 92,
        matchFitReason: 'ton niveau (3,5) et tes soirées en semaine',
      ),
      MuGame(
        sport: MuSport.football,
        venue: 'Arena Five',
        court: 'Terrain 2',
        place: 'La Marsa',
        distanceKm: 1.4,
        start: tomorrow,
        dateLabel: 'Demain',
        spotsTotal: 10,
        spotsLeft: 2,
        pricePerPlayer: 15,
        levelMin: 3,
        levelMax: 4.5,
        players: const [
          MuPerson('Skander T.'),
          MuPerson('Hamza R.'),
          MuPerson('Nour A.'),
          MuPerson('Aziz H.'),
          MuPerson('Omar D.'),
          MuPerson('Salma G.'),
          MuPerson('Lina F.'),
          MuPerson('Ines M.'),
        ],
        organiser: 'Skander T.',
        organiserReliability: 96,
        matchFit: 85,
        matchFitReason: 'Milieu recherché et terrain à 1,4 km',
      ),
    ];
  }

  @override
  Future<int> unreadNotifications() async => 3;

  @override
  Future<int> pendingInvitations() async => 1;
}
