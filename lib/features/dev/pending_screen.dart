import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../router.dart';
import '../../theme/theme.dart';
import '../../ui/ui.dart';

/// Temporary landing for designed screens that a later phase builds (role onboardings).
/// Not a design: it only names the screen code so the flow can be followed end to end.
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MuSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MuIconButton(
                icon: PhosphorIcons.arrowLeft(),
                label: 'Retour',
                size: MuIconButtonSize.l,
                onPressed: () => goBack(context, Routes.roles),
              ),
              const Spacer(),
              Text(code.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
              const SizedBox(height: MuSpace.s2),
              Text('Écran prévu dans une prochaine phase.', style: MuType.h2.copyWith(color: c.text)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
