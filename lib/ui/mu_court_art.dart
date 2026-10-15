import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum MuCourtArtVariant { poster, pattern }

/// CourtArt (components/CourtArt.md): the art-directed stand-in for photography.
///
/// - `poster` (300 × 400 canvas, cover-cropped): the sport ground, bold court circles and lines at
///   55 %, a Volt ball with an ink seam top-right and an ink fade over the bottom 37 %. Fixed in
///   both themes, like a photo.
/// - `pattern` (120 × 120): `<sport>-soft` ground with the court outline in `<sport>-text` at 55 %;
///   follows the theme.
///
/// The `photo` variant (floodlit court in perspective) comes with the player onboarding (PLY-01).
/// [child] is laid over the art. The art is never mirrored in RTL.
class MuCourtArt extends StatelessWidget {
  const MuCourtArt({
    super.key,
    this.sport = MuSport.football,
    this.variant = MuCourtArtVariant.poster,
    this.semanticLabel,
    this.child,
  });

  final MuSport sport;
  final MuCourtArtVariant variant;

  /// Only when the image adds information; decorative otherwise.
  final String? semanticLabel;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final painter = switch (variant) {
      MuCourtArtVariant.poster => _PosterPainter(sport),
      MuCourtArtVariant.pattern => _PatternPainter(
          sport,
          ground: sport.soft(c),
          line: sport.text(c),
        ),
    };
    Widget art = Directionality(
      textDirection: TextDirection.ltr,
      child: CustomPaint(painter: painter, child: const SizedBox.expand()),
    );
    art = semanticLabel == null
        ? ExcludeSemantics(child: art)
        : Semantics(image: true, label: semanticLabel, child: art);
    if (child == null) return ClipRect(child: art);
    return ClipRect(
      child: Stack(fit: StackFit.expand, children: [art, child!]),
    );
  }
}

/// Scales a fixed canvas to cover [size], centred (BoxFit.cover maths).
void _cover(Canvas canvas, Size size, Size canvasSize) {
  final scale = math.max(size.width / canvasSize.width, size.height / canvasSize.height);
  canvas.translate(
    (size.width - canvasSize.width * scale) / 2,
    (size.height - canvasSize.height * scale) / 2,
  );
  canvas.scale(scale);
}

class _PosterPainter extends CustomPainter {
  _PosterPainter(this.sport);

  final MuSport sport;

  // CourtArt.md: poster canvas 300 × 400; lines at 55 %; ink fade 0 → 85 % over the bottom 37 %.
  static const _canvas = Size(300, 400);
  static const double _lineAlpha = 0.55;
  static const double _fadeStart = 0.63;
  static const double _fadeAlpha = 0.85;
  static const double _stroke = 6;
  // The ground darkens towards the bottom: the sport hue mixed with ink.
  static const double _groundShade = 0.35;

