import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';

enum MuSlotStatus { available, booked, blocked, mine }

/// One step of a court's timeline.
@immutable
class MuSlot {
  const MuSlot({
    this.status = MuSlotStatus.available,
    this.price,
    this.peak = false,
    this.discount,
    this.oldPrice,
    this.label,
  });

  final MuSlotStatus status;

  /// The court's price for the hour (« 150 DT »).
  final num? price;
  final bool peak;

  /// « −20 % » over the new [price], with [oldPrice] struck.
  final int? discount;
  final num? oldPrice;

  /// The run's name when blocked (« Tournoi »).
  final String? label;

  bool get free => status == MuSlotStatus.available;
}

/// A court row: name, detail (« Éclairé »), an optional icon (`umbrella` for « Couvert ») and its
/// slots from the grid's start, one per step.
@immutable
class MuSlotCourt {
  const MuSlotCourt({
    required this.id,
    required this.name,
    required this.slots,
    this.detail,
    this.icon,
    this.iconLabel,
  });

  final String id;
  final String name;
  final String? detail;
  final IconData? icon;
  final String? iconLabel;
  final List<MuSlot> slots;
}

/// The picked run: slots [from] to [to] (exclusive) on [courtId].
@immutable
class MuSlotRange {
  const MuSlotRange(this.courtId, this.from, this.to);

  final String courtId;
  final int from;
  final int to;

  int get length => to - from;
  bool contains(String court, int i) => court == courtId && i >= from && i < to;

  @override
  bool operator ==(Object other) =>
      other is MuSlotRange && other.courtId == courtId && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(courtId, from, to);
}

/// SlotGrid (components/SlotGrid.md): courts as rows, time as columns; free cells show the court's
/// hourly price (lightning at peak hours), booked and blocked runs read as one block, the picked
/// run as one Volt bar. Tap a free slot to start a run, the next one to lengthen it, an end to
/// shorten it, a lone cell to clear it.
///
/// The court column stays put while the times scroll; the end edge fades while more slots follow.
/// The summary lives in the screen's sticky bottom bar on mobile.
class MuSlotGrid extends StatefulWidget {
  const MuSlotGrid({
    super.key,
    required this.courts,
    required this.start,
    required this.label,
    this.step = 60,
    this.value,
    this.onChanged,
    this.maxSlots = 2,
    this.legend = true,
    this.priceNote = 'Prix du terrain / h',
    this.padding = MuSpace.s4,
  });

  final List<MuSlotCourt> courts;

  /// Minutes after midnight of the first column (« 20h00 » = 1200).
  final int start;
  final int step;
  final MuSlotRange? value;
  final ValueChanged<MuSlotRange?>? onChanged;
  final int maxSlots;
  final bool legend;

  /// The corner of the time header.
  final String priceNote;

  /// Accessible name (« Créneaux Arena Five, mercredi 21 octobre »).
  final String label;

  /// Side padding (the grid is flush on mobile screens).
  final double padding;

  @override
  State<MuSlotGrid> createState() => _MuSlotGridState();
}

class _MuSlotGridState extends State<MuSlotGrid> {
  final _scroll = ScrollController();
  bool _moreAfter = true;
  bool _scrolled = false;

  // SlotGrid.md: court column 148 (128 under 560 wide); cells 56 high, `space-1` apart; 60 min
  // cells 96 wide (80 narrow), 30 min 68 (64); legend swatches 24 × 16; time header 24.
  static const double _narrow = 560;
  static const double _court = 148;
  static const double _courtNarrow = 128;
  static const double _cellH = 56;
  static const double _gap = MuSpace.s1;
  static const double _header = 24;
  static const Size _swatch = Size(24, 16);
  static const double _icon = 14;

  static const double _hour = 96;
  static const double _hourNarrow = 80;
  static const double _half = 68;
  static const double _halfNarrow = 64;
  static const double _pressScale = 0.96;

