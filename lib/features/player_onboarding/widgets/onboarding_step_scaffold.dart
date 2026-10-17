import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/onboarding_controller.dart';
import '../../../l10n/l10n.dart';

/// The player onboarding's 8 steps (PLY-01 … PLY-10).
const int onboardingSteps = 8;

/// A player onboarding screen: back, optional « Passer », « Étape n sur 8 · title », body and the
/// sticky bottom bar. Opening it records [route] so the player resumes here.
class OnboardingStepScaffold extends ConsumerStatefulWidget {
  OnboardingStepScaffold({
    super.key,
    required this.route,
    required this.step,
    required this.stepTitle,
    required this.onBack,
    required this.body,
    this.onSkip,
    this.bottomBar = const [],
    this.gap = MuSpace.s6,
    String? backLabel,
  }) : backLabel = backLabel ?? l10n.retour;

  final String route;
  final int step;
  final String stepTitle;
  final VoidCallback onBack;
  final String backLabel;
  final VoidCallback? onSkip;
  final List<Widget> body;
  final List<Widget> bottomBar;
  final double gap;

  @override
  ConsumerState<OnboardingStepScaffold> createState() => _OnboardingStepScaffoldState();
}

class _OnboardingStepScaffoldState extends ConsumerState<OnboardingStepScaffold> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(onboardingProvider.notifier).visit(widget.route));
  }

  @override
  Widget build(BuildContext context) {
    return FlowScaffold(
      onBack: widget.onBack,
      backLabel: widget.backLabel,
      topAction: widget.onSkip == null
          ? null
          : MuButton.tertiary(label: l10n.passer, onPressed: widget.onSkip),
      header: MuStepIndicator(
        step: widget.step,
        total: onboardingSteps,
        title: widget.stepTitle,
      ),
      gap: widget.gap,
      body: widget.body,
      bottomBar: widget.bottomBar,
    );
  }
}

/// « Ta progression est enregistrée, tu peux reprendre plus tard. » (PLY-01).
class ProgressSavedNote extends StatelessWidget {
  const ProgressSavedNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: MuSize.iconXs, color: c.textSecondary),
        const SizedBox(width: MuSpace.s2),
        Flexible(
          child: Text(text, style: MuType.caption.copyWith(color: c.textSecondary)),
        ),
      ],
    );
  }
}
