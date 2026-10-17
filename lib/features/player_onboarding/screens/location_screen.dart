import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/onboarding_controller.dart';
import '../data/location_services.dart';
import '../widgets/onboarding_step_scaffold.dart';
import '../../../l10n/l10n.dart';

/// PLY-06 · Localisation: explains why before the system prompt. Granted → PLY-07 with the
/// position; refused → PLY-08.
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  bool _asking = false;

  // PLY-06: map 196 high; the 5 km ring is 132 across with a 1,5 px dashed edge.
  static const double _mapHeight = 196;
  static const double _ring = 132;
  static const double _ringStroke = 1.5;
  static const double _zoom = 0.8;
  static const double _labelPadV = 2;

  static const _me = MuLatLng(36.866, 10.296);
  static final _venues = [
    MuMapVenue(id: 'arena', name: l10n.arenaFive, sport: MuSport.football,
        position: const MuLatLng(36.8780, 10.3230), area: l10n.laMarsa),
    MuMapVenue(id: 'smash', name: l10n.smashPadelClub, sport: MuSport.padel,
        position: const MuLatLng(36.8540, 10.2660), area: l10n.lac),
    MuMapVenue(id: 'carthage', name: l10n.padelHouseCarthage, sport: MuSport.padel,
        position: const MuLatLng(36.8550, 10.3300), area: l10n.carthage),
    MuMapVenue(id: 'gammarth', name: l10n.gammarthFive, sport: MuSport.football,
        position: const MuLatLng(36.8790, 10.2800), area: l10n.gammarth),
    MuMapVenue(id: 'hoop', name: l10n.urbanCourt, sport: MuSport.basketball,
        position: const MuLatLng(36.8700, 10.2540), area: l10n.laMarsa),
  ];

  Future<void> _activate() async {
    setState(() => _asking = true);
    final outcome = await ref.read(devicePermissionsProvider).requestLocation();
    if (!mounted) return;
    if (outcome == PermissionOutcome.granted) {
      final area = await ref.read(zoneDirectoryProvider).currentArea();
      await ref.onboarding.setLocation(granted: true, area: area);
      if (mounted) context.push(Routes.playerZones);
    } else {
      await ref.onboarding.setLocation(granted: false);
      if (mounted) context.push(Routes.playerLocationDenied);
    }
    if (mounted) setState(() => _asking = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return OnboardingStepScaffold(
      route: Routes.playerLocation,
      step: 5,
      stepTitle: l10n.localisation,
      onBack: () => goBack(context, Routes.playerAvailability),
      body: [
        ExcludeSemantics(
          child: SizedBox(
            height: _mapHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: MuMapView(
                    center: _me,
                    user: _me,
                    venues: _venues,
                    zoom: _zoom,
                    district: l10n.laMarsa,
                    street: l10n.routeLaMarsa,
                    label: l10n.terrainsAutourDeLaMarsa,
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    size: const Size.square(_ring),
                    painter: _DashedCirclePainter(c.info, _ringStroke),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, _ring / 2 - MuSpace.s2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: _labelPadV),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: MuRadius.fullAll,
                      boxShadow: MuElevation.of(context).level1,
                    ),
                    child: Text(l10n.km4, style: MuType.labelS.copyWith(color: c.infoText)),
                  ),
                ),
              ],
            ),
          ),
        ),
        FlowTitle(
          l10n.jouePresDeChezToi,
          lead: l10n.activeTaPositionPourVoir,
        ),
        Column(
          children: [
            _Benefit(
              icon: Icon(PhosphorIcons.mapPin(), size: MuSize.iconS, color: c.text),
              title: l10n.desPartiesAMoinsDe,
              text: l10n.trieesParDistanceATon,
            ),
            const SizedBox(height: MuSpace.s4),
            _Benefit(
              icon: Icon(PhosphorIcons.path(), size: MuSize.iconS, color: c.text),
              title: l10n.lItineraireJusquAuTerrain,
              text: l10n.avecLeTempsDeTrajet,
            ),
            const SizedBox(height: MuSpace.s4),
            _Benefit(
              icon: SvgPicture.asset(
                MuGlyph.court,
                width: MuSize.iconS,
                height: MuSize.iconS,
                colorFilter: ColorFilter.mode(c.text, BlendMode.srcIn),
              ),
              title: l10n.lesTerrainsAutourDeToi,
              text: l10n.creneauxLibresEtPrixPar,
            ),
          ],
        ),
      ],
      bottomBar: [
        ProgressSavedNote(
          icon: PhosphorIcons.deviceMobile(),
          text: l10n.tonTelephoneVaTeDemander,
        ),
        MuButton.primary(
          label: l10n.activerLaLocalisation,
          leading: PhosphorIcons.navigationArrow(),
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _asking,
          onPressed: _activate,
        ),
        MuButton.tertiary(
          label: l10n.choisirMesZonesALa,
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: () => context.push(Routes.playerZones),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.text});

  final Widget icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      children: [
        Container(
          width: MuSize.controlM,
          height: MuSize.controlM,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
          child: ExcludeSemantics(child: icon),
        ),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MuType.label.copyWith(color: c.text)),
              Text(text, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.color, this.stroke);

  final Color color;
  final double stroke;

  static const int _dashes = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    const sweep = 2 * math.pi / _dashes;
    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color || old.stroke != stroke;
}
