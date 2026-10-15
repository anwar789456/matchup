import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/onboarding_controller.dart';
import '../data/level_estimator.dart';
import '../data/question_bank.dart';
import '../widgets/onboarding_step_scaffold.dart';

/// PLY-03 · Niveau estimé (IA): the estimate with its confidence, why, « Ajuster mon niveau », and
/// the other sports still to estimate.
class LevelResultScreen extends ConsumerStatefulWidget {
  const LevelResultScreen({super.key, required this.sport});

  final MuSport sport;

  @override
  ConsumerState<LevelResultScreen> createState() => _LevelResultScreenState();
}

class _LevelResultScreenState extends ConsumerState<LevelResultScreen> {
  bool _adjusting = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final state = ref.watchOnboarding();
    final estimate = state.estimates[widget.sport];
    if (estimate == null) {
      // Opened without answers (deep link): start the questionnaire.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.replace(Routes.playerQuestions(widget.sport)),
      );
      return const SizedBox.shrink();
    }
    final level = state.levels[widget.sport] ?? estimate.level;
    final adjusted = level != estimate.level;
    final toEstimate =
        state.sports.where((s) => s != widget.sport && !state.estimates.containsKey(s));

    return OnboardingStepScaffold(
      route: Routes.playerLevel(widget.sport),
      step: 2,
      stepTitle: 'Ton niveau',
      onBack: () => goBack(context, Routes.playerQuestions(widget.sport)),
      gap: MuSpace.s4,
      body: [
        FlowTitle('Ton niveau ${widget.sport.withDe}'),
        _EstimateCard(
          sport: widget.sport,
          estimate: estimate,
          level: level,
          adjusted: adjusted,
        ),
        _Reasons(estimate: estimate),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuButton.secondary(
              label: 'Ajuster mon niveau',
              leading: PhosphorIcons.pencilSimple(),
              trailing: _adjusting ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: () => setState(() => _adjusting = !_adjusting),
            ),
            AnimatedSize(
              duration: MuMotion.durationOf(context, MuMotion.base),
              curve: MuMotion.move,
              alignment: Alignment.topCenter,
              child: _adjusting
                  ? Padding(
                      padding: const EdgeInsets.only(top: MuSpace.s3),
                      child: Container(
                        padding: const EdgeInsets.all(MuSpace.s4),
                        decoration:
                            BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MuLevelSlider(
                              label: 'Ton niveau ${widget.sport.lowerName}',
                              value: level,
                              aiEstimate: estimate.level,
                              onChanged: (v) => ref.onboarding.setLevel(widget.sport, v),
                            ),
                            const SizedBox(height: MuSpace.s2),
                            Text(
                              'Tu connais ton jeu mieux que personne : ton choix remplace '
                              'l’estimation.',
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: MuSpace.s3),
            ProgressSavedNote(
              icon: PhosphorIcons.arrowsClockwise(),
              text: 'Le niveau se met à jour automatiquement après tes matchs.',
            ),
          ],
        ),
        for (final other in toEstimate)
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(
                MuSpace.s3, MuSpace.s3, MuSpace.s2, MuSpace.s3),
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
            child: Row(
              children: [
                MuSportTile(other),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${other.onboardingName} · à estimer',
                          style: MuType.label.copyWith(color: c.text)),
                      Text('6 questions, moins d’une minute',
                          style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                MuButton.tertiary(
                  label: 'Estimer',
                  size: MuButtonSize.s,
                  onPressed: () => context.push(Routes.playerQuestions(other)),
                ),
              ],
            ),
          ),
      ],
      bottomBar: [
        MuButton.primary(
          label: 'C’est bon',
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(Routes.playerPosition),
        ),
      ],
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.sport,
    required this.estimate,
    required this.level,
    required this.adjusted,
  });

  final MuSport sport;
  final LevelEstimate estimate;
  final double level;
  final bool adjusted;

  // PLY-03: confidence dots 6 px, 3 apart; the hero value sits 6 above the band's baseline.
  static const double _dot = 6;
  static const double _dotGap = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (String confidence, int dots) = switch (estimate.confidence) {
      EstimateConfidence.low => ('faible', 1),
      EstimateConfidence.medium => ('moyenne', 2),
      EstimateConfidence.high => ('élevée', 3),
    };
    return Semantics(
      container: true,
      label: adjusted ? 'Niveau ${sport.lowerName} choisi' : 'Niveau ${sport.lowerName} estimé',
      child: Container(
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
                if (!adjusted) ...[
                  const MuAiLabel(),
                  const SizedBox(width: MuSpace.s2),
                ],
                Expanded(
                  child: Text(adjusted ? 'Ton niveau' : 'Niveau estimé',
                      style: MuType.label.copyWith(color: c.textSecondary)),
                ),
                MuChip.sport(sport),
              ],
            ),
            const SizedBox(height: MuSpace.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Semantics(
                  label: '${formatLevel(level)} sur 7',
                  excludeSemantics: true,
                  child: Text(formatLevel(level), style: MuType.numHero.copyWith(color: c.text)),
                ),
                const SizedBox(width: MuSpace.s4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: MuSpace.s2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(levelBand(level), style: MuType.h3.copyWith(color: c.text)),
                        Text('sur une échelle de 1,0 à 7,0',
                            style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MuSpace.s3),
            MuLevelIndicator(
              level: level,
              variant: MuLevelVariant.bar,
              label: 'Niveau ${sport.lowerName} estimé',
            ),
            const SizedBox(height: MuSpace.s3),
            Container(
              padding: const EdgeInsets.only(top: MuSpace.s3),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: _dotGap),
                    Container(
                      width: _dot,
                      height: _dot,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < dots ? c.text : c.borderStrong,
                      ),
                    ),
                  ],
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'Confiance : $confidence',
                          style: MuType.labelS.copyWith(color: c.text),
                        ),
                        const TextSpan(text: ' · s’affine après 3 matchs'),
                      ]),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reasons extends StatelessWidget {
  const _Reasons({required this.estimate});

  final LevelEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    Widget icon(String questionId) => switch (questionId) {
          Q.experience => Icon(PhosphorIcons.clock(), size: MuSize.iconS, color: c.textSecondary),
          Q.frequency =>
            Icon(PhosphorIcons.calendarCheck(), size: MuSize.iconS, color: c.textSecondary),
          Q.rating => Icon(PhosphorIcons.target(), size: MuSize.iconS, color: c.textSecondary),
          _ => SvgPicture.asset(
              MuGlyph.trophy,
              width: MuSize.iconS,
              height: MuSize.iconS,
              colorFilter: ColorFilter.mode(c.textSecondary, BlendMode.srcIn),
            ),
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Pourquoi ce niveau ?', style: MuType.h3.copyWith(color: c.text)),
              ),
            ),
            Text('Basé sur tes réponses', style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
        const SizedBox(height: MuSpace.s3),
        LayoutBuilder(builder: (context, constraints) {
          final half = (constraints.maxWidth - MuSpace.s3) / 2;
          return Wrap(
            spacing: MuSpace.s3,
            runSpacing: MuSpace.s3,
            children: [
              for (final r in estimate.reasons)
                SizedBox(
                  width: half,
                  child: Row(
                    children: [
                      icon(r.questionId),
                      const SizedBox(width: MuSpace.s2),
                      Expanded(
                        child: Text(r.text, style: MuType.body.copyWith(color: c.text)),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}
