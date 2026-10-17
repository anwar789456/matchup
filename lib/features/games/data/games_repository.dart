import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/connectivity.dart';
import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import 'game_details.dart';

export 'game_details.dart';

/// Open games (« Parties »): Explorer's list, the Home's « Parties pour toi », and the game page
/// with its lineup, waitlist and the player's membership.
abstract interface class GamesRepository {
  /// Open games near the player's zone, recommended first.
  Future<List<MuGame>> openGames();

  /// « Parties pour toi »: the AI's best matches, best first.
  Future<List<MuGame>> recommended();

  /// Lists a public game the player organises, so players at their level can join it.
  Future<void> publish(MuGame game);

  /// The game page.
  Future<GameDetails> details(String id);

  /// The games the player joined, for « Mes matchs » (status joined).
  Future<List<MuGame>> joined();

  /// Takes the free position [slot] of team [team], once the share is paid.
  Future<void> join(String id, {required int team, required int slot});

  /// Gives the place back; the share is refunded to the balance.
  Future<void> leave(String id);

  Future<void> joinWaitlist(String id);
  Future<void> leaveWaitlist(String id);

  /// A player left a full game: one place opens, for the waitlist to claim.
  Future<void> freeSpot(String id);
}

/// The story's games (design/screens/STORY-DATA.md), with the membership kept in memory.
class FakeGamesRepository implements GamesRepository {
  FakeGamesRepository({this.latency = const Duration(milliseconds: 700), bool Function()? offline})
    : _offline = offline ?? (() => false);

  final Duration latency;
  final bool Function() _offline;
  final _published = <MuGame>[];
  final _membership = <String, GameMembership>{};
  final _slot = <String, (int, int)>{};
  final _waitlistPosition = <String, int>{};
  final _freed = <String, int>{};

  // STORY-DATA.md: the levels of the people around Yassine (football unless padel).
  static const _levels = <String, double>{
    'Skander T.': 4.0,
    'Hamza R.': 3.5,
    'Nour A.': 3.0,
    'Aziz H.': 4.5,
    'Omar D.': 3.5,
    'Salma G.': 3.0,
    'Lina F.': 3.5,
    'Ines M.': 4.0,
    'Mariem K.': 4.0,
    'Rami S.': 3.5,
    'Yassine B.': 3.0,
  };

  /// Players per side.
  static int teamSize(MuSport sport) => switch (sport) {
    MuSport.football => 5,
    MuSport.padel => 2,
    MuSport.basketball => 3,
  };

  static List<String> teamNames(MuSport sport) => switch (sport) {
    MuSport.basketball => const ['Noirs', 'Oranges'],
    MuSport.padel => const ['Équipe A', 'Équipe B'],
    _ => const ['Blancs', 'Bleus'],
  };

  Future<void> _wait() async {
    await Future<void>.delayed(latency);
    if (_offline()) throw const OfflineException();
  }

  MuGame? _find(String id) {
    for (final g in [...Story.openGames, ..._published]) {
      if (g.id == id) return g;
    }
    return null;
  }

  MuGame _current(MuGame g) {
    final joined = _membership[g.id] == GameMembership.joined;
    final left = g.spotsLeft + (_freed[g.id] ?? 0) - (joined ? 1 : 0);
    return MuGame(
      id: g.id,
      venueId: g.venueId,
      sport: g.sport,
      venue: g.venue,
      court: g.court,
      place: g.place,
      distanceKm: g.distanceKm,
      start: g.start,
      spotsTotal: g.spotsTotal,
      spotsLeft: left,
      pricePerPlayer: g.pricePerPlayer,
      gameType: g.gameType,
      levelMin: g.levelMin,
      levelMax: g.levelMax,
      dateLabel: g.dateLabel,
      players: joined ? [...g.players, Story.yassine] : g.players,
      organiser: g.organiser,
      organiserReliability: g.organiserReliability,
      matchFit: g.matchFit,
      matchFitReason: g.matchFitReason,
      status: joined ? MuGameStatus.joined : g.status,
      refund: g.refund,
    );
  }

  @override
  Future<List<MuGame>> openGames() async {
    await _wait();
    return [
      for (final g in [...Story.openGames, ..._published]) _current(g),
    ];
  }

  @override
  Future<void> publish(MuGame game) async => _published.add(game);

  @override
  Future<List<MuGame>> recommended() async {
    await _wait();
    return [_current(Story.g1), _current(Story.g2)];
  }

  @override
  Future<List<MuGame>> joined() async {
    await Future<void>.delayed(latency);
    return [
      for (final g in [...Story.openGames, ..._published])
        if (_membership[g.id] == GameMembership.joined) _current(g),
    ];
  }

