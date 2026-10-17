import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/app_settings.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/connectivity.dart';
import 'package:matchup/core/format.dart';
import 'package:matchup/features/explore/data/tournaments_repository.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/home/controllers/home_providers.dart';
import 'package:matchup/features/matches/data/bookings_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/profile/data/profile_repository.dart';
import 'package:matchup/features/states/data/account_status.dart';
import 'package:matchup/features/states/widgets/state_widgets.dart';
import 'package:matchup/features/venue/data/venues_repository.dart';
import 'package:matchup/router.dart';

/// Phase 12: strings from the ARB files, Arabic (RTL, « د.ت », 24 h), and the global states
/// STA-01 to STA-09.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => setFormatLocale(const Locale('fr')));

  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester, String at, {String name = 'Yassine B.'}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    container = ProviderContainer(
      // The simulated 503 must not be retried in the background.
      retry: (_, _) => null,
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
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
        .first;
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -300), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Arabic: Home is right-to-left with the RTL-01 strings and « د.ت »', (tester) async {
    await pumpApp(tester, Routes.home);
    container.read(appSettingsProvider.notifier).setLocale(const Locale('ar')).ignore();
    await tester.pumpAndSettle();
    expect(find.text('مباريات تناسبك'), findsWidgets);
    expect(find.text('الرئيسية'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.text('مباريات تناسبك').first));
    expect(dir, TextDirection.rtl);
    expect(formatDT(15), '15 د.ت');
    expect(formatTime(DateTime(2026, 10, 18, 20)), '20:00');
    expect(formatDay(DateTime(2026, 10, 18)), 'الأحد 18 أكتوبر');
    container.read(appSettingsProvider.notifier).setLocale(const Locale('fr')).ignore();
    await tester.pumpAndSettle();
    expect(find.text('Parties pour toi'), findsWidgets);
  });

  testWidgets('STA-01 offline strip and STA-06 email banner on Home', (tester) async {
    await pumpApp(tester, Routes.home);
    container.read(simulatedOfflineProvider.notifier).set(true);
    container.read(accountFlagsProvider.notifier).setEmailVerified(false);
    await tester.pumpAndSettle();
    expect(find.text('Tu es hors ligne'), findsOneWidget);
    expect(
      find.text(
        'Tu vois tes données du ven. 16 oct. à 17h42. Reconnecte-toi pour rejoindre ou payer.',
      ),
      findsOneWidget,
    );
    expect(find.text('Vérifie ton email'), findsOneWidget);
    await tap(tester, find.text('Renvoyer l’email'));
    expect(
      find.text('Lien envoyé à yassine.b@email.tn. Il te permettra de récupérer ton compte.'),
      findsOneWidget,
    );
  });

  testWidgets('STA-02 server error on Mes matchs, then « Réessayer »', (tester) async {
    await pumpApp(tester, Routes.matches);
    container.read(simulatedServerErrorProvider.notifier).set(true);
    container.invalidate(upcomingMatchesProvider);
    await tester.pumpAndSettle();
    expect(find.text('Tes matchs ne se chargent pas'), findsOneWidget);
    expect(find.textContaining('MU-7F3A-2C', findRichText: true), findsOneWidget);
    await tap(tester, find.text('Réessayer'));
    expect(find.text('Tes matchs ne se chargent pas'), findsNothing);
  });

  testWidgets('STA-03 dead game link → « Trouver une autre partie »', (tester) async {
    await pumpApp(tester, Routes.game('7Q2K9'));
    expect(find.text('Cette partie n’existe plus'), findsOneWidget);
    await tap(tester, find.text('Trouver une autre partie'));
    expect(find.text('Explorer'), findsWidgets);
  });

  testWidgets('STA-04 session expired → « Me reconnecter » → AUTH-05', (tester) async {
    await pumpApp(tester, Routes.wallet);
    final context = tester.element(find.byType(Scaffold).first);
    showSessionExpired(
      context,
      name: 'Yassine B.',
      email: 'yassine.b@email.tn',
      balance: 30,
      onReconnect: () => container.read(routerProvider).push(Routes.login),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ta session a expiré'), findsOneWidget);
    await tap(tester, find.text('Me reconnecter'));
    expect(find.text('Ta session a expiré'), findsNothing);
  });

  testWidgets('STA-07 suspended account on Home', (tester) async {
    await pumpApp(tester, Routes.home, name: 'Omar D.');
    container
        .read(suspensionsProvider.notifier)
        .suspend(
          'Omar D.',
          Suspension(
            until: DateTime(2026, 10, 23, 18),
            reason: '2 matchs manqués sans prévenir, le sam. 26 sept. et le jeu. 8 oct.',
            refunded: 30,
            freedGames: 2,
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Salut Omar'), findsOneWidget);
    expect(find.text('Ton compte est suspendu 7 jours'), findsOneWidget);
    expect(find.text('Contester la décision'), findsOneWidget);
    expect(find.text('Parties pour toi'), findsNothing);
  });

  testWidgets('STA-08 profile completion on PRF-01', (tester) async {
    await pumpApp(tester, Routes.profile);
    await see(tester, find.text('Compléter mon profil'));
    expect(find.textContaining('Ton profil est complet à', findRichText: true), findsOneWidget);
    await tap(tester, find.text('Plus tard'));
    expect(find.text('Compléter mon profil'), findsNothing);
  });

  testWidgets('STA-09 optimistic waitlist rolls back with a snackbar; end of list', (tester) async {
    await pumpApp(tester, Routes.explore);
    container.read(simulatedServerErrorProvider.notifier).set(true);
    await tap(tester, find.text('Mon niveau'));
    final waitlist = find.text('Liste d’attente');
    final down = find
        .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
        .first;
    for (var i = 0; i < 10 && waitlist.evaluate().isEmpty; i++) {
      await tester.drag(down, const Offset(0, -300), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Centre it: the AI button floats over the end of the cards near the bottom.
    await Scrollable.ensureVisible(tester.element(waitlist.first), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(waitlist.first);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.text('Impossible de rejoindre la liste d’attente. Rien n’a changé.'),
      findsOneWidget,
    );
    expect(find.text('Liste d’attente'), findsWidgets);
    expect(find.text('Sur la liste'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    for (var i = 0; i < 20 && find.text('C’est tout pour l’instant').evaluate().isEmpty; i++) {
      await tester.drag(down, const Offset(0, -300), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('C’est tout pour l’instant'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  test('app_ar.arb uses the placeholders of app_fr.arb', () {
    Map<String, dynamic> read(String f) =>
        jsonDecode(File('lib/l10n/$f').readAsStringSync()) as Map<String, dynamic>;
    final fr = read('app_fr.arb');
    final ar = read('app_ar.arb');
    final placeholder = RegExp(r'\{(p\d+)\}');
    for (final e in ar.entries.where((e) => !e.key.startsWith('@'))) {
      expect(fr.containsKey(e.key), isTrue, reason: e.key);
      final want = placeholder.allMatches(fr[e.key] as String).map((m) => m[1]).toSet();
      final got = placeholder.allMatches(e.value as String).map((m) => m[1]).toSet();
      expect(got, want, reason: e.key);
    }
  });
}
