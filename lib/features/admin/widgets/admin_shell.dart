import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/admin_repository.dart';
import '../../../l10n/l10n.dart';

/// The admin space's frame (CLAUDE.md rule 14): Vue · Utilisateurs · Vérifications · Modération ·
/// Finance, each tab keeping its own stack, the open reports on Modération, and the AI FAB
/// (later milestone). ADM-02 hides the tab bar while several accounts are selected.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const usersTab = 1;

  static List<MuTabItem> tabs({int reports = 0}) => [
    MuTabItem(
      icon: PhosphorIcons.gauge(),
      selectedIcon: PhosphorIcons.gauge(PhosphorIconsStyle.fill),
      label: l10n.vue,
    ),
    MuTabItem(
      icon: PhosphorIcons.users(),
      selectedIcon: PhosphorIcons.users(PhosphorIconsStyle.fill),
      label: l10n.utilisateurs,
    ),
    MuTabItem(
      icon: PhosphorIcons.sealCheck(),
      selectedIcon: PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
      label: l10n.verifications2,
    ),
    MuTabItem(
      icon: PhosphorIcons.flag(),
      selectedIcon: PhosphorIcons.flag(PhosphorIconsStyle.fill),
      label: l10n.moderation,
      badge: reports,
      badgeLabel: '$reports signalements',
    ),
    MuTabItem(
      icon: PhosphorIcons.chartLineUp(),
      selectedIcon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
      label: l10n.finance,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final reports = ref.watch(adminModerationProvider).value?.length ?? 0;
    final bulk = ref.watch(adminBulkModeProvider) && shell.currentIndex == usersTab;
    return Scaffold(
      backgroundColor: c.bg,
      body: shell,
      bottomNavigationBar: bulk
          ? null
          : MuTabBar(
              items: tabs(reports: reports),
              index: shell.currentIndex,
              onChanged: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            ),
      floatingActionButton: bulk ? null : MuFab(onPressed: () => showComingSoon(context)),
    );
  }
}

/// ADM-02's bulk-select mode: the sticky action bar replaces the tab bar.
class AdminBulkMode extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final adminBulkModeProvider = NotifierProvider<AdminBulkMode, bool>(AdminBulkMode.new);
