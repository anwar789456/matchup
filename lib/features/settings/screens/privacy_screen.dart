import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/settings_repository.dart';
import '../../../l10n/l10n.dart';

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
            title: l10n.confidentialite,
            backLabel: l10n.retourAuxParametres,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                MuSettingsGroup(
                  title: l10n.profil,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.eye(),
                      title: l10n.quiVoitMonProfil,
                      value: s.profilePublic ? l10n.toutLeMonde : l10n.mesAbonnes,
                      onTap: () => _pick(
                        context,
                        l10n.quiVoitMonProfil,
                        [(l10n.toutLeMonde, true), (l10n.mesAbonnes, false)],
                        s.profilePublic,
                        (v) => ctrl.update((s) => s.copyWith(profilePublic: v)),
                      ),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.userPlus(),
                      title: l10n.quiPeutMInviter,
                      value: switch (s.invites) {
                        InvitePolicy.everyone => l10n.toutLeMonde,
                        InvitePolicy.teammates => l10n.mesCoequipiers,
                        InvitePolicy.nobody => l10n.personne,
                      },
                      onTap: () => _pick(
                        context,
                        l10n.quiPeutMInviter,
                        [
                          (l10n.toutLeMonde, InvitePolicy.everyone),
                          (l10n.mesCoequipiers, InvitePolicy.teammates),
                          (l10n.personne, InvitePolicy.nobody),
                        ],
                        s.invites,
                        (v) => ctrl.update((s) => s.copyWith(invites: v)),
                      ),
                    ),
                    toggle(
                      PhosphorIcons.chartBar(),
                      l10n.afficherMonNiveau,
                      l10n.enPadelEtEnFoot,
                      s.showLevel,
                      (v) => ctrl.update((s) => s.copyWith(showLevel: v)),
                    ),
                    toggle(
                      PhosphorIcons.sealCheck(),
                      l10n.afficherMaFiabilite,
                      l10n.masqueeLesOrganisateursLisentFiabilite,
                      s.showReliability,
                      (v) => ctrl.update((s) => s.copyWith(showReliability: v)),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.localisation,
                  children: [
                    toggle(
                      PhosphorIcons.mapPin(),
                      l10n.positionPrecise,
                      l10n.pourDesDistancesExactesLes,
                      s.preciseLocation,
                      (v) => ctrl.update((s) => s.copyWith(preciseLocation: v)),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.tesDonnees,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.downloadSimple(),
                      title: l10n.telechargerMesDonnees,
                      description: l10n.profilMatchsEtPaiementsPar,
                      onTap: () => MuToast.show(
                        context,
                        tone: MuToastTone.success,
                        title: l10n.demandeEnvoyee,
                        description: l10n.tuRecevrasTesDonneesPar,
                      ),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.prohibit(),
                      title: l10n.joueursBloques,
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
