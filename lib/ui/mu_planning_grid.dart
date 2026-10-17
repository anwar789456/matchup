import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';

/// What a slot of the planning holds (OWN-11 legend).
enum MuPlanningState {
  /// Nothing booked: dashed outline, « Libre », the price (with ⚡ at peak hours).
  free,

  /// A private booking: surface, hairline and the sport bar.
  booked,

  /// A public game: the sport's soft fill and bar.
  public,

  /// Booked, not fully paid yet: like [booked] with the clock in `warning-text`.
  pendingPayment,

  /// Closed by the owner: hatched, lock + reason.
  blocked,

  /// Nobody came: `error-soft`.
  noShow,

  /// The owner's own game.
  mine,

  /// Finished: muted.
  done,
}

/// One cell of a [MuPlanningGrid].
@immutable
class MuPlanningCell {
  const MuPlanningCell({
    required this.state,
    required this.semanticLabel,
    this.title,
    this.meta,
    this.metaIcon,
    this.metaIconColor,
    this.live = false,
    this.peak = false,
    this.dimmed = false,
    this.onTap,
    this.onLongPress,
  });

  final MuPlanningState state;

  /// « Terrain 1, 19h00, partie publique de Salma G., 8 sur 10 ».
  final String semanticLabel;

  /// « Salma G. », « Libre », « Bloqué ».
  final String? title;

  /// « 8/10 joueurs », « 150 DT », « Nettoyage ».
  final String? meta;
  final IconData? metaIcon;
  final Color? metaIconColor;

  /// « En cours »: the red live dot before [meta].
  final bool live;

  /// Peak hour: ⚡ before the price of a free slot.
  final bool peak;

  /// A free slot already past (60 %).
  final bool dimmed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
}

/// A column header (« Terrain 3 » · « Indoor » with the umbrella).
@immutable
class MuPlanningColumn {
  const MuPlanningColumn({required this.name, this.detail, this.icon});

  final String name;
  final String? detail;
  final IconData? icon;
}

/// The owner's planning (OWN-11): courts as columns, hours as rows, sticky court headers and hour
/// labels, the « now » line in `error`, and the quiet hours before the first booking folded into
/// one row (« 08h00 – 17h00 · aucune réservation ») that opens on tap.
///
/// Cells are 60 high, 4 apart; the hour column is 48 wide; columns are at least 104 wide (the
/// grid scrolls sideways on narrow phones). In RTL the courts follow the reading direction; hours
/// stay top to bottom.
class MuPlanningGrid extends StatefulWidget {
  const MuPlanningGrid({
    super.key,
    required this.columns,
    required this.hours,
    required this.cellAt,
    required this.hourLabel,
    required this.label,
    this.now,
    this.foldBefore,
    this.foldLabel,
    this.selected,
    this.sportColor,
    this.sportSoft,
    this.bottomPadding = 120,
  });

  final List<MuPlanningColumn> columns;

  /// The hours shown, in order (8 … 23).
  final List<int> hours;
  final MuPlanningCell Function(int column, int hour) cellAt;

  /// « 08h ».
  final String Function(int hour) hourLabel;

  /// The grid's accessible name.
  final String label;

  /// The « now » line; null when the day isn't today.
  final DateTime? now;

  /// Hours before this one are folded into one row while nothing happens in them.
  final int? foldBefore;

  /// « 08h00 – 17h00 · aucune réservation ».
  final String? foldLabel;

  /// The selected cell (column, hour): 2 px `text` ring.
  final (int, int)? selected;

  /// Defaults to `football` / `football-soft`.
  final Color? sportColor;
  final Color? sportSoft;
  final double bottomPadding;

  @override
  State<MuPlanningGrid> createState() => _MuPlanningGridState();
}

class _MuPlanningGridState extends State<MuPlanningGrid> {
  bool _unfolded = false;

