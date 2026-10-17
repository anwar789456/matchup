import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/coach_controller.dart';
import '../../../l10n/l10n.dart';

/// [ProWizardScaffold] set up for step [step] of the coach onboarding.
class CoachWizard extends ConsumerStatefulWidget {
  const CoachWizard({
    super.key,
    required this.step,
    required this.title,
    required this.lead,
    required this.body,
    this.validate,
  });

  final int step;
  final String title;
  final String lead;
  final Widget body;
  final FutureOr<bool> Function()? validate;

  @override
  ConsumerState<CoachWizard> createState() => _CoachWizardState();
}

class _CoachWizardState extends ConsumerState<CoachWizard> {
  bool _busy = false;

  static const _routes = [Routes.coachProfile, Routes.coachCertification, Routes.coachDashboard];

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      if (widget.validate != null && !await widget.validate!()) return;
      await ref.read(coachProvider.notifier).complete(widget.step);
      if (mounted) context.go(_routes[widget.step + 1]);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(coachProvider).requireValue;
    return ProWizardScaffold(
      space: ProSpace.coach,
      flowTitle: l10n.deviensCoachSurMatchup,
      flowMeta: l10n.etapesEnvironMin(CoachSteps.all.length),
      steps: CoachSteps.of(d, widget.step),
      current: widget.step,
      onStepTap: (i) => context.go(_routes[i]),
      title: widget.title,
      lead: widget.lead,
      body: widget.body,
      onBack: () => context.go(widget.step == 0 ? Routes.roles : _routes[widget.step - 1]),
      onSaveAndQuit: () => context.go(Routes.coachDashboard),
      onContinue: _busy ? null : _continue,
      continueLoading: _busy,
      savedAt: d.savedAt,
    );
  }
}
