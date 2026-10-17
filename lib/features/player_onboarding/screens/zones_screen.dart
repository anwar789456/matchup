import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_step_scaffold.dart';
import '../widgets/zone_search_field.dart';
import '../../../l10n/l10n.dart';

/// PLY-07 · Zones préférées: districts where the player plays and the maximum distance.
class ZonesScreen extends ConsumerWidget {
  const ZonesScreen({super.key});

  static const radii = [5, 10, 20, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final state = ref.watchOnboarding();
    final suggestions = ref
        .read(zoneDirectoryProvider)
        .suggestionsNear(state.area)
        .where((z) => !state.zones.contains(z))
        .toList();
    final n = state.zones.length;
    void next() => context.push(Routes.playerNotifications);

    Widget sectionTitle(String text, [String? aside, TextStyle? asideStyle]) => Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(text, style: MuType.label.copyWith(color: c.text)),
              ),
            ),
            if (aside != null)
              Text(aside, style: asideStyle ?? MuType.caption.copyWith(color: c.textSecondary)),
          ],
        );

    return OnboardingStepScaffold(
      route: Routes.playerZones,
      step: 5,
      stepTitle: l10n.localisation,
      onBack: () => goBack(context, Routes.playerLocation),
      onSkip: next,
      gap: MuSpace.s5,
      body: [
        FlowTitle(
          l10n.tesZonesDeJeu,
          lead: l10n.ajouteLesQuartiersOuTu,
        ),
        if (state.locationGranted == true)
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
              decoration: BoxDecoration(color: c.successSoft, borderRadius: MuRadius.mdAll),
              child: Row(
                children: [
                  Icon(PhosphorIcons.navigationArrow(), size: MuSize.iconS, color: c.successText),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: l10n.positionActivee, style: MuType.label),
                        if (state.area != null) TextSpan(text: ' · ${state.area}'),
                      ]),
                      style: MuType.body.copyWith(color: c.text),
                    ),
                  ),
                  Icon(PhosphorIcons.checkCircle(), size: MuSize.iconS, color: c.successText),
                ],
              ),
            ),
          ),
        const ZoneSearchField(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle(l10n.tesZones, n == 0 ? 'Aucune zone' : (n == 1 ? l10n.zone : '$n zones')),
            const SizedBox(height: MuSpace.s2),
            Wrap(
              spacing: MuSpace.s2,
              children: [
                for (final z in state.zones)
                  MuChip(
                    label: z,
                    kind: MuChipKind.input,
                    icon: PhosphorIcons.mapPin(),
                    removeLabel: l10n.retirer(z),
                    onRemove: () => ref.onboarding.removeZone(z),
                  ),
              ],
            ),
          ],
        ),
        if (suggestions.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sectionTitle(l10n.suggestionsAutourDeToi),
              const SizedBox(height: MuSpace.s1),
              Wrap(
                spacing: MuSpace.s2,
                children: [
                  for (final z in suggestions)
                    MuChip(
                      label: z,
                      icon: PhosphorIcons.plus(),
                      onSelected: (_) => ref.onboarding.addZone(z),
                    ),
                ],
              ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle(
              l10n.distanceMaximale,
              l10n.jusquAKm2(state.radiusKm),
              MuType.label.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: MuSpace.s3),
            MuSegmentedControl<int>(
              semanticLabel: l10n.distanceMaximale,
              expand: true,
              value: state.radiusKm,
              onChanged: ref.onboarding.setRadius,
              segments: [
                for (final km in radii) MuSegment(value: km, label: '$km km'),
              ],
            ),
          ],
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: l10n.continuer,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: next,
        ),
      ],
    );
  }
}
