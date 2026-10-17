import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/data/story_data.dart';

/// Someone the player could invite.
@immutable
class Teammate {
  const Teammate({
    required this.name,
    required this.level,
    required this.position,
    required this.gamesTogether,
  });

  final String name;
  final double level;

  /// « Attaquant », « Gardien ».
  final String position;
  final int gamesTogether;

  /// « Attaquant · 6 matchs ensemble », « Milieu · joue à La Marsa ».
  String meta(String zone) => gamesTogether > 0
      ? '$position · $gamesTogether ${gamesTogether == 1 ? 'match' : 'matchs'} ensemble'
      : '$position · joue à $zone';

  /// Invited by default: played together twice or more.
  bool get regular => gamesTogether >= 2;
}

abstract interface class TeammatesRepository {
  /// Who played with the player at [venueId] or near their zone, most games together first.
  Future<List<Teammate>> suggested(String venueId);
}

class FakeTeammatesRepository implements TeammatesRepository {
  const FakeTeammatesRepository();

  @override
  Future<List<Teammate>> suggested(String venueId) async => [
    for (final t in Story.teammates)
      Teammate(name: t.name, level: t.level, position: t.position, gamesTogether: t.together),
  ];
}

final teammatesRepositoryProvider = Provider<TeammatesRepository>(
  (ref) => const FakeTeammatesRepository(),
);
