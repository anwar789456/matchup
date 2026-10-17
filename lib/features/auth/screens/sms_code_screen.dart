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
import '../../../l10n/l10n.dart';

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
        TextSpan(text: l10n.codeEnvoyeAu),
        TextSpan(text: maskPhone(digits), style: MuType.labelL.copyWith(color: c.text)),
        const TextSpan(text: ' · '),
        inlineLink(l10n.modifier, () => goBack(context, Routes.phone), MuType.labelL),
      ]),
      label: l10n.codeRecuParSms,
      helper: l10n.leCodeExpireDansMinutes,
      buttonLabel: l10n.verifier,
      successMessage: AuthMessages.phoneVerified,
      verify: repo.verifyPhoneCode,
      onResend: () => repo.sendPhoneCode(digits),
      onVerified: () => context.push(Routes.verifyEmail),
    );
  }
}
