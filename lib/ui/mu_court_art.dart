import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum MuCourtArtVariant { photo, poster, pattern }

/// CourtArt (components/CourtArt.md): the art-directed stand-in for photography.
///
/// - `photo` (400 × 240 canvas, cover-cropped): night sky, two floodlights with beams and glow,
///   the court in perspective in the sport colour with `court-line` markings (padel adds glass
///   walls and the net, basketball the hoop) on a `night-800` ground. Fixed in both themes.
/// - `poster` (300 × 400 canvas, cover-cropped): the sport ground, bold court circles and lines at
///   55 %, a Volt ball with an ink seam top-right and an ink fade over the bottom 37 %. Fixed in
///   both themes, like a photo.
/// - `pattern` (120 × 120): `<sport>-soft` ground with the court outline in `<sport>-text` at 55 %;
///   follows the theme.
///
/// [child] is laid over the art. The art is never mirrored in RTL.
class MuCourtArt extends StatelessWidget {
  const MuCourtArt({
    super.key,
    this.sport = MuSport.football,
    this.variant = MuCourtArtVariant.photo,
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
      MuCourtArtVariant.photo => _PhotoPainter(sport),
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

  Color get _ground => _sportHue(sport);

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

Color _sportHue(MuSport sport) => switch (sport) {
      MuSport.football => MuPalette.football,
      MuSport.padel => MuPalette.padel,
      MuSport.basketball => MuPalette.basketball,
    };

class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.sport);

  final MuSport sport;

  // CourtArt.md: photo canvas 400 × 240. Art-direction values of the drawing below.
  static const _canvas = Size(400, 240);
  static const double _horizon = 0.36;
  static const double _beamAlpha = 0.16;
  static const double _glowAlpha = 0.55;
  static const double _lineAlpha = 0.85;
  static const double _glassAlpha = 0.14;
  static const double _boardAlpha = 0.85;
  static const double _shade = 0.3;
  static const double _glow = 18;

  /// Court corners in canvas units: the far edge, then the near edge (below the frame).
  static const _farLeft = Offset(120, 92);
  static const _farRight = Offset(280, 92);
  static const _nearLeft = Offset(-40, 272);
  static const _nearRight = Offset(440, 272);

  /// A point of the court plane (u across, v from far to near) in canvas units.
  Offset _at(double u, double v) {
    final left = Offset.lerp(_farLeft, _nearLeft, v)!;
    final right = Offset.lerp(_farRight, _nearRight, v)!;
    return Offset.lerp(left, right, u)!;
  }

  Path _poly(List<Offset> pts, {bool close = false}) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    if (close) p.close();
    return p;
  }

  Path _line(double u1, double v1, double u2, double v2) => _poly([_at(u1, v1), _at(u2, v2)]);

  Path _rect(double u1, double v1, double u2, double v2) =>
      _poly([_at(u1, v1), _at(u2, v1), _at(u2, v2), _at(u1, v2)], close: true);

  /// An ellipse on the court plane, sampled as a polygon so it follows the perspective.
  Path _circle(double cu, double cv, double ru, double rv) => _poly([
        for (var i = 0; i <= 48; i++)
          _at(cu + ru * math.cos(i / 48 * 2 * math.pi), cv + rv * math.sin(i / 48 * 2 * math.pi)),
      ], close: true);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _cover(canvas, size, _canvas);
    final w = _canvas.width;
    final h = _canvas.height;
    final hue = _sportHue(sport);

    // Sky and ground.
    final sky = Rect.fromLTWH(0, 0, w, h * _horizon);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MuPalette.night900, MuPalette.ink900],
        ).createShader(sky),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * _horizon, w, h * (1 - _horizon)),
      Paint()..color = MuPalette.night800,
    );

    // Court surface, darker towards the far end.
    final court = _poly([_farLeft, _farRight, _nearRight, _nearLeft], close: true);
    canvas.drawPath(
      court,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(hue, MuPalette.ink900, _shade)!, hue],
        ).createShader(Rect.fromLTWH(0, _farLeft.dy, w, h - _farLeft.dy)),
    );

    final line = Paint()
      ..color = MuColors.light.courtLine.withValues(alpha: _lineAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_rect(0.04, 0.04, 0.96, 1.2), line);

    switch (sport) {
      case MuSport.football:
        canvas.drawPath(_line(0.04, 0.52, 0.96, 0.52), line);
        canvas.drawPath(_circle(0.5, 0.52, 0.14, 0.16), line);
        canvas.drawPath(_rect(0.3, 0.04, 0.7, 0.2), line);
      case MuSport.padel:
        canvas.drawPath(_line(0.5, 0.18, 0.5, 0.86), line);
        canvas.drawPath(_line(0.04, 0.18, 0.96, 0.18), line);
        canvas.drawPath(_line(0.04, 0.86, 0.96, 0.86), line);
        // The net across the middle, then the glass walls at the back and on the sides.
        canvas.drawPath(
          _line(0, 0.5, 1, 0.5),
          Paint()
            ..color = MuPalette.ink900
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        canvas.drawPath(_line(0, 0.5, 1, 0.5), line);
        final glass = Paint()..color = MuPalette.white.withValues(alpha: _glassAlpha);
        canvas.drawRect(
          Rect.fromLTRB(_farLeft.dx, _farLeft.dy - 34, _farRight.dx, _farLeft.dy),
          glass,
        );
        canvas.drawPath(
          _poly(
            [_farLeft.translate(0, -34), _farLeft, _nearLeft, _nearLeft.translate(0, -60)],
            close: true,
          ),
          glass,
        );
        canvas.drawPath(
          _poly(
            [_farRight.translate(0, -34), _farRight, _nearRight, _nearRight.translate(0, -60)],
            close: true,
          ),
          glass,
        );
      case MuSport.basketball:
        canvas.drawPath(_rect(0.38, 0.04, 0.62, 0.36), line);
        canvas.drawPath(_circle(0.5, 0.36, 0.12, 0.1), line);
        canvas.drawPath(_circle(0.5, 0.04, 0.42, 0.62), line);
        // Backboard and hoop above the far key.
        canvas.drawRect(
          Rect.fromCenter(center: Offset(w / 2, _farLeft.dy - 22), width: 34, height: 20),
          Paint()..color = MuPalette.white.withValues(alpha: _boardAlpha),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w / 2, _farLeft.dy - 8), width: 16, height: 5),
          Paint()
            ..color = MuPalette.basketball
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }

    // Two floodlights: beams onto the court, glow around the lamps.
    for (final x in [w * 0.1, w * 0.9]) {
      final lamp = Offset(x, h * 0.06);
      final target = x < w / 2 ? _at(0.3, 0.6) : _at(0.7, 0.6);
      final beam = Path()
        ..moveTo(lamp.dx - 6, lamp.dy)
        ..lineTo(lamp.dx + 6, lamp.dy)
        ..lineTo(target.dx + 70, target.dy)
        ..lineTo(target.dx - 70, target.dy)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MuPalette.white.withValues(alpha: _beamAlpha),
              MuPalette.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromPoints(lamp, target)),
      );
      canvas.drawLine(
        Offset(x, lamp.dy),
        Offset(x, h * _horizon),
        Paint()
          ..color = MuPalette.ink700
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        lamp,
        _glow,
        Paint()
          ..shader = RadialGradient(colors: [
            MuPalette.white.withValues(alpha: _glowAlpha),
            MuPalette.white.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: lamp, radius: _glow)),
      );
      canvas.drawRect(
        Rect.fromCenter(center: lamp, width: 12, height: 5),
        Paint()..color = MuPalette.white,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PhotoPainter old) => old.sport != sport;
}
