import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/features/owner/data/clients_repository.dart';
import 'package:matchup/features/owner/data/owner_drafts.dart';
import 'package:matchup/features/owner/data/owner_repository.dart';
import 'package:matchup/features/owner/data/reviews_repository.dart';
import 'package:matchup/features/owner/data/tariffs_repository.dart';
import 'package:matchup/features/owner/screens/bookings_screen.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

/// Phase 13, owner « Plus »: OWN-15 rows, OWN-16 with the AI promo (nothing saved before
/// « Enregistrer les tarifs »), OWN-14 search and filters, OWN-17 visibility, OWN-18 search,
/// OWN-19 reply.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late ProviderContainer container;
  late FakeTariffsRepository tariffs;
  late FakeReviewsRepository reviews;
  late FakeOwnerRepository owner;

  GoRouter router() => container.read(routerProvider);
  String path() {
    final config = router().routerDelegate.currentConfiguration;
    final last = config.last;
    return last is ImperativeRouteMatch ? last.matches.uri.path : config.uri.path;
  }

  // Toasts and snackbars run timers: pump instead of settling.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpApp(WidgetTester tester, String at, {Object? extra}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tariffs = FakeTariffsRepository(latency: Duration.zero);
    reviews = FakeReviewsRepository(latency: Duration.zero, clock: () => storyNow);
    owner = FakeOwnerRepository(latency: Duration.zero);
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(
            const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.'),
          ),
        ),
        ownerRepositoryProvider.overrideWithValue(owner),
        tariffsRepositoryProvider.overrideWithValue(tariffs),
        reviewsRepositoryProvider.overrideWithValue(reviews),
        clientsRepositoryProvider.overrideWithValue(FakeClientsRepository(latency: Duration.zero)),
      ],
    );
    addTearDown(container.dispose);
    router().go(at, extra: extra);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MatchUpApp()),
    );
    await settle(tester);
  }

  /// Scrolls the page's list until [finder] is built, then into view.
  Future<void> see(WidgetTester tester, Finder finder, {bool up = false}) async {
    final list = find.byType(ListView).first;
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, Offset(0, up ? 300 : -300), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('OWN-15: every row opens its screen', (tester) async {
    await pumpApp(tester, Routes.ownerMore);
    expect(find.text('Plan Pro · essai gratuit'), findsOneWidget);
    expect(find.text('3 terrains'), findsOneWidget);
    expect(find.text('4,7 · 128 avis'), findsOneWidget);

    final rows = {
      'Terrains': Routes.ownerCourtList,
      'Tarifs': Routes.ownerTariffs,
      'Clients': Routes.ownerClients,
      'Avis': Routes.ownerReviews,
      'Revenus': Routes.ownerRevenue,
      'Paramètres': Routes.settings,
    };
    for (final MapEntry(key: title, value: route) in rows.entries) {
      await tap(tester, find.widgetWithText(MuSettingsRow, title));
      expect(path(), route, reason: title);
      router().go(Routes.ownerMore);
      await settle(tester);
    }

    await tap(tester, find.widgetWithText(MuSettingsRow, 'Changer de rôle'));
    expect(find.byType(MuRoleSwitcher), findsOneWidget);
  });

  testWidgets('OWN-16: the AI promo opens filled in and is only saved with « Enregistrer »', (
    tester,
  ) async {
    await pumpApp(tester, Routes.ownerTariffs, extra: PromoDraft.thursdayAfternoon);
    final promo = find.text('Jeudi 14h00 – 17h00 · −20 %');
    await see(tester, promo);
    expect(promo, findsOneWidget);
    expect(find.text('À confirmer'), findsOneWidget);
    expect(find.text('120 DT'), findsWidgets);
    expect(find.text('96 DT'), findsWidgets);
    expect(find.text('Jeu. 22 oct.'), findsWidgets);
    expect(find.text('Tous les jeudis'), findsOneWidget);
    expect(tariffs.saves, 0);

    // Leaving discards it.
    await tap(tester, find.bySemanticsLabel('Retour'));
    expect(path(), Routes.ownerMore);
    expect(tariffs.saves, 0);
    expect((await tester.runAsync(tariffs.load))!.promos, isEmpty);

    // Back from OWN-10 « Appliquer »: still nothing until « Enregistrer les tarifs ».
    router().push(Routes.ownerTariffs, extra: PromoDraft.thursdayAfternoon);
    await settle(tester);
    expect(tariffs.saves, 0);
    await tap(tester, find.text('Enregistrer les tarifs'));
    expect(tariffs.saves, 1);
    final saved = (await tester.runAsync(tariffs.load))!.promos;
    expect(saved, hasLength(1));
    expect(saved.single.draft.percent, 20);
    expect(saved.single.firstDay, DateTime(2026, 10, 22));
    expect(find.text('Tarifs enregistrés'), findsOneWidget);
    expect(path(), Routes.ownerMore);
  });

  testWidgets('OWN-16: an edited price is saved with the list', (tester) async {
    await pumpApp(tester, Routes.ownerTariffs);
    expect(find.text('Jeudi 14h00 – 17h00 · −20 %'), findsNothing);
    final peak = find.widgetWithText(MuTextField, 'Pointe').first;
    await tester.enterText(find.descendant(of: peak, matching: find.byType(EditableText)), '160');
    await settle(tester);
    expect(find.text('soit 16 DT /pers.'), findsOneWidget);
    expect(tariffs.saves, 0);
    await tap(tester, find.text('Enregistrer les tarifs'));
    expect((await tester.runAsync(tariffs.load))!.prices.first.peak, 160);
  });

  testWidgets('OWN-14: search and filters work on the bookings', (tester) async {
    await pumpApp(tester, Routes.ownerBookings);
    expect(find.text('CE SOIR · VEN. 16 OCT.'), findsOneWidget);
    expect(find.text('10 à venir'), findsOneWidget);
    expect(find.text('Salma G.'), findsOneWidget);
    expect(find.text('Voir les 6 autres de ce soir'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, 'yassine');
    await settle(tester);
    expect(find.byType(OwnerBookingRow), findsOneWidget);
    expect(find.text('Yassine B.'), findsOneWidget);
    expect(find.text('Salma G.'), findsNothing);

    await tester.enterText(find.byType(EditableText).first, 'MU-48196');
    await settle(tester);
    expect(find.byType(OwnerBookingRow), findsOneWidget);
    expect(find.text('Ines M.'), findsOneWidget);
    expect(find.text('9/10 payé'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, '');
    await settle(tester);
    await tap(tester, find.widgetWithText(MuChip, 'No-shows'));
    expect(find.text('Rami S.'), findsOneWidget);
    expect(find.text('No-show'), findsOneWidget);

    await tap(tester, find.widgetWithText(MuChip, 'À venir'));
    await tap(tester, find.text('Salma G.'));
    expect(path(), Routes.ownerBooking('MU-48190'));
  });

  testWidgets('OWN-17: hiding a court persists', (tester) async {
    await pumpApp(tester, Routes.ownerCourtList);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('Entretien du gazon'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Terrain 1 visible et réservable'));
    expect((await tester.runAsync(owner.courts))!.first.visible, isFalse);
    expect(find.text('Masqué'), findsOneWidget);
    await see(tester, find.text('2'), up: true);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('OWN-18: search and filters on the clients', (tester) async {
    await pumpApp(tester, Routes.ownerClients);
    expect(find.text('Créneau préféré'), findsOneWidget);
    await tap(tester, find.widgetWithText(MuChip, 'Avec no-show'));
    expect(find.text('Omar D.'), findsOneWidget);
    expect(find.text('Aziz H.'), findsOneWidget);
    expect(find.text('Nour A.'), findsNothing);
    await tap(tester, find.widgetWithText(MuChip, 'Tous'));
    await tester.enterText(find.byType(EditableText).first, 'MU-48213');
    await settle(tester);
    expect(find.text('Yassine B.'), findsOneWidget);
    expect(find.text('Hamza R.'), findsNothing);
  });

  testWidgets('OWN-19: replying to Omar publishes the reply', (tester) async {
    await pumpApp(tester, Routes.ownerReviews);
    expect(find.text('Mariem K.'), findsOneWidget);
    expect(find.textContaining('Gazon impeccable'), findsOneWidget);
    expect(find.text('Sans réponse'), findsWidgets);
    expect(find.text('Ta réponse publique'), findsOneWidget);

    await tap(tester, find.text('Publier la réponse'));
    final omar = (await tester.runAsync(reviews.reviews))!.latest
        .firstWhere((r) => r.author == 'Omar D.');
    expect(omar.answered, isTrue);
    expect(omar.reply, startsWith('Merci Omar pour ton retour'));
    expect(find.text('Ta réponse publique'), findsNothing);
    expect(find.text('Répondu'), findsOneWidget);
    expect(find.text('Arena Five · à l’instant'), findsOneWidget);
  });
}
