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
import '../../../l10n/l10n.dart';

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
            title: l10n.securite,
            backLabel: l10n.retourAuxParametres,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                MuSettingsGroup(
                  title: l10n.motDePasse,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.key(),
                      title: l10n.changerLeMotDePasse,
                      description: l10n.modifie(s.passwordChanged),
                      onTap: () => context.push(Routes.forgotPassword),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.doubleAuthentification,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MuSpace.s4,
                        vertical: MuSpace.s3,
                      ),
                      child: MuSwitch(
                        value: s.twoFactor,
                        icon: PhosphorIcons.shieldCheck(),
                        label: l10n.codeAChaqueNouvelAppareil,
                        description: l10n.unCodeParSmsEn,
                        onChanged: (v) => ctrl.update((s) => s.copyWith(twoFactor: v)),
                      ),
                    ),
                    if (s.twoFactor)
                      MuSettingsRow(
                        icon: PhosphorIcons.chatText(),
                        title: l10n.methode,
                        value: l10n.sms(s.maskedPhone),
                        onTap: () => context.push(Routes.settingsAccount),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s3),
                        child: MuBanner(
                          tone: MuBannerTone.warning,
                          title:
                              l10n.sansCodeSeulTonMot(formatDT(Story.myBalance)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.sessionsActives,
                  children: [
                    for (final d in s.sessions)
                      MuSettingsRow(
                        icon: d.mobile ? PhosphorIcons.deviceMobile() : PhosphorIcons.desktop(),
                        title: d.name,
                        description: d.where,
                        trailing: d.current
                            ? MuStatusBadge(
                                status: MuStatus.confirmed,
                                label: l10n.cetAppareil,
                                size: MuBadgeSize.s,
                              )
                            : MuButton.tertiary(
                                label: l10n.deconnecter,
                                size: MuButtonSize.s,
                                onPressed: () {
                                  ctrl.signOutSession(d.id);
                                  MuToast.show(context, title: l10n.deconnecte(d.name));
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
                        ? l10n.aucuneAutreSessionOuverteSeul(s.sessions.first.name)
                        : l10n.tuNeReconnaisPasUn,
                    style: caption,
                  ),
                ),
                if (others.isNotEmpty) ...[
                  const SizedBox(height: MuSpace.s4),
                  MuButton.destructiveOutline(
                    label: l10n.deconnecterToutesLesAutresSessions,
                    size: MuButtonSize.l,
                    fullWidth: true,
                    onPressed: () {
                      ctrl.signOutOthers();
                      MuToast.show(context, title: l10n.autresSessionsDeconnectees);
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
