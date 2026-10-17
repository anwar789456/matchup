import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_settings.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../../l10n/l10n.dart';

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
            title: l10n.langueEtTheme,
            backLabel: l10n.retourAuxParametres,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 34),
              children: [
                card([
                  MuRadioGroup<String>(
                    label: l10n.langue,
                    value: app.locale.languageCode,
                    onChanged: (v) => ctrl.setLocale(Locale(v)),
                    options: [
                      MuRadioOption(
                        value: 'fr',
                        label: l10n.francais,
                        description: l10n.langueParDefautDeMatchup,
                      ),
                      MuRadioOption(
                        value: 'ar',
                        label: 'العربية',
                        description: l10n.arabeLInterfacePasseDe,
                      ),
                      MuRadioOption(value: 'en', label: l10n.english, description: l10n.anglais),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s3),
                  Text(
                    l10n.enArabeLesMenusEt,
                    style: caption,
                  ),
                ]),
                const SizedBox(height: MuSpace.s5),
                card([
                  MuRadioGroup<ThemeMode>(
                    label: l10n.theme,
                    value: app.themeMode,
                    onChanged: ctrl.setThemeMode,
                    options: [
                      MuRadioOption(value: ThemeMode.light, label: l10n.clair),
                      MuRadioOption(value: ThemeMode.dark, label: l10n.sombre),
                      MuRadioOption(value: ThemeMode.system, label: l10n.systeme),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s3),
                  Text(
                    l10n.systemeSuitLeReglageDe,
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
