import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../controllers/auth_providers.dart';
import '../widgets/auth_messages.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/code_entry.dart';

/// AUTH-03 · Code SMS, with the AUTH-03b error state (wrong code, tries left, resend).
class SmsCodeScreen extends ConsumerWidget {
  const SmsCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final digits = ref.watch(authFlowProvider).phoneDigits ?? '';
    final repo = ref.read(authRepositoryProvider);
    return CodeEntry(
      onBack: () => goBack(context, Routes.phone),
      lead: TextSpan(children: [
        const TextSpan(text: 'Code envoyé au '),
        TextSpan(text: maskPhone(digits), style: MuType.labelL.copyWith(color: c.text)),
        const TextSpan(text: ' · '),
        inlineLink('Modifier', () => goBack(context, Routes.phone), MuType.labelL),
      ]),
      label: 'Code reçu par SMS',
      helper: 'Le code expire dans 10 minutes.',
      buttonLabel: 'Vérifier',
      successMessage: AuthMessages.phoneVerified,
      verify: repo.verifyPhoneCode,
      onResend: () => repo.sendPhoneCode(digits),
      onVerified: () => context.push(Routes.verifyEmail),
    );
  }
}
