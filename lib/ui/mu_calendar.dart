import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'src/interaction.dart';

/// What a day offers: free slots, sold out (still selectable to ask for an alert) or closed.
enum MuDayAvailability { available, soldOut, closed }

/// DatePicker (components/DatePicker.md), strip variant: a row of 52-wide pills — « Auj. » or the
/// weekday over the day number, with a pip when slots are free. Selected is Volt; sold out is
/// dimmed with the number struck through. The strip scrolls the selected day into view.
///
/// The month grid and the date field (`MuCalendar`, `MuDateField`) come when a screen needs them.
class MuDateStrip extends StatefulWidget {
  const MuDateStrip({
    super.key,
    required this.start,
    required this.today,
    required this.value,
    required this.onChanged,
    this.days = 14,
    this.availability,
    this.label = 'Jour',
    this.bleed = MuSpace.s4,
  });

  /// The first day shown.
  final DateTime start;
  final DateTime today;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final int days;
  final MuDayAvailability Function(DateTime day)? availability;

  /// The radio group's name (« Jour de réservation »).
  final String label;

  /// The strip runs to the screen edges, its content inset by this much.
  final double bleed;

  @override
  State<MuDateStrip> createState() => _MuDateStripState();
}

class _MuDateStripState extends State<MuDateStrip> {
  final _scroll = ScrollController();

  // DatePicker.md: strip pills 52 × 64, 4 px pip, `space-2` apart.
  static const double _pillW = 52;
  static const double _pillH = 64;
  static const double _pip = 4;

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> get _dates => [
    for (var i = 0; i < widget.days; i++)
      DateTime(widget.start.year, widget.start.month, widget.start.day + i),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(jump: true));
  }

  @override
  void didUpdateWidget(MuDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_same(oldWidget.value, widget.value)) _reveal();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls just enough for the selected pill to be fully visible (the strip stays on
  /// « Auj. » when the day is already in view).
  void _reveal({bool jump = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final i = _dates.indexWhere((d) => _same(d, widget.value));
    if (i < 0) return;
    final p = _scroll.position;
    if (!p.hasViewportDimension || p.viewportDimension == 0) return;
    final start = widget.bleed + i * (_pillW + MuSpace.s2);
    final end = start + _pillW;
    double? target;
    if (end + widget.bleed > p.pixels + p.viewportDimension) {
      target = end + widget.bleed - p.viewportDimension;
    } else if (start - widget.bleed < p.pixels) {
      target = start - widget.bleed;
    }
    if (target == null) return;
    target = target.clamp(0.0, p.maxScrollExtent);
    if (jump || MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: MuMotion.base, curve: MuMotion.move);
    }
  }

  KeyEventResult _onKey(KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dates = _dates;
    final i = dates.indexWhere((d) => _same(d, widget.value));
    var next = i;
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) next = i + (rtl ? -1 : 1);
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) next = i + (rtl ? 1 : -1);
    if (next == i || next < 0 || next >= dates.length) return KeyEventResult.ignored;
    widget.onChanged(dates[next]);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final dates = _dates;
    return Semantics(
      container: true,
      label: widget.label,
      child: Focus(
        onKeyEvent: (_, e) => _onKey(e),
        child: SizedBox(
          height: _pillH,
          child: ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: widget.bleed),
            itemCount: dates.length,
            separatorBuilder: (_, _) => const SizedBox(width: MuSpace.s2),
            itemBuilder: (context, i) {
              final d = dates[i];
              final selected = _same(d, widget.value);
              final today = _same(d, widget.today);
              final avail = widget.availability?.call(d) ?? MuDayAvailability.available;
              final soldOut = avail != MuDayAvailability.available;
              final closed = avail == MuDayAvailability.closed;
              final ink = selected ? c.onAccent : (soldOut ? c.textDisabled : c.text);
              final name = today ? 'Auj.' : formatWeekday(d);
              return Semantics(
                inMutuallyExclusiveGroup: true,
                selected: selected,
                button: true,
                enabled: !closed,
                label:
                    '${formatDay(d)}${today ? ', aujourd’hui' : ''}'
                    '${switch (avail) {
                      MuDayAvailability.available => ', créneaux disponibles',
                      MuDayAvailability.soldOut => ', complet',
                      MuDayAvailability.closed => ', fermé',
                    }}',
                excludeSemantics: true,
                child: MuFocusRing(
                  borderRadius: MuRadius.fullAll,
                  child: Material(
                    color: selected ? c.accent : (soldOut ? c.surfaceMuted : c.surface),
                    shape: StadiumBorder(
                      side: selected
                          ? BorderSide.none
                          : BorderSide(color: soldOut ? c.border : c.borderStrong),
                    ),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: closed ? null : () => widget.onChanged(d),
                      child: SizedBox(
                        width: _pillW,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: MuType.caption.copyWith(
                                color: selected ? ink : (soldOut ? ink : c.textSecondary),
                              ),
                            ),
                            Text(
                              '${d.day}',
                              style: MuType.numM.copyWith(
                                color: ink,
                                decoration: soldOut ? TextDecoration.lineThrough : null,
                                decorationColor: ink,
                              ),
                            ),
                            const SizedBox(height: MuSpace.s1 / 2),
                            Container(
                              width: _pip,
                              height: _pip,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: soldOut ? null : (selected ? c.onAccent : c.success),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
