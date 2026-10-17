import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_settings.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// SET-04 · Langue et thème: Français · العربية · English; Clair · Sombre · Système. Both apply
/// at once and are saved on the device.
class LanguageThemeScreen extends ConsumerWidget {
  const LanguageThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final app = ref.watch(appSettingsProvider);
    final ctrl = ref.read(appSettingsProvider.notifier);
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget card(List<Widget> children) => Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: 'Langue et thème',
            backLabel: 'Retour aux paramètres',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                card([
                  MuRadioGroup<String>(
                    label: 'Langue',
                    value: app.locale.languageCode,
                    onChanged: (v) => ctrl.setLocale(Locale(v)),
                    options: const [
                      MuRadioOption(
                        value: 'fr',
                        label: 'Français',
                        description: 'Langue par défaut de MatchUp',
                      ),
                      MuRadioOption(
                        value: 'ar',
                        label: 'العربية',
                        description: 'Arabe · l’interface passe de droite à gauche',
                      ),
                      MuRadioOption(value: 'en', label: 'English', description: 'Anglais'),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s3),
                  Text(
                    'En arabe, les menus et les flèches s’inversent. Les chiffres, les scores et '
                    'les cartes restent dans le même sens.',
                    style: caption,
                  ),
                ]),
                const SizedBox(height: MuSpace.s5),
                card([
                  MuRadioGroup<ThemeMode>(
                    label: 'Thème',
                    value: app.themeMode,
                    onChanged: ctrl.setThemeMode,
                    options: const [
                      MuRadioOption(value: ThemeMode.light, label: 'Clair'),
                      MuRadioOption(value: ThemeMode.dark, label: 'Sombre'),
                      MuRadioOption(value: ThemeMode.system, label: 'Système'),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s3),
                  Text(
                    'Système suit le réglage de ton téléphone. Sombre, c’est « Night match » : '
                    'pensé pour les matchs du soir.',
                    style: caption,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
