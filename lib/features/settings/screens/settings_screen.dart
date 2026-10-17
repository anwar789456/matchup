import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/app_settings.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../profile/widgets/account_menu.dart';
import '../data/settings_repository.dart';
import '../../../l10n/l10n.dart';

/// SET-01 · Paramètres: Compte, Préférences, Assistance, then sign out and delete.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final s = ref.watch(accountSettingsProvider);
    final app = ref.watch(appSettingsProvider);
    final language = switch (app.locale.languageCode) {
      'ar' => 'العربية',
      'en' => l10n.english,
      _ => l10n.francais,
    };
    final theme = switch (app.themeMode) {
      ThemeMode.light => l10n.clair,
      ThemeMode.dark => l10n.sombre,
      ThemeMode.system => l10n.systeme,
    };
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.parametres,
            backLabel: l10n.retourAuProfil,
            onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                MuSettingsGroup(
                  title: l10n.compte,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.userCircle(),
                      title: l10n.compte,
                      value: s.email,
                      onTap: () => context.push(Routes.settingsAccount),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.shieldCheck(),
                      title: l10n.securite,
                      value: s.twoFactor ? l10n.t2faActivee : l10n.t2faDesactivee,
                      onTap: () => context.push(Routes.settingsSecurity),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.linkSimple(),
                      title: l10n.comptesConnectes,
                      value: [
                        if (s.googleEmail != null) l10n.google,
                        if (s.appleConnected) l10n.apple,
                      ].join(' · '),
                      onTap: () => context.push(Routes.settingsAccounts),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.preferences,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.bell(),
                      title: l10n.notifications,
                      value: s.notificationsSummary,
                      onTap: () => context.push(Routes.notificationSettings),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.translate(),
                      title: l10n.langueEtTheme,
                      value: '$language · $theme',
                      onTap: () => context.push(Routes.settingsLanguage),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.eye(),
                      title: l10n.confidentialite,
                      value: s.profilePublic ? l10n.profilPublic : l10n.profilLimite,
                      onTap: () => context.push(Routes.settingsPrivacy),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: l10n.assistance,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.lifebuoy(),
                      title: l10n.aide,
                      value: l10n.faqNousEcrire,
                      onTap: () => showComingSoon(context),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.info(),
                      title: l10n.aPropos,
                      value: l10n.version,
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                Semantics(
                  label: l10n.session,
                  child: MuSettingsGroup(
                    children: [
                      MuSettingsRow(
                        icon: PhosphorIcons.signOut(),
                        title: l10n.seDeconnecter,
                        chevron: false,
                        onTap: () => signOutToLogin(context, ref),
                      ),
                      MuSettingsRow(
                        icon: PhosphorIcons.trash(),
                        title: l10n.supprimerLeCompte,
                        destructive: true,
                        onTap: () => context.push(Routes.settingsDelete),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
