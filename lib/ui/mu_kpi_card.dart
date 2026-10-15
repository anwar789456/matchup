import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';

/// KpiCard (components/KpiCard.md): label, big tabular value (with its unit), then the change
/// over a period — or a [note] when there is nothing to compare yet. A rise is good unless
/// [upIsGood] is false (no-shows, cancellations).
///
/// The sparkline and the AI insight come with the analytics milestone.
class MuKpiCard extends StatelessWidget {
  const MuKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.deltaText,
    this.period,
    this.upIsGood = true,
    this.note,
  });

  final String label;

  /// Formatted value; « — » when there is none yet.
  final String value;
  final String? unit;

  /// Signed change (sign only matters).
  final double? delta;

  /// « +12 % ».
  final String? deltaText;
  final String? period;
  final bool upIsGood;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final empty = value == '—';
    Widget? change;
    if (delta != null && deltaText != null) {
      final flat = delta == 0;
      final good = flat ? null : (delta! > 0) == upIsGood;
      final color = good == null ? c.textSecondary : (good ? c.successText : c.errorText);
      change = Row(
        children: [
          Icon(
            flat
                ? PhosphorIcons.minus()
                : (delta! > 0 ? PhosphorIcons.trendUp() : PhosphorIcons.trendDown()),
            size: MuSize.iconXs,
            color: color,
          ),
          const SizedBox(width: MuSpace.s1),
          Text(deltaText!, style: MuType.numS.copyWith(color: color)),
          if (period != null) ...[
            const SizedBox(width: MuSpace.s2),
            Flexible(
              child: Text(period!, style: MuType.caption.copyWith(color: c.textSecondary)),
            ),
          ],
        ],
      );
    }

    return Semantics(
      container: true,
      label: [label, empty ? 'pas encore de valeur' : '$value${unit == null ? '' : ' $unit'}',
              ?deltaText, ?period, ?note]
          .join(', '),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s5),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: MuRadius.mdAll,
          boxShadow: MuElevation.of(context).level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: MuType.label.copyWith(color: c.textSecondary)),
            const SizedBox(height: MuSpace.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: MuType.numXl.copyWith(color: c.text)),
                if (unit != null) ...[
                  const SizedBox(width: MuSpace.s1),
                  Text(unit!, style: MuType.numM.copyWith(color: c.textSecondary)),
                ],
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            change ??
                Text(note ?? '', style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}