  /// G1's teams as the lobby shows them (STORY-DATA.md); other games fill their sides in order.
  List<MuLineupTeam> _teams(MuGame g) {
    final size = teamSize(g.sport);
    final names = teamNames(g.sport);
    MuLineupPlayer player(MuPerson p) => MuLineupPlayer(
      p.name,
      level: _levels[p.name],
      role: p.name == g.organiser ? MuLineupRole.organizer : null,
      you: p.name == Story.myName,
    );
    final List<List<MuLineupPlayer?>> sides;
    if (g.id == Story.g1.id) {
      sides = [
        [player(Story.hamza), player(Story.nour), null, player(Story.skander), player(Story.salma)],
        [player(Story.omar), player(Story.lina), player(Story.ines), player(Story.aziz), null],
      ];
      // GAM-02: Mariem and Rami took the last two places (in the story, not after a join).
      final storyLeft = Story.g1.spotsLeft + (_freed[g.id] ?? 0);
      if (storyLeft <= 0) {
        sides[0][2] = player(Story.mariem);
        sides[1][4] = player(Story.rami);
      } else if (storyLeft == 1) {
        sides[1][4] = player(Story.rami);
      }
    } else {
      sides = [List.filled(size, null), List.filled(size, null)];
      var i = 0;
      for (final p in g.players) {
        if (i >= size * 2) break;
        sides[i % 2][i ~/ 2] = player(p);
        i++;
      }
    }
    final freed = _freed[g.id] ?? 0;
    if (freed > 0) {
      // The freed places: the last filled, non-organiser positions.
      var toFree = freed;
      for (var t = 1; t >= 0 && toFree > 0; t--) {
        for (var s = size - 1; s >= 0 && toFree > 0; s--) {
          final p = sides[t][s];
          if (p != null && p.role == null && !p.you) {
            sides[t][s] = null;
            toFree--;
          }
        }
      }
    }
    final mine = _slot[g.id];
    if (_membership[g.id] == GameMembership.joined && mine != null) {
      sides[mine.$1][mine.$2] = MuLineupPlayer(
        Story.myName,
        level: Story.myLevels[g.sport] ?? _levels[Story.myName],
        you: true,
      );
    }
    return [for (var t = 0; t < 2; t++) MuLineupTeam(name: names[t], players: sides[t])];
  }

  @override
  Future<GameDetails> details(String id) async {
    await _wait();
    final base = _find(id);
    if (base == null) throw StateError('Partie introuvable : $id');
    final g = _current(base);
    final venue = Story.venues.firstWhere(
      (v) => v.id == g.venueId,
      orElse: () => Story.venues.first,
    );
    final full = g.isFull;
    final isG1 = id == Story.g1.id;
    const c = _levels;
    final organiserFirst = (g.organiser ?? 'L’organisateur').split(' ').first;
    final waitlistCount = full ? 2 : 0;
    final membership = _membership[id] ?? GameMembership.none;
    return GameDetails(
      game: g,
      venue: venue,
      teams: _teams(g),
      messageCount: isG1 ? 14 : 3,
      messages: [
        GameMessage(
          author: MuPerson(g.organiser ?? 'Organisateur'),
          time: Story.at(16, 17, 42),
          text: full
              ? 'On est au complet ! Chasubles fournies : Blancs contre Bleus.'
              : isG1
              ? 'Chasubles fournies : Blancs contre Bleus. Il nous manque un milieu !'
              : 'On se retrouve 10 min avant devant l’accueil.',
        ),
        GameMessage(
          author: isG1 ? Story.hamza : (g.players.isNotEmpty ? g.players.last : Story.omar),
          time: Story.at(16, 17, 55),
          text: isG1 ? 'Je serai dans les cages.' : 'Présent !',
        ),
      ],
      fitFactors: [
        MuFitFactor(
          icon: PhosphorIcons.gauge(),
          label: 'Niveau dans la fourchette',
          detail:
              'Toi ${formatLevel(Story.myLevels[g.sport] ?? c[Story.myName]!)}'
              '${g.levelLabel == null ? '' : ' · partie ${g.levelLabel}'}',
        ),
        if (full)
          MuFitFactor(
            icon: PhosphorIcons.calendarCheck(),
            label:
                'Dispo ${formatWeekday(g.start).replaceAll('.', '') == 'dim' ? 'dimanche' : formatDay(g.start)} soir',
            detail: 'D’après tes disponibilités',
          )
        else
          MuFitFactor(
            icon: PhosphorIcons.usersThree(),
            label: isG1 ? 'Milieu recherché' : 'Une place à ton poste',
            detail: 'Ton poste habituel',
          ),
        MuFitFactor(
          icon: PhosphorIcons.mapPin(),
          label: 'À ${formatLevel(g.distanceKm ?? 0)} km',
          detail: '${g.venue} · ${g.place}',
        ),
      ],
      fitNote: full
          ? 'Recommandé car ton niveau et tes soirées libres collent. L’IA peut se tromper.'
          : 'Recommandé car $organiserFirst cherche un milieu près de chez toi. L’IA peut se tromper.',
      membership: membership,
      waitlistCount: waitlistCount,
      waitlistPosition: membership == GameMembership.waitlisted ? _waitlistPosition[id] : null,
      joinedTeam: _slot[id]?.$1,
      joinedSlot: _slot[id]?.$2,
    );
  }

  @override
  Future<void> join(String id, {required int team, required int slot}) async {
    _membership[id] = GameMembership.joined;
    _slot[id] = (team, slot);
    _waitlistPosition.remove(id);
  }

  @override
  Future<void> leave(String id) async {
    _membership.remove(id);
    _slot.remove(id);
  }

  @override
  Future<void> joinWaitlist(String id) async {
    _membership[id] = GameMembership.waitlisted;
    _waitlistPosition[id] = 3;
  }

  @override
  Future<void> leaveWaitlist(String id) async {
    _membership.remove(id);
    _waitlistPosition.remove(id);
  }

  @override
  Future<void> freeSpot(String id) async {
    _freed[id] = (_freed[id] ?? 0) + 1;
  }
}

final gamesRepositoryProvider = Provider<GamesRepository>(
  (ref) => FakeGamesRepository(offline: () => ref.read(simulatedOfflineProvider)),
);

/// The game page's data; invalidate after joining, leaving or the waitlist.
final gameDetailsProvider = FutureProvider.family<GameDetails, String>(
  (ref, id) => ref.watch(gamesRepositoryProvider).details(id),
);
