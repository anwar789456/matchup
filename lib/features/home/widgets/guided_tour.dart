import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// One step of the guided tour.
class TourStep {
  const TourStep({
    required this.target,
    required this.title,
    required this.body,
    required this.header,
    this.radius = MuRadius.lg,
    this.padding = MuSpace.s2,
  });

  /// The widget the spotlight frames.
  final GlobalKey target;
  final String title;
  final String body;

  /// The bubble's top-start label: the « IA » mark or an overline.
  final Widget header;
  final double radius;

  /// Space between the target and the spotlight edge.
  final double padding;
}

/// PLY-11 guided tour: a scrim with a spotlight on the step's target (2 px white ring) and a bubble
/// with an arrow, « n/3 », « Passer la visite » and « Suivant » / « C’est parti ».
class GuidedTour extends StatefulWidget {
  const GuidedTour({super.key, required this.steps, required this.onDone});

  final List<TourStep> steps;
  final VoidCallback onDone;

  @override
  State<GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends State<GuidedTour> {
  int _index = 0;
  Rect? _hole;

  // PLY-11: 2 px white ring; 12 px arrow; the bubble sits 16 from the screen edges and 18 from the
  // spotlight.
  static const double _ring = 2;
  static const double _arrow = 12;
  static const double _gap = 18;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final step = widget.steps[_index];
      final target = step.target.currentContext?.findRenderObject() as RenderBox?;
      final me = context.findRenderObject() as RenderBox?;
      if (target == null || me == null || !target.attached) return;
      final topLeft = target.localToGlobal(Offset.zero, ancestor: me);
      setState(() => _hole = (topLeft & target.size).inflate(step.padding));
    });
  }

  void _next() {
    if (_index == widget.steps.length - 1) {
      widget.onDone();
      return;
    }
    setState(() => _index++);
    _measure();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final hole = _hole;
    final step = widget.steps[_index];
    final duration = MuMotion.durationOf(context, MuMotion.slow);
    final size = MediaQuery.sizeOf(context);
    final last = _index == widget.steps.length - 1;

    return Stack(
      children: [
        // Blocks the page while the tour runs.
        Positioned.fill(
          child: TweenAnimationBuilder<Rect?>(
            tween: RectTween(end: hole ?? Rect.fromCenter(center: size.center(Offset.zero), width: 0, height: 0)),
            duration: duration,
            curve: MuMotion.move,
            builder: (context, rect, _) => CustomPaint(
              painter: _SpotlightPainter(
                hole: rect,
                radius: step.radius,
                scrim: c.scrim,
                ring: MuPalette.white,
                ringWidth: _ring,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        if (hole != null) _bubble(context, hole, step, last),
      ],
    );
  }

  Widget _bubble(BuildContext context, Rect hole, TourStep step, bool last) {
    final c = context.mu;
    final size = MediaQuery.sizeOf(context);
    // Below the spotlight when there is room, else above it.
    final below = hole.center.dy < size.height / 2;
    final double arrowX = (hole.center.dx - MuSpace.s4 - _arrow / 2)
        .clamp(MuSpace.s4, math.max(MuSpace.s4, size.width - MuSpace.s4 * 3 - _arrow))
        .toDouble();

    final bubble = Material(
      color: c.surfaceElevated,
      borderRadius: MuRadius.mdAll,
      elevation: MuElevation.materialLevel3,
      shadowColor: MuElevation.of(context).shadowColor,
      child: Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                step.header,
                const Spacer(),
                Semantics(
                  label: 'Étape ${_index + 1} sur ${widget.steps.length}',
                  excludeSemantics: true,
                  child: Text('${_index + 1}/${widget.steps.length}',
                      style: MuType.numXs.copyWith(color: c.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            Semantics(
              header: true,
              child: Text(step.title, style: MuType.labelL.copyWith(color: c.text)),
            ),
            const SizedBox(height: MuSpace.s2),
            Text(step.body, style: MuType.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: MuSpace.s3),
            Row(
              children: [
                if (!last)
                  Transform.translate(
                    offset: const Offset(-MuSpace.s3, 0),
                    child: MuButton.tertiary(label: 'Passer la visite', onPressed: widget.onDone),
                  ),
                const Spacer(),
                MuButton.primary(label: last ? 'C’est parti' : 'Suivant', onPressed: _next),
              ],
            ),
          ],
        ),
      ),
    );

    final arrow = Transform.rotate(
      angle: math.pi / 4,
      child: Container(width: _arrow, height: _arrow, color: c.surfaceElevated),
    );

    final animated = TweenAnimationBuilder<double>(
      key: ValueKey(_index),
      tween: Tween(begin: 0, end: 1),
      duration: MuMotion.durationOf(context, MuMotion.base),
      curve: MuMotion.enter,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 6), child: child),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          Positioned(
            left: arrowX,
            top: below ? -_arrow / 2 : null,
            bottom: below ? null : -_arrow / 2,
            child: arrow,
          ),
        ],
      ),
    );

    return Positioned(
      left: MuSpace.s4,
      right: MuSpace.s4,
      top: below ? hole.bottom + _gap : null,
      bottom: below ? null : size.height - hole.top + _gap,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: step.title,
        child: animated,
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.scrim,
    required this.ring,
    required this.ringWidth,
  });

  final Rect? hole;
  final double radius;
  final Color scrim;
  final Color ring;
  final double ringWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    if (hole == null) {
      canvas.drawPath(screen, Paint()..color = scrim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole!, Radius.circular(radius));
    canvas.drawPath(
      Path.combine(PathOperation.difference, screen, Path()..addRRect(rrect)),
      Paint()..color = scrim,
    );
    canvas.drawRRect(
      rrect.inflate(ringWidth / 2),
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.radius != radius || old.scrim != scrim;
}
