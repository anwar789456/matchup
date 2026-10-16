import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/format.dart';
import '../../theme/theme.dart';
import '../mu_button.dart';
import '../mu_chip.dart';
import '../mu_court_art.dart';
import '../mu_icon_button.dart';
import '../mu_map_view.dart';
import '../mu_sport_icon.dart';

/// The interactive body of [MuMapView.explore] (MapView.md): muted tiles, pins, clusters, your
/// position, controls and the mini card.
class MuExploreMap extends StatefulWidget {
  const MuExploreMap({super.key, required this.map});

  final MuMapView map;

  @override
  State<MuExploreMap> createState() => _MuExploreMapState();
}

/// Pins drawn as one marker: a venue, or a cluster of venues too close to tell apart.
class _Group {
  _Group(this.at, this.venue);

  Offset at;
  final MuMapVenue venue;
  final members = <MuMapVenue>[];

  bool get isCluster => members.length > 1;
  LatLng get centre {
    final lat = members.map((v) => v.position.lat).reduce((a, b) => a + b) / members.length;
    final lng = members.map((v) => v.position.lng).reduce((a, b) => a + b) / members.length;
    return LatLng(lat, lng);
  }
}

class _MuExploreMapState extends State<MuExploreMap> with TickerProviderStateMixin {
  final _controller = MapController();
  late final AnimationController _fly = AnimationController(vsync: this, duration: MuMotion.slow);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: MuMotion.pulse * 1.5,
  );
  bool _moved = false;
  bool _ready = false;

  // MapView.md: pin 36 with a 2 px white ring, icon 18 (selected: × 1,22, icon 22, 3 px accent
  // ring); cluster 48 with a 4 px mix ring and a 34 count disc; you 16 with a 3 px ring and a 56
  // halo at 16 %; mini card 288 wide, 34 above the pin's centre, 12 px arrow; zoom 0,6–2,4 of the
  // design maps to web zoom 10–17, buttons × 1,25 (≈ +0,32), cluster tap × 1,6 (≈ +0,68).
  static const double _pin = 36;
  static const double _pinIcon = 18;
  static const double _pinRing = 2;
  static const double _selectedScale = 1.22;
  static const double _selectedIcon = 22;
  static const double _selectedRing = 3;
  static const double _cluster = 48;
  static const double _clusterRing = 4;
  static const double _clusterCount = 34;
  static const double _you = 16;
  static const double _youRing = 3;
  static const double _halo = 56;
  static const double _haloAlpha = 0.16;
  static const double _card = 288;
  static const double _cardLift = 34;
  static const double _arrow = 12;
  static const double _thumb = 56;
  static const double _minZoom = 10;
  static const double _maxZoom = 17;
  static const double _zoomStep = 0.32;
  static const double _clusterZoom = 0.68;
  static const double _clusterRadius = 48;
  static const double _controlsRoom = MuSpace.s3 * 2 + MuSize.touchTarget;

  static const _attribution = '© OpenStreetMap · © CARTO';
  static const _userAgent = 'tn.matchup.app';

  MuMapView get _map => widget.map;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _fly.dispose();
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  LatLng _ll(MuLatLng p) => LatLng(p.lat, p.lng);

  /// Flies the camera over `duration-slow` on `ease-move` (instantly under reduced motion).
  Future<void> _flyTo(LatLng to, double zoom) async {
    final camera = _controller.camera;
    final from = camera.center;
    final fromZoom = camera.zoom;
    final target = zoom.clamp(_minZoom, _maxZoom);
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.move(to, target);
      return;
    }
    final curve = CurvedAnimation(parent: _fly, curve: MuMotion.move);
    void tick() {
      final t = curve.value;
      _controller.move(
        LatLng(
          from.latitude + (to.latitude - from.latitude) * t,
          from.longitude + (to.longitude - from.longitude) * t,
        ),
        fromZoom + (target - fromZoom) * t,
      );
    }

    _fly.addListener(tick);
    await _fly.forward(from: 0);
    _fly.removeListener(tick);
    curve.dispose();
  }

  void _zoomBy(double delta) {
    final camera = _controller.camera;
    _flyTo(camera.center, camera.zoom + delta);
  }

  void _locate() {
    _map.onLocate?.call();
    final user = _map.user;
    if (user != null) _flyTo(_ll(user), math.max(_controller.camera.zoom, _map.zoom));
    setState(() => _moved = false);
  }

  // Selecting a pin pans it down to 68 % of the height, so the card fits above it.
  static const double _selectedY = 0.68;

  void _select(MuMapVenue? v) {
    _map.onSelect?.call(v?.id);
    if (v != null) _reveal(v);
  }

  void _reveal(MuMapVenue v) {
    final camera = _controller.camera;
    final pin = camera.latLngToScreenOffset(_ll(v.position));
    final h = camera.nonRotatedSize.height;
    _flyTo(
      camera.screenOffsetToLatLng(Offset(pin.dx, pin.dy - (_selectedY - 0.5) * h)),
      camera.zoom,
    );
  }

  /// Greedy clustering on screen: a pin closer than 48 px to a group joins it.
  List<_Group> _groups(MapCamera camera) {
    final groups = <_Group>[];
    for (final v in _map.venues) {
      final at = camera.latLngToScreenOffset(_ll(v.position));
      final near = groups.where((g) => (g.at - at).distance < _clusterRadius).firstOrNull;
      if (near != null && v.id != _map.selectedId && near.venue.id != _map.selectedId) {
        near.members.add(v);
        near.at = Offset.lerp(near.at, at, 1 / near.members.length)!;
      } else {
        groups.add(_Group(at, v)..members.add(v));
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selected = _map.venues.where((v) => v.id == _map.selectedId).firstOrNull;

    return Semantics(
      container: true,
      label: _map.label,
      child: Directionality(
        // The map, pins and labels never mirror in RTL.
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: c.mapLand,
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _ll(_map.center),
              initialZoom: _map.zoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              backgroundColor: c.mapLand,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                setState(() => _ready = true);
                // A pin selected before the map opened: bring its card into view.
                final selected = _map.venues.where((v) => v.id == _map.selectedId).firstOrNull;
                if (selected != null) _reveal(selected);
              },
              onTap: (_, _) => _map.onSelect?.call(null),
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && !_moved) setState(() => _moved = true);
              },
            ),
            children: [
              if (_map.tiles)
                TileLayer(
                  urlTemplate: dark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                      : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  retinaMode: RetinaMode.isHighDensity(context),
                  userAgentPackageName: _userAgent,
                ),
              if (_map.user != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ll(_map.user!),
                      width: _halo,
                      height: _halo,
                      child: _youMarker(c),
                    ),
                  ],
                ),
              Builder(
                builder: (context) {
                  final camera = MapCamera.of(context);
                  final groups = _ready ? _groups(camera) : <_Group>[];
                  return MarkerLayer(
                    markers: [
                      for (final g in groups)
                        if (!g.members.contains(selected))
                          Marker(
                            point: g.isCluster ? g.centre : _ll(g.venue.position),
                            width: g.isCluster ? _cluster : MuSize.touchTarget,
                            height: g.isCluster ? _cluster : MuSize.touchTarget,
                            child: g.isCluster
                                ? _clusterMarker(c, g, camera)
                                : _pinMarker(c, g.venue, false),
                          ),
                      if (selected != null)
                        Marker(
                          point: _ll(selected.position),
                          width: MuSize.touchTarget * _selectedScale,
                          height: MuSize.touchTarget * _selectedScale,
                          child: _pinMarker(c, selected, true),
                        ),
                    ],
                  );
                },
              ),
              if (selected != null)
                Builder(
                  builder: (context) {
                    final camera = MapCamera.of(context);
                    final pin = camera.latLngToScreenOffset(_ll(selected.position));
                    final width = camera.nonRotatedSize.width;
                    final left = (pin.dx - _card / 2).clamp(
                      MuSpace.s3,
                      // Clear of the zoom pill and « Me localiser » on the end side.
                      math.max(MuSpace.s3, width - _card - _controlsRoom),
                    ).toDouble();
                    return Stack(
                      children: [
                        Positioned(
                          left: left,
                          bottom: camera.nonRotatedSize.height - pin.dy + _cardLift,
                          width: _card,
                          child: _MiniCard(
                            venue: selected,
                            arrowX: pin.dx - left,
                            onClose: () => _map.onSelect?.call(null),
                            onOpen: (slot) => _map.onOpen?.call(selected, slot),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              _controls(c),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(MuSpace.s1),
                  child: ExcludeSemantics(
                    child: Text(_attribution, style: MuType.caption.copyWith(color: c.mapLabel)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(MuColors c) {
    final e = MuElevation.of(context);
    return Stack(
      children: [
        Positioned(
          top: MuSpace.s3,
          right: MuSpace.s3,
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: MuRadius.fullAll,
                  boxShadow: e.level2,
                ),
                child: Column(
                  children: [
                    MuIconButton(
                      icon: PhosphorIcons.plus(),
                      label: 'Zoomer',
                      onPressed: () => _zoomBy(_zoomStep),
                    ),
                    MuIconButton(
                      icon: PhosphorIcons.minus(),
                      label: 'Dézoomer',
                      onPressed: () => _zoomBy(-_zoomStep),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuSpace.s3),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                  boxShadow: e.level2,
                ),
                child: MuIconButton(
                  icon: PhosphorIcons.gpsFix(),
                  label: 'Me localiser',
                  onPressed: _locate,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: MuSpace.s3,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedSwitcher(
              duration: MuMotion.durationOf(context, MuMotion.base),
              switchInCurve: MuMotion.enter,
              child: !_moved || _map.onSearchArea == null
                  ? const SizedBox.shrink()
                  : DecoratedBox(
                      key: const ValueKey('search-area'),
                      decoration: BoxDecoration(
                        borderRadius: MuRadius.fullAll,
                        boxShadow: e.level2,
                      ),
                      child: MuButton.secondary(
                        label: 'Rechercher dans cette zone',
                        size: MuButtonSize.s,
                        onPressed: () {
                          final centre = _controller.camera.center;
                          _map.onSearchArea!(MuLatLng(centre.latitude, centre.longitude));
                          setState(() => _moved = false);
                        },
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _youMarker(MuColors c) {
    return Semantics(
      image: true,
      label: 'Ta position',
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

  Widget _pinMarker(MuColors c, MuMapVenue v, bool selected) {
    final scale = selected ? _selectedScale : 1.0;
    final disc = _pin * scale;
    return Semantics(
      button: true,
      expanded: selected,
      label:
          '${v.name}, ${v.sport.label}'
          '${v.area == null ? '' : ', ${v.area}'}'
          '${v.priceFrom == null ? '' : ', dès ${formatDT(v.priceFrom!)} par personne'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(selected ? null : v),
        child: Center(
          child: Container(
            width: disc + _pinRing * 2 + (selected ? _selectedRing * 2 : 0),
            height: disc + _pinRing * 2 + (selected ? _selectedRing * 2 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? c.accent : null,
              boxShadow: MuElevation.of(context).level2,
            ),
            alignment: Alignment.center,
            child: Container(
              width: disc + _pinRing * 2,
              height: disc + _pinRing * 2,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: v.sport.color(c),
                border: Border.all(color: MuPalette.white, width: _pinRing),
              ),
              child: MuSportIcon(
                v.sport,
                size: selected ? _selectedIcon : _pinIcon,
                color: MuPalette.ink900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _clusterMarker(MuColors c, _Group g, MapCamera camera) {
    final mix = <MuSport, int>{};
    for (final v in g.members) {
      mix[v.sport] = (mix[v.sport] ?? 0) + 1;
    }
    final mixText = [for (final e in mix.entries) '${e.value} ${e.key.label.toLowerCase()}']
        .join(', ');
    return Semantics(
      button: true,
      label: '${g.members.length} terrains : $mixText — zoomer',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _flyTo(g.centre, camera.zoom + _clusterZoom),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surface,
            boxShadow: MuElevation.of(context).level2,
          ),
          child: CustomPaint(
            painter: _MixRingPainter(
              [for (final e in mix.entries) (e.key.color(c), e.value)],
              c.borderStrong,
              _clusterRing,
            ),
            child: Center(
              child: Container(
                width: _clusterCount,
                height: _clusterCount,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surfaceInverse, shape: BoxShape.circle),
                child: Text(
                  '${g.members.length}',
                  style: MuType.numS.copyWith(color: c.textInverse),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The cluster ring, split by the sport mix.
class _MixRingPainter extends CustomPainter {
  const _MixRingPainter(this.parts, this.fallback, this.width);

  final List<(Color, int)> parts;
  final Color fallback;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2 + width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final total = parts.fold<int>(0, (a, p) => a + p.$2);
    if (parts.length < 2 || total == 0) {
      canvas.drawOval(rect, paint..color = parts.length == 1 ? parts.first.$1 : fallback);
      return;
    }
    var start = -math.pi / 2;
    for (final (color, n) in parts) {
      final sweep = 2 * math.pi * n / total;
      canvas.drawArc(rect, start, sweep, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_MixRingPainter oldDelegate) =>
      oldDelegate.parts != parts || oldDelegate.fallback != fallback;
}

/// The mini card above the selected pin: art, name, sport and subtitle, rating, price, up to three
/// slots and « Voir ».
class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.venue,
    required this.arrowX,
    required this.onClose,
    required this.onOpen,
  });

  final MuMapVenue venue;
  final double arrowX;
  final VoidCallback onClose;
  final ValueChanged<String?> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = MuElevation.of(context);
    final v = venue;
    final card = Container(
      padding: const EdgeInsets.all(MuSpace.s3),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: MuRadius.mdAll,
        boxShadow: e.level2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: _MuExploreMapState._thumb,
                child: ClipRRect(
                  borderRadius: MuRadius.smAll,
                  child: MuCourtArt(sport: v.sport),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    const SizedBox(height: MuSpace.s1),
                    Row(
                      children: [
                        MuSportIcon(v.sport, size: MuSize.iconXs, color: v.sport.text(c)),
                        const SizedBox(width: MuSpace.s1),
                        Text(v.sport.label, style: MuType.caption.copyWith(color: v.sport.text(c))),
                        if (v.subtitle != null) ...[
                          const SizedBox(width: MuSpace.s2),
                          Flexible(
                            child: Text(
                              v.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (v.rating != null) ...[
                      const SizedBox(height: MuSpace.s1),
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                PhosphorIcons.star(PhosphorIconsStyle.fill),
                                size: MuSize.iconXs,
                                color: c.warning,
                              ),
                            ),
                            TextSpan(
                              text: ' ${formatLevel(v.rating!)}',
                              style: MuType.numXs.copyWith(color: c.text),
                            ),
                            if (v.reviews != null) TextSpan(text: ' (${v.reviews} avis)'),
                          ],
                        ),
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              // Room for the close button, which sits in the card's corner.
              const SizedBox(width: MuSpace.s5),
            ],
          ),
          if (v.priceFrom != null) ...[
            const SizedBox(height: MuSpace.s3),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'dès ',
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                  TextSpan(text: formatAmount(v.priceFrom!), style: MuType.numM),
                  TextSpan(text: ' DT', style: MuType.numS),
                  TextSpan(
                    text: ' /pers.',
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              style: TextStyle(color: c.text),
            ),
          ],
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  label: 'Prochains créneaux',
                  child: Wrap(
                    spacing: MuSpace.s2,
                    runSpacing: MuSpace.s2,
                    children: [
                      for (final slot in v.slots.take(3))
                        MuChip(label: slot, size: MuChipSize.s, onSelected: (_) => onOpen(slot)),
                    ],
                  ),
                ),
              ),
              MuButton.primary(
                label: 'Voir',
                trailing: PhosphorIcons.arrowRight(),
                size: MuButtonSize.s,
                onPressed: () => onOpen(null),
              ),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: v.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              card,
              PositionedDirectional(
                top: MuSpace.s1,
                end: MuSpace.s1,
                child: MuIconButton(
                  icon: PhosphorIcons.x(),
                  label: 'Fermer',
                  size: MuIconButtonSize.s,
                  onPressed: onClose,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: (arrowX - _MuExploreMapState._arrow).clamp(
                MuSpace.s3,
                _MuExploreMapState._card - MuSpace.s3 - _MuExploreMapState._arrow * 2,
              ),
            ),
            child: CustomPaint(
              size: const Size(_MuExploreMapState._arrow * 2, _MuExploreMapState._arrow),
              painter: _ArrowPainter(c.surfaceElevated),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}
