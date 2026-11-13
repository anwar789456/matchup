import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/forum/data/forum_repository.dart';
import 'package:matchup/features/forum/data/forum_seed.dart';
import 'package:matchup/features/forum/data/market_seed.dart';
import 'package:matchup/features/forum/data/messages_models.dart';
import 'package:matchup/features/forum/data/messages_seed.dart';
import 'package:matchup/features/forum/data/sqlite_forum_repository.dart';
import 'package:matchup/features/forum/data/sqlite_messages_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/router.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';

/// Équipement as a marketplace: listings (price, condition, sold), media in posts, buyers'
/// reviews of sellers kept apart from comments, « Écrire au vendeur », and media in chats.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('repository', () {
    late AppDatabase db;
    late SqliteForumRepository me;
    SqliteForumRepository as(String id) => SqliteForumRepository(db, now: () => storyNow, meId: () => id);
    final mariem = ForumSeed.id(4);
    final raquette = MarketSeed.postId('raquette');
    const photo = 'data:image/png;base64,iVBORw0KGgo=';
    const video = 'data:video/mp4;base64,AAAAIGZ0eXA=';

    setUp(() {
      db = AppDatabase();
      me = as(ForumSeed.me);
    });
    tearDown(() => db.close());

    test('the story’s listings: price, condition, sold, the seller’s rating', () async {
      final feed = await me.feed(const ForumQuery(category: ForumCategory.equipment));
      final r = feed.posts.firstWhere((p) => p.id == raquette);
      expect(r.listing!.price, 180);
      expect(r.listing!.condition, ListingCondition.likeNew);
      expect(r.listing!.sold, isFalse);
      expect(r.sellerRating!.count, 3);
      expect(r.sellerRating!.average, closeTo(4.67, 0.01));
      expect(feed.posts.firstWhere((p) => p.id == MarketSeed.postId('ballon')).listing!.sold, isTrue);
      // A question in Équipement stays a discussion.
      expect(feed.posts.firstWhere((p) => p.title.startsWith('Crampons pour')).listing, isNull);
    });

    test('selling needs a price; another category is a plain post; photos and a video are kept', () async {
      const draft = PostDraft(
        category: ForumCategory.equipment,
        sport: MuSport.football,
        title: 'Gants de gardien Uhlsport taille 9',
        body: 'Portés trois fois.',
        listing: ForumListing(price: 0, condition: ListingCondition.likeNew),
      );
      await expectLater(() => me.publish(draft), throwsA(isA<ForumRuleException>()));
      final sold = await me.publish(
        draft.copyWith(
          listing: () => const ForumListing(price: 45, condition: ListingCondition.likeNew, size: '9', city: 'La Marsa'),
          images: [photo, photo, video],
        ),
      );
      expect(sold.listing!.price, 45);
      expect(sold.listing!.size, '9');
      expect(sold.images, hasLength(3));
      final discussion = await me.publish(
        draft.copyWith(category: ForumCategory.general, listing: () => const ForumListing(price: 45, condition: ListingCondition.good)),
      );
      expect(discussion.listing, isNull);
    });

    test('only the seller marks it sold, and back for sale', () async {
      await expectLater(() => me.markSold(raquette, sold: true), throwsA(isA<ForumRuleException>()));
      await as(mariem).markSold(raquette, sold: true);
      expect((await me.thread(raquette)).post.listing!.sold, isTrue);
      await as(mariem).markSold(raquette, sold: false);
      expect((await me.thread(raquette)).post.listing!.sold, isFalse);
    });

    test('reviews: one per buyer and seller, not on oneself, average and stars', () async {
      await expectLater(() => as(mariem).review(mariem, 5, 'Top'), throwsA(isA<ForumRuleException>()));
      await me.review(mariem, 3, 'Correct, rendez-vous un peu en retard.', postId: raquette);
      var r = await me.sellerReviews(mariem);
      expect(r.count, 4);
      expect(r.stars, [2, 1, 1, 0, 0]);
      expect(r.mine!.rating, 3);
      expect(r.reviews.firstWhere((x) => x.mine).item, startsWith('Raquette Bullpadel'));
      // Again: the same review is updated.
      await me.review(mariem, 5, 'Finalement parfait !');
      r = await me.sellerReviews(mariem);
      expect(r.count, 4);
      expect(r.average, closeTo(4.75, 0.01));
      await me.deleteReview(mariem);
      expect((await me.sellerReviews(mariem)).count, 3);
    });

    test('a hurtful review is stopped, then only its author sees it', () async {
      await expectLater(() => me.review(mariem, 1, 'T’es nulle, arnaqueuse.'), throwsA(isA<ForumAlertException>()));
      await me.review(mariem, 1, 'T’es nulle, arnaqueuse.', confirmed: true);
      expect((await me.sellerReviews(mariem)).mine!.hidden, isTrue);
      final seen = await as(ForumSeed.id(2)).sellerReviews(mariem);
      expect(seen.reviews.any((x) => x.text.contains('arnaqueuse')), isFalse);
      expect(seen.count, 3);
    });

    test('chat media: photo, video, voice, with their previews; a friend answers a voice message', () async {
      final chat = SqliteMessagesRepository(db, now: () => storyNow);
      final id = MessagesSeed.conversationId('mariem');
      final p = await chat.sendMedia(id, photo, caption: 'Regarde la housse');
      expect(p.kind, ChatKind.image);
      expect(p.body, 'Regarde la housse');
      final v = await chat.sendMedia(id, video);
      expect(v.kind, ChatKind.video);
      final voice = await chat.sendVoice(id, 'data:audio/wav;base64,UklGRg==', const Duration(seconds: 12));
      expect(voice.kind, ChatKind.voice);
      expect(voice.media!.duration, const Duration(seconds: 12));
      expect(await chat.demoAnswer(id), isTrue);
      expect(MessagesSeed.answersToVoice, contains((await chat.messages(id)).last.body));
    });

    test('a shared listing shows its price in the chat', () async {
      final chat = SqliteMessagesRepository(db, now: () => storyNow);
      final m = await chat.sharePost(MessagesSeed.conversationId('mariem'), raquette);
      expect(m.shared!.listing!.price, 180);
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

    testWidgets('Équipement: the listing card, then the listing with reviews and « Écrire au vendeur »', (tester) async {
      await pumpApp(tester, Routes.community);
      await tap(tester, find.text('Équipement'));
      const title = 'Raquette Bullpadel Vertex 03 · très bon état';
      await tester.scrollUntilVisible(find.text(title), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      final card = find.ancestor(of: find.text(title), matching: find.byType(MuForumPostCard));
      expect(find.descendant(of: card, matching: find.textContaining('180')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('Disponible')), findsOneWidget);

      await tap(tester, find.text(title));
      expect(find.text('Écrire au vendeur'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Avis sur Mariem K.'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('3 avis'), findsOneWidget);
      expect(find.text('Donner mon avis'), findsOneWidget);
      expect(find.textContaining('question'), findsWidgets);

      // A review: 4 stars, then the thanks.
      await tap(tester, find.text('Donner mon avis'));
      await tap(tester, find.bySemanticsLabel(RegExp('4')).last);
      await tester.tap(find.text('Publier mon avis'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Merci pour ton avis !'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('4 avis'), findsOneWidget);

      // « Écrire au vendeur »: the chat with the listing and the question ready.
      await tester.scrollUntilVisible(find.text('Écrire au vendeur'), -200, scrollable: find.byType(Scrollable).first);
      await tap(tester, find.text('Écrire au vendeur'));
      expect(find.text('Bonjour ! Est-ce toujours disponible ?'), findsOneWidget);
      expect(find.text('Annonce'.toUpperCase()), findsOneWidget);
    });

    testWidgets('FRM-02 in Équipement: « Je vends un article » with price and condition', (tester) async {
      await pumpApp(tester, Routes.forumNew);
      final vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
      await tap(tester, find.widgetWithText(MuChip, 'Équipement'));
      expect(find.text('Je vends un article'), findsOneWidget);
      expect(find.text('Prix'), findsOneWidget);
      expect(find.text('Très bon état'), findsOneWidget);
      expect(find.text('Ce que tu vends'), findsOneWidget);
      await tester.scrollUntilVisible(find.textContaining('Photos et vidéo'), 200, scrollable: vertical);
      await tester.pumpAndSettle();
      expect(find.textContaining('Photos et vidéo'), findsOneWidget);
      await tester.scrollUntilVisible(find.widgetWithText(MuChip, 'Conseils & technique'), -200, scrollable: vertical);
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(MuChip, 'Conseils & technique'));
      expect(find.text('Je vends un article'), findsNothing);
    });
  });
}
