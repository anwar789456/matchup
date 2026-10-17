import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';

/// ProgressRing (components/ProgressRing.md): circular progress at 32 / 48 / 72 / 120 with the
/// value in the centre (« 3/12 » or « 62 % »); complete, it turns into the success medal. Starts
/// at 12 o'clock, clockwise, never mirrored in RTL.
class MuProgressRing extends StatelessWidget {
  const MuProgressRing({
    super.key,
    required this.value,
    this.max = 100,
    this.size = 48,
    this.tone = MuTone.primary,
    this.unit,
    this.label,
    this.percent,
  });

  final double value;
  final double max;

  /// 32, 48, 72 or 120.
  final double size;
  final MuTone tone;

  /// « séances »: shows a fraction with the unit under it (120 only).
  final String? unit;

  /// What is measured, for screen readers (« Profil complété »).
  final String? label;

  /// Forces « 62 % » (default when [max] is 100 and there is no unit).
  final bool? percent;

  // ProgressRing.md: strokes 4 / 5 / 6 / 8; checks 16 / 20 / 28 / 40; medal inset stroke + 3.
  double get _stroke => size <= 32 ? 4 : size <= 48 ? 5 : size <= 72 ? 6 : 8;
  double get _check => size <= 32 ? 16 : size <= 48 ? 20 : size <= 72 ? 28 : 40;
  static const double _medalInset = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final done = value >= max;
    final asPercent = percent ?? (unit == null && max == 100);
    final text = asPercent
        ? '${(value / max * 100).round()} %'
        : '${formatAmount(value)}/${formatAmount(max)}';
    final arc = done ? c.success : tone.color(c);
    final centreStyle = size <= 48 ? MuType.numXs : size <= 72 ? MuType.numM : MuType.numXl;
    final duration = MuMotion.durationOf(context, MuMotion.counter);

    return Semantics(
      label: label,
      value: asPercent ? text : '${formatAmount(value)} sur ${formatAmount(max)}${unit == null ? '' : ' $unit'}',
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: (value / max).clamp(0, 1)),
          duration: duration,
          curve: MuMotion.move,
          builder: (context, t, _) => CustomPaint(
            painter: _RingPainter(
              t: t,
              stroke: _stroke,
              track: c.border,
              arc: arc,
              ai: tone == MuTone.ai && !done,
              from: c.aiGradientFrom,
              to: c.aiGradientTo,
            ),
            child: done
                ? Padding(
                    padding: EdgeInsets.all(_stroke + _medalInset),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: c.successSoft, shape: BoxShape.circle),
                      child: Center(
                        child: Icon(
                          PhosphorIcons.check(PhosphorIconsStyle.bold),
                          size: _check,
                          color: c.successText,
                        ),
                      ),
                    ),
                  )
                : size <= 32
                ? null
                : Center(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(text, style: centreStyle.copyWith(color: c.text)),
                          if (unit != null && size >= 120)
                            Text(unit!, style: MuType.caption.copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.t,
    required this.stroke,
    required this.track,
    required this.arc,
    required this.ai,
    required this.from,
    required this.to,
  });

  final double t;
  final double stroke;
  final Color track;
  final Color arc;
  final bool ai;
  final Color from;
  final Color to;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (t <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = arc;
    if (ai) {
      paint.shader = SweepGradient(
        colors: [from, to],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    }
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * t, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.arc != arc || old.track != track;
}
