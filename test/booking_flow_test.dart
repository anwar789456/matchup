import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/format.dart';
import 'package:matchup/features/booking/data/payment_repository.dart';
import 'package:matchup/features/explore/data/tournaments_repository.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/venue/data/venues_repository.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeBookingsRepository bookings;
  late FakeGamesRepository games;

  Future<void> pumpApp(WidgetTester tester, String at) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    bookings = FakeBookingsRepository(latency: Duration.zero);
    games = FakeGamesRepository(latency: Duration.zero);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(
            const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.'),
          ),
        ),
        bookingsRepositoryProvider.overrideWithValue(bookings),
        gamesRepositoryProvider.overrideWithValue(games),
        venuesRepositoryProvider.overrideWithValue(FakeVenuesRepository(latency: Duration.zero)),
        tournamentsRepositoryProvider.overrideWithValue(
          FakeTournamentsRepository(latency: Duration.zero),
        ),
        paymentRepositoryProvider.overrideWithValue(
          FakePaymentRepository(latency: Duration.zero),
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

  /// Scrolls the page's list until [finder] is built and visible.
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

  /// VEN-01 → mer. 21 oct. → Terrain 1 at 20h00 → VEN-02 → « Continuer » (BKG-01).
  Future<void> pickSlot(WidgetTester tester) async {
    await pumpApp(tester, Routes.venue('arena-five'));
    expect(find.text('Arena Five'), findsWidgets);
    expect(find.text('Choisis ton créneau'), findsOneWidget);
    await tap(tester, find.descendant(of: find.byType(MuDateStrip), matching: find.text('21')));
    expect(find.text('Mer. 21 oct. · 20h00 – 00h00'), findsOneWidget);
    // Terrain 1 at 21h00 is MU-48213, already Yassine's.
    expect(find.text('Toi'), findsOneWidget);
    await tap(
      tester,
      find.descendant(of: find.byType(MuSlotGrid), matching: find.text(formatDT(150))).first,
    );
    await tap(tester, find.text('Réserver'));
    expect(find.text('Mer. 21 oct. · 20h00'), findsOneWidget);
    expect(find.text('à 10 joueurs'), findsOneWidget);
    await tap(tester, find.text('Continuer'));
    expect(find.text('Qui joue avec toi ?'), findsOneWidget);
    expect(find.text('Arena Five · Terrain 1'), findsOneWidget);
  }

  testWidgets('public game: places to fill drive the share, then pay my share', (tester) async {
    await pickSlot(tester);
    await tap(tester, find.text('Continuer'));

    // BKG-02: the regular teammates are invited, 4 places to fill, 15 DT each.
    expect(find.text('Complète ton équipe'), findsOneWidget);
    expect(find.text('Déjà 6 joueurs'), findsOneWidget);
    expect(find.text('10 joueurs · ${formatDT(15)} chacun'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Retirer une place'));
    expect(find.text('9 joueurs · ${formatDT(150 / 9)} chacun'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Ajouter une place'));
    await tap(tester, find.text('Continuer'));

    // BKG-04.
    expect(find.text('Vérifie et paie ta part'), findsOneWidget);
    expect(find.text('Chacun paie sa part · ${formatDT(15)}'), findsOneWidget);
    expect(find.text('6/10 · 4 places'), findsOneWidget);
    await see(tester, find.text('Gratuit jusqu’au mar. 20 oct. · 20h00'));
    await tap(tester, find.text('Payer ma part'));

    // PAY-01 → PAY-09 (reçu, billet, « Encore 4 places »), saved and listed in Explorer.
    expect(find.text('Ta part · réservation MU-48214'.toUpperCase()), findsOneWidget);
    await see(tester, find.byType(MuCheckbox));
    await tap(tester, find.byType(MuCheckbox));
    await tap(tester, find.widgetWithText(MuButton, 'Payer'));
    expect(find.text('Paiement réussi'), findsOneWidget);
    expect(find.text('MU-48214'), findsWidgets);
    await see(tester, find.text('Encore 4 places'));
    expect(find.text('Ta partie publique est visible dans Explorer.'), findsOneWidget);
    // The fakes wait on the fake clock: read them outside it.
    final upcoming = await tester.runAsync(bookings.upcoming);
    expect(upcoming!.bookings.map((b) => b.id), contains('MU-48214'));
    final open = await tester.runAsync(games.openGames);
    expect(open!.map((g) => g.id), contains('MU-48214'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('private game: invites, then I pay all with my balance', (tester) async {
    await pickSlot(tester);
    await tap(tester, find.text('Privée'));
    await tap(tester, find.text('Continuer · inviter mes amis'));

    // BKG-03.
    expect(find.text('Invite tes amis'), findsOneWidget);
    expect(find.text('5 amis invités'), findsOneWidget);
    expect(find.text('Il reste 4 places sur 10'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Inviter Nour A.'));
    expect(find.text('Inviter 4 amis et continuer'), findsOneWidget);
    await tap(tester, find.text('Inviter 4 amis et continuer'));

    // BKG-04: the whole court, 30 DT from the balance.
    await tap(tester, find.text('Je paie tout · ${formatDT(150)}'));
    await tap(tester, find.text('Utiliser mon solde MatchUp'));
    await see(tester, find.text('−${formatDT(30)}'));
    expect(find.text('Payer le terrain'), findsOneWidget);
    await tap(tester, find.text('Payer le terrain'));

    // PAY-01: the balance is offered again in the checkout; card pays the whole court.
    await see(tester, find.byType(MuCheckbox));
    await tap(tester, find.byType(MuCheckbox));
    await tap(tester, find.widgetWithText(MuButton, 'Payer'));
    expect(find.text('Paiement réussi'), findsOneWidget);
    await tap(tester, find.text('Terminé'));
    // MAT-05 of the new booking.
    expect(find.textContaining('MU-48214', findRichText: true), findsWidgets);
    final open = await tester.runAsync(games.openGames);
    expect(open!.map((g) => g.id), isNot(contains('MU-48214')));
    expect(tester.takeException(), isNull);
  });
}
