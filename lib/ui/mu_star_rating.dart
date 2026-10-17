import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'src/interaction.dart';
import '../l10n/l10n.dart';

/// StarRating (components/StarRating.md): five stars with the exact value and the count, or five
/// 44 px stars to give a note with its word.
///
/// Stars are painted: filled in `warning` with a 1 px `warning-text` edge (3:1 on white), empty as a
/// 1,5 px `border-control` outline, the half star clipped on the reading side. Display rounds to the
/// nearest half and prints the value; stars are never the only cue.
class MuStarRating extends StatelessWidget {
  /// « ★★★★½ 4,7 (128 avis) ».
  const MuStarRating.display({
    super.key,
    required this.value,
    this.count,
    this.size = 20,
    this.showValue = true,
  }) : onChanged = null,
       label = null,
       words = null,
       input = false;

  /// Five 44 px targets; the word of the note follows the stars.
  const MuStarRating.input({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.words,
    this.size = 28,
  }) : count = null,
       showValue = false,
       input = true;

  final double value;
  final int? count;
  final double size;
  final bool showValue;
  final ValueChanged<int>? onChanged;

  /// The criterion (« Fair-play »), in a column before the stars.
  final String? label;

  /// The five words, from 1 to 5.
  final List<String>? words;
  final bool input;

  static List<String> get _defaultWords => [l10n.decevant, l10n.moyen, l10n.correct, l10n.bien, l10n.excellent];

  // StarRating.md: gaps 1 (16), 2 (20); input targets 44; label column 88.
  static const double _labelColumn = 88;

  double get _gap => size <= 16 ? 1 : 2;

  @override
  Widget build(BuildContext context) => input ? _input(context) : _display(context);

  Widget _display(BuildContext context) {
    final c = context.mu;
    final rounded = (value * 2).round() / 2;
    final small = size <= 20;
    return Semantics(
      image: true,
      label: l10n.noteSur(formatLevel(value), count == null ? '' : l10n.avis5('$count')),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) SizedBox(width: _gap),
            _Star(size: size, fill: (rounded - i).clamp(0.0, 1.0)),
          ],
          if (showValue) ...[
            const SizedBox(width: MuSpace.s2),
            Text(
              formatLevel(value),
              style: (small ? MuType.numS : MuType.numM).copyWith(color: c.text),
            ),
          ],
          if (count != null) ...[
            const SizedBox(width: MuSpace.s1),
            Text(
              l10n.avis3(formatInt(count!)),
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _input(BuildContext context) {
    final c = context.mu;
    final note = value.round();
    final words = this.words ?? _defaultWords;
    final word = note == 0 ? null : words[note - 1];
    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            inMutuallyExclusiveGroup: true,
            selected: note == i,
            button: true,
            label: l10n.sur4(i, (this.words ?? _defaultWords)[i - 1]),
            excludeSemantics: true,
            child: MuFocusRing(
              borderRadius: MuRadius.smAll,
              child: InkResponse(
                onTap: onChanged == null ? null : () => onChanged!(i),
                radius: MuSize.touchTarget / 2,
                child: SizedBox.square(
                  dimension: MuSize.touchTarget,
                  child: Center(
                    child: _Star(size: size, fill: i <= note ? 1 : 0),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          SizedBox(
            width: _labelColumn,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label!, style: MuType.label.copyWith(color: c.text)),
                Text(
                  word ?? l10n.aNoter,
                  style: word == null
                      ? MuType.caption.copyWith(color: c.textSecondary)
                      : MuType.labelS.copyWith(color: c.text),
                ),
              ],
            ),
          ),
        Semantics(container: true, label: label ?? l10n.note, child: stars),
        if (label == null) ...[
          const SizedBox(width: MuSpace.s2),
          Text(
            word ?? l10n.touchePourNoter,
            style: word == null
                ? MuType.body.copyWith(color: c.textSecondary)
                : MuType.label.copyWith(color: c.text),
          ),
        ],
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.size, required this.fill});

  final double size;

  /// 0, 0,5 or 1.
  final double fill;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(
        fill: fill,
        fillColor: c.warning,
        edge: c.warningText,
        empty: c.borderControl,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({
    required this.fill,
    required this.fillColor,
    required this.edge,
    required this.empty,
    required this.rtl,
  });

  final double fill;
  final Color fillColor;
  final Color edge;
  final Color empty;
  final bool rtl;

  static const double _emptyStroke = 1.5;
  static const double _edgeStroke = 1;
  static const double _inner = 0.42;

  Path _path(Size s) {
    final r = s.width / 2;
    final centre = Offset(r, r * 1.06);
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final angle = -math.pi / 2 + k * math.pi / 5;
      final radius = k.isEven ? r * 0.98 : r * _inner;
      final p = centre + Offset(radius * math.cos(angle), radius * math.sin(angle));
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final star = _path(size);
    canvas.drawPath(
      star,
      Paint()
        ..color = empty
        ..style = PaintingStyle.stroke
        ..strokeWidth = _emptyStroke
        ..strokeJoin = StrokeJoin.round,
    );
    if (fill <= 0) return;
    canvas.save();
    final w = size.width * fill;
    canvas.clipRect(
      rtl ? Rect.fromLTWH(size.width - w, 0, w, size.height) : Rect.fromLTWH(0, 0, w, size.height),
    );
    canvas.drawPath(star, Paint()..color = fillColor);
    canvas.drawPath(
      star,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = _edgeStroke
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.fill != fill || old.fillColor != fillColor || old.rtl != rtl || old.empty != empty;
}
