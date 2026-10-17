import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/features/admin/controllers/admin_controller.dart';
import 'package:matchup/features/admin/data/admin_repository.dart';
import 'package:matchup/features/explore/data/tournaments_repository.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/profile/data/profile_repository.dart';
import 'package:matchup/features/states/data/account_status.dart';
import 'package:matchup/features/venue/data/venues_repository.dart';
import 'package:matchup/router.dart';

/// Phase 14: the admin space (ADM-01 to ADM-10). Suspending Omar D. reaches his Home (STA-07);
/// bulk selection swaps the tab bar for the action bar; destructive decisions confirm first.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester, String at, {String name = 'Leila M.'}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        adminRepositoryProvider.overrideWithValue(FakeAdminRepository(latency: Duration.zero)),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(
            PlayerOnboardingState(completed: true, tourSeen: true, fullName: name),
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

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> see(WidgetTester tester, Finder finder) async {
    final list = find
        .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
        .last;
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -300), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> top(WidgetTester tester) async {
    await tester.drag(
      find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last,
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ADM-02 → ADM-03 → ADM-04: suspending Omar D. shows STA-07 on his Home', (
    tester,
  ) async {
    await pumpApp(tester, Routes.adminUsers, name: 'Omar D.');
    expect(find.text('Utilisateurs'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'Omar');
    await tester.pumpAndSettle();
    expect(find.text('Omar D.'), findsOneWidget);
    expect(find.text('Mariem K.'), findsNothing);

    await tap(tester, find.text('Omar D.'));
    expect(find.text('Fiche utilisateur'), findsOneWidget);
    expect(find.text('2 no-shows en 3 semaines'), findsOneWidget);
    await tap(tester, find.text('Suspendre'));

    // ADM-04: the dialog states the consequence before anything happens.
    expect(find.text('Suspendre Omar D. ?'), findsOneWidget);
    expect(
      find.textContaining('Jusqu’au ven. 23 oct. · 18h00 : ni partie, ni réservation.'),
      findsOneWidget,
    );
    expect(find.textContaining('Ses 2 parties à venir sont libérées'), findsOneWidget);
    await tap(tester, find.text('30 jours'));
    expect(find.textContaining('Jusqu’au dim. 15 nov.'), findsOneWidget);
    expect(find.text('Suspendre 30 jours'), findsOneWidget);
    await tap(tester, find.text('Définitif'));
    expect(find.text('Bannir Omar D. ?'), findsOneWidget);
    expect(find.textContaining('sans réinscription possible'), findsOneWidget);
    await tap(tester, find.text('7 jours'));
    expect(find.text('Suspendre 7 jours'), findsOneWidget);
    // Reason: open the select and keep « No-shows répétés ».
    await tap(tester, find.text('No-shows répétés'));
    await tap(tester, find.text('No-shows répétés').last);
    expect(container.read(suspensionsProvider), isEmpty);

    await tap(tester, find.text('Suspendre 7 jours'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final s = container.read(suspensionsProvider)['Omar D.'];
    expect(s, isNotNull);
    expect(s!.until, DateTime(2026, 10, 23, 18));
    expect(s.reason, '2 matchs manqués sans prévenir, le sam. 26 sept. et le jeu. 8 oct.');
    expect(s.refunded, 30);
    expect(s.freedGames, 2);
    // Back on ADM-02, Omar is suspended.
    await tester.pumpAndSettle();
    expect(find.text('Suspendu'), findsOneWidget);

    // Omar's Home: STA-07.
    container.read(routerProvider).go(Routes.home);
    await tester.pumpAndSettle();
    expect(find.text('Ton compte est suspendu 7 jours'), findsOneWidget);
    expect(find.text('Contester la décision'), findsOneWidget);
  });

  testWidgets('ADM-04 « Garder le compte actif » suspends nobody', (tester) async {
    await pumpApp(tester, Routes.adminUser('omar'));
    await tap(tester, find.text('Suspendre'));
    await tap(tester, find.text('Garder le compte actif'));
    expect(find.text('Suspendre Omar D. ?'), findsNothing);
    expect(find.text('Fiche utilisateur'), findsOneWidget);
    expect(container.read(suspensionsProvider), isEmpty);
  });

  testWidgets('ADM-02 bulk select: the sticky action bar replaces the tab bar', (tester) async {
    await pumpApp(tester, Routes.adminUsers);
    expect(find.text('Modération'), findsOneWidget);
    expect(find.text('Exporter'), findsNothing);

    await tap(tester, find.byTooltip('Sélectionner plusieurs utilisateurs'));
    expect(find.text('0 sélectionné'), findsOneWidget);
    expect(find.text('Exporter'), findsOneWidget);
    expect(find.text('Modération'), findsNothing);

    await tap(tester, find.text('bons.plans.tn'));
    await tap(tester, find.text('promo_crampons'));
    expect(find.text('2 sélectionnés'), findsOneWidget);
    expect(find.text('Suspendre (2)'), findsOneWidget);

    // Bulk suspension confirms with its consequence.
    await tap(tester, find.text('Suspendre (2)'));
    expect(find.text('Suspendre 2 comptes ?'), findsOneWidget);
    expect(find.textContaining('ni partie, ni réservation'), findsOneWidget);
    await tap(tester, find.text('Garder les comptes actifs'));
    expect(container.read(suspensionsProvider), isEmpty);

    await tap(tester, find.text('Annuler'));
    expect(find.text('Exporter'), findsNothing);
    expect(find.text('Modération'), findsOneWidget);

    // A long press also enters the mode, with that row selected.
    await tester.longPress(find.text('Mariem K.'));
    await tester.pumpAndSettle();
    expect(find.text('1 sélectionné'), findsOneWidget);
  });

  testWidgets('ADM-02 sort sheet and filter chips', (tester) async {
    await pumpApp(tester, Routes.adminUsers);
    await tap(tester, find.text('À traiter d’abord'));
    expect(find.text('Trier les utilisateurs'), findsOneWidget);
    await tap(tester, find.text('Nom (A → Z)'));
    await tap(tester, find.text('Appliquer'));
    expect(find.text('Nom (A → Z)'), findsOneWidget);
    await tap(tester, find.text('Signalés'));
    expect(find.text('Mariem K.'), findsNothing);
    expect(find.text('Omar D.'), findsOneWidget);
  });

  test('applyUserQuery: « À traiter d’abord », reliability and new accounts', () async {
    final users = await FakeAdminRepository(latency: Duration.zero).users();
    final first = applyUserQuery(users, const AdminUserQuery(), storyNow);
    expect(first.take(3).map((u) => u.name), ['bons.plans.tn', 'promo_crampons', 'Omar D.']);
    final reliable = applyUserQuery(
      users,
      const AdminUserQuery(sort: AdminUserSort.reliability),
      storyNow,
    );
    expect(reliable.first.name, 'Omar D.');
    final fresh = applyUserQuery(users, const AdminUserQuery(newOnly: true), storyNow);
    expect(fresh.map((u) => u.name), ['bons.plans.tn', 'promo_crampons']);
    final byPhone = applyUserQuery(users, const AdminUserQuery(text: '22 456'), storyNow);
    expect(byPhone.single.name, 'Omar D.');
  });

  testWidgets('ADM-10: a destructive decision asks for confirmation first', (tester) async {
    await pumpApp(tester, Routes.adminModeration);
    expect(find.text('7 contenus'), findsOneWidget);
    await tap(tester, find.textContaining('T’as jamais mis les pieds'));
    expect(find.text('Revoir le commentaire'), findsOneWidget);
    expect(find.textContaining('1er avertissement pour Yassine B.'), findsOneWidget);

    await tap(tester, find.text('Supprimer et avertir'));
    expect(find.text('Supprimer et avertir Yassine B. ?'), findsOneWidget);
    await tap(tester, find.text('Annuler'));
    expect(find.text('Supprimer et avertir Yassine B. ?'), findsNothing);
    expect(find.text('Revoir le commentaire'), findsOneWidget);
    expect(container.read(adminModerationProvider).value, hasLength(7));

    await tap(tester, find.text('Supprimer et avertir'));
    await tap(tester, find.text('Supprimer et avertir').last);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.text('Revoir le commentaire'), findsNothing);
    await top(tester);
    expect(find.text('6 contenus'), findsOneWidget);
  });

  testWidgets('ADM-10 « Suspendre l’auteur » goes through ADM-04', (tester) async {
    await pumpApp(tester, Routes.adminModeration);
    await tap(tester, find.textContaining('T’as jamais mis les pieds'));
    await tap(tester, find.text('Suspendre l’auteur'));
    await tap(tester, find.text('Choisir la durée'));
    expect(find.text('Suspendre Yassine B. ?'), findsOneWidget);
    await tap(tester, find.text('24 h'));
    await tap(tester, find.text('Suspendre 24 h'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(container.read(suspensionsProvider)['Yassine B.']?.until, DateTime(2026, 10, 17, 18));
    await top(tester);
    expect(find.text('6 contenus'), findsOneWidget);
  });

  testWidgets('Admin tabs: Vue, Vérifications, Finance → ADM-07 and ADM-08', (tester) async {
    await pumpApp(tester, Routes.adminOverview);
    expect(find.text('Vue d’ensemble'), findsOneWidget);
    expect(find.text('Bonjour Leila · ven. 16 oct. · 18h00'), findsOneWidget);
    await see(tester, find.text('Réservations par sport'));
    await see(tester, find.text('3 abonnés Premium à risque'));

    await tap(tester, find.text('Vérifications').last);
    expect(find.text('3 demandes · la plus ancienne : lun. 12 oct.'), findsOneWidget);
    await tap(tester, find.text('Approuver').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    await top(tester);
    expect(find.text('2 demandes · la plus ancienne : lun. 12 oct.'), findsOneWidget);

    await tap(tester, find.text('Finance').last);
    expect(find.text('Au ven. 16 oct. · 18h00 · toutes les villes'), findsOneWidget);
    await see(tester, find.text('D’où vient l’argent'));
    expect(find.text('81 %'), findsOneWidget);

    await top(tester);
    await tap(tester, find.text('Versements et remboursements'));
    expect(find.text('3 sélectionnés'), findsOneWidget);
    await tap(tester, find.text('Valider 3 versements'));
    expect(find.text('Valider 3 versements ?'), findsOneWidget);
    await tap(tester, find.text('Pas maintenant'));
    await tap(tester, find.text('Arena Five'));
    expect(find.text('2 sélectionnés'), findsOneWidget);
    expect(find.text('Valider 2 versements'), findsOneWidget);

    await tap(tester, find.byTooltip('Retour à Finance'));
    await tap(tester, find.text('Risque de churn'));
    expect(find.text('3 abonnés pourraient partir'), findsOneWidget);
    await tap(tester, find.text('Ignorer'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    await top(tester);
    expect(find.text('2 abonnés pourraient partir'), findsOneWidget);
  });

  testWidgets('The role switcher lists the admin space', (tester) async {
    await pumpApp(tester, Routes.adminOverview);
    await tap(tester, find.text('LM'));
    expect(find.text('Admin MatchUp'), findsOneWidget);
  });
}
