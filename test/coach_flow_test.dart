import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/coach/coach_routes.dart';
import 'package:matchup/features/coach/controllers/coach_providers.dart';
import 'package:matchup/features/coach/data/coach_models.dart';
import 'package:matchup/features/coach/data/coach_repository.dart';
import 'package:matchup/features/coach/data/coach_story.dart';
import 'package:matchup/features/coach/data/draft_ops.dart';
import 'package:matchup/features/coach/screens/coach_students_screen.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Coach story', () {
    test('the counts of the designs hold: 38 students, 3 late, 24 active, 6 finished', () {
      final s = CoachStory.students;
      expect(s, hasLength(38));
      expect(s.where((x) => x.late), hasLength(3));
      expect(s.where((x) => x.activeThisWeek), hasLength(24));
      expect(s.where((x) => x.finished), hasLength(6));
      // Nobody did anything after « now » (ven. 16 oct. 18h00).
      expect(s.every((x) => !x.lastActivity.isAfter(storyNow)), isTrue);
    });

    test('the draft: 10 sessions of 12, week 4 lacks 2, session 5 in processing', () {
      final d = CoachStory.draft;
      expect(d.sessionCount, 10);
      expect(d.missingSessions, 2);
      expect(d.weeks.last.sessions, hasLength(1));
      expect(d.sessions[4].title, 'Volée croisée profonde');
      expect(d.sessions[4].processing, isTrue);
      expect(d.sessions[4].minutes, 24);
    });

    test('draft edits: add, reorder, remove', () {
      var d = CoachStory.draft;
      d = DraftOps.addWeek(d);
      expect(d.weeks, hasLength(5));
      final (withSession, id) = DraftOps.addSession(d, d.weeks.last.id);
      expect(withSession.sessionCount, 11);
      expect(DraftOps.find(withSession, id)!.$1, 5);
      final s5 = d.sessions[4];
      final added = DraftOps.addExercises(s5, [CoachStory.library.first]);
      expect(added.exercises.last.name, 'Split-step avant la volée');
      final moved = DraftOps.reorderExercises(added, 3, 0);
      expect(moved.exercises.first.name, 'Split-step avant la volée');
      expect(DraftOps.removeExercise(moved, moved.exercises.first.id).exercises, hasLength(3));
      final weeks = DraftOps.reorderWeeks(d, 0, 2);
      expect(weeks.weeks[2].title, 'Les bases au filet');
    });

    test('a draft survives JSON (uploads come back processing)', () {
      final back = ProgramDraft.fromJson(CoachStory.draft.toJson());
      expect(back.sessionCount, 10);
      expect(back.title, CoachStory.draft.title);
      final ex = back.sessions[4].exercises[2];
      expect(ex.video, VideoState.processing);
    });
  });

  group('SqliteCoachRepository (schema v5)', () {
    late AppDatabase database;
    late SqliteCoachRepository repo;

    setUp(() {
      database = AppDatabase();
      repo = SqliteCoachRepository(database);
    });
    tearDown(() => database.close());

    test('the seeded draft, todos handled, feedback sent — and queued for Supabase', () async {
      final db = await database.db;
      expect((await repo.draft())!.title, 'Jeu au filet en 4 semaines');
      expect(await db.query('sync_outbox'), isEmpty);

      final d = (await repo.draft())!;
      await repo.saveDraft(d.copyWith(title: 'Jeu au filet', priceSet: true));
      expect((await repo.draft())!.title, 'Jeu au filet');
      expect((await repo.draft())!.priceSet, isTrue);

      await repo.handle('dropped-lina');
      expect(await repo.handled(), {'dropped-lina'});

      await repo.sendFeedback(
        CoachFeedback(
          studentId: 'yassine',
          comments: CoachStory.comments,
          message: 'Bravo',
          askNewVideo: true,
          sentAt: storyNow,
        ),
      );
      final f = (await repo.feedback('yassine'))!;
      expect(f.comments, hasLength(2));
      expect(f.message, 'Bravo');
      expect(await repo.handled(), contains('video-yassine'));

      await repo.deleteDraft();
      expect(await repo.draft(), isNull);

      final queued = {
        for (final r in await db.query('sync_outbox')) r['tableau']! as String,
      };
      expect(queued, {'coach_brouillons', 'coach_actions', 'coach_retours'});
    });
  });

  group('Coach space', () {
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
          coachRepositoryProvider.overrideWithValue(FakeCoachRepository()),
          coachFakeServerProvider.overrideWithValue(false),
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

    Future<void> see(WidgetTester tester, Finder finder) async {
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
        await tester.drag(list, const Offset(0, -300), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('COA-04: dashboard, « Relancer » clears Lina from « À traiter »', (tester) async {
      await pumpApp(tester, CoachRoutes.dashboard);
      expect(find.text('Salut Karim'), findsOneWidget);
      expect(find.text('Espace coach'), findsOneWidget);
      expect(find.text('Vidéo de Yassine B.'), findsOneWidget);
      expect(find.text('Avis 3★ d’Omar D.'), findsOneWidget);
      expect(find.text('Lina F. a décroché'), findsOneWidget);
      await tester.tap(find.text('Relancer'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Message de relance envoyé à Lina F.'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Lina F. a décroché'), findsNothing);
      // The four tabs.
      expect(find.text('Tableau'), findsOneWidget);
      expect(find.text('Revenus'), findsWidgets);
      await settleFonts(tester);
    });

    testWidgets('COA-09: 38 students, « En retard » keeps the 3 late ones', (tester) async {
      await pumpApp(tester, CoachRoutes.students);
      expect(find.textContaining('38', findRichText: true), findsWidgets);
      await tester.tap(find.widgetWithText(MuChip, 'En retard'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentRow), findsNWidgets(3));
      await settleFonts(tester);
    });

    testWidgets('COA-06: add « Gainage latéral » to session 5 from the library', (tester) async {
      final c = await pumpApp(tester, CoachRoutes.builder);
      expect(find.text('Volée croisée profonde'), findsOneWidget);
      await see(tester, find.text('Ajouter un exercice'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter un exercice'));
      await tester.pumpAndSettle();
      expect(find.text('Choisis un exercice'), findsOneWidget);
      await tester.tap(find.text('Gainage latéral'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter 1 exercice'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1 exercice ajouté'), findsOneWidget);
      await tester.pumpAndSettle();
      final s5 = c.read(coachDraftProvider).value!.sessions[4];
      expect(s5.exercises.last.name, 'Gainage latéral');
      await settleFonts(tester);
    });

    testWidgets('COA-08: « Programmer la publication » → COA-05 shows it scheduled', (tester) async {
      await pumpApp(tester, CoachRoutes.publish);
      expect(find.text('Prix pour un élève'), findsOneWidget);
      expect(find.textContaining('31,500'), findsOneWidget);
      await tester.tap(find.text('Programmer la publication'));
      await tester.pumpAndSettle();
      expect(find.text('Publication programmée'), findsWidgets);
      expect(find.textContaining('et le prix'), findsNothing);
      await settleFonts(tester);
    });

    testWidgets('COA-05: deleting the draft asks first', (tester) async {
      final c = await pumpApp(tester, CoachRoutes.programs);
      expect(find.text('Jeu au filet en 4 semaines'), findsOneWidget);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer le brouillon ?'), findsOneWidget);
      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();
      expect(c.read(coachDraftProvider).value, isNull);
      expect(find.text('Jeu au filet en 4 semaines'), findsNothing);
      await settleFonts(tester);
    });

    testWidgets('COA-10 → COA-11: comment at 0:39 with the AI, send the feedback', (tester) async {
      final c = await pumpApp(tester, CoachRoutes.student('yassine'));
      expect(find.text('Yassine B.'), findsOneWidget);
      expect(find.text('Attend ton retour'), findsOneWidget);
      await tester.tap(find.text('Faire un retour'));
      await tester.pumpAndSettle();
      expect(find.text('Retour à Yassine B.'), findsOneWidget);
      expect(find.text('2 sur la vidéo'), findsOneWidget);
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('3 sur la vidéo'), findsOneWidget);
      await see(tester, find.text('Ajouter'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();
      // The AI's moment is now a comment: its card is gone.
      expect(find.text('Ajouter'), findsNothing);
      await tester.tap(find.text('Envoyer le retour'));
      await tester.pumpAndSettle();
      final sent = await c.read(coachRepositoryProvider).feedback('yassine');
      expect(sent!.comments, hasLength(4));
      expect(sent.comments.any((x) => x.fromAi), isTrue);
      expect(find.text('Retour envoyé'), findsWidgets);
      await settleFonts(tester);
    });
  });
}

