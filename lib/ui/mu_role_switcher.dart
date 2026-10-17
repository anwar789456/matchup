import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_bottom_sheet.dart';
import 'src/interaction.dart';
import '../l10n/l10n.dart';

/// A role the account holds (or can add): « Joueur · Padel 3,5 · La Marsa », « Propriétaire de
/// terrain · Configuration à terminer · 3 étapes ».
@immutable
class MuRole {
  const MuRole({
    required this.id,
    required this.name,
    required this.icon,
    this.detail,
    this.pending = 0,
    this.semanticLabel,
  });

  final String id;
  final String name;
  final IconData icon;
  final String? detail;

  /// Things to finish in that role, shown as a counter.
  final int pending;
  final String? semanticLabel;
}

/// RoleSwitcher (components/RoleSwitcher.md), sheet variant (PRF-06): one row per role, a check
/// on the current one, then « Ajouter un rôle ».
class MuRoleSwitcher extends StatelessWidget {
  MuRoleSwitcher({
    super.key,
    required this.roles,
    required this.current,
    required this.onChanged,
    this.onAddRole,
    String? addRoleLabel,
    String? addRoleDetail,
  }) : addRoleDetail = addRoleDetail ?? l10n.coachOuOrganisateurDeTournois, addRoleLabel = addRoleLabel ?? l10n.ajouterUnRole;

  final List<MuRole> roles;
  final String current;
  final ValueChanged<MuRole> onChanged;
  final VoidCallback? onAddRole;
  final String addRoleLabel;
  final String addRoleDetail;

  // RoleSwitcher.md: rows 56 high, radius-md, padding s2 / s3, gap s3; the icon tile 44.
  static const double _row = 56;
  static const double _tile = MuSize.touchTarget;

  static Future<void> show(
    BuildContext context, {
    required List<MuRole> roles,
    required String current,
    required ValueChanged<MuRole> onChanged,
    VoidCallback? onAddRole,
  }) => MuBottomSheet.show<void>(
    context,
    title: l10n.changerDeRole,
    height: MuSheetHeight.auto,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
      child: MuRoleSwitcher(
        roles: roles,
        current: current,
        onChanged: (r) {
          Navigator.of(context, rootNavigator: true).pop();
          onChanged(r);
        },
        onAddRole: onAddRole == null
            ? null
            : () {
                Navigator.of(context, rootNavigator: true).pop();
                onAddRole();
              },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    Widget row({
      required Widget tile,
      required String title,
      String? detail,
      Widget? end,
      required VoidCallback? onTap,
      bool selected = false,
      String? semanticLabel,
    }) => Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? '$title${selected ? l10n.roleActuel : ''}',
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.mdAll,
        child: InkWell(
          borderRadius: MuRadius.mdAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _row),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s2),
              child: Row(
                children: [
                  tile,
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: MuType.label.copyWith(color: c.text)),
                        if (detail != null)
                          Text(detail, style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                  if (end != null) ...[const SizedBox(width: MuSpace.s3), end],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in roles)
          row(
            tile: Container(
              width: _tile,
              height: _tile,
              decoration: BoxDecoration(
                color: r.id == current ? c.accent : c.surfaceMuted,
                borderRadius: MuRadius.smAll,
              ),
              child: Icon(r.icon, size: MuSize.iconM, color: r.id == current ? c.onAccent : c.text),
            ),
            title: r.name,
            detail: r.detail,
            selected: r.id == current,
            semanticLabel: r.semanticLabel,
            end: r.id == current
                ? Icon(
                    PhosphorIcons.check(PhosphorIconsStyle.bold),
                    size: MuSize.iconS,
                    color: c.text,
                  )
                : r.pending > 0
                ? Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.error, borderRadius: MuRadius.fullAll),
                    child: Text(
                      '${r.pending}',
                      style: MuType.labelS.copyWith(color: c.onDestructive),
                    ),
                  )
                : null,
            onTap: r.id == current ? null : () => onChanged(r),
          ),
        if (onAddRole != null) ...[
          const SizedBox(height: MuSpace.s2),
          Divider(height: 1, thickness: 1, color: c.border),
          const SizedBox(height: MuSpace.s2),
          row(
            tile: Container(
              width: _tile,
              height: _tile,
              decoration: BoxDecoration(
                borderRadius: MuRadius.smAll,
                border: Border.all(color: c.borderStrong),
              ),
              child: Icon(PhosphorIcons.plus(), size: MuSize.iconM, color: c.textSecondary),
            ),
            title: addRoleLabel,
            detail: addRoleDetail,
            onTap: onAddRole,
          ),
        ],
      ],
    );
  }
}
