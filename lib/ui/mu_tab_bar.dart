import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_toast.dart';
import 'src/interaction.dart';
import '../l10n/l10n.dart';

/// One destination of the [MuTabBar].
@immutable
class MuTabItem {
  const MuTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
    this.badgeLabel,
  });

  final IconData icon;

  /// Fill weight, shown when active.
  final IconData selectedIcon;
  final String label;

  /// Something that needs the player (invitations, unpaid shares) — never a count of content.
  final int badge;

  /// The badge's meaning, appended to the tab name (« 1 invitation »).
  final String? badgeLabel;
}

/// TabBar (components/TabBar.md): the mobile bottom navigation with the Volt pill behind the
/// active icon. Tab widths start from their content and share the rest equally, so « Entraînement »
/// and « Communauté » never touch. Includes the bottom safe area.
class MuTabBar extends StatelessWidget {
  const MuTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.itemKeys,
  });

  final List<MuTabItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  /// Optional keys on each tab, to locate one (the guided tour points at « Mes matchs »).
  final List<GlobalKey>? itemKeys;

  // TabBar.md: pill 56 × 32; badge 18 with a 2 px surface ring; the pill grows from 40 % width.
  static const double _pillW = 56;
  static const double _pillH = 32;
  static const double _badge = 18;
  static const double _ring = 2;
  static const double _pillStart = 0.4;

  /// The five player destinations.
  static List<MuTabItem> playerTabs({int matchesBadge = 0}) => [
        MuTabItem(
          icon: PhosphorIcons.house(),
          selectedIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
          label: l10n.accueil,
        ),
        MuTabItem(
          icon: PhosphorIcons.compass(),
          selectedIcon: PhosphorIcons.compass(PhosphorIconsStyle.fill),
          label: l10n.explorer,
        ),
        MuTabItem(
          icon: PhosphorIcons.calendarCheck(),
          selectedIcon: PhosphorIcons.calendarCheck(PhosphorIconsStyle.fill),
          label: l10n.mesMatchs,
          badge: matchesBadge,
          badgeLabel: '$matchesBadge ${matchesBadge == 1 ? 'invitation' : 'invitations'}',
        ),
        MuTabItem(
          icon: PhosphorIcons.barbell(),
          selectedIcon: PhosphorIcons.barbell(PhosphorIconsStyle.fill),
          label: l10n.entrainement,
        ),
        MuTabItem(
          icon: PhosphorIcons.usersThree(),
          selectedIcon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
          label: l10n.communaute,
        ),
      ];

  static double _labelWidth(String label, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: MuType.labelS),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final scaler = MediaQuery.textScalerOf(context);

    // Content width of each tab: its label or the pill, whichever is wider.
    final widths = [
      for (final item in items) math.max(_pillW, _labelWidth(item.label, scaler)),
    ];

    // Toasts stay above the tab bar.
    return MuToastAnchor(
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surface, boxShadow: MuElevation.of(context).level2Up),
        child: SafeArea(
          top: false,
          child: Semantics(
            container: true,
            label: l10n.navigationPrincipale,
            child: SizedBox(
              height: MuSize.tabBar,
              child: LayoutBuilder(builder: (context, constraints) {
                final available = constraints.maxWidth - MuSpace.s1 * 2;
                final total = widths.fold<double>(0, (a, b) => a + b);
                final extra = math.max(0.0, (available - total) / items.length);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        SizedBox(
                          width: total > available
                              ? available / items.length
                              : widths[i] + extra,
                          key: itemKeys?[i],
                          child: _Tab(
                            item: items[i],
                            active: i == index,
                            onTap: () => onChanged(i),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final MuTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final duration = MuMotion.durationOf(context, MuMotion.base);
    final name = item.badge > 0 && item.badgeLabel != null
        ? '${item.label}, ${item.badgeLabel}'
        : item.label;

    final pill = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: duration,
          curve: MuMotion.move,
          width: active ? MuTabBar._pillW : MuTabBar._pillW * MuTabBar._pillStart,
          height: MuTabBar._pillH,
          decoration: BoxDecoration(
            color: active ? c.accent : Colors.transparent,
            borderRadius: MuRadius.fullAll,
          ),
        ),
        Icon(
          active ? item.selectedIcon : item.icon,
          size: MuSize.iconM,
          color: active ? c.onAccent : c.textSecondary,
        ),
        if (item.badge > 0)
          PositionedDirectional(
            top: -MuTabBar._ring,
            end: MuSpace.s2,
            child: Container(
              constraints: const BoxConstraints(minWidth: MuTabBar._badge + MuTabBar._ring * 2),
              height: MuTabBar._badge + MuTabBar._ring * 2,
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.destructive,
                borderRadius: MuRadius.fullAll,
                border: Border.all(color: c.surface, width: MuTabBar._ring),
              ),
              child: Text('${item.badge}', style: MuType.labelS.copyWith(color: c.onDestructive)),
            ),
          ),
      ],
    );

    return Semantics(
      button: true,
      selected: active,
      label: name,
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: MuRadius.mdAll,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: MuTabBar._pillW, height: MuTabBar._pillH, child: pill),
              const SizedBox(height: MuSpace.s1),
              Text(
                item.label,
                maxLines: 1,
                softWrap: false,
                style: MuType.labelS.copyWith(color: active ? c.text : c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
