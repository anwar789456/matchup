import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';

/// One step of a [MuWizardStepper].
@immutable
class MuWizardStep {
  const MuWizardStep(this.label, {this.summary, this.error});

  final String label;

  /// What was filled in, under a done step (« Arena Five SARL »).
  final String? summary;

  /// Why the step needs fixing; turns it into an error step.
  final String? error;
}

enum MuStepperVariant { vertical, compact }

/// WizardStepper (components/WizardStepper.md): where the wizard is. `vertical` in the onboarding
/// rail — done steps (check, summary) are buttons, current has the Volt marker with its halo,
/// upcoming is outlined; `compact` on narrow screens: « Étape 3 sur 8 · Terrains », « Suivant : … »
/// and 4 px segments. [current] is 0-based.
///
/// The horizontal variant comes with the screens that use it.
class MuWizardStepper extends StatelessWidget {
  const MuWizardStepper({
    super.key,
    required this.steps,
    required this.current,
    required this.label,
    this.onStepTap,
    this.variant = MuStepperVariant.vertical,
  });

  final List<MuWizardStep> steps;
  final int current;

  /// Accessible name (« Espace propriétaire · étapes »).
  final String label;

  /// Called with the index of a done or error step.
  final ValueChanged<int>? onStepTap;
  final MuStepperVariant variant;

  // WizardStepper.md: 32 marker, 18 check, 4 px halo at 28 %, 2 px connector `space-2` from the
  // markers, steps `space-6` apart, 1,5 px ring when upcoming; compact segments 4 px.
  static const double _marker = MuSize.controlS;
  static const double _check = 18;
  static const double _halo = 4;
  static const double _haloAlpha = 0.28;
  static const double _connector = 2;
  static const double _ring = 1.5;
  static const double _segment = 4;

  @override
  Widget build(BuildContext context) =>
      variant == MuStepperVariant.compact ? _compact(context) : _vertical(context);

  Widget _compact(BuildContext context) {
    final c = context.mu;
    final step = steps[current];
    final next = current + 1 < steps.length ? steps[current + 1] : null;
    return Semantics(
      label: label,
      value: 'Étape ${current + 1} sur ${steps.length} : ${step.label}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Étape ${current + 1} sur ${steps.length} · '),
              TextSpan(text: step.label, style: MuType.label.copyWith(color: c.text)),
            ]),
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
          if (next != null)
            Text('Suivant : ${next.label}', style: MuType.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s2),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: MuSpace.s1),
                Expanded(
                  child: Container(
                    height: _segment,
                    decoration: BoxDecoration(
                      color: steps[i].error != null
                          ? c.error
                          : (i <= current ? c.primary : c.border),
                      borderRadius: MuRadius.fullAll,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _vertical(BuildContext context) {
    final c = context.mu;
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < steps.length; i++)
            _VerticalStep(
              index: i,
              step: steps[i],
              status: steps[i].error != null
                  ? _Status.error
                  : (i < current ? _Status.done : (i == current ? _Status.current : _Status.upcoming)),
              last: i == steps.length - 1,
              connectorDone: i < current,
              onTap: onStepTap == null || i >= current && steps[i].error == null
                  ? null
                  : () => onStepTap!(i),
              colors: c,
            ),
        ],
      ),
    );
  }
}

enum _Status { done, current, upcoming, error }

class _VerticalStep extends StatefulWidget {
  const _VerticalStep({
    required this.index,
    required this.step,
    required this.status,
    required this.last,
    required this.connectorDone,
    required this.onTap,
    required this.colors,
  });

  final int index;
  final MuWizardStep step;
  final _Status status;
  final bool last;
  final bool connectorDone;
  final VoidCallback? onTap;
  final MuColors colors;

  @override
  State<_VerticalStep> createState() => _VerticalStepState();
}

class _VerticalStepState extends State<_VerticalStep> {
  bool _hovered = false;

  // WizardStepper.md: hover lifts the marker to 1.06.
  static const double _hoverScale = 1.06;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    const m = MuWizardStepper._marker;
    final status = widget.status;
    final duration = MuMotion.durationOf(context, MuMotion.fast);

    final Widget marker = AnimatedScale(
      scale: _hovered && widget.onTap != null ? _hoverScale : 1,
      duration: duration,
      curve: MuMotion.pop,
      child: Container(
        width: m + MuWizardStepper._halo * 2,
        height: m + MuWizardStepper._halo * 2,
        alignment: Alignment.center,
        decoration: status == _Status.current
            ? BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent.withValues(alpha: MuWizardStepper._haloAlpha),
              )
            : null,
        child: Container(
          width: m,
          height: m,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: switch (status) {
              _Status.done => _hovered ? c.primaryHover : c.primary,
              _Status.current => c.accent,
              _Status.error => c.errorSoft,
              _Status.upcoming => null,
            },
            border: switch (status) {
              _Status.upcoming =>
                Border.all(color: c.borderStrong, width: MuWizardStepper._ring),
              _Status.error => Border.all(color: c.error, width: MuWizardStepper._ring),
              _ => null,
            },
          ),
          child: switch (status) {
            _Status.done => Icon(PhosphorIcons.check(),
                size: MuWizardStepper._check, color: c.onPrimary),
            _Status.error => Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                size: MuWizardStepper._check, color: c.errorText),
            _ => Text(
                '${widget.index + 1}',
                style: MuType.numS.copyWith(
                  color: status == _Status.current ? c.onAccent : c.textSecondary,
                ),
              ),
          },
        ),
      ),
    );

    final labelStyle = switch (status) {
      _Status.current => MuType.label.copyWith(color: c.text),
      _Status.error => MuType.label.copyWith(color: c.errorText),
      _Status.done => MuType.body.copyWith(
          color: c.text,
          decoration: _hovered ? TextDecoration.underline : null,
          decorationColor: c.text,
        ),
      _Status.upcoming => MuType.body.copyWith(color: c.textSecondary),
    };
    final detail = widget.step.error ?? (status == _Status.done ? widget.step.summary : null);

    const outer = m + MuWizardStepper._halo * 2;
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Marker over the connector to the next step.
          SizedBox(
            width: outer,
            child: Column(
              children: [
                marker,
                if (!widget.last)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
                      child: Container(
                        width: MuWizardStepper._connector,
                        decoration: BoxDecoration(
                          color: widget.connectorDone ? c.primary : c.border,
                          borderRadius: MuRadius.fullAll,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s2),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: MuWizardStepper._halo + MuSpace.s1,
                bottom: widget.last ? 0 : MuSpace.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.step.label, style: labelStyle),
                  if (detail != null)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.caption.copyWith(
                        color: status == _Status.error ? c.errorText : c.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final spoken = '${widget.step.label}, ${switch (status) {
      _Status.done => 'terminé',
      _Status.current => 'étape en cours',
      _Status.error => 'à corriger',
      _Status.upcoming => 'à venir',
    }}';
    if (widget.onTap == null) {
      return Semantics(label: spoken, excludeSemantics: true, child: row);
    }
    return Semantics(
      button: true,
      label: spoken,
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.mdAll,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: row,
          ),
        ),
      ),
    );
  }
}
