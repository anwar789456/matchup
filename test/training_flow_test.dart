import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/core/clock.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_state.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/features/common/data/file_services.dart';
import 'package:matchup/features/common/data/pro_providers.dart' show fileSourceProvider;
import 'package:matchup/features/training/controllers/video_analysis_controller.dart';
import 'package:matchup/features/training/data/sqlite_training_repository.dart';
import 'package:matchup/features/training/data/training_models.dart';
import 'package:matchup/features/training/data/training_repository.dart';
import 'package:matchup/features/training/data/training_story.dart';
import 'package:matchup/features/training/training_routes.dart';
import 'package:matchup/router.dart';
import 'package:matchup/ui/ui.dart';

/// The phone's picker, answering with one clip.
class _PickOne implements FileSource {
  _PickOne(this.file);

  final PickedFile? file;

  @override
  Future<List<PickedFile>> pickImages() async => const [];

  @override
  Future<PickedFile?> pickOne(List<String> extensions) async => file;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Training progress (story: ven. 16 oct. 18h00)', () {
    final progress = TrainingProgress(
      enrolled: {'bandeja': TrainingStory.bandejaJoined},
      results: TrainingStory.doneSessions,
      streakBefore: TrainingStory.streakBefore,
      weeklyGoal: TrainingStory.weeklyGoal,
    );

    test('this week: lun. and mer. done, 2/3, 6 weeks in a row', () {
      expect(progress.daysDone(storyNow), {DateTime.monday, DateTime.wednesday});
      expect(progress.doneThisWeek(storyNow), 2);
      expect(progress.weekValidated(storyNow), isFalse);
      expect(progress.streak(storyNow), 6);
    });

    test('session 5 « Bandeja croisée » is next, in week 2 of 4', () {
      final next = progress.nextLesson(TrainingStory.bandeja)!;
      expect(next.index, 5);
      expect(next.title, 'Bandeja croisée');
      expect(TrainingStory.bandeja.weekOf(next.index), 2);
    });

    test('doing session 5 today validates the week: 3/3, 7 weeks', () {
      final after = progress.copyWith(
        results: [
          ...progress.results,
          LessonResult(
            programId: 'bandeja',
            index: 5,
            doneAt: storyNow,
            minutes: 24,
            drillsDone: 4,
            drillsTotal: 4,
            reps: 29,
            target: 36,
          ),
        ],
      );
      expect(after.doneCount('bandeja'), 5);
      expect(after.weekValidated(storyNow), isTrue);
      expect(after.streak(storyNow), 7);
      expect(after.nextLesson(TrainingStory.bandeja)!.title, 'Bandeja sous pression');
    });

