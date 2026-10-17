import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';
import '../l10n/l10n.dart';

/// A named stretch of a [MuRangeSlider] track (« Débutant » 1,0–2,5).
@immutable
class MuRangeBand {
  const MuRangeBand(this.from, this.to, this.label);

  final double from;
  final double to;
  final String label;
}

/// RangeSlider (components/RangeSlider.md): a two-thumb slider for a min–max filter — price per
/// person, distance, level range — with the range in the header and a value bubble while dragging.
///
/// Thumbs never cross (the smallest gap is one [step]); [onChangeEnd] fires when a drag or key
/// press ends, to refresh results once. With [bands] the track splits at their edges and names
/// them underneath (bands inside the range in `label-s`).
class MuRangeSlider extends StatefulWidget {
  MuRangeSlider({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    this.onChangeEnd,
    this.step = 1,
    this.format,
    this.formatRange,
    String? minLabel,
    String? maxLabel,
    this.bands = const [],
    this.showLimits = true,
  }) : maxLabel = maxLabel ?? l10n.maximum, minLabel = minLabel ?? l10n.minimum;

  final RangeValues values;
  final double min;
  final double max;
  final double step;

  /// The header label (« Prix par personne »), also the group's accessible name.
  final String label;
  final ValueChanged<RangeValues>? onChanged;
  final ValueChanged<RangeValues>? onChangeEnd;

  /// One value: « 10 DT », « 3,0 », « 8 km ».
  final String Function(double value)? format;

  /// The header range: defaults to « 10 DT - 25 DT » from [format]; « Jusqu’à 10 km » for open ends.
  final String Function(double low, double high)? formatRange;

  /// Thumb names: « Prix minimum », « Prix maximum ».
  final String minLabel;
  final String maxLabel;
  final List<MuRangeBand> bands;

  /// « 0 DT » and « 50 DT » under the track ends (not with bands).
  final bool showLimits;

  @override
  State<MuRangeSlider> createState() => _MuRangeSliderState();
}

class _MuRangeSliderState extends State<MuRangeSlider> {
  /// The thumb being dragged (0 low, 1 high), or null.
  int? _active;
  late final _focus = [FocusNode(), FocusNode()];

  // RangeSlider.md: track 4, thumb 24 with a 1,5 px edge, hit area 44 inset 12 each side, bubble
  // 10 above the thumb with an 8 px caret, bands 3 px apart.
  static const double _track = 4;
  static const double _thumb = 24;
  static const double _thumbEdge = 1.5;
  static const double _dragRing = 2;
  static const double _inset = 12;
  static const double _bubbleGap = 10;
  static const double _caret = 8;
  static const double _bandGap = 3;

  bool get _enabled => widget.onChanged != null;

  @override
  void dispose() {
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  String _fmt(double v) => widget.format?.call(v) ?? v.toStringAsFixed(0);

  String _range(RangeValues r) =>
      widget.formatRange?.call(r.start, r.end) ?? '${_fmt(r.start)} - ${_fmt(r.end)}';

  double _snap(double v) {
    final s = widget.step;
    return (widget.min + ((v - widget.min) / s).round() * s).clamp(widget.min, widget.max);
  }

  /// Moves [thumb] to [v], kept one step away from the other thumb.
  void _move(int thumb, double v) {
    final r = widget.values;
    final s = widget.step;
    final next = thumb == 0
        ? RangeValues(_snap(v).clamp(widget.min, r.end - s), r.end)
        : RangeValues(r.start, _snap(v).clamp(r.start + s, widget.max));
    if (next != r) widget.onChanged?.call(next);
  }

  void _end() {
    setState(() => _active = null);
    widget.onChangeEnd?.call(widget.values);
  }

  double _frac(double v) => ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double _valueAt(double dx, double width) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final f = ((dx - _inset) / (width - 2 * _inset)).clamp(0.0, 1.0);
    return widget.min + (ltr ? f : 1 - f) * (widget.max - widget.min);
  }

