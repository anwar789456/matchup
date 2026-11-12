import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../common/widgets/coming_soon.dart';
import 'screens/coach_earnings_screen.dart';
import 'screens/coach_home_screen.dart';
import 'screens/coach_programs_screen.dart';
import 'screens/coach_students_screen.dart';
import 'widgets/coach_shell.dart';

/// The coach space's routes (COA-04…12), one per screen code.
abstract final class CoachRoutes {
  static const dashboard = '/coach'; // COA-04
  static const programs = '/coach/programmes'; // COA-05
  static const builder = '/coach/programmes/brouillon'; // COA-06
  static String session(String id) => '/coach/programmes/brouillon/seance/$id'; // COA-07
  static const publish = '/coach/programmes/brouillon/publication'; // COA-08
  static const students = '/coach/eleves'; // COA-09
  static String student(String id) => '/coach/eleves/$id'; // COA-10
  static String feedback(String id) => '/coach/eleves/$id/retour'; // COA-11
  static const earnings = '/coach/revenus'; // COA-12
}

/// The four tabs (Tableau · Programmes · Élèves · Revenus) and the pages over them ([rootKey]).
StatefulShellRoute coachShellRoute(GlobalKey<NavigatorState> rootKey) {
  GoRoute page(String path, Widget Function(GoRouterState state) build) => GoRoute(
    path: path,
    parentNavigatorKey: rootKey,
    builder: (context, state) => build(state),
  );

  Widget soon(String title, String fallback) => ComingSoonScreen(title: title, fallback: fallback);

  return StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => CoachShell(shell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: CoachRoutes.dashboard,
            builder: (context, state) => const CoachHomeScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: CoachRoutes.programs,
            builder: (context, state) => const CoachProgramsScreen(),
            routes: [
              page('brouillon', (s) => soon(l10n.coaBuilder, CoachRoutes.programs)),
              page('brouillon/seance/:id', (s) => soon(l10n.entSession, CoachRoutes.builder)),
              page('brouillon/publication', (s) => soon(l10n.coaPriceTitle, CoachRoutes.builder)),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: CoachRoutes.students,
            builder: (context, state) => const CoachStudentsScreen(),
            routes: [
              page(':id', (s) => soon(l10n.coaStudent, CoachRoutes.students)),
              page(':id/retour', (s) => soon(l10n.coaFeedback, CoachRoutes.students)),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: CoachRoutes.earnings,
            builder: (context, state) => const CoachEarningsScreen(),
          ),
        ],
      ),
    ],
  );
}
