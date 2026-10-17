import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_icon_button.dart';
import 'src/card_surface.dart';
import '../l10n/l10n.dart';

enum MuSeriesStyle { solid, previous }

/// One line of a [MuLineChart]. A missing value is null and prints « — ».
@immutable
class MuSeries {
  const MuSeries({
    required this.label,
    required this.data,
    this.style = MuSeriesStyle.solid,
    this.color,
  });

  final String label;
  final List<double?> data;
  final MuSeriesStyle style;

  /// Defaults to `chart-1…8` in order; `previous` is always `chart-axis`.
  final Color? color;
}

/// LineChart (components/LineChart.md): a `mu-card` with title and subtitle, a 0-based plot with
/// clean y steps and compact tick labels, 2 px lines (area wash on a single series, dashed for
/// the previous period), the end dot and label, a crosshair with its tooltip on touch / keyboard
/// (← → Home End Esc) and « Voir le tableau » for the table twin. The plot never mirrors in RTL.
class MuLineChart extends StatefulWidget {
  MuLineChart({
    super.key,
    required this.title,
    this.subtitle,
    required this.x,
    this.tooltipX,
    required this.series,
    required this.format,
    this.compact,
    this.height = 280,
    this.xTicks,
    String? showTableLabel,
    String? showChartLabel,
    this.chartLabel,
    String? dateHeader,
  }) : dateHeader = dateHeader ?? l10n.date, showChartLabel = showChartLabel ?? l10n.voirLeGraphique, showTableLabel = showTableLabel ?? l10n.voirLeTableau;

  final String title;
  final String? subtitle;

  /// Axis labels (« 13 oct. »), one per point.
  final List<String> x;

  /// Tooltip and table labels (« mar. 13 oct. »); defaults to [x].
  final List<String>? tooltipX;
  final List<MuSeries> series;

  /// Full value (« 5 130 DT »).
  final String Function(double value) format;

  /// Tick value (« 2,5 k DT »); defaults to [format].
  final String Function(double value)? compact;

  /// Includes the x band.
  final double height;

  /// Indexes of the x labels to print; defaults to every 7th from the latest.
  final List<int>? xTicks;

  /// The toggle's name, both ways.
  final String showTableLabel;
  final String showChartLabel;

  /// The plot's accessible name; defaults to [title].
  final String? chartLabel;

  /// The first column of the table (« Jour »).
  final String dateHeader;

  @override
  State<MuLineChart> createState() => _MuLineChartState();
}

class _MuLineChartState extends State<MuLineChart> {
  int? _active;
  bool _table = false;
  final _focus = FocusNode();

  // LineChart.md: x band, end-label room, tooltip key 12 × 3, end dot r 4 + 2 px ring.
  static const double _xBand = 28;
  static const double _yLabelW = 44;
  static const double _endRoom = 64;

  int get _n => widget.x.length;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<Color> _colors(MuColors c) {
    final palette = [
      c.chart1,
      c.chart2,
      c.chart3,
      c.chart4,
      c.chart5,
      c.chart6,
      c.chart7,
      c.chart8,
    ];
    var i = 0;
    return [
      for (final s in widget.series)
        s.style == MuSeriesStyle.previous
            ? c.chartAxis
            : (s.color ?? palette[i++ % palette.length]),
    ];
  }

  void _pick(Offset local, double plotLeft, double plotWidth) {
    if (_n < 2) return;
    final t = ((local.dx - plotLeft) / plotWidth).clamp(0.0, 1.0);
    setState(() => _active = (t * (_n - 1)).round());
  }

