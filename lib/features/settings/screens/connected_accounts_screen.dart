import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/settings_repository.dart';
import '../../../l10n/l10n.dart';

/// SET-06 · Comptes connectés: email, Google, Apple — keep at least one way in.
class ConnectedAccountsScreen extends ConsumerWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final s = ref.watch(accountSettingsProvider);
    final ctrl = ref.read(accountSettingsProvider.notifier);
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final connected = MuStatusBadge(
      status: MuStatus.confirmed,
      label: l10n.connecte,
      size: MuBadgeSize.s,
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.comptesConnectes,
            backLabel: l10n.retourAuxParametres,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                MuSettingsGroup(
                  title: l10n.tesMethodesDeConnexion,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.envelopeSimple(),
                      title: l10n.emailEtMotDePasse,
                      description: s.email,
                      trailing: connected,
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.googleLogo(),
                      title: l10n.google,
                      description: s.googleEmail ?? l10n.nonConnecte,
                      trailing: s.googleEmail != null
                          ? MuButton.tertiary(
                              label: l10n.deconnecter,
                              size: MuButtonSize.s,
                              onPressed: () {
                                ctrl.update((s) => s.copyWith(googleEmail: null));
                                MuToast.show(context, title: l10n.googleDeconnecte);
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.appleLogo(),
                      title: l10n.apple,
                      description: s.appleConnected ? l10n.connecte : l10n.nonConnecte,
                      trailing: s.appleConnected ? connected : const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                MuBanner(
                  tone: MuBannerTone.info,
                  title: l10n.gardeAuMoinsUneMethode,
                  detail:
                      l10n.sansElleTuPerdraisL,
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(
                  header: true,
                  child: Text(l10n.ajouterUneMethode, style: MuType.h3.copyWith(color: c.text)),
                ),
                const SizedBox(height: MuSpace.s3),
                if (s.googleEmail == null) ...[
                  MuSocialButton(
                    provider: MuSocialProvider.google,
                    label: l10n.continuerAvecGoogle,
                    onPressed: () {
                      ctrl.update((s) => s.copyWith(googleEmail: l10n.yassineBGmailCom));
                      MuToast.show(context, tone: MuToastTone.success, title: l10n.googleConnecte);
                    },
                  ),
                  const SizedBox(height: MuSpace.s3),
                ],
                if (!s.appleConnected)
                  MuSocialButton(
                    provider: MuSocialProvider.apple,
                    label: l10n.continuerAvecApple,
                    onPressed: () {
                      ctrl.update((s) => s.copyWith(appleConnected: true));
                      MuToast.show(context, tone: MuToastTone.success, title: l10n.appleConnecte);
                    },
                  ),
                const SizedBox(height: MuSpace.s3),
                Text(
                  l10n.onNePublieJamaisRien,
                  style: caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
