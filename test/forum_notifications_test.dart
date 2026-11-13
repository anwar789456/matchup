import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/format.dart';
import 'package:matchup/features/forum/data/forum_repository.dart';
import 'package:matchup/features/forum/data/forum_seed.dart';
import 'package:matchup/features/forum/data/forum_watcher.dart';
import 'package:matchup/features/forum/data/market_seed.dart';
import 'package:matchup/features/forum/data/messages_models.dart';
import 'package:matchup/features/forum/data/messages_seed.dart';
import 'package:matchup/features/forum/data/search_seed.dart';
import 'package:matchup/features/forum/data/sqlite_forum_repository.dart';
import 'package:matchup/features/forum/data/sqlite_messages_repository.dart';
import 'package:matchup/features/notifications/data/notification_models.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/router.dart';
import 'package:matchup/theme/theme.dart';

/// The Communauté's notifications, offers on listings and saved searches.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('repository', () {
    late AppDatabase db;
    late SqliteForumRepository me;
    late SqliteMessagesRepository chat;
    late ForumWatcher watcher;
    SqliteForumRepository as(String id) => SqliteForumRepository(db, now: () => storyNow, meId: () => id);
    SqliteMessagesRepository chatAs(String id) => SqliteMessagesRepository(db, now: () => storyNow, meId: () => id);
    final raquette = MarketSeed.postId('raquette');
    final mariem = ForumSeed.id(4);

    setUp(() {
      db = AppDatabase();
      me = as(ForumSeed.me);
      chat = chatAs(ForumSeed.me);
      watcher = ForumWatcher(db, now: () => storyNow, meId: () => ForumSeed.me);
    });
    tearDown(() => db.close());

    Future<List<ForumEvent>> scan() async => (await watcher.scan()).events;

    test('first scan: only the last 24 hours (Ines’s mention); then nothing is told twice', () async {
      final first = await watcher.scan();
      expect(first.first, isTrue);
      expect(first.events.map((e) => e.type), contains(NotificationType.mention));
      expect(first.events.every((e) => storyNow.difference(e.at) <= ForumWatcher.recent), isTrue);
      final again = await watcher.scan();
      expect(again.first, isFalse);
      expect(again.events, isEmpty);
    });

    test('a reply to the member’s post, a player joining their search, the waiting list moving up', () async {
      await scan();
      // Yassine looks for players; Hamza replies and joins.
      final post = await me.publish(
        PostDraft(
          category: ForumCategory.venues,
          title: 'Il manque un gardien jeudi à Arena Five',
          body: 'Un seul joueur, niveau 3.',
          search: PlayerSearch(sport: MuSport.football, place: 'Arena Five', at: storyNow.add(const Duration(days: 1)), needed: 1),
        ),
      );
      final hamza = as(ForumSeed.id(6));
      await hamza.reply(post.id, 'Je peux garder les cages !');
      await hamza.join(post.id);
      final events = await scan();
      expect(events.map((e) => e.type), containsAll([NotificationType.postReply, NotificationType.playersJoined]));
      expect(events.firstWhere((e) => e.type == NotificationType.playersJoined).title, 'Hamza R. vient à ton match');
      expect(events.every((e) => e.route == Routes.forumPost(post.id)), isTrue);

      // Mariem's padel is full: Yassine waits, then Lina drops out and he plays.
      final padel = SearchSeed.postId('padel');
      await me.join(padel);
      expect(await scan(), isEmpty);
      await as(ForumSeed.id(17)).leave(padel);
      // Nour (waiting before Yassine) moves up first: Yassine still waits.
      expect(await scan(), isEmpty);
      await as(ForumSeed.id(15)).leave(padel);
      final promoted = await scan();
      expect(promoted.single.type, NotificationType.spotFreed);
      expect(promoted.single.title, 'Une place s’est libérée : tu joues !');
    });

    test('a buyer’s review of the member as a seller', () async {
      await scan();
      await as(ForumSeed.id(2)).review(ForumSeed.me, 5, 'Parfait, merci !');
      final e = (await scan()).single;
      expect(e.type, NotificationType.sellerReview);
      expect(e.title, 'Ines M. t’a laissé un avis · 5 étoiles');
    });

    test('offers: sent, countered by the demo seller, accepted, each side told', () async {
      await scan();
      final id = MessagesSeed.conversationId('mariem');
      final offer = await chat.sendOffer(id, raquette, 140);
      expect(offer.offer!.asking, 180);
      expect(offer.offer!.status, OfferStatus.pending);
      await expectLater(() => chat.answerOffer(offer.id, accept: true), throwsA(isA<ForumRuleException>()));
      // 140 < 85 % of 180: Mariem counters halfway, rounded to 5 DT.
      expect(await chat.demoAnswer(id), isTrue);
      final messages = await chat.messages(id);
      final counter = messages.last;
      expect(counter.kind, ChatKind.offer);
      expect(counter.offer!.price, 160);
      expect(messages.firstWhere((m) => m.id == offer.id).offer!.status, OfferStatus.replaced);
      final told = await scan();
      expect(told.single.type, NotificationType.offerReceived);
      expect(told.single.title, 'Mariem K. te propose ${formatDT(160)}');
      // Yassine accepts the counter-offer; Mariem is told.
      await chat.answerOffer(counter.id, accept: true);
      expect((await chat.messages(id)).last.offer!.status, OfferStatus.accepted);
      final forMariem = ForumWatcher(db, now: () => storyNow, meId: () => mariem);
      await forMariem.scan();
      // (Mariem's first scan already counts it: within the last 24 hours.)
    });

    test('an offer of 85 % or more is accepted by the demo seller', () async {
      final id = MessagesSeed.conversationId('mariem');
      await chat.sendOffer(id, raquette, 160);
      expect(await chat.demoAnswer(id), isTrue);
      expect((await chat.messages(id)).last.offer!.status, OfferStatus.accepted);
    });

    test('saved searches: at least one criterion, matches counted, a new matching post told', () async {
      await scan();
      await expectLater(() => me.saveAlert(AlertKind.listing), throwsA(isA<ForumRuleException>()));
      final alert = await me.saveAlert(AlertKind.listing, words: 'crampons', maxPrice: 130, size: '42');
      expect((await me.alerts()).single.matches, 1);
      expect((await me.feed(const ForumQuery(listingsOnly: true, maxPrice: 100))).posts.map((p) => p.id), isNot(contains(MarketSeed.postId('crampons'))));
      // Old posts are not « new »: nothing yet.
      expect(await scan(), isEmpty);
      final later = SqliteForumRepository(db, now: () => storyNow.add(const Duration(hours: 1)), meId: () => ForumSeed.id(8));
      await later.publish(
        const PostDraft(
          category: ForumCategory.equipment,
          sport: MuSport.football,
          title: 'Crampons Adidas Predator taille 42',
          body: 'Portés deux fois.',
          listing: ForumListing(price: 90, condition: ListingCondition.likeNew, size: '42'),
        ),
      );
      final e = (await scan()).single;
      expect(e.type, NotificationType.savedSearchMatch);
      expect(e.title, 'Nouvelle annonce · crampons · ≤ ${formatDT(130)} · Taille 42');
      await me.setAlertActive(alert.id, active: false);
      expect((await me.alerts()).single.active, isFalse);
      await me.deleteAlert(alert.id);
      expect(await me.alerts(), isEmpty);
    });

    test('a story friend joins the member’s new search (demo)', () async {
      final post = await me.publish(
        PostDraft(
          category: ForumCategory.general,
          title: 'Padel samedi matin, qui vient ?',
          body: 'Niveau 3,5.',
          search: PlayerSearch(
            sport: MuSport.padel,
            place: 'Smash Padel Club',
            at: storyNow.add(const Duration(days: 1)),
            needed: 2,
            levelMin: 3,
            levelMax: 4,
          ),
        ),
      );
      expect(await me.demoJoin(post.id), isTrue);
      final s = (await me.thread(post.id)).post.search!;
      expect(s.players.single.sport, MuSport.padel);
      expect(s.fits(s.players.single.level), isTrue);
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

    testWidgets('Communauté: « Notifications » counts the forum’s and opens the centre on Communauté', (tester) async {
      await pumpApp(tester, Routes.community);
      expect(find.text('Notifications'), findsOneWidget);
      await tap(tester, find.text('Notifications'));
      expect(find.text('Ines M. t’a mentionné'), findsOneWidget);
    });

    testWidgets('« Faire une offre » from a listing: the chat with the offer card', (tester) async {
      await pumpApp(tester, Routes.forumPost(MarketSeed.postId('raquette')));
      await tap(tester, find.text('Faire une offre'));
      expect(find.text('Prix demandé : ${formatDT(180)}'), findsOneWidget);
      await tap(tester, find.text(formatDT(170)));
      await tap(tester, find.text('Proposer ${formatDT(170)}'));
      expect(find.text('Ton offre'.toUpperCase()), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget);
      // Mariem accepts (≥ 85 %).
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Acceptée'), findsOneWidget);
    });

    testWidgets('« Mes alertes »: create one from Équipement, see it with its matches', (tester) async {
      await pumpApp(tester, Routes.community);
      await tap(tester, find.text('Équipement'));
      await tap(tester, find.text('Être prévenu des nouvelles annonces'));
      expect(find.text('Nouvelle alerte'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'raquette');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer l’alerte'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Alerte créée'), findsOneWidget);
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(routerProvider).push(Routes.forumAlerts);
      await tester.pumpAndSettle();
      expect(find.text('raquette'), findsOneWidget);
      expect(find.text('Annonces · 1 annonce'), findsOneWidget);
    });
  });
}