  double _cellW(bool narrow) =>
      widget.step >= 60 ? (narrow ? _hourNarrow : _hour) : (narrow ? _halfNarrow : _half);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelection());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final p = _scroll.position;
    final more = p.pixels < p.maxScrollExtent - 1;
    final scrolled = p.pixels > 0;
    if (more != _moreAfter || scrolled != _scrolled) {
      setState(() {
        _moreAfter = more;
        _scrolled = scrolled;
      });
    }
  }

  /// Opens scrolled to the selection.
  void _revealSelection() {
    if (!mounted || !_scroll.hasClients) return;
    final v = widget.value;
    _onScroll();
    if (v == null) return;
    final narrow = (context.size?.width ?? 0) < _narrow;
    final x = v.from * (_cellW(narrow) + _gap) - _gap;
    _scroll.jumpTo(x.clamp(0, _scroll.position.maxScrollExtent));
  }

  String _time(int index) => formatHour(widget.start + index * widget.step);

  void _tap(MuSlotCourt court, int i) {
    final v = widget.value;
    MuSlotRange? next;
    if (v == null || v.courtId != court.id) {
      next = MuSlotRange(court.id, i, i + 1);
    } else if (i == v.to && v.length < widget.maxSlots) {
      next = MuSlotRange(court.id, v.from, v.to + 1);
    } else if (i == v.from - 1 && v.length < widget.maxSlots) {
      next = MuSlotRange(court.id, i, v.to);
    } else if (v.length == 1 && i == v.from) {
      next = null;
    } else if (i == v.to - 1) {
      next = MuSlotRange(court.id, v.from, v.to - 1);
    } else if (i == v.from) {
      next = MuSlotRange(court.id, v.from + 1, v.to);
    } else {
      next = MuSlotRange(court.id, i, i + 1);
    }
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrow;
        final courtW = narrow ? _courtNarrow : _court;
        final cellW = _cellW(narrow);
        final columns = widget.courts.fold<int>(0, (m, r) => math.max(m, r.slots.length));
        final pad = widget.padding;

        final names = Container(
          width: courtW + pad,
          padding: EdgeInsetsDirectional.only(start: pad, end: MuSpace.s2),
          decoration: BoxDecoration(
            color: c.surface,
            border: _scrolled ? BorderDirectional(end: BorderSide(color: c.border)) : null,
            boxShadow: _scrolled ? MuElevation.of(context).level1 : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: _header,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    widget.priceNote,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
              for (final court in widget.courts) ...[
                const SizedBox(height: _gap),
                SizedBox(
                  height: _cellH,
                  child: Semantics(
                    header: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                court.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MuType.label.copyWith(color: c.text),
                              ),
                            ),
                            if (court.icon != null) ...[
                              const SizedBox(width: MuSpace.s1),
                              Icon(
                                court.icon,
                                size: _icon,
                                color: c.text,
                                semanticLabel: court.iconLabel,
                              ),
                            ],
                          ],
                        ),
                        if (court.detail != null)
                          Text(
                            court.detail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

        Widget row(MuSlotCourt court) {
          final blocks = <Widget>[];
          var i = 0;
          while (i < court.slots.length) {
            // Closures below must keep this block's index, not the loop's final one.
            final start = i;
            final s = court.slots[i];
            var span = 1;
            final selected = widget.value?.contains(court.id, i) ?? false;
            if (selected) {
              while (i + span < court.slots.length && widget.value!.contains(court.id, i + span)) {
                span++;
              }
            } else if (!s.free) {
              while (i + span < court.slots.length &&
                  court.slots[i + span].status == s.status &&
                  court.slots[i + span].label == s.label) {
                span++;
              }
            }
            final width = span * cellW + (span - 1) * _gap;
            if (blocks.isNotEmpty) blocks.add(const SizedBox(width: _gap));
            blocks.add(
              SizedBox(
                width: width,
                height: _cellH,
                child: selected
                    ? _Selected(
                        slots: court.slots.sublist(i, i + span),
                        cellWidth: cellW,
                        onTapCell: (k) => _tap(court, start + k),
                        semantics: [
                          for (var k = 0; k < span; k++)
                            '${court.name}, ${_time(i + k)}, sélectionné',
                        ],
                      )
                    : s.free
                    ? _Free(
                        slot: s,
                        onTap: () => _tap(court, start),
                        semantics:
                            '${court.name}, ${_time(i)}, disponible'
                            '${s.peak ? ', heure de pointe' : ''}'
                            '${s.price == null ? '' : ', ${formatDT(s.price!)} de l’heure'}',
                      )
                    : _Taken(slot: s, semantics: '${court.name}, ${_time(i)}'),
              ),
            );
            i += span;
          }
          return Row(children: blocks);
        }

        final times = Row(
          children: [
            for (var k = 0; k < columns; k++) ...[
              if (k > 0) const SizedBox(width: _gap),
              SizedBox(
                width: cellW,
                height: _header,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      _time(k),
                      style: MuType.numXs.copyWith(
                        color: (widget.start + k * widget.step) % 60 == 0
                            ? c.text
                            : c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );

        Widget scroller = SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsetsDirectional.only(end: pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              times,
              for (final court in widget.courts) ...[const SizedBox(height: _gap), row(court)],
            ],
          ),
        );
        if (_moreAfter) {
          final rtl = Directionality.of(context) == TextDirection.rtl;
          scroller = ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) {
              final fade = MuSpace.s10 / bounds.width;
              return LinearGradient(
                begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
                end: rtl ? Alignment.centerLeft : Alignment.centerRight,
                colors: [c.text, c.text, c.text.withValues(alpha: 0)],
                stops: [0, 1 - fade, 1],
              ).createShader(bounds);
            },
            child: scroller,
          );
        }

        final grid = Semantics(
          container: true,
          label: widget.label,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              names,
              Expanded(child: scroller),
            ],
          ),
        );

        if (!widget.legend) return grid;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: const _Legend(swatch: _swatch),
            ),
            const SizedBox(height: MuSpace.s4),
            grid,
          ],
        );
      },
    );
  }
}

