import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/features/dev/debug_menu.dart';
import 'package:matchup/features/explore/data/tournaments_repository.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/owner/data/camera.dart';
import 'package:matchup/features/owner/data/owner_repository.dart';
import 'package:matchup/features/owner/screens/check_in_result_screen.dart';
import 'package:matchup/features/owner/screens/scanner_screen.dart';
import 'package:matchup/features/owner/screens/today_screen.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/venue/data/venues_repository.dart';
import 'package:matchup/router.dart';

/// Phase 13: the owner space — check-in (valid, already used, invalid, camera refused),
/// blocking a slot from the planning, reporting a no-show, and PRF-06 opening the space.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late ProviderContainer container;
  late FakeOwnerRepository owner;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpApp(WidgetTester tester, String at) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    owner = FakeOwnerRepository(latency: Duration.zero);
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(
            const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.'),
          ),
        ),
        debugMenuEnabledProvider.overrideWithValue(false),
        ownerRepositoryProvider.overrideWithValue(owner),
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

  Future<void> typeCode(WidgetTester tester, String code) async {
    await tap(tester, find.text('Saisir le code'));
    await tester.enterText(find.byType(TextField), code);
    await tap(tester, find.text('Vérifier le code'));
  }

  testWidgets('OWN-20 → typed code MU-48213 → OWN-21 valide → scan the next player', (
    tester,
  ) async {
    await pumpApp(tester, Routes.ownerCheckIn);
    expect(find.text('Vise le QR code du joueur'), findsOneWidget);
    await typeCode(tester, 'mu-48213');
    expect(find.byType(CheckInResultScreen), findsOneWidget);
    expect(find.text('Valide'), findsOneWidget);
    expect(find.text('Bon match ! Laisse entrer le groupe.'), findsOneWidget);
    expect(find.textContaining('Yassine B.', findRichText: true), findsWidgets);
    expect(find.textContaining('Encore attendus : Ines M.'), findsOneWidget);
    await tap(tester, find.text('Scanner le joueur suivant'));
    expect(find.byType(ScannerScreen), findsOneWidget);
    expect(find.byType(CheckInResultScreen), findsNothing);
  });

  testWidgets('OWN-22 déjà utilisé (MU-48190) and OWN-23 invalide (any other code)', (
    tester,
  ) async {
    await pumpApp(tester, Routes.ownerCheckIn);
    await typeCode(tester, 'MU-48190');
    expect(find.text('Déjà utilisé'), findsOneWidget);
    expect(find.text('Billet de Hamza R.'), findsOneWidget);
    expect(find.textContaining('par Skander T.', findRichText: true), findsOneWidget);
    await tap(tester, find.text('Scanner un autre billet'));
    await typeCode(tester, 'MU-48377');
    expect(find.text('Invalide'), findsOneWidget);
    expect(find.text('Ce billet n’est pas pour Arena Five.'), findsOneWidget);
    expect(find.text('Réservé dans un autre terrain'), findsOneWidget);
    await tap(tester, find.text('Chercher dans le planning'));
    expect(find.text('Planning'), findsWidgets);
  });

  testWidgets('STA-05: refused camera shows the steps and the typed-code fallback', (tester) async {
    await pumpApp(tester, Routes.ownerCheckIn);
    container.read(cameraDeniedProvider.notifier).set(true);
    await settle(tester);
    expect(find.text('Caméra bloquée'), findsOneWidget);
    expect(find.text('Touche MatchUp'), findsOneWidget);
    await tap(tester, find.text('Saisir le code à la main'));
    expect(find.text('Le code est écrit sous le QR, dans le billet du joueur.'), findsOneWidget);
  });

  testWidgets('OWN-11 → free slot → OWN-13 → « Bloquer 1 créneau » → the cell is blocked', (
    tester,
  ) async {
    await pumpApp(tester, Routes.ownerPlanning);
    expect(find.text('Hamza R.'), findsOneWidget);
    // The legend's key plus the cleaning slot of Terrain 3.
    expect(find.text('Bloqué'), findsNWidgets(2));
    // Terrain 2 at 19h00 is free (150 DT at peak).
    await tap(tester, find.bySemanticsLabel(RegExp(r'^Terrain 2, 19h00, libre')));
    expect(find.text('Bloquer un créneau'), findsOneWidget);
    expect(find.textContaining('1 h · 1 créneau · aucune réservation touchée'), findsOneWidget);
    await tap(tester, find.text('Tournoi'));
    await tap(tester, find.text('Bloquer 1 créneau'));
    expect(find.text('Bloquer un créneau'), findsNothing);
    expect(find.text('Créneau bloqué'), findsOneWidget);
    final blocks = (await tester.runAsync(() => owner.blocksOn(DateTime(2026, 10, 16))))!;
    expect(blocks.where((b) => b.court == 2 && b.start.hour == 19), hasLength(1));
    expect(blocks.last.reason, BlockReason.tournament);
    expect(find.text('Bloqué'), findsNWidgets(3));
  });

  testWidgets('OWN-12 → « No-show » → OWN-24 → « Marquer Sarra B. absent »', (tester) async {
    await pumpApp(tester, Routes.ownerPlanning);
    await tap(tester, find.text('Aziz H.'));
    expect(find.text('Réf. MU-48160', findRichText: true), findsOneWidget);
    await tap(tester, find.text('No-show'));
    expect(find.text('Signaler un no-show'), findsOneWidget);
    expect(find.text('Sarra B.'), findsOneWidget);
    expect(find.text('Sa part reste due'), findsOneWidget);
    await tap(tester, find.text('Marquer Sarra B. absent'));
    expect(find.text('No-show signalé'), findsOneWidget);
    final b = await tester.runAsync(() => owner.booking('MU-48160'));
    expect(b!.noShows, ['Sarra B.']);
    expect(b.expected, isEmpty);
  });

  testWidgets('OWN-24 needs a player picked before confirming', (tester) async {
    await pumpApp(tester, Routes.ownerNoShow('MU-48213'));
    expect(find.text('Choisis le joueur absent'), findsOneWidget);
    await tap(tester, find.text('Rami S.'));
    expect(find.text('Marquer Rami S. absent'), findsOneWidget);
  });

  testWidgets('PRF-06 « Propriétaire de terrain » opens the owner space', (tester) async {
    await pumpApp(tester, Routes.home);
    await tap(tester, find.bySemanticsLabel(RegExp('^Mon compte')));
    await tap(tester, find.text('Changer de rôle'));
    await tap(tester, find.text('Propriétaire de terrain'));
    expect(find.byType(OwnerTodayScreen), findsOneWidget);
    expect(find.text('Check-in'), findsWidgets);
  });
}