  int _nearest(double v) {
    final r = widget.values;
    if (r.start == r.end) return v < r.start ? 0 : 1;
    return (v - r.start).abs() <= (v - r.end).abs() ? 0 : 1;
  }

  KeyEventResult _onKey(int thumb, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final v = thumb == 0 ? widget.values.start : widget.values.end;
    final s = widget.step;
    final page = widget.bands.isNotEmpty
        ? widget.bands.first.to - widget.bands.first.from
        : (widget.max - widget.min) / 10;
    final k = e.logicalKey;
    double? next;
    if (k == LogicalKeyboardKey.arrowRight) next = v + (rtl ? -s : s);
    if (k == LogicalKeyboardKey.arrowLeft) next = v + (rtl ? s : -s);
    if (k == LogicalKeyboardKey.arrowUp) next = v + s;
    if (k == LogicalKeyboardKey.arrowDown) next = v - s;
    if (k == LogicalKeyboardKey.pageUp) next = v + page;
    if (k == LogicalKeyboardKey.pageDown) next = v - page;
    if (k == LogicalKeyboardKey.home) next = widget.min;
    if (k == LogicalKeyboardKey.end) next = widget.max;
    if (next == null) return KeyEventResult.ignored;
    _move(thumb, next);
    widget.onChangeEnd?.call(widget.values);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = widget.values;
    final ink = _enabled ? c.text : c.textDisabled;
    final fill = _enabled ? c.primary : c.textDisabled;
    final duration = MuMotion.durationOf(context, MuMotion.fast);
    final ltr = Directionality.of(context) == TextDirection.ltr;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(widget.label, style: MuType.label.copyWith(color: ink)),
        ),
        const SizedBox(width: MuSpace.s3),
        AnimatedOpacity(
          opacity: _active == null ? 1 : 0,
          duration: duration,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(_range(r), style: MuType.numM.copyWith(color: ink)),
          ),
        ),
      ],
    );

    final track = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final usable = width - 2 * _inset;
        double x(double v) => _inset + (ltr ? _frac(v) : 1 - _frac(v)) * usable;
        final lo = x(r.start);
        final hi = x(r.end);
        final left = lo < hi ? lo : hi;
        final right = lo < hi ? hi : lo;

        // Track segments: one per band (3 px apart), or the whole track.
        final segments = <(double, double)>[
          if (widget.bands.isEmpty)
            (_inset, width - _inset)
          else
            for (final (i, b) in widget.bands.indexed)
              () {
                final a = x(b.from);
                final z = x(b.to);
                final s = (a < z ? a : z) + (i == 0 ? 0 : _bandGap / 2);
                final e = (a < z ? z : a) - (i == widget.bands.length - 1 ? 0 : _bandGap / 2);
                return (s, e);
              }(),
        ];

        Widget thumb(int i) {
          final v = i == 0 ? r.start : r.end;
          final cx = x(v);
          final dragging = _active == i;
          return Positioned(
            left: cx - MuSize.touchTarget / 2,
            top: 0,
            width: MuSize.touchTarget,
            height: MuSize.touchTarget,
            child: Semantics(
              slider: true,
              label: i == 0 ? widget.minLabel : widget.maxLabel,
              value: l10n.rangeTo(_fmt(r.start), _fmt(r.end)),
              increasedValue: _fmt(_snap(v + widget.step)),
              decreasedValue: _fmt(_snap(v - widget.step)),
              onIncrease: _enabled ? () => _move(i, v + widget.step) : null,
              onDecrease: _enabled ? () => _move(i, v - widget.step) : null,
              child: Focus(
                focusNode: _focus[i],
                canRequestFocus: _enabled,
                onKeyEvent: (_, e) => _onKey(i, e),
                child: Builder(
                  builder: (context) {
                    final focused = Focus.of(context).hasFocus;
                    return Center(
                      child: MuFocusRing(
                        borderRadius: MuRadius.fullAll,
                        forceVisible: focused,
                        child: AnimatedContainer(
                          duration: duration,
                          width: _thumb,
                          height: _thumb,
                          decoration: BoxDecoration(
                            color: c.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: dragging
                                  ? c.primary
                                  : (_enabled ? c.borderControl : c.borderStrong),
                              width: dragging ? _dragRing : _thumbEdge,
                            ),
                            boxShadow: !_enabled
                                ? null
                                : dragging
                                ? MuElevation.of(context).level2
                                : MuElevation.of(context).level1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }

        Widget? bubble() {
          final i = _active;
          if (i == null) return null;
          final v = i == 0 ? r.start : r.end;
          return Positioned(
            left: x(v),
            bottom: MuSize.touchTarget / 2 + _thumb / 2 + _bubbleGap,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MuSpace.s2,
                        vertical: MuSpace.s1,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceInverse,
                        borderRadius: MuRadius.smAll,
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(_fmt(v), style: MuType.numS.copyWith(color: c.textInverse)),
                      ),
                    ),
                    CustomPaint(
                      size: const Size(_caret * 2, _caret),
                      painter: _CaretPainter(c.surfaceInverse),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final b = bubble();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled
              ? (d) {
                  final v = _valueAt(d.localPosition.dx, width);
                  _move(_nearest(v), v);
                }
              : null,
          onTapUp: _enabled ? (_) => widget.onChangeEnd?.call(widget.values) : null,
          onHorizontalDragStart: _enabled
              ? (d) {
                  final v = _valueAt(d.localPosition.dx, width);
                  final i = _nearest(v);
                  _focus[i].requestFocus();
                  setState(() => _active = i);
                }
              : null,
          onHorizontalDragUpdate: _enabled && _active != null
              ? (d) => _move(_active!, _valueAt(d.localPosition.dx, width))
              : null,
          onHorizontalDragEnd: _enabled ? (_) => _end() : null,
          onHorizontalDragCancel: _enabled ? () => setState(() => _active = null) : null,
          child: SizedBox(
            height: MuSize.touchTarget,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final (s, e) in segments) ...[
                  Positioned(
                    left: s,
                    width: (e - s).clamp(0.0, width),
                    top: (MuSize.touchTarget - _track) / 2,
                    height: _track,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: c.border, borderRadius: MuRadius.fullAll),
                    ),
                  ),
                  if (right > s && left < e)
                    Positioned(
                      left: left < s ? s : left,
                      width: ((right > e ? e : right) - (left < s ? s : left)).clamp(0.0, width),
                      top: (MuSize.touchTarget - _track) / 2,
                      height: _track,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: fill, borderRadius: MuRadius.fullAll),
                      ),
                    ),
                ],
                thumb(0),
                thumb(1),
                ?b,
              ],
            ),
          ),
        );
      },
    );

    Widget? under;
    if (widget.bands.isNotEmpty) {
      under = Padding(
        padding: const EdgeInsets.symmetric(horizontal: _inset),
        child: Row(
          children: [
            for (final band in widget.bands)
              Expanded(
                flex: ((band.to - band.from) * 100).round(),
                child: Text(
                  band.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: band.from < r.end && band.to > r.start
                      ? MuType.labelS.copyWith(color: ink)
                      : MuType.caption.copyWith(color: c.textSecondary),
                ),
              ),
          ],
        ),
      );
    } else if (widget.showLimits) {
      final style = MuType.caption.copyWith(color: c.textSecondary);
      under = Row(
        children: [
          Text(_fmt(widget.min), style: style),
          const Spacer(),
          Text(_fmt(widget.max), style: style),
        ],
      );
    }

    return Semantics(
      container: true,
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          const SizedBox(height: MuSpace.s1),
          track,
          if (under != null) ExcludeSemantics(child: under),
        ],
      ),
    );
  }
}

/// The bubble's caret, pointing down at the thumb.
class _CaretPainter extends CustomPainter {
  const _CaretPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) => oldDelegate.color != color;
}
