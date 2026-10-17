import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/features/owner/data/owner_drafts.dart';
import 'package:matchup/features/owner/data/owner_repository.dart';
import 'package:matchup/features/owner/data/revenue_repository.dart';
import 'package:matchup/features/owner/data/review_highlights.dart';
import 'package:matchup/features/owner/screens/prices_screen.dart';
import 'package:matchup/features/owner/screens/revenue_screen.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

/// Phase 13: the owner's « Aujourd’hui » (OWN-10) and « Revenus » (OWN-25).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late ProviderContainer container;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
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
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(
            const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Skander T.'),
          ),
        ),
        ownerRepositoryProvider.overrideWithValue(FakeOwnerRepository(latency: Duration.zero)),
        ownerRevenueRepositoryProvider.overrideWithValue(
          FakeOwnerRevenueRepository(latency: Duration.zero),
        ),
        reviewHighlightsRepositoryProvider.overrideWithValue(
          FakeReviewHighlightsRepository(latency: Duration.zero),
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

  const insight = 'Jeudi 14h–17h : 80 % de créneaux vides. Proposer −20 % ?';

  testWidgets('OWN-10 shows the day: KPIs, next arrival, programme, payout, reviews', (
    tester,
  ) async {
    await pumpApp(tester, Routes.ownerToday);
    expect(find.text('Aujourd’hui'), findsWidgets);
    for (final label in ['Taux d’occupation', 'Revenus du jour', 'No-shows']) {
      expect(find.text(label), findsOneWidget);
    }
    // « Réservations » is also a tab.
    expect(find.text('Réservations'), findsNWidgets(2));
    expect(find.text('78 %'), findsOneWidget);
    expect(find.text('1 140'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('+6 pts'), findsOneWidget);
    expect(find.text('Prochaine arrivée · 19h00'), findsOneWidget);
    expect(find.text('Salma G. · Terrain 1'), findsOneWidget);
    expect(find.text('Maintenant'), findsOneWidget);
    expect(find.text('Hamza R.'), findsOneWidget);
    expect(find.text('Personne au check-in'), findsOneWidget);
    expect(find.text('Nettoyage du terrain indoor'), findsOneWidget);
    expect(find.text('Libre'), findsOneWidget);
    expect(find.text('8 réservations · 1 créneau libre'), findsOneWidget);
    expect(find.text('2 paiements en attente'), findsOneWidget);
    expect(find.text(insight), findsOneWidget);
    expect(find.text('Versement prévu vers le lun. 19 oct.'), findsOneWidget);
    expect(
      find.text(
        '« Vestiaires à rafraîchir, l’eau chaude manquait après 21h. '
        'Le terrain reste top. »',
      ),
      findsOneWidget,
    );
    expect(find.text('Sans réponse'), findsOneWidget);
  });

  testWidgets('OWN-10 « Appliquer » opens OWN-16 with the promo, nothing applied', (tester) async {
    await pumpApp(tester, Routes.ownerToday);
    await tap(tester, find.text('Appliquer'));
    final prices = tester.widget<OwnerPricesScreen>(find.byType(OwnerPricesScreen));
    expect(prices.promo, same(PromoDraft.thursdayAfternoon));
  });

  testWidgets('OWN-10 « Ignorer » hides the insight', (tester) async {
    await pumpApp(tester, Routes.ownerToday);
    expect(find.text(insight), findsOneWidget);
    await tap(tester, find.text('Ignorer'));
    expect(find.text(insight), findsNothing);
    expect(find.text('Appliquer'), findsNothing);
  });

  testWidgets('OWN-10 payout card → OWN-25 with its chart', (tester) async {
    await pumpApp(tester, Routes.ownerToday);
    await tap(tester, find.text('Versement prévu vers le lun. 19 oct.'));
    expect(find.byType(OwnerRevenueScreen), findsOneWidget);
    expect(find.byType(MuLineChart), findsOneWidget);
    expect(find.text('Revenus par jour'), findsOneWidget);
  });

  testWidgets('OWN-25 renders the payout, KPIs, chart and payouts; period switches', (
    tester,
  ) async {
    await pumpApp(tester, Routes.ownerRevenue);
    expect(find.text('Revenus'), findsOneWidget);
    expect(find.textContaining('1 410', findRichText: true), findsWidgets);
    expect(find.text('Revenus · 30 j'), findsOneWidget);
    expect(find.text('26 740'), findsOneWidget);
    expect(find.text('312'), findsOneWidget);
    expect(find.byType(MuLineChart), findsOneWidget);
    expect(find.text('Revenus par jour'), findsOneWidget);
    expect(find.text('18 sept.'), findsOneWidget);
    expect(find.text('16 oct.'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('D’où viennent'), 200);
    expect(find.text('D’où viennent les 26 740 DT'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Versé · lun. 12 oct.'), 200);
    await settle(tester);
    expect(find.text('Prévu · lun. 19 oct.'), findsOneWidget);
    expect(find.text('VR-2026-0412 · •••• 1234'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Compte de versement'), 200);
    await settle(tester);
    expect(find.text('Télécharger le relevé d’octobre'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('12 mois'), -200);
    await tap(tester, find.text('12 mois'));
    expect(find.text('Revenus · 12 mois'), findsOneWidget);
    expect(find.text('Revenus par mois'), findsOneWidget);
  });
}
