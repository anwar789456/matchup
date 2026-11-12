import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/auth_providers.dart';
import '../widgets/auth_messages.dart';
import '../widgets/auth_widgets.dart';
import '../../../l10n/l10n.dart';

/// AUTH-04 · Vérifie ta boîte mail: the 6-digit code emailed at sign-up (there is no server to
/// open a link), checked as soon as it is typed; resend after 0:45, or continue and verify later.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  // AUTH-04: « Renvoyer l’email » is available again after 0:45.
  static const _resendIn = Duration(seconds: 45);

  final _code = TextEditingController();
  String? _error;
  String? _disabled;
  String? _success;
  bool _verifying = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _resend(String email) async {
    try {
      await ref.read(authRepositoryProvider).resendVerificationEmail();
    } catch (e) {
      if (mounted) {
        MuToast.show(context, tone: MuToastTone.error, title: AuthMessages.emailFailure(e));
      }
      return;
    }
    if (!mounted) return;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.emailRenvoye,
      description: l10n.codeEnvoyeA2(email),
    );
  }

  Future<void> _verify() async {
    if (_verifying || _success != null || _disabled != null) return;
    if (_code.text.length < 6) {
      setState(() => _error = AuthMessages.codeIncomplete);
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyEmailCode(_code.text);
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _success = l10n.emailVerifie;
      });
      await Future<void>.delayed(MuMotion.success);
      if (mounted) context.push(Routes.roles);
    } catch (e) {
      final message = AuthMessages.codeFailure(e);
      if (!mounted) return;
      setState(() {
        _verifying = false;
        if (message == AuthMessages.tooManyCodes) {
          _disabled = message;
        } else {
          _error = message ?? AuthMessages.emailFailure(e);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final email = ref.watch(authFlowProvider).email ?? '';
    return FlowScaffold(
      onBack: () => goBack(context, Routes.smsCode),
      gap: MuSpace.s6,
      body: [
        Column(
          children: [
            StatusHeroTile(
              icon: PhosphorIcons.envelopeSimpleOpen(),
              ground: c.infoSoft,
              ink: c.infoText,
              badgeIcon: PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill),
              badgeFill: c.accent,
              badgeInk: c.onAccent,
            ),
            const SizedBox(height: MuSpace.s6),
            FlowTitle(
              l10n.verifieTaBoiteMail,
              centered: true,
              leadSpan: TextSpan(children: [
                TextSpan(text: l10n.onAEnvoyeUnCodeA),
                TextSpan(text: email, style: MuType.labelL.copyWith(color: c.text)),
                TextSpan(text: l10n.entreLePourActiverTonCompte),
              ]),
            ),
          ],
        ),
        MuOtpInput(
          controller: _code,
          label: l10n.codeRecuParEmail,
          helper: l10n.expireDansMinutesRegardeAussi,
          error: _error,
          success: _success,
          verifying: _verifying,
          disabled: _disabled,
          resendIn: _resendIn,
          onResend: () => _resend(email),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onCompleted: (_) => _verify(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuButton.secondary(
              label: l10n.ouvrirMaMessagerie,
              leading: PhosphorIcons.envelopeSimpleOpen(),
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: () async {
                // Opens the mail app; the toast stays as a fallback when none is set up.
                final opened = await launchUrl(Uri(scheme: 'mailto'));
                if (!opened && context.mounted) {
                  MuToast.show(
                    context,
                    title: l10n.ouvreTaMessagerie,
                    description: l10n.leCodeDeConfirmationT,
                  );
                }
              },
            ),
            const SizedBox(height: MuSpace.s1),
            Center(
              child: MuButton.tertiary(
                label: l10n.modifierLAdresse,
                onPressed: () => context.go(Routes.signup),
              ),
            ),
            const SizedBox(height: MuSpace.s3),
            Text(
              l10n.rienRecuRegardeDansTes,
              textAlign: TextAlign.center,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: l10n.continuer,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(Routes.roles),
        ),
        Text(
          l10n.tuPourrasVerifierPlusTard,
          textAlign: TextAlign.center,
          style: MuType.caption.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}
