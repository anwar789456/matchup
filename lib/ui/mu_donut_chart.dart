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

/// One segment of a [MuDonutChart].
@immutable
class MuSlice {
  const MuSlice({required this.label, required this.value, this.color, this.sport});

  MuSlice.sport(MuSport this.sport, this.value, {String? label})
    : label = label ?? sport.label,
      color = null;

  final String label;
  final double value;

  /// Defaults to the sport colour, else `chart-1…6` in order.
  final Color? color;
  final MuSport? sport;
}

/// DonutChart (components/DonutChart.md): a `mu-card` with title, subtitle and the table toggle,
/// a ring of up to 6 segments clockwise from 12 o’clock with 2 px `surface` gaps, the total in the
/// hole, and a legend (key · label · value · share). Tapping a segment or a legend row lifts it:
/// the others fade to 45 %, its row gets `surface-muted` and the hole becomes the readout
/// (value, name, « 29 % du total »). Esc restores the total.
class MuDonutChart extends StatefulWidget {
  MuDonutChart({
    super.key,
    required this.title,
    this.subtitle,
    required this.data,
    required this.format,
    required this.total,
    required this.totalLabel,
    this.centerFormat,
    this.size = 200,
    this.thickness = 32,
    String? categoryLabel,
    String? valueLabel,
    String? shareLabel,
    String? totalRowLabel,
    String? shareOfTotal,
    String? showTableLabel,
    String? showChartLabel,
  }) : showChartLabel = showChartLabel ?? l10n.voirLeGraphique, showTableLabel = showTableLabel ?? l10n.voirLeTableau, shareOfTotal = shareOfTotal ?? l10n.duTotal, totalRowLabel = totalRowLabel ?? l10n.total, shareLabel = shareLabel ?? l10n.partText2, valueLabel = valueLabel ?? l10n.valeur, categoryLabel = categoryLabel ?? l10n.categorie;

  final String title;
  final String? subtitle;
  final List<MuSlice> data;

  /// Legend and table value (« 39 200 DT »).
  final String Function(double value) format;

  /// The hole: total without unit (« 48 600 ») over [totalLabel] (« DT encaissés »).
  final String total;
  final String totalLabel;

  /// The readout's value in the hole; defaults to [format].
  final String Function(double value)? centerFormat;
  final double size;
  final double thickness;
  final String categoryLabel;
  final String valueLabel;
  final String shareLabel;
  final String totalRowLabel;

  /// « 29 % du total ».
  final String shareOfTotal;
  final String showTableLabel;
  final String showChartLabel;

  @override
  State<MuDonutChart> createState() => _MuDonutChartState();
}

class _MuDonutChartState extends State<MuDonutChart> {
  int? _active;
  bool _table = false;
  final _focus = FocusNode();

  // DonutChart.md: legend rows 44, keys 10 × 10.
  static const double _row = 44;
  static const double _key = 10;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<Color> _colors(MuColors c) {
    final palette = [c.chart1, c.chart2, c.chart3, c.chart4, c.chart5, c.chart6];
    var i = 0;
    return [
      for (final s in widget.data) s.color ?? s.sport?.color(c) ?? palette[i++ % palette.length],
    ];
  }

  /// Whole percentages adding up to 100 (largest remainder).
  List<int> get _shares {
    final sum = widget.data.fold(0.0, (a, s) => a + s.value);
    if (sum <= 0) return [for (final _ in widget.data) 0];
    final raw = [for (final s in widget.data) s.value * 100 / sum];
    final out = [for (final r in raw) r.floor()];
    var left = 100 - out.fold(0, (a, b) => a + b);
    final order = [for (var i = 0; i < raw.length; i++) i]
      ..sort((a, b) => (raw[b] - raw[b].floor()).compareTo(raw[a] - raw[a].floor()));
    for (final i in order) {
      if (left <= 0) break;
      out[i]++;
      left--;
    }
    return out;
  }