  KeyEventResult _onKey(KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    int? next;
    if (k == LogicalKeyboardKey.arrowRight) next = math.min((_active ?? -1) + 1, _n - 1);
    if (k == LogicalKeyboardKey.arrowLeft) next = math.max((_active ?? _n) - 1, 0);
    if (k == LogicalKeyboardKey.home) next = 0;
    if (k == LogicalKeyboardKey.end) next = _n - 1;
    if (k == LogicalKeyboardKey.escape) {
      setState(() => _active = null);
      return KeyEventResult.handled;
    }
    if (next == null) return KeyEventResult.ignored;
    setState(() => _active = next);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final colors = _colors(c);
    return MuCardSurface(
      padding: const EdgeInsets.all(MuSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(widget.title, style: MuType.h3.copyWith(color: c.text)),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                  ],
                ),
              ),
              MuIconButton(
                icon: _table ? PhosphorIcons.chartLine() : PhosphorIcons.table(),
                label: _table ? widget.showChartLabel : widget.showTableLabel,
                size: MuIconButtonSize.s,
                variant: MuIconButtonVariant.ghost,
                onPressed: () => setState(() => _table = !_table),
              ),
            ],
          ),
          if (widget.series.length > 1) ...[
            const SizedBox(height: MuSpace.s3),
            Wrap(
              spacing: MuSpace.s5,
              runSpacing: MuSpace.s1,
              children: [
                for (var i = 0; i < widget.series.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: const Size(18, 2),
                        painter: _KeyPainter(
                          colors[i],
                          dashed: widget.series[i].style == MuSeriesStyle.previous,
                        ),
                      ),
                      const SizedBox(width: MuSpace.s2),
                      Text(widget.series[i].label, style: MuType.labelS.copyWith(color: c.text)),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: MuSpace.s4),
          if (_table) _tableView(c) else _plot(c, colors),
        ],
      ),
    );
  }

  Widget _tableView(MuColors c) {
    final tx = widget.tooltipX ?? widget.x;
    final head = MuType.labelS.copyWith(color: c.textSecondary);
    final cell = MuType.numS.copyWith(color: c.text);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.height),
      child: SingleChildScrollView(
        child: Table(
          columnWidths: const {0: FlexColumnWidth(1.4)},
          border: TableBorder(horizontalInside: BorderSide(color: c.border)),
          children: [
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
                  child: Text(widget.dateHeader, style: head),
                ),
                for (final s in widget.series)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
                    child: Text(s.label, style: head, textAlign: TextAlign.end),
                  ),
              ],
            ),
            for (var i = _n - 1; i >= 0; i--)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
                    child: Text(tx[i], style: MuType.caption.copyWith(color: c.text)),
                  ),
                  for (final s in widget.series)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
                      child: Text(
                        ltr(
                          i < s.data.length && s.data[i] != null ? widget.format(s.data[i]!) : '—',
                        ),
                        style: cell,
                        textAlign: TextAlign.end,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _plot(MuColors c, List<Color> colors) {
    final tx = widget.tooltipX ?? widget.x;
    final values = [for (final s in widget.series) ...s.data.whereType<double>()];
    final yMax = _niceMax(values.isEmpty ? 1 : values.reduce(math.max));
    final ticks = _ticks(yMax);
    final xTicks = widget.xTicks ?? [for (var i = _n - 1; i >= 0; i -= 7) i].reversed.toList();
    final compact = widget.compact ?? widget.format;
    final summary = [
      for (final s in widget.series)
        if (s.data.isNotEmpty && s.data.last != null) '${s.label} : ${widget.format(s.data.last!)}',
    ].join(', ');
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, box) {
            const left = _yLabelW;
            final plotW = box.maxWidth - left - _endRoom;
            final plotH = widget.height - _xBand;
            return Focus(
              focusNode: _focus,
              onKeyEvent: (_, e) => _onKey(e),
              child: Semantics(
                container: true,
                label: widget.chartLabel ?? widget.title,
                value: _active == null
                    ? summary
                    : '${tx[_active!]} : ${[for (final s in widget.series)
                        if (_active! < s.data.length) s.data[_active!] == null ? '—' : widget.format(s.data[_active!]!)].join(', ')}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _pick(d.localPosition, left, plotW),
                  onHorizontalDragStart: (d) => _pick(d.localPosition, left, plotW),
                  onHorizontalDragUpdate: (d) => _pick(d.localPosition, left, plotW),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: Size(box.maxWidth, widget.height),
                        painter: _LinePainter(
                          series: widget.series,
                          colors: colors,
                          yMax: yMax,
                          ticks: ticks,
                          left: left,
                          plotW: plotW,
                          plotH: plotH,
                          grid: c.chartGrid,
                          axis: c.chartAxis,
                          ring: c.surface,
                          active: _active,
                          area: widget.series.length == 1,
                        ),
                      ),
                      // Y tick labels.
                      for (final t in ticks)
                        Positioned(
                          left: 0,
                          width: left - MuSpace.s2,
                          top: plotH - plotH * t / yMax - 8,
                          child: Text(
                            compact(t),
                            textAlign: TextAlign.end,
                            style: MuType.numXs.copyWith(color: c.textSecondary),
                          ),
                        ),
                      // X labels.
                      for (final i in xTicks)
                        if (i >= 0 && i < _n)
                          Positioned(
                            left: left + (_n < 2 ? 0 : plotW * i / (_n - 1)) - 40,
                            width: 80,
                            top: plotH + MuSpace.s2,
                            child: Text(
                              widget.x[i],
                              textAlign: TextAlign.center,
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ),
                      // End labels (dropped when they would collide).
                      ..._endLabels(c, colors, yMax, left, plotW, plotH),
                      if (_active != null) _tooltip(c, colors, tx, yMax, left, plotW, plotH),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _endLabels(
    MuColors c,
    List<Color> colors,
    double yMax,
    double left,
    double plotW,
    double plotH,
  ) {
    final taken = <double>[];
    final out = <Widget>[];
    for (var i = 0; i < widget.series.length; i++) {
      final s = widget.series[i];
      if (s.data.isEmpty || s.data.last == null) continue;
      final y = plotH - plotH * s.data.last! / yMax;
      if (taken.any((t) => (t - y).abs() < 16)) continue;
      taken.add(y);
      out.add(
        Positioned(
          left: left + plotW + MuSpace.s3,
          top: y - 9,
          child: Text(widget.format(s.data.last!), style: MuType.numXs.copyWith(color: c.text)),
        ),
      );
    }
    return out;
  }

  Widget _tooltip(
    MuColors c,
    List<Color> colors,
    List<String> tx,
    double yMax,
    double left,
    double plotW,
    double plotH,
  ) {
    final i = _active!;
    final x = left + (_n < 2 ? 0 : plotW * i / (_n - 1));
    final first = widget.series.first.data;
    final v = i < first.length ? first[i] : null;
    final y = v == null ? plotH / 2 : plotH - plotH * v / yMax;
    final below = y < plotH / 2;
    const w = 150.0;
    final dx = (x - w / 2).clamp(0.0, left + plotW + _endRoom - w);
    return Positioned(
      left: dx,
      top: below ? y + MuSpace.s3 : null,
      bottom: below ? null : widget.height - y + MuSpace.s3,
      width: w,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
          decoration: BoxDecoration(
            color: c.surfaceElevated,
            borderRadius: MuRadius.smAll,
            boxShadow: MuElevation.of(context).level2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tx[i], style: MuType.labelS.copyWith(color: c.textSecondary)),
              for (var k = 0; k < widget.series.length; k++)
                Row(
                  children: [
                    Container(width: 12, height: 3, color: colors[k]),
                    const SizedBox(width: MuSpace.s2),
                    Text(
                      i < widget.series[k].data.length && widget.series[k].data[i] != null
                          ? widget.format(widget.series[k].data[i]!)
                          : '—',
                      style: MuType.numS.copyWith(color: c.text),
                    ),
                    if (widget.series.length > 1) ...[
                      const SizedBox(width: MuSpace.s1),
                      Flexible(
                        child: Text(
                          widget.series[k].label,
                          overflow: TextOverflow.ellipsis,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Clean steps 1 / 2 / 2,5 / 4 / 5 × 10ⁿ, about four of them, from 0.
  static double _step(double max) {
    final raw = max / 4;
    final p = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in [1.0, 2.0, 2.5, 4.0, 5.0, 10.0]) {
      if (m * p >= raw) return m * p;
    }
    return 10 * p;
  }

  static double _niceMax(double max) {
    if (max <= 0) return 1;
    final s = _step(max);
    return (max / s).ceil() * s;
  }

  static List<double> _ticks(double yMax) {
    final s = _step(yMax);
    return [for (var t = 0.0; t <= yMax + s / 100; t += s) t];
  }
}

class _KeyPainter extends CustomPainter {
  const _KeyPainter(this.color, {required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      return;
    }
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 6, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(_KeyPainter old) => old.color != color || old.dashed != dashed;
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.series,
    required this.colors,
    required this.yMax,
    required this.ticks,
    required this.left,
    required this.plotW,
    required this.plotH,
    required this.grid,
    required this.axis,
    required this.ring,
    required this.active,
    required this.area,
  });

  final List<MuSeries> series;
  final List<Color> colors;
  final double yMax;
  final List<double> ticks;
  final double left;
  final double plotW;
  final double plotH;
  final Color grid;
  final Color axis;
  final Color ring;
  final int? active;
  final bool area;

  // LineChart.md: 2 px lines, 10 % area wash, dashes 6/4, dots r 4 with a 2 px ring.
  static const double _line = 2;
  static const double _wash = 0.10;
  static const double _dot = 4;
  static const double _ring = 2;

  int get _n => series.isEmpty ? 0 : series.map((s) => s.data.length).reduce(math.max);

  Offset _at(int i, double v) =>
      Offset(left + (_n < 2 ? 0 : plotW * i / (_n - 1)), plotH - plotH * v / yMax);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final t in ticks.skip(1)) {
      final y = plotH - plotH * t / yMax;
      canvas.drawLine(Offset(left, y), Offset(left + plotW, y), gridPaint);
    }
    canvas.drawLine(
      Offset(left, plotH),
      Offset(left + plotW, plotH),
      Paint()
        ..color = axis
        ..strokeWidth = 1,
    );
    for (var k = 0; k < series.length; k++) {
      final s = series[k];
      final color = colors[k];
      final path = Path();
      var open = false;
      Offset? first;
      Offset? last;
      for (var i = 0; i < s.data.length; i++) {
        final v = s.data[i];
        if (v == null) {
          open = false;
          continue;
        }
        final p = _at(i, v);
        open ? path.lineTo(p.dx, p.dy) : path.moveTo(p.dx, p.dy);
        open = true;
        first ??= p;
        last = p;
      }
      if (first == null || last == null) continue;
      final dashed = s.style == MuSeriesStyle.previous;
      if (area && !dashed) {
        final fill = Path.from(path)
          ..lineTo(last.dx, plotH)
          ..lineTo(first.dx, plotH)
          ..close();
        canvas.drawPath(fill, Paint()..color = color.withValues(alpha: _wash));
      }
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _line
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (dashed) {
        for (final metric in path.computeMetrics()) {
          for (var d = 0.0; d < metric.length; d += 10) {
            canvas.drawPath(metric.extractPath(d, math.min(d + 6, metric.length)), stroke);
          }
        }
      } else {
        canvas.drawPath(path, stroke);
      }
      if (!dashed) _drawDot(canvas, last, color);
    }
    if (active != null) {
      final x = left + (_n < 2 ? 0 : plotW * active! / (_n - 1));
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, plotH),
        Paint()
          ..color = axis
          ..strokeWidth = 1,
      );
      for (var k = 0; k < series.length; k++) {
        final d = series[k].data;
        if (active! < d.length && d[active!] != null) {
          _drawDot(canvas, _at(active!, d[active!]!), colors[k]);
        }
      }
    }
  }

  void _drawDot(Canvas canvas, Offset p, Color color) {
    canvas.drawCircle(p, _dot + _ring, Paint()..color = ring);
    canvas.drawCircle(p, _dot, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}
