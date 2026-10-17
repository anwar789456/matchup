import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../l10n/l10n.dart';

enum MuStepVariant { bar, dots }

/// StepIndicator (components/StepIndicator.md): « Étape 2 sur 8 · Tes sports » over a segmented
/// bar, or carousel dots. [step] is 1-based.
class MuStepIndicator extends StatelessWidget {
  const MuStepIndicator({
    super.key,
    required this.step,
    required this.total,
    this.variant = MuStepVariant.bar,
    this.title,
    this.showLabel = false,
  });

  final int step;
  final int total;
  final MuStepVariant variant;

  /// Step name shown after the count (« Tes sports »).
  final String? title;

  /// Dots only: show « 2 sur 4 » above.
  final bool showLabel;

  // StepIndicator.md: bar segments 4 px high; dots 8 px, the current one a 24 × 8 pill.
  static const double _segment = 4;
  static const double _dot = 8;
  static const double _dotCurrent = 24;

  @override
  Widget build(BuildContext context) {
    return variant == MuStepVariant.bar ? _bar(context) : _dots(context);
  }

  Widget _bar(BuildContext context) {
    final c = context.mu;
    final slow = MuMotion.durationOf(context, MuMotion.slow);
    final valueText = l10n.etapeSur2(step, total, title != null ? ' : $title' : '');
    return Semantics(
      label: valueText,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: l10n.etapeSur(step, total)),
              if (title != null) ...[
                const TextSpan(text: ' · '),
                TextSpan(text: title, style: MuType.labelS.copyWith(color: c.text)),
              ],
            ]),
            style: MuType.labelS.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s2),
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: MuSpace.s1),
                Expanded(
                  child: Container(
                    height: _segment,
                    decoration: BoxDecoration(
                      color: i < step ? c.primary : c.border,
                      borderRadius: MuRadius.xsAll,
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: AlignmentDirectional.centerStart,
                    child: i == step
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 0.5),
                            duration: slow,
                            curve: MuMotion.move,
                            builder: (context, f, _) => FractionallySizedBox(
                              widthFactor: f,
                              heightFactor: 1,
                              child: ColoredBox(color: c.primary),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dots(BuildContext context) {
    final c = context.mu;
    final base = MuMotion.durationOf(context, MuMotion.base);
    return Semantics(
      label: l10n.diapoSur(step, total),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Text(l10n.stepOfTotal(step, total), style: MuType.labelS.copyWith(color: c.textSecondary)),
            const SizedBox(height: MuSpace.s2),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: MuSpace.s2),
                AnimatedContainer(
                  duration: base,
                  curve: MuMotion.move,
                  width: i == step ? _dotCurrent : _dot,
                  height: _dot,
                  decoration: BoxDecoration(
                    color: i == step
                        ? c.primary
                        : (i < step ? c.textSecondary : c.borderStrong),
                    borderRadius: MuRadius.fullAll,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
