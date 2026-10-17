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
      'en' => 'English',
      _ => 'Français',
    };
    final theme = switch (app.themeMode) {
      ThemeMode.light => 'Clair',
      ThemeMode.dark => 'Sombre',
      ThemeMode.system => 'Système',
    };
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: 'Paramètres',
            backLabel: 'Retour au profil',
            onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                MuSettingsGroup(
                  title: 'Compte',
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.userCircle(),
                      title: 'Compte',
                      value: s.email,
                      onTap: () => context.push(Routes.settingsAccount),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.shieldCheck(),
                      title: 'Sécurité',
                      value: s.twoFactor ? '2FA activée' : '2FA désactivée',
                      onTap: () => context.push(Routes.settingsSecurity),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.linkSimple(),
                      title: 'Comptes connectés',
                      value: [
                        if (s.googleEmail != null) 'Google',
                        if (s.appleConnected) 'Apple',
                      ].join(' · '),
                      onTap: () => context.push(Routes.settingsAccounts),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: 'Préférences',
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.bell(),
                      title: 'Notifications',
                      value: s.notificationsSummary,
                      onTap: () => showComingSoon(context),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.translate(),
                      title: 'Langue et thème',
                      value: '$language · $theme',
                      onTap: () => context.push(Routes.settingsLanguage),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.eye(),
                      title: 'Confidentialité',
                      value: s.profilePublic ? 'Profil public' : 'Profil limité',
                      onTap: () => context.push(Routes.settingsPrivacy),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                MuSettingsGroup(
                  title: 'Assistance',
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.lifebuoy(),
                      title: 'Aide',
                      value: 'FAQ · nous écrire',
                      onTap: () => showComingSoon(context),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.info(),
                      title: 'À propos',
                      value: 'Version 1.0',
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                Semantics(
                  label: 'Session',
                  child: MuSettingsGroup(
                    children: [
                      MuSettingsRow(
                        icon: PhosphorIcons.signOut(),
                        title: 'Se déconnecter',
                        chevron: false,
                        onTap: () => signOutToLogin(context, ref),
                      ),
                      MuSettingsRow(
                        icon: PhosphorIcons.trash(),
                        title: 'Supprimer le compte',
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
