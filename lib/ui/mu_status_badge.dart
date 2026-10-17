import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import '../l10n/l10n.dart';

enum MuStatus { confirmed, paid, pending, failed, live, refunded, full, verified, cancelled, draft, neutral }

enum MuBadgeSize { m, s }

/// StatusBadge (components/StatusBadge.md): a state as colour + icon + word. [label] overrides the
/// default word (« RIB en vérification »).
///
/// The pulsing `live` dot comes with the live-scores milestone; `live` shows its dot still.
class MuStatusBadge extends StatelessWidget {
  const MuStatusBadge({
    super.key,
    required this.status,
    this.label,
    this.size = MuBadgeSize.m,
    this.iconOnly = false,
  });

  final MuStatus status;
  final String? label;
  final MuBadgeSize size;

  /// A 24 circle with the icon only; the label becomes its tooltip.
  final bool iconOnly;

  // StatusBadge.md: M 24 high, padding 8 / 10, icon 16; S 20, 6 / 8, icon 14; live dot 8.
  static const double _heightM = 24;
  static const double _heightS = 20;
  static const double _iconS = 14;
  static const double _liveDot = 8;
  static const double _padStartS = 6;
  static const double _padEndM = 10;

  String get _defaultLabel => switch (status) {
        MuStatus.confirmed => l10n.confirme2,
        MuStatus.paid => l10n.paye,
        MuStatus.pending => l10n.enAttente,
        MuStatus.failed => l10n.echec,
        MuStatus.live => l10n.enDirect3,
        MuStatus.refunded => l10n.rembourse2,
        MuStatus.full => l10n.complet,
        MuStatus.verified => l10n.verifie,
        MuStatus.cancelled => l10n.annule2,
        MuStatus.draft => l10n.brouillon,
        MuStatus.neutral => '',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final small = size == MuBadgeSize.s;
    const fill = PhosphorIconsStyle.fill;
    final (Color ground, Color ink, IconData? icon, bool ring) = switch (status) {
      MuStatus.confirmed || MuStatus.paid =>
        (c.successSoft, c.successText, PhosphorIcons.checkCircle(fill), false),
      MuStatus.pending => (c.warningSoft, c.warningText, PhosphorIcons.clock(fill), false),
      MuStatus.failed => (c.errorSoft, c.errorText, PhosphorIcons.warningCircle(fill), false),
      MuStatus.live => (c.errorSoft, c.errorText, null, false),
      MuStatus.refunded => (c.infoSoft, c.infoText, PhosphorIcons.arrowUUpLeft(fill), false),
      MuStatus.full => (c.surfaceInverse, c.textInverse, PhosphorIcons.usersThree(fill), false),
      MuStatus.verified => (c.accent, c.onAccent, PhosphorIcons.sealCheck(fill), false),
      MuStatus.cancelled => (c.surfaceMuted, c.textSecondary, PhosphorIcons.xCircle(fill), true),
      MuStatus.draft => (c.surfaceMuted, c.textSecondary, PhosphorIcons.notePencil(fill), true),
      MuStatus.neutral => (c.surfaceMuted, c.textSecondary, null, true),
    };
    final text = label ?? _defaultLabel;

    if (iconOnly && icon != null) {
      return Tooltip(
        message: text,
        child: Semantics(
          label: text,
          excludeSemantics: true,
          child: Container(
            width: _heightM,
            height: _heightM,
            decoration: ShapeDecoration(
              color: ground,
              shape: CircleBorder(side: ring ? BorderSide(color: c.border) : BorderSide.none),
            ),
            child: Icon(icon, size: _iconS, color: ink),
          ),
        ),
      );
    }
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        height: small ? _heightS : _heightM,
        padding: EdgeInsetsDirectional.only(
          start: small ? _padStartS : MuSpace.s2,
          end: small ? MuSpace.s2 : _padEndM,
        ),
        decoration: ShapeDecoration(
          color: ground,
          shape: StadiumBorder(side: ring ? BorderSide(color: c.border) : BorderSide.none),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: small ? _iconS : MuSize.iconXs, color: ink)
            else if (status == MuStatus.live)
              Container(
                width: _liveDot,
                height: _liveDot,
                decoration: BoxDecoration(color: c.live, shape: BoxShape.circle),
              ),
            if (icon != null || status == MuStatus.live) const SizedBox(width: MuSpace.s1),
            Text(
              status == MuStatus.live ? text.toUpperCase() : text,
              style: (status == MuStatus.live ? MuType.overline : MuType.labelS)
                  .copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}
