import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_step_scaffold.dart';
import '../widgets/zone_search_field.dart';
import '../../../l10n/l10n.dart';

/// PLY-08 · Localisation refusée: how to turn it on in Réglages, or pick zones by hand.
class LocationDeniedScreen extends ConsumerWidget {
  const LocationDeniedScreen({super.key});

  static final _steps = [l10n.reglages, l10n.matchup, l10n.position, l10n.lorsqueLAppEstActive];

  // PLY-08: numbered steps in 20 px circles.
  static const double _stepDot = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final state = ref.watchOnboarding();
    final nearby = ref.read(zoneDirectoryProvider).suggestionsNear(state.area);
    final zones = [...nearby, ...state.zones.where((z) => !nearby.contains(z))];
    void next() => context.push(Routes.playerNotifications);

    return OnboardingStepScaffold(
      route: Routes.playerLocationDenied,
      step: 5,
      stepTitle: l10n.localisation,
      onBack: () => goBack(context, Routes.playerLocation),
      onSkip: next,
      gap: MuSpace.s5,
      body: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuBanner(
              tone: MuBannerTone.warning,
              icon: PhosphorIcons.mapPinArea(PhosphorIconsStyle.fill),
              title: l10n.localisationDesactivee,
              detail: l10n.choisisTesZonesALa,
            ),
            const SizedBox(height: MuSpace.s3),
            Container(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s4),
              decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(l10n.pourLActiver, style: MuType.label.copyWith(color: c.text)),
                        ),
                      ),
                      MuButton.link(
                        label: l10n.ouvrirReglages,
                        trailing: PhosphorIcons.arrowSquareOut(),
                        inline: true,
                        linkStyle: MuType.label,
                        onPressed: () => ref.read(devicePermissionsProvider).openSettings(),
                      ),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Wrap(
                    spacing: MuSpace.s2,
                    runSpacing: MuSpace.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final (i, step) in _steps.indexed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: _stepDot,
                              height: _stepDot,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.borderStrong),
                              ),
                              child: Text('${i + 1}', style: MuType.numXs.copyWith(color: c.text)),
                            ),
                            const SizedBox(width: MuSpace.s1),
                            Text(step, style: MuType.label.copyWith(color: c.text)),
                            if (i < _steps.length - 1) ...[
                              const SizedBox(width: MuSpace.s1),
                              ExcludeSemantics(
                                child: MuDirectionalIcon(PhosphorIcons.caretRight(),
                                    size: MuSize.iconXs, color: c.textSecondary),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.choisisTesZonesDeJeu, style: MuType.h2.copyWith(color: c.text)),
            ),
            const SizedBox(height: MuSpace.s1),
            Text(l10n.onTeProposeraDesParties,
                style: MuType.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: MuSpace.s3),
            const ZoneSearchField(),
            const SizedBox(height: MuSpace.s2),
            Semantics(
              container: true,
              label: l10n.zonesProposees,
              child: Wrap(
                spacing: MuSpace.s2,
                children: [
                  for (final z in zones)
                    MuChip(
                      label: z,
                      selected: state.zones.contains(z),
                      onSelected: (_) => ref.onboarding.toggleZone(z),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: l10n.continuerAvecMesZones,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: next,
        ),
      ],
    );
  }
}
