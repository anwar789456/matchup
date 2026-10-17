import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/app_settings.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/features/explore/data/tournaments_repository.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/profile/data/profile_repository.dart';
import 'package:matchup/features/venue/data/venues_repository.dart';
import 'package:matchup/router.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester, String at) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(
            const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.'),
          ),
        ),
        playerProfileRepositoryProvider.overrideWithValue(
          FakePlayerProfileRepository(latency: Duration.zero),
        ),
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
    await tester.pumpAndSettle();
  }

  Future<void> see(WidgetTester tester, Finder finder) async {
    final list = find.byType(ListView).first;
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -300), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('PRF-01 → PRF-03 why level → PRF-04 edit and save', (tester) async {
    await pumpApp(tester, Routes.profile);
    expect(find.text('Yassine B.'), findsOneWidget);
    expect(find.text('@yassine.b · La Marsa'), findsOneWidget);
    expect(find.text('58 % de victoires'), findsOneWidget);
    await see(tester, find.text('Pourquoi ce niveau ?').first);
    await tap(tester, find.text('Pourquoi ce niveau ?').first);
    expect(find.text('Pourquoi 3,5 en padel ?'), findsOneWidget);
    expect(find.text('Tes 18 matchs de padel'), findsOneWidget);
    await tap(tester, find.text('J’ai compris'));

    await tester.drag(find.byType(ListView).first, const Offset(0, 3000), warnIfMissed: false);
    await tester.pumpAndSettle();
    await see(tester, find.text('Modifier le profil'));
    await tap(tester, find.text('Modifier le profil'));
    expect(find.text('Sports et postes'), findsOneWidget);
    await see(tester, find.text('Côté droit'));
    await tap(tester, find.text('Côté droit'));
    await see(tester, find.text('Enregistrer'));
    await tap(tester, find.text('Enregistrer'));
    final me = await tester.runAsync(() => container.read(playerProfileRepositoryProvider).me());
    expect(me!.positions[MuSport.padel], 'côté droit');
  });

  testWidgets('PRF-02 public profile: follow', (tester) async {
    await pumpApp(tester, Routes.player('Skander T.'));
    expect(find.text('Skander T.'), findsOneWidget);
    expect(find.text('Ses parties te correspondent'), findsOneWidget);
    await tap(tester, find.text('Suivre'));
    expect(find.text('Suivi'), findsOneWidget);
  });

  testWidgets('SET-01 → SET-04 theme and language apply', (tester) async {
    await pumpApp(tester, Routes.settings);
    expect(find.text('Français · Système'), findsOneWidget);
    await tap(tester, find.text('Langue et thème'));
    await tap(tester, find.text('Sombre'));
    expect(container.read(appSettingsProvider).themeMode, ThemeMode.dark);
    await tap(tester, find.text('English'));
    expect(container.read(appSettingsProvider).locale.languageCode, 'en');
  });

  testWidgets('SET-07: the button needs SUPPRIMER', (tester) async {
    await pumpApp(tester, Routes.settingsDelete);
    expect(find.text('Après le 15 nov., c’est définitif'), findsOneWidget);
    final button = find.widgetWithText(MuButton, 'Supprimer mon compte');
    expect(tester.widget<MuButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'SUPPRIMER');
    await tester.pumpAndSettle();
    expect(tester.widget<MuButton>(button).onPressed, isNotNull);
  });
}
