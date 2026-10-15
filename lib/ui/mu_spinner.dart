import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Spinner (components/Spinner.md): a 25 % track and a 90° arc that rotates. Holds still under
/// reduced motion. Colour comes from [color] or the ambient `IconTheme`.
class MuSpinner extends StatefulWidget {
  const MuSpinner({super.key, this.size = 20, this.color, this.semanticLabel});

  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  State<MuSpinner> createState() => _MuSpinnerState();
}

class _MuSpinnerState extends State<MuSpinner>
    with SingleTickerProviderStateMixin {
  // Spinner.md: one turn every 800 ms, linear.
  static const _turn = Duration(milliseconds: 800);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _turn);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
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
    final color = widget.color ?? IconTheme.of(context).color!;
    Widget spinner = RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _SpinnerPainter(color),
      ),
    );
    if (widget.semanticLabel != null) {
      spinner = Semantics(
        liveRegion: true,
        label: widget.semanticLabel,
        child: spinner,
      );
    }
    return spinner;
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.color);

  final Color color;

  // Spinner.md: stroke = size × 2.5 / 24, track at 25 %.
  static const _strokeRatio = 2.5 / 24;
  static const _trackAlpha = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * _strokeRatio;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false,
        paint..color = color.withValues(alpha: _trackAlpha));
    canvas.drawArc(rect, -math.pi / 2, math.pi / 2, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.color != color;
}
