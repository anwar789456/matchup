import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import 'data/assistant_models.dart';
import 'screens/assistant_screen.dart';

/// The AI assistant: a takeover over everything (Takeover.md), from the AI button or « Demande à
/// MatchUp… » (AI-01…06), and from the AI button of the owner's space (AI-07).
abstract final class AssistantRoutes {
  static const player = '/assistant'; // AI-01 … AI-06
  static const owner = '/owner/assistant'; // AI-07
}

/// Fade + 16 px rise over `duration-slow`, back over `duration-base` (Takeover.md).
Page<void> _takeover(BuildContext context, GoRouterState state, Widget child) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    fullscreenDialog: true,
    transitionDuration: reduce ? Duration.zero : MuMotion.slow,
    reverseTransitionDuration: reduce ? Duration.zero : MuMotion.base,
    child: child,
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: MuMotion.enter,
        reverseCurve: MuMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) =>
              Transform.translate(offset: Offset(0, MuSpace.s4 * (1 - curved.value)), child: child),
        ),
      );
    },
  );
}

List<RouteBase> assistantRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    path: AssistantRoutes.player,
    parentNavigatorKey: rootKey,
    pageBuilder: (context, state) => _takeover(context, state, const AssistantScreen()),
  ),
  GoRoute(
    path: AssistantRoutes.owner,
    parentNavigatorKey: rootKey,
    pageBuilder: (context, state) =>
        _takeover(context, state, const AssistantScreen(space: AssistantSpace.owner)),
  ),
];
