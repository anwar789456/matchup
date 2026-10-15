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

/// PLY-05 · Disponibilités: days × matin / après-midi / soir (optional).
class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  static const days = [
    ('lun', 'lun.', 'Lundi'),
    ('mar', 'mar.', 'Mardi'),
    ('mer', 'mer.', 'Mercredi'),
    ('jeu', 'jeu.', 'Jeudi'),
    ('ven', 'ven.', 'Vendredi'),
    ('sam', 'sam.', 'Samedi'),
    ('dim', 'dim.', 'Dimanche'),
  ];
  static const slots = [
    ('matin', 'Matin', '8h–12h', 'matin'),
    ('aprem', 'Après-midi', '12h–18h', 'après-midi'),
    ('soir', 'Soir', '18h–23h', 'soir'),
  ];

  // PLY-05: the day column is 48 wide, cells 44 high and 6 apart; legend keys 16.
  static const double _dayColumn = 48;
  static const double _cell = 44;
  static const double _gap = 6;
  static const double _key = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final state = ref.watchOnboarding();
    final n = state.availability.length;
    void next() => context.push(Routes.playerLocation);

    Widget row(List<Widget> cells, {Widget? first, CrossAxisAlignment? align}) => Row(
          crossAxisAlignment: align ?? CrossAxisAlignment.center,
          children: [
            SizedBox(width: _dayColumn, child: first),
            for (final (i, cell) in cells.indexed) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(child: cell),
            ],
          ],
        );

    return OnboardingStepScaffold(
      route: Routes.playerAvailability,
      step: 4,
      stepTitle: 'Tes disponibilités',
      onBack: () => goBack(context, Routes.playerPosition),
      onSkip: next,
      gap: MuSpace.s5,
      body: [
        const FlowTitle(
          'Quand es-tu dispo ?',
          lead: 'Touche les créneaux où tu peux jouer, on s’en sert pour te proposer des parties.',
        ),
        Semantics(
          container: true,
          label: 'Tes disponibilités dans la semaine',
          child: Column(
            children: [
              ExcludeSemantics(
                child: row([
                  for (final (_, name, hours, _) in slots)
                    Column(
                      children: [
                        Text(name, style: MuType.labelS.copyWith(color: c.text)),
                        Text(hours, style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    ),
                ], align: CrossAxisAlignment.end),
              ),
              for (final (id, short, long) in days) ...[
                const SizedBox(height: _gap),
                row(
                  first: ExcludeSemantics(
                    child: Text(short, style: MuType.label.copyWith(color: c.text)),
                  ),
                  [
                    for (final (slot, _, _, spoken) in slots)
                      _SlotButton(
                        on: state.availability.contains('$id-$slot'),
                        label: '$long $spoken',
                        height: _cell,
                        onTap: () => ref.onboarding.toggleSlot('$id-$slot'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            Container(
              width: _key,
              height: _key,
              decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.xsAll),
              child: Icon(PhosphorIcons.check(), size: MuSize.iconXs * 0.75, color: c.onAccent),
            ),
            const SizedBox(width: MuSpace.s2),
            Text('Dispo', style: MuType.caption.copyWith(color: c.textSecondary)),
            const SizedBox(width: MuSpace.s4),
            Container(
              width: _key,
              height: _key,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: MuRadius.xsAll,
                border: Border.all(color: c.border),
              ),
            ),
            const SizedBox(width: MuSpace.s2),
            Text('Pas dispo', style: MuType.caption.copyWith(color: c.textSecondary)),
            const Spacer(),
            Semantics(
              liveRegion: true,
              child: Text(
                n == 0 ? 'Aucun créneau' : (n == 1 ? '1 créneau' : '$n créneaux'),
                style: MuType.label.copyWith(color: c.text),
              ),
            ),
          ],
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

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.on,
    required this.label,
    required this.height,
    required this.onTap,
  });

  final bool on;
  final String label;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      excludeSemantics: true,
      child: MuPressScale(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: MuRadius.smAll,
            child: AnimatedContainer(
              duration: MuMotion.durationOf(context, MuMotion.fast),
              curve: MuMotion.enter,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? c.accent : c.surfaceMuted,
                borderRadius: MuRadius.smAll,
                border: Border.all(color: on ? c.accent : c.border),
              ),
              child: on ? Icon(PhosphorIcons.check(), size: MuSize.iconS, color: c.onAccent) : null,
            ),
          ),
        ),
      ),
    );
  }
}
