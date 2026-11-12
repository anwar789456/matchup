import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/forum/data/forum_ai.dart';
import 'package:matchup/features/forum/data/forum_repository.dart';
import 'package:matchup/features/forum/data/sqlite_forum_repository.dart';
import 'package:matchup/theme/theme.dart';

/// The forum's rules on the phone's database (schema v3, seeded with the story), the same as the
/// backend's forum module.
void main() {
  late AppDatabase db;
  late SqliteForumRepository me; // Yassine (1)

  SqliteForumRepository as(int id) => SqliteForumRepository(db, now: () => storyNow, meId: id);

  setUp(() {
    db = AppDatabase();
    me = as(1);
  });
  tearDown(() => db.close());

  Future<ForumPost> postTitled(String start) async =>
      (await me.feed(const ForumQuery(), limit: 50)).posts.firstWhere((p) => p.title.startsWith(start));

  group('FRM-01 feed', () {
    test('pinned first, hidden spam left out, mention and saved state', () async {
      final feed = await me.feed(const ForumQuery());
      expect(feed.posts.first.title, startsWith('Padel Masters'));
      expect(feed.posts.first.mine.saved, isTrue);
      expect(feed.posts.any((p) => p.title.startsWith('Vends')), isFalse);
      expect(feed.total, 7);
      final bandeja = feed.posts.firstWhere((p) => p.title.startsWith('Bandeja :'));
      expect(bandeja.mentionsMe, isTrue);
      expect(bandeja.mine.vote, 1);
      expect(bandeja.excerpt, isNot(contains('**')));
      expect(bandeja.body, isNull);
    });

    test('filters, sorts and pages', () async {
      final padel = await me.feed(const ForumQuery(sport: MuSport.padel));
      expect(padel.posts.every((p) => p.sport == MuSport.padel), isTrue);
      final top = await me.feed(const ForumQuery(sort: ForumSort.top));
      final scores = top.posts.skip(1).map((p) => p.score).toList();
      expect(scores, [...scores]..sort((a, b) => b.compareTo(a)));
      final tech = await me.feed(const ForumQuery(category: ForumCategory.technique));
      expect(tech.posts.map((p) => p.category).toSet(), {ForumCategory.technique});
      expect((await me.feed(const ForumQuery(search: 'synth'))).total, 1);
      expect((await me.feed(const ForumQuery(tag: '#lac2'))).total, 2);
      expect((await me.feed(const ForumQuery(savedOnly: true))).total, 1);
      final page = await me.feed(const ForumQuery(), limit: 2, offset: 2);
      expect(page.posts, hasLength(2));
      expect(page.total, 7);
    });

    test('« nouveaux depuis ta dernière visite » count from the last visit', () async {
      final before = await me.categories();
      expect(before.firstWhere((c) => c.category == ForumCategory.technique).fresh, 1);
      expect(before.firstWhere((c) => c.category == ForumCategory.venues).fresh, 1);
      await me.markVisited();
      expect((await me.categories()).every((c) => c.fresh == 0), isTrue);
    });
  });

  group('FRM-04 thread', () {
    test('best answer apart, 2 levels, masked reply only for its author', () async {
      final crampons = await postTitled('Crampons');
      final t = await me.thread(crampons.id);
      expect(t.bestAnswer?.author.name, 'Yassine B.');
      expect(t.replies.any((r) => r.id == t.bestAnswer!.id), isFalse);
      final hamza = t.replies.firstWhere((r) => r.body?.startsWith('J’ai pris') ?? false);
      expect(hamza.children, hasLength(2));
      expect(hamza.children.first.byPostAuthor, isTrue);
      expect(hamza.children.last.answering?.name, 'Skander T.');
      final omar = t.replies.firstWhere((r) => r.author.name == 'Omar D.');
      expect(omar.children.single.hidden, isTrue);
      expect(omar.children.single.body, isNotNull);
      expect(t.post.replies, 8);

      final other = await as(2).thread(crampons.id);
      final omar2 = other.replies.firstWhere((r) => r.author.name == 'Omar D.');
      expect(omar2.children.single.body, isNull);
    });

    test('votes and reactions recount; no vote on your own reply', () async {
      final crampons = await postTitled('Crampons');
      final best = (await me.thread(crampons.id)).bestAnswer!;
      expect(() => me.vote(ForumTarget.reply, best.id, 1), throwsA(isA<ForumRuleException>()));
      final ines = as(2);
      expect(await ines.vote(ForumTarget.reply, best.id, 1), best.score + 1);
      expect(await ines.vote(ForumTarget.reply, best.id, 1), best.score + 1);
      expect(await ines.vote(ForumTarget.reply, best.id, -1), best.score - 1);
      expect(await ines.vote(ForumTarget.reply, best.id, 0), best.score);
      await ines.react(ForumTarget.post, crampons.id, ForumReaction.thanks, on: true);
      expect((await ines.thread(crampons.id)).post.thanks, crampons.thanks + 1);
    });

    test('a hurtful reply is refused, then published masked with « confirmed »', () async {
      final crampons = await postTitled('Crampons');
      const text = 'T’as jamais mis les pieds sur un synthétique, franchement t’es nul.';
      final hamza = as(6);
      await expectLater(hamza.reply(crampons.id, text), throwsA(isA<ForumAlertException>()));
      final r = await hamza.reply(crampons.id, text, confirmed: true);
      expect(r.hidden, isTrue);
      expect((await hamza.thread(crampons.id)).post.replies, 8);
    });

    test('answering a level-2 reply attaches to its level-1 parent', () async {
      final crampons = await postTitled('Crampons');
      final t = await me.thread(crampons.id);
      final level2 = t.replies.firstWhere((r) => r.children.length == 2).children.last;
      final r = await me.reply(crampons.id, 'Merci pour l’adresse !', parentId: level2.id);
      expect(r.parentId, level2.parentId);
      expect(r.answering?.name, level2.author.name);
    });

    test('3 reports from different people hide a reply; « Ne plus voir » blocks its author', () async {
      final crampons = await postTitled('Crampons');
      final spam = (await me.thread(crampons.id)).replies.firstWhere((r) => r.author.name == 'Bons Plans Sport TN');
      expect(await me.report(ForumTarget.reply, spam.id, ReportReason.spam, muteAuthor: true), isFalse);
      expect((await me.thread(crampons.id)).replies.any((r) => r.author.name == 'Bons Plans Sport TN'), isFalse);
      // Mariem (4) reported it in the story: Yassine was the 2nd, Hamza is the 3rd.
      expect(await as(6).report(ForumTarget.reply, spam.id, ReportReason.spam), isTrue);
      final seen = (await as(2).thread(crampons.id)).replies.firstWhere((r) => r.id == spam.id);
      expect(seen.hidden, isTrue);
    });

    test('best answer: only the author, a level-1 reply by someone else', () async {
      final crampons = await postTitled('Crampons');
      final t = await me.thread(crampons.id);
      final aziz = t.replies.firstWhere((r) => r.author.name == 'Aziz H.');
      expect(() => me.chooseBestAnswer(crampons.id, aziz.id), throwsA(isA<ForumRuleException>()));
      final skander = as(3);
      await skander.chooseBestAnswer(crampons.id, aziz.id);
      expect((await skander.thread(crampons.id)).bestAnswer?.id, aziz.id);
      final level2 = t.replies.firstWhere((r) => r.children.isNotEmpty).children.first;
      expect(() => skander.chooseBestAnswer(crampons.id, level2.id), throwsA(isA<ForumRuleException>()));
    });

    test('a deleted reply with answers stays as a placeholder', () async {
      final crampons = await postTitled('Crampons');
      final hamza = as(6);
      final t = await hamza.thread(crampons.id);
      final withAnswers = t.replies.firstWhere((r) => r.author.id == 6 && r.children.isNotEmpty);
      await hamza.deleteReply(withAnswers.id);
      final after = (await hamza.thread(crampons.id)).replies.firstWhere((r) => r.id == withAnswers.id);
      expect(after.deleted, isTrue);
      expect(after.body, isNull);
      expect(after.children, isNotEmpty);
    });
  });

  group('FRM-02', () {
    test('publish, similar discussions, AI tags, draft', () async {
      final similar = await me.similar('Bandeja croisée : vous visez où sur la vitre ?', sport: MuSport.padel);
      expect(similar.first.post.title, startsWith('Bandeja :'));
      final tags = await me.suggestTags('Bandeja croisée : vous visez où sur la vitre ?', 'Je suis à 3,5, côté gauche.', const ['Padel', 'Bandeja']);
      expect(tags.map((t) => t.tag), containsAll(['Vitre', 'Côté gauche']));

      await me.saveDraft(const PostDraft(title: 'Brouillon'));
      expect((await me.loadDraft())?.title, 'Brouillon');
      await me.clearDraft();
      expect(await me.loadDraft(), isNull);

      final post = await me.publish(const PostDraft(
        category: ForumCategory.technique,
        sport: MuSport.padel,
        title: 'Bandeja croisée : vous visez où sur la vitre ?',
        body: 'Je travaille la **bandeja** avec @karim.j',
        tags: ['#Padel', 'padel', 'Bandeja'],
      ));
      expect(post.tags, ['Padel', 'Bandeja']);
      expect(post.mine.author, isTrue);
      expect(post.mine.following, isTrue);
      expect(() => me.publish(const PostDraft(title: 'court', body: 'x')), throwsA(isA<ForumRuleException>()));
    });

    test('a suspended member cannot write', () async {
      final database = await db.db;
      await database.insert('forum_sanctions', {
        'utilisateur_id': 1,
        'type': 'suspension',
        'motif': 'Propos insultants',
        'jusqua': storyNow.add(const Duration(days: 7)).toIso8601String(),
        'cree_le': storyNow.toIso8601String(),
      });
      expect(await me.suspendedUntil(), isNotNull);
      final crampons = await postTitled('Crampons');
      expect(() => me.reply(crampons.id, 'Bonjour'), throwsA(isA<ForumSuspendedException>()));
    });
  });

  group('ForumAi', () {
    test('scores the screens’ examples', () {
      final insult = ForumAi.analyze('T’as jamais mis les pieds sur un synthétique, franchement t’es nul. Arrête de raconter n’importe quoi.');
      expect(insult.score, 0.62);
      expect(insult.alert, isTrue);
      final hit = insult.excerpts.single;
      expect('T’as jamais mis les pieds sur un synthétique, franchement t’es nul.'.substring(hit.start, hit.end), 't’es nul');
      expect(ForumAi.analyze('Vends crampons pas cher, livraison partout, lien en bio').level, RiskLevel.high);
      expect(ForumAi.analyze('Prends des stabilisés (TF) ou des moulés courts (AG).').alert, isFalse);
      expect(ForumAi.analyze('Je vends mes crampons taille 42, peu portés.').alert, isFalse);
      expect(ForumAi.rewrite('T’es nul, prends des AG, ils accrochent moins sur synthétique.'), 'Prends des AG, ils accrochent moins sur synthétique.');
      expect(ForumAi.mentions('@yassine.b tu bosses ? cc @Karim_J.'), ['yassine.b', 'karim_j']);
      expect(ForumAi.hashtag('Côté gauche'), '#côtégauche');
    });
  });
}
