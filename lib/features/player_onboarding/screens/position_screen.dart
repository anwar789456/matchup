import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/onboarding_controller.dart';
import '../data/question_bank.dart';
import '../widgets/onboarding_step_scaffold.dart';
import '../../../l10n/l10n.dart';

/// A position a player can prefer, with the hint shown once picked.
class PositionOption {
  const PositionOption(this.id, this.label, this.hint, {this.wide = false});

  final String id;
  final String label;
  final String hint;

  /// Spans both columns of the grid (« Les deux »).
  final bool wide;
}

/// Positions per sport. Football and padel are designed (PLY-04); basketball is a draft.
abstract final class Positions {
  static String subtitle(MuSport sport) => switch (sport) {
        MuSport.football => l10n.lePosteOuTuJoues,
        MuSport.padel => l10n.leCoteOuTuRecois,
        MuSport.basketball => l10n.leRoleQueTuPrends,
      };

  static String groupLabel(MuSport sport) => switch (sport) {
        MuSport.football => l10n.posteAuFootball,
        MuSport.padel => l10n.coteAuPadel,
        MuSport.basketball => l10n.roleAuBasket,
      };

  static List<PositionOption> of(MuSport sport) => switch (sport) {
        MuSport.football => [
            PositionOption('gardien', l10n.gardien,
                l10n.gardienTuTiensLaCage),
            PositionOption('defenseur', l10n.defenseur,
                l10n.defenseurTuCouvresLArriere),
            PositionOption('milieu', l10n.milieu,
                l10n.milieuTuFaisLeLien),
            PositionOption('attaquant', l10n.attaquant,
                l10n.attaquantTuJouesHautEt),
          ],
        MuSport.padel => [
            PositionOption('droit', l10n.coteDroit,
                l10n.coteDroitCoupDroitAu),
            PositionOption('gauche', l10n.coteGauche,
                l10n.coteGaucheReversCoteVitre),
            PositionOption('deux', l10n.lesDeux, l10n.lesDeuxTuTAdaptes,
                wide: true),
          ],
        // Draft copy, to validate with design.
        MuSport.basketball => [
            PositionOption('meneur', l10n.meneur,
                l10n.meneurTuMontesLaBalle),
            PositionOption('ailier', l10n.ailier,
                l10n.ailierTuAttaquesLeCercle),
            PositionOption('interieur', l10n.interieur,
                l10n.interieurTuPrendsLesRebonds),
            PositionOption('polyvalent', l10n.polyvalent,
                l10n.polyvalentTuTAdaptesA),
          ],
      };
}

/// PLY-04 · Poste: the preferred position for each selected sport (optional).
class PositionScreen extends ConsumerWidget {
  const PositionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final state = ref.watchOnboarding();
    void next() => context.push(Routes.playerAvailability);

    return OnboardingStepScaffold(
      route: Routes.playerPosition,
      step: 3,
      stepTitle: l10n.tonPoste,
      onBack: () => goBack(
        context,
        state.sports.isEmpty ? Routes.playerSports : Routes.playerLevel(state.sports.last),
      ),
      onSkip: next,
      gap: MuSpace.s5,
      body: [
        FlowTitle(
          l10n.ouPreferesTuJouer,
          lead: l10n.onSEnSertPour,
        ),
        for (final sport in state.sports)
          _SportPositions(
            sport: sport,
            selected: state.positions[sport],
            onSelected: (id) => ref.onboarding.setPosition(sport, id),
            colors: c,
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

class _SportPositions extends StatelessWidget {
  const _SportPositions({
    required this.sport,
    required this.selected,
    required this.onSelected,
    required this.colors,
  });

  final MuSport sport;
  final String? selected;
  final ValueChanged<String> onSelected;
  final MuColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final options = Positions.of(sport);
    final hint = options.where((o) => o.id == selected).firstOrNull?.hint;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.border),
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuSportTile(sport),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(sport.onboardingName, style: MuType.labelL.copyWith(color: c.text)),
                    ),
                    Text(Positions.subtitle(sport),
                        style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Semantics(
            container: true,
            label: Positions.groupLabel(sport),
            child: LayoutBuilder(builder: (context, constraints) {
              final half = (constraints.maxWidth - MuSpace.s2) / 2;
              return Wrap(
                spacing: MuSpace.s2,
                runSpacing: 0,
                children: [
                  for (final o in options)
                    SizedBox(
                      width: o.wide ? constraints.maxWidth : half,
                      child: MuChip(
                        label: o.label,
                        kind: MuChipKind.choice,
                        expand: true,
                        selected: selected == o.id,
                        onSelected: (_) => onSelected(o.id),
                      ),
                    ),
                ],
              );
            }),
          ),
          if (hint != null) ...[
            const SizedBox(height: MuSpace.s2),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
                decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                child: Text(hint, style: MuType.caption.copyWith(color: c.textSecondary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
