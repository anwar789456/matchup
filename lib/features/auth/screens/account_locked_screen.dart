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
import '../widgets/auth_widgets.dart';

/// AUTH-10 · Compte bloqué: 15 minutes after 5 failed sign-ins, with the time left.
class AccountLockedScreen extends ConsumerWidget {
  const AccountLockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final until = ref.read(authRepositoryProvider).lockedUntil() ?? DateTime.now();
    return FlowScaffold(
      onBack: () => goBack(context, Routes.login),
      centerBody: true,
      body: [
        Column(
          children: [
            StatusHeroTile(
              icon: PhosphorIcons.lock(),
              ground: c.warningSoft,
              ink: c.warningText,
            ),
            const SizedBox(height: MuSpace.s6),
            const FlowTitle(
              'Compte bloqué pendant 15 min',
              centered: true,
              lead: 'Après 5 tentatives incorrectes, on bloque la connexion pour protéger ton compte.',
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(MuSpace.s4),
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
          child: Center(
            child: MuCountdown(
              endsAt: until,
              size: MuCountdownSize.l,
              centered: true,
              label: 'Tu pourras réessayer dans',
              urgentAfter: const Duration(minutes: 1),
              expiredLabel: 'Tu peux te reconnecter',
            ),
          ),
        ),
        MuBanner(
          tone: MuBannerTone.info,
          icon: PhosphorIcons.shieldWarning(PhosphorIconsStyle.fill),
          title: 'Ce n’était pas toi ?',
          detail: 'Réinitialise ton mot de passe maintenant : toutes tes sessions seront fermées. '
              'On t’a aussi prévenu par email.',
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: 'Réinitialiser mon mot de passe',
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(Routes.forgotPassword),
        ),
        MuButton.secondary(
          label: 'Contacter le support',
          size: MuButtonSize.xl,
          fullWidth: true,
          // The support line of the design (help card of the pro onboarding).
          onPressed: () async {
            final opened = await launchUrl(Uri(scheme: 'tel', path: '+21671234567'));
            if (!opened && context.mounted) {
              MuToast.show(
                context,
                title: 'Appelle-nous au +216 71 234 567',
                description: 'Du lundi au samedi, de 9h00 à 18h00.',
              );
            }
          },
        ),
      ],
    );
  }
}
