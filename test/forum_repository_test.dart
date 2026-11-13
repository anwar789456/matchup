import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/forum/data/forum_ai.dart';
import 'package:matchup/features/forum/data/forum_identity.dart';
import 'package:matchup/features/forum/data/forum_repository.dart';
import 'package:matchup/features/forum/data/forum_seed.dart';
import 'package:matchup/features/forum/data/sqlite_forum_repository.dart';
import 'package:matchup/theme/theme.dart';

/// The forum on the phone's database (schema v5), shaped for the Supabase sync: UUID ids, an
/// `auteur_id` on every shared row, one row per vote / reaction / report, counts computed from
/// the rows, and no phone ever writing another member's post.
void main() {
  late AppDatabase db;
  late SqliteForumRepository me; // Yassine, the demo player

  SqliteForumRepository as(String id) => SqliteForumRepository(db, now: () => storyNow, meId: () => id);
  final uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  setUp(() {
    db = AppDatabase();
    me = as(ForumSeed.me);
  });
  tearDown(() => db.close());

  Future<Map<String, Object?>> rawPost(String id) async =>
      (await (await db.db).query('forum_sujets', where: 'id = ?', whereArgs: [id])).single;

  group('identity and ids', () {
    test('UUID v4, unique', () {
      final ids = {for (var i = 0; i < 1000; i++) newForumId()};
      expect(ids, hasLength(1000));
      expect(ids.every(uuid.hasMatch), isTrue);
    });

    test('without Supabase the member is the demo player', () {
      expect(forumUserId(), ForumSeed.me);
    });

    test('a new Supabase user gets their own member row and writes under their id', () async {
      const supa = '6f1c2b8e-1d2a-4c3b-9e8f-0a1b2c3d4e5f';
      final user = as(supa);
      expect((await user.me()).name, 'Yassine B.');
      final post = await user.publish(const PostDraft(title: 'Qui joue au padel au Lac ce soir ?', body: 'Il nous manque un 4e.'));
      expect(uuid.hasMatch(post.id), isTrue);
      expect((await rawPost(post.id))['auteur_id'], supa);
      expect(post.mine.author, isTrue);
      final reply = await me.reply(post.id, 'Je suis chaud !');
      expect(uuid.hasMatch(reply.id), isTrue);
      final rows = await (await db.db).query('forum_messages', where: 'id = ?', whereArgs: [reply.id]);
      expect(rows.single['auteur_id'], ForumSeed.me);
    });
  });

  group('FRM-01 feed', () {
    test('« Tendance »: pinned first, moderated spam left out, mention and saved state', () async {
      final feed = await me.feed(const ForumQuery(sort: ForumSort.trending));
      expect(feed.posts.first.title, startsWith('Padel Masters'));
      expect(feed.posts.first.mine.saved, isTrue);
      expect(feed.posts.any((p) => p.title.startsWith('Vends')), isFalse);
      expect(feed.total, 10);
      final bandeja = feed.posts.firstWhere((p) => p.title.startsWith('Bandeja :'));
      expect(bandeja.mentionsMe, isTrue);
      expect(bandeja.mine.vote, 1);
      expect(bandeja.score, 16);
      expect(bandeja.excerpt, isNot(contains('**')));
    });

    test('by default the newest post comes first, pinned or not', () async {
      final feed = await me.feed(const ForumQuery());
      final dates = [for (final p in feed.posts) p.createdAt];
      expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
      expect(feed.posts.first.title, startsWith('Bandeja :'));
    });

    test('filters, sorts and pages', () async {
      final padel = await me.feed(const ForumQuery(sport: MuSport.padel));
      expect(padel.posts.every((p) => p.sport == MuSport.padel), isTrue);
      final top = await me.feed(const ForumQuery(sort: ForumSort.top));
      final scores = top.posts.skip(1).map((p) => p.score).toList();
      expect(scores, [...scores]..sort((a, b) => b.compareTo(a)));
      expect((await me.feed(const ForumQuery(search: 'synth'))).total, 2);
      expect((await me.feed(const ForumQuery(tag: '#lac2'))).total, 2);
      expect((await me.feed(const ForumQuery(savedOnly: true))).total, 1);
      expect((await me.feed(ForumQuery(authorId: ForumSeed.id(4)))).total, 3);
      final page = await me.feed(const ForumQuery(), limit: 2, offset: 2);
      expect(page.posts, hasLength(2));
    });

    test('« nouveaux depuis ta dernière visite »', () async {
      final before = await me.categories();
      expect(before.firstWhere((c) => c.category == ForumCategory.technique).fresh, 1);
      await me.markVisited();
      expect((await me.categories()).every((c) => c.fresh == 0), isTrue);
    });
  });

  group('FRM-04 thread', () {
    test('counts come from the rows; best answer, 2 levels, masked reply for its author only', () async {
      final t = await me.thread(ForumSeed.postId('crampons'));
      expect(t.post.score, 19);
      expect(t.post.useful, 12);
      expect(t.post.thanks, 4);
      expect(t.post.replies, 8);
      expect(t.bestAnswer?.id, ForumSeed.replyId('tf'));
      expect(t.bestAnswer?.score, 24);
      final hamza = t.replies.firstWhere((r) => r.id == ForumSeed.replyId('ag'));
      expect(hamza.children.map((c) => c.id), [ForumSeed.replyId('ou'), ForumSeed.replyId('marseille')]);
      expect(hamza.children.last.answering?.name, 'Skander T.');
      final omar = t.replies.firstWhere((r) => r.id == ForumSeed.replyId('visses'));
      expect(omar.children.single.hidden, isTrue);
      expect(omar.children.single.body, isNotNull);

      final ines = await as(ForumSeed.id(2)).thread(ForumSeed.postId('crampons'));
      expect(ines.replies.firstWhere((r) => r.id == ForumSeed.replyId('visses')).children.single.body, isNull);
    });

    test('a vote is the voter’s own row; the post row never changes', () async {
      final postId = ForumSeed.postId('crampons');
      final before = await rawPost(postId);
      final ines = as(ForumSeed.id(2));
      expect(await ines.vote(ForumTarget.post, postId, 1), 20);
      expect(await ines.vote(ForumTarget.post, postId, -1), 18);
      expect(await ines.vote(ForumTarget.post, postId, 0), 19);
      await ines.vote(ForumTarget.post, postId, 1);
      final votes = await (await db.db).query('forum_votes', where: 'auteur_id = ? AND cible_id = ?', whereArgs: [ForumSeed.id(2), postId]);
      expect(votes, hasLength(1));
      expect(uuid.hasMatch(votes.single['id']! as String), isTrue);
      await ines.react(ForumTarget.post, postId, ForumReaction.thanks, on: true);
      expect((await ines.thread(postId)).post.thanks, 5);
      expect(await rawPost(postId), before);
      expect(() => me.vote(ForumTarget.reply, ForumSeed.replyId('tf'), 1), throwsA(isA<ForumRuleException>()));
    });

    test('a hurtful reply: refused, then the author’s own row published masked', () async {
      const text = 'T’as jamais mis les pieds sur un synthétique, franchement t’es nul.';
      final hamza = as(ForumSeed.id(6));
      await expectLater(hamza.reply(ForumSeed.postId('crampons'), text), throwsA(isA<ForumAlertException>()));
      final r = await hamza.reply(ForumSeed.postId('crampons'), text, confirmed: true);
      expect(r.hidden, isTrue);
      expect((await hamza.thread(ForumSeed.postId('crampons'))).post.replies, 8);
    });

    test('answering a level-2 reply attaches to its level-1 parent', () async {
      final r = await me.reply(ForumSeed.postId('crampons'), 'Merci pour l’adresse !', parentId: ForumSeed.replyId('marseille'));
      expect(r.parentId, ForumSeed.replyId('ag'));
      expect(r.answering?.name, 'Hamza R.');
    });

    test('reports: one row per reporter, never hiding the content', () async {
      final target = ForumSeed.replyId('bonsplans');
      await me.report(ForumTarget.reply, target, ReportReason.spam, muteAuthor: true);
      await me.report(ForumTarget.reply, target, ReportReason.other, details: 'Pub');
      await as(ForumSeed.id(6)).report(ForumTarget.reply, target, ReportReason.spam);
      await as(ForumSeed.id(7)).report(ForumTarget.reply, target, ReportReason.spam);
      final rows = await (await db.db).query('forum_signalements', where: 'cible_id = ?', whereArgs: [target]);
      expect(rows, hasLength(4)); // Mariem (story), Yassine, Hamza, Aziz
      expect(rows.where((r) => r['auteur_id'] == ForumSeed.me).single['motif'], 'autre');
      final ines = await as(ForumSeed.id(2)).thread(ForumSeed.postId('crampons'));
      expect(ines.replies.firstWhere((r) => r.id == target).hidden, isFalse);
      // Yassine muted the author: gone from his thread, still there for others.
      expect((await me.thread(ForumSeed.postId('crampons'))).replies.any((r) => r.id == target), isFalse);
      await me.undoReport(ForumTarget.reply, target);
      expect(
        await (await db.db).query('forum_signalements', where: 'cible_id = ? AND auteur_id = ?', whereArgs: [target, ForumSeed.me]),
        isEmpty,
      );
    });

    test('best answer: only the post’s author, a level-1 reply by someone else', () async {
      final postId = ForumSeed.postId('crampons');
      expect(() => me.chooseBestAnswer(postId, ForumSeed.replyId('pluie')), throwsA(isA<ForumRuleException>()));
      final skander = as(ForumSeed.id(3));
      await skander.chooseBestAnswer(postId, ForumSeed.replyId('pluie'));
      expect((await skander.thread(postId)).bestAnswer?.id, ForumSeed.replyId('pluie'));
      expect(() => skander.chooseBestAnswer(postId, ForumSeed.replyId('marseille')), throwsA(isA<ForumRuleException>()));
    });

    test('a deleted reply with answers stays as a placeholder', () async {
      final hamza = as(ForumSeed.id(6));
      await hamza.deleteReply(ForumSeed.replyId('ag'));
      final after = (await hamza.thread(ForumSeed.postId('crampons'))).replies.firstWhere((r) => r.id == ForumSeed.replyId('ag'));
      expect(after.deleted, isTrue);
      expect(after.body, isNull);
      expect(after.children, isNotEmpty);
      expect(() => me.deleteReply(ForumSeed.replyId('pluie')), throwsA(isA<ForumRuleException>()));
    });
  });

  group('FRM-02', () {
    test('publish, similar discussions, AI tags, draft', () async {
      final similar = await me.similar('Bandeja croisée : vous visez où sur la vitre ?', sport: MuSport.padel);
      expect(similar.first.post.title, startsWith('Bandeja :'));
      final tags = await me.suggestTags('Bandeja croisée : vous visez où sur la vitre ?', 'Je suis à 3,5, côté gauche.', const [
        'Padel',
        'Bandeja',
      ]);
      expect(tags.map((t) => t.tag), containsAll(['Vitre', 'Côté gauche']));

      await me.saveDraft(const PostDraft(title: 'Brouillon'));
      expect((await me.loadDraft())?.title, 'Brouillon');
      await me.clearDraft();
      expect(await me.loadDraft(), isNull);

      final post = await me.publish(
        const PostDraft(
          category: ForumCategory.technique,
          sport: MuSport.padel,
          title: 'Bandeja croisée : vous visez où sur la vitre ?',
          body: 'Je travaille la **bandeja** avec @karim.j',
          tags: ['#Padel', 'padel', 'Bandeja'],
        ),
      );
      expect(post.tags, ['Padel', 'Bandeja']);
      expect(post.mine.following, isTrue);
      expect(() => me.publish(const PostDraft(title: 'court', body: 'x')), throwsA(isA<ForumRuleException>()));
    });

    test('a suspended member cannot write', () async {
      await (await db.db).insert('forum_sanctions', {
        'id': newForumId(),
        'utilisateur_id': ForumSeed.me,
        'type': 'suspension',
        'motif': 'Propos insultants',
        'jusqua': storyNow.add(const Duration(days: 7)).toIso8601String(),
        'cree_le': storyNow.toIso8601String(),
      });
      expect(await me.suspendedUntil(), isNotNull);
      expect(() => me.reply(ForumSeed.postId('crampons'), 'Bonjour'), throwsA(isA<ForumSuspendedException>()));
    });
  });

  test('ForumAi scores the screens’ examples', () {
    final insult = ForumAi.analyze(
      'T’as jamais mis les pieds sur un synthétique, franchement t’es nul. Arrête de raconter n’importe quoi.',
    );
    expect(insult.score, 0.62);
    expect(ForumAi.analyze('Vends crampons pas cher, livraison partout, lien en bio').level, RiskLevel.high);
    expect(ForumAi.analyze('Je vends mes crampons taille 42, peu portés.').alert, isFalse);
    expect(
      ForumAi.rewrite('T’es nul, prends des AG, ils accrochent moins sur synthétique.'),
      'Prends des AG, ils accrochent moins sur synthétique.',
    );
    expect(ForumAi.mentions('@yassine.b tu bosses ? cc @Karim_J.'), ['yassine.b', 'karim_j']);
  });
}
