import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';

enum MuProgressVariant { bar, segmented, spots }

enum MuProgressSize { s, m, l }

/// ProgressBar (components/ProgressBar.md): continuous, segmented or game spots (confirmed solid,
/// [pending] hatched, free). Always pair it with a number — [label] + value — or a [hint].
///
/// The AvatarStack header of the spots variant comes with the GameCard milestone.
class MuProgressBar extends StatelessWidget {
  const MuProgressBar({
    super.key,
    this.value = 0,
    this.max = 100,
    this.pending = 0,
    this.variant = MuProgressVariant.bar,
    this.size = MuProgressSize.m,
    this.tone = MuTone.primary,
    this.label,
    this.unit,
    this.valueLabel,
    this.showValue = true,
    this.hint,
    this.indeterminate = false,
  });

  final double value;
  final double max;
  final double pending;
  final MuProgressVariant variant;
  final MuProgressSize size;
  final MuTone tone;
  final String? label;

  /// Unit after the fraction (« places »); without it the value shows as a percentage.
  final String? unit;

  /// Overrides the value text (« 90/150 DT »).
  final String? valueLabel;
  final bool showValue;
  final String? hint;
  final bool indeterminate;

  // ProgressBar.md: tracks 4 / 6 / 8 px; segment gaps 3 px; pending starts 2 px after the solid.
  static const double _trackS = 4;
  static const double _trackM = 6;
  static const double _trackL = 8;
  static const double _segmentGap = 3;

  double get _track => switch (size) {
        MuProgressSize.s => _trackS,
        MuProgressSize.m => _trackM,
        MuProgressSize.l => _trackL,
      };

  String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String get _valueText {
    if (valueLabel != null) return valueLabel!;
    if (unit != null) return '${_num(value)}/${_num(max)}';
    return '${(max == 0 ? 0 : value / max * 100).round()} %';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final error = tone == MuTone.error;

    final Widget track = indeterminate
        ? _Indeterminate(height: _track, color: tone.color(c))
        : variant == MuProgressVariant.bar
            ? _ContinuousTrack(
                height: _track,
                fraction: max == 0 ? 0 : (value / max).clamp(0, 1),
                color: tone.color(c),
                ai: tone == MuTone.ai,
              )
            : _SegmentTrack(
                height: _track,
                total: max.round(),
                filled: value.round(),
                pending: pending.round(),
                color: tone.color(c),
              );

    final semantics = indeterminate
        ? (label ?? 'Chargement')
        : unit != null
            ? '${_num(value)} sur ${_num(max)} $unit${pending > 0 ? ', dont ${_num(pending)} en attente' : ''}'
            : _valueText;

    return Semantics(
      label: label,
      value: semantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null || (showValue && !indeterminate)) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (label != null)
                  Expanded(child: Text(label!, style: MuType.label.copyWith(color: c.text)))
                else
                  const Spacer(),
                if (showValue && !indeterminate)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: _valueText, style: MuType.numS.copyWith(color: c.text)),
                        if (unit != null && valueLabel == null)
                          TextSpan(
                            text: ' $unit',
                            style: MuType.body.copyWith(color: c.textSecondary),
                          ),
                      ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
          ],
          ExcludeSemantics(child: track),
          if (hint != null) ...[
            const SizedBox(height: MuSpace.s1),
            Row(
              children: [
                if (error) ...[
                  Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                      size: MuSize.iconXs, color: c.errorText),
                  const SizedBox(width: MuSpace.s1),
                ],
                Expanded(
                  child: Text(
                    hint!,
                    style: MuType.caption.copyWith(color: error ? c.errorText : c.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContinuousTrack extends StatelessWidget {
  const _ContinuousTrack({
    required this.height,
    required this.fraction,
    required this.color,
    required this.ai,
  });

  final double height;
  final double fraction;
  final Color color;
  final bool ai;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return ClipRRect(
      borderRadius: MuRadius.xsAll,
      child: Container(
        height: height,
        color: c.border,
        alignment: AlignmentDirectional.centerStart,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: MuMotion.durationOf(context, MuMotion.slow),
          curve: MuMotion.move,
          builder: (context, f, _) => FractionallySizedBox(
            widthFactor: f,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ai ? null : color,
                gradient: ai ? MuGradients.ai : null,
                borderRadius: MuRadius.xsAll,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentTrack extends StatelessWidget {
  const _SegmentTrack({
    required this.height,
    required this.total,
    required this.filled,
    required this.pending,
    required this.color,
  });

  final double height;
  final int total;
  final int filled;
  final int pending;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: MuProgressBar._segmentGap),
            Expanded(
              child: i < filled
                  ? DecoratedBox(
                      decoration: BoxDecoration(color: color, borderRadius: MuRadius.xsAll),
                    )
                  : i < filled + pending
                      ? CustomPaint(painter: _HatchPainter(color))
                      : DecoratedBox(
                          decoration: BoxDecoration(color: c.border, borderRadius: MuRadius.xsAll),
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pending places: 45° stripes of the fill colour with a 1.5 px inset outline.
class _HatchPainter extends CustomPainter {
  _HatchPainter(this.color);

  final Color color;

  static const double _outline = 1.5;
  static const double _spacing = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(MuRadius.xs));
    canvas.save();
    canvas.clipRRect(rrect);
    final stripe = Paint()
      ..color = color
      ..strokeWidth = _outline;
    for (double x = -size.height; x < size.width + size.height; x += _spacing) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), stripe);
    }
    canvas.restore();
    canvas.drawRRect(
      rrect.deflate(_outline / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outline
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.color != color;
}

class _Indeterminate extends StatefulWidget {
  const _Indeterminate({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  State<_Indeterminate> createState() => _IndeterminateState();
}

class _IndeterminateState extends State<_Indeterminate> with SingleTickerProviderStateMixin {
  // ProgressBar.md: a 36 % segment slides over duration-shimmer; static at 35 % opacity when
  // motion is reduced.
  static const double _segment = 0.36;
  static const double _staticAlpha = 0.35;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: MuMotion.shimmer);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final reduced = MediaQuery.of(context).disableAnimations;
    return ClipRRect(
      borderRadius: MuRadius.xsAll,
      child: Container(
        height: widget.height,
        color: c.border,
        child: reduced
            ? ColoredBox(color: widget.color.withValues(alpha: _staticAlpha))
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // Alignment ±1 puts the segment flush with an edge; go past it to slide in/out.
                  const overshoot = 1 + 2 * _segment / (1 - _segment);
                  final x = -overshoot + 2 * overshoot * _controller.value;
                  return FractionallySizedBox(
                    widthFactor: _segment,
                    alignment: AlignmentDirectional(x, 0),
                    child: ColoredBox(color: widget.color),
                  );
                },
              ),
      ),
    );
  }
}
