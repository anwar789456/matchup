import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/onboarding_controller.dart';
import '../data/question_bank.dart';
import '../widgets/onboarding_step_scaffold.dart';

/// PLY-01 · Sports: pick one or more sports (multi-select photo cards).
class SportsScreen extends ConsumerWidget {
  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watchOnboarding();
    void next() {
      final sport = state.nextSportToEstimate;
      context.push(sport != null ? Routes.playerQuestions(sport) : Routes.playerPosition);
    }

    return OnboardingStepScaffold(
      route: Routes.playerSports,
      step: 1,
      stepTitle: 'Tes sports',
      onBack: () => goBack(context, Routes.roles),
      body: [
        const FlowTitle(
          'Quels sports tu joues ?',
          lead: 'Choisis-en un ou plusieurs. On te proposera des parties et des joueurs à ton '
              'niveau.',
        ),
        Semantics(
          container: true,
          label: 'Tes sports',
          child: Column(
            children: [
              for (final (i, sport) in MuSport.values.indexed) ...[
                if (i > 0) const SizedBox(height: MuSpace.s3),
                SportPhotoCard(
                  sport: sport,
                  selected: state.sports.contains(sport),
                  onTap: () => ref.onboarding.toggleSport(sport),
                ),
              ],
            ],
          ),
        ),
      ],
      bottomBar: [
        ProgressSavedNote(
          icon: PhosphorIcons.cloudCheck(),
          text: 'Ta progression est enregistrée, tu peux reprendre plus tard.',
        ),
        MuButton.primary(
          label: 'Continuer',
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: state.sports.isEmpty ? null : next,
        ),
      ],
    );
  }
}

/// A sport answer card on the floodlit CourtArt photo: sport tile, name and format over the
/// photo scrim, a 28 px check badge top-end; selected = 2 px gap + 2 px `primary` ring.
class SportPhotoCard extends StatelessWidget {
  const SportPhotoCard({
    super.key,
    required this.sport,
    required this.selected,
    required this.onTap,
  });

  final MuSport sport;
  final bool selected;
  final VoidCallback onTap;

  // PLY-01: card 116 high; badge 28 with a 2 px white edge; selected ring 2 px gap + 2 px.
  static const double _height = 116;
  static const double _badge = 28;
  static const double _badgeEdge = 2;
  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final duration = MuMotion.durationOf(context, MuMotion.fast);
    return Semantics(
      checked: selected,
      label: '${sport.onboardingName}, ${sport.formatLine}',
      excludeSemantics: true,
      child: MuPressScale(
        child: AnimatedContainer(
          duration: duration,
          curve: MuMotion.enter,
          decoration: BoxDecoration(
            borderRadius: MuRadius.mdAll,
            boxShadow: selected
                ? [
                    BoxShadow(color: c.primary, spreadRadius: _ring * 2),
                    BoxShadow(color: c.surface, spreadRadius: _ring),
                  ]
                : const [],
          ),
          child: ClipRRect(
            borderRadius: MuRadius.mdAll,
            child: SizedBox(
              height: _height,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MuCourtArt(sport: sport),
                      const DecoratedBox(
                        decoration: BoxDecoration(gradient: MuGradients.photoScrim),
                      ),
                      PositionedDirectional(
                        start: MuSpace.s4,
                        end: MuSpace.s4,
                        bottom: MuSpace.s4,
                        child: Row(
                          children: [
                            MuSportTile(sport),
                            const SizedBox(width: MuSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    sport.onboardingName,
                                    style: MuType.labelL.copyWith(color: MuPalette.white),
                                  ),
                                  Text(
                                    sport.formatLine,
                                    style: MuType.caption.copyWith(color: MuPalette.ink100),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        top: MuSpace.s3,
                        end: MuSpace.s3,
                        child: AnimatedContainer(
                          duration: duration,
                          curve: MuMotion.pop,
                          width: _badge,
                          height: _badge,
                          decoration: BoxDecoration(
                            color: selected ? c.accent : null,
                            borderRadius: MuRadius.xsAll,
                            border: Border.all(
                              color: selected ? c.accent : MuPalette.white,
                              width: _badgeEdge,
                            ),
                          ),
                          child: selected
                              ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                                  size: MuSize.iconS, color: c.onAccent)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
