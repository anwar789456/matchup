import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/settings_repository.dart';

/// SET-05 · Confidentialité: profile visibility, invitations, level and reliability display,
/// precise location, data download, blocked players.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final s = ref.watch(accountSettingsProvider);
    final ctrl = ref.read(accountSettingsProvider.notifier);
    Widget toggle(
      IconData icon,
      String label,
      String description,
      bool value,
      ValueChanged<bool> on,
    ) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
      child: MuSwitch(
        value: value,
        icon: icon,
        label: label,
        description: description,
        onChanged: on,
      ),
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: 'Confidentialité',
            backLabel: 'Retour aux paramètres',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                MuSettingsGroup(
                  title: 'Profil',
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.eye(),
                      title: 'Qui voit mon profil',
                      value: s.profilePublic ? 'Tout le monde' : 'Mes abonnés',
                      onTap: () => _pick(
                        context,
                        'Qui voit mon profil',
                        const [('Tout le monde', true), ('Mes abonnés', false)],
                        s.profilePublic,
                        (v) => ctrl.update((s) => s.copyWith(profilePublic: v)),
                      ),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.userPlus(),
                      title: 'Qui peut m’inviter',
                      value: switch (s.invites) {
                        InvitePolicy.everyone => 'Tout le monde',
                        InvitePolicy.teammates => 'Mes coéquipiers',
                        InvitePolicy.nobody => 'Personne',
                      },
                      onTap: () => _pick(
                        context,
                        'Qui peut m’inviter',
                        const [
                          ('Tout le monde', InvitePolicy.everyone),
                          ('Mes coéquipiers', InvitePolicy.teammates),
                          ('Personne', InvitePolicy.nobody),
                        ],
                        s.invites,
                        (v) => ctrl.update((s) => s.copyWith(invites: v)),
                      ),
                    ),
                    toggle(
                      PhosphorIcons.chartBar(),
                      'Afficher mon niveau',
                      '3,5 en padel et 3,0 en foot, sur ton profil et dans les parties.',
                      s.showLevel,
                      (v) => ctrl.update((s) => s.copyWith(showLevel: v)),
                    ),
                    toggle(
                      PhosphorIcons.sealCheck(),
                      'Afficher ma fiabilité',
                      'Masquée, les organisateurs lisent « Fiabilité masquée ».',
                      s.showReliability,
                      (v) => ctrl.update((s) => s.copyWith(showReliability: v)),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: 'Localisation',
                  children: [
                    toggle(
                      PhosphorIcons.mapPin(),
                      'Position précise',
                      'Pour des distances exactes. Les autres voient « La Marsa ».',
                      s.preciseLocation,
                      (v) => ctrl.update((s) => s.copyWith(preciseLocation: v)),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: 'Tes données',
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.downloadSimple(),
                      title: 'Télécharger mes données',
                      description: 'Profil, matchs et paiements, par email sous 48 h',
                      onTap: () => MuToast.show(
                        context,
                        tone: MuToastTone.success,
                        title: 'Demande envoyée',
                        description: 'Tu recevras tes données par email sous 48 h.',
                      ),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.prohibit(),
                      title: 'Joueurs bloqués',
                      value: '${s.blocked}',
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick<T>(
    BuildContext context,
    String title,
    List<(String, T)> options,
    T current,
    ValueChanged<T> onPick,
  ) => MuBottomSheet.show<void>(
    context,
    title: title,
    height: MuSheetHeight.auto,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (label, value) in options)
          MuSettingsRow(
            title: label,
            chevron: false,
            trailing: value == current
                ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: MuSize.iconS)
                : const SizedBox.shrink(),
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              onPick(value);
            },
          ),
        const SizedBox(height: MuSpace.s4),
      ],
    ),
  );
}
