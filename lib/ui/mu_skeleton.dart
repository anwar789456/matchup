import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum MuSkeletonShape { rect, text, circle, pill }

/// Skeleton (components/Skeleton.md): a placeholder block shaped like the content it replaces.
///
/// `rect` is `width` × `height` at `radius-sm` (or [radius]); `text` is 12 high, [lines] stacked
/// `space-2` apart, the last at 62 %; `circle` and `pill` are fully rounded. Blocks are plain fills
/// in `skeleton`; inside a [MuSkeletonGroup] they shimmer.
class MuSkeleton extends StatelessWidget {
  const MuSkeleton({
    super.key,
    this.shape = MuSkeletonShape.rect,
    this.width,
    this.height,
    this.lines = 1,
    this.radius,
  });

  /// Text lines, [width] wide (the parent's width by default).
  const MuSkeleton.text({super.key, this.width, this.lines = 1})
    : shape = MuSkeletonShape.text,
      height = null,
      radius = null;

  const MuSkeleton.circle({super.key, required double size})
    : shape = MuSkeletonShape.circle,
      width = size,
      height = size,
      lines = 1,
      radius = null;

  const MuSkeleton.pill({super.key, required this.width, this.height = MuSize.controlS})
    : shape = MuSkeletonShape.pill,
      lines = 1,
      radius = null;

  final MuSkeletonShape shape;
  final double? width;
  final double? height;
  final int lines;
  final BorderRadius? radius;

  // Skeleton.md: text lines 12 high, the last at 62 %.
  static const double textHeight = 12;
  static const double _lastLine = 0.62;

  // The highlight band is a third of a block wide.
  static const double _band = 0.33;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final sweep = _SkeletonSweep.of(context);
    Widget block(double? w, double? h, BorderRadius r) => SizedBox(
      width: w,
      height: h,
      child: sweep == null
          ? DecoratedBox(
              decoration: BoxDecoration(color: c.skeleton, borderRadius: r),
            )
          : AnimatedBuilder(
              animation: sweep,
              builder: (context, _) {
                final t = sweep.value;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    gradient: LinearGradient(
                      colors: [c.skeleton, c.skeletonHighlight, c.skeleton],
                      stops: [
                        (t - _band / 2).clamp(0.0, 1.0),
                        t.clamp(0.0, 1.0),
                        (t + _band / 2).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                );
              },
            ),
    );

    return ExcludeSemantics(
      child: switch (shape) {
        MuSkeletonShape.rect => block(width, height, radius ?? MuRadius.smAll),
        MuSkeletonShape.circle || MuSkeletonShape.pill => block(width, height, MuRadius.fullAll),
        MuSkeletonShape.text => LayoutBuilder(
          builder: (context, constraints) {
            final full =
                width ??
                (constraints.maxWidth.isFinite ? constraints.maxWidth : MuSize.controlXl * 2);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines; i++) ...[
                  if (i > 0) const SizedBox(height: MuSpace.s2),
                  block(
                    lines > 1 && i == lines - 1 ? full * _lastLine : full,
                    textHeight,
                    MuRadius.xsAll,
                  ),
                ],
              ],
            );
          },
        ),
      },
    );
  }
}

/// SkeletonGroup: wraps a loading region and announces [label] once (politely); every block inside
/// sweeps a `skeleton-highlight` band over `duration-shimmer`, in step, repeating. The sweep stops
/// under reduced motion; the blocks stay.
class MuSkeletonGroup extends StatefulWidget {
  const MuSkeletonGroup({super.key, this.label = 'Chargement…', required this.child});

  final String label;
  final Widget child;

  @override
  State<MuSkeletonGroup> createState() => _MuSkeletonGroupState();
}

class _MuSkeletonGroupState extends State<MuSkeletonGroup> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: MuMotion.shimmer);

  // The band starts before the start edge and leaves past the end edge.
  late final Animation<double> _sweep = _controller
      .drive(CurveTween(curve: MuMotion.move))
      .drive(Tween(begin: -MuSkeleton._band, end: 1 + MuSkeleton._band));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      label: widget.label,
      child: ExcludeSemantics(
        child: _SkeletonSweep(sweep: still ? null : _sweep, child: widget.child),
      ),
    );
  }
}

/// Shares the group's sweep with its blocks, so they shimmer in step.
class _SkeletonSweep extends InheritedWidget {
  const _SkeletonSweep({required this.sweep, required super.child});

  final Animation<double>? sweep;

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonSweep>()?.sweep;

  @override
  bool updateShouldNotify(_SkeletonSweep oldWidget) => sweep != oldWidget.sweep;
}
