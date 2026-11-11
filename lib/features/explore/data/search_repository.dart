import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../common/data/story_data.dart';
import 'sqlite_catalog_repositories.dart';

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

/// Districts and players live in the phone's database. Tests override it with the fake.
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SqliteSearchRepository(ref.watch(appDatabaseProvider)),
);

final searchZonesProvider = FutureProvider<List<ZoneHit>>(
  (ref) => ref.watch(searchRepositoryProvider).zones(),
);

final searchPlayersProvider = FutureProvider<List<PlayerHit>>(
  (ref) => ref.watch(searchRepositoryProvider).players(),
);

/// The player's recent searches, newest first (table `recherches_recentes`; removable one by
/// one).
class RecentSearches extends Notifier<List<String>> {
  // SearchField.md keeps a short personal history.
  static const int _max = 8;

  AppDatabase get _database => ref.read(appDatabaseProvider);

  @override
  List<String> build() {
    _load();
    return Story.recentSearches;
  }

  Future<void> _load() async {
    try {
      final rows = await (await _database.db)
          .query('recherches_recentes', orderBy: 'faite_le DESC', limit: _max);
      state = [for (final r in rows) r['requete']! as String];
    } catch (_) {
      // No database: keep the story's searches.
    }
  }

  Future<void> _write(Future<void> Function(Database db) change) async {
    try {
      await change(await _database.db);
    } catch (_) {
      // The list still changes for this session.
    }
  }

  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final dropped = state.where((r) => r.toLowerCase() == q.toLowerCase()).toList();
    state = [q, ...state.where((r) => r.toLowerCase() != q.toLowerCase())].take(_max).toList();
    _write((db) async {
      for (final r in dropped) {
        await db.delete('recherches_recentes', where: 'requete = ?', whereArgs: [r]);
      }
      await db.insert('recherches_recentes',
          {'requete': q, 'faite_le': DateTime.now().toIso8601String()},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  void remove(String query) {
    state = [...state]..remove(query);
    _write((db) => db.delete('recherches_recentes', where: 'requete = ?', whereArgs: [query]));
  }

  void clear() {
    state = const [];
    _write((db) => db.delete('recherches_recentes'));
  }

  /// The story's searches, oldest first so the first one is the newest.
  static Future<void> seed(DatabaseExecutor db) async {
    final start = DateTime(2026, 10, 16, 17);
    for (final (i, q) in Story.recentSearches.reversed.indexed) {
      await db.insert('recherches_recentes',
          {'requete': q, 'faite_le': start.add(Duration(minutes: i)).toIso8601String()});
    }
  }
}

final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(RecentSearches.new);