  Color get _ground => switch (sport) {
        MuSport.football => MuPalette.football,
        MuSport.padel => MuPalette.padel,
        MuSport.basketball => MuPalette.basketball,
      };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _cover(canvas, size, _canvas);
    final w = _canvas.width;
    final h = _canvas.height;
    final rect = Offset.zero & _canvas;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_ground, Color.lerp(_ground, MuPalette.ink900, _groundShade)!],
        ).createShader(rect),
    );

    final line = Paint()
      ..color = MuColors.light.courtLine.withValues(alpha: _lineAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    switch (sport) {
      case MuSport.football:
        // Penalty and goal boxes at the top, halfway line, centre circle and spot.
        canvas.drawRect(Rect.fromLTRB(w * 0.22, -_stroke, w * 0.78, h * 0.16), line);
        canvas.drawRect(Rect.fromLTRB(w * 0.38, -_stroke, w * 0.62, h * 0.06), line);
        canvas.drawLine(Offset(0, h * 0.62), Offset(w, h * 0.62), line);
        canvas.drawCircle(Offset(w / 2, h * 0.62), w * 0.4, line);
        canvas.drawCircle(Offset(w / 2, h * 0.62), w * 0.22, line);
      case MuSport.padel:
        // Glass-wall posts, service line, centre line, net, and the court circle.
        canvas.drawLine(Offset(w * 0.08, 0), Offset(w * 0.08, h), line);
        canvas.drawLine(Offset(w * 0.92, 0), Offset(w * 0.92, h), line);
        canvas.drawLine(Offset(w * 0.08, h * 0.3), Offset(w * 0.92, h * 0.3), line);
        canvas.drawLine(Offset(w / 2, h * 0.3), Offset(w / 2, h * 0.62), line);
        canvas.drawLine(Offset(0, h * 0.62), Offset(w, h * 0.62), line);
        canvas.drawCircle(Offset(w / 2, h * 0.62), w * 0.38, line);
      case MuSport.basketball:
        // Sidelines, the key and free-throw circle, half-court line and centre circle.
        canvas.drawLine(Offset(w * 0.06, 0), Offset(w * 0.06, h), line);
        canvas.drawLine(Offset(w * 0.94, 0), Offset(w * 0.94, h), line);
        canvas.drawRect(Rect.fromLTRB(w * 0.34, -_stroke, w * 0.66, h * 0.2), line);
        canvas.drawCircle(Offset(w / 2, h * 0.2), w * 0.16, line);
        canvas.drawLine(Offset(0, h * 0.64), Offset(w, h * 0.64), line);
        canvas.drawCircle(Offset(w / 2, h * 0.64), w * 0.36, line);
    }

    _ball(canvas, Offset(w * 0.77, h * 0.22), w * 0.115);

    final fade = Rect.fromLTRB(0, h * _fadeStart, w, h);
    canvas.drawRect(
      fade,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MuPalette.ink900.withValues(alpha: 0),
            MuPalette.ink900.withValues(alpha: _fadeAlpha),
          ],
        ).createShader(fade),
    );
    canvas.restore();
  }

  /// The Volt ball with its ink seam (the logo's ball).
  void _ball(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r, Paint()..color = MuPalette.volt400);
    final seam = Paint()
      ..color = MuPalette.ink900
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.14;
    final left = Path()
      ..moveTo(center.dx - r * 0.7, center.dy - r * 0.62)
      ..quadraticBezierTo(center.dx - r * 0.05, center.dy - r * 0.2,
          center.dx - r * 0.18, center.dy + r * 0.82);
    final right = Path()
      ..moveTo(center.dx + r * 0.7, center.dy - r * 0.62)
      ..quadraticBezierTo(center.dx + r * 0.05, center.dy - r * 0.2,
          center.dx + r * 0.18, center.dy + r * 0.82);
    canvas
      ..drawPath(left, seam)
      ..drawPath(right, seam);
  }

  @override
  bool shouldRepaint(_PosterPainter old) => old.sport != sport;
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.sport, {required this.ground, required this.line});

  final MuSport sport;
  final Color ground;
  final Color line;

  // CourtArt.md: pattern canvas 120 × 120, outline at 55 %.
  static const _canvas = Size(120, 120);
  static const double _lineAlpha = 0.55;
  static const double _stroke = 3;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    canvas.save();
    _cover(canvas, size, _canvas);
    final p = Paint()
      ..color = line.withValues(alpha: _lineAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    const court = Rect.fromLTRB(16, 16, 104, 104);
    canvas.drawRect(court, p);
    canvas.drawLine(Offset(16, court.center.dy), Offset(104, court.center.dy), p);
    switch (sport) {
      case MuSport.football:
        canvas.drawCircle(court.center, 16, p);
      case MuSport.padel:
        canvas.drawLine(const Offset(60, 36), const Offset(60, 84), p);
        canvas.drawLine(const Offset(16, 36), const Offset(104, 36), p);
        canvas.drawLine(const Offset(16, 84), const Offset(104, 84), p);
      case MuSport.basketball:
        canvas.drawCircle(court.center, 14, p);
        canvas.drawRect(const Rect.fromLTRB(46, 16, 74, 38), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.sport != sport || old.ground != ground || old.line != line;
}
