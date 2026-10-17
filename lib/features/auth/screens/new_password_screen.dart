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
import '../../../l10n/l10n.dart';

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
      header: MuStepIndicator(step: 3, total: 3, title: l10n.nouveauMotDePasse),
      body: [
        FlowTitle(
          l10n.choisisUnNouveauMotDe,
          lead: l10n.ilDoitEtreDifferentDe,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuPasswordField(
              label: l10n.nouveauMotDePasse,
              controller: _password,
              strength: true,
              rules: MuPasswordRules.standard,
              showRuleErrors: rulesError != null,
              error: _passwordError ?? rulesError,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: MuSpace.s5),
            MuPasswordField(
              label: l10n.confirmeLeMotDePasse,
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
          label: l10n.enregistrer,
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
