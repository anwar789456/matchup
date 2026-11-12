import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

/// The Communauté from the player's tab: FRM-01 → FRM-04 (vote, FRM-03 alert, masked reply,
/// FRM-05 report) and FRM-02 → publish.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpApp(WidgetTester tester, String at) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => storyNow),
        onboardingStoreProvider.overrideWithValue(
          MemoryOnboardingStore(const PlayerOnboardingState(completed: true, tourSeen: true, fullName: 'Yassine B.')),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(routerProvider).go(at);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MatchUpApp()));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  testWidgets('FRM-01: categories, feed, mention, filters', (tester) async {
    await pumpApp(tester, Routes.community);
    expect(find.text('Pose ta question à la communauté'), findsOneWidget);
    expect(find.text('Catégories'), findsOneWidget);
    expect(find.text('Nouveaux depuis ta dernière visite'), findsOneWidget);
    expect(find.text('Padel Masters Lac 2 : toutes les infos et vos questions'), findsOneWidget);
    expect(find.textContaining('t’a mentionné'), findsOneWidget);

    await tap(tester, find.text('Terrains'));
    expect(find.text('Avis Smash Padel Club après rénovation'), findsOneWidget);
    expect(find.text('Padel Masters Lac 2 : toutes les infos et vos questions'), findsNothing);
    await tap(tester, find.text('Terrains'));
    expect(find.text('Padel Masters Lac 2 : toutes les infos et vos questions'), findsOneWidget);
  });

  testWidgets('FRM-04: best answer, vote, FRM-03 then a masked reply, FRM-05', (tester) async {
    await pumpApp(tester, Routes.community);
    await scrollTo(tester, find.text('Crampons pour synthétique ?'));
    await tap(tester, find.text('Crampons pour synthétique ?'));

    expect(find.text('Meilleure réponse'), findsOneWidget);
    expect(find.text('choisie par Skander T.'), findsOneWidget);
    expect(find.text('Suivre'), findsOneWidget);
    await scrollTo(tester, find.text('8 réponses'));
    expect(find.text('8 réponses'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();

    // « Merci » on the post.
    await tap(tester, find.widgetWithText(MuChip, 'Merci'));
    expect(find.widgetWithText(MuChip, 'Merci'), findsOneWidget);

    // A hurtful reply: FRM-03, then « Publier quand même ».
    await tester.enterText(find.byType(TextField).last, 'T’as jamais mis les pieds sur un synthétique, franchement t’es nul.');
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Envoyer'));
    expect(find.text('Ce message pourrait blesser. Le modifier avant de publier ?'), findsOneWidget);
    await tap(tester, find.text('Publier quand même'));
    expect(find.text('Ce message pourrait blesser. Le modifier avant de publier ?'), findsNothing);
    await scrollTo(tester, find.textContaining('Ta réponse à Skander T. · seul toi vois ce message'));
    expect(find.text('Masqué par la modération · en cours de vérification'), findsWidgets);

    // FRM-05 on Bons Plans Sport TN, muting the author.
    await scrollTo(tester, find.text('Bons Plans Sport TN'));
    final row = find.ancestor(of: find.text('Bons Plans Sport TN'), matching: find.byType(Row)).first;
    await tap(tester, find.descendant(of: row, matching: find.byTooltip('Plus d’options')));
    await tap(tester, find.text('Signaler').last);
    expect(find.text('Signaler ce commentaire'), findsOneWidget);
    expect(find.text('Ne plus voir les messages de Bons Plans Sport TN'), findsOneWidget);
    await tap(tester, find.widgetWithText(MuButton, 'Signaler'));
    expect(find.text('Bons Plans Sport TN'), findsNothing);
  });

  testWidgets('FRM-02: similar discussions, AI tags, publish', (tester) async {
    await pumpApp(tester, Routes.community);
    await tap(tester, find.text('Pose ta question à la communauté'));
    expect(find.text('Nouveau post'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Bandeja croisée : vous visez où sur la vitre ?');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Discussions similaires'), findsOneWidget);
    expect(find.text('Bandeja : je n’arrive pas à la placer croisée'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), 'Je travaille la bandeja, je suis à 3,5, côté gauche.');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Suggérés par l’IA'));
    expect(find.text('Suggérés par l’IA'), findsOneWidget);
    expect(find.text('Brouillon enregistré'), findsOneWidget);

    await tap(tester, find.widgetWithText(MuButton, 'Publier'));
    expect(find.text('Discussion'), findsOneWidget);
    expect(find.text('Bandeja croisée : vous visez où sur la vitre ?'), findsOneWidget);
    expect(find.text('Pas encore de réponse'), findsOneWidget);
  });
}
