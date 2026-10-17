import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/auth_providers.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/code_entry.dart';
import '../../../l10n/l10n.dart';

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
      header: MuStepIndicator(step: 2, total: 3, title: l10n.code),
      lead: TextSpan(children: [
        TextSpan(text: l10n.codeEnvoyeA),
        TextSpan(text: email, style: MuType.labelL.copyWith(color: c.text)),
        const TextSpan(text: ' · '),
        inlineLink(l10n.modifier, () => goBack(context, Routes.forgotPassword), MuType.labelL),
      ]),
      label: l10n.codeRecuParEmail,
      helper: l10n.expireDansMinutesRegardeAussi,
      buttonLabel: l10n.verifierLeCode,
      verify: repo.verifyPasswordResetCode,
      onResend: () => repo.sendPasswordResetCode(email),
      onVerified: () => context.push(Routes.newPassword),
    );
  }
}
