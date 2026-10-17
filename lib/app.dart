import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_settings.dart';
import 'core/format.dart';
import 'features/dev/debug_menu.dart';
import 'features/player_onboarding/controllers/onboarding_controller.dart';
import 'l10n/l10n.dart';
import 'router.dart';
import 'theme/theme.dart';

class MatchUpApp extends ConsumerWidget {
  const MatchUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);
    // The global strings follow the chosen language (CLAUDE.md rule 12).
    setL10nLocale(settings.locale);
    setFormatLocale(settings.locale);
    return MaterialApp.router(
      title: 'MatchUp',
      debugShowCheckedModeBanner: false,
      theme: MuTheme.light(arabic: settings.isArabic),
      darkTheme: MuTheme.dark(arabic: settings.isArabic),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      routerConfig: router,
      // Screens read the saved onboarding progress synchronously: wait until it is loaded
      // (a few milliseconds) so a resumed or deep-linked screen never sees an empty state.
      builder: (context, child) => Consumer(
        builder: (context, ref, _) => ref.watch(onboardingProvider).hasValue
            ? (ref.watch(debugMenuEnabledProvider)
                  ? Stack(children: [child!, const DebugMenuButton()])
                  : child!)
            : ColoredBox(color: context.mu.bg),
      ),
    );
  }
}