/// « 150 DT » with the peak lightning, or the promo pill over the new price.
class _Price extends StatelessWidget {
  const _Price({required this.slot, required this.color, this.leading});

  final MuSlot slot;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    if (slot.price == null) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?leading,
          if (leading == null && slot.peak) ...[
            Icon(
              PhosphorIcons.lightning(PhosphorIconsStyle.fill),
              size: _MuSlotGridState._icon,
              color: c.warningText,
            ),
            const SizedBox(width: MuSpace.s1),
          ],
          if (slot.discount != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
              decoration: BoxDecoration(color: c.successSoft, borderRadius: MuRadius.fullAll),
              child: Text(
                '−${slot.discount} %',
                style: MuType.labelS.copyWith(color: c.successText),
              ),
            ),
            const SizedBox(width: MuSpace.s1),
          ],
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(formatDT(slot.price!), style: MuType.numS.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _Free extends StatefulWidget {
  const _Free({required this.slot, required this.onTap, required this.semantics});

  final MuSlot slot;
  final VoidCallback onTap;
  final String semantics;

  @override
  State<_Free> createState() => _FreeState();
}

class _FreeState extends State<_Free> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final duration = MuMotion.durationOf(context, MuMotion.fast);
    return Semantics(
      button: true,
      selected: false,
      label: widget.semantics,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _down ? _MuSlotGridState._pressScale : 1,
        duration: duration,
        curve: MuMotion.enter,
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: MuRadius.xsAll,
            side: BorderSide(color: _hover ? c.text : c.borderStrong),
          ),
          child: InkWell(
            borderRadius: MuRadius.xsAll,
            onTap: widget.onTap,
            onHover: (v) => setState(() => _hover = v),
            onHighlightChanged: (v) => setState(() => _down = v),
            child: Center(
              child: _Price(slot: widget.slot, color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// The picked run: one Volt bar, the check on its first cell, each cell still tappable.
class _Selected extends StatelessWidget {
  const _Selected({
    required this.slots,
    required this.cellWidth,
    required this.onTapCell,
    required this.semantics,
  });

  final List<MuSlot> slots;
  final double cellWidth;
  final ValueChanged<int> onTapCell;
  final List<String> semantics;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.xsAll),
      child: Row(
        children: [
          for (var k = 0; k < slots.length; k++) ...[
            if (k > 0) const SizedBox(width: _MuSlotGridState._gap),
            SizedBox(
              width: cellWidth,
              child: Semantics(
                button: true,
                selected: true,
                label: semantics[k],
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: MuRadius.xsAll,
                  onTap: () => onTapCell(k),
                  child: Center(
                    child: _Price(
                      slot: slots[k],
                      color: c.onAccent,
                      leading: k == 0
                          ? Padding(
                              padding: const EdgeInsetsDirectional.only(end: MuSpace.s1),
                              child: Icon(
                                PhosphorIcons.check(),
                                size: MuSize.iconXs,
                                color: c.onAccent,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A booked, blocked or « Ta réservation » run.
class _Taken extends StatelessWidget {
  const _Taken({required this.slot, required this.semantics});

  final MuSlot slot;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (String word, Widget child) = switch (slot.status) {
      MuSlotStatus.mine => (
        'ta réservation',
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.user(PhosphorIconsStyle.fill),
              size: _MuSlotGridState._icon,
              color: c.textInverse,
            ),
            const SizedBox(width: MuSpace.s1),
            Text('Toi', style: MuType.labelS.copyWith(color: c.textInverse)),
          ],
        ),
      ),
      MuSlotStatus.blocked => (
        (slot.label ?? 'Bloqué').toLowerCase(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
          decoration: BoxDecoration(color: c.surface, borderRadius: MuRadius.fullAll),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.lockSimple(),
                size: _MuSlotGridState._icon,
                color: c.textSecondary,
              ),
              const SizedBox(width: MuSpace.s1),
              Text(slot.label ?? 'Bloqué', style: MuType.labelS.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ),
      _ => ('réservé', Text('Réservé', style: MuType.labelS.copyWith(color: c.textSecondary))),
    };
    final Color ground = switch (slot.status) {
      MuSlotStatus.mine => c.surfaceInverse,
      MuSlotStatus.blocked => c.surface,
      _ => c.surfaceMuted,
    };
    return Semantics(
      label: '$semantics, $word',
      excludeSemantics: true,
      child: CustomPaint(
        foregroundPainter: null,
        painter: slot.status == MuSlotStatus.blocked ? _Hatch(c.borderStrong) : null,
        child: Container(
          decoration: BoxDecoration(
            color: slot.status == MuSlotStatus.blocked ? null : ground,
            borderRadius: MuRadius.xsAll,
            border: slot.status == MuSlotStatus.mine ? null : Border.all(color: c.border),
          ),
          alignment: Alignment.center,
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }
}

/// 135° hatching of a blocked run.
class _Hatch extends CustomPainter {
  const _Hatch(this.color);

  final Color color;

  static const double _spacing = 8;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(MuRadius.xs)),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += _spacing) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Hatch oldDelegate) => oldDelegate.color != color;
}

/// The keys: Disponible · Ta sélection · Réservé · Bloqué · Heure de pointe · Promo · Ta réservation.
class _Legend extends StatelessWidget {
  const _Legend({required this.swatch});

  final Size swatch;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    Widget key(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.fromSize(size: swatch, child: mark),
        const SizedBox(width: MuSpace.s2),
        Text(label, style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
    );
    BoxDecoration box(Color fill, [Color? edge]) => BoxDecoration(
      color: fill,
      borderRadius: MuRadius.xsAll,
      border: edge == null ? null : Border.all(color: edge),
    );
    return ExcludeSemantics(
      child: Wrap(
        spacing: MuSpace.s4,
        runSpacing: MuSpace.s2,
        children: [
          key(DecoratedBox(decoration: box(c.surface, c.borderStrong)), 'Disponible'),
          key(
            DecoratedBox(
              decoration: box(c.accent),
              child: Icon(PhosphorIcons.check(), size: MuSize.iconXs * 0.75, color: c.onAccent),
            ),
            'Ta sélection',
          ),
          key(DecoratedBox(decoration: box(c.surfaceMuted, c.border)), 'Réservé'),
          key(
            CustomPaint(
              painter: _Hatch(c.borderStrong),
              child: DecoratedBox(decoration: box(c.surface.withValues(alpha: 0), c.border)),
            ),
            'Bloqué',
          ),
          key(
            DecoratedBox(
              decoration: box(c.surface, c.border),
              child: Icon(
                PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                size: MuSize.iconXs * 0.75,
                color: c.warningText,
              ),
            ),
            'Heure de pointe',
          ),
          key(
            DecoratedBox(
              decoration: box(c.successSoft),
              child: Center(
                child: FittedBox(
                  child: Text('−%', style: MuType.labelS.copyWith(color: c.successText)),
                ),
              ),
            ),
            'Promo',
          ),
          key(
            DecoratedBox(
              decoration: box(c.surfaceInverse),
              child: Icon(
                PhosphorIcons.user(PhosphorIconsStyle.fill),
                size: MuSize.iconXs * 0.75,
                color: c.textInverse,
              ),
            ),
            'Ta réservation',
          ),
        ],
      ),
    );
  }
}
