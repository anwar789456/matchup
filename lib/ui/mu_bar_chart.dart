import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_icon_button.dart';
import 'mu_sport_icon.dart';
import 'src/card_surface.dart';
import '../l10n/l10n.dart';

enum MuBarMode { grouped, stacked }

/// One series of a [MuBarChart]. Sport series take the sport colour and carry the sport icon.
@immutable
class MuBarSeries {
  const MuBarSeries({required this.label, required this.data, this.color, this.sport});

  /// A sport series (football → padel → basketball, in that order everywhere).
  MuBarSeries.sport(MuSport this.sport, {required this.data, String? label})
    : label = label ?? sport.label,
      color = null;

  final String label;
  final List<double> data;

  /// Defaults to the sport colour, else `chart-1…8` in order.
  final Color? color;
  final MuSport? sport;
}

/// BarChart (components/BarChart.md): a `mu-card` with title, subtitle, the table toggle and a
/// legend (10 × 10 keys + sport icons); columns ≤ 24 px (62 % of the band) with a 4 px rounded
/// data end and 2 px `surface` gaps between stacked segments, gridlines on clean steps, totals
/// on the peak and the latest stack, series names beside the last stack, and a per-category
/// tooltip on touch or keyboard (← → Home End Esc). Horizontal bars: 44 px rows, 22 px bars, the
/// value at the tip. The plot never mirrors in RTL.
class MuBarChart extends StatefulWidget {
  MuBarChart({
    super.key,
    required this.title,
    this.subtitle,
    required this.categories,
    this.tooltipCategories,
    required this.series,
    required this.format,
    this.compact,
    this.orientation = Axis.vertical,
    this.mode = MuBarMode.stacked,
    this.height = 260,
    this.valueLabels = true,
    this.directLabels = true,
    this.xTicks,
    String? totalLabel,
    String? totalHeader,
    String? categoryLabel,
    String? showTableLabel,
    String? showChartLabel,
    this.chartLabel,
  }) : showChartLabel = showChartLabel ?? l10n.voirLeGraphique, showTableLabel = showTableLabel ?? l10n.voirLeTableau, categoryLabel = categoryLabel ?? l10n.jour, totalHeader = totalHeader ?? l10n.total, totalLabel = totalLabel ?? l10n.auTotal;

  final String title;
  final String? subtitle;

  /// Axis labels (« 13 oct. »), one per category.
  final List<String> categories;

  /// Tooltip and table labels (« mar. 13 oct. »); defaults to [categories].
  final List<String>? tooltipCategories;
  final List<MuBarSeries> series;

  /// Full value (« 340 », « 5 130 DT »).
  final String Function(double value) format;

  /// Tick value; defaults to [format].
  final String Function(double value)? compact;
  final Axis orientation;
  final MuBarMode mode;

  /// Vertical: includes the x band. Horizontal: grows with the rows.
  final double height;

  /// Peak + latest (columns), totals (stacked), every bar (horizontal), none (grouped).
  final bool valueLabels;

  /// Series names beside the last stack when its segment is ≥ 16 px tall.
  final bool directLabels;

  /// Indexes of the x labels to print; defaults to every other one from the latest.
  final List<int>? xTicks;

  /// « au total » after the stack's sum in the tooltip.
  final String totalLabel;

  /// The table's last column when there are several series.
  final String totalHeader;

  /// The table's first column.
  final String categoryLabel;
  final String showTableLabel;
  final String showChartLabel;

  /// The plot's accessible name; defaults to [title].
  final String? chartLabel;

  @override
  State<MuBarChart> createState() => _MuBarChartState();
}

class _MuBarChartState extends State<MuBarChart> {
  int? _active;
  bool _table = false;
  final _focus = FocusNode();

  // BarChart.md: x band, y labels, direct-label room, bars ≤ 24 px at 62 % of the band.
  static const double _xBand = 28;
  static const double _yLabelW = 36;
  static const double _directRoom = 76;
  static const double _maxBar = 24;
  static const double _bandShare = 0.62;
  static const double _gap = 2;
  static const double _end = 4;
  static const double _minDirect = 16;
  static const double _row = 44;
  static const double _hBar = 22;

