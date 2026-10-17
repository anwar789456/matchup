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

/// « Mes matchs » with nothing ahead (MAT-04).
class _EmptyBookings extends FakeBookingsRepository {
  _EmptyBookings() : super(latency: Duration.zero);

  @override
  Future<UpcomingMatches> upcoming() async =>
      const UpcomingMatches(invitations: [], bookings: []);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeBookingsRepository bookings;
  late FakeGamesRepository games;

  Future<void> pumpApp(WidgetTester tester, String at, {BookingsRepository? repo}) async {
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
        bookingsRepositoryProvider.overrideWithValue(repo ?? bookings),
        gamesRepositoryProvider.overrideWithValue(games),
        venuesRepositoryProvider.overrideWithValue(FakeVenuesRepository(latency: Duration.zero)),
        tournamentsRepositoryProvider.overrideWithValue(
          FakeTournamentsRepository(latency: Duration.zero),
        ),
        paymentRepositoryProvider.overrideWithValue(
          const FakePaymentRepository(latency: Duration.zero),
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

  /// Taps and lets the fakes answer without settling, so a toast is still on screen.
  Future<void> tapQuick(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('GAM-01 → join G1 → GAM-05 → Mes matchs « Tu joues » → MAT-07 leave', (
    tester,
  ) async {
    await pumpApp(tester, Routes.game('g1'));
    expect(find.text('Arena Five · Terrain 2'), findsOneWidget);
    expect(find.text('8/10 joueurs'), findsOneWidget);
    expect(find.text('Pourquoi pour toi'), findsOneWidget);
    expect(find.text('Touche un « + » pour choisir ton poste'), findsOneWidget);
    await see(tester, find.text('Chasubles fournies : Blancs contre Bleus. Il nous manque un milieu !'));
    await see(tester, find.text('Annulation gratuite'));
    expect(find.text('Remboursé sur ton solde MatchUp, en entier si Skander annule.'), findsOneWidget);

    await tap(tester, find.text('Rejoindre et payer'));

    // GAM-05.
    expect(find.text('Tu es dans la partie !'), findsOneWidget);
    expect(
      find.text('Skander et 7 joueurs t’attendent dimanche à Arena Five. Ta part est payée.'),
      findsOneWidget,
    );
    expect(find.text('Ta place'), findsOneWidget);
    expect(find.text('Plus qu’une place'), findsOneWidget);
    await tap(tester, find.text('Voir mes matchs'));

    // MAT-01.
    expect(find.text('Mes matchs'), findsWidgets);
    expect(find.text('DIM. 18 OCT. · TU JOUES'), findsOneWidget);
    expect(find.text('Tu joues'), findsOneWidget);
    expect(find.text('MER. 21 OCT. · TU ORGANISES'), findsOneWidget);
    expect(find.text('Mariem K. t’invite au padel'), findsOneWidget);
    final joined = await tester.runAsync(games.joined);
    expect(joined!.map((g) => g.id), ['g1']);

    // MAT-07.
    await tap(tester, find.text('Quitter'));
    expect(find.text('Quitter la partie ?'), findsOneWidget);
    expect(
      find.text(
        'Tes ${formatDT(15)} seront remboursés sur ton solde MatchUp. Annulation gratuite '
        'jusqu’à sam. 17 oct. · 20h00.',
      ),
      findsOneWidget,
    );
    await tapQuick(tester, find.text('Quitter la partie'));
    expect(find.text('Partie quittée'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('DIM. 18 OCT. · TU JOUES'), findsNothing);

    // « Annuler » takes the place back (no settling: the toast would be gone).
    await tester.tap(find.text('Annuler'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('DIM. 18 OCT. · TU JOUES'), findsOneWidget);
  });

  testWidgets('GAM-02 full game → waitlist (GAM-03) → leave the list', (tester) async {
    await pumpApp(tester, Routes.game('g4'));
    expect(find.text('Complet'), findsWidgets);
    expect(find.text('10/10'), findsWidgets);
    expect(find.text('Rejoindre la liste d’attente'), findsOneWidget);
    await tap(tester, find.text('Rejoindre la liste d’attente'));

    expect(find.text('Tu es 3e sur la liste d’attente'), findsOneWidget);
    expect(find.text('Plus que 2 joueurs avant toi.'), findsOneWidget);
    expect(find.text('Comment ça marche'), findsOneWidget);
    expect(find.text('Me prévenir aussi par SMS'), findsOneWidget);
    await tapQuick(tester, find.text('Quitter la liste'));
    expect(find.text('Tu as quitté la liste d’attente'), findsOneWidget);
    expect(find.text('Rejoindre la liste d’attente'), findsOneWidget);
  });

  testWidgets('MAT-05 → MAT-06 cancel MU-48213 → Annulés with the refund', (tester) async {
    await pumpApp(tester, Routes.booking('MU-48213'));
    expect(find.text('Arena Five · Terrain 1'), findsOneWidget);
    expect(find.text('Partie publique · mixte · niveau 2,5 – 4,0 · tu organises'), findsOneWidget);
    expect(find.text('Afficher le QR code'), findsOneWidget);
    await see(tester, find.text('4 places publiques'));
    await see(tester, find.text('Je prends les gants, je serai gardien.'));
    await see(tester, find.text('Annuler la réservation'));
    await tap(tester, find.text('Annuler la réservation'));

    expect(find.text('Annuler la réservation ?'), findsOneWidget);
    expect(
      find.text('Les 6 joueurs seront remboursés : ${formatDT(15)} chacun sur leur solde MatchUp.'),
      findsOneWidget,
    );
    expect(find.text('Total remboursé · 6 joueurs'), findsOneWidget);
    await tapQuick(tester, find.widgetWithText(MuButton, 'Annuler la réservation').last);

    // Back on Mes matchs, on « Annulés ».
    expect(find.text('Réservation annulée'), findsOneWidget);
    expect(find.text('Remboursement'), findsWidgets);
    expect(find.text('Arena Five · Terrain 1'), findsOneWidget);
    expect(find.text('Total remboursé · 6 joueurs'), findsOneWidget);
    final cancelled = await tester.runAsync(bookings.cancelled);
    expect(cancelled!.first.booking.id, 'MU-48213');
    final upcoming = await tester.runAsync(bookings.upcoming);
    expect(upcoming!.bookings, isEmpty);
  });

  testWidgets('MAT-02 → rate the padel mates (MAT-08) → score (MAT-09)', (tester) async {
    await pumpApp(tester, Routes.matches);
    await tap(tester, find.text('Passés'));
    expect(find.text('À ÉVALUER'), findsOneWidget);
    expect(find.text('Évalue tes coéquipiers'), findsOneWidget);
    expect(find.text('Mariem, Ines et Nour · 1 min'), findsOneWidget);
    expect(find.text('3 matchs depuis septembre · 2 victoires'), findsOneWidget);
    await tap(tester, find.text('Évaluer les joueurs'));

    expect(find.text('Évalue les joueurs'), findsOneWidget);
    expect(find.text('Ta partenaire · côté droit · annoncée 4,0'), findsOneWidget);
    expect(find.text('Son niveau ce jour-là'), findsNWidgets(3));
    await tap(tester, find.text('Envoyer'));

    expect(find.text('Le score du match'), findsOneWidget);
    await see(tester, find.text('Ajouter un 3e set'));
    await tap(tester, find.bySemanticsLabel('Ajouter un jeu à Ines et Nour').first);
    await tapQuick(tester, find.text('Enregistrer le score'));

    expect(find.text('Score enregistré'), findsOneWidget);
    expect(find.text('À ÉVALUER'), findsNothing);
    expect(find.text('Évalués'), findsOneWidget);
    final past = await tester.runAsync(bookings.past);
    expect(past!.first.rated, isTrue);
    expect(past.first.sets, [(6, 5), (6, 3)]);
  });

  testWidgets('MAT-01: answering the invitation; MAT-04 empty state', (tester) async {
    await pumpApp(tester, Routes.matches);
    expect(find.text('À RÉPONDRE'), findsOneWidget);
    await tapQuick(tester, find.text('Accepter'));
    expect(find.text('Invitation acceptée'), findsOneWidget);
    expect(find.text('À RÉPONDRE'), findsNothing);
    expect(find.text('VEN. 23 OCT. · TU JOUES'), findsOneWidget);
  });

  testWidgets('MAT-04: nothing ahead', (tester) async {
    await pumpApp(tester, Routes.matches, repo: _EmptyBookings());
    expect(find.text('Aucun match à venir'), findsOneWidget);
    expect(find.text('Trouver une partie'), findsOneWidget);
    expect(find.text('Réserver un terrain'), findsWidgets);
  });
}
