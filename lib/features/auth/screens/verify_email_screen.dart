import 'package:flutter/material.dart';
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
      title: 'Email renvoyé',
      description: 'Lien envoyé à $email',
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
              'Vérifie ta boîte mail',
              centered: true,
              leadSpan: TextSpan(children: [
                const TextSpan(text: 'On a envoyé un lien de confirmation à '),
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
              label: 'Ouvrir ma messagerie',
              leading: PhosphorIcons.envelopeSimpleOpen(),
              size: MuButtonSize.l,
              fullWidth: true,
              // Opening the mail app needs a platform integration (later milestone).
              onPressed: () => MuToast.show(
                context,
                title: 'Ouvre ta messagerie',
                description: 'Le lien de confirmation t’attend dans ta boîte.',
              ),
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
                label: 'Modifier l’adresse',
                onPressed: () => context.go(Routes.signup),
              ),
            ),
            const SizedBox(height: MuSpace.s3),
            Text(
              'Rien reçu ? Regarde dans tes spams ou l’onglet Promotions.',
              textAlign: TextAlign.center,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: 'Continuer',
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(Routes.roles),
        ),
        Text(
          'Tu pourras vérifier plus tard. En attendant, un rappel s’affichera en haut de l’app.',
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
          label: 'Renvoyer l’email',
          countdown: waiting ? formatClock(left + const Duration(milliseconds: 999)) : null,
          loading: widget.loading,
          onPressed: waiting ? null : widget.onPressed,
        );
      },
    );
  }
}
