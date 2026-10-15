import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/auth_providers.dart';
import '../data/auth_repository.dart';
import '../widgets/auth_messages.dart';

/// AUTH-08 · Mot de passe oublié 3/3: choose and confirm the new password.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;
  bool _loading = false;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _password.addListener(_rebuild);
    _confirm.addListener(_rebuild);
  }

  void _rebuild() => setState(() {
        if (_passwordError == AuthMessages.samePassword) _passwordError = null;
      });

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _rulesOk => MuPasswordRules.allMet(_password.text);
  bool get _matches => _confirm.text.isNotEmpty && _confirm.text == _password.text;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_rulesOk || !_matches) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(_password.text);
      if (mounted) context.go(Routes.passwordChanged);
    } on SamePassword {
      setState(() => _passwordError = AuthMessages.samePassword);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rulesError = _submitted && !_rulesOk ? AuthMessages.passwordRules : null;
    final confirmError =
        _submitted && _rulesOk && !_matches ? AuthMessages.passwordsDiffer : null;
    return FlowScaffold(
      onBack: () => goBack(context, Routes.resetCode),
      header: const MuStepIndicator(step: 3, total: 3, title: 'Nouveau mot de passe'),
      body: [
        const FlowTitle(
          'Choisis un nouveau mot de passe',
          lead: 'Il doit être différent de l’ancien.',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuPasswordField(
              label: 'Nouveau mot de passe',
              controller: _password,
              strength: true,
              rules: MuPasswordRules.standard,
              showRuleErrors: rulesError != null,
              error: _passwordError ?? rulesError,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: MuSpace.s5),
            MuPasswordField(
              label: 'Confirme le mot de passe',
              controller: _confirm,
              newPassword: true,
              error: confirmError,
              success: _matches && _rulesOk ? AuthMessages.passwordsMatch : null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: 'Enregistrer',
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
