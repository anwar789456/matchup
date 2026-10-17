import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/settings_repository.dart';

/// SET-06 · Comptes connectés: email, Google, Apple — keep at least one way in.
class ConnectedAccountsScreen extends ConsumerWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final s = ref.watch(accountSettingsProvider);
    final ctrl = ref.read(accountSettingsProvider.notifier);
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    const connected = MuStatusBadge(
      status: MuStatus.confirmed,
      label: 'Connecté',
      size: MuBadgeSize.s,
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: 'Comptes connectés',
            backLabel: 'Retour aux paramètres',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                MuSettingsGroup(
                  title: 'Tes méthodes de connexion',
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.envelopeSimple(),
                      title: 'Email et mot de passe',
                      description: s.email,
                      trailing: connected,
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.googleLogo(),
                      title: 'Google',
                      description: s.googleEmail ?? 'Non connecté',
                      trailing: s.googleEmail != null
                          ? MuButton.tertiary(
                              label: 'Déconnecter',
                              size: MuButtonSize.s,
                              onPressed: () {
                                ctrl.update((s) => s.copyWith(googleEmail: null));
                                MuToast.show(context, title: 'Google déconnecté');
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.appleLogo(),
                      title: 'Apple',
                      description: s.appleConnected ? 'Connecté' : 'Non connecté',
                      trailing: s.appleConnected ? connected : const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                const MuBanner(
                  tone: MuBannerTone.info,
                  title: 'Garde au moins une méthode de connexion',
                  detail:
                      'Sans elle, tu perdrais l’accès à ton compte. Ton email reste actif si tu '
                      'déconnectes Google.',
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(
                  header: true,
                  child: Text('Ajouter une méthode', style: MuType.h3.copyWith(color: c.text)),
                ),
                const SizedBox(height: MuSpace.s3),
                if (s.googleEmail == null) ...[
                  MuSocialButton(
                    provider: MuSocialProvider.google,
                    label: 'Continuer avec Google',
                    onPressed: () {
                      ctrl.update((s) => s.copyWith(googleEmail: 'yassine.b@gmail.com'));
                      MuToast.show(context, tone: MuToastTone.success, title: 'Google connecté');
                    },
                  ),
                  const SizedBox(height: MuSpace.s3),
                ],
                if (!s.appleConnected)
                  MuSocialButton(
                    provider: MuSocialProvider.apple,
                    label: 'Continuer avec Apple',
                    onPressed: () {
                      ctrl.update((s) => s.copyWith(appleConnected: true));
                      MuToast.show(context, tone: MuToastTone.success, title: 'Apple connecté');
                    },
                  ),
                const SizedBox(height: MuSpace.s3),
                Text(
                  'On ne publie jamais rien sur tes comptes. Apple peut masquer ton adresse email.',
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
