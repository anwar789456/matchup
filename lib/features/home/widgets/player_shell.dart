import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../assistant/assistant_routes.dart';
import '../../training/controllers/training_reminders.dart';
import '../controllers/home_providers.dart';

/// The player app's frame: the five tabs (TabBar.md) around the current branch, each tab keeping
/// its own navigation stack, and the AI FAB above the bar on Accueil and Explorer.
class PlayerShell extends ConsumerWidget {
  const PlayerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  // The FAB sits on Accueil, Explorer, Entraînement and Communauté (HOM-01, EXP-01, ENT-01/02,
  // FRM-01).
  static const _fabTabs = {0, 1, 3, 4};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final invitations = ref.watch(upcomingMatchesProvider).value?.invitations.length ?? 0;
    // Keeps the « Rappels de séance » timer running while the player app is open.
    ref.watch(trainingReminderSchedulerProvider);
    return Scaffold(
      backgroundColor: c.bg,
      body: shell,
      bottomNavigationBar: MuTabBar(
        items: MuTabBar.playerTabs(matchesBadge: invitations),
        index: shell.currentIndex,
        itemKeys: ref.watch(playerTabKeysProvider),
        // Tapping the current tab again goes back to its root.
        onChanged: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
      floatingActionButton: _fabTabs.contains(shell.currentIndex)
          ? MuFab(onPressed: () => context.push(AssistantRoutes.player))
          : null,
    );
  }
}
