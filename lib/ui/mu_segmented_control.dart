import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';

enum MuSegmentedSize { m, s }

/// One option of a [MuSegmentedControl].
@immutable
class MuSegment<T> {
  const MuSegment({
    required this.value,
    required this.label,
    this.icon,
    this.selectedIcon,
    this.badge,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// One short fact about the option (« 2 mois offerts » on « Annuel »).
  final String? badge;

  /// Fill-weight icon for the selected state.
  final IconData? selectedIcon;
}

/// SegmentedControl (components/SegmentedControl.md): 2–4 exclusive options in one track with a
/// Volt thumb that slides to the selected one. [expand] shares the width equally (use it on
/// mobile). The choice applies at once.
class MuSegmentedControl<T> extends StatelessWidget {
  const MuSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.size = MuSegmentedSize.m,
    this.expand = false,
  }) : assert(segments.length >= 2 && segments.length <= 4);

  final List<MuSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final String semanticLabel;
  final MuSegmentedSize size;
  final bool expand;

  // SegmentedControl.md: badge min-width 18, padding-inline 5.
  static const double _badgeMin = 18;
  static const double _badgePad = 5;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final small = size == MuSegmentedSize.s;
    final trackH = small ? MuSize.controlS : MuSize.controlM;
    final segH = trackH - MuSpace.s1 * 2;
    final index = segments.indexWhere((s) => s.value == value).clamp(0, segments.length - 1);
    final duration = MuMotion.durationOf(context, MuMotion.base);

    Widget segment(int i) {
      final s = segments[i];
      final selected = i == index;
      final fg = selected ? c.onAccent : c.textSecondary;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        selected: selected,
        button: true,
        child: MuFocusRing(
          borderRadius: MuRadius.smAll,
          child: InkWell(
            onTap: () => onChanged(s.value),
            borderRadius: MuRadius.smAll,
            child: Container(
              height: segH,
              padding: EdgeInsets.symmetric(horizontal: small ? MuSpace.s3 : MuSpace.s4),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s.icon != null) ...[
                    Icon(selected ? (s.selectedIcon ?? s.icon) : s.icon,
                        size: small ? MuSize.iconXs : MuSize.iconS, color: fg),
                    const SizedBox(width: MuSpace.s2),
                  ],
                  Text(s.label, style: MuType.label.copyWith(color: fg)),
                  if (s.badge != null) ...[
                    const SizedBox(width: MuSpace.s2),
                    Container(
                      constraints: const BoxConstraints(minWidth: _badgeMin),
                      padding: const EdgeInsets.symmetric(horizontal: _badgePad),
                      decoration: BoxDecoration(
                        color: selected ? c.onAccent : c.surface,
                        borderRadius: MuRadius.fullAll,
                        border: selected ? null : Border.all(color: c.border),
                      ),
                      child: Text(
                        s.badge!,
                        textAlign: TextAlign.center,
                        style: MuType.labelS.copyWith(color: selected ? c.accent : c.text),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final Widget content;
    if (expand) {
      content = Stack(
        children: [
          AnimatedAlign(
            duration: duration,
            curve: MuMotion.move,
            alignment: AlignmentDirectional(
              segments.length == 1 ? 0 : -1 + 2 * index / (segments.length - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / segments.length,
              child: _Thumb(height: segH),
            ),
          ),
          Row(children: [for (var i = 0; i < segments.length; i++) Expanded(child: segment(i))]),
        ],
      );
    } else {
      content = _HuggingSegments(
        index: index,
        duration: duration,
        thumbHeight: segH,
        children: [for (var i = 0; i < segments.length; i++) segment(i)],
      );
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        height: trackH,
        padding: const EdgeInsets.all(MuSpace.s1),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: MuRadius.mdAll,
          border: Border.all(color: c.border),
        ),
        child: Material(type: MaterialType.transparency, child: content),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: MuRadius.smAll,
        boxShadow: MuElevation.of(context).level1,
      ),
    );
  }
}

/// Segments that hug their labels; the thumb is measured after layout and slides between them.
class _HuggingSegments extends StatefulWidget {
  const _HuggingSegments({
    required this.index,
    required this.duration,
    required this.thumbHeight,
    required this.children,
  });

  final int index;
  final Duration duration;
  final double thumbHeight;
  final List<Widget> children;

  @override
  State<_HuggingSegments> createState() => _HuggingSegmentsState();
}

class _HuggingSegmentsState extends State<_HuggingSegments> {
  late List<GlobalKey> _keys = [for (final _ in widget.children) GlobalKey()];
  Rect? _thumb;

  @override
  void didUpdateWidget(_HuggingSegments old) {
    super.didUpdateWidget(old);
    if (old.children.length != widget.children.length) {
      _keys = [for (final _ in widget.children) GlobalKey()];
    }
    _measure();
  }

  @override
  void initState() {
    super.initState();
    _measure();
  }

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final row = context.findRenderObject() as RenderBox?;
      final seg = _keys[widget.index].currentContext?.findRenderObject() as RenderBox?;
      if (row == null || seg == null) return;
      final offset = seg.localToGlobal(Offset.zero, ancestor: row);
      final rect = offset & seg.size;
      if (rect != _thumb) setState(() => _thumb = rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_thumb != null)
          AnimatedPositioned(
            duration: widget.duration,
            curve: MuMotion.move,
            left: _thumb!.left,
            top: 0,
            width: _thumb!.width,
            child: _Thumb(height: widget.thumbHeight),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              KeyedSubtree(key: _keys[i], child: widget.children[i]),
          ],
        ),
      ],
    );
  }
}
