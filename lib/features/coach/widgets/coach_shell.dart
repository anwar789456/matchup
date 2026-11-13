import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../profile/widgets/account_menu.dart';
import '../data/coach_story.dart';

/// The coach space's frame (CLAUDE.md rule 14): Tableau · Programmes · Élèves · Revenus, each tab
/// keeping its own stack.
class CoachShell extends StatelessWidget {
  const CoachShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static List<MuTabItem> tabs() => [
    MuTabItem(
      icon: PhosphorIcons.house(),
      selectedIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
      label: l10n.coaTabDashboard,
    ),
    MuTabItem(
      icon: PhosphorIcons.clipboardText(),
      selectedIcon: PhosphorIcons.clipboardText(PhosphorIconsStyle.fill),
      label: l10n.coaTabPrograms,
    ),
    MuTabItem(
      icon: PhosphorIcons.users(),
      selectedIcon: PhosphorIcons.users(PhosphorIconsStyle.fill),
      label: l10n.coaTabStudents,
    ),
    MuTabItem(
      icon: PhosphorIcons.coins(),
      selectedIcon: PhosphorIcons.coins(PhosphorIconsStyle.fill),
      label: l10n.coaTabEarnings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.bg,
      body: shell,
      bottomNavigationBar: MuTabBar(
        items: tabs(),
        index: shell.currentIndex,
        onChanged: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

/// « Espace coach » with the whistle, the tab's h1 (and an optional count after it), [actions],
/// then Karim's avatar, which opens the role switcher (PRF-06).
class CoachHeader extends StatelessWidget {
  const CoachHeader({
    super.key,
    required this.title,
    this.count,
    this.subtitle,
    this.actions = const [],
  });

  final String title;

  /// « Élèves 38 ».
  final int? count;
  final String? subtitle;
  final List<Widget> actions;

  static const double _pillIcon = 14;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MuSpace.s2,
                      vertical: MuSpace.s1 / 2,
                    ),
                    decoration: ShapeDecoration(
                      color: c.surface,
                      shape: StadiumBorder(side: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          MuGlyph.whistle,
                          width: _pillIcon,
                          height: _pillIcon,
                          colorFilter: ColorFilter.mode(c.text, BlendMode.srcIn),
                        ),
                        const SizedBox(width: MuSpace.s1),
                        Text(l10n.coaSpace, style: MuType.labelS.copyWith(color: c.text)),
                      ],
                    ),
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Semantics(
                    header: true,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: title),
                          if (count != null)
                            TextSpan(
                              text: ' $count',
                              style: MuType.numL.copyWith(color: c.textSecondary),
                            ),
                        ],
                      ),
                      style: MuType.h1.copyWith(color: c.text),
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: MuType.body.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            for (final a in actions) ...[a, const SizedBox(width: MuSpace.s2)],
            Semantics(
              button: true,
              label: l10n.coaSwitchRole(CoachStory.coachName),
              excludeSemantics: true,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => showRoleSwitcher(context, current: 'coach'),
                child: const Padding(
                  padding: EdgeInsets.all(MuSpace.s1 / 2),
                  child: MuAvatar(name: CoachStory.coachName, size: MuAvatarSize.m),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section title (`h2`) with an optional count badge and an end action or trailing widget.
class CoachSection extends StatelessWidget {
  const CoachSection({
    super.key,
    required this.title,
    this.badge,
    this.action,
    this.onAction,
    this.trailing,
  });

  final String title;
  final int? badge;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: MuSpace.s4,
        end: action == null ? MuSpace.s4 : MuSpace.s1,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MuSize.controlS),
        child: Row(
          children: [
            Semantics(
              header: true,
              child: Text(title, style: MuType.h2.copyWith(color: c.text)),
            ),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: MuSpace.s2),
              MuCounter(value: badge!),
            ],
            const Spacer(),
            if (action != null)
              MuButton.tertiary(label: action!, size: MuButtonSize.s, onPressed: onAction ?? () => showComingSoon(context))
            else
              ?trailing,
          ],
        ),
      ),
    );
  }
}