  KeyEventResult _onKey(KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final n = widget.data.length;
    final k = e.logicalKey;
    int? next;
    if (k == LogicalKeyboardKey.arrowDown) next = math.min((_active ?? -1) + 1, n - 1);
    if (k == LogicalKeyboardKey.arrowUp) next = math.max((_active ?? n) - 1, 0);
    if (k == LogicalKeyboardKey.escape) {
      setState(() => _active = null);
      return KeyEventResult.handled;
    }
    if (next == null) return KeyEventResult.ignored;
    setState(() => _active = next);
    return KeyEventResult.handled;
  }

  void _toggle(int i) => setState(() => _active = _active == i ? null : i);

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final colors = _colors(c);
    final shares = _shares;
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
                icon: _table ? PhosphorIcons.chartDonut() : PhosphorIcons.table(),
                label: _table ? widget.showChartLabel : widget.showTableLabel,
                size: MuIconButtonSize.s,
                variant: MuIconButtonVariant.ghost,
                onPressed: () => setState(() => _table = !_table),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          if (_table) _tableView(c, shares) else ..._chart(c, colors, shares),
        ],
      ),
    );
  }

  List<Widget> _chart(MuColors c, List<Color> colors, List<int> shares) {
    final a = _active;
    return [
      Center(
        child: ExcludeSemantics(
          child: GestureDetector(
            onTapDown: (d) {
              final r = widget.size / 2;
              final p = d.localPosition - Offset(r, r);
              final dist = p.distance;
              if (dist < r - widget.thickness - 4 || dist > r + 4) {
                setState(() => _active = null);
                return;
              }
              // Clockwise from 12 o’clock.
              var angle = math.atan2(p.dy, p.dx) + math.pi / 2;
              if (angle < 0) angle += 2 * math.pi;
              final sum = widget.data.fold(0.0, (a, s) => a + s.value);
              var acc = 0.0;
              for (var i = 0; i < widget.data.length; i++) {
                acc += widget.data[i].value / sum * 2 * math.pi;
                if (angle <= acc) {
                  _toggle(i);
                  return;
                }
              }
            },
            child: SizedBox.square(
              dimension: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(widget.size),
                    painter: _RingPainter(
                      values: [for (final s in widget.data) s.value],
                      colors: colors,
                      thickness: widget.thickness,
                      gap: c.surface,
                      active: a,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(widget.thickness + MuSpace.s2),
                    child: AnimatedSwitcher(
                      duration: MuMotion.durationOf(context, MuMotion.fast),
                      child: a == null
                          ? Column(
                              key: const ValueKey('total'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.total, style: MuType.numXl.copyWith(color: c.text)),
                                Text(
                                  widget.totalLabel,
                                  textAlign: TextAlign.center,
                                  style: MuType.caption.copyWith(color: c.textSecondary),
                                ),
                              ],
                            )
                          : Column(
                              key: ValueKey(a),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  child: Text(
                                    (widget.centerFormat ?? widget.format)(widget.data[a].value),
                                    style: MuType.numXl.copyWith(color: c.text),
                                  ),
                                ),
                                Text(
                                  widget.data[a].label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: MuType.labelS.copyWith(color: c.text),
                                ),
                                Text(
                                  '${shares[a]} % ${widget.shareOfTotal}',
                                  style: MuType.caption.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: MuSpace.s4),
      Focus(
        focusNode: _focus,
        onKeyEvent: (_, e) => _onKey(e),
        child: Column(
          children: [
            for (var i = 0; i < widget.data.length; i++)
              Semantics(
                button: true,
                selected: a == i,
                label:
                    '${widget.data[i].label} ${widget.format(widget.data[i].value)} · ${shares[i]} %',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: MuRadius.smAll,
                  onTap: () => _toggle(i),
                  child: AnimatedContainer(
                    duration: MuMotion.durationOf(context, MuMotion.fast),
                    constraints: const BoxConstraints(minHeight: _row),
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3),
                    decoration: BoxDecoration(
                      color: a == i ? c.surfaceMuted : c.surfaceMuted.withValues(alpha: 0),
                      borderRadius: MuRadius.smAll,
                    ),
                    child: Row(
                      children: [
                        Container(width: _key, height: _key, color: colors[i]),
                        const SizedBox(width: MuSpace.s3),
                        if (widget.data[i].sport != null) ...[
                          MuSportIcon(widget.data[i].sport!, size: MuSize.iconXs),
                          const SizedBox(width: MuSpace.s2),
                        ],
                        Expanded(
                          child: Text(
                            widget.data[i].label,
                            style: MuType.body.copyWith(color: c.text),
                          ),
                        ),
                        Text(
                          ltr(widget.format(widget.data[i].value)),
                          style: MuType.numS.copyWith(color: c.text),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                          child: Text('·', style: MuType.numS.copyWith(color: c.textSecondary)),
                        ),
                        SizedBox(
                          width: MuSpace.s10,
                          child: Text(
                            '${shares[i]} %',
                            textAlign: TextAlign.end,
                            style: MuType.numS.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _tableView(MuColors c, List<int> shares) {
    final head = MuType.labelS.copyWith(color: c.textSecondary);
    final cell = MuType.numS.copyWith(color: c.text);
    final sum = widget.data.fold(0.0, (a, s) => a + s.value);
    Widget pad(Widget w) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: w,
    );
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.6)},
      border: TableBorder(horizontalInside: BorderSide(color: c.border)),
      children: [
        TableRow(
          children: [
            pad(Text(widget.categoryLabel, style: head)),
            pad(Text(widget.valueLabel, style: head, textAlign: TextAlign.end)),
            pad(Text(widget.shareLabel, style: head, textAlign: TextAlign.end)),
          ],
        ),
        for (var i = 0; i < widget.data.length; i++)
          TableRow(
            children: [
              pad(Text(widget.data[i].label, style: MuType.caption.copyWith(color: c.text))),
              pad(
                Text(
                  ltr(widget.format(widget.data[i].value)),
                  style: cell,
                  textAlign: TextAlign.end,
                ),
              ),
              pad(Text('${shares[i]} %', style: cell, textAlign: TextAlign.end)),
            ],
          ),
        TableRow(
          children: [
            pad(Text(widget.totalRowLabel, style: MuType.label.copyWith(color: c.text))),
            pad(Text(ltr(widget.format(sum)), style: cell, textAlign: TextAlign.end)),
            pad(Text('100 %', style: cell, textAlign: TextAlign.end)),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.values,
    required this.colors,
    required this.thickness,
    required this.gap,
    required this.active,
  });

  final List<double> values;
  final List<Color> colors;
  final double thickness;
  final Color gap;
  final int? active;

  static const double _gapWidth = 2;
  static const double _lift = 4;
  static const double _fade = 0.45;

  @override
  void paint(Canvas canvas, Size size) {
    final sum = values.fold(0.0, (a, b) => a + b);
    if (sum <= 0) return;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - thickness / 2 - _lift;
    var start = -math.pi / 2;
    final edges = <double>[];
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / sum * 2 * math.pi;
      final lifted = active == i;
      final mid = start + sweep / 2;
      final offset = lifted ? Offset(math.cos(mid), math.sin(mid)) * _lift : Offset.zero;
      final color = active == null || lifted ? colors[i] : colors[i].withValues(alpha: _fade);
      canvas.drawArc(
        Rect.fromCircle(center: center + offset, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..color = color,
      );
      edges.add(start);
      start += sweep;
    }
    if (values.where((v) => v > 0).length < 2) return;
    final line = Paint()
      ..color = gap
      ..strokeWidth = _gapWidth;
    for (final a in edges) {
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (radius - thickness / 2 - 1),
        center + dir * (radius + thickness / 2 + _lift + 1),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => true;
}
