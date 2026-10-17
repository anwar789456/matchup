import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/features/common/data/draft_store.dart';
import 'package:matchup/features/dev/debug_menu.dart';
import 'package:matchup/features/explore/data/tournaments_repository.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/notifications/data/notification_catalog.dart';
import 'package:matchup/features/notifications/data/notification_models.dart';
import 'package:matchup/features/notifications/data/notification_prefs.dart';
import 'package:matchup/features/notifications/data/notification_repository.dart';
import 'package:matchup/features/notifications/data/push_service.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/venue/data/venues_repository.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

/// Phase 11: the centre (NOT-01/02/03), preferences (NOT-10), the real-time toast (NOT-07) from
/// the debug menu, simulated push (NOT-08/09) and the catalog (NOT-04/05/06).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late ProviderContainer container;
  late MemoryDraftStore prefsStore;
  late RecordingPushService pushes;

  // The freed spot's countdown ticks every second: pump instead of settling.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpApp(
    WidgetTester tester,
    String at, {
    bool empty = false,
    bool debugMenu = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    prefsStore = MemoryDraftStore();
    pushes = RecordingPushService();
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(
            const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.'),
          ),
        ),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(now: storyNow, empty: empty),
        ),
        notificationPrefsStoreProvider.overrideWithValue(prefsStore),
        pushServiceProvider.overrideWithValue(pushes),
        debugMenuEnabledProvider.overrideWithValue(debugMenu),
        bookingsRepositoryProvider.overrideWithValue(
          FakeBookingsRepository(latency: Duration.zero),
        ),
        gamesRepositoryProvider.overrideWithValue(FakeGamesRepository(latency: Duration.zero)),
        venuesRepositoryProvider.overrideWithValue(FakeVenuesRepository(latency: Duration.zero)),
        tournamentsRepositoryProvider.overrideWithValue(
          FakeTournamentsRepository(latency: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(routerProvider).go(at);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MatchUpApp()),
    );
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('Home bell → NOT-01 → « Tout marquer comme lu »', (tester) async {
    await pumpApp(tester, Routes.home);
    await tap(tester, find.bySemanticsLabel(RegExp('Notifications')).first);
    expect(find.text('AUJOURD’HUI'), findsOneWidget);
    expect(find.text('Une place s’est libérée'), findsOneWidget);
    expect(find.text('Réclamer la place'), findsOneWidget);
    expect(find.textContaining('3', findRichText: true), findsWidgets);
    expect(find.text('Mariem K. t’invite au padel'), findsOneWidget);
    await tap(tester, find.text('Tout marquer comme lu'));
    final list = await container.read(notificationRepositoryProvider).watch().first;
    expect(list.where((n) => n.unread), isEmpty);
    expect(container.read(unreadNotificationsProvider), 0);
  });

  testWidgets('NOT-02: Paiements filter, swipe « Supprimer »', (tester) async {
    await pumpApp(tester, Routes.notifications);
    await tester.drag(find.text('Tournois'), const Offset(-200, 0));
    await settle(tester);
    await tap(tester, find.text('Paiements'));
    expect(find.text('Une place s’est libérée'), findsNothing);
    expect(find.text('Ta part de 15 DT est en attente'), findsOneWidget);
    expect(find.text('Demande de remboursement envoyée'), findsOneWidget);
    expect(find.textContaining('non lue', findRichText: true), findsOneWidget);

    await tester.drag(find.text('Ta part de 15 DT est en attente'), const Offset(-200, 0));
    await settle(tester);
    expect(find.text('Supprimer'), findsWidgets);
    await tester.tap(find.text('Supprimer').first);
    await settle(tester);
    expect(find.text('Ta part de 15 DT est en attente'), findsNothing);
  });

  testWidgets('NOT-03 empty → « Gérer mes notifications » → NOT-10 saved locally', (tester) async {
    await pumpApp(tester, Routes.notifications, empty: true);
    expect(find.text('Tout est calme'), findsOneWidget);
    await tap(tester, find.text('Gérer mes notifications'));

    // NOT-10: payments and security can't leave the app; matches push can be cut.
    expect(find.text('Tout mettre en pause'), findsOneWidget);
    final locked = tester.widget<MuSwitch>(
      find.byWidgetPredicate(
        (w) => w is MuSwitch && (w.semanticLabel ?? '').startsWith('Paiements · In-app'),
      ),
    );
    expect(locked.onChanged, isNull);
    await tap(
      tester,
      find.byWidgetPredicate((w) => w is MuSwitch && w.semanticLabel == 'Matchs · Push'),
    );
    expect(
      container
          .read(notificationPrefsProvider)
          .isOn(NotificationCategory.matches, NotificationChannel.push),
      isFalse,
    );
    expect(prefsStore.drafts['notification_prefs'], isNotNull);
    await tester.scrollUntilVisible(
      find.text('1 h'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, find.text('1 h'));
    expect(find.text('En pause jusqu’à 19h00'), findsOneWidget);
    await tap(tester, find.text('Reprendre maintenant'));
    expect(find.text('1 h'), findsOneWidget);
  });

  testWidgets('NOT-07: the debug menu adds Rami S. to G1 while GAM-01 is open', (tester) async {
    await pumpApp(tester, Routes.game('g1'), debugMenu: true);
    expect(find.text('8/10 joueurs'), findsOneWidget);
    await tap(
      tester,
      find.descendant(of: find.byType(DebugMenuButton), matching: find.byType(InkWell)),
    );
    await tap(tester, find.text('Rami S. rejoint G1'));
    await settle(tester);
    expect(find.text('Rami S. a rejoint la partie · 9/10'), findsOneWidget);
    expect(find.text('Attaquant chez les Bleus · plus qu’1 place'), findsOneWidget);
    expect(find.text('9/10 joueurs'), findsOneWidget);
    final list = await container.read(notificationRepositoryProvider).watch().first;
    expect(list.first.title, 'Rami S. a rejoint la partie · 9/10');

    // NOT-08 / NOT-09: a simulated push from the same menu.
    await tap(
      tester,
      find.descendant(of: find.byType(DebugMenuButton), matching: find.byType(InkWell)),
    );
    final push = find.text('Une place s’est libérée');
    await tester.scrollUntilVisible(push, 200, scrollable: find.byType(Scrollable).last);
    await tap(tester, push);
    expect(pushes.shown.single.actions.map((a) => a.$2), ['Réclamer la place', 'Ignorer']);
    expect(pushes.shown.single.timeSensitive, isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  test('the catalog has the 36 types of NOT-04/05/06', () {
    final all = notificationCatalog(storyNow);
    expect(all.map((n) => n.type.number).toList(), List.generate(36, (i) => i + 1));
    expect(all.where((n) => n.priority == NotificationPriority.urgent).map((n) => n.type.number), [
      4,
      12,
      20,
    ]);
    expect(PushSamples.all, hasLength(5));
  });
}
