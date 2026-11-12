import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../common/widgets/coming_soon.dart';
import 'screens/lesson_done_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/program_screen.dart';
import 'screens/programs_screen.dart';

/// The Entraînement tab's routes, named by screen code (ENT-01…09). [trainingRoutes] are the
/// children of `/training` (the tab root, ENT-01) in the player shell.
abstract final class TrainingRoutes {
  static const root = '/training'; // ENT-01
  static const programs = '/training/programs'; // ENT-02
  static String program(String id) => '/training/program/$id'; // ENT-03
  static String lesson(String id, int index) => '/training/program/$id/lesson/$index'; // ENT-04
  static String lessonDone(String id, int index) =>
      '/training/program/$id/lesson/$index/done'; // ENT-05
  static const planGoals = '/training/plan'; // ENT-06
  static const plan = '/training/plan/week'; // ENT-07
  static const video = '/training/video'; // ENT-08
  static const videoResult = '/training/video/result'; // ENT-09
}

int _index(GoRouterState s) => int.tryParse(s.pathParameters['index'] ?? '') ?? 1;

/// ENT-02 keeps the tab bar (it is drawn on its PNG); the other pages cover it ([rootKey]).
List<RouteBase> trainingRoutes(GlobalKey<NavigatorState> rootKey) {
  GoRoute page(String path, Widget Function(GoRouterState state) build) => GoRoute(
    path: path,
    parentNavigatorKey: rootKey,
    builder: (context, state) => build(state),
  );

  Widget soon(String title) => ComingSoonScreen(title: title, fallback: TrainingRoutes.root);

  return [
    GoRoute(path: 'programs', builder: (context, state) => const ProgramsScreen()),
    page('program/:id', (s) => ProgramScreen(programId: s.pathParameters['id']!)),
    page(
      'program/:id/lesson/:index',
      (s) => LessonScreen(programId: s.pathParameters['id']!, index: _index(s)),
    ),
    page(
      'program/:id/lesson/:index/done',
      (s) => LessonDoneScreen(programId: s.pathParameters['id']!, index: _index(s)),
    ),
    page('plan', (s) => soon(l10n.entTrainingPlan)),
    page('plan/week', (s) => soon(l10n.entTrainingPlan)),
    page('video', (s) => soon(l10n.entAnalyseVideoTitle)),
    page('video/result', (s) => soon(l10n.entAnalyseVideoTitle)),
  ];
}