  // OWN-11: 48 hour column, 104 minimum court column, 60 cells, 4 gaps, 48 header, 32 fold row.
  static const double _timeW = 48;
  static const double _minCol = 104;
  static const double _cellH = 60;
  static const double _gap = 4;
  static const double _headH = 48;
  static const double _foldH = 32;
  static const double _nowDot = 8;
  static const double _nowLine = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final fold = widget.foldBefore != null && !_unfolded
        ? widget.hours.where((h) => h < widget.foldBefore!).toList()
        : const <int>[];
    final hours = widget.hours.where((h) => !fold.contains(h)).toList();
    return LayoutBuilder(
      builder: (context, box) {
        final n = widget.columns.length;
        final colW = math.max(_minCol, (box.maxWidth - _timeW - _gap * 2 - _gap * (n - 1)) / n);
        final width = _timeW + n * colW + (n - 1) * _gap + _gap * 2;
        final Widget header = Container(
          height: _headH,
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              const SizedBox(width: _timeW + _gap),
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                SizedBox(width: colW, child: _head(c, widget.columns[i])),
              ],
            ],
          ),
        );
        final rows = <Widget>[
          if (fold.isNotEmpty)
            _row(
              c,
              hour: fold.first,
              height: _foldH,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: MuSpace.s1),
                child: Semantics(
                  button: true,
                  expanded: false,
                  label: widget.foldLabel,
                  excludeSemantics: true,
                  child: Material(
                    color: c.surfaceMuted,
                    borderRadius: MuRadius.xsAll,
                    child: InkWell(
                      borderRadius: MuRadius.xsAll,
                      onTap: () => setState(() => _unfolded = true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.caretDown(), size: 14, color: c.textSecondary),
                            const SizedBox(width: MuSpace.s1 + 2),
                            Expanded(
                              child: Text(
                                widget.foldLabel ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MuType.caption.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              colW: colW,
              span: true,
            ),
          for (final h in hours)
            _row(
              c,
              hour: h,
              height: _cellH,
              colW: colW,
              child: Row(
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: colW,
                      height: _cellH,
                      child: _Cell(
                        cell: widget.cellAt(i, h),
                        selected: widget.selected == (i, h),
                        sport: widget.sportColor ?? c.football,
                        sportSoft: widget.sportSoft ?? c.footballSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ];
        final grid = SizedBox(
          width: width,
          child: Column(
            children: [
              header,
              Expanded(
                child: Semantics(
                  container: true,
                  label: widget.label,
                  child: ListView(
                    padding: EdgeInsets.only(top: _gap, bottom: widget.bottomPadding),
                    children: rows,
                  ),
                ),
              ),
            ],
          ),
        );
        return ColoredBox(
          color: c.surface,
          child: width > box.maxWidth
              ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: grid)
              : grid,
        );
      },
    );
  }

  Widget _head(MuColors c, MuPlanningColumn col) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  col.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.label.copyWith(color: c.text),
                ),
              ),
              if (col.icon != null) ...[
                const SizedBox(width: MuSpace.s1),
                Icon(col.icon, size: 14, color: c.textSecondary),
              ],
            ],
          ),
          if (col.detail != null)
            Text(col.detail!, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
      ),
    ),
  );

  Widget _row(
    MuColors c, {
    required int hour,
    required double height,
    required double colW,
    required Widget child,
    bool span = false,
  }) {
    final now = widget.now;
    final current = now != null && now.hour == hour && !span;
    final line = current ? height * now.minute / 60 : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _timeW,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: MuSpace.s1 + 2,
                      top: span ? MuSpace.s2 : 2,
                    ),
                    child: Text(
                      widget.hourLabel(hour),
                      textAlign: TextAlign.end,
                      style: MuType.numXs.copyWith(color: current ? c.errorText : c.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(child: child),
              ],
            ),
            if (line != null)
              PositionedDirectional(
                start: _timeW - _nowDot / 2,
                end: 0,
                top: line - _gap / 2 - _nowDot / 2,
                height: _nowDot,
                child: IgnorePointer(
                  child: Semantics(
                    label: 'now',
                    excludeSemantics: true,
                    child: Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        PositionedDirectional(
                          start: _nowDot / 2,
                          end: 0,
                          height: _nowLine,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.error,
                              borderRadius: MuRadius.fullAll,
                            ),
                          ),
                        ),
                        Container(
                          width: _nowDot,
                          height: _nowDot,
                          decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.cell,
    required this.selected,
    required this.sport,
    required this.sportSoft,
  });

  final MuPlanningCell cell;
  final bool selected;
  final Color sport;
  final Color sportSoft;

  // OWN-11: 3 px sport bar, 1 px hairline, 2 px selection ring, live dot 6, meta icons 12.
  static const double _live = 6;
  static const double _metaIcon = 12;
  static const double _dimmed = 0.6;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = cell.state;
    final bg = switch (s) {
      MuPlanningState.public => sportSoft,
      MuPlanningState.done => c.surfaceMuted,
      MuPlanningState.noShow => c.errorSoft,
      MuPlanningState.free => Colors.transparent,
      _ => c.surface,
    };
    final ink = switch (s) {
      MuPlanningState.noShow => c.errorText,
      MuPlanningState.done || MuPlanningState.free || MuPlanningState.blocked => c.textSecondary,
      _ => c.text,
    };
    final metaInk = s == MuPlanningState.noShow ? c.errorText : c.textSecondary;
    final hairline = switch (s) {
      MuPlanningState.booked ||
      MuPlanningState.pendingPayment ||
      MuPlanningState.mine => c.borderStrong,
      MuPlanningState.done => c.border,
      MuPlanningState.noShow => c.error.withValues(alpha: 0.3),
      MuPlanningState.blocked => c.borderStrong,
      _ => null,
    };
    final bar = switch (s) {
      MuPlanningState.booked || MuPlanningState.public || MuPlanningState.pendingPayment => sport,
      MuPlanningState.mine => c.primary,
      _ => null,
    };

    final Widget meta = Row(
      children: [
        if (cell.live) ...[
          Container(
            width: _live,
            height: _live,
            decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
          ),
          const SizedBox(width: MuSpace.s1),
        ],
        if (cell.peak) ...[
          Icon(
            PhosphorIcons.lightning(PhosphorIconsStyle.fill),
            size: _metaIcon,
            color: c.warningText,
          ),
          const SizedBox(width: 3),
        ],
        if (cell.metaIcon != null) ...[
          Icon(cell.metaIcon, size: _metaIcon, color: cell.metaIconColor ?? metaInk),
          const SizedBox(width: 3),
        ],
        if (cell.meta != null)
          Flexible(
            child: Text(
              cell.meta!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (s == MuPlanningState.free ? MuType.numXs : MuType.caption).copyWith(
                color: metaInk,
              ),
            ),
          ),
      ],
    );

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (cell.title != null)
          Text(
            cell.title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (s == MuPlanningState.free ? MuType.caption : MuType.labelS).copyWith(
              color: ink,
            ),
          ),
        if (cell.meta != null || cell.live) meta,
      ],
    );
    if (s == MuPlanningState.blocked) {
      content = Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: c.surface, borderRadius: MuRadius.xsAll),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.lockSimple(), size: _metaIcon, color: c.text),
                  const SizedBox(width: MuSpace.s1),
                  Text(cell.title ?? '', style: MuType.labelS.copyWith(color: c.text)),
                ],
              ),
              if (cell.meta != null)
                Text(
                  cell.meta!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
            ],
          ),
        ),
      );
    }

    Widget box = CustomPaint(
      painter: _CellPainter(
        fill: bg,
        hairline: hairline,
        bar: bar,
        dashed: s == MuPlanningState.free ? c.borderStrong : null,
        hatch: s == MuPlanningState.blocked ? (c.surfaceMuted, c.borderStrong) : null,
        ring: selected ? c.text : null,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: MuSpace.s2, end: MuSpace.s2),
        child: content,
      ),
    );
    if (cell.dimmed) box = Opacity(opacity: _dimmed, child: box);

    return Semantics(
      button: cell.onTap != null,
      selected: selected,
      label: cell.semanticLabel,
      excludeSemantics: true,
      onLongPress: cell.onLongPress,
      child: MuFocusRing(
        borderRadius: MuRadius.xsAll,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: MuRadius.xsAll,
            onTap: cell.onTap,
            onLongPress: cell.onLongPress,
            child: box,
          ),
        ),
      ),
    );
  }
}

