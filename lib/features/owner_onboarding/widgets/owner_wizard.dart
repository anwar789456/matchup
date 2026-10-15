import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/owner_controller.dart';

/// [ProWizardScaffold] set up for step [step] of the owner wizard: rail summaries from the draft,
/// « Retour » to the previous step (the role choice from the first), « Enregistrer et quitter »
/// to the dashboard, « Continuer » after [validate] passes.
class OwnerWizard extends ConsumerStatefulWidget {
  const OwnerWizard({
    super.key,
    required this.step,
    required this.title,
    required this.lead,
    required this.body,
    this.validate,
    this.onContinue,
    this.continueLabel = 'Continuer',
    this.draftNote = true,
  });

  final int step;
  final String title;
  final String lead;
  final Widget body;

  /// Checks the step (showing its errors); « Continuer » moves on when it returns true.
  final FutureOr<bool> Function()? validate;

  /// Replaces the default « Continuer » (OWN-08 starts the trial).
  final Future<void> Function()? onContinue;
  final String continueLabel;
  final bool draftNote;

  @override
  ConsumerState<OwnerWizard> createState() => _OwnerWizardState();
}

class _OwnerWizardState extends ConsumerState<OwnerWizard> {
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      if (widget.validate != null && !await widget.validate!()) return;
      if (widget.onContinue != null) {
        await widget.onContinue!();
        return;
      }
      await ref.read(ownerProvider.notifier).complete(widget.step);
      if (mounted) context.go(Routes.owner[widget.step + 1]);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(ownerProvider).requireValue;
    final venue = d.venueName.trim().isEmpty ? 'ton terrain' : d.venueName.trim();
    return ProWizardScaffold(
      space: ProSpace.owner,
      railTitle: 'Mets $venue en ligne',
      railMeta: '${OwnerSteps.all.length} étapes · environ 10 min',
      steps: OwnerSteps.of(d, widget.step),
      current: widget.step,
      onStepTap: (i) => context.go(Routes.owner[i]),
      title: widget.title,
      lead: widget.lead,
      body: widget.body,
      onBack: () => context.go(widget.step == 0 ? Routes.roles : Routes.owner[widget.step - 1]),
      onSaveAndQuit: () => context.go(Routes.ownerDashboard),
      onContinue: _busy ? null : _continue,
      continueLoading: _busy,
      continueLabel: widget.continueLabel,
      savedAt: widget.draftNote ? d.savedAt : null,
    );
  }
}
