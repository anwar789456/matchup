import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../data/settings_repository.dart';

/// SET-03 · Sécurité: password, two-factor, active sessions.
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final s = ref.watch(accountSettingsProvider);
    final ctrl = ref.read(accountSettingsProvider.notifier);
    final others = s.sessions.where((d) => !d.current).toList();
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: 'Sécurité',
            backLabel: 'Retour aux paramètres',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                MuSettingsGroup(
                  title: 'Mot de passe',
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.key(),
                      title: 'Changer le mot de passe',
                      description: 'Modifié ${s.passwordChanged}',
                      onTap: () => context.push(Routes.forgotPassword),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: 'Double authentification',
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MuSpace.s4,
                        vertical: MuSpace.s3,
                      ),
                      child: MuSwitch(
                        value: s.twoFactor,
                        icon: PhosphorIcons.shieldCheck(),
                        label: 'Code à chaque nouvel appareil',
                        description: 'Un code par SMS en plus de ton mot de passe.',
                        onChanged: (v) => ctrl.update((s) => s.copyWith(twoFactor: v)),
                      ),
                    ),
                    if (s.twoFactor)
                      MuSettingsRow(
                        icon: PhosphorIcons.chatText(),
                        title: 'Méthode',
                        value: 'SMS · ${s.maskedPhone}',
                        onTap: () => context.push(Routes.settingsAccount),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s3),
                        child: MuBanner(
                          tone: MuBannerTone.warning,
                          title:
                              'Sans code, seul ton mot de passe protège ton compte et ton solde de '
                              '${formatDT(Story.myBalance)}.',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: 'Sessions actives',
                  children: [
                    for (final d in s.sessions)
                      MuSettingsRow(
                        icon: d.mobile ? PhosphorIcons.deviceMobile() : PhosphorIcons.desktop(),
                        title: d.name,
                        description: d.where,
                        trailing: d.current
                            ? const MuStatusBadge(
                                status: MuStatus.confirmed,
                                label: 'Cet appareil',
                                size: MuBadgeSize.s,
                              )
                            : MuButton.tertiary(
                                label: 'Déconnecter',
                                size: MuButtonSize.s,
                                onPressed: () {
                                  ctrl.signOutSession(d.id);
                                  MuToast.show(context, title: '${d.name} déconnecté');
                                },
                              ),
                      ),
                  ],
                ),
                const SizedBox(height: MuSpace.s2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: Text(
                    others.isEmpty
                        ? 'Aucune autre session ouverte. Seul cet ${s.sessions.first.name} est connecté.'
                        : 'Tu ne reconnais pas un appareil ? Déconnecte-le, puis change ton mot de passe.',
                    style: caption,
                  ),
                ),
                if (others.isNotEmpty) ...[
                  const SizedBox(height: MuSpace.s4),
                  MuButton.destructiveOutline(
                    label: 'Déconnecter toutes les autres sessions',
                    size: MuButtonSize.l,
                    fullWidth: true,
                    onPressed: () {
                      ctrl.signOutOthers();
                      MuToast.show(context, title: 'Autres sessions déconnectées');
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
