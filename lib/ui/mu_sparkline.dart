import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'mu_skeleton.dart';

enum MuSparkTone { muted, accent }

/// Sparkline (components/Sparkline.md): a 12-point trend glyph — a 2 px line ending in a dot, the
/// past de-emphasised and the current segment in the series colour. Pair it with the value it
/// explains; it never carries axes or tooltips.
class MuSparkline extends StatelessWidget {
  const MuSparkline({
    super.key,
    required this.values,
    this.tone = MuSparkTone.muted,
    this.color,
    this.area = false,
    this.size = const Size(96, 32),
    this.min,
    this.max,
    this.semanticLabel,
    this.ring,
  }) : loading = false;

  const MuSparkline.loading({super.key, this.size = const Size(96, 32)})
    : values = const [],
      tone = MuSparkTone.muted,
      color = null,
      area = false,
      min = null,
      max = null,
      semanticLabel = null,
      ring = null,
      loading = true;

  /// Oldest → current; `null` breaks the line.
  final List<double?> values;
  final MuSparkTone tone;

  /// The series colour (`chart1` by default, or a sport colour).
  final Color? color;
  final bool area;
  final Size size;

  /// A fixed scale (levels 1,0–7,0); the data's own range otherwise.
  final double? min;
  final double? max;
  final String? semanticLabel;

  /// The dot's ring colour when the glyph is not on `surface`.
  final Color? ring;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    if (loading) return MuSkeleton(width: size.width, height: size.height);
    final points = values.whereType<double>().toList();
    final label =
        semanticLabel ??
        (points.length < 2
            ? 'Pas encore assez de données pour une tendance'
            : 'Tendance sur ${values.length} points : de ${_fmt(points.first)} à '
                  '${_fmt(points.last)}');
    return Semantics(
      image: true,
      label: label,
      child: SizedBox.fromSize(
        size: size,
        child: CustomPaint(
          painter: _SparkPainter(
            values: values,
            past: tone == MuSparkTone.muted ? c.textSecondary : (color ?? c.chart1),
            accent: color ?? c.chart1,
            wash: area
                ? (tone == MuSparkTone.muted
                      ? c.textSecondary.withValues(alpha: 0.08)
                      : (color ?? c.chart1).withValues(alpha: 0.1))
                : null,
            ring: ring ?? c.surface,
            axis: c.chartAxis,
            min: min,
            max: max,
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({
    required this.values,
    required this.past,
    required this.accent,
    required this.ring,
    required this.axis,
    this.wash,
    this.min,
    this.max,
  });

  final List<double?> values;
  final Color past;
  final Color accent;
  final Color ring;
  final Color axis;
  final Color? wash;
  final double? min;
  final double? max;

  // Sparkline.md: 2 px line, dot r 4 with a 2 px ring, insets 2 start / 6 end, top and bottom.
  static const double _stroke = 2;
  static const double _dot = 4;
  static const double _ringW = 2;
  static const double _insetStart = 2;
  static const double _insetEnd = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final present = values.whereType<double>().toList();
    if (present.length < 2) {
      canvas.drawLine(
        Offset(_insetStart, size.height / 2),
        Offset(size.width - _insetEnd, size.height / 2),
        Paint()
          ..color = axis
          ..strokeWidth = 1,
      );
      return;
    }
    final lo = min ?? present.reduce((a, b) => a < b ? a : b);
    final hi = max ?? present.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo) == 0 ? 1 : hi - lo;
    final w = size.width - _insetStart - _insetEnd;
    final h = size.height - _insetEnd * 2;
    Offset at(int i, double v) => Offset(
      _insetStart + (values.length == 1 ? 0 : i / (values.length - 1)) * w,
      _insetEnd + (1 - (v - lo) / span) * h,
    );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Segments, broken on nulls; the last one in the accent.
    Offset? prev;
    int? prevI;
    Offset? last;
    final lastI = values.lastIndexWhere((v) => v != null);
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) {
        prev = null;
        continue;
      }
      final p = at(i, v);
      if (prev != null) {
        final isLast = i == lastI && prevI == i - 1;
        canvas.drawLine(prev, p, line..color = isLast ? accent : past);
      }
      prev = p;
      prevI = i;
      last = p;
    }
    if (wash != null) {
      final path = Path();
      var open = false;
      for (var i = 0; i < values.length; i++) {
        final v = values[i];
        if (v == null) {
          if (open) {
            path.lineTo(at(i - 1, values[i - 1]!).dx, size.height);
            path.close();
            open = false;
          }
          continue;
        }
        final p = at(i, v);
        if (!open) {
          path.moveTo(p.dx, size.height);
          open = true;
        }
        path.lineTo(p.dx, p.dy);
      }
      if (open) {
        path.lineTo(last!.dx, size.height);
        path.close();
      }
      canvas.drawPath(path, Paint()..color = wash!);
    }
    if (last != null) {
      canvas.drawCircle(last, _dot + _ringW, Paint()..color = ring);
      canvas.drawCircle(last, _dot, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.past != past || old.accent != accent || old.wash != wash;
}