    test('the catalogue matches the designs: 4 programs, 12 sessions for Bandeja', () {
      expect(TrainingStory.programs.map((p) => p.title), [
        'Bandeja en 4 semaines',
        'Service et retour',
        'Endurance foot 5v5',
        'Bases du basket 3×3',
      ]);
      for (final p in TrainingStory.programs) {
        expect(p.lessons, hasLength(p.card.sessions), reason: p.title);
        expect(p.weeks, hasLength(p.card.weeks), reason: p.title);
      }
      expect(TrainingStory.bandeja.weeks.first.minutes, 65); // « 1 h 05 au total »
    });
  });

  group('SqliteTrainingRepository (schema v5)', () {
    late AppDatabase database;
    late SqliteTrainingRepository repo;

    setUp(() {
      database = AppDatabase();
      repo = SqliteTrainingRepository(database);
    });
    tearDown(() => database.close());

    test('starts with the story: Bandeja joined, sessions 1–4 done', () async {
      final p = await repo.progress();
      expect(p.enrolled.keys, ['bandeja']);
      expect(p.doneCount('bandeja'), 4);
      expect(p.streakBefore, 6);
      expect(p.planCardHidden, isFalse);
    });

    test('enrolling, finishing and rating a session are kept', () async {
      await repo.enroll('service-retour');
      await repo.completeLesson(
        LessonResult(
          programId: 'bandeja',
          index: 5,
          doneAt: storyNow,
          minutes: 24,
          drillsDone: 4,
          drillsTotal: 4,
          reps: 29,
          target: 36,
          notes: 'Poignet plus ferme',
        ),
      );
      await repo.rateLesson('bandeja', 5, LessonFeeling.right);
      await repo.hidePlanCard();
      final p = await repo.progress();
      expect(p.isEnrolled('service-retour'), isTrue);
      expect(p.result('bandeja', 5)!.reps, 29);
      expect(p.result('bandeja', 5)!.feeling, LessonFeeling.right);
      expect(p.result('bandeja', 5)!.notes, 'Poignet plus ferme');
      expect(p.planCardHidden, isTrue);
    });
  });

  test('training changes are queued for Supabase; the story seed is not', () async {
    final database = AppDatabase();
    addTearDown(database.close);
    final repo = SqliteTrainingRepository(database, aiDelay: Duration.zero);
    final db = await database.db;
    Future<List<String>> queued() async => [
      for (final r in await db.query('sync_outbox', orderBy: 'id')) r['tableau']! as String,
    ];
    expect(await queued(), isEmpty);
    await repo.enroll('basket-3x3');
    await repo.completeLesson(
      LessonResult(
        programId: 'bandeja',
        index: 5,
        doneAt: storyNow,
        minutes: 24,
        drillsDone: 4,
        drillsTotal: 4,
      ),
    );
    final plan = await repo.generatePlan(PlanRequest.story, storyNow);
    await repo.acceptPlan(plan);
    final video = await repo.analyseVideo(
      move: VideoMove.bandeja,
      fileName: 'bandeja-ven16.mp4',
      sizeBytes: 19293798,
      share: false,
      now: storyNow,
    );
    expect(video.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-')));
    expect(await queued(), [
      'entrainement_inscriptions',
      'entrainement_seances',
      'entrainement_plans',
      'entrainement_profil',
      'entrainement_analyses',
    ]);
  });

  group('Entraînement tab', () {
    Future<void> pumpApp(
      WidgetTester tester,
      String at, {
      PickedFile? clip,
      Duration step = const Duration(milliseconds: 300),
    }) async {
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
          fileSourceProvider.overrideWithValue(
            _PickOne(clip ?? const PickedFile(name: 'bandeja-ven16.mp4', sizeBytes: 19293798)),
          ),
          videoAnalysisTimingProvider.overrideWithValue(
            VideoAnalysisTiming(upload: const Duration(milliseconds: 500), step: step),
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

    /// Lets google_fonts' bundled fonts finish loading before the test ends: with Flutter 3.50 the
    /// « fonts changed » relayout otherwise lands after it, reported as an animation left running.
    Future<void> settleFonts(WidgetTester tester) async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
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

    testWidgets('ENT-01 shows the week, today’s session and the programs', (tester) async {
      await pumpApp(tester, TrainingRoutes.root);
      expect(find.text('Entraînement'), findsWidgets);
      expect(find.text('TA SEMAINE · 12 – 18 OCT.'), findsOneWidget);
      expect(find.text('semaines de suite'), findsOneWidget);
      expect(
        find.text('Fais la séance 5 aujourd’hui pour valider ta 7e semaine.'),
        findsOneWidget,
      );
      expect(find.text('À faire aujourd’hui'), findsWidgets);
      expect(find.text('Bandeja croisée'), findsOneWidget);
      await see(tester, find.text('Mes programmes'));
      expect(find.text('SEMAINE 2 SUR 4 · 33 %'), findsOneWidget);
      await see(tester, find.text('Crée ton plan de la semaine'));
      await see(tester, find.text('Analyse ta bandeja'));
      await see(tester, find.text('Pour progresser'));
      await see(tester, find.text('Service et retour'));
      expect(find.byType(MuFab), findsOneWidget);
      await settleFonts(tester);
    });

    testWidgets('« Plus tard » hides the AI plan card', (tester) async {
      await pumpApp(tester, TrainingRoutes.root);
      await see(tester, find.text('Plus tard'));
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();
      expect(find.text('Crée ton plan de la semaine'), findsNothing);
      await settleFonts(tester);
    });

    testWidgets('ENT-04 → ENT-05: session 5 played through validates the week', (tester) async {
      await pumpApp(tester, TrainingRoutes.lesson('bandeja', 5));
      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.text('Échauffement des épaules'), findsOneWidget);
      await tester.tap(find.text('Marquer comme fait'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('Bandeja croisée sur lancer'), findsOneWidget);
      expect(find.text('Série 1 sur 3'), findsOneWidget);
      await tester.ensureVisible(find.text('Lancer'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.bySemanticsLabel('Ajouter une bandeja'));
        await tester.pump();
      }
      await tester.tap(find.text('Lancer'));
      await tester.pump();
      expect(find.text('Série 2 sur 3'), findsOneWidget);
      await tester.tap(find.text('Passer'));
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Marquer comme fait'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Séance 5 terminée'), findsWidgets);
      expect(find.text('Semaine validée : 3/3'), findsOneWidget);
      expect(find.text('Ta série passe à 7 semaines de suite.'), findsOneWidget);
      expect(find.text('5 séances sur 12 · 42 %'), findsOneWidget);
      await tester.tap(find.text('Juste bien'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retour à mon entraînement'));
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
      expect(find.textContaining('Semaine validée'), findsOneWidget);
      await settleFonts(tester);
    });

    testWidgets('ENT-03: joining a free program adds it to Mes programmes', (tester) async {
      await pumpApp(tester, TrainingRoutes.program('basket-3x3'));
      expect(find.text('Bases du basket 3×3'), findsOneWidget);
      expect(find.text('Gratuit · sans engagement'), findsOneWidget);
      await tester.tap(find.text('S’inscrire au programme'));
      await tester.pumpAndSettle();
      expect(find.text('Mes programmes'), findsOneWidget);
      await see(tester, find.text('Bases du basket 3×3'));
      await settleFonts(tester);
    });

    testWidgets('ENT-03: a paid program opens the checkout (PAY-01)', (tester) async {
      await pumpApp(tester, TrainingRoutes.program('service-retour'));
      expect(find.textContaining('en une fois · accès à vie'), findsOneWidget);
      await tester.tap(find.textContaining('et m’inscrire'));
      await tester.pumpAndSettle();
      expect(find.text('Service et retour'), findsWidgets);
      expect(find.textContaining('PROGRAMME D’ENTRAÎNEMENT'), findsWidgets);
      await settleFonts(tester);
    });

    testWidgets('ENT-03 joined: « Continuer · Séance 5 » opens the session', (tester) async {
      await pumpApp(tester, TrainingRoutes.program('bandeja'));
      expect(find.text('Bandeja en 4 semaines'), findsOneWidget);
      expect(find.text('Continuer · Séance 5'), findsOneWidget);
      await tester.tap(find.text('Continuer · Séance 5'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 4'), findsOneWidget);
      await settleFonts(tester);
    });

    testWidgets('ENT-01 → ENT-06 → ENT-07 → « Accepter le plan »', (tester) async {
      await pumpApp(tester, TrainingRoutes.root);
      await see(tester, find.text('Créer mon plan'));
      await tester.tap(find.text('Créer mon plan'));
      await tester.pumpAndSettle();
      expect(find.text('Ton plan de la semaine'), findsOneWidget);
      expect(find.text('3 jours'), findsOneWidget);
      expect(find.text('La séance 5 prend une de tes 3 places.'), findsOneWidget);
      // Two goals already: a third one is refused with a toast.
      await tester.tap(find.text('Service'));
      await tester.pump();
      expect(find.textContaining('2 objectifs maximum'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Générer mon plan'));
      await tester.pumpAndSettle();
      expect(find.text('Ta semaine du 19 au 25 oct.'), findsOneWidget);
      expect(find.text('Tes 3 séances'), findsOneWidget);
      expect(find.text('Séance 6 · Bandeja sous pression'), findsOneWidget);
      expect(find.text('Placement au filet, sans sauter'), findsOneWidget);
      expect(find.text('Étirements après le tournoi'), findsOneWidget);
      expect(find.text('Généré à 18h00'), findsOneWidget);
      await tester.tap(find.text('Accepter le plan'));
      await tester.pumpAndSettle();
      expect(find.text('Mes programmes'), findsOneWidget);
      expect(find.text('Crée ton plan de la semaine'), findsNothing);
      await settleFonts(tester);
    });

    testWidgets('ENT-06 without the program: the AI proposes the Monday session', (tester) async {
      await pumpApp(tester, TrainingRoutes.planGoals);
      await see(tester, find.text('Inclure mon programme Bandeja'));
      await tester.tap(find.text('Inclure mon programme Bandeja'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Générer mon plan'));
      await tester.pumpAndSettle();
      expect(find.text('Séance 6 · Bandeja sous pression'), findsNothing);
      expect(find.text('Fractionné court, 30/30'), findsOneWidget);
      // « Modifier » goes back to the goals with the answers kept.
      await see(tester, find.text('Modifier'));
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      expect(find.text('Ton plan de la semaine'), findsOneWidget);
      await settleFonts(tester);
    });

    testWidgets('ENT-08 → ENT-09: the clip is sent, analysed, then the 3 tips', (tester) async {
      await pumpApp(tester, TrainingRoutes.video);
      expect(find.text('Analyse vidéo'), findsOneWidget);
      expect(find.text('Quel geste ?'), findsOneWidget);
      await tester.tap(find.text('Filme ou choisis une vidéo'));
      await tester.pump();
      expect(find.text('bandeja-ven16.mp4'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('L’IA analyse ta bandeja'), findsOneWidget);
      expect(find.text('Détection de ta bandeja…'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Comparaison à la référence…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await see(tester, find.text('Voir mes 3 conseils'));
      expect(find.text('C’est prêt'), findsOneWidget);
      await tester.tap(find.text('Voir mes 3 conseils'));
      await tester.pumpAndSettle();
      expect(find.text('Ta bandeja'), findsOneWidget);
      expect(find.text('Ce que l’IA a vu'), findsOneWidget);
      expect(find.textContaining('Bons appuis et épaule bien de profil'), findsOneWidget);
      await see(tester, find.text('Frappe devant l’épaule'));
      expect(find.text('En lecture'), findsOneWidget);
      await see(tester, find.text('0:08'));
      await tester.tap(find.text('0:08'));
      await tester.pumpAndSettle();
      // « En lecture » moved to tip 2.
      expect(
        find.descendant(
          of: find.ancestor(of: find.text('Arme plus tôt'), matching: find.byType(MuCardSurface)),
          matching: find.text('En lecture'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Demander l’avis de Karim J.'));
      await tester.pumpAndSettle();
      expect(find.text('Envoyé à Karim J.'), findsWidgets);
      await settleFonts(tester);
    });

    testWidgets('ENT-08 « Me prévenir »: ENT-01 follows the analysis, then opens ENT-09', (
      tester,
    ) async {
      await pumpApp(tester, TrainingRoutes.video, step: const Duration(seconds: 3));
      await tester.tap(find.text('Filme ou choisis une vidéo'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Me prévenir'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Mes programmes'), findsOneWidget);
      await see(tester, find.text('Analyse ta bandeja'));
      expect(find.textContaining('L’IA analyse ta vidéo · étape'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Ton analyse est prête : 3 conseils t’attendent.'), findsOneWidget);
      await tester.tap(find.text('Analyse ta bandeja'));
      await tester.pumpAndSettle();
      expect(find.text('Ta bandeja'), findsOneWidget);
      await settleFonts(tester);
    });

    testWidgets('ENT-08 refuses a clip over 100 Mo', (tester) async {
      await pumpApp(
        tester,
        TrainingRoutes.video,
        clip: const PickedFile(name: 'match.mp4', sizeBytes: 250 * 1000 * 1000),
      );
      await tester.tap(find.text('Filme ou choisis une vidéo'));
      await tester.pumpAndSettle();
      expect(find.text('Cette vidéo dépasse 100 Mo. Coupe-la à 60 s.'), findsOneWidget);
      expect(find.text('match.mp4'), findsNothing);
      await settleFonts(tester);
    });

    testWidgets('stale links: an unknown program, a session not done yet', (tester) async {
      await pumpApp(tester, TrainingRoutes.program('nope'));
      expect(find.text('Programme introuvable'), findsOneWidget);
      await pumpApp(tester, TrainingRoutes.lessonDone('bandeja', 9));
      expect(find.text('Séance 9 pas encore faite'), findsOneWidget);
      await tester.tap(find.text('Lancer la séance'));
      await tester.pumpAndSettle();
      expect(find.text('SÉANCE 9 · MONTER AU FILET'), findsOneWidget); // ENT-04
      await pumpApp(tester, TrainingRoutes.lessonDone('bandeja', 99));
      expect(find.text('Programme introuvable'), findsOneWidget);
      await settleFonts(tester);
    });

    testWidgets('ENT-02 lists the programs and filters them', (tester) async {
      await pumpApp(tester, TrainingRoutes.programs);
      expect(find.text('Programmes'), findsWidgets);
      expect(find.textContaining('4 programmes', findRichText: true), findsOneWidget);
      expect(find.textContaining('niveau 2,5 – 4,5', findRichText: true), findsOneWidget);
      expect(find.text('Pour toi'), findsOneWidget);
      expect(find.text('Service et retour'), findsOneWidget);
      // Football only: Endurance foot 5v5.
      final football = find.widgetWithText(MuChip, 'Football').first;
      await tester.ensureVisible(football);
      await tester.pumpAndSettle();
      await tester.tap(football);
      await tester.pumpAndSettle();
      expect(find.textContaining('1 programme', findRichText: true), findsOneWidget);
      expect(find.text('Endurance foot 5v5'), findsOneWidget);
      expect(find.text('Service et retour'), findsNothing);
      await see(tester, find.text('Coach Sonia L.').last);
      await settleFonts(tester);
    });
  });
}
