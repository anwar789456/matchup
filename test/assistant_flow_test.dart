import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/connectivity.dart';
import 'package:matchup/features/assistant/assistant_routes.dart';
import 'package:matchup/features/assistant/data/assistant_models.dart';
import 'package:matchup/features/assistant/data/assistant_repository.dart';
import 'package:matchup/features/assistant/data/assistant_story.dart';
import 'package:matchup/features/owner/screens/prices_screen.dart';
import 'package:matchup/features/payments/controllers/checkout_controller.dart';
import 'package:matchup/features/payments/screens/checkout_screen.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/training/data/training_repository.dart';
import 'package:matchup/features/training/screens/program_screen.dart';
import 'package:matchup/router.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Fake assistant (story: ven. 16 oct. 18h00)', () {
    test('picks the answer of each screen', () {
      expect(AssistantStory.normalize('Réserve un Terrain'), 'reserve un terrain');
      AiAnswer last(String q, [AssistantSpace s = AssistantSpace.player]) {
        final a = AssistantStory.answer(q, s);
        return AiAnswer(understood: a.understood, blocks: a.blocks);
      }

      expect(
        last('Réserve un terrain à La Marsa samedi').blocks.whereType<AiSlots>(),
        hasLength(1),
      );
      expect(
        last('Trouve-moi une partie de padel demain soir').blocks.first,
        isA<AiNothingFound>(),
      );
      expect(last('Quel programme pour améliorer mon service ?').blocks.last, isA<AiPrograms>());
      expect(last('Pourquoi j’ai 3,5 au padel ?').blocks.single, isA<AiText>());
      expect(
        last('Mes créneaux les moins remplis', AssistantSpace.owner).blocks[1],
        isA<AiChart>(),
      );
      expect(last('bonjour').blocks.last, isA<AiFollowUps>());
    });

    test('AI-02: 150 DT the hour at 10 → 15 DT each; 20h00 on Terrain 2', () {
      final s = AssistantStory.arenaSlots;
      expect(s.share, 15);
      expect(s.slot.court, 'Terrain 2');
      expect(s.pick(2).slot.indoor, isTrue);
    });

    test('the padel search streams its 3 steps, then the answer', () async {
      final repo = FakeAssistantRepository(offline: () => false, step: Duration.zero);
      final answers = await repo.ask('padel demain soir', AssistantSpace.player).toList();
      expect([for (final a in answers) a.step], [0, 1, 2, 0]);
      expect(answers[1].found, isNotNull);
      expect(answers.last.searching, isNull);
      expect(answers.last.blocks, isNotEmpty);
    });

    test('offline: the answer fails (AI-06)', () async {
      final repo = FakeAssistantRepository(offline: () => true, step: Duration.zero);
      expect(repo.ask('padel', AssistantSpace.player).toList(), throwsA(isA<OfflineException>()));
    });
  });

  group('Assistant', () {
    Future<ProviderContainer> pumpApp(WidgetTester tester, String at) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => storyNow),
          onboardingStoreProvider.overrideWithValue(
            MemoryOnboardingStore(
              const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.'),
            ),
          ),
          trainingRepositoryProvider.overrideWithValue(FakeTrainingRepository()),
          assistantStepProvider.overrideWithValue(const Duration(milliseconds: 10)),
        ],
      );
      addTearDown(container.dispose);
      container.read(routerProvider).go(at);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MatchUpApp()),
      );
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> settleFonts(WidgetTester tester) async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pumpAndSettle();
    }

    Future<void> ask(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Envoyer'));
      await tester.pumpAndSettle();
    }

    testWidgets('AI-01 → AI-02 → 22h00 → AI-03 → « Confirmer » opens PAY-01', (tester) async {
      final c = await pumpApp(tester, AssistantRoutes.player);
      expect(find.textContaining('Salut Yassine !'), findsOneWidget);
      expect(find.text('Padel 3,5'), findsOneWidget);
      await tester.tap(find.text('Réserve un terrain à La Marsa samedi'));
      await tester.pumpAndSettle();
      expect(find.text('Terrain 2 · sam. 17 oct. · 20h00'), findsOneWidget);
      await tester.ensureVisible(find.text('22h00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('22h00'));
      await tester.pumpAndSettle();
      expect(find.text('Terrain 3 · sam. 17 oct. · 22h00'), findsOneWidget);
      await tester.ensureVisible(find.text('Réserver 22h00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Réserver 22h00'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Je réserve le Terrain 3 à Arena Five'), findsOneWidget);
      expect(
        find.text(
          'Rien n’est réservé ni payé sans ta confirmation. Tu vérifies le paiement juste après.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Confirmer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(c.read(checkoutRequestProvider)?.amount, 15);
      await settleFonts(tester);
    });

    testWidgets('AI-04 → AI-05: steps, then no game; « Activer » the alert', (tester) async {
      await pumpApp(tester, AssistantRoutes.player);
      await tester.tap(find.text('Trouve-moi une partie de padel demain soir'));
      await tester.pump(const Duration(milliseconds: 15));
      expect(find.text('Je cherche ta partie de padel'), findsOneWidget);
      expect(find.text('Réponse en cours…'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Aucune partie ouverte', findRichText: true), findsNothing);
      expect(find.textContaining('Aucune partie ouverte', findRichText: true), findsOneWidget);
      expect(find.text('Crée ta partie demain à 19h30'), findsOneWidget);
      await tester.ensureVisible(find.text('Activer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activer'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Activée'), findsOneWidget);
      await tester.pumpAndSettle();
      await settleFonts(tester);
    });

    testWidgets('stop keeps what was written', (tester) async {
      await pumpApp(tester, AssistantRoutes.player);
      await tester.tap(find.text('Trouve-moi une partie de padel demain soir'));
      await tester.pump(const Duration(milliseconds: 15));
      await tester.tap(find.bySemanticsLabel('Arrêter la réponse'));
      await tester.pumpAndSettle();
      expect(find.text('Réponse arrêtée.'), findsOneWidget);
      expect(find.text('Demande à MatchUp…'), findsOneWidget);
      await settleFonts(tester);
    });

    testWidgets('AI-06: offline, the message is kept; « Réessayer » answers with a program', (
      tester,
    ) async {
      final c = await pumpApp(tester, AssistantRoutes.player);
      await ask(tester, 'Pourquoi j’ai 3,5 au padel ?');
      expect(find.textContaining('18 matchs'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Réponse utile'));
      await tester.pumpAndSettle();
      expect(find.text('Merci pour ton retour · L’IA peut se tromper.'), findsOneWidget);

      c.read(simulatedOfflineProvider.notifier).set(true);
      await ask(tester, 'Quel programme pour améliorer mon service ?');
      expect(find.text('Connexion instable'), findsOneWidget);
      expect(find.text('Je n’ai pas pu répondre'), findsOneWidget);
      expect(find.text('Voir les programmes'), findsOneWidget);

      c.read(simulatedOfflineProvider.notifier).set(false);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Connexion instable'), findsNothing);
      await tester.ensureVisible(find.text('Service et retour'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service et retour'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramScreen), findsOneWidget);
      await settleFonts(tester);
    });

    testWidgets('AI-07: the owner sees the emptiest slots and prepares the offer', (tester) async {
      await pumpApp(tester, AssistantRoutes.owner);
      expect(find.text('Espace propriétaire · Arena Five'), findsOneWidget);
      await tester.tap(find.text('Mes créneaux les moins remplis'));
      await tester.pumpAndSettle();
      expect(find.text('Créneaux les plus vides'), findsOneWidget);
      await tester.ensureVisible(find.text('Préparer l’offre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Préparer l’offre'));
      await tester.pumpAndSettle();
      final prices = tester.widget<OwnerPricesScreen>(find.byType(OwnerPricesScreen));
      expect(prices.promo?.percent, 20);
      await settleFonts(tester);
    });
  });
}
