import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/format.dart';
import 'package:matchup/features/explore/data/tournaments_repository.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/payments/data/payment_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/venue/data/venues_repository.dart';
import 'package:matchup/features/wallet/data/wallet_repository.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

/// Phase 9: every outcome of the debug menu through the checkout (PAY-01 to PAY-10), the wallet
/// top-up (WAL-02/03 → WAL-01) and the refund request (WAL-04 → WAL-05).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late ProviderContainer container;
  late FakeGamesRepository games;

  Future<void> pumpApp(WidgetTester tester, String at) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    games = FakeGamesRepository(latency: Duration.zero);
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(
            const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.'),
          ),
        ),
        bookingsRepositoryProvider.overrideWithValue(
          FakeBookingsRepository(latency: Duration.zero),
        ),
        gamesRepositoryProvider.overrideWithValue(games),
        venuesRepositoryProvider.overrideWithValue(FakeVenuesRepository(latency: Duration.zero)),
        tournamentsRepositoryProvider.overrideWithValue(
          FakeTournamentsRepository(latency: Duration.zero),
        ),
        walletRepositoryProvider.overrideWithValue(FakeWalletRepository(latency: Duration.zero)),
        // The debug menu's outcome drives the fake, as in the app.
        paymentRepositoryProvider.overrideWith(
          (ref) => FakePaymentRepository(
            latency: Duration.zero,
            outcome: () => ref.read(paymentOutcomeProvider),
          ),
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

  void outcome(PaymentOutcome o) => container.read(paymentOutcomeProvider.notifier).select(o);

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

  /// Taps and lets the fakes answer without settling, so a toast is still on screen.
  Future<void> tapQuick(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Finder payButton() => find.widgetWithText(MuButton, 'Payer');

  /// GAM-01 G1 « Rejoindre et payer » → PAY-01 with the terms accepted.
  Future<void> openCheckout(WidgetTester tester) async {
    await pumpApp(tester, Routes.game('g1'));
    await tap(tester, find.text('Rejoindre et payer'));
    expect(find.text('Paiement'), findsWidgets);
    expect(find.text('Arena Five · Terrain 2'), findsOneWidget);
    await see(tester, find.byType(MuCheckbox));
    await tap(tester, find.byType(MuCheckbox));
  }

  testWidgets('succès: PAY-01 → PAY-09 → « Terminé » → GAM-05, the payment in WAL-01', (
    tester,
  ) async {
    await openCheckout(tester);
    await tap(tester, payButton());
    expect(find.text('Paiement réussi'), findsOneWidget);
    expect(find.text('Visa •••• 4242'), findsOneWidget);
    await tap(tester, find.text('Terminé'));
    expect(find.text('Tu es dans la partie !'), findsOneWidget);
    final joined = await tester.runAsync(games.joined);
    expect(joined!.map((g) => g.id), ['g1']);

    container.read(routerProvider).go(Routes.wallet);
    await tester.pumpAndSettle();
    expect(find.text('Part · Arena Five'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3-D Secure: the bank takeover (PAY-07) « Valider » → PAY-09', (tester) async {
    await openCheckout(tester);
    outcome(PaymentOutcome.threeDSecure);
    await tap(tester, payButton());
    expect(find.text('Confirme ce paiement'), findsOneWidget);
    await tap(tester, find.text('Valider'));
    expect(find.text('Paiement réussi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refusée ×3: a toast each time, then PAY-10', (tester) async {
    await openCheckout(tester);
    outcome(PaymentOutcome.declined);
    await tapQuick(tester, payButton());
    expect(find.text('Paiement refusé'), findsOneWidget);
    expect(find.textContaining('fonds insuffisants'), findsWidgets);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tap(tester, payButton());
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tap(tester, payButton());
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Le paiement a échoué'), findsOneWidget);
    expect(find.text('Changer de moyen de paiement'), findsOneWidget);
    // Back to the checkout, nothing joined.
    await tap(tester, find.text('Changer de moyen de paiement'));
    expect(payButton(), findsOneWidget);
    final joined = await tester.runAsync(games.joined);
    expect(joined, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erreur réseau: PAY-08 « Vérifier le statut », then « Réessayer » succeeds', (
    tester,
  ) async {
    await openCheckout(tester);
    outcome(PaymentOutcome.networkError);
    await tap(tester, payButton());
    expect(find.text('Connexion perdue pendant le paiement'), findsOneWidget);
    expect(find.text('À vérifier'), findsOneWidget);
    await tapQuick(tester, find.text('Vérifier le statut'));
    expect(find.text('Ta part n’est pas passée'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    outcome(PaymentOutcome.success);
    await tap(tester, find.text('Réessayer'));
    expect(find.text('Paiement réussi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('délai dépassé: the timeout variant of PAY-08', (tester) async {
    await openCheckout(tester);
    outcome(PaymentOutcome.timeout);
    await tap(tester, payButton());
    expect(find.text('Ta banque met trop de temps à répondre'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recharge 50 DT: WAL-02 → checkout → WAL-01 at 80 DT with a « Recharge » line', (
    tester,
  ) async {
    await pumpApp(tester, Routes.wallet);
    expect(find.text('Portefeuille'), findsWidgets);
    expect(find.text('${formatAmount(30)} DT', findRichText: true), findsOneWidget);
    await tap(tester, find.text('Recharger'));
    expect(find.text('Combien veux-tu ajouter ?'), findsOneWidget);
    await tap(tester, find.widgetWithText(MuButton, 'Continuer'));
    await see(tester, find.byType(MuCheckbox));
    await tap(tester, find.byType(MuCheckbox));
    await tap(tester, payButton());
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Portefeuille'), findsWidgets);
    expect(find.text('${formatAmount(80)} DT', findRichText: true), findsOneWidget);
    await see(tester, find.text('Recharge').first);
    expect(find.text('Recharge'), findsWidgets);
    final history = await tester.runAsync(container.read(walletRepositoryProvider).history);
    expect(history!.first.kind, MuTransactionKind.topup);
    expect(history.first.amount, 50);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remboursement: WAL-04 → « Envoyer la demande » → WAL-05', (tester) async {
    await pumpApp(tester, Routes.wallet);
    await see(tester, find.text('Demander un remboursement'));
    await tap(tester, find.text('Demander un remboursement'));
    // The last card payment: Arena Five, sam. 3 oct.
    await tap(tester, find.text('sam. 3 oct. · Carte •••• 4242'));
    await see(tester, find.text('Terrain fermé'));
    await tap(tester, find.text('Terrain fermé'));
    await tap(tester, find.text('Envoyer la demande'));
    expect(find.text('Suivi du remboursement'), findsOneWidget);
    expect(find.text('Où en est ta demande ?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
