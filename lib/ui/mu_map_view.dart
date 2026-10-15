import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'mu_sport_icon.dart';

/// A geographic point.
@immutable
class MuLatLng {
  const MuLatLng(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// A venue pin on the map.
@immutable
class MuMapVenue {
  const MuMapVenue({
    required this.id,
    required this.name,
    required this.sport,
    required this.position,
    this.area,
  });

  final String id;
  final String name;
  final MuSport sport;
  final MuLatLng position;
  final String? area;
}

/// MapView (components/MapView.md), static mode: venues on MatchUp's muted map — sport-coloured
/// pins with the sport glyph and your position — drawn from the `map-*` tokens, no pan or zoom.
///
/// The interactive map (Explorer « Carte », on Google Maps / Mapbox with a style generated from the
/// same tokens, clusters, mini card, controls) comes with the Explorer milestone.
class MuMapView extends StatefulWidget {
  const MuMapView({
    super.key,
    required this.center,
    this.venues = const [],
    this.user,
    this.zoom = 1,
    this.label,
    this.district,
    this.street,
  });

  final MuLatLng center;
  final List<MuMapVenue> venues;
  final MuLatLng? user;

  /// 0,6–2,4 as in the spec; 1 shows about 0,07° of longitude across 360 px.
  final double zoom;

  /// Accessible name (« Terrains autour de La Marsa »).
  final String? label;

  /// District label (`overline`, « LA MARSA ») and street label (`caption`, from zoom 0,8).
  final String? district;
  final String? street;

  /// The static map's projection: pixels per degree at zoom 1 (to move a pin by dragging).
  static const double pixelsPerDegree = 5000;

  @override
  State<MuMapView> createState() => _MuMapViewState();
}

class _MuMapViewState extends State<MuMapView> with SingleTickerProviderStateMixin {
  // MapView.md: user halo pulses every 1,5 × duration-pulse.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: MuMotion.pulse * 1.5,
  );

  // Projection: pixels per degree at zoom 1.
  static const double _pxPerDegree = MuMapView.pixelsPerDegree;
  // MapView.md: pin 36 with a 2 px white ring, icon 18; you: 16 dot, 3 px ring, 56 halo at 16 %.
  static const double _pin = 36;
  static const double _pinIcon = 18;
  static const double _pinRing = 2;
  static const double _you = 16;
  static const double _youRing = 3;
  static const double _halo = 56;
  static const double _haloAlpha = 0.16;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Offset _project(MuLatLng p, Size size) {
    final k = _pxPerDegree * widget.zoom;
    return Offset(
      size.width / 2 + (p.lng - widget.center.lng) * k,
      size.height / 2 - (p.lat - widget.center.lat) * k,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      image: true,
      label: widget.label,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: MuRadius.mdAll,
        child: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.biggest;
          return Directionality(
            // Maps never mirror in RTL.
            textDirection: TextDirection.ltr,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPainter(
                      c,
                      district: widget.district,
                      street: widget.zoom >= 0.8 ? widget.street : null,
                    ),
                  ),
                ),
                if (widget.user != null) _youMarker(c, _project(widget.user!, size)),
                for (final v in widget.venues) _pinMarker(c, v, _project(v.position, size)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _youMarker(MuColors c, Offset at) {
    return Positioned(
      left: at.dx - _halo / 2,
      top: at.dy - _halo / 2,
      width: _halo,
      height: _halo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Transform.scale(
              scale: 0.6 + 0.4 * _pulse.value,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.info.withValues(alpha: _haloAlpha * (1.6 - 0.6 * _pulse.value)),
                ),
              ),
            ),
          ),
          Container(
            width: _you + _youRing * 2,
            height: _you + _youRing * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.info,
              border: Border.all(color: MuPalette.white, width: _youRing),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinMarker(MuColors c, MuMapVenue v, Offset at) {
    const outer = _pin + _pinRing * 2;
    return Positioned(
      left: at.dx - outer / 2,
      top: at.dy - outer / 2,
      child: Container(
        width: outer,
        height: outer,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: v.sport.color(c),
          border: Border.all(color: MuPalette.white, width: _pinRing),
          boxShadow: MuElevation.of(context).level2,
        ),
        child: MuSportIcon(v.sport, size: _pinIcon, color: MuPalette.ink900),
      ),
    );
  }
}

/// The muted base map: land, a coastline, a park, cased main roads and labels. A drawing, not
/// real geography — it stands in for the tiled map in static previews.
class _MapPainter extends CustomPainter {
  _MapPainter(this.c, {this.district, this.street});

  final MuColors c;
  final String? district;
  final String? street;

  static const double _mainRoad = 10;
  static const double _road = 5;
  static const double _casing = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = c.mapLand);

    // Sea along the north-east, a park in the south-east.
    final sea = Path()
      ..moveTo(w * 0.72, 0)
      ..cubicTo(w * 0.8, h * 0.25, w * 0.86, h * 0.4, w, h * 0.42)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(sea, Paint()..color = c.mapWater);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.7, h * 0.72, w * 0.16, h * 0.3),
      Paint()..color = c.mapPark,
    );

    // Streets: a loose grid, then two cased main roads.
    final streetPaint = Paint()
      ..color = c.mapRoad
      ..strokeWidth = _road;
    for (final f in [0.18, 0.38, 0.58]) {
      canvas.drawLine(Offset(0, h * f + h * 0.2), Offset(w * 0.68, h * f), streetPaint);
    }
    for (final f in [0.12, 0.3, 0.5, 0.62]) {
      canvas.drawLine(Offset(w * f, h), Offset(w * f + w * 0.08, 0), streetPaint);
    }
    void mainRoad(Path p) {
      canvas.drawPath(
        p,
        Paint()
          ..color = c.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = _mainRoad + _casing * 2,
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = c.mapRoad
          ..style = PaintingStyle.stroke
          ..strokeWidth = _mainRoad,
      );
    }

    mainRoad(Path()
      ..moveTo(w * 0.2, h)
      ..quadraticBezierTo(w * 0.55, h * 0.55, w * 0.78, 0));
    mainRoad(Path()
      ..moveTo(w * 0.62, h * 0.38)
      ..quadraticBezierTo(w * 0.78, h * 0.6, w * 0.86, h));

    _label(canvas, district?.toUpperCase(), MuType.overline, Offset(w * 0.72, h * 0.02));
    if (street != null) {
      canvas.save();
      canvas.translate(w * 0.56, h * 0.82);
      canvas.rotate(-0.85);
      _label(canvas, street!, MuType.caption, Offset.zero);
      canvas.restore();
    }
  }

  void _label(Canvas canvas, String? text, TextStyle style, Offset at) {
    if (text == null) return;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: c.mapLabel)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
    tp.dispose();
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.c != c || old.district != district || old.street != street;
}
