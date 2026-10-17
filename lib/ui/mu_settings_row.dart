import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';

/// One row of a settings list (SET-01…): an icon tile, a title with an optional description, a
/// value at the end and a chevron. `destructive` paints it in `destructive` (« Supprimer le
/// compte »). Group rows in a [MuSettingsGroup].
class MuSettingsRow extends StatelessWidget {
  const MuSettingsRow({
    super.key,
    required this.title,
    this.icon,
    this.description,
    this.value,
    this.trailing,
    this.chevron = true,
    this.destructive = false,
    this.onTap,
    this.semanticValue,
  });

  final String title;
  final IconData? icon;
  final String? description;

  /// « yassine.b@email.tn », « 2FA activée ».
  final String? value;

  /// Replaces the value and chevron (a switch, a badge).
  final Widget? trailing;
  final bool chevron;
  final bool destructive;
  final VoidCallback? onTap;
  final String? semanticValue;

  // SET-01: rows 56 high, a 36 icon tile on surface-muted, padding s4.
  static const double _minHeight = 56;
  static const double _tile = 36;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final ink = destructive ? c.destructive : c.text;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s2),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(
                  color: destructive ? c.errorSoft : c.surfaceMuted,
                  borderRadius: MuRadius.smAll,
                ),
                child: Icon(icon, size: MuSize.iconS, color: ink),
              ),
              const SizedBox(width: MuSpace.s3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: MuType.label.copyWith(color: ink)),
                  if (description != null)
                    Text(description!, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (value != null) ...[
                const SizedBox(width: MuSpace.s2),
                Flexible(
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MuType.body.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
              if (chevron && onTap != null) ...[
                const SizedBox(width: MuSpace.s2),
                Icon(PhosphorIcons.caretRight(), size: MuSize.iconXs, color: c.textSecondary),
              ],
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: title,
      value: semanticValue ?? value,
      excludeSemantics: trailing == null,
      child: MuFocusRing(
        borderRadius: BorderRadius.zero,
        child: InkWell(onTap: onTap, child: row),
      ),
    );
  }
}

/// A card of rows with 1 px rules between them, under an optional overline (« COMPTE »).
class MuSettingsGroup extends StatelessWidget {
  const MuSettingsGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, bottom: MuSpace.s2),
            child: Semantics(
              header: true,
              child: Text(
                title!.toUpperCase(),
                style: MuType.overline.copyWith(color: c.textSecondary),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: MuRadius.mdAll,
            boxShadow: MuElevation.of(context).level1,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: c.border,
                    indent: MuSpace.s4,
                    endIndent: MuSpace.s4,
                  ),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
