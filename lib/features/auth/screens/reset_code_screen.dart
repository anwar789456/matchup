import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/auth_providers.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/code_entry.dart';

/// AUTH-07 · Mot de passe oublié 2/3: the code received by email.
class ResetCodeScreen extends ConsumerWidget {
  const ResetCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final email = ref.watch(authFlowProvider).resetEmail ?? '';
    final repo = ref.read(authRepositoryProvider);
    return CodeEntry(
      onBack: () => goBack(context, Routes.forgotPassword),
      header: const MuStepIndicator(step: 2, total: 3, title: 'Code'),
      lead: TextSpan(children: [
        const TextSpan(text: 'Code envoyé à '),
        TextSpan(text: email, style: MuType.labelL.copyWith(color: c.text)),
        const TextSpan(text: ' · '),
        inlineLink('Modifier', () => goBack(context, Routes.forgotPassword), MuType.labelL),
      ]),
      label: 'Code reçu par email',
      helper: 'Expire dans 10 minutes. Regarde aussi dans tes spams.',
      buttonLabel: 'Vérifier le code',
      verify: repo.verifyPasswordResetCode,
      onResend: () => repo.sendPasswordResetCode(email),
      onVerified: () => context.push(Routes.newPassword),
    );
  }
}
