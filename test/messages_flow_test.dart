import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/features/forum/controllers/messages_providers.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

/// Messages from the Communauté: the entry card, a group chat (poll, sending, a demo friend
/// answering), a new group, and « Envoyer à un ami » from a discussion.
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

  testWidgets('Communauté → Messages → a group: vote, write, a friend answers', (tester) async {
    await pumpApp(tester, Routes.community);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.bySemanticsLabel('Messages, 5 non lus'), findsOneWidget);
    await tap(tester, find.text('Messages'));

    expect(find.text('Tes amis'), findsOneWidget);
    expect(find.text('Five du mercredi · Arena Five'), findsOneWidget);
    expect(find.text('Nour : Je passe par là, je te prends à 20h30 !'), findsOneWidget);
    await tap(tester, find.text('Five du mercredi · Arena Five'));

    // The cards of the story.
    expect(find.text('6 membres'), findsOneWidget);
    expect(find.text('Je passe par là, je te prends à 20h30 !'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Chasubles ou maillots ?'), findsOneWidget);
    await tap(tester, find.text('Chacun son maillot'));
    expect(find.text('5 votes'), findsOneWidget);

    // Writing: the message shows, then « en train d’écrire… », then the answer.
    await tester.enterText(find.byType(TextField).last, 'Je peux prendre Omar aussi si besoin');
    await tester.pump();
    await tap(tester, find.byTooltip('Envoyer'));
    expect(find.text('Je peux prendre Omar aussi si besoin'), findsOneWidget);
    await tester.pump(ChatController.typingDelay);
    await tester.pump();
    expect(find.text('en train d’écrire…'), findsOneWidget);
    await tester.pump(ChatController.answerDelay);
    await tester.pumpAndSettle();
    expect(find.text('en train d’écrire…'), findsNothing);

    // Back in the list, the group is read and the conversation moved up.
    await tap(tester, find.byTooltip('Retour aux messages'));
    expect(find.textContaining('Je peux prendre Omar'), findsNothing);
  });

  testWidgets('Nouveau message: two friends make a group', (tester) async {
    await pumpApp(tester, Routes.messages);
    await tap(tester, find.byTooltip('Nouveau message'));
    expect(find.text('Choisis un ou plusieurs amis'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'kar');
    await tester.pumpAndSettle();
    await tap(tester, find.text('Karim J.').last);
    expect(find.text('Écrire à Karim J.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'meh');
    await tester.pumpAndSettle();
    await tap(tester, find.text('Mehdi K.').last);
    expect(find.text('Créer le groupe (3)'), findsOneWidget);
    expect(find.text('Nom du groupe'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'Basket du vendredi');
    await tester.pumpAndSettle();
    await tap(tester, find.widgetWithText(MuButton, 'Créer le groupe (3)'));

    expect(find.text('Basket du vendredi'), findsOneWidget);
    expect(find.text('Yassine B. a créé le groupe'), findsOneWidget);
  });

  testWidgets('« Envoyer à un ami » from a discussion', (tester) async {
    await pumpApp(tester, Routes.forumPost('demo-sujet-crampons'));
    await tap(tester, find.byTooltip('Plus d’options : signaler, copier le lien'));
    await tap(tester, find.text('Envoyer à un ami'));
    expect(find.text('Conversations récentes'), findsOneWidget);
    await tester.tap(find.text('Mariem K.').first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Envoyée à Mariem K.'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
