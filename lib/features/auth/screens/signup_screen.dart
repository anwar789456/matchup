import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/auth_providers.dart';
import '../data/auth_repository.dart';
import '../widgets/auth_messages.dart';
import '../widgets/auth_widgets.dart';
import '../../../l10n/l10n.dart';

/// AUTH-01 · Inscription, with the AUTH-01b error states (email taken, weak password, terms not
/// accepted) shown on submit. What the player typed is always kept.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _consent = false;
  bool _marketing = false;
  bool _submitted = false;
  bool _loading = false;
  String? _emailError;
  bool _emailTaken = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() {
      if (_submitted) setState(() {});
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _passwordOk => MuPasswordRules.allMet(_password.text);

  Future<void> _submit() async {
    final emailError = AuthMessages.validateEmail(_email.text);
    setState(() {
      _submitted = true;
      _emailError = emailError;
      _emailTaken = false;
    });
    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (!_passwordOk) {
      _passwordFocus.requestFocus();
      return;
    }
    if (!_consent) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _email.text,
            password: _password.text,
            marketingOptIn: _marketing,
          );
      ref.read(authFlowProvider.notifier).setEmail(_email.text);
      if (mounted) context.push(Routes.phone);
    } on EmailAlreadyUsed {
      setState(() {
        _emailError = AuthMessages.emailTaken;
        _emailTaken = true;
      });
      _emailFocus.requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _social(SocialProvider provider) async {
    try {
      await ref.read(authRepositoryProvider).signInWithProvider(provider);
      if (mounted) context.push(Routes.phone);
    } on ProviderSignInFailed {
      if (mounted) {
        MuToast.show(context, tone: MuToastTone.error, title: AuthMessages.providerFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return FlowScaffold(
      onBack: () => goBack(context, Routes.welcome3),
      topAction: MuButton.tertiary(
        label: l10n.seConnecter,
        onPressed: () => context.pushReplacement(Routes.login),
      ),
      body: [
        FlowTitle(
          l10n.creeTonCompte,
          lead: l10n.trouveDesPartiesATon,
        ),
        SocialButtons(
          onGoogle: () => _social(SocialProvider.google),
          onApple: () => _social(SocialProvider.apple),
        ),
        OrDivider(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTextField(
              label: l10n.email,
              controller: _email,
              focusNode: _emailFocus,
              leadingIcon: PhosphorIcons.envelopeSimple(),
              placeholder: l10n.yassineBEmailTn,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              error: _emailError,
              messageExtra: _emailTaken
                  ? Text.rich(
                      TextSpan(children: [
                        TextSpan(text: l10n.cEstLeTien),
                        inlineLink(
                          l10n.seConnecter,
                          () => context.pushReplacement(Routes.login),
                          MuType.labelS,
                        ),
                      ]),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    )
                  : null,
              onChanged: (_) {
                if (_emailError != null) {
                  setState(() {
                    _emailError = null;
                    _emailTaken = false;
                  });
                }
              },
            ),
            const SizedBox(height: MuSpace.s5),
            MuPasswordField(
              controller: _password,
              focusNode: _passwordFocus,
              strength: true,
              rules: MuPasswordRules.standard,
              showRuleErrors: _submitted && !_passwordOk,
              error: _submitted && !_passwordOk ? AuthMessages.passwordRules : null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuCheckbox(
              value: _consent,
              label: l10n.jAccepteLesConditionsD,
              error: _submitted && !_consent ? AuthMessages.consent : null,
              onChanged: (v) => setState(() => _consent = v ?? false),
            ),
            MuCheckbox(
              value: _marketing,
              label: l10n.recevoirLesPartiesPresDe,
              onChanged: (v) => setState(() => _marketing = v ?? false),
            ),
          ],
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: l10n.creerMonCompte,
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
