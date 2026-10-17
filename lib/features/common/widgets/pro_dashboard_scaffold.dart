import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/session.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../../l10n/l10n.dart';
import 'pro_wizard_scaffold.dart' show ProPhoneFrame, ProSpace, showComingSoon;

/// The phone page of a pro space's first dashboard (OWN-09, COA-03, ORG-02), drawn wide in the
/// designs and reflowed to one column: the header (the space pill, the bell, the account avatar
/// that opens « Mon compte »), an optional strip [banner] under it, then the scrolling [body]
/// with its cards stacked.
class ProDashboardScaffold extends ConsumerWidget {
  const ProDashboardScaffold({
    super.key,
    required this.space,
    required this.userName,
    required this.userRole,
    required this.body,
    this.userEmail = '',
    this.userImage,
    this.notifications = 0,
    this.banner,
  });

  final ProSpace space;
  final String userName;

  /// Under the name in the account sheet (« Propriétaire », « Organisatrice »).
  final String userRole;
  final String userEmail;
  final ImageProvider? userImage;
  final int notifications;
  final Widget? banner;
  final Widget body;

  void _showAccount(BuildContext context, WidgetRef ref) {
    final nav = Navigator.of(context, rootNavigator: true);
    void soon() {
      nav.pop();
      showComingSoon(context);
    }

    MuBottomSheet.show<void>(
      context,
      title: l10n.monCompte,
      height: MuSheetHeight.auto,
      child: Builder(
        builder: (sheet) {
          final c = sheet.mu;
          return Padding(
            padding: const EdgeInsets.only(bottom: MuSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MuSpace.s4,
                    vertical: MuSpace.s2,
                  ),
                  child: Row(
                    children: [
                      MuAvatar(name: userName, image: userImage, size: MuAvatarSize.l),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: MuType.h3.copyWith(color: c.text)),
                            Text(
                              [userRole, if (userEmail.isNotEmpty) userEmail].join(' · '),
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Container(height: 1, color: c.border),
                MuSettingsRow(
                  icon: PhosphorIcons.userCircle(),
                  title: l10n.monProfil,
                  onTap: soon,
                ),
                MuSettingsRow(
                  icon: PhosphorIcons.gearSix(),
                  title: l10n.parametres,
                  onTap: soon,
                ),
                MuSettingsRow(
                  icon: PhosphorIcons.arrowsLeftRight(),
                  title: l10n.changerDeRole,
                  onTap: () {
                    nav.pop();
                    context.go(Routes.roles);
                  },
                ),
                Container(height: 1, color: c.border),
                MuSettingsRow(
                  icon: PhosphorIcons.signOut(),
                  title: l10n.seDeconnecter,
                  chevron: false,
                  onTap: () async {
                    nav.pop();
                    await ref.read(sessionProvider.notifier).signOut();
                    if (context.mounted) context.go(Routes.login);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;

    final header = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s2, MuSpace.s2, 0),
      child: SizedBox(
        height: MuSize.appBar,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    MuSpace.s2,
                    MuSpace.s1,
                    MuSpace.s3,
                    MuSpace.s1,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: MuRadius.fullAll,
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      space.icon(c.text, MuSize.iconXs),
                      const SizedBox(width: MuSpace.s2),
                      Flexible(
                        child: Text(
                          space.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MuType.labelS.copyWith(color: c.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            MuIconButton(
              icon: PhosphorIcons.bell(),
              label: notifications > 0
                  ? l10n.notificationsNonLues(notifications)
                  : l10n.notifications,
              size: MuIconButtonSize.l,
              badge: notifications,
              onPressed: () => showComingSoon(context),
            ),
            Semantics(
              button: true,
              label: l10n.monCompte2(userName),
              excludeSemantics: true,
              child: InkResponse(
                onTap: () => _showAccount(context, ref),
                radius: MuSize.controlL / 2,
                child: SizedBox.square(
                  dimension: MuSize.controlL,
                  child: Center(
                    child: MuAvatar(name: userName, image: userImage, size: MuAvatarSize.s),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ProPhoneFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              ?banner,
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    MuSpace.s4,
                    MuSpace.s4,
                    MuSpace.s4,
                    MuSpace.s8 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [children] in [columns] equal columns (gap 16), each row as tall as its tallest card: the
/// KPI pairs of the phone dashboards.
class ProCardRow extends StatelessWidget {
  const ProCardRow({super.key, required this.children, this.columns = 2});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    const gap = MuSpace.s4;
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

/// The dashboard card (`radius-md`, `elevation-1`), 16 inside on phones.
class ProCard extends StatelessWidget {
  const ProCard({super.key, required this.child, this.padding = const EdgeInsets.all(MuSpace.s4)});

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
