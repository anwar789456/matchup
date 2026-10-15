import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/auth_providers.dart';
import '../widgets/auth_messages.dart';

/// AUTH-06 · Mot de passe oublié 1/3: the account email, to receive a 6-digit code.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _email = TextEditingController(
    text: ref.read(authFlowProvider).resetEmail ?? ref.read(authFlowProvider).email ?? '',
  );
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = AuthMessages.validateEmail(_email.text);
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetCode(_email.text);
      ref.read(authFlowProvider.notifier).setResetEmail(_email.text);
      if (mounted) context.push(Routes.resetCode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowScaffold(
      onBack: () => goBack(context, Routes.login),
      header: const MuStepIndicator(step: 1, total: 3, title: 'Ton email'),
      body: [
        const FlowTitle(
          'Mot de passe oublié ?',
          lead: 'Entre l’email de ton compte. On t’envoie un code à 6 chiffres pour choisir un '
              'nouveau mot de passe.',
        ),
        MuTextField(
          label: 'Email',
          controller: _email,
          leadingIcon: PhosphorIcons.envelopeSimple(),
          placeholder: 'yassine.b@email.tn',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          error: _error,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: 'Envoyer le code',
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
