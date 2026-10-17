import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';

/// Open games (« Parties »): Explorer's list and the Home's « Parties pour toi ».
abstract interface class GamesRepository {
  /// Open games near the player's zone, recommended first.
  Future<List<MuGame>> openGames();

  /// « Parties pour toi »: the AI's best matches, best first.
  Future<List<MuGame>> recommended();

  /// Lists a public game the player organises, so players at their level can join it.
  Future<void> publish(MuGame game);
}

/// The story's games (design/screens/STORY-DATA.md).
class FakeGamesRepository implements GamesRepository {
  FakeGamesRepository({this.latency = const Duration(milliseconds: 700), bool Function()? offline})
    : _offline = offline ?? (() => false);

  final Duration latency;
  final bool Function() _offline;
  final _published = <MuGame>[];

  Future<void> _wait() async {
    await Future<void>.delayed(latency);
    if (_offline()) throw const OfflineException();
  }

  @override
  Future<List<MuGame>> openGames() async {
    await _wait();
    return [...Story.openGames, ..._published];
  }

  @override
  Future<void> publish(MuGame game) async => _published.add(game);

  @override
  Future<List<MuGame>> recommended() async {
    await _wait();
    return [Story.g1, Story.g2];
  }
}

final gamesRepositoryProvider = Provider<GamesRepository>(
  (ref) => FakeGamesRepository(offline: () => ref.read(simulatedOfflineProvider)),
);
