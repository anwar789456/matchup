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

/// AUTH-05 · Connexion, with the AUTH-05b error banner (wrong credentials, tries left before the
/// temporary lock). The 5th failure opens AUTH-10.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final _email = TextEditingController(text: ref.read(authFlowProvider).email ?? '');
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String? _emailError;
  String? _passwordError;
  int? _attemptsLeft;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = AuthMessages.validateEmail(_email.text);
    final passwordError = _password.text.isEmpty ? AuthMessages.passwordMissing : null;
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    if (repo.lockedUntil() != null) {
      context.push(Routes.accountLocked);
      return;
    }
    setState(() => _loading = true);
    try {
      await repo.signIn(email: _email.text, password: _password.text);
      ref.read(authFlowProvider.notifier).setEmail(_email.text);
      if (mounted) context.go(Routes.roles);
    } on InvalidCredentials catch (e) {
      setState(() => _attemptsLeft = e.attemptsLeft);
    } on AccountLocked {
      if (mounted) context.push(Routes.accountLocked);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _social(SocialProvider provider) async {
    try {
      await ref.read(authRepositoryProvider).signInWithProvider(provider);
      if (mounted) context.go(Routes.roles);
    } on ProviderSignInFailed {
      if (mounted) {
        MuToast.show(context, tone: MuToastTone.error, title: AuthMessages.providerFailed);
      }
    }
  }

  void _forgot() {
    ref.read(authFlowProvider.notifier).setResetEmail(_email.text);
    context.push(Routes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return FlowScaffold(
      onBack: () => goBack(context, Routes.welcome3),
      body: [
        FlowTitle(
          l10n.contentDeTeRevoir,
          lead: l10n.connecteToiPourRetrouverTes,
        ),
        SocialButtons(
          onGoogle: () => _social(SocialProvider.google),
          onApple: () => _social(SocialProvider.apple),
        ),
        OrDivider(),
        if (_attemptsLeft != null)
          MuBanner(
            tone: MuBannerTone.error,
            title: AuthMessages.wrongCredentials,
            detail: AuthMessages.beforeLock(_attemptsLeft!),
            footer: MuButton.link(
              label: l10n.reinitialiserMonMotDePasse,
              inline: true,
              linkStyle: MuType.label,
              onPressed: _forgot,
            ),
          ),
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
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: MuSpace.s5),
            MuPasswordField(
              controller: _password,
              focusNode: _passwordFocus,
              error: _passwordError,
              textInputAction: TextInputAction.done,
              labelAside: MuButton.link(
                label: l10n.motDePasseOublie,
                inline: true,
                linkStyle: MuType.label,
                onPressed: _forgot,
              ),
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: l10n.seConnecter,
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _loading,
          onPressed: _submit,
        ),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: l10n.pasEncoreDeCompte),
            inlineLink(l10n.creerUnCompte, () => context.pushReplacement(Routes.signup), MuType.label),
          ]),
          textAlign: TextAlign.center,
          style: MuType.body.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}
