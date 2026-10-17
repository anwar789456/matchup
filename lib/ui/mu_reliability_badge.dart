import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_status_badge.dart';

/// ReliabilityBadge (components/ReliabilityBadge.md): « Fiable 96 % » in a pill whose tone follows
/// the score — success from 90 %, neutral from 75 %, warning under. [detail] adds the period, a
/// 4 px bar and « 48/50 matchs honorés ».
class MuReliabilityBadge extends StatelessWidget {
  const MuReliabilityBadge({
    super.key,
    required this.score,
    this.size = MuBadgeSize.m,
    this.detail = false,
    this.honored,
    this.total,
    this.period = '12 derniers mois',
  });

  /// 0–100.
  final int score;
  final MuBadgeSize size;
  final bool detail;
  final int? honored;
  final int? total;
  final String period;

  // ReliabilityBadge.md: S 20 high (6 / space-2, icon 14), M 24 (space-2 / 10, icon 16); bar 4.
  static const double _heightS = 20;
  static const double _heightM = 24;
  static const double _iconS = 14;
  static const double _padStartS = 6;
  static const double _padEndM = 10;
  static const double _bar = 4;
  static const double _detailMin = 220;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final small = size == MuBadgeSize.s;
    final (Color ground, Color ink, Color? edge, Color bar, IconData icon) = score >= 90
        ? (
            c.successSoft,
            c.successText,
            null,
            c.success,
            PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
          )
        : score >= 75
        ? (
            c.surfaceMuted,
            c.textSecondary,
            c.border,
            c.textSecondary,
            PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
          )
        : (
            c.warningSoft,
            c.warningText,
            null,
            c.warning,
            PhosphorIcons.shieldWarning(PhosphorIconsStyle.fill),
          );

    final pill = Semantics(
      label: 'Fiable $score %',
      excludeSemantics: true,
      child: Container(
        height: small ? _heightS : _heightM,
        padding: EdgeInsetsDirectional.only(
          start: small ? _padStartS : MuSpace.s2,
          end: small ? MuSpace.s2 : _padEndM,
        ),
        decoration: ShapeDecoration(
          color: ground,
          shape: StadiumBorder(side: edge == null ? BorderSide.none : BorderSide(color: edge)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: small ? _iconS : MuSize.iconXs, color: ink),
            const SizedBox(width: MuSpace.s1),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Fiable ', style: MuType.labelS),
                  TextSpan(text: '$score %', style: MuType.numXs),
                ],
              ),
              style: TextStyle(color: ink),
            ),
          ],
        ),
      ),
    );
    if (!detail) return pill;

    final h = honored ?? 0;
    final t = total ?? 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _detailMin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              pill,
              const SizedBox(width: MuSpace.s2),
              Text(period, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Semantics(
            label: 'Matchs honorés',
            value: '$h sur $t',
            child: ClipRRect(
              borderRadius: MuRadius.xsAll,
              child: Container(
                height: _bar,
                color: c.border,
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: t == 0 ? 0 : (h / t).clamp(0, 1),
                  heightFactor: 1,
                  child: ColoredBox(color: bar),
                ),
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$h/$t', style: MuType.numS),
                const TextSpan(text: ' matchs honorés'),
              ],
            ),
            style: MuType.body.copyWith(color: c.text),
          ),
        ],
      ),
    );
  }
}
