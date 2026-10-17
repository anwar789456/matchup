import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/features/auth/controllers/auth_providers.dart';
import 'package:matchup/features/auth/data/fake_auth_repository.dart';
import 'package:matchup/features/explore/data/tournaments_repository.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/home/screens/home_screen.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/level_estimator.dart';
import 'package:matchup/features/player_onboarding/data/location_services.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/player_onboarding/data/profile_repository.dart';
import 'package:matchup/features/player_onboarding/screens/availability_screen.dart';
import 'package:matchup/features/player_onboarding/screens/level_result_screen.dart';
import 'package:matchup/features/player_onboarding/screens/location_denied_screen.dart';
import 'package:matchup/features/player_onboarding/screens/zones_screen.dart';
import 'package:matchup/features/venue/data/venues_repository.dart';
import 'package:matchup/router.dart';
import 'package:matchup/theme/theme.dart';

class _FakePermissions implements DevicePermissions {
  _FakePermissions(this.location);

  final PermissionOutcome location;
  bool settingsOpened = false;

  @override
  Future<PermissionOutcome> requestLocation() async => location;

  @override
  Future<PermissionOutcome> requestNotifications() async => PermissionOutcome.granted;

  @override
  Future<bool> openSettings() async => settingsOpened = true;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late MemoryOnboardingStore store;

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    String? at,
    PermissionOutcome location = PermissionOutcome.granted,
    PlayerOnboardingState? saved,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    store = MemoryOnboardingStore(saved);
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(latency: Duration.zero)),
      onboardingStoreProvider.overrideWithValue(store),
      levelEstimatorProvider.overrideWithValue(const FakeLevelEstimator(latency: Duration.zero)),
      devicePermissionsProvider.overrideWithValue(_FakePermissions(location)),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository(latency: Duration.zero)),
      gamesRepositoryProvider.overrideWithValue(FakeGamesRepository(latency: Duration.zero)),
      venuesRepositoryProvider.overrideWithValue(FakeVenuesRepository(latency: Duration.zero)),
      bookingsRepositoryProvider.overrideWithValue(
        FakeBookingsRepository(latency: Duration.zero),
      ),
      tournamentsRepositoryProvider.overrideWithValue(
        FakeTournamentsRepository(latency: Duration.zero),
      ),
    ]);
    addTearDown(container.dispose);
    if (at != null) container.read(routerProvider).go(at);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MatchUpApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) => tap(tester, find.text(text).last);

  Future<void> enter(WidgetTester tester, String label, String text) async {
    final field = find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(field.first, text);
    await tester.pumpAndSettle();
  }

  testWidgets('sports → questionnaire → level → … → profile → Home with the tour',
      (tester) async {
    await pumpApp(tester, at: Routes.playerSports);
    expect(find.text('Quels sports tu joues ?'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel(RegExp('^Padel')));
    await tapText(tester, 'Continuer');

    // PLY-02: six questions, the designed answers.
    expect(find.text('Depuis quand joues-tu au padel ?'), findsOneWidget);
    for (final answer in [
      '2 à 5 ans',
      '2 fois par semaine ou plus',
      '1 ou 2 tournois amicaux',
    ]) {
      await tapText(tester, answer);
      await tapText(tester, 'Continuer');
    }
    await tap(tester, find.bySemanticsLabel('3, À l’aise'));
    expect(find.text('3 · À l’aise'), findsOneWidget);
    await tapText(tester, 'Continuer');
    await tapText(tester, 'Je la sors régulièrement');
    await tapText(tester, 'Continuer');
    await tapText(tester, 'Régulier');
    await tapText(tester, 'Voir mon niveau');

    // PLY-03.
    expect(find.byType(LevelResultScreen), findsOneWidget);
    expect(find.text('3,5'), findsOneWidget);
    expect(find.textContaining('Confiance : moyenne', findRichText: true), findsOneWidget);
    expect(find.text('Volée à l’aise (3/5)'), findsOneWidget);
    await tapText(tester, 'C’est bon');

    // PLY-04.
    await tapText(tester, 'Côté gauche');
    expect(find.text('Côté gauche : revers côté vitre, souvent celui qui finit au smash.'),
        findsOneWidget);
    await tapText(tester, 'Continuer');

    // PLY-05.
    expect(find.byType(AvailabilityScreen), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Lundi soir'));
    await tap(tester, find.bySemanticsLabel('Samedi après-midi'));
    expect(find.text('2 créneaux'), findsOneWidget);
    await tapText(tester, 'Continuer');

    // PLY-06 → 07, position granted.
    await tapText(tester, 'Activer la localisation');
    expect(find.byType(ZonesScreen), findsOneWidget);
    expect(find.textContaining('Position activée', findRichText: true), findsOneWidget);
    expect(find.text('1 zone'), findsOneWidget);
    await tapText(tester, 'Ennasr');
    expect(find.text('2 zones'), findsOneWidget);
    await tapText(tester, '20 km');
    expect(find.text('Jusqu’à 20 km'), findsOneWidget);
    await tapText(tester, 'Continuer');

    // PLY-09.
    expect(find.text('Ne rate aucune partie'), findsOneWidget);
    await tapText(tester, 'Activer les notifications');

    // PLY-10.
    expect(find.text('Montre-toi'), findsOneWidget);
    await enter(tester, 'Pseudo', 'mariem.k');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('@mariem.k est déjà pris. Essaie une variante.'), findsOneWidget);
    await enter(tester, 'Pseudo', 'yassine.b');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('@yassine.b est disponible'), findsOneWidget);
    await enter(tester, 'Prénom et nom', 'Yassine Belhadj');
    expect(find.text('Les autres joueurs voient « Yassine B. », jamais ton nom complet.'),
        findsOneWidget);
    await tapText(tester, 'Terminer');

    // PLY-11 with the tour.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Salut Yassine'), findsOneWidget);
    expect(find.text('Des parties choisies pour toi'), findsOneWidget);
    expect(find.textContaining('Recommandé car ton niveau (3,5)'), findsOneWidget);
    await tapText(tester, 'Suivant');
    expect(find.text('Crée ta partie en 1 minute'), findsOneWidget);
    await tapText(tester, 'Suivant');
    expect(find.text('Tous tes matchs au même endroit'), findsOneWidget);
    await tapText(tester, 'C’est parti');
    expect(find.text('Tous tes matchs au même endroit'), findsNothing);

    final saved = store.state!;
    expect(saved.completed, isTrue);
    expect(saved.tourSeen, isTrue);
    expect(saved.levels[MuSport.padel], 3.5);
    expect(saved.zones, ['La Marsa', 'Ennasr']);
    expect(saved.radiusKm, 20);
    expect(saved.availability, {'lun-soir', 'sam-aprem'});
    expect(saved.notificationsGranted, isTrue);
  });

  testWidgets('a refused location opens PLY-08 with zones to pick', (tester) async {
    await pumpApp(tester, at: Routes.playerLocation, location: PermissionOutcome.denied);
    await tapText(tester, 'Activer la localisation');
    expect(find.byType(LocationDeniedScreen), findsOneWidget);
    expect(find.text('Localisation désactivée'), findsOneWidget);
    await tapText(tester, 'Lac 2');
    expect(store.state!.zones, ['Lac 2']);
    expect(store.state!.locationGranted, isFalse);
    await tapText(tester, 'Continuer avec mes zones');
    expect(find.text('Ne rate aucune partie'), findsOneWidget);
  });

  testWidgets('reopening the app resumes the onboarding where it stopped', (tester) async {
    await pumpApp(
      tester,
      at: Routes.splash,
      saved: const PlayerOnboardingState(lastRoute: Routes.playerAvailability),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.byType(AvailabilityScreen), findsOneWidget);
  });

  testWidgets('a finished onboarding opens the Home without the tour', (tester) async {
    await pumpApp(
      tester,
      at: Routes.splash,
      saved: const PlayerOnboardingState(completed: true, tourSeen: true, pseudo: 'yassine.b'),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Salut yassine.b'), findsOneWidget);
    expect(find.text('Des parties choisies pour toi'), findsNothing);
  });
}
