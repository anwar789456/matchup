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
import '../../../l10n/l10n.dart';

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
            FlowTitle(
              l10n.compteBloquePendantMin,
              centered: true,
              lead: l10n.apresTentativesIncorrectesOnBloque,
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
              label: l10n.tuPourrasReessayerDans,
              urgentAfter: const Duration(minutes: 1),
              expiredLabel: l10n.tuPeuxTeReconnecter,
            ),
          ),
        ),
        MuBanner(
          tone: MuBannerTone.info,
          icon: PhosphorIcons.shieldWarning(PhosphorIconsStyle.fill),
          title: l10n.ceNEtaitPasToi,
          detail: l10n.reinitialiseTonMotDePasse,
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: l10n.reinitialiserMonMotDePasse,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => context.push(Routes.forgotPassword),
        ),
        MuButton.secondary(
          label: l10n.contacterLeSupport,
          size: MuButtonSize.xl,
          fullWidth: true,
          // The support line of the design (help card of the pro onboarding).
          onPressed: () async {
            final opened = await launchUrl(Uri(scheme: 'tel', path: '+21671234567'));
            if (!opened && context.mounted) {
              MuToast.show(
                context,
                title: l10n.appelleNousAu,
                description: l10n.duLundiAuSamediDe,
              );
            }
          },
        ),
      ],
    );
  }
}
