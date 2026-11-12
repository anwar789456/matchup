import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/sync/sync_service.dart';
import 'package:matchup/features/forum/data/forum_repository.dart';
import 'package:matchup/features/forum/data/sqlite_forum_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Supabase in memory, enforcing the shared-table rules: everyone reads, a row is written only
/// by its owner, and its `auteur_id` must be that owner.
class _Supabase implements SyncRemote {
  _Supabase(this.userId, this.tables);

  @override
  String? userId;
  final Map<String, Map<String, Map<String, Object?>>> tables;

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows, List<String> keys) async {
    for (final r in rows) {
      if (r['owner_id'] != userId) throw Exception('RLS: owner_id');
      if (r.containsKey('auteur_id') && r['auteur_id'] != userId) throw Exception('RLS: auteur_id');
      (tables[table] ??= {})[[r['owner_id'], for (final k in keys) '${r[k]}'].join('|')] = {...r};
    }
  }

  @override
  Future<void> delete(String table, Map<String, Object?> key) async {
    tables[table]?.removeWhere((_, r) => r['owner_id'] == userId && key.entries.every((e) => '${r[e.key]}' == '${e.value}'));
  }

  @override
  Future<List<Map<String, Object?>>> fetchAll(String table, {bool everyone = false}) async => [
    for (final r in (tables[table] ?? {}).values)
      if (everyone || r['owner_id'] == userId) {...r},
  ];
}

void main() {
  sqfliteFfiInit();

  test('a post, a vote and a reply travel between two members’ phones', () async {
    final dir = await Directory.systemTemp.createTemp('matchup_forum_sync');
    addTearDown(() => dir.delete(recursive: true));
    final cloud = <String, Map<String, Map<String, Object?>>>{};
    const a = '11111111-1111-4111-8111-111111111111';
    const b = '22222222-2222-4222-8222-222222222222';

    AppDatabase phone(String name) => AppDatabase(factory: databaseFactoryFfi, path: '${dir.path}/$name.db');
    final phoneA = phone('a');
    final phoneB = phone('b');
    addTearDown(phoneA.close);
    addTearDown(phoneB.close);
    final forumA = SqliteForumRepository(phoneA, now: () => storyNow, meId: () => a);
    final forumB = SqliteForumRepository(phoneB, now: () => storyNow, meId: () => b);
    final syncA = SyncService(phoneA, _Supabase(a, cloud));
    final syncB = SyncService(phoneB, _Supabase(b, cloud));

    // A publishes.
    final post = await forumA.publish(
      const PostDraft(
        category: ForumCategory.technique,
        title: 'Qui joue au padel au Lac ce soir ?',
        body: 'Il nous manque un 4e, niveau 3,5.',
      ),
    );
    expect((await syncA.sync()).errors, isEmpty);
    expect(cloud['forum_sujets']!.values.single['auteur_id'], a);
    expect(cloud['forum_membres']!.values.single['id'], a);

    // B gets it at the next sync, with A's profile, then votes and replies.
    expect((await syncB.sync()).errors, isEmpty);
    final seen = await forumB.thread(post.id);
    expect(seen.post.title, 'Qui joue au padel au Lac ce soir ?');
    expect(seen.post.author.id, a);
    await forumB.vote(ForumTarget.post, post.id, 1);
    await forumB.react(ForumTarget.post, post.id, ForumReaction.useful, on: true);
    final reply = await forumB.reply(post.id, 'Je suis chaud, 20h ?');
    expect((await syncB.sync()).errors, isEmpty);

    // The vote and the reply are B's own rows: A's post row on Supabase is untouched.
    final postRowsBefore = Map.of(cloud['forum_sujets']!.values.single);
    expect(cloud['forum_votes']!.values.single['auteur_id'], b);

    // A sees the count, the « Utile » and the reply.
    expect((await syncA.sync()).errors, isEmpty);
    final t = await forumA.thread(post.id);
    expect(t.post.score, 1);
    expect(t.post.useful, 1);
    expect(t.post.replies, 1);
    expect(t.replies.single.id, reply.id);
    expect(t.replies.single.author.id, b);
    expect(cloud['forum_sujets']!.values.single, postRowsBefore);

    // A chooses B's reply as the best answer: A writes only A's post.
    await forumA.chooseBestAnswer(post.id, reply.id);
    expect((await syncA.sync()).errors, isEmpty);
    await syncB.sync();
    expect((await forumB.thread(post.id)).bestAnswer?.id, reply.id);
  });
}