  int get _n => widget.categories.length;
  bool get _stacked => widget.mode == MuBarMode.stacked && widget.series.length > 1;

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
      for (final s in widget.series) s.color ?? s.sport?.color(c) ?? palette[i++ % palette.length],
    ];
  }

  double _value(MuBarSeries s, int i) => i < s.data.length ? s.data[i] : 0;

  double _total(int i) => widget.series.fold(0.0, (sum, s) => sum + _value(s, i));

  double _top(int i) =>
      _stacked ? _total(i) : widget.series.map((s) => _value(s, i)).fold(0.0, math.max);

  KeyEventResult _onKey(KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    int? next;
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowDown) {
      next = math.min((_active ?? -1) + 1, _n - 1);
    }
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowUp) {
      next = math.max((_active ?? _n) - 1, 0);
    }
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

  String _describe(int i) {
    final tx = widget.tooltipCategories ?? widget.categories;
    final parts = [
      for (final s in widget.series) '${s.label} ${widget.format(_value(s, i))}',
      if (widget.series.length > 1) '${widget.format(_total(i))} ${widget.totalLabel}',
    ];
    return '${tx[i]} : ${parts.join(', ')}';
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
                icon: _table ? PhosphorIcons.chartBar() : PhosphorIcons.table(),
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
                      Container(width: 10, height: 10, color: colors[i]),
                      const SizedBox(width: MuSpace.s2),
                      if (widget.series[i].sport != null) ...[
                        MuSportIcon(widget.series[i].sport!, size: MuSize.iconXs),
                        const SizedBox(width: MuSpace.s1),
                      ],
                      Text(widget.series[i].label, style: MuType.labelS.copyWith(color: c.text)),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: MuSpace.s4),
          if (_table)
            _tableView(c)
          else if (widget.orientation == Axis.horizontal)
            _horizontal(c, colors)
          else
            _vertical(c, colors),
        ],
      ),
    );
  }

  Widget _tableView(MuColors c) {
    final tx = widget.tooltipCategories ?? widget.categories;
    final head = MuType.labelS.copyWith(color: c.textSecondary);
    final cell = MuType.numS.copyWith(color: c.text);
    final multi = widget.series.length > 1;
    Widget pad(Widget w) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: w,
    );
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.4)},
      border: TableBorder(horizontalInside: BorderSide(color: c.border)),
      children: [
        TableRow(
          children: [
            pad(Text(widget.categoryLabel, style: head)),
            for (final s in widget.series)
              pad(Text(s.label, style: head, textAlign: TextAlign.end)),
            if (multi) pad(Text(widget.totalHeader, style: head, textAlign: TextAlign.end)),
          ],
        ),
        for (var i = _n - 1; i >= 0; i--)
          TableRow(
            children: [
              pad(Text(tx[i], style: MuType.caption.copyWith(color: c.text))),
              for (final s in widget.series)
                pad(Text(ltr(widget.format(_value(s, i))), style: cell, textAlign: TextAlign.end)),
              if (multi)
                pad(Text(ltr(widget.format(_total(i))), style: cell, textAlign: TextAlign.end)),
            ],
          ),
      ],
    );
  }

  Widget _vertical(MuColors c, List<Color> colors) {
    final tops = [for (var i = 0; i < _n; i++) _top(i)];
    final yMax = _niceMax(tops.isEmpty ? 1 : tops.reduce(math.max));
    final ticks = _ticks(yMax);
    final xTicks = widget.xTicks ?? [for (var i = _n - 1; i >= 0; i -= 2) i].reversed.toList();
    final compact = widget.compact ?? widget.format;
    final peak = tops.isEmpty ? -1 : tops.indexOf(tops.reduce(math.max));
    final direct = widget.directLabels && _stacked;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, box) {
            const left = _yLabelW;
            final plotW = box.maxWidth - left - (direct ? _directRoom : MuSpace.s2);
            final plotH = widget.height - _xBand;
            final band = plotW / math.max(_n, 1);
            final barW = math.min(_maxBar, band * _bandShare);
            double cx(int i) => left + band * i + band / 2;
            double y(double v) => plotH - plotH * v / yMax;

            final labels = <Widget>[];
            // Selective labels: peak + latest (totals when stacked), none when grouped.
            final totals =
                widget.valueLabels &&
                (widget.mode == MuBarMode.stacked || widget.series.length == 1);
            if (totals) {
              for (final i in {peak, _n - 1}) {
                if (i < 0) continue;
                labels.add(
                  Positioned(
                    left: cx(i) - 30,
                    width: 60,
                    top: y(tops[i]) - 20,
                    child: ExcludeSemantics(
                      child: Text(
                        widget.format(tops[i]),
                        textAlign: TextAlign.center,
                        style: MuType.numXs.copyWith(color: c.text),
                      ),
                    ),
                  ),
                );
              }
            }
            if (direct && _n > 0) {
              final i = _n - 1;
              var base = 0.0;
              for (var k = 0; k < widget.series.length; k++) {
                final v = _value(widget.series[k], i);
                final h = plotH * v / yMax;
                final mid = y(base + v / 2);
                base += v;
                if (h < _minDirect) continue;
                final s = widget.series[k];
                labels.add(
                  Positioned(
                    left: cx(i) + barW / 2 + MuSpace.s2,
                    width: _directRoom,
                    top: mid - 9,
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          if (s.sport != null) ...[
                            MuSportIcon(s.sport!, size: MuSize.iconXs, color: c.textSecondary),
                            const SizedBox(width: MuSpace.s1),
                          ],
                          Flexible(
                            child: Text(
                              s.label,
                              overflow: TextOverflow.ellipsis,
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            }

            void pick(Offset p) {
              if (_n == 0) return;
              final i = ((p.dx - left) / band).floor().clamp(0, _n - 1);
              setState(() => _active = i);
            }

            return Focus(
              focusNode: _focus,
              onKeyEvent: (_, e) => _onKey(e),
              child: Semantics(
                container: true,
                label: widget.chartLabel ?? widget.title,
                value: _active == null ? (_n == 0 ? null : _describe(_n - 1)) : _describe(_active!),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => pick(d.localPosition),
                  onHorizontalDragStart: (d) => pick(d.localPosition),
                  onHorizontalDragUpdate: (d) => pick(d.localPosition),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: Size(box.maxWidth, widget.height),
                        painter: _ColumnPainter(
                          values: [for (final s in widget.series) s.data],
                          colors: colors,
                          stacked: _stacked,
                          yMax: yMax,
                          ticks: ticks,
                          left: left,
                          plotW: plotW,
                          plotH: plotH,
                          band: band,
                          barW: barW,
                          grid: c.chartGrid,
                          axis: c.chartAxis,
                          hover: c.surfaceMuted,
                          active: _active,
                        ),
                      ),
                      for (final t in ticks)
                        Positioned(
                          left: 0,
                          width: left - MuSpace.s2,
                          top: y(t) - 8,
                          child: Text(
                            compact(t),
                            textAlign: TextAlign.end,
                            style: MuType.numXs.copyWith(color: c.textSecondary),
                          ),
                        ),
                      for (final i in xTicks)
                        if (i >= 0 && i < _n)
                          Positioned(
                            left: cx(i) - 40,
                            width: 80,
                            top: plotH + MuSpace.s2,
                            child: Text(
                              widget.categories[i],
                              textAlign: TextAlign.center,
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ),
                      ...labels,
                      if (_active != null)
                        _tooltip(c, colors, cx(_active!), y(tops[_active!]), box.maxWidth),
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

  Widget _tooltip(MuColors c, List<Color> colors, double x, double top, double width) {
    final i = _active!;
    final tx = widget.tooltipCategories ?? widget.categories;
    const w = 160.0;
    final room = top > 110;
    final dx = (x - w / 2).clamp(0.0, math.max(0.0, width - w)).toDouble();
    return Positioned(
      left: dx,
      bottom: room ? widget.height - top + MuSpace.s2 : null,
      top: room ? null : MuSpace.s2,
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
              for (var k = widget.series.length - 1; k >= 0; k--)
                Row(
                  children: [
                    Container(width: 10, height: 10, color: colors[k]),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        widget.series[k].label,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                    Text(
                      widget.format(_value(widget.series[k], i)),
                      style: MuType.numS.copyWith(color: c.text),
                    ),
                  ],
                ),
              if (widget.series.length > 1)
                Text(
                  '${widget.format(_total(i))} ${widget.totalLabel}',
                  style: MuType.labelS.copyWith(color: c.text),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _horizontal(MuColors c, List<Color> colors) {
    final tops = [for (var i = 0; i < _n; i++) _top(i)];
    final max = tops.isEmpty ? 1.0 : math.max(tops.reduce(math.max), 1.0);
    return Column(
      children: [
        for (var i = 0; i < _n; i++)
          Semantics(
            container: true,
            label: _describe(i),
            child: ExcludeSemantics(
              child: SizedBox(
                height: _row,
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        widget.categories[i],
                        overflow: TextOverflow.ellipsis,
                        style: MuType.body.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final room = box.maxWidth - 72;
                          var x = 0.0;
                          final parts = <Widget>[];
                          for (var k = 0; k < widget.series.length; k++) {
                            final w = room * _value(widget.series[k], i) / max;
                            final last = k == widget.series.length - 1;
                            parts.add(
                              Positioned(
                                left: x,
                                width: math.max(0, w - (last ? 0 : _gap)),
                                top: (_row - _hBar) / 2,
                                height: _hBar,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors[k],
                                    borderRadius: last
                                        ? const BorderRadius.horizontal(
                                            right: Radius.circular(_end),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                            x += w;
                          }
                          return Stack(
                            children: [
                              ...parts,
                              if (widget.valueLabels)
                                Positioned(
                                  left: x + MuSpace.s2,
                                  top: (_row - 18) / 2,
                                  child: Text(
                                    widget.format(tops[i]),
                                    style: MuType.numXs.copyWith(color: c.text),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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

class _ColumnPainter extends CustomPainter {
  _ColumnPainter({
    required this.values,
    required this.colors,
    required this.stacked,
    required this.yMax,
    required this.ticks,
    required this.left,
    required this.plotW,
    required this.plotH,
    required this.band,
    required this.barW,
    required this.grid,
    required this.axis,
    required this.hover,
    required this.active,
  });

  final List<List<double>> values;
  final List<Color> colors;
  final bool stacked;
  final double yMax;
  final List<double> ticks;
  final double left;
  final double plotW;
  final double plotH;
  final double band;
  final double barW;
  final Color grid;
  final Color axis;
  final Color hover;
  final int? active;

  static const double _gap = 2;
  static const double _end = 4;

  int get _n => values.isEmpty ? 0 : values.map((s) => s.length).reduce(math.max);

  double _y(double v) => plotH - plotH * v / yMax;

  double _v(int k, int i) => i < values[k].length ? values[k][i] : 0;

  @override
  void paint(Canvas canvas, Size size) {
    if (active != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left + band * active!, 0, band, plotH),
          const Radius.circular(_end),
        ),
        Paint()..color = hover,
      );
    }
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final t in ticks.skip(1)) {
      final y = _y(t);
      canvas.drawLine(Offset(left, y), Offset(left + plotW, y), gridPaint);
    }
    for (var i = 0; i < _n; i++) {
      final cx = left + band * i + band / 2;
      if (stacked) {
        var base = 0.0;
        final topK = [
          for (var k = 0; k < values.length; k++)
            if (_v(k, i) > 0) k,
        ].lastOrNull;
        for (var k = 0; k < values.length; k++) {
          final v = _v(k, i);
          if (v <= 0) continue;
          final bottom = _y(base) - (base > 0 ? _gap : 0);
          final top = _y(base + v);
          base += v;
          if (bottom <= top) continue;
          final r = k == topK ? const Radius.circular(_end) : Radius.zero;
          canvas.drawRRect(
            RRect.fromLTRBAndCorners(
              cx - barW / 2,
              top,
              cx + barW / 2,
              bottom,
              topLeft: r,
              topRight: r,
            ),
            Paint()..color = colors[k],
          );
        }
      } else {
        final m = values.length;
        final w = (barW - _gap * (m - 1)) / m;
        for (var k = 0; k < m; k++) {
          final v = _v(k, i);
          if (v <= 0) continue;
          final x = cx - barW / 2 + k * (w + _gap);
          canvas.drawRRect(
            RRect.fromLTRBAndCorners(
              x,
              _y(v),
              x + w,
              plotH,
              topLeft: const Radius.circular(_end),
              topRight: const Radius.circular(_end),
            ),
            Paint()..color = colors[k],
          );
        }
      }
    }
    canvas.drawLine(
      Offset(left, plotH),
      Offset(left + plotW, plotH),
      Paint()
        ..color = axis
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_ColumnPainter old) => true;
}
