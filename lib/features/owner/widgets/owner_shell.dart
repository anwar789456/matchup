import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../../l10n/l10n.dart';

/// The owner space's frame (CLAUDE.md rule 14): Aujourd’hui · Planning · Check-in ·
/// Réservations · Plus, each tab keeping its own stack, and the AI FAB (AI-07, later milestone).
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const checkInTab = 2;

  static List<MuTabItem> tabs() => [
    MuTabItem(
      icon: PhosphorIcons.house(),
      selectedIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
      label: l10n.aujourdHui2,
    ),
    MuTabItem(
      icon: PhosphorIcons.calendarBlank(),
      selectedIcon: PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill),
      label: l10n.planning,
    ),
    MuTabItem(
      icon: PhosphorIcons.qrCode(),
      selectedIcon: PhosphorIcons.qrCode(PhosphorIconsStyle.fill),
      label: l10n.checkIn,
    ),
    MuTabItem(
      icon: PhosphorIcons.listChecks(),
      selectedIcon: PhosphorIcons.listChecks(PhosphorIconsStyle.fill),
      label: l10n.reservations,
    ),
    MuTabItem(
      icon: PhosphorIcons.dotsThree(),
      selectedIcon: PhosphorIcons.dotsThree(PhosphorIconsStyle.fill),
      label: l10n.plus,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // The check-in tab is a camera screen: it stays in Night match (OWN-20).
    if (shell.currentIndex == checkInTab && Theme.of(context).brightness == Brightness.light) {
      return MuNightTheme(child: Builder(builder: _scaffold));
    }
    return _scaffold(context);
  }

  Widget _scaffold(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.bg,
      body: shell,
      bottomNavigationBar: MuTabBar(
        items: tabs(),
        index: shell.currentIndex,
        onChanged: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
      floatingActionButton: MuFab(onPressed: () => showComingSoon(context)),
    );
  }
}