class _CellPainter extends CustomPainter {
  _CellPainter({
    required this.fill,
    required this.hairline,
    required this.bar,
    required this.dashed,
    required this.hatch,
    required this.ring,
    required this.rtl,
    this.radius = MuRadius.xs,
    this.hatchStep = 9,
  });

  final double radius;
  final double hatchStep;
  final Color fill;
  final Color? hairline;
  final Color? bar;
  final Color? dashed;
  final (Color, Color)? hatch;
  final Color? ring;
  final bool rtl;

  static const double _bar = 3;
  static const double _ringW = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(rect, Paint()..color = fill);
    if (hatch != null) {
      final (muted, strong) = hatch!;
      final p = Paint()
        ..color = muted
        ..strokeWidth = hatchStep / 3;
      final q = Paint()
        ..color = strong
        ..strokeWidth = 1;
      // 135° stripes every 9 px.
      for (var x = -size.height; x < size.width + size.height; x += hatchStep) {
        canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
        canvas.drawLine(Offset(x + 1, size.height), Offset(x + 1 + size.height, 0), q);
      }
    }
    if (bar != null) {
      canvas.drawRect(
        rtl
            ? Rect.fromLTWH(size.width - _bar, 0, _bar, size.height)
            : Rect.fromLTWH(0, 0, _bar, size.height),
        Paint()..color = bar!,
      );
    }
    canvas.restore();
    if (hairline != null) {
      canvas.drawRRect(
        rr.deflate(0.5),
        Paint()
          ..color = hairline!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    if (dashed != null) {
      final path = Path()..addRRect(rr.deflate(0.5));
      final p = Paint()
        ..color = dashed!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 6) {
          canvas.drawPath(m.extractPath(d, math.min(d + 3, m.length)), p);
        }
      }
    }
    if (ring != null) {
      canvas.drawRRect(
        rr.deflate(_ringW / 2),
        Paint()
          ..color = ring!
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringW,
      );
    }
  }

  @override
  bool shouldRepaint(_CellPainter old) => true;
}

