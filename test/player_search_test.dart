import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/forum/data/forum_repository.dart';
import 'package:matchup/features/forum/data/forum_seed.dart';
import 'package:matchup/features/forum/data/search_seed.dart';
import 'package:matchup/features/forum/data/sqlite_forum_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/router.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';

/// « Cherche joueurs »: players in order, the waiting list moving up by itself, the organiser
/// closing, the filter, and the screens (card « Je viens », FRM-04, FRM-02).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('repository', () {
    late AppDatabase db;
    late SqliteForumRepository me;
    SqliteForumRepository as(String id) => SqliteForumRepository(db, now: () => storyNow, meId: () => id);
    final sunday = SearchSeed.postId('dimanche');
    final padel = SearchSeed.postId('padel');

    setUp(() {
      db = AppDatabase();
      me = as(ForumSeed.me);
    });
    tearDown(() => db.close());

    Future<PlayerSearch> search(String id, [SqliteForumRepository? who]) async => (await (who ?? me).thread(id)).post.search!;

    test('the story: Skander needs 3 and has Rami; Mariem is full with Nour waiting', () async {
      final s = await search(sunday);
      expect(s.needed, 3);
      expect([for (final p in s.players) p.name], ['Rami S.']);
      expect(s.left, 2);
      expect(s.fits(3.0), isTrue);
      final p = await search(padel);
      expect(p.full, isTrue);
      expect([for (final w in p.waiting) w.name], ['Nour A.']);
    });

    test('joining: playing while there is room, then the waiting list; leaving moves the next one up', () async {
      expect(await me.join(sunday), SearchStatus.playing);
      expect(await as(ForumSeed.id(6)).join(sunday), SearchStatus.playing);
      expect((await search(sunday)).full, isTrue);
      final omar = as(ForumSeed.id(8));
      expect(await omar.join(sunday), SearchStatus.waiting);
      expect((await search(sunday, omar)).waitingRank, 1);
      // Yassine drops out: Omar plays, without anyone writing Omar's row.
      await me.leave(sunday);
      final after = await search(sunday, omar);
      expect(after.status, SearchStatus.playing);
      expect(after.waiting, isEmpty);
      expect((await search(sunday)).status, SearchStatus.out);
    });

    test('joining twice keeps one row and one place', () async {
      await me.join(sunday);
      await me.join(sunday);
      expect((await search(sunday)).players, hasLength(2));
    });

    test('the organiser cannot join, closes and reopens; nobody joins a closed or past game', () async {
      final skander = as(ForumSeed.id(3));
      await expectLater(() => skander.join(sunday), throwsA(isA<ForumRuleException>()));
      await expectLater(() => me.closeSearch(sunday, closed: true), throwsA(isA<ForumRuleException>()));
      await skander.closeSearch(sunday, closed: true);
      expect((await search(sunday)).closed, isTrue);
      await expectLater(() => me.join(sunday), throwsA(isA<ForumRuleException>()));
      await skander.closeSearch(sunday, closed: false);
      expect(await me.join(sunday), SearchStatus.playing);
      final later = SqliteForumRepository(db, now: () => DateTime(2026, 10, 19), meId: () => ForumSeed.id(8));
      await expectLater(() => later.join(sunday), throwsA(isA<ForumRuleException>()));
    });

    test('« Cherche joueurs » filter: open ones only, the soonest game first', () async {
      final feed = await me.feed(const ForumQuery(lookingOnly: true));
      expect([for (final p in feed.posts) p.id], [padel, SearchSeed.postId('basket'), sunday]);
      await as(ForumSeed.id(4)).closeSearch(padel, closed: true);
      expect((await me.feed(const ForumQuery(lookingOnly: true))).total, 2);
    });

    test('publishing a search: checked, the post takes its sport, editing keeps it', () async {
      final at = storyNow.add(const Duration(days: 2));
      final draft = PostDraft(
        category: ForumCategory.venues,
        title: 'On cherche 4 joueurs pour un 5v5 mardi',
        body: 'Terrain réservé, il manque du monde.',
        search: PlayerSearch(sport: MuSport.football, place: '', at: at, needed: 4),
      );
      await expectLater(() => me.publish(draft), throwsA(isA<ForumRuleException>()));
      final past = draft.copyWith(search: () => PlayerSearch(sport: MuSport.football, place: 'Arena Five', at: storyNow, needed: 4));
      await expectLater(() => me.publish(past), throwsA(isA<ForumRuleException>()));
      final ok = draft.copyWith(
        search: () => PlayerSearch(sport: MuSport.football, place: 'Arena Five', at: at, needed: 4, levelMin: 2.5, levelMax: 4, price: 12),
      );
      final post = await me.publish(ok);
      expect(post.sport, MuSport.football);
      expect(post.search!.needed, 4);
      expect(post.search!.price, 12);
      final edited = await me.editPost(post.id, ok.copyWith(search: () => PlayerSearch(sport: MuSport.football, place: 'Arena Five', at: at, needed: 2)));
      expect(edited.search!.needed, 2);
      expect(edited.search!.levelMin, isNull);
    });
  });

  group('screens', () {
    Future<void> pumpApp(WidgetTester tester, String at) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => storyNow),
          onboardingStoreProvider.overrideWithValue(
            MemoryOnboardingStore(const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.')),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(routerProvider).go(at);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MatchUpApp()));
      await tester.pumpAndSettle();
    }

    Future<void> tap(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    const title = 'Il manque 3 joueurs dimanche 20h à Arena Five';

    testWidgets('the card: « Cherche 2 joueurs », the places, « Je viens » right from the feed', (tester) async {
      await pumpApp(tester, Routes.community);
      await tap(tester, find.text('Cherche joueurs'));
      await tester.scrollUntilVisible(find.text(title), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      final card = find.ancestor(of: find.text(title), matching: find.byType(MuForumPostCard));
      expect(find.descendant(of: card, matching: find.text('Cherche 2 joueurs')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('Ton niveau 3,0 correspond')), findsOneWidget);
      await tester.tap(find.descendant(of: card, matching: find.text('Je viens')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Tu es dans l’équipe !'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.descendant(of: card, matching: find.text('Cherche 1 joueur')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('Tu joues · Je ne viens plus')), findsOneWidget);
    });

    testWidgets('FRM-04: the players, a free place, the waiting list; leaving asks first', (tester) async {
      await pumpApp(tester, Routes.forumPost(SearchSeed.postId('padel')));
      expect(find.text('Complet'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Nour A.'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Organisateur'), findsOneWidget);
      expect(find.text('Lina F.'), findsOneWidget);
      expect(find.text('1er'), findsOneWidget);
      await tap(tester, find.widgetWithText(MuButton, 'Liste d’attente'));
      // Joined a full game: 2nd on the waiting list.
      expect(find.text('En attente · 2e'), findsOneWidget);
      await tap(tester, find.text('En attente · 2e'));
      expect(find.text('Tu ne viens plus ?'), findsOneWidget);
      await tap(tester, find.widgetWithText(MuButton, 'Je ne viens plus'));
      expect(find.text('Liste d’attente'), findsWidgets);
    });

    testWidgets('FRM-02: « Je cherche des joueurs » with the place, the day, the players', (tester) async {
      await pumpApp(tester, Routes.forumNew);
      expect(find.text('Je cherche des joueurs'), findsOneWidget);
      await tap(tester, find.text('Je cherche des joueurs'));
      expect(find.text('Lieu'), findsOneWidget);
      expect(find.text('Demain'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Joueurs recherchés'), 200, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
      expect(find.text('Joueurs recherchés'), findsOneWidget);
    });
  });
}
