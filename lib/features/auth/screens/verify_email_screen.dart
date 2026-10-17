import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/auth_providers.dart';
import '../widgets/auth_widgets.dart';
import '../../../l10n/l10n.dart';

/// AUTH-04 · Vérifie ton email: open the mailbox, resend after 0:45, or continue and verify later.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  // AUTH-04: « Renvoyer l’email » is available again after 0:45.
  static const _resendDelay = Duration(seconds: 45);

  late DateTime _resendAt = DateTime.now().add(_resendDelay);
  bool _sending = false;

  Future<void> _resend(String email) async {
    setState(() => _sending = true);
    await ref.read(authRepositoryProvider).resendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _resendAt = DateTime.now().add(_resendDelay);
    });
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.emailRenvoye,
      description: l10n.lienEnvoyeA(email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final email = ref.watch(authFlowProvider).email ?? '';
    return FlowScaffold(
      onBack: () => goBack(context, Routes.smsCode),
      centerBody: true,
      gap: MuSpace.s8,
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
                TextSpan(text: l10n.onAEnvoyeUnLien),
                TextSpan(text: email, style: MuType.labelL.copyWith(color: c.text)),
                const TextSpan(text: '. Ouvre‑le pour activer ton compte.'),
              ]),
            ),
          ],
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
                    description: l10n.leLienDeConfirmationT,
                  );
                }
              },
            ),
            const SizedBox(height: MuSpace.s3),
            Center(child: _ResendButton(
              resendAt: _resendAt,
              loading: _sending,
              onPressed: () => _resend(email),
            )),
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

/// « Renvoyer l’email · 0:45 », disabled while the countdown runs.
class _ResendButton extends StatefulWidget {
  const _ResendButton({required this.resendAt, required this.loading, required this.onPressed});

  final DateTime resendAt;
  final bool loading;
  final VoidCallback onPressed;

  @override
  State<_ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends State<_ResendButton> {
  late final Stream<int> _ticks = Stream.periodic(const Duration(seconds: 1), (i) => i);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticks,
      builder: (context, _) {
        final left = widget.resendAt.difference(DateTime.now());
        final waiting = left > Duration.zero;
        return MuButton.tertiary(
          label: l10n.renvoyerLEmail,
          countdown: waiting ? formatClock(left + const Duration(milliseconds: 999)) : null,
          loading: widget.loading,
          onPressed: waiting ? null : widget.onPressed,
        );
      },
    );
  }
}
