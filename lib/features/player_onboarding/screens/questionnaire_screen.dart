import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/onboarding_controller.dart';
import '../data/question_bank.dart';
import '../widgets/onboarding_step_scaffold.dart';

/// PLY-02 · Questionnaire IA: six quick questions, one at a time, to estimate the level in [sport].
/// Answers are saved as they are given; the screen reopens on the first unanswered question.
class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key, required this.sport});

  final MuSport sport;

  @override
  ConsumerState<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  late final List<LevelQuestion> _questions = QuestionBank.forSport(widget.sport);
  int _index = 0;
  bool _estimating = false;
  // Slide direction of the next question (+1 forward, -1 back).
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    final answers = ref.read(onboardingProvider).value?.answers[widget.sport] ?? const {};
    final firstOpen = _questions.indexWhere((q) => answers[q.id] == null);
    _index = firstOpen < 0 ? _questions.length - 1 : firstOpen;
  }

  Map<String, String> get _answers => ref.watchOnboarding().answers[widget.sport] ?? const {};

  bool get _last => _index == _questions.length - 1;

  void _back() {
    if (_index == 0) {
      goBack(context, Routes.playerSports);
    } else {
      setState(() {
        _direction = -1;
        _index--;
      });
    }
  }

  Future<void> _next() async {
    if (!_last) {
      setState(() {
        _direction = 1;
        _index++;
      });
      return;
    }
    setState(() => _estimating = true);
    final answers = ref.read(onboardingProvider).value?.answers[widget.sport] ?? const {};
    final estimate = await ref.read(levelEstimatorProvider).estimate(widget.sport, answers);
    await ref.onboarding.saveEstimate(widget.sport, estimate);
    if (!mounted) return;
    setState(() => _estimating = false);
    context.push(Routes.playerLevel(widget.sport));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final question = _questions[_index];
    final answer = _answers[question.id];
    final n = _index + 1;

    return OnboardingStepScaffold(
      route: Routes.playerQuestions(widget.sport),
      step: 2,
      stepTitle: 'Ton niveau',
      onBack: _back,
      backLabel: _index == 0 ? 'Retour' : 'Question précédente',
      body: [
        Container(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s4),
          decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.mdAll),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const MuAiLabel(size: MuAiLabelSize.s, onAiSurface: true),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Text(
                      'Niveau ${widget.sport.lowerName}',
                      style: MuType.labelS.copyWith(color: c.aiText),
                    ),
                  ),
                  Text(
                    'Question $n sur ${_questions.length}',
                    style: MuType.labelS.copyWith(color: c.aiText),
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s3),
              MuProgressBar(
                value: n.toDouble(),
                max: _questions.length.toDouble(),
                variant: MuProgressVariant.segmented,
                size: MuProgressSize.s,
                tone: MuTone.ai,
                showValue: false,
              ),
              const SizedBox(height: MuSpace.s3),
              Text(
                '6 questions rapides pour te proposer des parties équilibrées.',
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: MuMotion.durationOf(context, MuMotion.base),
          switchInCurve: MuMotion.enter,
          switchOutCurve: MuMotion.exit,
          layoutBuilder: (current, previous) =>
              Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: Offset(0.03 * _direction, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(question.id),
            child: _QuestionView(
              question: question,
              answer: answer,
              onAnswer: (v) => ref.onboarding.answer(widget.sport, question.id, v),
            ),
          ),
        ),
      ],
      bottomBar: [
        _last
            ? MuButton.primary(
                label: 'Voir mon niveau',
                trailing: PhosphorIcons.arrowRight(),
                size: MuButtonSize.xl,
                fullWidth: true,
                loading: _estimating,
                onPressed: answer == null ? null : _next,
              )
            : MuButton.primary(
                label: 'Continuer',
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: answer == null ? null : _next,
              ),
      ],
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.question, required this.answer, required this.onAnswer});

  final LevelQuestion question;
  final String? answer;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(question.title, style: MuType.h2.copyWith(color: c.text)),
        ),
        if (question.subtitle != null) ...[
          const SizedBox(height: MuSpace.s2),
          Text(question.subtitle!, style: MuType.body.copyWith(color: c.textSecondary)),
        ],
        const SizedBox(height: MuSpace.s5),
        if (question.kind == QuestionKind.choice)
          MuChoiceGroup(
            label: question.title,
            children: [
              for (final o in question.options)
                MuChoiceCard(
                  title: o.title,
                  description: o.description,
                  selected: answer == o.id,
                  onTap: () => onAnswer(o.id),
                ),
            ],
          )
        else
          _ScaleQuestion(question: question, answer: answer, onAnswer: onAnswer),
      ],
    );
  }
}

/// The 1–5 self-rating: five answer tiles, then the chosen step explained.
class _ScaleQuestion extends StatelessWidget {
  const _ScaleQuestion({required this.question, required this.answer, required this.onAnswer});

  final LevelQuestion question;
  final String? answer;
  final ValueChanged<String> onAnswer;

  // PLY-02: tiles at least 84 high, 8 apart; selected ring 2 px.
  static const double _tileMin = 84;
  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final chosen = int.tryParse(answer ?? '');
    final duration = MuMotion.durationOf(context, MuMotion.fast);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: question.title,
          // Equal-height tiles inside the scrolling page.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 1; i <= question.scale.length; i++) ...[
                  if (i > 1) const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Semantics(
                      inMutuallyExclusiveGroup: true,
                      selected: chosen == i,
                      label: '$i, ${question.scale[i - 1].word}',
                      excludeSemantics: true,
                      child: MuPressScale(
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: () => onAnswer('$i'),
                            borderRadius: MuRadius.mdAll,
                            child: AnimatedContainer(
                              duration: duration,
                              curve: MuMotion.enter,
                              constraints: const BoxConstraints(minHeight: _tileMin),
                              padding: const EdgeInsets.symmetric(
                                horizontal: MuSpace.s1,
                                vertical: MuSpace.s2,
                              ),
                              decoration: BoxDecoration(
                                color: chosen == i ? c.accent : c.surface,
                                borderRadius: MuRadius.mdAll,
                                border: Border.all(
                                  color: chosen == i ? c.primary : c.borderControl,
                                  width: chosen == i ? _ring : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$i',
                                    style: MuType.numL.copyWith(
                                      color: chosen == i ? c.onAccent : c.text,
                                    ),
                                  ),
                                  const SizedBox(height: MuSpace.s1),
                                  Text(
                                    question.scale[i - 1].word,
                                    textAlign: TextAlign.center,
                                    style: MuType.caption.copyWith(
                                      color: chosen == i ? c.onAccent : c.textSecondary,
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
                ],
              ],
            ),
          ),
        ),
        if (chosen != null) ...[
          const SizedBox(height: MuSpace.s5),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
              decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$chosen · ${question.scale[chosen - 1].word}',
                    style: MuType.label.copyWith(color: c.text),
                  ),
                  Text(
                    question.scale[chosen - 1].description,
                    style: MuType.body.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