/// The legend key of a planning state (OWN-11: 14 × 10, radius 2).
class MuPlanningKey extends StatelessWidget {
  const MuPlanningKey({super.key, required this.state, this.sportColor, this.sportSoft});

  final MuPlanningState state;
  final Color? sportColor;
  final Color? sportSoft;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final sport = sportColor ?? c.football;
    return CustomPaint(
      painter: _CellPainter(
        fill: switch (state) {
          MuPlanningState.public => sportSoft ?? c.footballSoft,
          MuPlanningState.free => Colors.transparent,
          MuPlanningState.noShow => c.errorSoft,
          MuPlanningState.done => c.surfaceMuted,
          _ => c.surface,
        },
        hairline: switch (state) {
          MuPlanningState.free || MuPlanningState.public => null,
          _ => c.borderStrong,
        },
        bar: switch (state) {
          MuPlanningState.booked ||
          MuPlanningState.public ||
          MuPlanningState.pendingPayment => sport,
          MuPlanningState.mine => c.primary,
          _ => null,
        },
        dashed: state == MuPlanningState.free ? c.borderStrong : null,
        hatch: state == MuPlanningState.blocked ? (c.surface, c.borderStrong) : null,
        ring: null,
        rtl: Directionality.of(context) == TextDirection.rtl,
        radius: 2,
        hatchStep: 3,
      ),
    );
  }
}
