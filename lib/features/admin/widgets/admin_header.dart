import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../profile/widgets/account_menu.dart';
import '../../../l10n/l10n.dart';

/// The header of the admin tabs (ADM-01, 02, 05, 06, 09): the « Admin » pill over the tab's h1
/// and its [subtitle], then Leila's avatar, which opens the role switcher (PRF-06).
class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          MuSpace.s4,
          MuSpace.s2,
          MuSpace.s2,
          MuSpace.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AdminRolePill(),
                  const SizedBox(height: MuSpace.s2),
                  Semantics(
                    header: true,
                    child: Text(title, style: MuType.h1.copyWith(color: c.text)),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: MuSpace.s2),
                    Text(subtitle!, style: MuType.body.copyWith(color: c.textSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: MuSpace.s3),
            Semantics(
              button: true,
              label: l10n.adminChangerDeRole(Story.adminName),
              excludeSemantics: true,
              child: InkResponse(
                onTap: () => showRoleSwitcher(context, current: 'admin'),
                radius: MuSize.touchTarget / 2,
                child: const SizedBox.square(
                  dimension: MuSize.controlL,
                  child: Center(
                    child: MuAvatar(name: Story.adminName, size: MuAvatarSize.s),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Admin » on `surface-inverse`, with the filled shield.
class AdminRolePill extends StatelessWidget {
  const AdminRolePill({super.key});

  // adm-role: 24 high, padding 0 10 0 8, shield 14.
  static const double _height = 24;
  static const double _endPad = 10;
  static const double _icon = 14;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      height: _height,
      padding: const EdgeInsetsDirectional.only(start: MuSpace.s2, end: _endPad),
      decoration: BoxDecoration(color: c.surfaceInverse, borderRadius: MuRadius.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
            size: _icon,
            color: c.textInverse,
          ),
          const SizedBox(width: MuSpace.s1),
          Text(l10n.admin, style: MuType.labelS.copyWith(color: c.textInverse)),
        ],
      ),
    );
  }
}
