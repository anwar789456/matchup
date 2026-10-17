import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';

/// One page-level tab: a short noun and an optional count.
@immutable
class MuTab {
  const MuTab(this.label, {this.count});

  final String label;
  final int? count;
}

enum MuTabsVariant { underline, pill }

/// Tabs (components/Tabs.md): underline tabs at page level (« À venir 3 · Passés · Annulés ») or
/// pill tabs inside a card. [fullWidth] shares the width equally; otherwise the row scrolls.
///
/// The indicator slides to the selected tab over `duration-base` on `ease-move`.
class MuTabs extends StatefulWidget {
  const MuTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    required this.label,
    this.variant = MuTabsVariant.underline,
    this.fullWidth = false,
  });

  final List<MuTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  /// The list's accessible name (« Mes matchs »).
  final String label;
  final MuTabsVariant variant;
  final bool fullWidth;

  // Tabs.md: underline 48 high, 2 px indicator with a 2 px top radius, gap space-6; pill 32 in a
  // space-1 track; count pill 18 min.
  static const double indicator = 2;
  static const double countMin = 18;
  static const double countPad = 5;
  static const int countMax = 999;

  @override
  State<MuTabs> createState() => _MuTabsState();
}

class _MuTabsState extends State<MuTabs> {
  late List<GlobalKey> _keys = [for (final _ in widget.tabs) GlobalKey()];

  List<MuTab> get tabs => widget.tabs;
  int get index => widget.index;
  ValueChanged<int> get onChanged => widget.onChanged;
  String get label => widget.label;
  MuTabsVariant get variant => widget.variant;
  bool get fullWidth => widget.fullWidth;

  @override
  void didUpdateWidget(MuTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _keys = [for (final _ in widget.tabs) GlobalKey()];
    }
  }

  @override
  Widget build(BuildContext context) =>
      variant == MuTabsVariant.pill ? _pill(context) : _underline(context);

  Widget _count(BuildContext context, int n, {required bool active, required bool onAccent}) {
    final c = context.mu;
    final text = n > MuTabs.countMax ? '$MuTabs.countMax+' : '$n';
    final (Color ground, Color ink) = onAccent
        ? active
              ? (c.onAccent, c.accent)
              : (c.surface, c.text)
        : active
        ? (c.surfaceInverse, c.textInverse)
        : (c.surfaceMuted, c.textSecondary);
    return Container(
      constraints: const BoxConstraints(minWidth: MuTabs.countMin, minHeight: MuTabs.countMin),
      padding: const EdgeInsets.symmetric(horizontal: MuTabs.countPad),
      decoration: BoxDecoration(color: ground, borderRadius: MuRadius.fullAll),
      alignment: Alignment.center,
      child: Text(text, style: MuType.labelS.copyWith(color: ink)),
    );
  }

  Widget _tab(BuildContext context, int i, {required bool pill}) {
    final c = context.mu;
    final t = tabs[i];
    final active = i == index;
    final ink = pill
        ? (active ? c.onAccent : c.textSecondary)
        : (active ? c.text : c.textSecondary);
    return Semantics(
      selected: active,
      button: true,
      inMutuallyExclusiveGroup: true,
      label: '${t.label}${t.count == null ? '' : ', ${t.count}'}',
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.smAll,
        child: InkWell(
          borderRadius: pill ? MuRadius.fullAll : MuRadius.smAll,
          onTap: () => onChanged(i),
          child: Container(
            height: pill ? MuSize.controlS : MuSize.controlL,
            padding: EdgeInsets.symmetric(horizontal: pill ? MuSpace.s4 : MuSpace.s1),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.label, style: MuType.label.copyWith(color: ink)),
                if (t.count != null) ...[
                  const SizedBox(width: MuSpace.s2),
                  _count(context, t.count!, active: active, onAccent: pill),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _underline(BuildContext context) {
    final c = context.mu;
    final duration = MuMotion.durationOf(context, MuMotion.base);
    final row = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0 && !fullWidth) const SizedBox(width: MuSpace.s6),
          fullWidth
              ? Expanded(child: _tab(context, i, pill: false))
              : _tab(context, i, pill: false),
        ],
      ],
    );
    final content = _Underlined(
      index: index,
      count: tabs.length,
      fullWidth: fullWidth,
      duration: duration,
      color: c.primary,
      thickness: MuTabs.indicator,
      keys: _keys,
      child: row,
    );
    return Semantics(
      container: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: fullWidth
            ? content
            : SingleChildScrollView(scrollDirection: Axis.horizontal, child: content),
      ),
    );
  }

  Widget _pill(BuildContext context) {
    final c = context.mu;
    final duration = MuMotion.durationOf(context, MuMotion.base);
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s1),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: MuRadius.fullAll,
          border: Border.all(color: c.border),
        ),
        child: Stack(
          children: [
            if (fullWidth)
              AnimatedAlign(
                duration: duration,
                curve: MuMotion.move,
                alignment: Alignment(tabs.length == 1 ? 0 : -1 + 2 * index / (tabs.length - 1), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / tabs.length,
                  child: Container(
                    height: MuSize.controlS,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: MuRadius.fullAll,
                      boxShadow: MuElevation.of(context).level1,
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  if (fullWidth)
                    Expanded(child: _tab(context, i, pill: true))
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: i == index ? c.accent : null,
                        borderRadius: MuRadius.fullAll,
                      ),
                      child: _tab(context, i, pill: true),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The underline indicator: content width under the active tab, sliding between tabs. Scrolling
/// tabs are measured from their keys after each frame.
class _Underlined extends StatefulWidget {
  const _Underlined({
    required this.index,
    required this.count,
    required this.fullWidth,
    required this.duration,
    required this.color,
    required this.thickness,
    required this.keys,
    required this.child,
  });

  final int index;
  final int count;
  final bool fullWidth;
  final Duration duration;
  final Color color;
  final double thickness;
  final List<GlobalKey> keys;
  final Widget child;

  @override
  State<_Underlined> createState() => _UnderlinedState();
}

class _UnderlinedState extends State<_Underlined> {
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_Underlined oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  void _schedule() {
    if (widget.fullWidth) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted || widget.index >= widget.keys.length) return;
    final box = widget.keys[widget.index].currentContext?.findRenderObject() as RenderBox?;
    final me = context.findRenderObject() as RenderBox?;
    if (box == null || me == null || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero, ancestor: me) & box.size;
    if (rect != _rect) setState(() => _rect = rect);
  }

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      height: widget.thickness,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final r = _rect;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (widget.fullWidth && width.isFinite)
              AnimatedPositionedDirectional(
                duration: widget.duration,
                curve: MuMotion.move,
                bottom: 0,
                start: width / widget.count * widget.index + MuSpace.s1,
                width: width / widget.count - MuSpace.s1 * 2,
                child: bar,
              )
            else if (r != null)
              AnimatedPositioned(
                duration: widget.duration,
                curve: MuMotion.move,
                bottom: 0,
                left: r.left + MuSpace.s1,
                width: r.width - MuSpace.s1 * 2,
                child: bar,
              ),
          ],
        );
      },
    );
  }
}
