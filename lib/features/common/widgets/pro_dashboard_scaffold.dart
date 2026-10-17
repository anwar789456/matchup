import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/session.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import 'pro_wizard_scaffold.dart' show showComingSoon;
import '../../../l10n/l10n.dart';

/// The person's sidebar choice; null follows the window (collapsed below 1200).
class SidebarCollapsed extends Notifier<bool?> {
  @override
  bool? build() => null;

  void set(bool value) => state = value;
}

final sidebarCollapsedProvider = NotifierProvider<SidebarCollapsed, bool?>(SidebarCollapsed.new);

/// The desktop dashboard frame (OWN-09, COA-03, ORG-02): [MuSidebar] + [MuTopBar], an optional
/// strip [banner] under the bar, and the scrolling page (padding 32). Below 840 the sidebar moves
/// into a drawer opened from the bar.
class ProDashboardScaffold extends ConsumerWidget {
  const ProDashboardScaffold({
    super.key,
    required this.sections,
    required this.role,
    required this.user,
    required this.userRole,
    required this.body,
    this.title = 'Tableau de bord',
    this.activeId = 'dashboard',
    this.notifications = 0,
    this.banner,
  });

  final List<MuNavSection> sections;
  final MuSidebarRole role;
  final MuSidebarUser user;

  /// Under the name in the bar (« Propriétaire », « Organisatrice »).
  final String userRole;
  final String title;
  final String activeId;
  final int notifications;
  final Widget? banner;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final width = MediaQuery.sizeOf(context).width;
    final docked = width >= MuLayout.bpExpanded;
    final narrow = width < MuLayout.bpMedium;
    final collapsed = ref.watch(sidebarCollapsedProvider) ?? width < MuLayout.bpLarge;

    void navigate(String id) {
      if (id != activeId) showComingSoon(context);
    }

    MuSidebar sidebar({required bool collapsed, ValueChanged<bool>? onCollapsed}) => MuSidebar(
      sections: sections,
      activeId: activeId,
      role: role,
      user: user,
      collapsed: collapsed,
      onCollapsedChanged: onCollapsed,
      onNavigate: navigate,
      onRole: () => showComingSoon(context),
      onHelp: () => showComingSoon(context),
      onUserMenu: () => showComingSoon(context),
    );

    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (context) => MuTopBar(
            title: title,
            userName: user.name,
            userRole: userRole,
            userEmail: user.email,
            notifications: notifications,
            onSearch: () => showComingSoon(context),
            onAssistant: () => showComingSoon(context),
            onNotifications: () => showComingSoon(context),
            leading: docked
                ? null
                : MuIconButton(
                    icon: PhosphorIcons.list(),
                    label: l10n.ouvrirLeMenu,
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
            menuItems: [
              MuMenuEntry(
                label: l10n.monProfil,
                icon: PhosphorIcons.user(),
                onPressed: () => showComingSoon(context),
              ),
              MuMenuEntry(
                label: l10n.parametres,
                icon: PhosphorIcons.gearSix(),
                onPressed: () => showComingSoon(context),
              ),
              MuMenuEntry(
                label: l10n.changerDeRole,
                icon: PhosphorIcons.arrowsLeftRight(),
                onPressed: () => context.go(Routes.roles),
              ),
              MuMenuEntry(
                label: l10n.seDeconnecter,
                icon: PhosphorIcons.signOut(),
                separated: true,
                onPressed: () async {
                  await ref.read(sessionProvider.notifier).signOut();
                  if (context.mounted) context.go(Routes.login);
                },
              ),
            ],
          ),
        ),
        ?banner,
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(narrow ? MuSpace.s4 : MuLayout.gridDesktopMargin),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: MuSize.contentMax),
                child: body,
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: c.bg,
      drawer: docked
          ? null
          : Drawer(
              width: MuSize.sidebar,
              shape: const RoundedRectangleBorder(),
              child: sidebar(collapsed: false),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (docked)
              sidebar(
                collapsed: collapsed,
                onCollapsed: (v) => ref.read(sidebarCollapsedProvider.notifier).set(v),
              ),
            Expanded(child: page),
          ],
        ),
      ),
    );
  }
}

/// [children] in [columns] equal columns (gap 24), each row as tall as its tallest card.
class ProCardRow extends StatelessWidget {
  const ProCardRow({super.key, required this.children, required this.columns});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    const gap = MuSpace.s6;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i += columns) ...[
          if (i > 0) const SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: gap),
                  Expanded(child: i + j < children.length ? children[i + j] : const SizedBox()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A wide card beside a narrow one (2 : 1, gap 24), or [narrowRatio] below 1200; stacked below
/// 960 (dashboard sources: `db-cols`).
class ProSplit extends StatelessWidget {
  const ProSplit({super.key, required this.start, required this.end, this.narrowRatio = (2, 1)});

  final Widget start;
  final Widget end;

  /// Flex of the two cards between 960 and 1200 (1,3 : 1 next to an AI card).
  final (int, int) narrowRatio;

  static const double stackBelow = 960;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < stackBelow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          start,
          const SizedBox(height: MuSpace.s6),
          end,
        ],
      );
    }
    final (a, b) = width < MuLayout.bpLarge ? narrowRatio : (2, 1);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: a, child: start),
          const SizedBox(width: MuSpace.s6),
          Expanded(flex: b, child: end),
        ],
      ),
    );
  }
}

/// The white dashboard card (`radius-md`, `elevation-1`).
class ProCard extends StatelessWidget {
  const ProCard({super.key, required this.child, this.padding = const EdgeInsets.all(MuSpace.s6)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: child,
    );
  }
}
