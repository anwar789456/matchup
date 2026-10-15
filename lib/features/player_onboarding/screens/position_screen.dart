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
        MuSport.football => 'Le poste où tu joues le plus souvent',
        MuSport.padel => 'Le côté où tu reçois le service',
        MuSport.basketball => 'Le rôle que tu prends le plus souvent',
      };

  static String groupLabel(MuSport sport) => switch (sport) {
        MuSport.football => 'Poste au football',
        MuSport.padel => 'Côté au padel',
        MuSport.basketball => 'Rôle au basket',
      };

  static List<PositionOption> of(MuSport sport) => switch (sport) {
        MuSport.football => const [
            PositionOption('gardien', 'Gardien',
                'Gardien : tu tiens la cage et tu relances le jeu.'),
            PositionOption('defenseur', 'Défenseur',
                'Défenseur : tu couvres l’arrière et tu bloques les contres.'),
            PositionOption('milieu', 'Milieu',
                'Milieu : tu fais le lien entre la défense et l’attaque.'),
            PositionOption('attaquant', 'Attaquant',
                'Attaquant : tu joues haut et tu finis les actions.'),
          ],
        MuSport.padel => const [
            PositionOption('droit', 'Côté droit',
                'Côté droit : coup droit au centre, tu construis le point.'),
            PositionOption('gauche', 'Côté gauche',
                'Côté gauche : revers côté vitre, souvent celui qui finit au smash.'),
            PositionOption('deux', 'Les deux', 'Les deux : tu t’adaptes au côté de ton partenaire.',
                wide: true),
          ],
        // Draft copy, to validate with design.
        MuSport.basketball => const [
            PositionOption('meneur', 'Meneur',
                'Meneur : tu montes la balle et tu lances le jeu.'),
            PositionOption('ailier', 'Ailier',
                'Ailier : tu attaques le cercle et tu tires de loin.'),
            PositionOption('interieur', 'Intérieur',
                'Intérieur : tu prends les rebonds et tu joues près du panier.'),
            PositionOption('polyvalent', 'Polyvalent',
                'Polyvalent : tu t’adaptes à ce dont l’équipe a besoin.'),
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
      stepTitle: 'Ton poste',
      onBack: () => goBack(context, Routes.playerSports),
      onSkip: next,
      gap: MuSpace.s5,
      body: [
        const FlowTitle(
          'Où préfères-tu jouer ?',
          lead: 'On s’en sert pour équilibrer les équipes. Tu pourras en changer depuis ton profil.',
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
          label: 'Continuer',
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
