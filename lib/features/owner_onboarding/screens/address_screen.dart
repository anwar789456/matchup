import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/owner_controller.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_wizard.dart';

/// OWN-02 — the address, and the pin moved onto the entrance.
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  late final _d = ref.read(ownerProvider).requireValue;
  late final _street = TextEditingController(text: _d.street);
  late final _postal = TextEditingController(text: _d.postalCode);
  late final _city = TextEditingController(text: _d.city);
  late final _access = TextEditingController(text: _d.access);
  late String _governorate = _d.governorate;

  String? _streetError;
  String? _postalError;
  String? _cityError;

  OwnerController get _owner => ref.read(ownerProvider.notifier);

  @override
  void dispose() {
    for (final c in [_street, _postal, _city, _access]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _streetError = _street.text.trim().isEmpty ? 'Indique l’adresse du terrain.' : null;
      _postalError = RegExp(r'^\d{4}$').hasMatch(_postal.text.trim())
          ? null
          : 'Le code postal compte 4 chiffres.';
      _cityError = _city.text.trim().isEmpty ? 'Indique la ville.' : null;
    });
    return _streetError == null && _postalError == null && _cityError == null;
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(ownerProvider).requireValue;
    final venue = d.venueName.trim().isEmpty ? 'ton terrain' : d.venueName.trim();
    return OwnerWizard(
      step: 1,
      title: 'Où se trouve $venue ?',
      lead: 'Les joueurs te trouvent sur la carte et reçoivent l’itinéraire avant le match.',
      validate: _validate,
      body: ProFormCard(
        divided: false,
        children: [
          ProFormSection(
            children: [
              ProFieldGrid(
                children: [
                  MuTextField(
                    label: 'Adresse',
                    controller: _street,
                    size: MuFieldSize.m,
                    leadingIcon: PhosphorIcons.mapPin(),
                    clearable: true,
                    error: _streetError,
                    autofillHints: const [AutofillHints.streetAddressLine1],
                    onChanged: (v) {
                      if (_streetError != null) setState(() => _streetError = null);
                      _owner.edit((d) => d.copyWith(street: v));
                    },
                  ),
                  MuTextField(
                    label: 'Code postal',
                    controller: _postal,
                    size: MuFieldSize.m,
                    error: _postalError,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    autofillHints: const [AutofillHints.postalCode],
                    onChanged: (v) {
                      if (_postalError != null) setState(() => _postalError = null);
                      _owner.edit((d) => d.copyWith(postalCode: v));
                    },
                  ),
                  MuTextField(
                    label: 'Ville',
                    controller: _city,
                    size: MuFieldSize.m,
                    error: _cityError,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.addressCity],
                    onChanged: (v) {
                      if (_cityError != null) setState(() => _cityError = null);
                      _owner.edit((d) => d.copyWith(city: v));
                    },
                  ),
                  MuSelect<String>(
                    label: 'Gouvernorat',
                    size: MuFieldSize.m,
                    value: _governorate,
                    options: [
                      for (final g in OwnerCatalog.governorates) MuSelectOption(value: g, label: g),
                    ],
                    onChanged: (v) {
                      setState(() => _governorate = v);
                      _owner.edit((d) => d.copyWith(governorate: v));
                    },
                  ),
                ],
              ),
              _PinMap(venue: venue),
              MuTextField(
                label: 'Indications d’accès',
                controller: _access,
                size: MuFieldSize.m,
                optional: true,
                onChanged: (v) => _owner.edit((d) => d.copyWith(access: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// « Position sur la carte »: the static map with the venue pin to drag onto the entrance,
/// zoom buttons, and the coordinates with « Recentrer sur l’adresse ».
class _PinMap extends ConsumerStatefulWidget {
  const _PinMap({required this.venue});

  final String venue;

  @override
  ConsumerState<_PinMap> createState() => _PinMapState();
}

class _PinMapState extends ConsumerState<_PinMap> {
  double _zoom = _startZoom;
  bool _dragging = false;

  // OWN-02 source: map 220 high at zoom 1,9; MapView.md zoom range 0,6–2,4. Drags start within
  // a pin's reach (36 pin + margin) of it.
  static const double _height = 220;
  static const double _startZoom = 1.9;
  static const double _minZoom = 0.6;
  static const double _maxZoom = 2.4;
  static const double _zoomStep = 0.3;
  static const double _grab = 32;

  Offset _pinOffset(Size size, double lat, double lng, double cLat, double cLng) {
    final k = MuMapView.pixelsPerDegree * _zoom;
    return Offset(size.width / 2 + (lng - cLng) * k, size.height / 2 - (lat - cLat) * k);
  }

  String _coord(double v, String pos, String neg) =>
      '${v.abs().toStringAsFixed(4).replaceAll('.', ',')}° ${v >= 0 ? pos : neg}';

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = ref.watch(ownerProvider).requireValue;
    final owner = ref.read(ownerProvider.notifier);
    final moved = d.pinOffsetMeters.round();

    final controls = Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: MuRadius.fullAll,
            boxShadow: MuElevation.of(context).level2,
          ),
          child: Column(
            children: [
              MuIconButton(
                icon: PhosphorIcons.plus(),
                label: 'Zoomer',
                onPressed: _zoom >= _maxZoom
                    ? null
                    : () => setState(() => _zoom = (_zoom + _zoomStep).clamp(_minZoom, _maxZoom)),
              ),
              Container(width: MuSpace.s6, height: 1, color: c.border),
              MuIconButton(
                icon: PhosphorIcons.minus(),
                label: 'Dézoomer',
                onPressed: _zoom <= _minZoom
                    ? null
                    : () => setState(() => _zoom = (_zoom - _zoomStep).clamp(_minZoom, _maxZoom)),
              ),
            ],
          ),
        ),
        const SizedBox(height: MuSpace.s2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
            boxShadow: MuElevation.of(context).level2,
          ),
          child: MuIconButton(
            icon: PhosphorIcons.crosshairSimple(),
            label: 'Centrer sur l’épingle',
            onPressed: () => setState(() => _zoom = _startZoom),
          ),
        ),
      ],
    );

    final map = LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, _height);
        final pin = _pinOffset(size, d.latitude, d.longitude, d.addressLat, d.addressLng);
        return GestureDetector(
          onPanStart: (e) => _dragging = (e.localPosition - pin).distance <= _grab,
          onPanUpdate: (e) {
            if (!_dragging) return;
            final k = MuMapView.pixelsPerDegree * _zoom;
            // The map never mirrors, so the drag is read left to right whatever the language.
            owner.edit(
              (d) => d.copyWith(
                latitude: d.latitude - e.delta.dy / k,
                longitude: d.longitude + e.delta.dx / k,
              ),
            );
          },
          onPanEnd: (_) => _dragging = false,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: SizedBox(
              height: _height,
              child: MuMapView(
                center: MuLatLng(d.addressLat, d.addressLng),
                zoom: _zoom,
                district: d.city.toUpperCase(),
                label: 'Position de ${widget.venue}, ${d.city}',
                venues: [
                  MuMapVenue(
                    id: 'venue',
                    name: widget.venue,
                    sport: d.courts.firstOrNull?.sport ?? MuSport.football,
                    position: MuLatLng(d.latitude, d.longitude),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Position sur la carte', style: MuType.label.copyWith(color: c.text)),
        const SizedBox(height: MuSpace.s3),
        Stack(
          children: [
            map,
            PositionedDirectional(
              top: MuSpace.s3,
              start: MuSpace.s3,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
                  decoration: BoxDecoration(
                    color: c.surfaceInverse,
                    borderRadius: MuRadius.fullAll,
                    boxShadow: MuElevation.of(context).level2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.handPointing(), size: MuSize.iconXs, color: c.textInverse),
                      const SizedBox(width: MuSpace.s2),
                      Text(
                        'Déplace l’épingle sur l’entrée',
                        style: MuType.labelS.copyWith(color: c.textInverse),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PositionedDirectional(top: MuSpace.s3, end: MuSpace.s3, child: controls),
          ],
        ),
        const SizedBox(height: MuSpace.s3),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: MuSpace.s2,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.crosshair(), size: MuSize.iconXs, color: c.textSecondary),
                const SizedBox(width: MuSpace.s2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${_coord(d.latitude, 'N', 'S')} · ${_coord(d.longitude, 'E', 'O')}',
                    style: MuType.numXs.copyWith(color: c.textSecondary),
                  ),
                ),
                if (moved > 0)
                  Flexible(
                    child: Text(
                      ' · épingle déplacée de $moved m',
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
              ],
            ),
            MuButton.tertiary(
              label: 'Recentrer sur l’adresse',
              leading: PhosphorIcons.arrowCounterClockwise(),
              size: MuButtonSize.s,
              onPressed: moved == 0
                  ? null
                  : () => owner.edit(
                      (d) => d.copyWith(latitude: d.addressLat, longitude: d.addressLng),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
