import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/data/story_data.dart';

/// A player the search finds.
@immutable
class PlayerHit {
  const PlayerHit({required this.name, required this.level, required this.place});

  final String name;
  final double level;
  final String place;
}

/// A district the search finds, with the venues in it (null: all around the player's zone).
@immutable
class ZoneHit {
  const ZoneHit({required this.name, this.venueIds});

  final String name;
  final List<String>? venueIds;
}

/// What EXP-05 searches besides games and venues: districts and players.
abstract interface class SearchRepository {
  Future<List<ZoneHit>> zones();
  Future<List<PlayerHit>> players();
}

/// The story's districts and players.
class FakeSearchRepository implements SearchRepository {
  const FakeSearchRepository();

  @override
  Future<List<ZoneHit>> zones() async => [
    for (final (name, ids) in Story.zones) ZoneHit(name: name, venueIds: ids),
  ];

  @override
  Future<List<PlayerHit>> players() async => [
    for (final p in Story.players) PlayerHit(name: p.name, level: p.level, place: p.place),
  ];
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) => const FakeSearchRepository());

final searchZonesProvider = FutureProvider<List<ZoneHit>>(
  (ref) => ref.watch(searchRepositoryProvider).zones(),
);

final searchPlayersProvider = FutureProvider<List<PlayerHit>>(
  (ref) => ref.watch(searchRepositoryProvider).players(),
);

/// The player's recent searches, newest first (kept on the device; removable one by one).
class RecentSearches extends Notifier<List<String>> {
  // SearchField.md keeps a short personal history.
  static const int _max = 8;

  @override
  List<String> build() => Story.recentSearches;

  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    state = [q, ...state.where((r) => r.toLowerCase() != q.toLowerCase())].take(_max).toList();
  }

  void remove(String query) => state = [...state]..remove(query);

  void clear() => state = const [];
}

final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(RecentSearches.new);
