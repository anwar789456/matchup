import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/connectivity.dart';
import 'package:matchup/features/common/data/story_data.dart';
import 'package:matchup/features/explore/controllers/explore_controller.dart';
import 'package:matchup/features/explore/data/tournaments_repository.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/venue/data/venues_repository.dart';
import 'package:matchup/router.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  DateTime now() => storyNow;
  final venues = venuesById(Story.venues);
  const myLevel = RangeValues(3, 4.5);

  group('Explorer filters (story data, ven. 16 oct. 18h00)', () {
    test('the default filters keep the 12 open games and count 2', () {
      const f = ExploreFilters(level: myLevel);
      expect(f.activeCount, 2);
      final games = filterGames(Story.openGames, venues, f, ExploreSort.recommended, now());
      expect(games, hasLength(12));
      expect(games.first.id, 'g1');
    });

    test('« Mon niveau » spans the lowest level to one point above the highest', () {
      expect(ExploreController.myLevelRange(Story.myLevels.values), myLevel);
    });

    test('basket tonight finds nothing; without « Ce soir » it finds G3', () {
      const f = ExploreFilters(sports: {MuSport.basketball}, when: ExploreWhen.tonight);
      expect(f.activeCount, 3);
      expect(filterGames(Story.openGames, venues, f, ExploreSort.soonest, now()), isEmpty);
      final relaxed = filterGames(
        Story.openGames,
        venues,
        f.copyWith(when: ExploreWhen.any),
        ExploreSort.soonest,
        now(),
      );
      expect(relaxed.single.id, 'g3');
    });

    test('tonight is G2 only; the sort orders by price', () {
      const tonight = ExploreFilters(when: ExploreWhen.tonight);
      expect(
        filterGames(Story.openGames, venues, tonight, ExploreSort.recommended, now()).single.id,
        'g2',
      );
      final cheapest = filterGames(
        Story.openGames,
        venues,
        const ExploreFilters(),
        ExploreSort.cheapest,
        now(),
      );
      expect(cheapest.first.pricePerPlayer, 9);
    });

    test('venues free tonight, closest first; price filters the share per person', () {
      final all = filterVenues(Story.venues, const ExploreFilters(), ExploreSort.closest);
      expect(all.map((v) => v.name), [
        'Arena Five',
        'Smash Padel Club',
        'Padel House Menzah',
        'Hoop Zone',
      ]);
      final cheap = filterVenues(
        Story.venues,
        const ExploreFilters(price: RangeValues(0, 15)),
        ExploreSort.closest,
      );
      expect(cheap.map((v) => v.name), ['Arena Five', 'Hoop Zone']);
    });
  });

  group('Home and Explorer screens', () {
    Future<ProviderContainer> pumpApp(WidgetTester tester, String at) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(now),
          onboardingStoreProvider.overrideWithValue(
            MemoryOnboardingStore(
              const PlayerOnboardingState(
                completed: true,
                tourSeen: true,
                fullName: 'Yassine Belhaj',
                zones: ['La Marsa'],
              ),
            ),
          ),
          gamesRepositoryProvider.overrideWith(
            (ref) => FakeGamesRepository(
              latency: Duration.zero,
              offline: () => ref.read(simulatedOfflineProvider),
            ),
          ),
          venuesRepositoryProvider.overrideWith(
            (ref) => FakeVenuesRepository(
              latency: Duration.zero,
              offline: () => ref.read(simulatedOfflineProvider),
            ),
          ),
          tournamentsRepositoryProvider.overrideWithValue(
            FakeTournamentsRepository(latency: Duration.zero),
          ),
          bookingsRepositoryProvider.overrideWithValue(
            FakeBookingsRepository(latency: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(routerProvider).go(at);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MatchUpApp()),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pumpAndSettle();
      return container;
    }

    final page = find.byType(Scrollable).first;

    Future<void> scrollTo(WidgetTester tester, Finder finder) =>
        tester.scrollUntilVisible(finder, 300, scrollable: page);

    Finder chip(String label) => find.widgetWithText(MuChip, label).first;

    Future<void> tap(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('HOM-01 shows every section of the story', (tester) async {
      await pumpApp(tester, Routes.home);
      expect(find.text('Salut Yassine'), findsOneWidget);
      expect(find.text('Parties pour toi'), findsOneWidget);
      expect(
        find.text('Choisies selon ton niveau, tes zones et tes soirs libres.'),
        findsOneWidget,
      );
      await scrollTo(tester, find.text('Mariem K. t’invite au padel'));
      await scrollTo(tester, find.text('Arena Five · Terrain 1')); // MU-48213, compact
      await scrollTo(tester, find.text('Padel Masters Lac 2'));
      expect(find.text('Smash Padel Club'), findsWidgets);
      expect(find.text('Plus que 4 places'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Réserver un terrain » opens Explorer on Terrains (EXP-03)', (tester) async {
      await pumpApp(tester, Routes.home);
      await scrollTo(tester, find.text('Réserver un terrain'));
      await tap(tester, find.text('Réserver un terrain'));
      expect(find.text('Explorer'), findsWidgets);
      expect(find.text('libres ce soir'), findsNothing); // the count is one rich text
      expect(find.textContaining('libres ce soir'), findsOneWidget);
      expect(find.text('Hoop Zone'), findsOneWidget);
    });

    testWidgets('EXP-01 lists 12 games; basket tonight gives EXP-06 and its leads', (tester) async {
      await pumpApp(tester, Routes.explore);
      expect(find.textContaining('parties'), findsWidgets);
      expect(find.textContaining('près de La Marsa'), findsOneWidget);
      expect(find.text('Arena Five · Terrain 2'), findsOneWidget);

      await tap(tester, chip('Mon niveau'));
      await tap(tester, chip('Ce soir'));
      await tap(tester, chip('Basket'));
      expect(find.text('Aucune partie de basket ce soir'), findsOneWidget);
      expect(find.text('Préviens-moi'), findsOneWidget);
      expect(find.text('Retirer « Ce soir »'), findsOneWidget);
      expect(find.text('1 partie de basket sam. 17 oct. · 18h00'), findsOneWidget);

      await tap(tester, find.text('Retirer « Ce soir »'));
      expect(find.text('Hoop Zone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EXP-04: the sheet counts the results of its draft', (tester) async {
      await pumpApp(tester, Routes.explore);
      await tap(tester, chip('Filtres'));
      expect(find.text('Afficher 12 parties'), findsOneWidget);
      await tap(tester, find.widgetWithText(MuChip, 'Football').last);
      expect(find.text('Afficher 6 parties'), findsOneWidget);
      await tap(tester, find.text('Afficher 6 parties'));
      expect(find.text('Afficher 6 parties'), findsNothing);
      expect(find.textContaining('près de La Marsa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EXP-07: offline keeps the saved list with « Enregistrées à »', (tester) async {
      final container = await pumpApp(tester, Routes.explore);
      container.read(simulatedOfflineProvider.notifier).set(true);
      container.invalidate(exploreGamesProvider);
      await tester.pumpAndSettle();
      expect(find.text('Hors ligne'), findsOneWidget);
      expect(find.text('Reconnecte-toi pour réserver.'), findsOneWidget);
      expect(find.textContaining('Enregistrées à'), findsOneWidget);
      expect(find.text('Recherche indisponible hors ligne'), findsOneWidget);
      expect(find.text('Arena Five · Terrain 2'), findsOneWidget);

      container.read(simulatedOfflineProvider.notifier).set(false);
      await tap(tester, find.text('Réessayer'));
      expect(find.text('Hors ligne'), findsNothing);
    });

    testWidgets('EXP-05: recent searches and results for « mar »', (tester) async {
      await pumpApp(tester, Routes.explore);
      await tap(tester, find.byType(TextField).first);
      expect(find.text('RECHERCHES RÉCENTES'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'mar');
      await tester.pumpAndSettle();
      expect(find.text('ZONES'), findsOneWidget);
      expect(find.text('Marsa Corniche'), findsOneWidget);
      expect(find.text('12 parties · 4 terrains'), findsOneWidget);
      expect(find.text('Foot 5v5 femmes · Arena Five'), findsOneWidget);
      expect(find.text('Omar D.'), findsOneWidget);
      expect(find.text('Mariem K.'), findsOneWidget); // only as a recent search
      expect(tester.takeException(), isNull);
    });
  });
}
