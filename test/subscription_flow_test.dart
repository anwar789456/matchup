import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/features/payments/data/payment_repository.dart';
import 'package:matchup/features/payments/data/receipt_pdf.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/subscription/data/subscription_repository.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

/// Phase 10: subscribe (SUB-01 → SUB-02 → SUB-03), change to yearly (SUB-05), cancel (SUB-06 →
/// SUB-07 → SUB-08), reactivate, the retention offer and the A4 receipt (SUB-09).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeSubscriptionRepository subs;

  Future<void> pumpApp(
    WidgetTester tester,
    String at, {
    PremiumStatus initial = PremiumStatus.free,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    subs = FakeSubscriptionRepository(latency: Duration.zero, initial: initial);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(
            const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.'),
          ),
        ),
        subscriptionRepositoryProvider.overrideWithValue(subs),
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository(latency: Duration.zero)),
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

  testWidgets('subscribe: SUB-01 annuel → SUB-02 consent → SUB-03 → SUB-04', (tester) async {
    await pumpApp(tester, Routes.subscriptionOffers);
    expect(find.text('Joue plus. Progresse plus vite.'), findsOneWidget);
    await tap(tester, find.text('Annuel'));
    await see(tester, find.text('Ton offre actuelle'));
    await see(tester, find.text('Compare Gratuit et Premium'));
    await see(tester, find.text('Comment je résilie ?'));
    await tap(tester, find.text('Comment je résilie ?'));
    expect(find.textContaining('sans appel ni frais'), findsOneWidget);
    expect(find.textContaining('puis 190 DT/an dès le ven. 30 oct.'), findsOneWidget);
    await tap(tester, find.text('Essayer Premium gratuitement'));

    // SUB-02: nothing starts without the consent.
    expect(find.text('Démarre ton essai Premium'), findsOneWidget);
    await tap(tester, find.widgetWithText(MuButton, 'Commencer l’essai gratuit'));
    await see(tester, find.text('Coche cette case pour démarrer l’essai.'));
    await tap(tester, find.byType(MuCheckbox));
    await tap(tester, find.widgetWithText(MuButton, 'Commencer l’essai gratuit'));

    // SUB-03.
    expect(find.text('Bienvenue dans Premium, Yassine !'), findsOneWidget);
    expect(find.text('Essai activé'), findsOneWidget);
    await tap(tester, find.text('Gérer mon abonnement'));

    // SUB-04.
    expect(find.text('14 jours d’essai restants'), findsOneWidget);
    expect(find.text('Joueur · annuel'), findsOneWidget);
    expect((await subs.current()).status, PremiumStatus.trial);
    expect(tester.takeException(), isNull);
  });

  testWidgets('change to yearly: SUB-04 → SUB-05 « Passer à l’annuel »', (tester) async {
    await pumpApp(tester, Routes.subscription, initial: PremiumStatus.trial);
    expect(find.text('Joueur · mensuel'), findsOneWidget);
    await tap(tester, find.text('Changer d’offre'));
    expect(find.text('Mensuel ou annuel ?'), findsOneWidget);
    expect(find.text('Ce que tu paieras avec l’annuel'), findsOneWidget);
    expect(find.text('Tu économises 38 DT par an'), findsOneWidget);
    await tester.tap(find.text('Passer à l’annuel'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Joueur · annuel'), findsOneWidget);
    expect((await subs.current()).period, MuBillingPeriod.year);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('cancel: SUB-06 → SUB-07 « Non merci, résilier » → SUB-08 → reactivate', (
    tester,
  ) async {
    await pumpApp(tester, Routes.subscription, initial: PremiumStatus.trial);
    await see(tester, find.text('Résilier l’abonnement'));
    await tap(tester, find.text('Résilier l’abonnement'));
    expect(find.text('Pourquoi tu veux résilier ?'), findsOneWidget);
    expect(find.textContaining('Étape 1 sur 2', findRichText: true), findsWidgets);
    await tap(tester, find.text('Continuer'));

    // SUB-07: both answers the same size.
    expect(find.text('Une dernière option'), findsOneWidget);
    expect(find.textContaining('Tu as répondu « Trop cher »'), findsOneWidget);
    final offer = tester.getSize(find.widgetWithText(MuButton, 'Accepter l’offre'));
    final no = tester.getSize(find.widgetWithText(MuButton, 'Non merci, résilier'));
    expect(offer, no);
    await tap(tester, find.text('Non merci, résilier'));

    // SUB-08.
    expect(find.text('Résiliation confirmée'), findsOneWidget);
    expect((await subs.current()).status, PremiumStatus.cancelled);
    await tap(tester, find.text('Réactiver Premium'));
    expect(find.text('Essai gratuit'), findsWidgets);
    expect((await subs.current()).status, PremiumStatus.trial);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retention offer: « Accepter l’offre » keeps Premium at 13,300 DT', (tester) async {
    await pumpApp(tester, Routes.subscriptionRetention, initial: PremiumStatus.trial);
    await tester.tap(find.text('Accepter l’offre'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Offre activée'), findsOneWidget);
    expect(find.text('13,300 DT · ven. 30 oct.'), findsOneWidget);
    expect((await subs.current()).offerAccepted, isTrue);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('SUB-09: the receipt is a real A4 PDF', (tester) async {
    final receipts = await FakeSubscriptionRepository(latency: Duration.zero).receipts();
    final bytes = await tester.runAsync(
      () => buildReceiptPdf(
        receipts.first,
        const ReceiptClient(
          name: 'Yassine Belhaj',
          city: 'La Marsa, Tunisie',
          email: 'yassine.b@email.tn',
          phone: '+216 20 123 456',
        ),
      ),
    );
    expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(10000));
  });
}
